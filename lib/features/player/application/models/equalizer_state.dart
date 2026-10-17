class EqualizerBandState {
  const EqualizerBandState({required this.frequency, required this.gain});

  final double frequency;
  final double gain;
}

class EqualizerState {
  const EqualizerState({
    required this.supported,
    required this.enabled,
    required this.minGain,
    required this.maxGain,
    required this.bands,
  });

  const EqualizerState.unsupported()
    : supported = false,
      enabled = false,
      minGain = -12,
      maxGain = 12,
      bands = const [];

  final bool supported;
  final bool enabled;
  final double minGain;
  final double maxGain;
  final List<EqualizerBandState> bands;
}
