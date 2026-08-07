/// Configuration thresholds for face liveness detection rules.
class LivenessThresholds {
  /// Minimum smile probability threshold (0.0 to 1.0)
  final double smileThreshold;

  /// Eye open probability threshold under which an eye is considered closed/blinking (0.0 to 1.0)
  final double blinkThreshold;

  /// Head tilt up threshold angle in degrees (X axis, positive)
  final double headTiltUpThreshold;

  /// Head tilt down threshold angle in degrees (X axis, negative value expected or positive magnitude)
  final double headTiltDownThreshold;

  /// Head turn left threshold angle in degrees (Y axis)
  final double headTurnLeftThreshold;

  /// Head turn right threshold angle in degrees (Y axis)
  final double headTurnRightThreshold;

  /// Minimum ratio of face bounding box area to camera view area (below this is considered too far)
  final double minFaceRatio;

  /// Maximum ratio of face bounding box area to camera view area (above this is considered too close)
  final double maxFaceRatio;

  /// Luminance threshold (0 to 255) below which ambient light is flagged as low light
  final double lowLightThreshold;

  const LivenessThresholds({
    this.smileThreshold = 0.5,
    this.blinkThreshold = 0.6,
    this.headTiltUpThreshold = 15.0,
    this.headTiltDownThreshold = -15.0,
    this.headTurnLeftThreshold = 25.0,
    this.headTurnRightThreshold = -25.0,
    this.minFaceRatio = 0.15,
    this.maxFaceRatio = 0.70,
    this.lowLightThreshold = 40.0,
  });
}
