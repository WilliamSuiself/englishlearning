import 'dart:math';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../services/tts_service.dart';
import '../services/database_service.dart';
import '../services/settings_service.dart';
import '../models/study_record.dart';

class SpeakingPage extends StatefulWidget {
  const SpeakingPage({super.key});

  @override
  State<SpeakingPage> createState() => _SpeakingPageState();
}

class _SentenceItem {
  final String sentence;
  final String? translation;
  final String word;

  _SentenceItem({
    required this.sentence,
    this.translation,
    required this.word,
  });
}

class _SpeakingPageState extends State<SpeakingPage> {
  final _tts = TtsService();
  final _speech = SpeechToText();
  List<_SentenceItem> _sentences = [];
  int _currentIndex = 0;
  bool _isListening = false;
  bool _isAvailable = false;
  bool _isLoading = true;
  String _recognizedText = '';
  String _feedback = '';
  double _score = 0;
  List<bool>? _wordMatches;
  DateTime? _startTime;
  int _correctCount = 0;
  double _ttsRate = 0.45;

  static const _sessionSize = 10;
  static const _minWords = 5;
  static const _maxWords = 14;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
    _initSpeech();
    _loadRate();
    _loadSentences();
  }

  Future<void> _loadRate() async {
    _ttsRate = await SettingsService.getTtsRate();
  }

  Future<void> _initSpeech() async {
    _isAvailable = await _speech.initialize();
    if (mounted) setState(() {});
  }

  Future<void> _loadSentences() async {
    setState(() => _isLoading = true);
    final rows = await DatabaseService.getRandomExamples(limit: 200);
    final items = <_SentenceItem>[];
    final seen = <String>{};
    for (final row in rows) {
      final sentence = row['example'] as String;
      final wordCount = sentence.split(RegExp(r'\s+')).length;
      if (wordCount < _minWords || wordCount > _maxWords) continue;
      if (seen.contains(sentence)) continue;
      seen.add(sentence);
      items.add(_SentenceItem(
        sentence: sentence,
        translation: row['translation'] as String?,
        word: row['word'] as String,
      ));
      if (items.length >= _sessionSize) break;
    }
    setState(() {
      _sentences = items;
      _currentIndex = 0;
      _isLoading = false;
    });
  }

  Future<void> _playSentence() async {
    if (_sentences.isEmpty) return;
    await _tts.speak(_sentences[_currentIndex].sentence, rate: _ttsRate);
  }

  void _startListening() {
    if (!_isAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('语音识别不可用，请检查权限设置')),
      );
      return;
    }

    setState(() {
      _isListening = true;
      _recognizedText = '';
      _feedback = '';
      _wordMatches = null;
    });

    _speech.listen(
      listenOptions: SpeechListenOptions(
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        localeId: 'en_US',
      ),
      onResult: (result) {
        setState(() {
          _recognizedText = result.recognizedWords;
          if (result.finalResult) {
            _isListening = false;
            _evaluateSpeech();
          }
        });
      },
    );
  }

  void _stopListening() {
    _speech.stop();
    setState(() => _isListening = false);
    _evaluateSpeech();
  }

  /// Normalize text: lowercase, strip punctuation (keep letters/digits).
  List<String> _tokenize(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r"[^a-z0-9\s]"), '')
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
  }

  /// LCS-based alignment: returns match flags for each target word.
  List<bool> _matchWords(List<String> target, List<String> spoken) {
    final m = target.length;
    final n = spoken.length;
    final dp = List.generate(m + 1, (_) => List.filled(n + 1, 0));
    for (var i = 1; i <= m; i++) {
      for (var j = 1; j <= n; j++) {
        if (target[i - 1] == spoken[j - 1]) {
          dp[i][j] = dp[i - 1][j - 1] + 1;
        } else {
          dp[i][j] = dp[i - 1][j] > dp[i][j - 1] ? dp[i - 1][j] : dp[i][j - 1];
        }
      }
    }
    // Backtrack to find matched target indices
    final matches = List.filled(m, false);
    var i = m, j = n;
    while (i > 0 && j > 0) {
      if (target[i - 1] == spoken[j - 1]) {
        matches[i - 1] = true;
        i--;
        j--;
      } else if (dp[i - 1][j] >= dp[i][j - 1]) {
        i--;
      } else {
        j--;
      }
    }
    return matches;
  }

  void _evaluateSpeech() {
    if (_sentences.isEmpty || _recognizedText.isEmpty) return;

    final target = _tokenize(_sentences[_currentIndex].sentence);
    final spoken = _tokenize(_recognizedText);
    final matches = _matchWords(target, spoken);
    final matchedCount = matches.where((m) => m).length;
    _score = target.isEmpty ? 0 : matchedCount / target.length * 100;
    _wordMatches = matches;

    if (_score >= 85) {
      _feedback = '太棒了，发音清晰流利！';
      _correctCount++;
    } else if (_score >= 60) {
      _feedback = '不错！红色单词再练一练';
    } else {
      _feedback = '再试一次，先听示范再跟读';
      DatabaseService.incrementWrongCount(
          _sentences[_currentIndex].word, 'speaking');
    }

    setState(() {});
  }

  void _nextSentence() {
    if (_currentIndex + 1 >= _sentences.length) {
      _finishSession();
      return;
    }
    setState(() {
      _currentIndex++;
      _recognizedText = '';
      _feedback = '';
      _score = 0;
      _wordMatches = null;
    });
  }

  Future<void> _finishSession() async {
    final duration = DateTime.now().difference(_startTime!).inSeconds;
    await DatabaseService.insertStudyRecord(StudyRecord(
      skill: 'speaking',
      exerciseType: 'sentence_reading',
      totalQuestions: _sentences.length,
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
          content: Text(
              '优秀: $_correctCount / ${_sentences.length}\n用时: ${duration ~/ 60}分${duration % 60}秒'),
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
      _correctCount = 0;
      _recognizedText = '';
      _feedback = '';
      _score = 0;
      _wordMatches = null;
      _startTime = DateTime.now();
    });
    _loadSentences();
  }

  /// Build the sentence display, with per-word coloring after evaluation.
  Widget _buildSentenceText(ThemeData theme) {
    final item = _sentences[_currentIndex];
    final displayWords = item.sentence.split(RegExp(r'\s+'));

    if (_wordMatches == null) {
      return Text(
        item.sentence,
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
          height: 1.5,
          color: theme.colorScheme.onPrimaryContainer,
        ),
        textAlign: TextAlign.center,
      );
    }

    // Align display words with tokenized words (they correspond 1:1 when
    // tokenization only strips punctuation within each word)
    final tokens = _tokenize(item.sentence);
    final spans = <TextSpan>[];
    var tokenIdx = 0;
    for (final dw in displayWords) {
      final normalized = dw
          .toLowerCase()
          .replaceAll(RegExp(r"[^a-z0-9]"), '');
      Color color = theme.colorScheme.onPrimaryContainer;
      if (normalized.isNotEmpty && tokenIdx < tokens.length) {
        color = _wordMatches![tokenIdx]
            ? Colors.green.shade700
            : Colors.red.shade700;
        tokenIdx++;
      }
      spans.add(TextSpan(
        text: '$dw ',
        style: TextStyle(color: color),
      ));
    }

    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
          height: 1.5,
        ),
        children: spans,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('口语练习'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _sentences.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.mic,
                            size: 64, color: theme.colorScheme.outline),
                        const SizedBox(height: 16),
                        const Text('暂无例句，请先在设置中重新导入词库'),
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
                                LinearProgressIndicator(
                                  value: (_currentIndex + 1) /
                                      _sentences.length,
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                        '${_currentIndex + 1} / ${_sentences.length}'),
                                    Text('优秀: $_correctCount'),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                // 例句卡片
                                SizedBox(
                                  height: max(
                                      180.0, constraints.maxHeight - 240.0),
                                  child: Card(
                                    elevation: 0,
                                    color: theme.colorScheme.primaryContainer,
                                    child: SingleChildScrollView(
                                      padding: const EdgeInsets.all(20),
                                      child: Column(
                                        children: [
                                          _buildSentenceText(theme),
                                          if (_sentences[_currentIndex]
                                                  .translation !=
                                              null) ...[
                                            const SizedBox(height: 12),
                                            Text(
                                              _sentences[_currentIndex]
                                                  .translation!,
                                              style: theme.textTheme.bodyMedium
                                                  ?.copyWith(
                                                color: theme.colorScheme
                                                    .onPrimaryContainer
                                                    .withValues(alpha: 0.7),
                                                height: 1.4,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                // 识别结果
                                if (_recognizedText.isNotEmpty)
                                  Card(
                                    elevation: 0,
                                    color: theme.colorScheme.surfaceContainerLow,
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        children: [
                                          Text('你说: $_recognizedText',
                                              style: theme.textTheme.bodyLarge),
                                          if (_feedback.isNotEmpty) ...[
                                            const SizedBox(height: 8),
                                            Text(
                                              '${_score.round()}分 · $_feedback',
                                              style: TextStyle(
                                                color: _score >= 85
                                                    ? Colors.green
                                                    : _score >= 60
                                                        ? Colors.orange
                                                        : Colors.red,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            LinearProgressIndicator(
                                              value: _score / 100,
                                              color: _score >= 85
                                                  ? Colors.green
                                                  : _score >= 60
                                                      ? Colors.orange
                                                      : Colors.red,
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                if (_isListening) ...[
                                  const SizedBox(height: 16),
                                  Center(
                                    child: Text(
                                      '正在聆听…',
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                ],
                                // 按钮
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    IconButton.filledTonal(
                                      onPressed: _playSentence,
                                      icon: const Icon(Icons.volume_up),
                                      iconSize: 32,
                                      padding: const EdgeInsets.all(16),
                                    ),
                                    IconButton.filled(
                                      onPressed: _isListening
                                          ? _stopListening
                                          : _startListening,
                                      icon: Icon(_isListening
                                          ? Icons.stop
                                          : Icons.mic),
                                      iconSize: 36,
                                      padding: const EdgeInsets.all(20),
                                    ),
                                    IconButton.filledTonal(
                                      onPressed: _feedback.isNotEmpty
                                          ? _nextSentence
                                          : null,
                                      icon: const Icon(Icons.arrow_forward),
                                      iconSize: 32,
                                      padding: const EdgeInsets.all(16),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
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
}
