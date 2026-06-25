# Phase 14 Asset Manifest

**This manifest is the single source of truth for all Phase 14 Prometheus Chromium assets.**

`verify-asset-pipeline.sh` (Wave 0), `prometheus_resources.grdp` (14-05),
`prometheus_resources.grd` (14-06), `prometheus_asset_resource_unittest.cc`
(14-06/14-08), and `prometheus_theme_preview.html` (14-07) MUST all match the
names/IDRs/counts here. If a downstream plan needs a different name, change THIS
file first.

---

## Section 1: Fonts (woff2) — WebUI delivery via @font-face

Location prefix: `chrome/browser/resources/prometheus/fonts/` (GRD packaged)
Also sourced from: `third_party/poppins/*.woff2`, `third_party/space_mono/*.woff2`

| Asset | Repo path (in chromium src) | IDR name | Count | Source (URL@rev) | License | Gate ref |
|-------|-----------------------------|----------|-------|-------------------|---------|----------|
| Poppins-Thin.woff2 | third_party/poppins/Poppins-Thin.woff2 | IDR_PROMETHEUS_FONT_POPPINS_THIN_WOFF2 | 1 | https://github.com/itfoundry/poppins@8.003 | OFL-1.1 | Assertion 1 line 35 |
| Poppins-Light.woff2 | third_party/poppins/Poppins-Light.woff2 | IDR_PROMETHEUS_FONT_POPPINS_LIGHT_WOFF2 | 1 | https://github.com/itfoundry/poppins@8.003 | OFL-1.1 | Assertion 1 line 36 |
| Poppins-ExtraBold.woff2 | third_party/poppins/Poppins-ExtraBold.woff2 | IDR_PROMETHEUS_FONT_POPPINS_EXTRABOLD_WOFF2 | 1 | https://github.com/itfoundry/poppins@8.003 | OFL-1.1 | Assertion 1 line 37 |
| Poppins-Black.woff2 | third_party/poppins/Poppins-Black.woff2 | IDR_PROMETHEUS_FONT_POPPINS_BLACK_WOFF2 | 1 | https://github.com/itfoundry/poppins@8.003 | OFL-1.1 | Assertion 1 line 38 |
| SpaceMono-Regular.woff2 | third_party/space_mono/SpaceMono-Regular.woff2 | IDR_PROMETHEUS_FONT_SPACE_MONO_WOFF2 | 1 | https://github.com/googlefonts/spacemono@1.000 | OFL-1.1 | Assertion 1 line 47 |

**Subtotal: 5 woff2 files**

---

## Section 2: Fonts (ttf) — Views shim (D-11 as-needed)

