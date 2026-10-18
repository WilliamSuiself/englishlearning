import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/skill_card.dart';
import '../services/database_service.dart';
import '../services/settings_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _streak = 0;
  int _todayCount = 0;
  double _accuracy = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats().then((_) => _checkPrivacy());
  }

  Future<void> _loadStats() async {
    final streak = await DatabaseService.getStreakDays();
    final todayCount = await DatabaseService.getTodayStudyCount();
    final records = await DatabaseService.getStudyRecords(days: 30);
    int totalCorrect = 0;
    int totalQuestions = 0;
    for (final r in records) {
      totalCorrect += r.correctCount;
      totalQuestions += r.totalQuestions;
    }
    setState(() {
      _streak = streak;
      _todayCount = todayCount;
      _accuracy = totalQuestions > 0 ? totalCorrect / totalQuestions : 0;
      _isLoading = false;
    });
  }

  Future<void> _checkPrivacy() async {
    final accepted = await SettingsService.hasAcceptedPrivacy();
    if (accepted || !mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) => _showPrivacyDialog());
  }

  void _showPrivacyDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('隐私政策'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '欢迎使用 EchoEnglish。我们非常重视你的隐私保护：',
            ),
            const SizedBox(height: 12),
            const Text(
              '• 你的学习记录、语音、写作内容均只保存在本地设备\n'
              '• 应用不会将任何个人数据发送到第三方服务器或 AI 服务\n'
              '• 使用口语练习时，语音识别由设备本地或系统服务完成\n'
              '• 你可随时在“设置 → 隐私”中查看完整隐私政策',
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _openPrivacyPolicy,
              child: Text(
                '查看完整隐私政策',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              SystemNavigator.pop();
            },
            child: const Text('不同意'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              await SettingsService.setPrivacyAccepted(true);
            },
            child: const Text('同意并继续使用'),
          ),
        ],
      ),
    );
  }

  Future<void> _openPrivacyPolicy() async {
    final uri = Uri.parse('https://english-learning-legal.pages.dev/privacy.html');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('无法打开隐私政策链接')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('EchoEnglish'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.go('/settings'),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 欢迎卡片
              Card(
                elevation: 0,
                color: theme.colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Icon(
                        Icons.waving_hand,
                        size: 40,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '欢迎回来！',
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: theme.colorScheme.onPrimaryContainer,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '利用碎片时间，每天进步一点点',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // 今日学习概览
              Text('今日学习', style: theme.textTheme.titleMedium),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: Icons.local_fire_department,
                      label: '连续打卡',
                      value: '$_streak',
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.today,
                      label: '今日练习',
                      value: '$_todayCount',
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.check_circle,
                      label: '正确率',
                      value: _isLoading ? '--' : '${(_accuracy * 100).round()}%',
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // 四项技能入口
              Text('技能练习', style: theme.textTheme.titleMedium),
              const SizedBox(height: 12),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.95,
                children: [
                  SkillCard(
                    icon: Icons.headphones,
                    title: '听力',
                    subtitle: '听写 · 听力选择',
                    color: Colors.blue,
                    onTap: () => context.go('/listening'),
                  ),
                  SkillCard(
                    icon: Icons.mic,
                    title: '口语',
                    subtitle: '跟读 · 发音练习',
                    color: Colors.purple,
                    onTap: () => context.go('/speaking'),
                  ),
                  SkillCard(
                    icon: Icons.book,
                    title: '阅读',
                    subtitle: '文章 · 理解题',
                    color: Colors.teal,
                    onTap: () => context.go('/reading'),
                  ),
                  SkillCard(
                    icon: Icons.edit,
                    title: '写作',
                    subtitle: '短文 · 翻译',
                    color: Colors.deepOrange,
                    onTap: () => context.go('/writing'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // 快速操作
              Text('快速操作', style: theme.textTheme.titleMedium),
              const SizedBox(height: 12),
              Card(
                elevation: 0,
                color: theme.colorScheme.surfaceContainerLow,
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.refresh, color: Colors.indigo),
                      title: const Text('复习错题'),
                      subtitle: const Text('巩固薄弱项'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.go('/review'),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.menu_book, color: Colors.brown),
                      title: const Text('背单词'),
                      subtitle: const Text('随机抽词 · 卡片翻转 · 认识/不认识'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.go('/vocabulary'),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.quiz, color: Colors.green),
                      title: const Text('习题练习'),
                      subtitle: const Text('词汇 · 语法 · 阅读 · 听力'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.go('/quiz'),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.timer, color: Colors.red),
                      title: const Text('模拟考试'),
                      subtitle: const Text('计时 · 20题 · 成绩报告'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.go('/quiz/exam'),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.bar_chart, color: Colors.cyan),
                      title: const Text('学习统计'),
                      subtitle: const Text('进度 · 日历 · 分析'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.go('/stats'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: color.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
