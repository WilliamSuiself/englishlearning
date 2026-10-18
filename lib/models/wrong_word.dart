class WrongWord {
  final int? id;
  final String word;
  final String? definition;
  final String skill; // 在哪个模块答错
  final int wrongCount;
  final DateTime createdAt;
  final DateTime? lastReviewedAt;
  final int? reviewStage; // FSRS 阶段

  const WrongWord({
    this.id,
    required this.word,
    this.definition,
    required this.skill,
    this.wrongCount = 1,
    required this.createdAt,
    this.lastReviewedAt,
    this.reviewStage = 0,
  });

  Map<String, dynamic> toDbMap() {
    return {
      'word': word,
      'definition': definition,
      'skill': skill,
      'wrong_count': wrongCount,
      'created_at': createdAt.toIso8601String(),
      'last_reviewed_at': lastReviewedAt?.toIso8601String(),
      'review_stage': reviewStage,
    };
  }

  factory WrongWord.fromDbMap(Map<String, dynamic> map) {
    return WrongWord(
      id: map['id'] as int?,
      word: map['word'] as String,
      definition: map['definition'] as String?,
      skill: map['skill'] as String,
      wrongCount: map['wrong_count'] as int,
      createdAt: DateTime.parse(map['created_at'] as String),
      lastReviewedAt: map['last_reviewed_at'] != null
          ? DateTime.parse(map['last_reviewed_at'] as String)
          : null,
      reviewStage: map['review_stage'] as int?,
    );
  }
}
