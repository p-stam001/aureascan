/// File upload response
class FileUploadResponse {
  final String fileId;
  final String fileUrl;

  FileUploadResponse({
    required this.fileId,
    required this.fileUrl,
  });

  factory FileUploadResponse.fromJson(Map<String, dynamic> json) {
    return FileUploadResponse(
      fileId: json['file_id'] as String,
      fileUrl: json['file_url'] as String,
    );
  }
}

/// Analysis job response (when job is created)
class AnalysisJobResponse {
  final String jobId;
  final String status;

  AnalysisJobResponse({
    required this.jobId,
    required this.status,
  });

  factory AnalysisJobResponse.fromJson(Map<String, dynamic> json) {
    return AnalysisJobResponse(
      jobId: json['job_id'] as String,
      status: json['status'] as String,
    );
  }
}

/// Analysis status response (polling/WebSocket)
class AnalysisStatusResponse {
  final String jobId;
  final String status; // pending, processing, completed, failed
  final Map<String, dynamic>? results;
  final String? error;

  AnalysisStatusResponse({
    required this.jobId,
    required this.status,
    this.results,
    this.error,
  });

  factory AnalysisStatusResponse.fromJson(Map<String, dynamic> json) {
    return AnalysisStatusResponse(
      jobId: json['job_id'] as String,
      status: json['status'] as String,
      results: json['results'] as Map<String, dynamic>?,
      error: json['error'] as String?,
    );
  }

  bool get isCompleted => status == 'completed';
  bool get isFailed => status == 'failed';
  bool get isProcessing => status == 'processing';
  bool get isPending => status == 'pending';
}

/// Skin analysis results
class SkinAnalysisResults {
  final SkinFeatureData? redness;
  final SkinFeatureData? oiliness;
  final SkinFeatureData? ageSpot;
  final SkinFeatureData? moisture;
  final SkinFeatureData? acne;
  final SkinPoreData? pore;
  final SkinWrinkleData? wrinkle;
  final SkinAllData? all;
  final int? skinAge;

  SkinAnalysisResults({
    this.redness,
    this.oiliness,
    this.ageSpot,
    this.moisture,
    this.acne,
    this.pore,
    this.wrinkle,
    this.all,
    this.skinAge,
  });

  factory SkinAnalysisResults.fromJson(Map<String, dynamic> json) {
    return SkinAnalysisResults(
      redness: json['redness'] != null 
          ? SkinFeatureData.fromJson(json['redness'] as Map<String, dynamic>)
          : null,
      oiliness: json['oiliness'] != null
          ? SkinFeatureData.fromJson(json['oiliness'] as Map<String, dynamic>)
          : null,
      ageSpot: json['age_spot'] != null
          ? SkinFeatureData.fromJson(json['age_spot'] as Map<String, dynamic>)
          : null,
      moisture: json['moisture'] != null
          ? SkinFeatureData.fromJson(json['moisture'] as Map<String, dynamic>)
          : null,
      acne: json['acne'] != null
          ? SkinFeatureData.fromJson(json['acne'] as Map<String, dynamic>)
          : null,
      pore: json['pore'] != null
          ? SkinPoreData.fromJson(json['pore'] as Map<String, dynamic>)
          : null,
      wrinkle: json['wrinkle'] != null
          ? SkinWrinkleData.fromJson(json['wrinkle'] as Map<String, dynamic>)
          : null,
      all: json['all'] != null
          ? SkinAllData.fromJson(json['all'] as Map<String, dynamic>)
          : null,
      skinAge: json['skin_age'] as int?,
    );
  }
}

/// Skin feature data (simple features)
class SkinFeatureData {
  final String url;
  final double? score;

  SkinFeatureData({
    required this.url,
    this.score,
  });

  factory SkinFeatureData.fromJson(Map<String, dynamic> json) {
    return SkinFeatureData(
      url: json['url'] as String,
      score: json['score'] != null ? (json['score'] as num).toDouble() : null,
    );
  }
}

/// Skin pore data (nested structure)
class SkinPoreData {
  final SkinFeatureData? forehead;
  final SkinFeatureData? nose;
  final SkinFeatureData? cheek;
  final SkinFeatureData? whole;

  SkinPoreData({
    this.forehead,
    this.nose,
    this.cheek,
    this.whole,
  });

  factory SkinPoreData.fromJson(Map<String, dynamic> json) {
    return SkinPoreData(
      forehead: json['forehead'] != null
          ? SkinFeatureData.fromJson(json['forehead'] as Map<String, dynamic>)
          : null,
      nose: json['nose'] != null
          ? SkinFeatureData.fromJson(json['nose'] as Map<String, dynamic>)
          : null,
      cheek: json['cheek'] != null
          ? SkinFeatureData.fromJson(json['cheek'] as Map<String, dynamic>)
          : null,
      whole: json['whole'] != null
          ? SkinFeatureData.fromJson(json['whole'] as Map<String, dynamic>)
          : null,
    );
  }
}

