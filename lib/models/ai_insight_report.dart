import 'dart:convert';

/// Represents a specific pillar evaluation in the AI Nutrition Coach report.
class AiInsightPillar {
  final String category;
  final String status; // 'optimal', 'warning', 'needs_attention'
  final String title;
  final String detail;
  final String action;

  const AiInsightPillar({
    required this.category,
    required this.status,
    required this.title,
    required this.detail,
    required this.action,
  });

  factory AiInsightPillar.fromJson(Map<String, dynamic> json) {
    return AiInsightPillar(
      category: json['category']?.toString() ?? '',
      status: json['status']?.toString().toLowerCase() ?? 'optimal',
      title: json['title']?.toString() ?? '',
      detail: json['detail']?.toString() ?? '',
      action: json['action']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'category': category,
        'status': status,
        'title': title,
        'detail': detail,
        'action': action,
      };
}

/// Represents an actionable food recommendation / swap.
class AiFoodSwap {
  final String context;
  final String recommendation;
  final String macros;

  const AiFoodSwap({
    required this.context,
    required this.recommendation,
    required this.macros,
  });

  factory AiFoodSwap.fromJson(Map<String, dynamic> json) {
    return AiFoodSwap(
      context: json['context']?.toString() ?? '',
      recommendation: json['recommendation']?.toString() ?? '',
      macros: json['macros']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'context': context,
        'recommendation': recommendation,
        'macros': macros,
      };
}

/// Structured AI Nutrition Coach report for Calora.
class AiInsightReport {
  final String weeklyGrade;
  final String statusBadge;
  final String headline;
  final String executiveSummary;
  final List<AiInsightPillar> pillars;
  final List<AiFoodSwap> actionableFoodSwaps;
  final String motivationalVerdict;
  final DateTime generatedAt;
  final String? model;

  const AiInsightReport({
    required this.weeklyGrade,
    required this.statusBadge,
    required this.headline,
    required this.executiveSummary,
    required this.pillars,
    required this.actionableFoodSwaps,
    required this.motivationalVerdict,
    required this.generatedAt,
    this.model,
  });

  factory AiInsightReport.fromJson(Map<String, dynamic> json, {String? model}) {
    return AiInsightReport(
      weeklyGrade: json['weeklyGrade']?.toString() ?? 'A',
      statusBadge: json['statusBadge']?.toString() ?? 'Metabolic Balance',
      headline: json['headline']?.toString() ?? '',
      executiveSummary: json['executiveSummary']?.toString() ?? '',
      pillars: (json['pillars'] as List<dynamic>? ?? [])
          .map((p) => AiInsightPillar.fromJson(p as Map<String, dynamic>))
          .toList(),
      actionableFoodSwaps: (json['actionableFoodSwaps'] as List<dynamic>? ?? [])
          .map((s) => AiFoodSwap.fromJson(s as Map<String, dynamic>))
          .toList(),
      motivationalVerdict: json['motivationalVerdict']?.toString() ?? '',
      generatedAt: json['generatedAt'] != null
          ? DateTime.tryParse(json['generatedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      model: model ?? json['model']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'weeklyGrade': weeklyGrade,
        'statusBadge': statusBadge,
        'headline': headline,
        'executiveSummary': executiveSummary,
        'pillars': pillars.map((p) => p.toJson()).toList(),
        'actionableFoodSwaps': actionableFoodSwaps.map((s) => s.toJson()).toList(),
        'motivationalVerdict': motivationalVerdict,
        'generatedAt': generatedAt.toIso8601String(),
        'model': model,
      };

  String serialize() => jsonEncode(toJson());

  static AiInsightReport? deserialize(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return AiInsightReport.fromJson(map);
    } catch (_) {
      return null;
    }
  }
}
