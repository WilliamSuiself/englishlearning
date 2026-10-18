import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../services/tts_service.dart';
import '../services/settings_service.dart';
import '../models/word.dart';
import '../models/study_record.dart';

class VocabularyPage extends StatefulWidget {
  const VocabularyPage({super.key});

  @override
  State<VocabularyPage> createState() => _VocabularyPageState();
}

class _VocabularyPageState extends State<VocabularyPage> {
  final _tts = TtsService();
  List<Word> _words = [];
  int _currentIndex = 0;
  bool _isLoading = true;
  bool _showDefinition = false;
  String? _selectedLevel;
  int _knownCount = 0;
  int _unknownCount = 0;
  double _ttsRate = 0.45;
  List<Map<String, dynamic>> _examples = [];
  DateTime _startTime = DateTime.now();

  final _levels = ['全部', 'CET4', 'CET6', '考研', 'TOEFL'];

  @override
  void initState() {
    super.initState();
    _loadRate();
    _loadWords();
  }

  Future<void> _loadRate() async {
    _ttsRate = await SettingsService.getTtsRate();
  }

  Future<void> _loadWords() async {
    setState(() => _isLoading = true);
    final level = _selectedLevel == '全部' || _selectedLevel == null
        ? null
        : _selectedLevel;
    final words = await DatabaseService.getRandomWords(level: level, limit: 20);
    setState(() {
      _words = words;
      _currentIndex = 0;
      _showDefinition = false;
      _knownCount = 0;
      _unknownCount = 0;
      _startTime = DateTime.now();
      _isLoading = false;
    });
  }

  void _nextWord({bool? known}) {
    if (known == true) {
      _knownCount++;
    } else if (known == false) {
      _unknownCount++;
    }

    if (_currentIndex + 1 >= _words.length) {
      _showFinishDialog();
      return;
    }

    setState(() {
      _currentIndex++;
      _showDefinition = false;
      _examples = [];
    });
  }

  Future<void> _loadExamples() async {
    final word = _words[_currentIndex];
    if (word.id == null) return;
    final examples = await DatabaseService.getExamplesForWord(word.id!);
    if (mounted) {
      setState(() => _examples = examples.take(2).toList());
    }
  }

