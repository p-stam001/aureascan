class IdealRatios {
  // Face Aspect Ratio - ideal is 1.46
  static const double faceAspectRatio = 1.46;

  // Face Horizontal Ratio - ideal is 1.0 (33% : 33% : 33%)
  static const double horizontalThird = 1.0;

  // Face Vertical Ratio - ideal is 1.0 (20% : 20% : 20% : 20% : 20%)
  static const double verticalFifth = 1.0;

  // Classic Golden Ratio (phi)
  static const double goldenRatio = 1.618;

  // Get ideal ratio for a specific ratio type
  static double? getIdealRatio(String ratioType) {
    switch (ratioType) {
      case 'faceAspectRatio':
      case 'Proporção Facial':
        return faceAspectRatio;
      case 'horizontalThird':
      case 'Terços Horizontais':
        return horizontalThird;
      case 'verticalFifth':
      case 'Quintas Verticais':
        return verticalFifth;
      case 'horizontalGoldenRatioLcStoMe':
      case 'horizontalGoldenRatioTrLnMe':
      case 'Proporção Áurea Horizontal (LC-Sto-Me)':
      case 'Proporção Áurea Horizontal (Tr-Ln-Me)':
        return goldenRatio;
      default:
        return null;
    }
  }

  // Get formatted ideal ratio string
  static String getFormattedIdealRatio(String ratioType) {
    final ideal = getIdealRatio(ratioType);
    if (ideal == null) return 'N/A';

    if (ratioType.contains('Horizontal') || ratioType.contains('Terços')) {
      return '33% : 33% : 33%';
    } else if (ratioType.contains('Vertical') ||
        ratioType.contains('Quintas')) {
      return '20% : 20% : 20% : 20% : 20%';
    } else if (ratioType.contains('Aspect') || ratioType.contains('Facial')) {
      return '1 : ${ideal.toStringAsFixed(2)}';
    } else {
      return ideal.toStringAsFixed(3);
    }
  }

  // Calculate deviation from ideal (as percentage)
  static double? calculateDeviation(double? userRatio, String ratioType) {
    final ideal = getIdealRatio(ratioType);
    if (userRatio == null || ideal == null) return null;

    return ((userRatio - ideal) / ideal) * 100;
  }

  // Get status (Short/Balanced/Long or Narrow/Balanced/Wide)
  static String getStatus(double? userRatio, String ratioType) {
    final ideal = getIdealRatio(ratioType);
    if (userRatio == null || ideal == null) return 'N/A';

    final deviation = calculateDeviation(userRatio, ratioType) ?? 0;

    if (ratioType.contains('Aspect') || ratioType.contains('Facial')) {
      // For aspect ratio: Short, Balanced, Long
      if (deviation < -5) return 'Short';
      if (deviation > 5) return 'Long';
      return 'Balanced';
    } else {
      // For horizontal/vertical: Narrow, Balanced, Wide
      if (deviation < -5) return 'Narrow';
      if (deviation > 5) return 'Wide';
      return 'Balanced';
    }
  }
}
