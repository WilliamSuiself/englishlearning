import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../models/study_record.dart';

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  List<StudyRecord> _records = [];
  Map<String, int> _skillStats = {};
  Map<String, int> _dailyCounts = {};
  int _todayCount = 0;
  int _streak = 0;
  int _totalDays = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    final records = await DatabaseService.getStudyRecords(days: 30);
    final skillStats = await DatabaseService.getSkillStats();
    final todayCount = await DatabaseService.getTodayStudyCount();
    final dailyCounts = await DatabaseService.getDailyCounts(days: 84);
    final streak = await DatabaseService.getStreakDays();
    final totalDays = await DatabaseService.getTotalStudyDays();
    setState(() {
      _records = records;
      _skillStats = skillStats;
      _todayCount = todayCount;
      _dailyCounts = dailyCounts;
      _streak = streak;
      _totalDays = totalDays;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final skills = [
      ('listening', '听力', Icons.headphones, Colors.blue),
      ('speaking', '口语', Icons.mic, Colors.purple),
      ('reading', '阅读', Icons.book, Colors.teal),
      ('writing', '写作', Icons.edit, Colors.deepOrange),
      ('vocabulary', '背单词', Icons.menu_book, Colors.brown),
      ('quiz', '习题', Icons.quiz, Colors.green),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('学习统计'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadStats,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 今日概览
                    Text('今日概览', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 12),
                    Card(
                      elevation: 0,
                      color: theme.colorScheme.primaryContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _StatItem(
                              icon: Icons.today,
                              label: '今日练习',
                              value: '$_todayCount',
                            ),
                            _StatItem(
                              icon: Icons.history,
                              label: '30天记录',
                              value: '${_records.length}',
                            ),
                            _StatItem(
                              icon: Icons.local_fire_department,
                              label: '连续打卡',
                              value: '$_streak',
                            ),
                            _StatItem(
                              icon: Icons.calendar_month,
                              label: '累计天数',
                              value: '$_totalDays',
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // 技能分布
                    Text('技能分布', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 12),
                    Card(
                      elevation: 0,
                      color: theme.colorScheme.surfaceContainerLow,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: skills.map((s) {
                            final count = _skillStats[s.$1] ?? 0;
                            final maxCount = _skillStats.values.isEmpty
                                ? 1
                                : _skillStats.values.reduce((a, b) => a > b ? a : b);
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                children: [
                                  Icon(s.$3, color: s.$4, size: 24),
                                  const SizedBox(width: 12),
                                  Text(s.$2),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: LinearProgressIndicator(
                                      value: maxCount > 0
                                          ? count / maxCount
                                          : 0,
                                      color: s.$4,
                                      backgroundColor:
                                          s.$4.withValues(alpha: 0.1),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  SizedBox(
                                    width: 32,
                                    child: Text(
                                      '$count',
                                      textAlign: TextAlign.right,
                                      style: theme.textTheme.bodyMedium,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // 学习日历
                    Text('学习日历（近12周）', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 12),
                    _buildCalendarHeatmap(theme),
                    const SizedBox(height: 24),
                    // 最近记录
                    Text('最近练习', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 12),
                    if (_records.isEmpty)
                      Card(
                        elevation: 0,
                        color: theme.colorScheme.surfaceContainerLow,
                        child: const Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(
                            child: Text('还没有练习记录，开始学习吧！'),
                          ),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _records.length > 20 ? 20 : _records.length,
                        itemBuilder: (context, index) {
                          final r = _records[index];
                          final skillLabel = skills.firstWhere(
                            (s) => s.$1 == r.skill,
                            orElse: () => ('', r.skill, Icons.circle, Colors.grey),
                          );
                          return Card(
                            margin: const EdgeInsets.only(bottom: 4),
                            elevation: 0,
                            color: theme.colorScheme.surfaceContainerLow,
                            child: ListTile(
                              leading: Icon(skillLabel.$3, color: skillLabel.$4),
                              title: Text(skillLabel.$2),
                              subtitle: Text(
                                '${r.exerciseType} · '
                                '正确率 ${(r.accuracy * 100).toStringAsFixed(0)}% · '
                                '${r.durationSeconds ~/ 60}m${r.durationSeconds % 60}s',
                              ),
                              trailing: Text(
                                '${r.studiedAt.month}/${r.studiedAt.day}',
                                style: theme.textTheme.bodySmall,
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
                ),
            ),
      ),
    );
  }

  Widget _buildCalendarHeatmap(ThemeData theme) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weeks = 12;
    final startDate = today.subtract(Duration(days: weeks * 7 - 1));

    final maxCount = _dailyCounts.values.isEmpty
        ? 1
        : _dailyCounts.values.reduce((a, b) => a > b ? a : b);

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const SizedBox(width: 28),
                ...['一', '三', '五'].map((d) => SizedBox(
                      width: 14,
                      child: Text(d,
                          style: theme.textTheme.bodySmall?.copyWith(fontSize: 9)),
                    )),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 4),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(weeks, (week) {
                  return Column(
                    children: List.generate(7, (day) {
                      final date = startDate
                          .add(Duration(days: week * 7 + day));
                      if (date.isAfter(today)) {
                        return SizedBox(
                          width: 14,
                          height: 14,
                          child: Container(),
                        );
                      }
                      final key =
                          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                      final count = _dailyCounts[key] ?? 0;
                      final intensity = count == 0 ? 0.0 : count / maxCount;

                      Color color;
                      if (count == 0) {
                        color = theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.3);
                      } else if (intensity < 0.25) {
                        color = Colors.green.withValues(alpha: 0.25);
                      } else if (intensity < 0.5) {
                        color = Colors.green.withValues(alpha: 0.45);
                      } else if (intensity < 0.75) {
                        color = Colors.green.withValues(alpha: 0.7);
                      } else {
                        color = Colors.green;
                      }

                      return Padding(
                        padding: const EdgeInsets.all(1),
                        child: Tooltip(
                          message: '${date.month}/${date.day}: $count 次',
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      );
                    }),
                  );
                }),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text('少', style: theme.textTheme.bodySmall?.copyWith(fontSize: 10)),
                const SizedBox(width: 4),
                ...[0.0, 0.25, 0.5, 0.75, 1.0].map((i) {
                  Color color;
                  if (i == 0) {
                    color = theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.3);
                  } else {
                    color = Colors.green.withValues(alpha: i);
                  }
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1),
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
                const SizedBox(width: 4),
                Text('多', style: theme.textTheme.bodySmall?.copyWith(fontSize: 10)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(icon, size: 28, color: theme.colorScheme.onPrimaryContainer),
        const SizedBox(height: 8),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}
