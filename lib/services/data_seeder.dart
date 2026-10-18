import 'dart:convert';
import 'package:flutter/services.dart';
import 'database_service.dart';
import '../models/word.dart';
import '../models/quiz_question.dart';

class DataSeeder {
  static Future<void> seedIfNeeded() async {
    await _seedWords();
    await _seedExamples();
    await _seedQuizzes();
  }

  static Future<void> _seedWords() async {
    final count = await DatabaseService.getWordCount();
    if (count > 0) return;

    final jsonString = await rootBundle.loadString('assets/data/words_all.json');
    final List<dynamic> jsonList = jsonDecode(jsonString);

    final words = jsonList.map((json) {
      return Word(
        word: json['word'] as String,
        phoneticUs: json['phonetic_us'] as String?,
        definition: json['definition'] as String,
        definitionEn: json['definition_en'] as String?,
        partOfSpeech: json['part_of_speech'] as String?,
        level: json['level'] as String?,
        exchange: json['exchange'] as String?,
        tag: json['tag'] as String?,
        collins: json['collins'] as int? ?? 0,
        oxford: json['oxford'] as int? ?? 0,
        frequency: 0,
      );
    }).toList();

    await DatabaseService.insertWords(words);
  }

  static Future<void> _seedExamples() async {
    final count = await DatabaseService.getExampleCount();
    if (count > 0) return;

    final jsonString =
        await rootBundle.loadString('assets/data/examples.json');
    final Map<String, dynamic> examplesMap = jsonDecode(jsonString);

    // Build word -> id lookup from database
    final allWords = await DatabaseService.getWords();
    final wordToId = <String, int>{};
    for (final w in allWords) {
      if (w.id != null) {
        wordToId[w.word.toLowerCase()] = w.id!;
      }
    }

    final rows = <Map<String, dynamic>>[];
    examplesMap.forEach((word, examples) {
      final wordId = wordToId[word];
      if (wordId == null) return;
      for (final ex in (examples as List<dynamic>)) {
        rows.add({
          'word_id': wordId,
          'example': ex['en'] as String,
          'translation': ex['cn'] as String?,
        });
      }
    });

    // Insert in chunks to avoid oversized batches
    const chunkSize = 2000;
    for (var i = 0; i < rows.length; i += chunkSize) {
      final end = (i + chunkSize < rows.length) ? i + chunkSize : rows.length;
      await DatabaseService.insertWordExamplesBatch(rows.sublist(i, end));
    }
  }

  static Future<void> _seedQuizzes() async {
    final count = await DatabaseService.getQuizCount();
    if (count > 0) return;

    final jsonString = await rootBundle.loadString('assets/data/quizzes.json');
    final List<dynamic> jsonList = jsonDecode(jsonString);

    final quizzes = jsonList.map((json) {
      return QuizQuestion(
        type: json['type'] as String,
        question: json['question'] as String,
        options: (json['options'] as List<dynamic>).map((e) => e.toString()).toList(),
        correctIndex: json['correct_index'] as int,
        explanation: json['explanation'] as String?,
        difficulty: json['difficulty'] as String?,
        category: json['category'] as String?,
      );
    }).toList();

    await DatabaseService.insertQuizQuestions(quizzes);
  }
}
