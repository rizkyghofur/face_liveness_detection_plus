import 'dart:developer';

import 'package:face_liveness_detection_plus/face_liveness_detection_plus.dart';
import 'package:flutter/cupertino.dart';
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
      appBar: AppBar(),
      body: FaceDetectorView(
          onSuccessValidation: (validated) {
            log('Face verification is completed', name: 'Validation');
          },
          onValidationDone: (controller) {
            return Text('Completed');
          },
          child: ({required countdown, required state, required hasFace}) =>
              Column(
                children: [
                  Text(
                      'dkjsad klsal jdkksja dslakd sakdsa dlksa dsajkldsakljds akdklsjad sakljdsa dslad sajkld sakljdsa ldksak ldjska ldkljsa dsakld jsads'),
                  const SizedBox(height: 20),
                  Row(
                      spacing: 10,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Image.asset('assets/face_verification_icon.png',
                        //     height: 30, width: 30),

                        Flexible(
                            child: AnimatedSize(
                                duration: const Duration(milliseconds: 150),
                                child: Text(
                                  hasFace
                                      ? 'User face found'
                                      : 'User face not found',
                                  style: _textStyle.copyWith(
                                      color: Colors.black,
                                      fontWeight: FontWeight.w400,
                                      fontSize: 12),
                                )))
                      ]),
                  const SizedBox(height: 30),
                  Text(getHintText(state),
                      style: _textStyle.copyWith(
                          color: Colors.black,
                          fontWeight: FontWeight.w600,
                          fontSize: 20)),
                  if (countdown > 0)
                    Text.rich(
                      textAlign: TextAlign.center,
                      TextSpan(children: [
                        const TextSpan(text: 'IN'),
                        const TextSpan(text: '\n'),
                        TextSpan(
                            text: countdown.toString(),
                            style: _textStyle.copyWith(
                                color: Colors.black,
                                fontWeight: FontWeight.w600,
                                fontSize: 22))
                      ]),
                      style: _textStyle.copyWith(
                          color: Colors.black,
                          fontWeight: FontWeight.w600,
                          fontSize: 16),
                    )
                  else ...[
                    const SizedBox(height: 50),
                    const CupertinoActivityIndicator()
                  ]
                ],
              ),
          onRulesetCompleted: (ruleset, imageUrl) {
            if (!_completedRuleset.contains(ruleset)) {
              _completedRuleset.add(ruleset);
            }
            log('Ruleset completed: $ruleset, Image URL: $imageUrl', name: 'RulesetCompletion');
          }),
    );
  }
}

String getHintText(Rulesets state) {
  String hint_ = '';
  switch (state) {
    case Rulesets.smiling:
      hint_ = 'Please Smile';
      break;
    case Rulesets.blink:
      hint_ = 'Please Blink';
      break;
    case Rulesets.tiltUp:
      hint_ = 'Please Look Up';
      break;
    case Rulesets.tiltDown:
      hint_ = 'Please Look Down';
      break;
    case Rulesets.toLeft:
      hint_ = 'Please Look Left';
      break;
    case Rulesets.toRight:
      hint_ = 'Please Look Right';
      break;
  }
  return hint_;
}
