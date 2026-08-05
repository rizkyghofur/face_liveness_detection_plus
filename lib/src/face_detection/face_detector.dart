import 'dart:developer' as dev;
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:face_liveness_detection_plus/src/debouncer/debouncer.dart';
import 'package:face_liveness_detection_plus/src/detector_view/detector_view.dart';
import 'package:face_liveness_detection_plus/src/painter/dotted_painter.dart';
import 'package:face_liveness_detection_plus/src/rule_set/rule_set.dart';
import 'package:face_liveness_detection_plus/src/face_capture/face_capture_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class FaceDetectorView extends StatefulWidget {
  final int pauseDurationInSeconds;
  final Size cameraSize;
  final Function(bool validated)? onSuccessValidation;
  final void Function(Rulesets ruleset, String? imageUrl)? onRulesetCompleted;
  final List<Rulesets> ruleset;
  final Color activeProgressColor;
  final Color progressColor;
  final bool autoCapture;
  final FaceCaptureController? controller;

  final Widget Function(
      {required Rulesets state,
      required int countdown,
      required bool hasFace}) child;
  final Widget Function(CameraController? controller) onValidationDone;
  final int totalDots;
  final double dotRadius;
  final Color? backgroundColor;
  final EdgeInsetsGeometry? contextPadding;
  const FaceDetectorView(
      {super.key,
      required this.onRulesetCompleted,
      required this.onValidationDone,
      this.controller,
      this.ruleset = const [
        Rulesets.smiling,
        Rulesets.blink,
        Rulesets.toRight,
        Rulesets.toLeft,
        Rulesets.tiltUp,
        Rulesets.tiltDown
      ],
      required this.child,
      this.progressColor = Colors.green,
      this.activeProgressColor = Colors.red,
      this.totalDots = 60,
      this.dotRadius = 3,
      this.onSuccessValidation,
      this.backgroundColor = Colors.white,
      this.contextPadding,
      this.cameraSize = const Size(200, 200),
      this.pauseDurationInSeconds = 5,
      this.autoCapture = true})
      : assert(ruleset.length != 0, 'Ruleset cannot be empty');

  @override
  State<FaceDetectorView> createState() => _FaceDetectorViewState();
}

