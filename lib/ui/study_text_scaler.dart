import 'package:flutter/painting.dart';

/// Apply the student's preference in addition to Android's accessibility scale.
class StudyTextScaler extends TextScaler {
  const StudyTextScaler(this.device, this.factor);
  final TextScaler device;
  final double factor;

  @override
  double scale(double fontSize) => device.scale(fontSize) * factor;

  @override
  double get textScaleFactor => scale(14) / 14;

  @override
  bool operator ==(Object other) =>
      other is StudyTextScaler &&
      other.device == device &&
      other.factor == factor;

  @override
  int get hashCode => Object.hash(device, factor);
}
