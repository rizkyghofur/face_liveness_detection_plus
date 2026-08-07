import 'dart:developer' as dev;
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:face_liveness_detection_plus/src/controller/liveness_detection_controller.dart';
import 'package:face_liveness_detection_plus/src/debouncer/debouncer.dart';
import 'package:face_liveness_detection_plus/src/detector_view/detector_view.dart';
import 'package:face_liveness_detection_plus/src/face_capture/face_capture_controller.dart';
import 'package:face_liveness_detection_plus/src/localization/liveness_localization.dart';
import 'package:face_liveness_detection_plus/src/options/face_position_status.dart';
import 'package:face_liveness_detection_plus/src/options/liveness_thresholds.dart';
import 'package:face_liveness_detection_plus/src/painter/dotted_painter.dart';
import 'package:face_liveness_detection_plus/src/painter/face_oval_mask_painter.dart';
import 'package:face_liveness_detection_plus/src/rule_set/rule_set.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

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

  /// Mode for face detection performance (fast or accurate)
  final FaceDetectorMode performanceMode;

  /// Custom detection thresholds
  final LivenessThresholds thresholds;

  /// Custom localization strings for UI instructions
  final LivenessLocalization localization;

  /// Optional custom builder for the face camera overlay border
  final Widget Function(BuildContext context, double progress, Widget child)?
      customOverlayBuilder;

  /// Resolution preset for camera feed
  final ResolutionPreset resolutionPreset;

  /// Callback when camera initialization fails
  final Function(Object error)? onCameraError;

  /// Callback fired when active rule changes
  final void Function(Rulesets? currentRule)? onRuleChanged;

  /// Maximum timeout duration for entire verification. Triggers [onTimeout] if exceeded.
  final Duration? timeoutDuration;

  /// Callback when overall verification times out
  final VoidCallback? onTimeout;

  final Widget Function(
      {required Rulesets state,
      required int countdown,
      required bool hasFace}) child;
  final Widget Function(CameraController? controller) onValidationDone;
  final int totalDots;
  final double dotRadius;
  final Color? backgroundColor;
  final EdgeInsetsGeometry? contextPadding;

  /// Whether to randomize ruleset order on initialize/reset
  final bool randomizeRuleset;

  /// Whether to trigger haptic feedback on rule completion
  final bool enableHapticFeedback;

  /// Callback when face position status changes (normal, tooClose, tooFar, multipleFaces)
  final void Function(FacePositionStatus status)? onFacePositionStatusChanged;

  /// Callback when ambient light level is evaluated
  final void Function(bool isLowLight)? onLowLightDetected;

  /// Whether to render a dimmed background overlay around the face oval
  final bool enableDimmedOverlay;

  /// Dimmed overlay color
  final Color overlayDimColor;

  const FaceDetectorView({
    super.key,
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
    this.autoCapture = true,
    this.performanceMode = FaceDetectorMode.accurate,
    this.thresholds = const LivenessThresholds(),
    this.localization = const LivenessLocalization(),
    this.customOverlayBuilder,
    this.resolutionPreset = ResolutionPreset.high,
    this.onCameraError,
    this.onRuleChanged,
    this.timeoutDuration,
    this.onTimeout,
    this.randomizeRuleset = false,
    this.enableHapticFeedback = true,
    this.onFacePositionStatusChanged,
    this.onLowLightDetected,
    this.enableDimmedOverlay = false,
    this.overlayDimColor = const Color.fromRGBO(0, 0, 0, 0.4),
  }) : assert(ruleset.length != 0, 'Ruleset cannot be empty');

  @override
  State<FaceDetectorView> createState() => _FaceDetectorViewState();
}

class _FaceDetectorViewState extends State<FaceDetectorView> {
  late final FaceDetector _faceDetector;
  late final LivenessDetectionController _livenessController;

  ValueNotifier<List<Rulesets>> ruleset = ValueNotifier<List<Rulesets>>([]);
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

