## 1.3.0

* **Feature:** Added `LivenessThresholds` for configurable detection sensitivity (smile, blink, head movement angles, face ratio, low light).
* **Feature:** Added `LivenessDetectionController` for headless state management, testing, and ruleset evaluation.
* **Feature:** Added `LivenessLocalization` for customizable and multi-language UI instructions (default English).
* **Feature:** Added `FaceOvalMaskPainter` (`enableDimmedOverlay`) for camera dimmed oval overlay masking.
* **Feature:** Added `FacePositionStatus` (`onFacePositionStatusChanged`) detecting too close, too far, and multiple faces.
* **Feature:** Added low-light ambient check (`onLowLightDetected`).
* **Feature:** Added `randomizeRuleset` option to prevent video playback spoofing.
* **Feature:** Added video recording support (`startVideoRecording`, `stopVideoRecording`) to `FaceCaptureController`.
* **Feature:** Added memory bytes output (`imageBytes`) in `FaceCaptureResult`.
* **Feature:** Added configurable `resolutionPreset`, `onCameraError`, and `onRuleChanged` callbacks.

## 1.2.0

* **Feature:** Added `FaceCaptureController` to support manual and programmatic control of face detection and capture workflows (`capture`, `pause`, `resume`, `reset`, `getImages`).
* **Feature:** `onRulesetCompleted` now returns the captured image file URL (`String? imageUrl`) along with the completed `Rulesets`.
* **Feature:** Added calculation of face pose and expression accuracy percentage (`accuracyPercentage`).
* **Feature:** Introduced `autoCapture` property in `FaceDetectorView` to enable or disable automatic photo capture on rule validation.
* **Credits:** Special thanks to [@danpraise4](https://github.com/danpraise4) for contributing these face capture features and controller enhancements ([PR #4](https://github.com/RoshanKarki007/facelivenessdetection/pull/4)).

## 0.0.1

This is the first version of the application.
