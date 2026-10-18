import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../models/quiz_question.dart';
import '../models/study_record.dart';
import '../services/tts_service.dart';

class QuizPage extends StatefulWidget {
  final bool examMode;

  const QuizPage({super.key, this.examMode = false});

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  final _tts = TtsService();

  // Filter state
  String? _selectedType;
  String? _selectedCategory;
  String? _selectedDifficulty;

  // Quiz state
  List<QuizQuestion> _questions = [];
  int _currentIndex = 0;
  int? _selectedAnswer;
  bool _isAnswered = false;
  int _correctCount = 0;
  DateTime? _startTime;
  bool _isLoading = false;
  bool _inProgress = false;

  // Exam mode state
  int _examDurationSeconds = 0;
  int _remainingSeconds = 0;
  bool _examFinished = false;

  final _typeLabels = {
    'vocabulary': '词汇',
    'grammar': '语法',
    'reading': '阅读',
    'listening': '听力',
  };

  final _difficultyLabels = {
    'easy': '简单',
    'medium': '中等',
    'hard': '困难',
  };

  final _categoryOptions = ['CET4', 'CET6', 'IELTS', 'TOEFL'];

  @override
  void initState() {
    super.initState();
    if (widget.examMode) {
      _startExam();
    }
  }

  Future<void> _loadQuestions() async {
    setState(() => _isLoading = true);
    final questions = await DatabaseService.getQuizQuestions(
      type: _selectedType,
      category: _selectedCategory,
      difficulty: _selectedDifficulty,
      limit: widget.examMode ? 20 : 10,
    );
    questions.shuffle();
    setState(() {
      _questions = questions;
      _isLoading = false;
      _inProgress = true;
      _currentIndex = 0;
      _correctCount = 0;
      _selectedAnswer = null;
      _isAnswered = false;
      _startTime = DateTime.now();
    });
  }

  void _startExam() {
    _examDurationSeconds = 600; // 10 minutes
    _remainingSeconds = _examDurationSeconds;
    _loadQuestions();
    _startTimer();
  }

