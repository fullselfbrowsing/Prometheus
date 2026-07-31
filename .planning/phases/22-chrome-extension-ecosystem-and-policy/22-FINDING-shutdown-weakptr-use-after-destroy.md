# Finding: `PrometheusBrowserMainExtraParts::PostMainMessageLoopRun()` runs on an already destroyed object

Status: characterized, not fixed. Prometheus owned code. Phase 22 does not own the fix.
Prepared: 2026-07-31.

This finding exists because the record was wrong about it. `22-05-SUMMARY.md` item 6 filed this
crash as pre existing test environment flakiness caused by sandbox resource contention. It is not
environmental. It is our own shutdown code, and the check that catches it is compiled out of
official builds.

---

## The observation

```
[33546:17386161:0730/202317.910851:FATAL:base/memory/weak_ptr.h:408] DCHECK failed: ptr_.
...
7   prometheus_extension_smoke_tests  prometheus::PrometheusBrowserMainExtraParts::PostMainMessageLoopRun() + 96
8   prometheus_extension_smoke_tests  ChromeBrowserMainParts::PostMainMessageLoopRun() + 240
9   libcontent.dylib                  content::BrowserMainLoop::ShutdownThreadsAndCleanUp() + 456
10  libcontent.dylib                  content::BrowserMainRunnerImpl::Shutdown() + 204
11  libcontent.dylib                  content::BrowserMain(content::MainFunctionParams) + 212
...
17  prometheus_extension_smoke_tests  content::BrowserTestBase::SetUp() + 2728
```

Rate across the 110 run sweep of 2026-07-31:

| Arm | n | Occurrences |
| --- | --- | --- |
| extension smoke (main) | 30 | 2 |
| extension smoke (main2) | 30 | 0 |
| unrelated `SafeBrowsing` browsertest, same binary, zero extension contact | 30 | **2** |
| extension smoke, post revert | 20 | 0 |

All four occurrences are at the **identical offset**, `PostMainMessageLoopRun + 96`. It kills the
browser process and therefore fails whichever browsertest happens to be running, regardless of
subject. That subject independence is exactly why it was mistaken for environment noise. It is
also what proves it has nothing to do with the extension flow.

Build under test: `is_debug = false`, `is_component_build = true`, `symbol_level = 0`. This is an
**optimized build**, not a debug build, with `dcheck_always_on` at its default value of
`(build_with_chromium && !is_official_build)`, which is true here. So DCHECKs are live in a release
build.

---

## Which factory, and why it is not ambiguous

`weak_ptr.h:408` is uniquely the `DCHECK(ptr_)` inside `WeakPtrFactory<T>::InvalidateWeakPtrs()`.
That is a header function, so it is inlined and reported against its caller. `PostMainMessageLoopRun()`
begins:

`chrome/browser/prometheus/prometheus_browser_main_extra_parts.cc`

```cpp
void PrometheusBrowserMainExtraParts::PostMainMessageLoopRun() {   // :3231
  weak_ptr_factory_.InvalidateWeakPtrs();                          // :3232
  extension_smoke_browser_waiter_.reset();
  ...
}
```

Three things close off the alternatives:

1. There are five `InvalidateWeakPtrs()` call sites in that translation unit. The only one reachable
   by inlining into `PostMainMessageLoopRun()` other than `:3232` is `:2972`, inside
   `PrometheusSupervisionTestComposition::Shutdown()`, which `PostMainMessageLoopRun()` calls
   through `supervision_test_composition_`. But that member is null in the comparison arm, which
   never exercises any Prometheus supervision path, and the crash occurs there too, at the same
   offset. So it is not that factory.
2. `+96` is a first statement offset. The `supervision_test_composition_->Shutdown()` call is the
   fourth statement group, after a `reset()`, a null checked `Shutdown()` and a setter.
3. The class destructor is a separate symbol far away in the binary
   (`...D2Ev` at `0x10420f2b0`, `PostMainMessageLoopRun` at `0x104210b80`), so the symbolizer could
   not have misattributed a destructor frame to this function. `symbol_level = 0` still emits local
   text symbols, and both are present.

So the failing call is `PrometheusBrowserMainExtraParts::weak_ptr_factory_.InvalidateWeakPtrs()`,
the first statement of `PostMainMessageLoopRun()`, with `ptr_ == 0`.

---

## What `ptr_ == 0` means, exactly

`ptr_` is `uintptr_t WeakPtrFactoryBase::ptr_`, initialized from the owner pointer. Only three
pieces of code ever write it:

`base/memory/weak_ptr.cc`

```cpp
WeakPtrFactoryBase::WeakPtrFactoryBase(uintptr_t ptr) : ptr_(ptr) {   // :122
  DCHECK(ptr_);                                                       // nonzero at construction
}

WeakPtrFactoryBase::~WeakPtrFactoryBase() {                           // :126
  ptr_ = 0;                                                           // :127
}
```

`base/memory/weak_ptr.h`

```cpp
void InvalidateWeakPtrsAndDoom() {   // :415
  DCHECK(ptr_);
  weak_reference_owner_.InvalidateAndDoom();
  ptr_ = 0;                          // :418
}
```

The factory is declared `base::WeakPtrFactory<PrometheusBrowserMainExtraParts> weak_ptr_factory_{this}`
(header `:120`), so it is nonzero at construction and the constructor DCHECKs that. The spelling
`InvalidateWeakPtrsAndDoom` appears **zero** times in
`prometheus_browser_main_extra_parts.{cc,h}` (verified by grep, count 0 in both files).

That leaves `~WeakPtrFactoryBase()` as the only remaining writer of zero. **`ptr_ == 0` is the
destructor's own deterministic signature**, not a garbage value that happened to read as zero.

