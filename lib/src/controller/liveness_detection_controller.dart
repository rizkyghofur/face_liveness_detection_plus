import 'dart:io';

import 'package:face_liveness_detection_plus/src/options/face_position_status.dart';
import 'package:face_liveness_detection_plus/src/options/liveness_thresholds.dart';
import 'package:face_liveness_detection_plus/src/rule_set/rule_set.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

/// Controller handling face detection evaluations, ruleset state progression, and accuracy logic.
class LivenessDetectionController extends ChangeNotifier {
  final List<Rulesets> initialRulesets;
  final LivenessThresholds thresholds;

  final bool randomizeRuleset;

  late List<Rulesets> _remainingRulesets;
  Rulesets? _currentRule;
  bool _isCompleted = false;

  LivenessDetectionController({
    required this.initialRulesets,
    this.thresholds = const LivenessThresholds(),
    this.randomizeRuleset = false,
  }) : assert(initialRulesets.isNotEmpty, 'Ruleset list cannot be empty') {
    reset();
  }

  List<Rulesets> get remainingRulesets => List.unmodifiable(_remainingRulesets);
  Rulesets? get currentRule => _currentRule;
  bool get isCompleted => _isCompleted;

  /// Resets the ruleset evaluation pipeline back to initial state.
  void reset() {
    _remainingRulesets = List<Rulesets>.from(initialRulesets);
    if (randomizeRuleset) {
      _remainingRulesets.shuffle();
    }
    _currentRule =
        _remainingRulesets.isNotEmpty ? _remainingRulesets.first : null;
    _isCompleted = false;
    notifyListeners();
  }

  /// Evaluates a face against the currently active rule.
  /// Returns true if rule is satisfied, false otherwise.
  bool evaluateFace(Face face) {
    if (_currentRule == null || _isCompleted) return false;

    final bool detected = checkRuleDetected(_currentRule!, face);
    if (detected) {
      _remainingRulesets.removeAt(0);
      if (_remainingRulesets.isNotEmpty) {
        _currentRule = _remainingRulesets.first;
      } else {
        _currentRule = null;
        _isCompleted = true;
      }
      notifyListeners();
      return true;
    }
    return false;
  }

  /// Evaluates whether a given face satisfies a specific rule using configured thresholds.
  bool checkRuleDetected(Rulesets rule, Face face) {
    switch (rule) {
      case Rulesets.smiling:
        return (face.smilingProbability ?? 0.0) > thresholds.smileThreshold;
      case Rulesets.blink:
        final left = face.leftEyeOpenProbability;
        final right = face.rightEyeOpenProbability;
        if (left != null && right != null) {
          return left < thresholds.blinkThreshold &&
              right < thresholds.blinkThreshold;
        }
        return false;
      case Rulesets.tiltUp:
        final rotX = face.headEulerAngleX;
        return rotX != null && rotX > thresholds.headTiltUpThreshold;
      case Rulesets.tiltDown:
        final rotX = face.headEulerAngleX;
        return rotX != null && rotX < thresholds.headTiltDownThreshold;
      case Rulesets.toLeft:
        return _checkHeadTurn(face, left: true);
      case Rulesets.toRight:
        return _checkHeadTurn(face, left: false);
    }
  }

  bool _checkHeadTurn(Face face, {required bool left}) {
    final rotY = face.headEulerAngleY;
    if (rotY == null) return false;
    final adjustedRotY = Platform.isIOS ? -rotY : rotY;

    if (left) {
      return adjustedRotY > thresholds.headTurnLeftThreshold;
    } else {
      return adjustedRotY < thresholds.headTurnRightThreshold;
    }
  }

  /// Calculates accuracy percentage (0.0 to 100.0) for a given rule and face.
  double computeAccuracy(Rulesets rule, Face face) {
    switch (rule) {
      case Rulesets.smiling:
        return ((face.smilingProbability ?? 0.0) * 100).clamp(0.0, 100.0);
      case Rulesets.blink:
        final left = 1.0 - (face.leftEyeOpenProbability ?? 1.0);
        final right = 1.0 - (face.rightEyeOpenProbability ?? 1.0);
        return (((left + right) / 2) * 100).clamp(0.0, 100.0);
      case Rulesets.tiltUp:
        final rotX = face.headEulerAngleX ?? 0.0;
        return (rotX <= 0) ? 0 : (rotX / 30.0 * 100).clamp(0.0, 100.0);
      case Rulesets.tiltDown:
        final rotX = face.headEulerAngleX ?? 0.0;
        return (rotX >= 0) ? 0 : (-rotX / 30.0 * 100).clamp(0.0, 100.0);
      case Rulesets.toLeft:
        final rotY = Platform.isIOS
            ? -(face.headEulerAngleY ?? 0.0)
            : (face.headEulerAngleY ?? 0.0);
        return (rotY >= 0) ? 0 : (-rotY / 50.0 * 100).clamp(0.0, 100.0);
      case Rulesets.toRight:
        final rotY = Platform.isIOS
            ? -(face.headEulerAngleY ?? 0.0)
            : (face.headEulerAngleY ?? 0.0);
        return (rotY <= 0) ? 0 : (rotY / 50.0 * 100).clamp(0.0, 100.0);
    }
  }

  /// Evaluates face position status relative to camera area size
  FacePositionStatus evaluateFacePosition(Face face, Size cameraSize) {
    final double cameraArea = cameraSize.width * cameraSize.height;
    if (cameraArea <= 0) return FacePositionStatus.normal;
    final double faceArea = face.boundingBox.width * face.boundingBox.height;
    final double ratio = faceArea / cameraArea;

    if (ratio < thresholds.minFaceRatio) {
      return FacePositionStatus.tooFar;
    } else if (ratio > thresholds.maxFaceRatio) {
      return FacePositionStatus.tooClose;
    }
    return FacePositionStatus.normal;
  }
}