TTF files live at the third_party ROOT paths. Assertion 1 (lines 41-48) requires ALL
FOUR Poppins ttf + SpaceMono ttf to be present and non-zero on disk. However, only
TWO ttf files get a packaged IDR row (the as-needed Views shim per D-11: Poppins Thin
for the monogram's P glyph + Space Mono for the ▽ glyph). The other three Poppins
ttf are on-disk gate assets without an IDR — they ship physically but are not packaged
into the .pak. This keeps the IDR set === the GRDP TTF IDR set (exactly 2 TTF IDRs)
so 14-08's full-manifest IDR test never references an undeclared TTF symbol.

woff2 + ttf ALSO copied to: `chrome/browser/resources/prometheus/fonts/` (GRD packaged)

| Asset | Repo path (in chromium src) | IDR name | Count | Source (URL@rev) | License | Gate ref |
|-------|-----------------------------|----------|-------|-------------------|---------|----------|
| Poppins-Thin.ttf | third_party/poppins/Poppins-Thin.ttf | IDR_PROMETHEUS_FONT_POPPINS_THIN_TTF | 1 | https://github.com/itfoundry/poppins@8.003 | OFL-1.1 | Assertion 1 line 41 |
| Poppins-Light.ttf | third_party/poppins/Poppins-Light.ttf | (no IDR — on-disk gate asset only; not packaged; D-11 as-needed shim) | 1 | https://github.com/itfoundry/poppins@8.003 | OFL-1.1 | Assertion 1 line 42 |
| Poppins-ExtraBold.ttf | third_party/poppins/Poppins-ExtraBold.ttf | (no IDR — on-disk gate asset only; not packaged; D-11 as-needed shim) | 1 | https://github.com/itfoundry/poppins@8.003 | OFL-1.1 | Assertion 1 line 43 |
| Poppins-Black.ttf | third_party/poppins/Poppins-Black.ttf | (no IDR — on-disk gate asset only; not packaged; D-11 as-needed shim) | 1 | https://github.com/itfoundry/poppins@8.003 | OFL-1.1 | Assertion 1 line 44 |
| SpaceMono-Regular.ttf | third_party/space_mono/SpaceMono-Regular.ttf | IDR_PROMETHEUS_FONT_SPACE_MONO_TTF | 1 | https://github.com/googlefonts/spacemono@1.000 | OFL-1.1 | Assertion 1 line 48 |

**Subtotal: 5 ttf files on disk; 2 packaged IDR rows (IDR_PROMETHEUS_FONT_POPPINS_THIN_TTF, IDR_PROMETHEUS_FONT_SPACE_MONO_TTF)**

---

## Section 3: FA Icons (svg) — WebUI raw subset; ALSO converted to .icon for Views (D-06, D-09)

Location: `chrome/browser/resources/prometheus/svg/fa_*.svg` (69 files)
Also: `chrome/browser/resources/prometheus/vector_icons/fa_*.icon` (69 files — Views)

This section is produced by Plan 14-05 (manifest-driven converter). Count = 69 (curated
subset). IDR names use the pattern `IDR_PROMETHEUS_ICON_FA_<GLYPH>` where GLYPH is the
glyph name uppercased with hyphens replaced by underscores.

| Asset | Repo path (in chromium src) | IDR name | Count | Source (URL@rev) | License | Gate ref |
|-------|-----------------------------|----------|-------|-------------------|---------|----------|
| fa_bolt.svg | chrome/browser/resources/prometheus/svg/fa_bolt.svg | IDR_PROMETHEUS_ICON_FA_BOLT | 1 | https://github.com/FortAwesome/Font-Awesome@6.x | CC-BY-4.0 | Assertion 1 line 51-52; Assertion 4 |
| fa_compass.svg | chrome/browser/resources/prometheus/svg/fa_compass.svg | IDR_PROMETHEUS_ICON_FA_COMPASS | 1 | https://github.com/FortAwesome/Font-Awesome@6.x | CC-BY-4.0 | Assertion 1 line 51-52; Assertion 4 |
| fa_layer_group.svg | chrome/browser/resources/prometheus/svg/fa_layer_group.svg | IDR_PROMETHEUS_ICON_FA_LAYER_GROUP | 1 | https://github.com/FortAwesome/Font-Awesome@6.x | CC-BY-4.0 | Assertion 1 line 51-52; Assertion 4 |
| fa_wand_magic_sparkles.svg | chrome/browser/resources/prometheus/svg/fa_wand_magic_sparkles.svg | IDR_PROMETHEUS_ICON_FA_WAND_MAGIC_SPARKLES | 1 | https://github.com/FortAwesome/Font-Awesome@6.x | CC-BY-4.0 | Assertion 1 line 51-52; Assertion 4 |
| fa_book_open.svg | chrome/browser/resources/prometheus/svg/fa_book_open.svg | IDR_PROMETHEUS_ICON_FA_BOOK_OPEN | 1 | https://github.com/FortAwesome/Font-Awesome@6.x | CC-BY-4.0 | Assertion 1 line 51-52; Assertion 4 |
| fa_highlighter.svg | chrome/browser/resources/prometheus/svg/fa_highlighter.svg | IDR_PROMETHEUS_ICON_FA_HIGHLIGHTER | 1 | https://github.com/FortAwesome/Font-Awesome@6.x | CC-BY-4.0 | Assertion 1 line 51-52; Assertion 4 |
| fa_sidebar_flip.svg | chrome/browser/resources/prometheus/svg/fa_sidebar_flip.svg | IDR_PROMETHEUS_ICON_FA_SIDEBAR_FLIP | 1 | placeholder (Pro-only; no FA Free source) | CC-BY-4.0 | Assertion 1 line 51-52; Assertion 4 |
| fa_arrow_down_to_line.svg | chrome/browser/resources/prometheus/svg/fa_arrow_down_to_line.svg | IDR_PROMETHEUS_ICON_FA_ARROW_DOWN_TO_LINE | 1 | https://github.com/FortAwesome/Font-Awesome@6.x (substituted: arrow-down) | CC-BY-4.0 | Assertion 1 line 51-52; Assertion 4 |
| fa_arrow_left.svg | chrome/browser/resources/prometheus/svg/fa_arrow_left.svg | IDR_PROMETHEUS_ICON_FA_ARROW_LEFT | 1 | https://github.com/FortAwesome/Font-Awesome@6.x | CC-BY-4.0 | Assertion 1 line 51-52; Assertion 4 |
| fa_arrow_right.svg | chrome/browser/resources/prometheus/svg/fa_arrow_right.svg | IDR_PROMETHEUS_ICON_FA_ARROW_RIGHT | 1 | https://github.com/FortAwesome/Font-Awesome@6.x | CC-BY-4.0 | Assertion 1 line 51-52; Assertion 4 |
| fa_arrow_up_from_bracket.svg | chrome/browser/resources/prometheus/svg/fa_arrow_up_from_bracket.svg | IDR_PROMETHEUS_ICON_FA_ARROW_UP_FROM_BRACKET | 1 | https://github.com/FortAwesome/Font-Awesome@6.x | CC-BY-4.0 | Assertion 1 line 51-52; Assertion 4 |
| fa_arrow_up.svg | chrome/browser/resources/prometheus/svg/fa_arrow_up.svg | IDR_PROMETHEUS_ICON_FA_ARROW_UP | 1 | https://github.com/FortAwesome/Font-Awesome@6.x | CC-BY-4.0 | Assertion 1 line 51-52; Assertion 4 |
| fa_bars.svg | chrome/browser/resources/prometheus/svg/fa_bars.svg | IDR_PROMETHEUS_ICON_FA_BARS | 1 | https://github.com/FortAwesome/Font-Awesome@6.x | CC-BY-4.0 | Assertion 1 line 51-52; Assertion 4 |
| fa_calendar_check.svg | chrome/browser/resources/prometheus/svg/fa_calendar_check.svg | IDR_PROMETHEUS_ICON_FA_CALENDAR_CHECK | 1 | https://github.com/FortAwesome/Font-Awesome@6.x | CC-BY-4.0 | Assertion 1 line 51-52; Assertion 4 |
| fa_camera.svg | chrome/browser/resources/prometheus/svg/fa_camera.svg | IDR_PROMETHEUS_ICON_FA_CAMERA | 1 | https://github.com/FortAwesome/Font-Awesome@6.x | CC-BY-4.0 | Assertion 1 line 51-52; Assertion 4 |
| fa_cart_shopping.svg | chrome/browser/resources/prometheus/svg/fa_cart_shopping.svg | IDR_PROMETHEUS_ICON_FA_CART_SHOPPING | 1 | https://github.com/FortAwesome/Font-Awesome@6.x | CC-BY-4.0 | Assertion 1 line 51-52; Assertion 4 |
| fa_check_double.svg | chrome/browser/resources/prometheus/svg/fa_check_double.svg | IDR_PROMETHEUS_ICON_FA_CHECK_DOUBLE | 1 | https://github.com/FortAwesome/Font-Awesome@6.x | CC-BY-4.0 | Assertion 1 line 51-52; Assertion 4 |
| fa_circle_check.svg | chrome/browser/resources/prometheus/svg/fa_circle_check.svg | IDR_PROMETHEUS_ICON_FA_CIRCLE_CHECK | 1 | https://github.com/FortAwesome/Font-Awesome@6.x | CC-BY-4.0 | Assertion 1 line 51-52; Assertion 4 |
| fa_circle_half_stroke.svg | chrome/browser/resources/prometheus/svg/fa_circle_half_stroke.svg | IDR_PROMETHEUS_ICON_FA_CIRCLE_HALF_STROKE | 1 | https://github.com/FortAwesome/Font-Awesome@6.x | CC-BY-4.0 | Assertion 1 line 51-52; Assertion 4 |
| fa_circle_info.svg | chrome/browser/resources/prometheus/svg/fa_circle_info.svg | IDR_PROMETHEUS_ICON_FA_CIRCLE_INFO | 1 | https://github.com/FortAwesome/Font-Awesome@6.x | CC-BY-4.0 | Assertion 1 line 51-52; Assertion 4 |
| fa_circle_minus.svg | chrome/browser/resources/prometheus/svg/fa_circle_minus.svg | IDR_PROMETHEUS_ICON_FA_CIRCLE_MINUS | 1 | https://github.com/FortAwesome/Font-Awesome@6.x | CC-BY-4.0 | Assertion 1 line 51-52; Assertion 4 |
| fa_circle_nodes.svg | chrome/browser/resources/prometheus/svg/fa_circle_nodes.svg | IDR_PROMETHEUS_ICON_FA_CIRCLE_NODES | 1 | https://github.com/FortAwesome/Font-Awesome@6.x | CC-BY-4.0 | Assertion 1 line 51-52; Assertion 4 |
| fa_circle_plus.svg | chrome/browser/resources/prometheus/svg/fa_circle_plus.svg | IDR_PROMETHEUS_ICON_FA_CIRCLE_PLUS | 1 | https://github.com/FortAwesome/Font-Awesome@6.x | CC-BY-4.0 | Assertion 1 line 51-52; Assertion 4 |
| fa_circle_question.svg | chrome/browser/resources/prometheus/svg/fa_circle_question.svg | IDR_PROMETHEUS_ICON_FA_CIRCLE_QUESTION | 1 | https://github.com/FortAwesome/Font-Awesome@6.x | CC-BY-4.0 | Assertion 1 line 51-52; Assertion 4 |
| fa_circle_xmark.svg | chrome/browser/resources/prometheus/svg/fa_circle_xmark.svg | IDR_PROMETHEUS_ICON_FA_CIRCLE_XMARK | 1 | https://github.com/FortAwesome/Font-Awesome@6.x | CC-BY-4.0 | Assertion 1 line 51-52; Assertion 4 |
| fa_copy.svg | chrome/browser/resources/prometheus/svg/fa_copy.svg | IDR_PROMETHEUS_ICON_FA_COPY | 1 | https://github.com/FortAwesome/Font-Awesome@6.x | CC-BY-4.0 | Assertion 1 line 51-52; Assertion 4 |
| fa_eye.svg | chrome/browser/resources/prometheus/svg/fa_eye.svg | IDR_PROMETHEUS_ICON_FA_EYE | 1 | https://github.com/FortAwesome/Font-Awesome@6.x | CC-BY-4.0 | Assertion 1 line 51-52; Assertion 4 |
| fa_folder_plus.svg | chrome/browser/resources/prometheus/svg/fa_folder_plus.svg | IDR_PROMETHEUS_ICON_FA_FOLDER_PLUS | 1 | https://github.com/FortAwesome/Font-Awesome@6.x | CC-BY-4.0 | Assertion 1 line 51-52; Assertion 4 |
| fa_heart_pulse.svg | chrome/browser/resources/prometheus/svg/fa_heart_pulse.svg | IDR_PROMETHEUS_ICON_FA_HEART_PULSE | 1 | https://github.com/FortAwesome/Font-Awesome@6.x | CC-BY-4.0 | Assertion 1 line 51-52; Assertion 4 |
| fa_house.svg | chrome/browser/resources/prometheus/svg/fa_house.svg | IDR_PROMETHEUS_ICON_FA_HOUSE | 1 | https://github.com/FortAwesome/Font-Awesome@6.x | CC-BY-4.0 | Assertion 1 line 51-52; Assertion 4 |
| fa_inbox.svg | chrome/browser/resources/prometheus/svg/fa_inbox.svg | IDR_PROMETHEUS_ICON_FA_INBOX | 1 | https://github.com/FortAwesome/Font-Awesome@6.x | CC-BY-4.0 | Assertion 1 line 51-52; Assertion 4 |
| fa_key.svg | chrome/browser/resources/prometheus/svg/fa_key.svg | IDR_PROMETHEUS_ICON_FA_KEY | 1 | https://github.com/FortAwesome/Font-Awesome@6.x | CC-BY-4.0 | Assertion 1 line 51-52; Assertion 4 |
| fa_keyboard.svg | chrome/browser/resources/prometheus/svg/fa_keyboard.svg | IDR_PROMETHEUS_ICON_FA_KEYBOARD | 1 | https://github.com/FortAwesome/Font-Awesome@6.x | CC-BY-4.0 | Assertion 1 line 51-52; Assertion 4 |
| fa_language.svg | chrome/browser/resources/prometheus/svg/fa_language.svg | IDR_PROMETHEUS_ICON_FA_LANGUAGE | 1 | https://github.com/FortAwesome/Font-Awesome@6.x | CC-BY-4.0 | Assertion 1 line 51-52; Assertion 4 |
| fa_link_slash.svg | chrome/browser/resources/prometheus/svg/fa_link_slash.svg | IDR_PROMETHEUS_ICON_FA_LINK_SLASH | 1 | https://github.com/FortAwesome/Font-Awesome@6.x | CC-BY-4.0 | Assertion 1 line 51-52; Assertion 4 |
| fa_link.svg | chrome/browser/resources/prometheus/svg/fa_link.svg | IDR_PROMETHEUS_ICON_FA_LINK | 1 | https://github.com/FortAwesome/Font-Awesome@6.x | CC-BY-4.0 | Assertion 1 line 51-52; Assertion 4 |
| fa_lock_open.svg | chrome/browser/resources/prometheus/svg/fa_lock_open.svg | IDR_PROMETHEUS_ICON_FA_LOCK_OPEN | 1 | https://github.com/FortAwesome/Font-Awesome@6.x | CC-BY-4.0 | Assertion 1 line 51-52; Assertion 4 |
| fa_lock.svg | chrome/browser/resources/prometheus/svg/fa_lock.svg | IDR_PROMETHEUS_ICON_FA_LOCK | 1 | https://github.com/FortAwesome/Font-Awesome@6.x | CC-BY-4.0 | Assertion 1 line 51-52; Assertion 4 |
| fa_magnifying_glass.svg | chrome/browser/resources/prometheus/svg/fa_magnifying_glass.svg | IDR_PROMETHEUS_ICON_FA_MAGNIFYING_GLASS | 1 | https://github.com/FortAwesome/Font-Awesome@6.x | CC-BY-4.0 | Assertion 1 line 51-52; Assertion 4 |
| fa_microchip.svg | chrome/browser/resources/prometheus/svg/fa_microchip.svg | IDR_PROMETHEUS_ICON_FA_MICROCHIP | 1 | https://github.com/FortAwesome/Font-Awesome@6.x | CC-BY-4.0 | Assertion 1 line 51-52; Assertion 4 |
| fa_microphone.svg | chrome/browser/resources/prometheus/svg/fa_microphone.svg | IDR_PROMETHEUS_ICON_FA_MICROPHONE | 1 | https://github.com/FortAwesome/Font-Awesome@6.x | CC-BY-4.0 | Assertion 1 line 51-52; Assertion 4 |
| fa_moon.svg | chrome/browser/resources/prometheus/svg/fa_moon.svg | IDR_PROMETHEUS_ICON_FA_MOON | 1 | https://github.com/FortAwesome/Font-Awesome@6.x | CC-BY-4.0 | Assertion 1 line 51-52; Assertion 4 |
| fa_note_sticky.svg | chrome/browser/resources/prometheus/svg/fa_note_sticky.svg | IDR_PROMETHEUS_ICON_FA_NOTE_STICKY | 1 | https://github.com/FortAwesome/Font-Awesome@6.x | CC-BY-4.0 | Assertion 1 line 51-52; Assertion 4 |
| fa_palette.svg | chrome/browser/resources/prometheus/svg/fa_palette.svg | IDR_PROMETHEUS_ICON_FA_PALETTE | 1 | https://github.com/FortAwesome/Font-Awesome@6.x | CC-BY-4.0 | Assertion 1 line 51-52; Assertion 4 |
| fa_paste.svg | chrome/browser/resources/prometheus/svg/fa_paste.svg | IDR_PROMETHEUS_ICON_FA_PASTE | 1 | https://github.com/FortAwesome/Font-Awesome@6.x | CC-BY-4.0 | Assertion 1 line 51-52; Assertion 4 |
| fa_pen.svg | chrome/browser/resources/prometheus/svg/fa_pen.svg | IDR_PROMETHEUS_ICON_FA_PEN | 1 | https://github.com/FortAwesome/Font-Awesome@6.x | CC-BY-4.0 | Assertion 1 line 51-52; Assertion 4 |
| fa_plug_circle_xmark.svg | chrome/browser/resources/prometheus/svg/fa_plug_circle_xmark.svg | IDR_PROMETHEUS_ICON_FA_PLUG_CIRCLE_XMARK | 1 | https://github.com/FortAwesome/Font-Awesome@6.x | CC-BY-4.0 | Assertion 1 line 51-52; Assertion 4 |
| fa_plug.svg | chrome/browser/resources/prometheus/svg/fa_plug.svg | IDR_PROMETHEUS_ICON_FA_PLUG | 1 | https://github.com/FortAwesome/Font-Awesome@6.x | CC-BY-4.0 | Assertion 1 line 51-52; Assertion 4 |
| fa_plus.svg | chrome/browser/resources/prometheus/svg/fa_plus.svg | IDR_PROMETHEUS_ICON_FA_PLUS | 1 | https://github.com/FortAwesome/Font-Awesome@6.x | CC-BY-4.0 | Assertion 1 line 51-52; Assertion 4 |
| fa_puzzle_piece.svg | chrome/browser/resources/prometheus/svg/fa_puzzle_piece.svg | IDR_PROMETHEUS_ICON_FA_PUZZLE_PIECE | 1 | https://github.com/FortAwesome/Font-Awesome@6.x | CC-BY-4.0 | Assertion 1 line 51-52; Assertion 4 |
| fa_rotate_left.svg | chrome/browser/resources/prometheus/svg/fa_rotate_left.svg | IDR_PROMETHEUS_ICON_FA_ROTATE_LEFT | 1 | https://github.com/FortAwesome/Font-Awesome@6.x | CC-BY-4.0 | Assertion 1 line 51-52; Assertion 4 |
| fa_rotate_right.svg | chrome/browser/resources/prometheus/svg/fa_rotate_right.svg | IDR_PROMETHEUS_ICON_FA_ROTATE_RIGHT | 1 | https://github.com/FortAwesome/Font-Awesome@6.x | CC-BY-4.0 | Assertion 1 line 51-52; Assertion 4 |
| fa_scissors.svg | chrome/browser/resources/prometheus/svg/fa_scissors.svg | IDR_PROMETHEUS_ICON_FA_SCISSORS | 1 | https://github.com/FortAwesome/Font-Awesome@6.x | CC-BY-4.0 | Assertion 1 line 51-52; Assertion 4 |
| fa_scroll.svg | chrome/browser/resources/prometheus/svg/fa_scroll.svg | IDR_PROMETHEUS_ICON_FA_SCROLL | 1 | https://github.com/FortAwesome/Font-Awesome@6.x | CC-BY-4.0 | Assertion 1 line 51-52; Assertion 4 |
| fa_server.svg | chrome/browser/resources/prometheus/svg/fa_server.svg | IDR_PROMETHEUS_ICON_FA_SERVER | 1 | https://github.com/FortAwesome/Font-Awesome@6.x | CC-BY-4.0 | Assertion 1 line 51-52; Assertion 4 |
| fa_shield.svg | chrome/browser/resources/prometheus/svg/fa_shield.svg | IDR_PROMETHEUS_ICON_FA_SHIELD | 1 | https://github.com/FortAwesome/Font-Awesome@6.x | CC-BY-4.0 | Assertion 1 line 51-52; Assertion 4 |
| fa_sliders.svg | chrome/browser/resources/prometheus/svg/fa_sliders.svg | IDR_PROMETHEUS_ICON_FA_SLIDERS | 1 | https://github.com/FortAwesome/Font-Awesome@6.x | CC-BY-4.0 | Assertion 1 line 51-52; Assertion 4 |
| fa_star_half_stroke.svg | chrome/browser/resources/prometheus/svg/fa_star_half_stroke.svg | IDR_PROMETHEUS_ICON_FA_STAR_HALF_STROKE | 1 | https://github.com/FortAwesome/Font-Awesome@6.x | CC-BY-4.0 | Assertion 1 line 51-52; Assertion 4 |
| fa_star.svg | chrome/browser/resources/prometheus/svg/fa_star.svg | IDR_PROMETHEUS_ICON_FA_STAR | 1 | https://github.com/FortAwesome/Font-Awesome@6.x | CC-BY-4.0 | Assertion 1 line 51-52; Assertion 4 |
| fa_stop.svg | chrome/browser/resources/prometheus/svg/fa_stop.svg | IDR_PROMETHEUS_ICON_FA_STOP | 1 | https://github.com/FortAwesome/Font-Awesome@6.x | CC-BY-4.0 | Assertion 1 line 51-52; Assertion 4 |
| fa_table_cells_large.svg | chrome/browser/resources/prometheus/svg/fa_table_cells_large.svg | IDR_PROMETHEUS_ICON_FA_TABLE_CELLS_LARGE | 1 | https://github.com/FortAwesome/Font-Awesome@6.x | CC-BY-4.0 | Assertion 1 line 51-52; Assertion 4 |
| fa_table.svg | chrome/browser/resources/prometheus/svg/fa_table.svg | IDR_PROMETHEUS_ICON_FA_TABLE | 1 | https://github.com/FortAwesome/Font-Awesome@6.x | CC-BY-4.0 | Assertion 1 line 51-52; Assertion 4 |
| fa_tag.svg | chrome/browser/resources/prometheus/svg/fa_tag.svg | IDR_PROMETHEUS_ICON_FA_TAG | 1 | https://github.com/FortAwesome/Font-Awesome@6.x | CC-BY-4.0 | Assertion 1 line 51-52; Assertion 4 |
| fa_thumbtack.svg | chrome/browser/resources/prometheus/svg/fa_thumbtack.svg | IDR_PROMETHEUS_ICON_FA_THUMBTACK | 1 | https://github.com/FortAwesome/Font-Awesome@6.x | CC-BY-4.0 | Assertion 1 line 51-52; Assertion 4 |
| fa_trash.svg | chrome/browser/resources/prometheus/svg/fa_trash.svg | IDR_PROMETHEUS_ICON_FA_TRASH | 1 | https://github.com/FortAwesome/Font-Awesome@6.x | CC-BY-4.0 | Assertion 1 line 51-52; Assertion 4 |
| fa_triangle_exclamation.svg | chrome/browser/resources/prometheus/svg/fa_triangle_exclamation.svg | IDR_PROMETHEUS_ICON_FA_TRIANGLE_EXCLAMATION | 1 | https://github.com/FortAwesome/Font-Awesome@6.x | CC-BY-4.0 | Assertion 1 line 51-52; Assertion 4 |
| fa_user_secret.svg | chrome/browser/resources/prometheus/svg/fa_user_secret.svg | IDR_PROMETHEUS_ICON_FA_USER_SECRET | 1 | https://github.com/FortAwesome/Font-Awesome@6.x | CC-BY-4.0 | Assertion 1 line 51-52; Assertion 4 |
| fa_vault.svg | chrome/browser/resources/prometheus/svg/fa_vault.svg | IDR_PROMETHEUS_ICON_FA_VAULT | 1 | https://github.com/FortAwesome/Font-Awesome@6.x | CC-BY-4.0 | Assertion 1 line 51-52; Assertion 4 |
| fa_volume_high.svg | chrome/browser/resources/prometheus/svg/fa_volume_high.svg | IDR_PROMETHEUS_ICON_FA_VOLUME_HIGH | 1 | https://github.com/FortAwesome/Font-Awesome@6.x | CC-BY-4.0 | Assertion 1 line 51-52; Assertion 4 |
| fa_volume_xmark.svg | chrome/browser/resources/prometheus/svg/fa_volume_xmark.svg | IDR_PROMETHEUS_ICON_FA_VOLUME_XMARK | 1 | https://github.com/FortAwesome/Font-Awesome@6.x | CC-BY-4.0 | Assertion 1 line 51-52; Assertion 4 |
| fa_wrench.svg | chrome/browser/resources/prometheus/svg/fa_wrench.svg | IDR_PROMETHEUS_ICON_FA_WRENCH | 1 | https://github.com/FortAwesome/Font-Awesome@6.x | CC-BY-4.0 | Assertion 1 line 51-52; Assertion 4 |
| fa_xmark.svg | chrome/browser/resources/prometheus/svg/fa_xmark.svg | IDR_PROMETHEUS_ICON_FA_XMARK | 1 | https://github.com/FortAwesome/Font-Awesome@6.x | CC-BY-4.0 | Assertion 1 line 51-52; Assertion 4 |

**Subtotal: 69 FA SVG files; 69 IDR rows (owned by Plan 14-05)**

Special cases (embedded in the 69):
- `fa_arrow_down_to_line` — arrow-down-to-line is missing from FA Free 6.x solid; substituted with arrow-down.svg source (D-08)
- `fa_sidebar_flip` — Pro-only, not in FA Free 6.x; bundled as a custom placeholder SVG (D-08)

---

## Section 4: Brand Marks (png + svg) — PM monogram, wordmark, FSB logos

Location: `chrome/browser/resources/prometheus/images/`

PNG files satisfy the Wave 0 gate + about/Finder/app-icon raster contexts.
SVG sources serve crisp WebUI rendering. Both formats ship per mark.

| Asset | Repo path (in chromium src) | IDR name | Count | Source (URL@rev) | License | Gate ref |
|-------|-----------------------------|----------|-------|-------------------|---------|----------|
| pm_mark_dark.png | chrome/browser/resources/prometheus/images/pm_mark_dark.png | IDR_PROMETHEUS_ASSET_PM_MARK_DARK | 1 | assets/prometheus.svg (rasterized) | Product-owned | Assertion 1 line 55 |
| pm_mark_light.png | chrome/browser/resources/prometheus/images/pm_mark_light.png | IDR_PROMETHEUS_ASSET_PM_MARK_LIGHT | 1 | assets/prometheus.svg (recolored to #1f1a17, rasterized) | Product-owned | Assertion 1 line 56 |
| pm_wordmark_dark.png | chrome/browser/resources/prometheus/images/pm_wordmark_dark.png | IDR_PROMETHEUS_ASSET_PM_WORDMARK_DARK | 1 | assets/prometheus-wordmark.svg (rasterized) | Product-owned | Assertion 1 line 57 |
| pm_wordmark_light.png | chrome/browser/resources/prometheus/images/pm_wordmark_light.png | IDR_PROMETHEUS_ASSET_PM_WORDMARK_LIGHT | 1 | assets/prometheus-wordmark-light.svg (rasterized) | Product-owned | Assertion 1 line 58 |
| fsb_logo_dark.png | chrome/browser/resources/prometheus/images/fsb_logo_dark.png | IDR_PROMETHEUS_ASSET_FSB_LOGO_DARK | 1 | assets/fsb_logo_dark.png | Product-owned | Assertion 1 line 61 |
| fsb_logo_light.png | chrome/browser/resources/prometheus/images/fsb_logo_light.png | IDR_PROMETHEUS_ASSET_FSB_LOGO_LIGHT | 1 | assets/fsb_logo_light.png | Product-owned | Assertion 1 line 62 |
| fsb_icon.png | chrome/browser/resources/prometheus/images/fsb_icon.png | IDR_PROMETHEUS_ASSET_FSB_ICON | 1 | .planning/design/prometheus-browser/prometheus/assets/fsb_icon.png | Product-owned | (no gate assertion; ships alongside) |
| pm_mark_dark.svg | chrome/browser/resources/prometheus/images/pm_mark_dark.svg | (SVG source; no IDR — WebUI inline) | 1 | assets/prometheus.svg | Product-owned | (no gate assertion; WebUI source) |
| pm_mark_light.svg | chrome/browser/resources/prometheus/images/pm_mark_light.svg | (SVG source; no IDR — WebUI inline) | 1 | assets/prometheus.svg (recolored #1f1a17) | Product-owned | (no gate assertion; real light variant per DESIGN-05) |
| pm_wordmark_dark.svg | chrome/browser/resources/prometheus/images/pm_wordmark_dark.svg | (SVG source; no IDR — WebUI inline) | 1 | assets/prometheus-wordmark.svg | Product-owned | (no gate assertion; WebUI source) |
| pm_wordmark_light.svg | chrome/browser/resources/prometheus/images/pm_wordmark_light.svg | (SVG source; no IDR — WebUI inline) | 1 | assets/prometheus-wordmark-light.svg | Product-owned | (no gate assertion; WebUI source) |

**Subtotal: 7 PNG files (6 gate-required + fsb_icon); 4 SVG sources alongside PNGs**

Notes:
- pm_mark_light.png/svg MUST be a REAL light-context variant (dark ink #1f1a17 on transparent/light surface), NOT a copy of pm_mark_dark — DESIGN-05 / Phase 14 success criterion #4.
- Gate requires exactly the names `pm_wordmark_dark.png` and `pm_wordmark_light.png` (NOT `prometheus_wordmark_*`).

---

## Summary Counts

| Section | Files | Packaged IDRs |
|---------|-------|---------------|
| Fonts (woff2) | 5 | 5 |
| Fonts (ttf) | 5 | 2 (Thin + SpaceMono only; 3 Light/ExtraBold/Black have no IDR) |
| FA icons (svg + icon) | 69 each | 69 (14-05 owns) |
| Brand marks (png + svg) | 7 PNG + 4 SVG | 7 IDR |
| **Total** | **155 files** | **83 packaged IDRs** |

---

## Gate Reference

All Assertion 1 checks (verify-asset-pipeline.sh lines 35-62) map to rows in this manifest:

- Lines 35-38: Poppins woff2 (Section 1)
- Lines 41-44: Poppins ttf at third_party ROOT (Section 2)
- Lines 47-48: SpaceMono woff2 + ttf (Sections 1 + 2)
- Lines 51-52: FA SVG subset >=1 (Section 3; full count gate owned by 14-05)
- Lines 55-56: pm_mark_{dark,light}.png (Section 4)
- Lines 57-58: pm_wordmark_{dark,light}.png (Section 4)
- Lines 61-62: fsb_logo_{dark,light}.png (Section 4)
