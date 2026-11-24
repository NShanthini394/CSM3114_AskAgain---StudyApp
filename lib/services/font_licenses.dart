import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

void registerFontLicenses() {
  LicenseRegistry.addLicense(() async* {
    for (final family in [
      'Inter',
      'Roboto',
      'OpenSans',
      'Lexend',
      'LibreBaskerville',
    ]) {
      final text = await rootBundle.loadString('assets/fonts/$family/OFL.txt');
      yield LicenseEntryWithLineBreaks(['AskAgain fonts / $family'], text);
    }
  });
}