  @override
  void initState() {
    super.initState();
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableContours: true,
        enableLandmarks: true,
        enableTracking: true,
        performanceMode: widget.performanceMode,
        enableClassification: true,
      ),
    );

    _livenessController = LivenessDetectionController(
      initialRulesets: widget.ruleset,
      thresholds: widget.thresholds,
      randomizeRuleset: widget.randomizeRuleset,
    );

    _initialRules = widget.ruleset.toList();
    ruleset.value = _livenessController.remainingRulesets.toList();
    _currentTest = ValueNotifier<Rulesets?>(_livenessController.currentRule);

    _debouncer = Debouncer(
      durationInSeconds: widget.pauseDurationInSeconds,
      onComplete: () =>
          dev.log('Timer is completed', name: 'Photo verification timer'),
    );
    _debouncer?.start();

    widget.controller?.bind(
      onCapture: (Rulesets? rule) async {
        if (_lastFace == null) {
          throw StateError(
              'No face detected. Please ensure a face is visible before capturing.');
        }
        final Rulesets effectiveRule =
            rule ?? _currentTest.value ?? ruleset.value.first;
        final double accuracy =
            _livenessController.computeAccuracy(effectiveRule, _lastFace!);
        final captureData = await _captureImage();
        final result = FaceCaptureResult(
            rule: effectiveRule,
            imageUrl: captureData.filePath,
            imageBytes: captureData.bytes,
            accuracyPercentage: accuracy);
        _results.add(result);
        return result;
      },
      onReset: () {
        _debouncer?.stop();
        _paused = false;
        _results.clear();
        _lastFace = null;
        _livenessController.reset();
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
      onStartVideoRecording: () async {
        if (controller == null || !controller!.value.isInitialized) {
          return null;
        }
        try {
          await controller!.startVideoRecording();
          return null;
        } catch (e) {
          dev.log('Error starting video recording: $e', name: 'VideoRecord');
          return null;
        }
      },
      onStopVideoRecording: () async {
        if (controller == null || !controller!.value.isRecordingVideo) {
          return null;
        }
        try {
          final XFile file = await controller!.stopVideoRecording();
          return file.path;
        } catch (e) {
          dev.log('Error stopping video recording: $e', name: 'VideoRecord');
          return null;
        }
      },
    );
  }

  /// Captures an image from the camera and returns file path & byte content
  Future<({String? filePath, Uint8List? bytes})> _captureImage() async {
    if (controller == null || !controller!.value.isInitialized) {
      return (filePath: null, bytes: null);
    }

    try {
      final XFile imageFile = await controller!.takePicture();
      final Uint8List bytes = await imageFile.readAsBytes();
      final Directory tempDir = await getTemporaryDirectory();
      final String fileName =
          'face_capture_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String filePath = path.join(tempDir.path, fileName);

      await imageFile.saveTo(filePath);
      return (filePath: filePath, bytes: bytes);
    } catch (e) {
      dev.log('Error capturing image: $e', name: 'ImageCapture');
      return (filePath: null, bytes: null);
    }
  }

  @override
  void dispose() {
    _canProcess = false;
    _faceDetector.close();
    _livenessController.dispose();
    _debouncer?.stop();
    super.dispose();
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
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            ValueListenableBuilder(
              valueListenable: _currentTest,
              builder: (context, state, child) {
                double targetProgress = state != null
                    ? (widget.ruleset.indexOf(state) / widget.ruleset.length)
                        .toDouble()
                    : 1.0;
                return TweenAnimationBuilder<double>(
                  duration: Duration(milliseconds: 500),
                  tween: Tween<double>(begin: 0, end: targetProgress),
                  builder: (context, animation, _) {
                    if (widget.customOverlayBuilder != null) {
                      return widget.customOverlayBuilder!(
                          context, animation, child!);
                    }
                    return CustomPaint(
                      painter: DottedCirclePainter(
                        activeProgressColor: widget.activeProgressColor,
                        progressColor: widget.progressColor,
                        progress: animation,
                        totalDots: widget.totalDots,
                        dotRadius: widget.dotRadius,
                      ),
                      child: child,
                    );
                  },
                );
              },
              child: Container(
                height: widget.cameraSize.height,
                width: widget.cameraSize.width,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                ),
                child: widget.enableDimmedOverlay
                    ? CustomPaint(
                        foregroundPainter: FaceOvalMaskPainter(
                          overlayColor: widget.overlayDimColor,
                        ),
                        child: DetectorView(
                          cameraSize: widget.cameraSize,
                          resolutionPreset: widget.resolutionPreset,
                          onCameraError: widget.onCameraError,
                          onController: (controller_) => controller = controller_,
                          title: 'Face Detector',
                          text: _text,
                          onImage: _processImage,
                          initialCameraLensDirection: _cameraLensDirection,
                        ),
                      )
                    : DetectorView(
                        cameraSize: widget.cameraSize,
                        resolutionPreset: widget.resolutionPreset,
                        onCameraError: widget.onCameraError,
                        onController: (controller_) => controller = controller_,
                        title: 'Face Detector',
                        text: _text,
                        onImage: _processImage,
                        initialCameraLensDirection: _cameraLensDirection,
                      ),
              ),
            ),
            SizedBox(height: 5),
            ValueListenableBuilder<Rulesets?>(
              valueListenable: _currentTest,
              builder: (context, state, child) {
                if (state != null) {
                  return widget.child(
                    state: state,
                    countdown: _debouncer!.timeLeft,
                    hasFace: hasFace,
                  );
                }
                return SizedBox.shrink();
              },
            ),
            AnimatedBuilder(
              animation: Listenable.merge([_currentTest, ruleset]),
              builder: (context, child) {
                if (_currentTest.value == null &&
                    ruleset.value.isEmpty &&
                    controller != null) {
                  return Expanded(
                    child: SizedBox(
                      width: double.infinity,
                      child: widget.onValidationDone(controller),
                    ),
                  );
                } else {
                  return SizedBox.shrink();
                }
              },
            )
          ],
        ),
      ),
    );
  }

  Future<void> _processImage(InputImage inputImage) async {
    if (!_canProcess) return;
    if (_isBusy) return;
    _isBusy = true;
    setState(() {
      _text = '';
    });

    // Low light analysis
    if (widget.onLowLightDetected != null &&
        inputImage.bytes != null &&
        inputImage.bytes!.isNotEmpty) {
      final bytes = inputImage.bytes!;
      final sampleLength = bytes.length > 5000 ? 5000 : bytes.length;
      double sum = 0;
      for (int i = 0; i < sampleLength; i++) {
        sum += bytes[i];
      }
      final double avgLuminance = sum / sampleLength;
      widget.onLowLightDetected!(
          avgLuminance < widget.thresholds.lowLightThreshold);
    }

    final faces = await _faceDetector.processImage(inputImage);
    hasFace = faces.isNotEmpty;
    _lastFace = faces.isNotEmpty ? faces.first : null;

    if (widget.onFacePositionStatusChanged != null) {
      if (faces.length > 1) {
        widget.onFacePositionStatusChanged!(FacePositionStatus.multipleFaces);
      } else if (faces.isNotEmpty) {
        final status = _livenessController.evaluateFacePosition(
            faces.first, widget.cameraSize);
        widget.onFacePositionStatusChanged!(status);
      } else {
        widget.onFacePositionStatusChanged!(FacePositionStatus.normal);
      }
    }

    if (!_paused && !(_debouncer?.isRunning ?? false)) {
      handleRuleSet(faces);
    }

    if (inputImage.metadata?.size == null ||
        inputImage.metadata?.rotation == null) {
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
    bool isDetected =
        _livenessController.checkRuleDetected(currentRuleset, face);

    if (!isDetected) {
      ruleset.value.insert(0, currentRuleset);
    } else {
      if (widget.autoCapture) {
        final captureData = await _captureImage();
        final double accuracy =
            _livenessController.computeAccuracy(currentRuleset, face);
        _results.add(FaceCaptureResult(
            rule: currentRuleset,
            imageUrl: captureData.filePath,
            imageBytes: captureData.bytes,
            accuracyPercentage: accuracy));
        widget.onRulesetCompleted?.call(currentRuleset, captureData.filePath);
      }

      if (ruleset.value.isNotEmpty) {
        _currentTest.value = ruleset.value.first;
        widget.onRuleChanged?.call(_currentTest.value);
        if (widget.autoCapture) {
          _debouncer?.start();
        }
      } else {
        _currentTest.value = null;
        widget.onRuleChanged?.call(null);
        _debouncer?.stop();
      }
      if (widget.enableHapticFeedback) {
        HapticFeedback.vibrate();
      }
    }
  }
}
