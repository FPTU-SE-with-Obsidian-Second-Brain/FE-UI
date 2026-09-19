/// Structured study roadmap returned by POST /chat when mode=study_plan.
class StudyPlanCourse {
  final String code;
  final String name;
  final double? credits;
  final String type;
  final String note;

  const StudyPlanCourse({
    required this.code,
    required this.name,
    this.credits,
    this.type = 'core',
    this.note = '',
  });

  factory StudyPlanCourse.fromJson(Map<String, dynamic> json) {
    final creditsRaw = json['credits'];
    double? credits;
    if (creditsRaw is num) credits = creditsRaw.toDouble();
    return StudyPlanCourse(
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? json['code']?.toString() ?? '',
      credits: credits,
      type: json['type']?.toString() ?? 'core',
      note: json['note']?.toString() ?? '',
    );
  }
}

class StudyPlanSemester {
  final int semester;
  final String label;
  final List<StudyPlanCourse> courses;

  const StudyPlanSemester({
    required this.semester,
    required this.label,
    this.courses = const [],
  });

  factory StudyPlanSemester.fromJson(Map<String, dynamic> json) {
    final rawCourses = json['courses'] as List<dynamic>? ?? [];
    return StudyPlanSemester(
      semester: (json['semester'] as num?)?.toInt() ?? 0,
      label: json['label']?.toString() ?? 'Kỳ ${json['semester']}',
      courses: rawCourses
          .whereType<Map>()
          .map((e) => StudyPlanCourse.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}

class StudyPlan {
  final int currentSemester;
  final String goal;
  final List<StudyPlanSemester> semesters;

  const StudyPlan({
    required this.currentSemester,
    required this.goal,
    this.semesters = const [],
  });

  factory StudyPlan.fromJson(Map<String, dynamic> json) {
    final raw = json['semesters'] as List<dynamic>? ?? [];
    return StudyPlan(
      currentSemester: (json['current_semester'] as num?)?.toInt() ?? 0,
      goal: json['goal']?.toString() ?? '',
      semesters: raw
          .whereType<Map>()
          .map((e) => StudyPlanSemester.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}