/// Skin wrinkle data (nested structure)
class SkinWrinkleData {
  final SkinFeatureData? forehead;
  final SkinFeatureData? glabellar;
  final SkinFeatureData? crowfeet;
  final SkinFeatureData? periocular;
  final SkinFeatureData? nasolabial;
  final SkinFeatureData? marionette;
  final SkinFeatureData? whole;

  SkinWrinkleData({
    this.forehead,
    this.glabellar,
    this.crowfeet,
    this.periocular,
    this.nasolabial,
    this.marionette,
    this.whole,
  });

  factory SkinWrinkleData.fromJson(Map<String, dynamic> json) {
    return SkinWrinkleData(
      forehead: json['forehead'] != null
          ? SkinFeatureData.fromJson(json['forehead'] as Map<String, dynamic>)
          : null,
      glabellar: json['glabellar'] != null
          ? SkinFeatureData.fromJson(json['glabellar'] as Map<String, dynamic>)
          : null,
      crowfeet: json['crowfeet'] != null
          ? SkinFeatureData.fromJson(json['crowfeet'] as Map<String, dynamic>)
          : null,
      periocular: json['periocular'] != null
          ? SkinFeatureData.fromJson(json['periocular'] as Map<String, dynamic>)
          : null,
      nasolabial: json['nasolabial'] != null
          ? SkinFeatureData.fromJson(json['nasolabial'] as Map<String, dynamic>)
          : null,
      marionette: json['marionette'] != null
          ? SkinFeatureData.fromJson(json['marionette'] as Map<String, dynamic>)
          : null,
      whole: json['whole'] != null
          ? SkinFeatureData.fromJson(json['whole'] as Map<String, dynamic>)
          : null,
    );
  }
}

/// Skin all data
class SkinAllData {
  final double? score;

  SkinAllData({
    this.score,
  });

  factory SkinAllData.fromJson(Map<String, dynamic> json) {
    return SkinAllData(
      score: json['score'] != null ? (json['score'] as num).toDouble() : null,
    );
  }
}

/// Ratio analysis results
class RatioAnalysisResults {
  final RatioFeatureData? faceAspectRatio;
  final RatioFeatureData? verticalFifth;
  final RatioFeatureData? horizontalThird;
  final RatioFeatureData? horizontalGoldenRatioLcStoMe;
  final RatioFeatureData? horizontalGoldenRatioTrLnMe;
  final RatioFeatureData? eyesToMouthWidthRatio;

  RatioAnalysisResults({
    this.faceAspectRatio,
    this.verticalFifth,
    this.horizontalThird,
    this.horizontalGoldenRatioLcStoMe,
    this.horizontalGoldenRatioTrLnMe,
    this.eyesToMouthWidthRatio,
  });

  factory RatioAnalysisResults.fromJson(Map<String, dynamic> json) {
    return RatioAnalysisResults(
      faceAspectRatio: json['face_aspect_ratio'] != null
          ? RatioFeatureData.fromJson(
              json['face_aspect_ratio'] as Map<String, dynamic>)
          : null,
      verticalFifth: json['vertical_fifth'] != null
          ? RatioFeatureData.fromJson(json['vertical_fifth'] as Map<String, dynamic>)
          : null,
      horizontalThird: json['horizontal_third'] != null
          ? RatioFeatureData.fromJson(json['horizontal_third'] as Map<String, dynamic>)
          : null,
      horizontalGoldenRatioLcStoMe:
          json['horizontal_golden_ratio_lc_sto_me'] != null
              ? RatioFeatureData.fromJson(
                  json['horizontal_golden_ratio_lc_sto_me']
                      as Map<String, dynamic>)
              : null,
      horizontalGoldenRatioTrLnMe:
          json['horizontal_golden_ratio_tr_ln_me'] != null
              ? RatioFeatureData.fromJson(
                  json['horizontal_golden_ratio_tr_ln_me']
                      as Map<String, dynamic>)
              : null,
      eyesToMouthWidthRatio: json['eyes_to_mouth_width_ratio'] != null
          ? RatioFeatureData.fromJson(
              json['eyes_to_mouth_width_ratio'] as Map<String, dynamic>)
          : null,
    );
  }
}

/// Ratio feature data
class RatioFeatureData {
  final List<double> rates;
  final String url;

  RatioFeatureData({
    required this.rates,
    required this.url,
  });

  double? get averageRate {
    if (rates.isEmpty) return null;
    return rates.reduce((a, b) => a + b) / rates.length;
  }

  factory RatioFeatureData.fromJson(Map<String, dynamic> json) {
    final dynamic rateValue = json['rate'];
    List<double> parsedRates = [];
    if (rateValue is List) {
      parsedRates = rateValue
          .whereType<num>()
          .map((value) => value.toDouble())
          .toList();
    } else if (rateValue is num) {
      parsedRates = [rateValue.toDouble()];
    }

    return RatioFeatureData(
      rates: parsedRates,
      url: json['url'] as String,
    );
  }
}

/// Retouch analysis results
class RetouchAnalysisResults {
  final String url;

  RetouchAnalysisResults({
    required this.url,
  });

  factory RetouchAnalysisResults.fromJson(Map<String, dynamic> json) {
    return RetouchAnalysisResults(
      url: json['url'] as String,
    );
  }
}