Therefore: **`PostMainMessageLoopRun()` is being invoked on a `PrometheusBrowserMainExtraParts`
whose destructor has already run.** This is a use after destroy on `this`.

The conclusion is robust to the one alternative worth naming. If the zero came instead from the
object's storage having been freed and reused or zeroed rather than from the destructor's own
write, the conclusion is unchanged, because that path also requires the object to have been
destroyed first. Both routes lead to the same statement.

Note the corroborating structure: `~PrometheusBrowserMainExtraParts()` (`:3058`) duplicates almost
the whole of `PostMainMessageLoopRun()`'s teardown and **begins with the same
`weak_ptr_factory_.InvalidateWeakPtrs()` statement** (`:3059`). The same teardown is reachable from
two places, and the crash is what you get when both run and the destructor wins the race.

*Deliberately not root caused:* why the object is already destroyed at that point. `ChromeBrowserMainParts`
owns the extra parts in a `std::vector<std::unique_ptr<ChromeBrowserMainExtraParts>>` destroyed only
in `~ChromeBrowserMainParts()`, and frame 8 shows `ChromeBrowserMainParts::PostMainMessageLoopRun()`
successfully iterating that vector to reach us, so the ordering violation is upstream of our object.
Establishing exactly which teardown path does this is out of scope for Phase 22.

---

## Release build behaviour at this site

This is the load bearing question, because `DCHECK` is compiled out of official builds and the
temptation is to assume that makes the crash cosmetic. It does not.

With `DCHECK_IS_ON()` false, `InvalidateWeakPtrs()` reduces to a single statement:

```cpp
void InvalidateWeakPtrs() {
  // DCHECK(ptr_);  <- gone
  weak_reference_owner_.Invalidate();
}
```

and `WeakReferenceOwner::Invalidate()` reduces to:

```cpp
void WeakReferenceOwner::Invalidate() {   // weak_ptr.cc:103
  // DCHECK(flag_);  <- gone
  flag_->Invalidate();                                   // :105
  flag_ = MakeRefCounted<WeakReference::Flag>();         // :106
}
```

The owner it is called on has already been destroyed. Its destructor is:

```cpp
WeakReferenceOwner::~WeakReferenceOwner() {   // :85
  if (flag_) {
    flag_->Invalidate();
  }
}
```

Critically, that destructor **does not null `flag_`**. It calls `Invalidate()` and then the
`scoped_refptr<Flag>` member destructor runs `Release()` on the pointer and leaves the stored
pointer dangling, because a `scoped_refptr` being destroyed has no reason to null its own field.

So in a build without DCHECKs, calling `Invalidate()` on the destroyed owner does two distinct
unsafe things:

1. **`flag_->Invalidate()`** dereferences the dangling pointer and executes
   `invalidated_.Set()` (`weak_ptr.cc:33`), an `AtomicFlag` store. That is a **write** through a
   pointer whose reference this owner already released.
2. **`flag_ = MakeRefCounted<Flag>()`** invokes `scoped_refptr::operator=`, which releases the old
   pointer. That is `RefCountedThreadSafe<Flag>::Release()` on a reference this owner **already
   dropped in its own destructor** — a second release of the same reference.

Both sub cases of step 2 are memory corruption, and which one you get depends only on whether any
`WeakPtr` was still outstanding:

- **The owner held the last reference.** The `Flag` was already freed when the owner was destroyed.
  Step 1 writes into freed heap; step 2 decrements a refcount in freed heap and, on reaching zero,
  `delete`s the block a second time. **Double free.**
- **Live `WeakPtr`s still hold references.** The `Flag` is alive, but step 2 **underflows its
  reference count by one**, so the `Flag` is destroyed while live `WeakPtr`s still point at it.
  Their next `IsValid()` or `MaybeValid()` is a use after free read.

Answer to the question, stated plainly: **not cosmetic, not a skipped operation, not a null
dereference. It is a real dangling access that performs a write, followed by a reference count
error that can free memory twice or free memory that is still referenced.** In an official build
the `DCHECK` is gone and all of this executes silently.

Worth flagging without over claiming: the predicted release mode failure here is a `Release()` on a
reference that has already been dropped, and the *other* crash signature observed in the same sweep
is `base/memory/ref_counted.h:235 DCHECK failed: !ref_count_.IsZero()` inside
`RefCountedThreadSafeBase::Release()`, also on the browser shutdown path. That is the same class of
error. It is a **different object** (a `BindState` reached through `~PendingTask()` during
`BrowserTaskExecutor::Shutdown()`, not a `WeakReference::Flag`), and no common root cause is claimed
here. It is recorded only because anyone fixing one should look at the other.

---

## What is and is not established

Observed directly:
- The `DCHECK` failure, its stack, and its identical `+96` offset in all four occurrences.
- The per arm rates in the table above, including 2/30 in an arm with zero extension contact.
- The build configuration (`is_debug = false`, `dcheck_always_on` defaulting true).

Established by source reading, not by runtime observation:
- That `ptr_ == 0` implies the factory was destroyed. This rests on the enumeration of writers of
  `ptr_` above, which is a static argument.
- The entire release build behaviour section. No official build was run; it is derived from the
  source of `InvalidateWeakPtrs()`, `WeakReferenceOwner::Invalidate()`,
  `~WeakReferenceOwner()`, `Flag::Invalidate()` and `scoped_refptr` assignment semantics.

Not established:
- Which teardown path destroys the object before `PostMainMessageLoopRun()` is dispatched.
- Whether a `WeakPtr` is typically still outstanding at that moment, which is what selects between
  the double free and the refcount underflow sub cases.
