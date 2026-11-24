# Bundled fonts

Inter, Roboto, Open Sans, Lexend and Libre Baskerville are bundled for offline use from the
[official Google Fonts repository](https://github.com/google/fonts/tree/cc5661d43cd4f9aad5567033a8e15ca28dc35c86/ofl).
Each family includes its original OFL.txt license, registered with Flutter's
license registry. Settings > About AskAgain opens the standard license page.

`tool/prepare_fonts.py` prepares static regular (400), semibold (600) and bold
(700) instances using fonttools 4.68.0. Other variable axes use the original
font's defaults. The script pins the source commit for reproducible assets.
The app loads these assets directly; it does not fetch fonts at runtime.
