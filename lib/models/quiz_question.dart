class QuizQuestion {
  final int? id;
  final String type; // listening, reading, grammar, vocabulary
  final String question;
  final List<String> options;
  final int correctIndex;
  final String? explanation;
  final String? difficulty; // easy, medium, hard
  final String? category; // IELTS, CET4, CET6, etc.
  final String? audioUrl;

  const QuizQuestion({
    this.id,
    required this.type,
    required this.question,
    required this.options,
    required this.correctIndex,
    this.explanation,
    this.difficulty,
    this.category,
    this.audioUrl,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      id: json['id'] as int?,
      type: json['type'] as String,
      question: json['question'] as String,
      options: (json['options'] as List<dynamic>)
          .map((e) => e.toString())
          .toList(),
      correctIndex: json['correct_index'] as int,
      explanation: json['explanation'] as String?,
      difficulty: json['difficulty'] as String?,
      category: json['category'] as String?,
      audioUrl: json['audio_url'] as String?,
    );
  }

  Map<String, dynamic> toDbMap() {
    return {
      'type': type,
      'question': question,
      'options': options.join('\x00'),
      'correct_index': correctIndex,
      'explanation': explanation,
      'difficulty': difficulty,
      'category': category,
      'audio_url': audioUrl,
    };
  }

  factory QuizQuestion.fromDbMap(Map<String, dynamic> map) {
    return QuizQuestion(
      id: map['id'] as int?,
      type: map['type'] as String,
      question: map['question'] as String,
      options: (map['options'] as String).split('\x00'),
      correctIndex: map['correct_index'] as int,
      explanation: map['explanation'] as String?,
      difficulty: map['difficulty'] as String?,
      category: map['category'] as String?,
      audioUrl: map['audio_url'] as String?,
    );
  }
}
