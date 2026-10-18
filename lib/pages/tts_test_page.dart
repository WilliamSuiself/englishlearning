import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/tts_service.dart';

class TtsTestPage extends StatefulWidget {
  const TtsTestPage({super.key});

  @override
  State<TtsTestPage> createState() => _TtsTestPageState();
}

class _TtsTestPageState extends State<TtsTestPage> {
  final _tts = TtsService();
  bool _isPlaying = false;
  bool _isSwitching = false;
  double _speed = 1.0;
  int _sid = 0;
  TtsModel _selectedModel = TtsModel.amyLow;

  final _testSentences = [
    'Hello, how are you doing today?',
    'The quick brown fox jumps over the lazy dog.',
    'I am learning English vocabulary with this app.',
    'Could you please repeat that sentence for me?',
    'Technology has changed the way we communicate.',
  ];

  final _speeds = [0.7, 0.85, 1.0, 1.15, 1.3];

  @override
  void initState() {
    super.initState();
    _switchModel(TtsModel.amyLow);
  }

  Future<void> _switchModel(TtsModel model) async {
    setState(() => _isSwitching = true);
    try {
      await _tts.init(model: model);
      setState(() {
        _selectedModel = model;
        _sid = model.defaultSid;
      });
    } catch (e) {
      debugPrint('Model switch error: $e');
    }
    setState(() => _isSwitching = false);
  }

  Future<void> _play(String text) async {
    if (_isSwitching) return;
    setState(() => _isPlaying = true);
    try {
      await _tts.speak(text, rate: 0.45 / _speed, sid: _sid);
    } catch (e) {
      debugPrint('TTS error: $e');
    }
    // Wait a bit for playback to finish
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() => _isPlaying = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('TTS 音频测试'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              context.go('/settings');
            }
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Model selector
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('模型选择', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 8),
                      if (_isSwitching)
                        const Padding(
                          padding: EdgeInsets.all(8),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                              SizedBox(width: 12),
                              Text('加载模型中...'),
                            ],
                          ),
                        )
                      else
                        RadioGroup<TtsModel>(
                          groupValue: _selectedModel,
                          onChanged: (m) {
                            if (m != null) _switchModel(m);
                          },
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: TtsModel.values.map((m) => RadioListTile<TtsModel>(
                              value: m,
                              title: Text(m.displayName),
                              subtitle: Text(_getModelDesc(m)),
                              selected: _selectedModel == m,
                              dense: true,
                            )).toList(),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Speaker ID (for multi-speaker models)
              if (_selectedModel == TtsModel.libritts)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('说话人 ID: $_sid', style: theme.textTheme.titleMedium),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: List.generate(8, (i) {
                            final sid = i * 100;
                            return ChoiceChip(
                              label: Text('$sid'),
                              selected: _sid == sid,
                              onSelected: (_) => setState(() => _sid = sid),
                            );
                          }),
                        ),
                        const SizedBox(height: 4),
                        Text('多说话人模型有 904 个说话人，试试不同 ID',
                            style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                ),
              if (_selectedModel == TtsModel.libritts)
                const SizedBox(height: 16),
              // Speed control
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('语速控制', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: _speeds.map((s) {
                          final selected = (_speed - s).abs() < 0.01;
                          return ChoiceChip(
                            label: Text('${s.toStringAsFixed(2)}x'),
                            selected: selected,
                            onSelected: (_) => setState(() => _speed = s),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Test sentences
              Text('测试句子', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              ..._testSentences.map((s) => _buildSentenceCard(s, theme)),
              const SizedBox(height: 24),
              // Single word test
              Text('单词发音测试', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  'apple', 'beautiful', 'comfortable', 'determine',
                  'education', 'frequency', 'government', 'happiness',
                ].map((word) => ActionChip(
                  label: Text(word),
                  onPressed: _isPlaying || _isSwitching ? null : () => _play(word),
                )).toList(),
              ),
              const SizedBox(height: 24),
              // Info
              Card(
                color: theme.colorScheme.surfaceContainerLow,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, size: 18, color: theme.colorScheme.primary),
                          const SizedBox(width: 8),
                          Text('当前模型信息', style: theme.textTheme.titleSmall),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('• 引擎: sherpa-onnx (VITS-piper)'),
                      Text('• 模型: ${_selectedModel.displayName}'),
                      Text('• 采样率: ${_tts.sampleRate}Hz'),
                      Text('• 双声道输出（已修复左右耳问题）'),
                      Text('• 完全离线运行，无需网络'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getModelDesc(TtsModel m) {
    switch (m) {
      case TtsModel.northernMale:
        return '英国北部男声 · int8 量化 · ~18MB';
      case TtsModel.amyLow:
        return '美国女声 · 低质量 · ~63MB';
      case TtsModel.libritts:
        return '美国多说话人 · 中等质量 · ~78MB · 904个说话人';
    }
  }

  Widget _buildSentenceCard(String sentence, ThemeData theme) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Text(sentence, style: theme.textTheme.bodyMedium),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: _isPlaying || _isSwitching ? null : () => _play(sentence),
              icon: _isPlaying
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.play_arrow),
            ),
          ],
        ),
      ),
    );
  }
}
