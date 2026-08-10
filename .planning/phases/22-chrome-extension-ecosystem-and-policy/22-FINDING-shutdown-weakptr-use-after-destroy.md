# Finding correction: shutdown weak-pointer crash was a stale direct-link object

Status: resolved in the Phase 22 verification harness.
Corrected: 2026-08-09.

The earlier version of this note classified the intermittent
`PrometheusBrowserMainExtraParts::PostMainMessageLoopRun() + 96` DCHECK as a
product use-after-destroy. That conclusion was wrong. The crash was caused by
an ABI mismatch in the source-synthesis verification binaries.

## Correct root cause

Task 22-05 added the extension-smoke waiter and controller members to
`PrometheusBrowserMainExtraParts`. The direct harnesses recompiled
`prometheus_browser_main_extra_parts.cc`, but continued linking the reviewed
July object for `chrome/browser/chrome_browser_main.cc`. That translation unit
contains the `std::make_unique<PrometheusBrowserMainExtraParts>` allocation and
therefore owns the class-size ABI at the allocation site.

The stale allocator object and current constructor/destructor object disagreed
about the class layout. The current constructor wrote the new members and
`WeakPtrFactory` using the enlarged layout into storage allocated with the old
size. At shutdown, `PostMainMessageLoopRun()` read the invalid factory field and
hit `base/memory/weak_ptr.h:408`.

The decisive evidence is:

- `obj/chrome/browser/core/chrome_browser_main.o` was dated 2026-07-26 while
  the current main-extra-parts object was rebuilt on 2026-08-09.
- Disassembly places `PostMainMessageLoopRun() + 0x60` at the first
  `WeakPtrFactory::InvalidateWeakPtrs()` call and shows the factory pointer
  being read from the new-layout offset before that call.
- The crash appeared in unrelated browser tests linked with the same stale
  owner object, explaining its subject independence.
- Recompiling `chrome_browser_main.o` before linking the source-synthesis
  binaries restores one consistent class layout and removes the failure.

## Fix and scope

Every Phase 22 browser-derived direct verifier now recompiles
`obj/chrome/browser/core/chrome_browser_main.o` before linking. The packaged
smoke does the same before relinking its temporary current-source runtime.
Reviewed Ninja metadata and packaged artifacts remain byte-for-byte preserved.

No production lifetime change was required. This finding is retained as a
correction so later audits do not repeat the original use-after-destroy claim.
