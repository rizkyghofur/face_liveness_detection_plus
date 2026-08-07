import 'package:face_liveness_detection_plus/src/rule_set/rule_set.dart';

/// Customizable localization strings for UI instructions.
class LivenessLocalization {
  final String smileInstruction;
  final String blinkInstruction;
  final String tiltUpInstruction;
  final String tiltDownInstruction;
  final String turnLeftInstruction;
  final String turnRightInstruction;
  final String noFaceDetectedText;
  final String tooCloseText;
  final String tooFarText;
  final String multipleFacesText;
  final String lowLightText;

  const LivenessLocalization({
    this.smileInstruction = 'Please smile',
    this.blinkInstruction = 'Please blink your eyes',
    this.tiltUpInstruction = 'Please tilt your head up',
    this.tiltDownInstruction = 'Please tilt your head down',
    this.turnLeftInstruction = 'Please turn your head left',
    this.turnRightInstruction = 'Please turn your head right',
    this.noFaceDetectedText = 'No face detected',
    this.tooCloseText = 'Face is too close',
    this.tooFarText = 'Face is too far',
    this.multipleFacesText = 'Only 1 face allowed',
    this.lowLightText = 'Low lighting environment',
  });

  /// Helper to get instruction for a specific rule
  String getInstruction(Rulesets rule) {
    switch (rule) {
      case Rulesets.smiling:
        return smileInstruction;
      case Rulesets.blink:
        return blinkInstruction;
      case Rulesets.tiltUp:
        return tiltUpInstruction;
      case Rulesets.tiltDown:
        return tiltDownInstruction;
      case Rulesets.toLeft:
        return turnLeftInstruction;
      case Rulesets.toRight:
        return turnRightInstruction;
    }
  }
}
