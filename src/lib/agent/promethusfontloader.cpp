#include "promethusfontloader.h"
#include <QFontDatabase>

void PromethusFontLoader::registerAll()
{
    struct FontEntry { const char* path; int weight; };
    static const FontEntry kFonts[] = {
        { ":/fonts/poppins/Poppins-Thin.ttf",        100 },
        { ":/fonts/poppins/Poppins-Light.ttf",       300 },
        { ":/fonts/poppins/Poppins-ExtraBold.ttf",   800 },
        { ":/fonts/poppins/Poppins-Black.ttf",        900 },
        { ":/fonts/spacemono/SpaceMono-Regular.ttf",  400 },
        { nullptr, 0 }
    };
    for (int i = 0; kFonts[i].path; ++i) {
        const int id = QFontDatabase::addApplicationFont(
            QLatin1String(kFonts[i].path));
        if (id == -1) {
            qWarning("PromethusFontLoader: failed to load %s \xe2\x80\x94 "
                     "falling back to system font for weight %d",
                     kFonts[i].path, kFonts[i].weight);
        }
    }
}
