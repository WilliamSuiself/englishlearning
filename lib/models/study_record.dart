class StudyRecord {
  final int? id;
  final String skill; // listening, speaking, reading, writing
  final String exerciseType; // dictation, shadowing, quiz, writing, etc.
  final int totalQuestions;
  final int correctCount;
  final int durationSeconds;
  final DateTime studiedAt;

  const StudyRecord({
    this.id,
    required this.skill,
    required this.exerciseType,
    required this.totalQuestions,
    required this.correctCount,
    required this.durationSeconds,
    required this.studiedAt,
  });

  double get accuracy =>
      totalQuestions > 0 ? correctCount / totalQuestions : 0.0;

  Map<String, dynamic> toDbMap() {
    return {
      'skill': skill,
      'exercise_type': exerciseType,
      'total_questions': totalQuestions,
      'correct_count': correctCount,
      'duration_seconds': durationSeconds,
      'studied_at': studiedAt.toIso8601String(),
    };
  }

  factory StudyRecord.fromDbMap(Map<String, dynamic> map) {
    return StudyRecord(
      id: map['id'] as int?,
      skill: map['skill'] as String,
      exerciseType: map['exercise_type'] as String,
      totalQuestions: map['total_questions'] as int,
      correctCount: map['correct_count'] as int,
      durationSeconds: map['duration_seconds'] as int,
      studiedAt: DateTime.parse(map['studied_at'] as String),
    );
  }
}