class _FaceDetectorViewState extends State<FaceDetectorView> {
  ValueNotifier<List<Rulesets>> ruleset = ValueNotifier<List<Rulesets>>([]);
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
        enableContours: true,
        enableLandmarks: true,
        enableTracking: true,
        performanceMode: FaceDetectorMode.accurate,
        enableClassification: true),
  );
  bool _canProcess = true;
  bool _isBusy = false;
  String? _text;
  final _cameraLensDirection = CameraLensDirection.front;
  late ValueNotifier<Rulesets?> _currentTest;
  Debouncer? _debouncer;
  CameraController? controller;
  bool hasFace = false;
  bool _paused = false;
  final List<FaceCaptureResult> _results = [];
  Face? _lastFace;
  late final List<Rulesets> _initialRules;

  /// Captures an image from the camera and saves it to temporary storage
  Future<String?> _captureImage() async {
    if (controller == null || !controller!.value.isInitialized) {
      return null;
    }

    try {
      final XFile imageFile = await controller!.takePicture();
      final Directory tempDir = await getTemporaryDirectory();
      final String fileName = 'face_capture_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String filePath = path.join(tempDir.path, fileName);
      
      // Copy the image to our desired location
      await imageFile.saveTo(filePath);
      
      return filePath;
    } catch (e) {
      dev.log('Error capturing image: $e', name: 'ImageCapture');
      return null;
    }
  }

  @override
  void dispose() {
    _canProcess = false;
    _faceDetector.close();
    _debouncer?.stop();
    super.dispose();
  }

  @override
  void initState() {
    _initialRules = widget.ruleset.toList();
    ruleset.value = _initialRules.toList();
    _currentTest = ValueNotifier<Rulesets?>(ruleset.value.first);
    _debouncer = Debouncer(
        durationInSeconds: widget.pauseDurationInSeconds,
        onComplete: () =>
            dev.log('Timer is completed', name: 'Photo verification timer'));
    _debouncer?.start();

    widget.controller?.bind(
      onCapture: (Rulesets? rule) async {
        if (_lastFace == null) {
          throw StateError('No face detected. Please ensure a face is visible before capturing.');
        }
        final Rulesets effectiveRule = rule ?? _currentTest.value ?? ruleset.value.first;
        final double accuracy = _computeAccuracy(effectiveRule, _lastFace!);
        final String? imageUrl = await _captureImage();
        final result = FaceCaptureResult(
            rule: effectiveRule, imageUrl: imageUrl, accuracyPercentage: accuracy);
        _results.add(result);
        return result;
      },
      onReset: () {
        _debouncer?.stop();
        _paused = false;
        _results.clear();
        _lastFace = null;
        ruleset.value = _initialRules.toList();
        _currentTest.value = ruleset.value.first;
        _debouncer?.start();
        setState(() {});
      },
      onPause: () {
        _paused = true;
        _debouncer?.stop();
        setState(() {});
      },
      onContinue: () {
        _paused = false;
        if (widget.autoCapture && ruleset.value.isNotEmpty) {
          _debouncer?.start();
        }
        setState(() {});
      },
      onGetImages: () => _results.toList(),
    );

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
        color: widget.backgroundColor ?? Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        child: Container(
            padding: widget.contextPadding ??
                EdgeInsets.symmetric(horizontal: 22, vertical: 16),
            width: double.infinity,
            child: Column(mainAxisSize: MainAxisSize.max, children: [
              ValueListenableBuilder(
                  valueListenable: _currentTest,
                  builder: (context, state, child) {
                    double targetProgress = state != null
                        ? (widget.ruleset.indexOf(state) /
                                widget.ruleset.length)
                            .toDouble()
                        : 1.0;
                    return TweenAnimationBuilder(
                        duration:
                            Duration(milliseconds: 500), // Animation speed
                        tween: Tween<double>(begin: 0, end: targetProgress),
                        builder: (context, animation, _) => CustomPaint(
                            painter: DottedCirclePainter(
                                activeProgressColor: widget.activeProgressColor,
                                progressColor: widget.progressColor,
                                progress: animation,
                                totalDots: widget.totalDots,
                                dotRadius: widget.dotRadius),
                            child: child));
                  },
                  child: Container(
                      height: widget.cameraSize.height,
                      width: widget.cameraSize.width,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                      ),
                      child: DetectorView(
                          cameraSize: widget.cameraSize,
                          onController: (controller_) =>
                              controller = controller_,
                          title: 'Face Detector',
                          text: _text,
                          onImage: _processImage,
                          initialCameraLensDirection: _cameraLensDirection))),
              SizedBox(height: 5),
              ValueListenableBuilder<Rulesets?>(
                  valueListenable: _currentTest,
                  builder: (context, state, child) {
                    if (state != null) {
                      return widget.child(
                          state: state,
                          countdown: _debouncer!.timeLeft,
                          hasFace: hasFace);
                    }
                    return SizedBox.shrink();
                  }),
              AnimatedBuilder(
                  animation: Listenable.merge([_currentTest, ruleset]),
                  builder: (context, child) {
                    if (_currentTest.value == null &&
                        ruleset.value.isEmpty &&
                        controller != null) {
                      return Expanded(
                          child: SizedBox(
                              width: double.infinity,
                              child: widget.onValidationDone(controller)));
                    } else {
                      return SizedBox.shrink();
                    }
                  })
            ])));
  }

  Future<void> _processImage(InputImage inputImage) async {
    if (!_canProcess) return;
    if (_isBusy) return;
    _isBusy = true;
    setState(() {
      _text = '';
    });
    final faces = await _faceDetector.processImage(inputImage);
    hasFace = faces.isNotEmpty;
    _lastFace = faces.isNotEmpty ? faces.first : null;
    
    // Process rules regardless of autoCapture, but only auto-capture when enabled
    if (!_paused && !(_debouncer?.isRunning ?? false)) {
      handleRuleSet(faces);
    }

    if (inputImage.metadata?.size != null &&
        inputImage.metadata?.rotation != null) {
    } else {
      String text = 'Faces found: ${faces.length}\n\n';
      for (final face in faces) {
        text += 'face: ${face.boundingBox}\n\n';
      }
      _text = text;
    }
    _isBusy = false;
    if (mounted) {
      setState(() {});
    }
  }

  void handleRuleSet(List<Face> faces) {
    if (faces.isEmpty) return;
    for (Face face in faces) {
      startRandomizedTime(face);
    }
  }

  Future<void> startRandomizedTime(Face face) async {
    if (ruleset.value.isEmpty) {
      widget.onSuccessValidation?.call(true);
      return;
    } else {
      widget.onSuccessValidation?.call(false);
    }

    var currentRuleset = ruleset.value.removeAt(0);
    bool isDetected = false;
    switch (currentRuleset) {
      case Rulesets.smiling:
        isDetected = _onSmilingDetected(face);
        break;
      case Rulesets.blink:
        isDetected = _onBlinkDetected(face);
        break;
      case Rulesets.tiltUp:
        isDetected = _detectHeadTiltUp(face);
        break;
      case Rulesets.tiltDown:
        isDetected = _detectHeadTiltDown(face);
        break;
      case Rulesets.toLeft:
        isDetected = _detectLeftHeadMovement(face);
        break;
      case Rulesets.toRight:
        isDetected = _detectRightHeadMovement(face);
        break;
    }
    if (!isDetected) {
      ruleset.value.insert(0, currentRuleset);
    } else {
      // Only auto-capture when autoCapture is enabled
      if (widget.autoCapture) {
        String? imageUrl = await _captureImage();
        final double accuracy = _computeAccuracy(currentRuleset, face);
        _results.add(FaceCaptureResult(
            rule: currentRuleset, imageUrl: imageUrl, accuracyPercentage: accuracy));
        // Call the callback with both ruleset and image URL
        widget.onRulesetCompleted?.call(currentRuleset, imageUrl);
      }
      
      if (ruleset.value.isNotEmpty) {
        _currentTest.value = ruleset.value.first;
        if (widget.autoCapture) {
          _debouncer?.start();
        }
      } else {
        _currentTest.value = null;
        _debouncer?.stop();
      }
      HapticFeedback.vibrate();
    }
  }

  bool _detectHeadTiltUp(Face face) {
    return _detectHeadTilt(face, up: true);
  }

  bool _detectHeadTiltDown(Face face) {
    return _detectHeadTilt(face, up: false);
  }

  bool _detectHeadTilt(Face face, {bool up = true}) {
    final double? rotX = face.headEulerAngleX;
    if (rotX == null) return false;

    if (!up) {
      dev.log(rotX.toString(), name: 'Head Movement');
      if (rotX < -20) {
        return true;
      }
    } else {
      if (rotX > 20) {
        return true;
      }
    }
    return false;
  }

  bool _detectRightHeadMovement(Face face) {
    return _detectHeadMovement(face, left: true);
  }

  bool _detectLeftHeadMovement(Face face) {
    return _detectHeadMovement(face, left: false);
  }

  bool _detectHeadMovement(Face face, {bool left = true}) {
    final double? rotY = face.headEulerAngleY;

    if (rotY == null) return false;
    final double adjustedRotY = Platform.isIOS ? -rotY : rotY;

    if (left) {
      if (adjustedRotY < -40) {
        return true;
      }
    } else {
      if (adjustedRotY > 40) {
        return true;
      }
    }
    return false;
  }

  bool _onBlinkDetected(Face face) {
    final double? leftEyeOpenProb = face.leftEyeOpenProbability;
    final double? rightEyeOpenProb = face.rightEyeOpenProbability;
    const double eyeOpenThreshold = 0.6;
    if (leftEyeOpenProb != null && rightEyeOpenProb != null) {
      if (leftEyeOpenProb < eyeOpenThreshold &&
          rightEyeOpenProb < eyeOpenThreshold) {
        return true;
      }
    }
    return false;
  }

  bool _onSmilingDetected(Face face) {
    if (face.smilingProbability != null) {
      final double? smileProb = face.smilingProbability;
      if ((smileProb ?? 0) > .5) {
        return true;
      }
    }
    return false;
  }

  double _computeAccuracy(Rulesets rule, Face face) {
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
        final rotY = Platform.isIOS ? -(face.headEulerAngleY ?? 0.0) : (face.headEulerAngleY ?? 0.0);
        return (rotY >= 0) ? 0 : (-rotY / 50.0 * 100).clamp(0.0, 100.0);
      case Rulesets.toRight:
        final rotY = Platform.isIOS ? -(face.headEulerAngleY ?? 0.0) : (face.headEulerAngleY ?? 0.0);
        return (rotY <= 0) ? 0 : (rotY / 50.0 * 100).clamp(0.0, 100.0);
    }
  }
}
