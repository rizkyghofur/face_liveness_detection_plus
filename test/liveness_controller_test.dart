import 'dart:ui';

import 'package:face_liveness_detection_plus/face_liveness_detection_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

void main() {
  group('LivenessDetectionController Tests', () {
    test('Initializes with provided rulesets', () {
      final controller = LivenessDetectionController(
        initialRulesets: [Rulesets.smiling, Rulesets.blink],
      );

      expect(controller.remainingRulesets,
          equals([Rulesets.smiling, Rulesets.blink]));
      expect(controller.currentRule, equals(Rulesets.smiling));
      expect(controller.isCompleted, isFalse);
    });

    test('Evaluates face smiling rule successfully based on threshold', () {
      final controller = LivenessDetectionController(
        initialRulesets: [Rulesets.smiling],
        thresholds: const LivenessThresholds(smileThreshold: 0.6),
      );

      final facePass = Face(
        boundingBox: Rect.fromLTWH(0, 0, 100, 100),
        landmarks: {},
        contours: {},
        smilingProbability: 0.8,
      );

      final result = controller.evaluateFace(facePass);
      expect(result, isTrue);
      expect(controller.remainingRulesets, isEmpty);
      expect(controller.currentRule, isNull);
      expect(controller.isCompleted, isTrue);
    });

    test('Fails evaluation when face does not meet smile threshold', () {
      final controller = LivenessDetectionController(
        initialRulesets: [Rulesets.smiling],
        thresholds: const LivenessThresholds(smileThreshold: 0.6),
      );

      final faceFail = Face(
        boundingBox: Rect.fromLTWH(0, 0, 100, 100),
        landmarks: {},
        contours: {},
        smilingProbability: 0.4,
      );

      final result = controller.evaluateFace(faceFail);
      expect(result, isFalse);
      expect(controller.currentRule, equals(Rulesets.smiling));
      expect(controller.isCompleted, isFalse);
    });

    test('Reset restores controller state to initial rulesets', () {
      final controller = LivenessDetectionController(
        initialRulesets: [Rulesets.smiling, Rulesets.blink],
      );

      final face = Face(
        boundingBox: Rect.fromLTWH(0, 0, 100, 100),
        landmarks: {},
        contours: {},
        smilingProbability: 0.9,
      );

      controller.evaluateFace(face);
      expect(controller.remainingRulesets.length, equals(1));

      controller.reset();
      expect(controller.remainingRulesets.length, equals(2));
      expect(controller.currentRule, equals(Rulesets.smiling));
      expect(controller.isCompleted, isFalse);
    });

    test('Evaluates face position (tooFar, tooClose, normal)', () {
      final controller = LivenessDetectionController(
        initialRulesets: [Rulesets.smiling],
        thresholds:
            const LivenessThresholds(minFaceRatio: 0.15, maxFaceRatio: 0.70),
      );

      final smallFace = Face(
        boundingBox: const Rect.fromLTWH(0, 0, 20, 20), // area: 400
        landmarks: {},
        contours: {},
      );
      final largeFace = Face(
        boundingBox: const Rect.fromLTWH(0, 0, 180, 180), // area: 32400
        landmarks: {},
        contours: {},
      );
      final normalFace = Face(
        boundingBox: const Rect.fromLTWH(0, 0, 100, 100), // area: 10000
        landmarks: {},
        contours: {},
      );

      const cameraSize = Size(200, 200); // area: 40000

      expect(controller.evaluateFacePosition(smallFace, cameraSize),
          equals(FacePositionStatus.tooFar));
      expect(controller.evaluateFacePosition(largeFace, cameraSize),
          equals(FacePositionStatus.tooClose));
      expect(controller.evaluateFacePosition(normalFace, cameraSize),
          equals(FacePositionStatus.normal));
    });
  });

  group('LivenessLocalization Tests', () {
    test('Returns correct default English instructions', () {
      const loc = LivenessLocalization();
      expect(loc.getInstruction(Rulesets.smiling), equals('Please smile'));
      expect(
          loc.getInstruction(Rulesets.blink), equals('Please blink your eyes'));
    });

    test('Allows custom override strings', () {
      const loc = LivenessLocalization(
        smileInstruction: 'Please smile now',
      );
      expect(loc.getInstruction(Rulesets.smiling), equals('Please smile now'));
    });
  });
}
