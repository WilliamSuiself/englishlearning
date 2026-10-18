import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../models/wrong_word.dart';
import '../services/tts_service.dart';

class ReviewPage extends StatefulWidget {
  const ReviewPage({super.key});

  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  final _tts = TtsService();
  List<WrongWord> _wrongWords = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWrongWords();
  }

  Future<void> _loadWrongWords() async {
    setState(() => _isLoading = true);
    final words = await DatabaseService.getWrongWords();
    setState(() {
      _wrongWords = words;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('错题复习'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadWrongWords,
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _wrongWords.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle,
                            size: 64, color: theme.colorScheme.outline),
                        const SizedBox(height: 16),
                        const Text('暂无错题，继续加油！'),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _wrongWords.length,
                    itemBuilder: (context, index) {
                      final ww = _wrongWords[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(
                            ww.word,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (ww.definition != null)
                                Text(ww.definition!),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Chip(
                                    label: Text(ww.skill),
                                    visualDensity: VisualDensity.compact,
                                    padding: EdgeInsets.zero,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '错误 ${ww.wrongCount} 次',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.error,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          isThreeLine: true,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.volume_up),
                                onPressed: () => _tts.speak(ww.word),
                              ),
                              IconButton(
                                icon: const Icon(Icons.check,
                                    color: Colors.green),
                                onPressed: () async {
                                  await DatabaseService.removeWrongWord(ww.id!);
                                  _loadWrongWords();
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
