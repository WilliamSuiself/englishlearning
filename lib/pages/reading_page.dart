import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import '../services/tts_service.dart';
import '../services/database_service.dart';
import '../models/study_record.dart';

class ReadingPage extends StatefulWidget {
  const ReadingPage({super.key});

  @override
  State<ReadingPage> createState() => _ReadingPageState();
}

class _ReadingPageState extends State<ReadingPage> {
  final _tts = TtsService();
  final _random = Random();
  List<Map<String, dynamic>> _articles = [
    {
      'title': 'The Benefits of Reading',
      'level': 'easy',
      'text': '''Reading is one of the most beneficial activities for the mind. It helps improve vocabulary, enhance comprehension skills, and boost creativity. When we read, we expose ourselves to new ideas and perspectives that we might not encounter in our daily lives.

Regular reading can also reduce stress. Getting lost in a good story can help you forget about your worries and relax. Studies have shown that just six minutes of reading can reduce stress levels by up to 68 percent.

Furthermore, reading improves focus and concentration. In our fast-paced digital world, where attention is constantly divided, reading trains the brain to focus on one thing for an extended period.''',
      'questions': [
        {
          'question': 'What is the main idea of the passage?',
          'options': [
            'Reading is a waste of time',
            'Reading has many benefits for the mind',
            'Reading is only for students',
            'Reading causes stress',
          ],
          'answer': 1,
        },
        {
          'question': 'How much can reading reduce stress levels?',
          'options': ['Up to 38%', 'Up to 48%', 'Up to 68%', 'Up to 88%'],
          'answer': 2,
        },
        {
          'question': 'What does reading improve besides vocabulary?',
          'options': [
            'Focus and concentration',
            'Physical strength',
            'Eyesight',
            'Hearing',
          ],
          'answer': 0,
        },
      ],
    },
    {
      'title': 'The Power of Habits',
      'level': 'medium',
      'text': '''Habits shape our lives more than we realize. Research suggests that about 40 percent of our daily actions are driven by habits rather than conscious decisions. This means that nearly half of what we do each day is on autopilot.

The key to building good habits is to start small. Instead of trying to read for an hour every day, start with just five minutes. Instead of aiming to exercise for two hours, begin with a ten-minute walk. Small habits are easier to maintain and can gradually grow into bigger ones.

It takes an average of 66 days to form a new habit, according to a study by University College London. However, this varies depending on the complexity of the habit and the individual. Simple habits may take as few as 18 days, while more complex ones may take up to 254 days.''',
      'questions': [
        {
          'question': 'What percentage of daily actions are driven by habits?',
          'options': ['20%', '30%', '40%', '50%'],
          'answer': 2,
        },
        {
          'question': 'What is the key to building good habits?',
          'options': [
            'Start big',
            'Start small',
            'Be perfect',
            'Use willpower',
          ],
          'answer': 1,
        },
        {
          'question': 'How long does it take to form a new habit on average?',
          'options': ['21 days', '30 days', '66 days', '100 days'],
          'answer': 2,
        },
      ],
    },
  ];

