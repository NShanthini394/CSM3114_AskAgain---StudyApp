import 'package:material_ui/material_ui.dart';

import 'app_palette.dart';

ThemeData appTheme(Brightness brightness, {String fontFamily = 'Inter'}) {
  final dark = brightness == Brightness.dark;
  final palette = AppPalette(dark);
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    fontFamily: fontFamily,
    scaffoldBackgroundColor: palette.background,
    colorScheme:
        ColorScheme.fromSeed(
          seedColor: const Color(0xff3657d6),
          brightness: brightness,
        ).copyWith(
          surface: Color(dark ? 0xff172235 : 0xffffffff),
          onSurface: palette.text,
          tertiary: dark ? const Color(0xffffb3b6) : const Color(0xffc5192d),
          secondary: dark ? const Color(0xff67dacc) : const Color(0xff00776c),
        ),
    inputDecorationTheme: const InputDecorationTheme(
      helperMaxLines: 3,
      border: OutlineInputBorder(),
    ),
    cardTheme: CardThemeData(
      color: palette.card,
      surfaceTintColor: Colors.transparent,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: palette.border),
      ),
      margin: const EdgeInsets.symmetric(vertical: 5),
    ),
  );
}
