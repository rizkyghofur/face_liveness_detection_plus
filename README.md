# Face Liveness Detection Plus

A real-time facial verification package for Flutter using Google ML Kit for liveness detection. It ensures user interaction through smiling, blinking, and head movements. Key capabilities include real-time face detection, dynamic UI feedback, countdown timers, manual/programmatic capture control via `FaceCaptureController`, and image path retrieval for secure authentication and anti-spoofing verification.

## Features

- **Real-Time Detection**: Fast and accurate face detection powered by Google ML Kit with configurable `performanceMode` (`fast` or `accurate`).
- **Configurable Thresholds**: Customize sensitivity thresholds for smiling, blinking, and head movements via `LivenessThresholds`.
- **Localization & Instructions**: Easily customize or translate instruction texts via `LivenessLocalization`.
- **Custom UI Overlay**: Replace default dotted border with custom `customOverlayBuilder`.
- **Liveness Controller**: Isolated logic and state controller `LivenessDetectionController` for testing and custom UI integration.
- **Dynamic Feedback**: Real-time visual UI feedback for each verification rule.
- **Animated Transitions**: Smooth progress animations during rule evaluation.
- **Countdown Timer**: Built-in countdown timer before verification completes.
- **Capture Controller**: Flexible manual or automatic image capture control (`FaceCaptureController`).
- **Accuracy Calculation**: Computes confidence/accuracy percentage per completed rule.

## Installation

Add `face_liveness_detection_plus` to your `pubspec.yaml`:

```yaml
dependencies:
  face_liveness_detection_plus: ^1.2.0
```

Run `flutter pub get` to install the package.

## Platform Setup

### iOS

Set your global platform target in `ios/Podfile`:

```ruby
platform :ios, '15.5'
```

Add camera and microphone permission descriptions to `ios/Runner/Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>Camera access is required for real-time face liveness detection.</string>
<key>NSMicrophoneUsageDescription</key>
<string>Microphone access is required for video recording during verification.</string>
```

## Preview

<p align="center">
  <img src="https://github.com/user-attachments/assets/eb0ca715-27f8-4aa5-9e23-fd11825e8960" width="45%" />
  &nbsp;
  <img src="https://github.com/user-attachments/assets/5f6729b3-8ec8-4d2a-b728-bcbb299379ae" width="45%" />
</p>

## Usage Example

### Basic Verification View

```dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:face_liveness_detection_plus/face_liveness_detection_plus.dart';

class FaceVerificationWidget extends StatefulWidget {
  const FaceVerificationWidget({super.key});

  @override
  State<FaceVerificationWidget> createState() => _FaceVerificationWidgetState();
}

class _FaceVerificationWidgetState extends State<FaceVerificationWidget> {
  final List<Rulesets> _completedRuleset = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FaceDetectorView(
        onSuccessValidation: (validated) {},
        onValidationDone: (controller) => const Center(
          child: Text('Verification Complete!'),
        ),
        onRulesetCompleted: (ruleset, imageUrl) {
          if (!_completedRuleset.contains(ruleset)) {
            setState(() => _completedRuleset.add(ruleset));
          }
        },
        child: ({required countdown, required state, required hasFace}) {
          return Column(
            children: [
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.face, size: 30),
                  const SizedBox(width: 10),
                  Text(
                    hasFace ? 'User face found' : 'User face not found',
                    style: _textStyle,
                  ),
                ],
              ),
              const SizedBox(height: 30),
              Text(
                _rulesetHints[state] ?? 'Please follow instructions',
                style: _textStyle.copyWith(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              if (countdown > 0)
                Text(
                  'Timer: $countdown',
                  style: _textStyle.copyWith(fontSize: 16),
                )
              else
                const CupertinoActivityIndicator(),
            ],
          );
        },
      ),
    );
  }
}

const TextStyle _textStyle = TextStyle(
  color: Colors.black,
  fontWeight: FontWeight.w400,
  fontSize: 12,
);

const Map<Rulesets, String> _rulesetHints = {
  Rulesets.smiling: 'Please Smile',
  Rulesets.blink: 'Please Blink',
  Rulesets.tiltUp: 'Please Look Up',
  Rulesets.tiltDown: 'Please Look Down',
  Rulesets.toLeft: 'Please Look Left',
  Rulesets.toRight: 'Please Look Right',
};
```

### Manual Capture using `FaceCaptureController`

```dart
final FaceCaptureController _controller = FaceCaptureController();

FaceDetectorView(
  autoCapture: false,
  controller: _controller,
  onRulesetCompleted: (rule, imageUrl) {
    print('Completed rule: $rule, image: $imageUrl');
  },
  onValidationDone: (controller) => Container(),
  child: ({required countdown, required state, required hasFace}) {
    return ElevatedButton(
      onPressed: () async {
        final result = await _controller.capture(null);
        print('Captured ${result.rule} with accuracy ${result.accuracyPercentage}%');
      },
      child: const Text('Capture Image'),
    );
  },
)
```

## Credits

This package is based on and inspired by the original work of [Roshan Karki](https://github.com/RoshanKarki007) ([facelivenessdetection](https://github.com/RoshanKarki007/facelivenessdetection)). Special thanks for the core implementation of Flutter face liveness detection.

## License

This project is licensed under the MIT License.
