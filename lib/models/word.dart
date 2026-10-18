class Word {
  final int? id;
  final String word;
  final String? phoneticUs;
  final String? phoneticUk;
  final String definition;
  final String? definitionEn;
  final String? partOfSpeech;
  final List<String>? examples;
  final List<String>? phrases;
  final String? level;
  final String? exchange;
  final String? tag;
  final int collins;
  final int oxford;
  final int frequency;

  const Word({
    this.id,
    required this.word,
    this.phoneticUs,
    this.phoneticUk,
    required this.definition,
    this.definitionEn,
    this.partOfSpeech,
    this.examples,
    this.phrases,
    this.level,
    this.exchange,
    this.tag,
    this.collins = 0,
    this.oxford = 0,
    this.frequency = 0,
  });

  factory Word.fromJson(Map<String, dynamic> json) {
    return Word(
      id: json['id'] as int?,
      word: json['word'] as String,
      phoneticUs: json['phonetic_us'] as String?,
      phoneticUk: json['phonetic_uk'] as String?,
      definition: json['definition'] as String,
      definitionEn: json['definition_en'] as String?,
      partOfSpeech: json['part_of_speech'] as String?,
      examples: (json['examples'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      phrases: (json['phrases'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      level: json['level'] as String?,
      exchange: json['exchange'] as String?,
      tag: json['tag'] as String?,
      collins: json['collins'] as int? ?? 0,
      oxford: json['oxford'] as int? ?? 0,
      frequency: json['frequency'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'word': word,
      'phonetic_us': phoneticUs,
      'phonetic_uk': phoneticUk,
      'definition': definition,
      'definition_en': definitionEn,
      'part_of_speech': partOfSpeech,
      'examples': examples,
      'phrases': phrases,
      'level': level,
      'exchange': exchange,
      'tag': tag,
      'collins': collins,
      'oxford': oxford,
      'frequency': frequency,
    };
  }

  Map<String, dynamic> toDbMap() {
    return {
      'word': word,
      'phonetic_us': phoneticUs,
      'phonetic_uk': phoneticUk,
      'definition': definition,
      'definition_en': definitionEn,
      'part_of_speech': partOfSpeech,
      'level': level,
      'exchange': exchange,
      'tag': tag,
      'collins': collins,
      'oxford': oxford,
      'frequency': frequency,
    };
  }

  factory Word.fromDbMap(Map<String, dynamic> map) {
    return Word(
      id: map['id'] as int?,
      word: map['word'] as String,
      phoneticUs: map['phonetic_us'] as String?,
      phoneticUk: map['phonetic_uk'] as String?,
      definition: map['definition'] as String,
      definitionEn: map['definition_en'] as String?,
      partOfSpeech: map['part_of_speech'] as String?,
      level: map['level'] as String?,
      exchange: map['exchange'] as String?,
      tag: map['tag'] as String?,
      collins: map['collins'] as int? ?? 0,
      oxford: map['oxford'] as int? ?? 0,
      frequency: map['frequency'] as int? ?? 0,
    );
  }
}
