import 'dart:developer';

import 'package:face_liveness_detection_plus/face_liveness_detection_plus.dart';
import 'package:flutter/material.dart';

class FaceDetector extends StatelessWidget {
  const FaceDetector({super.key});

  @override
  Widget build(BuildContext context) {
    return const _FaceDetector();
  }
}

class _FaceDetector extends StatefulWidget {
  const _FaceDetector();

  @override
  State<_FaceDetector> createState() => __FaceDetectorState();
}

class __FaceDetectorState extends State<_FaceDetector> {
  final List<Rulesets> _completedRuleset = [];
  final TextStyle _textStyle = const TextStyle();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Face Liveness Detection'),
        centerTitle: true,
      ),
      body: FaceDetectorView(
        cameraSize: const Size(280, 280),
        pauseDurationInSeconds: 0,
        ruleset: const [
          Rulesets.toRight,
          Rulesets.toLeft,
          Rulesets.smiling,
        ],
        onSuccessValidation: (validated) {
          log('Face verification is completed: $validated', name: 'Validation');
        },
        onValidationDone: (controller) {
          return const Center(
            child: Text(
              'Completed',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          );
        },
        child: ({required countdown, required state, required hasFace}) =>
            Column(
          children: [
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  hasFace ? Icons.check_circle : Icons.warning_amber_rounded,
                  color: hasFace ? Colors.green : Colors.orange,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  hasFace ? 'User face found' : 'User face not found',
                  style: _textStyle.copyWith(
                    color: Colors.black87,
                    fontWeight: FontWeight.w400,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            Text(
              getHintText(state),
              style: _textStyle.copyWith(
                color: Colors.black,
                fontWeight: FontWeight.w600,
                fontSize: 20,
              ),
            ),
          ],
        ),
        onRulesetCompleted: (ruleset, imageUrl) {
          if (!_completedRuleset.contains(ruleset)) {
            _completedRuleset.add(ruleset);
          }
          log('Ruleset completed: $ruleset, Image URL: $imageUrl',
              name: 'RulesetCompletion');
        },
      ),
    );
  }
}

String getHintText(Rulesets state) {
  switch (state) {
    case Rulesets.toRight:
      return 'Please Look Right';
    case Rulesets.toLeft:
      return 'Please Look Left';
    case Rulesets.smiling:
      return 'Please Smile';
    default:
      return '';
  }
}