  int _currentArticle = 0;
  int _currentQuestion = 0;
  int? _selectedAnswer;
  bool _isAnswered = false;
  int _correctCount = 0;
  bool _showReading = true;
  bool _isLoading = true;
  bool _articlesLoaded = false;
  DateTime _startTime = DateTime.now();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_articlesLoaded) {
      _articlesLoaded = true;
      _loadArticles();
    }
  }

  Future<void> _loadArticles() async {
    try {
      final jsonString = await DefaultAssetBundle.of(context)
          .loadString('assets/data/readings.json');
      final List<dynamic> decoded = jsonDecode(jsonString);
      final loaded = decoded.map((e) => e as Map<String, dynamic>).toList();
      loaded.shuffle(_random);
      if (mounted) {
        setState(() {
          _articles = loaded;
          _currentArticle = 0;
          _isLoading = false;
          _resetSession();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _resetSession() {
    _currentQuestion = 0;
    _selectedAnswer = null;
    _isAnswered = false;
    _correctCount = 0;
    _showReading = true;
    _startTime = DateTime.now();
  }

  String _getArticleText(Map<String, dynamic> article) {
    final text = article['text'];
    if (text is List) {
      return text.map((e) => e.toString()).join('\n\n');
    }
    return text.toString();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('阅读练习'), centerTitle: true),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_articles.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('阅读练习'), centerTitle: true),
        body: const Center(child: Text('暂无阅读材料')),
      );
    }

    final article = _articles[_currentArticle];

    return Scaffold(
      appBar: AppBar(
        title: const Text('阅读练习'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _showReading
            ? _buildReadingView(article, theme)
            : _buildQuestionView(article, theme),
      ),
    );
  }

  Widget _buildReadingView(Map<String, dynamic> article, ThemeData theme) {
    final text = _getArticleText(article);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  article['title'] as String,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Chip(
                label: Text(article['level'] as String),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SelectableText(
              text,
              style: theme.textTheme.bodyLarge?.copyWith(height: 1.8),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              IconButton.filledTonal(
                onPressed: () => _tts.speak(text),
                icon: const Icon(Icons.volume_up),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () {
                    setState(() {
                      _showReading = false;
                      _currentQuestion = 0;
                      _correctCount = 0;
                      _selectedAnswer = null;
                      _isAnswered = false;
                    });
                  },
                  child: const Text('开始答题'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionView(Map<String, dynamic> article, ThemeData theme) {
    final questions = article['questions'] as List;
    final q = questions[_currentQuestion];

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LinearProgressIndicator(
            value: (_currentQuestion + 1) / questions.length,
          ),
          const SizedBox(height: 8),
          Text(
            '第 ${_currentQuestion + 1} / ${questions.length} 题',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 24),
          Text(
            q['question'] as String,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.builder(
              itemCount: (q['options'] as List).length,
              itemBuilder: (context, index) {
                final option = q['options'][index];
                final isSelected = _selectedAnswer == index;
                final isCorrect = index == q['answer'];

                Color? color;
                if (_isAnswered) {
                  if (isCorrect) {
                    color = Colors.green.withValues(alpha: 0.1);
                  } else if (isSelected) {
                    color = Colors.red.withValues(alpha: 0.1);
                  }
                }

                return Card(
                  color: color,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: _isAnswered && isCorrect
                          ? Colors.green
                          : _isAnswered && isSelected
                              ? Colors.red
                              : theme.colorScheme.outlineVariant,
                    ),
                  ),
                  child: ListTile(
                    title: Text(option),
                    leading: CircleAvatar(
                      child: Text(String.fromCharCode(65 + index)),
                    ),
                    trailing: _isAnswered && isCorrect
                        ? const Icon(Icons.check, color: Colors.green)
                        : _isAnswered && isSelected
                            ? const Icon(Icons.close, color: Colors.red)
                            : null,
                    onTap: _isAnswered
                        ? null
                        : () {
                            setState(() {
                              _selectedAnswer = index;
                              _isAnswered = true;
                              if (index == q['answer']) {
                                _correctCount++;
                              }
                            });
                          },
                  ),
                );
              },
            ),
          ),
          if (_isAnswered)
            FilledButton(
              onPressed: () {
                if (_currentQuestion + 1 < questions.length) {
                  setState(() {
                    _currentQuestion++;
                    _selectedAnswer = null;
                    _isAnswered = false;
                  });
                } else {
                  _finishReading(questions.length);
                }
              },
              child: Text(
                _currentQuestion + 1 < questions.length ? '下一题' : '完成',
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _finishReading(int total) async {
    final duration = DateTime.now().difference(_startTime).inSeconds;
    await DatabaseService.insertStudyRecord(StudyRecord(
      skill: 'reading',
      exerciseType: 'comprehension',
      totalQuestions: total,
      correctCount: _correctCount,
      durationSeconds: duration,
      studiedAt: DateTime.now(),
    ));

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('阅读练习完成！'),
        content: Text('正确: $_correctCount / $total'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (_currentArticle + 1 < _articles.length) {
                setState(() {
                  _currentArticle++;
                  _resetSession();
                });
              } else {
                setState(() {
                  _articles.shuffle(_random);
                  _currentArticle = 0;
                  _resetSession();
                });
              }
            },
            child: const Text('继续'),
          ),
        ],
      ),
    );
  }
}
