import 'package:flutter/material.dart';
import 'package:face_liveness_detection_plus/face_liveness_detection_plus.dart';

class ControllerExample extends StatefulWidget {
  const ControllerExample({super.key});

  @override
  State<ControllerExample> createState() => _ControllerExampleState();
}

class _ControllerExampleState extends State<ControllerExample> {
  final FaceCaptureController _controller = FaceCaptureController();
  final List<FaceCaptureResult> _capturedResults = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Face Capture Controller Example'),
      ),
      body: Column(
        children: [
          // Face Detection Widget
          Expanded(
            flex: 3,
            child: FaceDetectorView(
              autoCapture: false, // Manual control
              controller: _controller,
              onRulesetCompleted: (rule, imageUrl) {
                debugPrint('Rule completed: $rule, Image: $imageUrl');
              },
              onValidationDone: (controller) => Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text('All rules completed!'),
                    ElevatedButton(
                      onPressed: () => _showResults(),
                      child: const Text('View Results'),
                    ),
                  ],
                ),
              ),
              child: ({required state, required countdown, required hasFace}) {
                return Column(
                  children: [
                    Text('Current rule: ${_getRuleHint(state)}'),
                    if (countdown > 0) Text('Countdown: $countdown'),
                    Text('Face detected: $hasFace'),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          onPressed: () => _captureCurrentRule(),
                          child: const Text('Capture'),
                        ),
                        ElevatedButton(
                          onPressed: () => _controller.pause(),
                          child: const Text('Pause'),
                        ),
                        ElevatedButton(
                          onPressed: () => _controller.resume(),
                          child: const Text('Resume'),
                        ),
                        ElevatedButton(
                          onPressed: () => _controller.reset(),
                          child: const Text('Reset'),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
          // Results section
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Captured Results: ${_capturedResults.length}'),
                  if (_capturedResults.isNotEmpty)
                    Expanded(
                      child: ListView.builder(
                        itemCount: _capturedResults.length,
                        itemBuilder: (context, index) {
                          final result = _capturedResults[index];
                          return ListTile(
                            title: Text('${result.rule} - ${result.accuracyPercentage.toStringAsFixed(1)}%'),
                            subtitle: Text(result.imageUrl ?? 'No image'),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getRuleHint(Rulesets rule) {
    switch (rule) {
      case Rulesets.smiling:
        return 'Please smile';
      case Rulesets.blink:
        return 'Please blink';
      case Rulesets.tiltUp:
        return 'Please look up';
      case Rulesets.tiltDown:
        return 'Please look down';
      case Rulesets.toLeft:
        return 'Please look left';
      case Rulesets.toRight:
        return 'Please look right';
    }
  }

  Future<void> _captureCurrentRule() async {
    try {
      final result = await _controller.capture(null); // Capture current rule
      if (!mounted) return;
      setState(() {
        _capturedResults.add(result);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Captured: ${result.rule} (${result.accuracyPercentage.toStringAsFixed(1)}%)')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _showResults() {
    final results = _controller.getImages();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('All Captured Results'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: results.length,
            itemBuilder: (context, index) {
              final result = results[index];
              return ListTile(
                title: Text('${result.rule}'),
                subtitle: Text('Accuracy: ${result.accuracyPercentage.toStringAsFixed(1)}%'),
                trailing: result.imageUrl != null 
                  ? const Icon(Icons.image)
                  : const Icon(Icons.error),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
