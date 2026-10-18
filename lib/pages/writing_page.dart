import 'dart:math';
import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../models/study_record.dart';

class WritingPage extends StatefulWidget {
  const WritingPage({super.key});

  @override
  State<WritingPage> createState() => _WritingPageState();
}

class _WritingPageState extends State<WritingPage> {
  final _writingController = TextEditingController();
  final List<Map<String, dynamic>> _prompts = [
    {
      'type': 'essay',
      'title': '短文写作',
      'prompt':
          'Write a short paragraph (80-120 words) about your favorite hobby and why you enjoy it.',
      'minWords': 80,
      'maxWords': 120,
    },
    {
      'type': 'translation',
      'title': '翻译练习',
      'prompt':
          '请将以下句子翻译成英文：\n\n"阅读是提高英语能力最有效的方法之一。每天花三十分钟阅读，你的词汇量和语感都会有显著提升。"',
      'minWords': 20,
      'maxWords': 80,
    },
    {
      'type': 'essay',
      'title': '短文写作',
      'prompt':
          'Write a short paragraph (80-120 words) describing a memorable trip you have taken.',
      'minWords': 80,
      'maxWords': 120,
    },
  ];
  int _currentPrompt = 0;
  DateTime? _startTime;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
  }

  int get _wordCount {
    final text = _writingController.text.trim();
    if (text.isEmpty) return 0;
    return text.split(RegExp(r'\s+')).length;
  }

  Future<void> _recordAndNext() async {
    final duration = DateTime.now().difference(_startTime!).inSeconds;
    await DatabaseService.insertStudyRecord(StudyRecord(
      skill: 'writing',
      exerciseType: _prompts[_currentPrompt]['type'] as String,
      totalQuestions: 1,
      correctCount: 1,
      durationSeconds: duration,
      studiedAt: DateTime.now(),
    ));

    if (!mounted) return;
    setState(() {
      _currentPrompt = (_currentPrompt + 1) % _prompts.length;
      _writingController.clear();
      _startTime = DateTime.now();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final prompt = _prompts[_currentPrompt];

    return Scaffold(
      appBar: AppBar(
        title: const Text('写作练习'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints:
                    BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Prompt card
                      Card(
                        elevation: 0,
                        color: theme.colorScheme.primaryContainer,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.edit,
                                      color: theme.colorScheme
                                          .onPrimaryContainer),
                                  const SizedBox(width: 8),
                                  Text(
                                    prompt['title'] as String,
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(
                                      color: theme.colorScheme
                                          .onPrimaryContainer,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                prompt['prompt'] as String,
                                style: TextStyle(
                                  color: theme.colorScheme.onPrimaryContainer
                                      .withValues(alpha: 0.9),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Writing area
                      SizedBox(
                        height: max(160.0, constraints.maxHeight - 220.0),
                        child: TextField(
                          controller: _writingController,
                          maxLines: null,
                          expands: true,
                          textAlignVertical: TextAlignVertical.top,
                          decoration: InputDecoration(
                            hintText: '在此输入你的英文...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignLabelWithHint: true,
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Bottom bar
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '字数: $_wordCount / ${prompt['minWords']}-${prompt['maxWords']}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: _wordCount >= (prompt['minWords'] as int)
                                  ? Colors.green
                                  : theme.colorScheme.outline,
                            ),
                          ),
                          FilledButton(
                            onPressed:
                                _wordCount >= (prompt['minWords'] as int)
                                    ? _recordAndNext
                                    : null,
                            child: const Text('完成本篇'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _writingController.dispose();
    super.dispose();
  }
}
