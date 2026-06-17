#pragma once
#include "qzcommon.h"

class FALKON_EXPORT PromethusFontLoader
{
public:
    // Register all five brand font TTF files from Qt resources.
    // Must be called in MainApplication constructor before any widget construction.
    // Emits qWarning for any failed registration; does not throw.
    static void registerAll();
};
