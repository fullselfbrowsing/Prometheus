export const compatibilityError = (entry) => {
  if (!entry || !['typed_stub', 'later_phase', 'removed'].includes(entry.disposition)) {
    throw new TypeError('A non-native compatibility entry is required.');
  }

  const error = {
    code: entry.disposition === 'later_phase' ? 'NOT_READY' : entry.errorCode,
    tool: entry.name,
    owner_phase: entry.ownerPhase ?? null,
    replacements: [...(entry.replacements ?? [])],
    recovery: entry.recovery,
  };
  if (entry.disposition === 'removed') {
    error.removed_since = entry.removed_since;
    error.observed_as_typed_stubs_as_of = entry.observed_as_typed_stubs_as_of;
  }
  return { ok: false, error };
};
