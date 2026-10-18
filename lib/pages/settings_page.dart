import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/settings_service.dart';
import '../services/database_service.dart';
import '../services/data_seeder.dart';

const _privacyPolicyUrl = 'https://english-learning-legal.pages.dev/privacy.html';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _themeMode = 'system';
  double _ttsRate = 0.45;
  int _dailyGoal = 20;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _themeMode = await SettingsService.getThemeMode();
    _ttsRate = await SettingsService.getTtsRate();
    _dailyGoal = await SettingsService.getDailyGoal();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              context.go('/');
            }
          },
        ),
      ),
      body: SafeArea(
        child: ListView(
          children: [
            const SizedBox(height: 16),
            // 外观
            _SectionHeader(title: '外观', theme: theme),
            ListTile(
              leading: const Icon(Icons.palette),
              title: const Text('主题模式'),
              subtitle: Text(_themeLabel(_themeMode)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showThemePicker(),
            ),

            const SizedBox(height: 16),
            // 语音
            _SectionHeader(title: '语音设置', theme: theme),
            ListTile(
              leading: const Icon(Icons.speed),
              title: const Text('TTS 语速'),
              subtitle: Text('${(_ttsRate * 100).round()}%'),
              trailing: SizedBox(
                width: 120,
                child: Slider(
                  value: _ttsRate,
                  min: 0.2,
                  max: 1.0,
                  divisions: 8,
                  onChanged: (v) => setState(() => _ttsRate = v),
                  onChangeEnd: (v) => SettingsService.setTtsRate(v),
                ),
              ),
            ),

            const SizedBox(height: 16),
            // 学习目标
            _SectionHeader(title: '学习目标', theme: theme),
            ListTile(
              leading: const Icon(Icons.flag),
              title: const Text('每日练习题数'),
              subtitle: Text('$_dailyGoal 题/天'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showGoalPicker(),
            ),

            const SizedBox(height: 16),
            // TTS 引擎
            _SectionHeader(title: 'TTS 引擎', theme: theme),
            ListTile(
              leading: const Icon(Icons.graphic_eq, color: Colors.purple),
              title: const Text('TTS 音频测试'),
              subtitle: const Text('测试不同语速和句子的发音效果'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.go('/tts-test'),
            ),
            const Divider(height: 1),

            const SizedBox(height: 16),
            // 隐私
            _SectionHeader(title: '隐私', theme: theme),
            ListTile(
              leading: const Icon(Icons.privacy_tip_outlined),
              title: const Text('隐私政策'),
              subtitle: const Text('查看我们如何收集、使用和共享你的信息'),
              trailing: const Icon(Icons.open_in_new),
              onTap: () => _openPrivacyPolicy(),
            ),

            const SizedBox(height: 16),
            // 数据管理
            _SectionHeader(title: '数据管理', theme: theme),
            ListTile(
              leading: const Icon(Icons.download, color: Colors.blue),
              title: const Text('重新导入词库'),
              subtitle: const Text('清空并重新加载内置词库和习题'),
              onTap: () => _showReimportConfirm(),
            ),
            ListTile(
              leading: const Icon(Icons.delete_forever, color: Colors.red),
              title: const Text('清空所有数据'),
              subtitle: const Text('删除词库、习题、学习记录'),
              onTap: () => _showClearConfirm(),
            ),

            const SizedBox(height: 16),
            // 关于
            _SectionHeader(title: '关于', theme: theme),
            const ListTile(
              leading: Icon(Icons.info),
              title: Text('EchoEnglish'),
              subtitle: Text('版本 1.0.4 · Flutter + Material 3'),
            ),
            ListTile(
              leading: const Icon(Icons.code),
              title: const Text('词库来源'),
              subtitle: const Text('KyleBing/english-vocabulary\nLuchoBazz/ielts-ai-dataset'),
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }

  String _themeLabel(String mode) {
    switch (mode) {
      case 'light':
        return '浅色模式';
      case 'dark':
        return '深色模式';
      default:
        return '跟随系统';
    }
  }

  void _showThemePicker() {
    showDialog(
      context: context,
      builder: (context) => RadioGroup<String>(
        groupValue: _themeMode,
        onChanged: (v) {
          if (v != null) _setTheme(v);
        },
        child: SimpleDialog(
          title: const Text('选择主题'),
          children: [
            RadioListTile<String>(
              value: 'system',
              title: const Text('跟随系统'),
              selected: _themeMode == 'system',
            ),
            RadioListTile<String>(
              value: 'light',
              title: const Text('浅色模式'),
              selected: _themeMode == 'light',
            ),
            RadioListTile<String>(
              value: 'dark',
              title: const Text('深色模式'),
              selected: _themeMode == 'dark',
            ),
          ],
        ),
      ),
    );
  }

  void _setTheme(String mode) {
    SettingsService.setThemeMode(mode);
    setState(() => _themeMode = mode);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('主题已切换，重启应用后生效')),
    );
  }

  void _showGoalPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('每日目标'),
        content: RadioGroup<int>(
          groupValue: _dailyGoal,
          onChanged: (v) {
            if (v == null) return;
            SettingsService.setDailyGoal(v);
            setState(() => _dailyGoal = v);
            Navigator.pop(context);
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [10, 20, 30, 50, 100].map((goal) {
              return RadioListTile<int>(
                value: goal,
                title: Text('$goal 题/天'),
                selected: _dailyGoal == goal,
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Future<void> _openPrivacyPolicy() async {
    final uri = Uri.parse(_privacyPolicyUrl);
    final messenger = ScaffoldMessenger.of(context);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      messenger.showSnackBar(
        const SnackBar(content: Text('无法打开隐私政策链接')),
      );
    }
  }

  void _showReimportConfirm() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('重新导入词库'),
        content: const Text('将清空现有词库和习题数据并重新导入，确定继续？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(context);
              await DatabaseService.clearAllData();
              await DataSeeder.seedIfNeeded();
              if (mounted) {
                messenger.showSnackBar(
                  const SnackBar(content: Text('词库已重新导入')),
                );
              }
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showClearConfirm() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清空所有数据'),
        content: const Text('此操作不可撤销！将删除所有词库、习题、学习记录和错题本。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(context);
              await DatabaseService.clearAllData();
              if (mounted) {
                messenger.showSnackBar(
                  const SnackBar(content: Text('所有数据已清空')),
                );
              }
            },
            child: const Text('清空'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final ThemeData theme;

  const _SectionHeader({required this.title, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
