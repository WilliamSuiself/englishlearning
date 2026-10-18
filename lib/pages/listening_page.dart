import 'dart:math';
import 'package:flutter/material.dart';
import '../services/tts_service.dart';
import '../services/database_service.dart';
import '../models/study_record.dart';
import '../models/word.dart';

class ListeningPage extends StatefulWidget {
  const ListeningPage({super.key});

  @override
  State<ListeningPage> createState() => _ListeningPageState();
}

class _ListeningPageState extends State<ListeningPage> {
  final _tts = TtsService();
  final _inputController = TextEditingController();
  List<Word> _words = [];
  int _currentIndex = 0;
  int _correctCount = 0;
  int _totalCount = 0;
  bool _isAnswered = false;
  bool? _isCorrect;
  double _speechRate = 0.45;
  DateTime? _startTime;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
    _loadWords();
  }

  Future<void> _loadWords() async {
    final words = await DatabaseService.getRandomWords(limit: 20);
    setState(() {
      _words = words;
      _totalCount = words.length;
    });
  }

  Future<void> _playWord() async {
    if (_words.isEmpty) return;
    await _tts.speak(_words[_currentIndex].word, rate: _speechRate);
  }

  void _checkAnswer() {
    if (_words.isEmpty) return;
    FocusScope.of(context).unfocus();
    final userAnswer = _inputController.text.trim().toLowerCase();
    final correctWord = _words[_currentIndex].word.toLowerCase();
    final isCorrect = userAnswer == correctWord;

    setState(() {
      _isAnswered = true;
      _isCorrect = isCorrect;
      if (isCorrect) {
        _correctCount++;
      } else {
        DatabaseService.incrementWrongCount(_words[_currentIndex].word, 'listening');
      }
    });
  }

  void _dontKnow() {
    if (_words.isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _isAnswered = true;
      _isCorrect = false;
      DatabaseService.incrementWrongCount(_words[_currentIndex].word, 'listening');
    });
  }

  void _nextWord() {
    FocusScope.of(context).unfocus();
    setState(() {
      _currentIndex++;
      _isAnswered = false;
      _isCorrect = null;
      _inputController.clear();
    });

    if (_currentIndex >= _words.length) {
      _finishSession();
    } else {
      _playWord();
    }
  }

  Future<void> _finishSession() async {
    final duration = DateTime.now().difference(_startTime!).inSeconds;
    await DatabaseService.insertStudyRecord(StudyRecord(
      skill: 'listening',
      exerciseType: 'dictation',
      totalQuestions: _totalCount,
      correctCount: _correctCount,
      durationSeconds: duration,
      studiedAt: DateTime.now(),
    ));

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('练习完成！'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _correctCount >= _totalCount * 0.6
                    ? Icons.celebration
                    : Icons.thumb_up,
                size: 48,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text('正确: $_correctCount / $_totalCount'),
              Text('正确率: ${(_correctCount / _totalCount * 100).toStringAsFixed(0)}%'),
              Text('用时: ${duration ~/ 60}分${duration % 60}秒'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _restart();
              },
              child: const Text('再来一轮'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('返回'),
            ),
          ],
        ),
      );
    }
  }

  void _restart() {
    setState(() {
      _currentIndex = 0;
      _correctCount = 0;
      _isAnswered = false;
      _isCorrect = null;
      _inputController.clear();
      _startTime = DateTime.now();
    });
    _playWord();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('听力练习'),
        centerTitle: true,
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.translucent,
        child: SafeArea(
          child: _words.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.headphones,
                          size: 64, color: theme.colorScheme.outline),
                      const SizedBox(height: 16),
                      const Text('请先导入词库'),
                      const SizedBox(height: 8),
                      FilledButton.tonal(
                        onPressed: _loadWords,
                        child: const Text('重新加载'),
                      ),
                    ],
                  ),
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints:
                            BoxConstraints(minHeight: constraints.maxHeight),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // 进度
                              LinearProgressIndicator(
                                value: _totalCount > 0
                                    ? (_currentIndex + 1) / _totalCount
                                    : 0,
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('${_currentIndex + 1} / $_totalCount'),
                                  Text('正确: $_correctCount'),
                                ],
                              ),
                              const SizedBox(height: 32),
                              // 播放按钮
                              SizedBox(
                                height: max(
                                    180.0, constraints.maxHeight - 260.0),
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    return SingleChildScrollView(
                                      child: ConstrainedBox(
                                        constraints: BoxConstraints(
                                            minHeight: constraints.maxHeight),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            IconButton.filled(
                                              onPressed: _playWord,
                                              icon: const Icon(Icons.volume_up,
                                                  size: 40),
                                              iconSize: 40,
                                              padding: const EdgeInsets.all(24),
                                            ),
                                            const SizedBox(height: 16),
                                            Text('点击播放，听写单词',
                                                style: theme.textTheme.bodyMedium
                                                    ?.copyWith(
                                                        color: theme.colorScheme
                                                            .outline)),
                                            if (_isAnswered &&
                                                _isCorrect != null) ...[
                                              const SizedBox(height: 24),
                                              Text(
                                                _words[_currentIndex].word,
                                                style: theme
                                                    .textTheme.headlineSmall
                                                    ?.copyWith(
                                                  color: _isCorrect!
                                                      ? Colors.green
                                                      : Colors.red,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Text(_words[_currentIndex]
                                                  .definition),
                                            ],
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              // 语速调节
                              Row(
                                children: [
                                  const Text('语速'),
                                  Expanded(
                                    child: Slider(
                                      value: _speechRate,
                                      min: 0.2,
                                      max: 1.0,
                                      divisions: 8,
                                      label: '${(_speechRate * 100).round()}%',
                                      onChanged: (v) =>
                                          setState(() => _speechRate = v),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              // 输入框
                              TextField(
                                controller: _inputController,
                                enabled: !_isAnswered,
                                decoration: InputDecoration(
                                  hintText: '输入听到的单词...',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  suffixIcon: _isAnswered
                                      ? Icon(
                                          _isCorrect!
                                              ? Icons.check
                                              : Icons.close,
                                          color: _isCorrect!
                                              ? Colors.green
                                              : Colors.red,
                                        )
                                      : null,
                                ),
                                onSubmitted: (_) => _checkAnswer(),
                              ),
                              const SizedBox(height: 16),
                              // 按钮
                              if (!_isAnswered)
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: _dontKnow,
                                        child: const Text('我不会'),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      flex: 2,
                                      child: FilledButton(
                                        onPressed: _checkAnswer,
                                        child: const Text('提交'),
                                      ),
                                    ),
                                  ],
                                )
                              else
                                FilledButton(
                                  onPressed: _nextWord,
                                  child: Text(
                                    _currentIndex + 1 >= _words.length
                                        ? '完成'
                                        : '下一个',
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }
}