  Future<void> _showFinishDialog() async {
    final total = _words.length;
    final duration = DateTime.now().difference(_startTime).inSeconds;
    await DatabaseService.insertStudyRecord(StudyRecord(
      skill: 'vocabulary',
      exerciseType: 'flashcards',
      totalQuestions: total,
      correctCount: _knownCount,
      durationSeconds: duration,
      studiedAt: DateTime.now(),
    ));

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('本轮完成！'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _knownCount >= total * 0.6 ? Icons.celebration : Icons.thumb_up,
              size: 48,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text('认识: $_knownCount / $total'),
            Text('不认识: $_unknownCount / $total'),
            Text('正确率: ${(_knownCount / total * 100).toStringAsFixed(0)}%'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('返回'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _loadWords();
            },
            child: const Text('再来一轮'),
          ),
        ],
      ),
    );
  }

  void _playWord() {
    if (_words.isEmpty) return;
    _tts.speak(_words[_currentIndex].word, rate: _ttsRate);
  }

  Widget _buildWordForms(String exchange, ThemeData theme) {
    final forms = <String>[];
    for (final part in exchange.split('/')) {
      final seg = part.split(':');
      if (seg.length == 2) {
        final type = seg[0];
        final word = seg[1];
        final label = switch (type) {
          'p' => '过去式',
          'd' => '过去分词',
          'i' => '现在分词',
          '3' => '第三人称单数',
          'r' => '比较级',
          't' => '最高级',
          's' => '复数',
          _ => null,
        };
        if (label != null) {
          forms.add('$label: $word');
        }
      }
    }
    if (forms.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      alignment: WrapAlignment.center,
      children: forms.map((f) => Text(
        f,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.outline,
        ),
      )).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('背单词'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Level filter
            SizedBox(
              height: 44,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _levels.length,
                itemBuilder: (context, index) {
                  final level = _levels[index];
                  final selected = _selectedLevel == level ||
                      (_selectedLevel == null && level == '全部');
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(level),
                      selected: selected,
                      onSelected: (_) {
                        setState(() => _selectedLevel = level);
                        _loadWords();
                      },
                    ),
                  );
                },
              ),
            ),
            // Progress
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: LinearProgressIndicator(
                      value: _words.isNotEmpty
                          ? (_currentIndex + 1) / _words.length
                          : 0,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _words.isNotEmpty
                        ? '${_currentIndex + 1}/${_words.length}'
                        : '',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            // Card area
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _words.isEmpty
                      ? Center(
                          child: Text('暂无词库数据',
                              style: theme.textTheme.bodyLarge),
                        )
                      : _buildWordCard(theme),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWordCard(ThemeData theme) {
    final word = _words[_currentIndex];

    return GestureDetector(
      onTap: () {
        setState(() => _showDefinition = !_showDefinition);
        if (_showDefinition && _examples.isEmpty) {
          _loadExamples();
        }
      },
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Word card
            Expanded(
              child: Card(
                elevation: 2,
                color: _showDefinition
                    ? theme.colorScheme.surfaceContainerLow
                    : theme.colorScheme.primaryContainer,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (!_showDefinition) const SizedBox(height: 60),
                      if (!_showDefinition) ...[
                        Text(
                          word.word,
                          style: theme.textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                        if (word.phoneticUs != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            '/${word.phoneticUs}/',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer
                                  .withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                        if (word.partOfSpeech != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            word.partOfSpeech!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer
                                  .withValues(alpha: 0.6),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        Text(
                          '点击卡片查看释义',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer
                                .withValues(alpha: 0.5),
                          ),
                        ),
                      ] else ...[
                        Text(
                          word.word,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (word.phoneticUs != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            '/${word.phoneticUs}/',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.outline,
                            ),
                          ),
                        ],
                        if (word.partOfSpeech != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            word.partOfSpeech!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontStyle: FontStyle.italic,
                              color: theme.colorScheme.outline,
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        Text(
                          word.definition,
                          style: theme.textTheme.titleMedium?.copyWith(
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (word.definitionEn != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            word.definitionEn!.split('\n').take(2).join('\n'),
                            style: theme.textTheme.bodySmall?.copyWith(
                              height: 1.4,
                              color: theme.colorScheme.outline,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        if (word.exchange != null && word.exchange!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          _buildWordForms(word.exchange!, theme),
                        ],
                        if (_examples.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 8),
                          for (final ex in _examples) ...[
                            InkWell(
                              onTap: () => _tts.speak(
                                  ex['example'] as String,
                                  rate: _ttsRate),
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 6, horizontal: 4),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Icon(Icons.volume_up,
                                            size: 16,
                                            color: theme
                                                .colorScheme.primary),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            ex['example'] as String,
                                            style: theme
                                                .textTheme.bodyMedium
                                                ?.copyWith(height: 1.4),
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (ex['translation'] != null)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                            left: 22, top: 2),
                                        child: Text(
                                          ex['translation'] as String,
                                          style: theme
                                              .textTheme.bodySmall
                                              ?.copyWith(
                                            color: theme
                                                .colorScheme.outline,
                                            height: 1.4,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                          ],
                        ],
                        if (word.level != null) ...[
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            alignment: WrapAlignment.center,
                            children: [
                              Chip(
                                label: Text(word.level!,
                                    style: const TextStyle(fontSize: 11)),
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                              ),
                              if (word.collins > 0)
                                Chip(
                                  label: Text('★' * word.collins,
                                      style: const TextStyle(fontSize: 10)),
                                  visualDensity: VisualDensity.compact,
                                  padding: EdgeInsets.zero,
                                ),
                              if (word.oxford == 1)
                                const Chip(
                                  label: Text('牛津三千',
                                      style: TextStyle(fontSize: 10)),
                                  visualDensity: VisualDensity.compact,
                                  padding: EdgeInsets.zero,
                                ),
                            ],
                          ),
                        ],
                      ],
                      const SizedBox(height: 24),
                      FilledButton.tonalIcon(
                        onPressed: _playWord,
                        icon: const Icon(Icons.volume_up),
                        label: const Text('发音'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: FilledButton.tonal(
                    onPressed: () => _nextWord(known: false),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.red.withValues(alpha: 0.1),
                      foregroundColor: Colors.red,
                    ),
                    child: const Text('不认识'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => _nextWord(known: true),
                    child: const Text('认识'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