  void _startTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted || _examFinished) return;
      setState(() => _remainingSeconds--);
      if (_remainingSeconds <= 0) {
        _finishQuiz();
      } else {
        _startTimer();
      }
    });
  }

  void _selectAnswer(int index) {
    if (_isAnswered) return;
    setState(() {
      _selectedAnswer = index;
      _isAnswered = true;
      if (index == _questions[_currentIndex].correctIndex) {
        _correctCount++;
      }
    });
  }

  void _nextQuestion() {
    if (_currentIndex + 1 >= _questions.length) {
      _finishQuiz();
    } else {
      setState(() {
        _currentIndex++;
        _selectedAnswer = null;
        _isAnswered = false;
      });
    }
  }

  Future<void> _finishQuiz() async {
    _examFinished = true;
    final duration = DateTime.now().difference(_startTime!).inSeconds;
    final skill = _selectedType ?? 'mixed';

    await DatabaseService.insertStudyRecord(StudyRecord(
      skill: skill == 'mixed' ? 'quiz' : skill,
      exerciseType: widget.examMode ? 'exam' : 'practice',
      totalQuestions: _questions.length,
      correctCount: _correctCount,
      durationSeconds: duration,
      studiedAt: DateTime.now(),
    ));

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Text(widget.examMode ? '考试结束！' : '练习完成！'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _correctCount >= _questions.length * 0.6
                    ? Icons.celebration
                    : Icons.thumb_up,
                size: 48,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text('正确: $_correctCount / ${_questions.length}'),
              Text(
                  '正确率: ${(_correctCount / _questions.length * 100).toStringAsFixed(0)}%'),
              if (widget.examMode)
                Text('剩余时间: ${_remainingSeconds ~/ 60}m${_remainingSeconds % 60}s')
              else
                Text('用时: ${duration ~/ 60}m${duration % 60}s'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  _inProgress = false;
                  _examFinished = false;
                });
              },
              child: const Text('返回'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                if (widget.examMode) {
                  _startExam();
                } else {
                  _loadQuestions();
                }
              },
              child: const Text('再来一轮'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.examMode ? '模拟考试' : '习题练习'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _inProgress
                ? _buildQuizView(theme)
                : _buildFilterView(theme),
      ),
    );
  }

  Widget _buildFilterView(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(Icons.quiz, size: 64, color: theme.colorScheme.primary),
          const SizedBox(height: 16),
          Text(
            widget.examMode ? '模拟考试模式' : '习题练习',
            style: theme.textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            widget.examMode
                ? '10分钟内完成20道题，测试你的英语水平'
                : '选择题型和难度，开始针对性练习',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.outline,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          // Type filter
          Text('题型', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              FilterChip(
                label: const Text('全部'),
                selected: _selectedType == null,
                onSelected: (_) => setState(() => _selectedType = null),
              ),
              ..._typeLabels.entries.map((e) => FilterChip(
                    label: Text(e.value),
                    selected: _selectedType == e.key,
                    onSelected: (_) => setState(() => _selectedType = e.key),
                  )),
            ],
          ),
          const SizedBox(height: 16),
          // Category filter
          Text('考试类别', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              FilterChip(
                label: const Text('全部'),
                selected: _selectedCategory == null,
                onSelected: (_) => setState(() => _selectedCategory = null),
              ),
              ..._categoryOptions.map((c) => FilterChip(
                    label: Text(c),
                    selected: _selectedCategory == c,
                    onSelected: (_) => setState(() => _selectedCategory = c),
                  )),
            ],
          ),
          const SizedBox(height: 16),
          // Difficulty filter
          Text('难度', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              FilterChip(
                label: const Text('全部'),
                selected: _selectedDifficulty == null,
                onSelected: (_) => setState(() => _selectedDifficulty = null),
              ),
              ..._difficultyLabels.entries.map((e) => FilterChip(
                    label: Text(e.value),
                    selected: _selectedDifficulty == e.key,
                    onSelected: (_) => setState(() => _selectedDifficulty = e.key),
                  )),
            ],
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: _loadQuestions,
            icon: const Icon(Icons.play_arrow),
            label: Text(widget.examMode ? '开始考试' : '开始练习'),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizView(ThemeData theme) {
    final q = _questions[_currentIndex];

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top bar: progress + timer
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: (_currentIndex + 1) / _questions.length,
                ),
              ),
              if (widget.examMode) ...[
                const SizedBox(width: 12),
                Text(
                  '${_remainingSeconds ~/ 60}:${(_remainingSeconds % 60).toString().padLeft(2, '0')}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: _remainingSeconds < 60
                        ? theme.colorScheme.error
                        : theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${_currentIndex + 1} / ${_questions.length}'),
              Text('正确: $_correctCount'),
            ],
          ),
          const SizedBox(height: 16),
          // Tags
          Wrap(
            spacing: 6,
            children: [
              Chip(
                label: Text(_typeLabels[q.type] ?? q.type,
                    style: const TextStyle(fontSize: 11)),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                ),
              if (q.category != null)
                Chip(
                  label: Text(q.category!,
                      style: const TextStyle(fontSize: 11)),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                ),
              if (q.difficulty != null)
                Chip(
                  label: Text(
                    _difficultyLabels[q.difficulty] ?? q.difficulty!,
                    style: const TextStyle(fontSize: 11),
                  ),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                ),
            ],
          ),
          const SizedBox(height: 16),
          // Question
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    q.question,
                    style: theme.textTheme.titleMedium?.copyWith(height: 1.5),
                  ),
                  if (q.type == 'listening') ...[
                    const SizedBox(height: 12),
                    FilledButton.tonalIcon(
                      onPressed: () {
                        final text = q.question.split('You will hear: ')[1]
                            .split('"')[1];
                        _tts.speak(text);
                      },
                      icon: const Icon(Icons.volume_up),
                      label: const Text('播放听力'),
                    ),
                  ],
                  const SizedBox(height: 20),
                  ...List.generate(q.options.length, (index) {
                    final isSelected = _selectedAnswer == index;
                    final isCorrect = index == q.correctIndex;

                    Color? color;
                    BorderSide? side;
                    Widget? trailing;

                    if (_isAnswered) {
                      if (isCorrect) {
                        color = Colors.green.withValues(alpha: 0.1);
                        side = const BorderSide(color: Colors.green);
                        trailing = const Icon(Icons.check, color: Colors.green);
                      } else if (isSelected) {
                        color = Colors.red.withValues(alpha: 0.1);
                        side = const BorderSide(color: Colors.red);
                        trailing = const Icon(Icons.close, color: Colors.red);
                      }
                    }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Material(
                        color: color ?? theme.colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          onTap: _isAnswered ? null : () => _selectAnswer(index),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            decoration: BoxDecoration(
                              border: side != null ? Border.all(color: side.color) : null,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  child: Text(String.fromCharCode(65 + index)),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(q.options[index],
                                      style: theme.textTheme.bodyLarge),
                                ),
                                if (trailing != null) trailing,
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                  if (_isAnswered && q.explanation != null) ...[
                    const SizedBox(height: 16),
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
                                Icon(Icons.lightbulb,
                                    color: theme.colorScheme.onPrimaryContainer),
                                const SizedBox(width: 8),
                                Text('解析',
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      color: theme.colorScheme.onPrimaryContainer,
                                      fontWeight: FontWeight.bold,
                                    )),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              q.explanation!,
                              style: TextStyle(
                                color: theme.colorScheme.onPrimaryContainer
                                    .withValues(alpha: 0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          // Bottom button
          if (_isAnswered)
            FilledButton(
              onPressed: _nextQuestion,
              child: Text(
                _currentIndex + 1 >= _questions.length ? '完成' : '下一题',
              ),
            ),
        ],
      ),
    );
  }
}
