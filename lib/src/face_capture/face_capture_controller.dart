import 'package:face_liveness_detection_plus/src/rule_set/rule_set.dart';

class FaceCaptureResult {
  final Rulesets rule;
  final String? imageUrl;
  final double accuracyPercentage;
  const FaceCaptureResult({
    required this.rule,
    required this.imageUrl,
    required this.accuracyPercentage,
  });
}

typedef CaptureCallback = Future<FaceCaptureResult> Function(Rulesets? rule);
typedef VoidSyncCallback = void Function();
typedef ResultsProvider = List<FaceCaptureResult> Function();

class FaceCaptureController {
  CaptureCallback? _onCapture;
  VoidSyncCallback? _onReset;
  VoidSyncCallback? _onPause;
  VoidSyncCallback? _onContinue;
  ResultsProvider? _onGetImages;

  void bind({
    required CaptureCallback onCapture,
    required VoidSyncCallback onReset,
    required VoidSyncCallback onPause,
    required VoidSyncCallback onContinue,
    required ResultsProvider onGetImages,
  }) {
    _onCapture = onCapture;
    _onReset = onReset;
    _onPause = onPause;
    _onContinue = onContinue;
    _onGetImages = onGetImages;
  }

  Future<FaceCaptureResult> capture(Rulesets? rule) async {
    if (_onCapture == null) {
      throw StateError('FaceCaptureController is not attached to a FaceDetectorView');
    }
    return _onCapture!(rule);
  }

  void reset() {
    if (_onReset == null) {
      throw StateError('FaceCaptureController is not attached to a FaceDetectorView');
    }
    _onReset!();
  }

  void pause() {
    if (_onPause == null) {
      throw StateError('FaceCaptureController is not attached to a FaceDetectorView');
    }
    _onPause!();
  }

  void resume() {
    if (_onContinue == null) {
      throw StateError('FaceCaptureController is not attached to a FaceDetectorView');
    }
    _onContinue!();
  }

  // Alias that reads closer to user's requested API name
  void continueCapture() => resume();

  List<FaceCaptureResult> getImages() {
    if (_onGetImages == null) {
      throw StateError('FaceCaptureController is not attached to a FaceDetectorView');
    }
    return _onGetImages!();
  }
}
