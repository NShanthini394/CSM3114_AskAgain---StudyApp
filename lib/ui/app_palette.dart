import 'package:flutter/painting.dart';

class AppPalette {
  const AppPalette(this.dark);
  final bool dark;

  Color get background => Color(dark ? 0xff111827 : 0xfff7f9fc);
  Color get card => Color(dark ? 0xff263e5d : 0xffdce8fc);
  Color get border => Color(dark ? 0xff7795bb : 0xff647fa3);
  Color get text => Color(dark ? 0xfff2f6ff : 0xff17263f);

  Color folder(int index) => (dark
      ? const [
          Color(0xff253f64),
          Color(0xff1d4946),
          Color(0xff40365d),
          Color(0xff4e3b2c),
        ]
      : const [
          Color(0xffdce8fc),
          Color(0xffd5f2ed),
          Color(0xffece2ff),
          Color(0xffffe9db),
        ])[index % 4];

  Color folderAccent(int index) => (dark
      ? const [
          Color(0xffb1caff),
          Color(0xff9ce5da),
          Color(0xffdbc4ff),
          Color(0xffffd2a4),
        ]
      : const [
          Color(0xff335ccf),
          Color(0xff006e66),
          Color(0xff7548b5),
          Color(0xff995523),
        ])[index % 4];
}
