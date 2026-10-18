# English Learning App - 开发计划

## 项目目标
构建一个英语学习 **Flutter 移动应用**（安卓优先），分别练习**听、说、读、写**四项能力，集成词库、习题集和间隔复习算法。面向碎片化时间学习场景，随时随地打开即练。

---

## 阶段一：项目初始化与基础框架 ✅

- [x] 初始化 Flutter 项目（Flutter + Dart + Material 3）
- [x] 搭建项目目录结构（lib/pages / widgets / models / services / utils / data）
- [x] 配置路由（go_router：首页 / 词汇 / 听力 / 口语 / 阅读 / 写作 / 复习 / 统计）
- [x] 设计整体 UI 布局与底部导航栏（Material 3 风格，适合单手操作）
- [x] 配置状态管理（Riverpod）与本地持久化（sqflite）
- [x] 内置 50 词示例词库 + 首次启动自动导入
- [x] Android 权限配置（RECORD_AUDIO / INTERNET / BLUETOOTH）
- [x] Debug APK 构建成功

## 阶段二：词库与数据层 ✅

- [x] 收集并整理词库资源
  - [x] KyleBing/english-vocabulary — CET4/6、考研、托福（TXT → JSON 转换）
- [x] 统一词库数据格式（word / phonetic / definition / examples / tags / level）
- [x] 实现词库导入与索引（sqflite 存储，支持按等级筛选）
- [x] 内置 12230 词，1.1MB，首次启动自动导入
- [x] 实现生词本功能（添加 / 移除 / 收藏管理）
- [ ] zhenghaoyang24/english-vocabulary — 10万+单词 + 14万+例句（后续扩展）
- [ ] first20hours/google-10000-english — 高频词表（后续扩展）
- [ ] mahavivo/english-wordlists — CET/GRE/COCA 词表（后续扩展）

## 阶段三：听力模块（Listening） ✅ 基础版

- [x] 单词听写练习（播放发音 → 用户拼写 → 判对错）
- [x] 语速调节与重复播放控制
- [x] 听力练习统计（正确率 / 练习次数）
- [x] 错题自动收录到错题本
- [ ] 句子听写练习（播放句子 → 用户输入 → 逐词对比）
- [ ] 听力选择题（听音频 → 选择正确答案）
- [ ] 参考：Listenly 的句子精听 + 影子跟读模式

## 阶段四：口语模块（Speaking） ✅ 基础版

- [x] 单词发音练习（看单词 → 朗读 → 识别对比）
- [x] 口语评分展示（简单评分逻辑）
- [x] 技术：speech_to_text (STT) + flutter_tts (TTS)
- [x] 错题自动收录到错题本
- [ ] 影子跟读练习（播放句子 → 用户跟读 → AI 打分）
- [ ] 发音不准单词高亮标记
- [ ] 完整度 / 流畅度 / 精准度全方位评分
- [ ] 参考：Echo Learner 口语跟读 + Listenly AI 打分

## 阶段五：阅读模块（Reading） ✅ 基础版

- [x] 文章阅读界面（分段显示 + TTS 朗读）
- [x] 阅读理解选择题（读文章 → 答题 → 查看对错）
- [x] 内置 2 篇示例文章（easy / medium）
- [ ] 生词高亮点击查词
- [ ] 阅读材料管理（按难度分级，支持导入自定义文章）
- [ ] 阅读速度统计（WPM）与理解率追踪
- [ ] 参考：Qwerty Learner 文章练习 + ielts-ai-dataset 阅读题

## 阶段六：写作模块（Writing） ✅ 基础版

- [x] 短文写作练习（给定题目 → 用户写作）
- [x] 翻译练习（中译英）
- [x] 字数统计与范围检查
- [x] 练习记录保存到数据库
- [ ] AI 批改（文法检查 / 结构分析 / 词汇提升建议）
- [ ] 写作评分展示（内容 / 组织 / 文法 / 词汇 / 体例）
- [ ] 写作历史记录与范文参考
- [ ] 技术：接入 Groq / Gemini / OpenAI API
- [ ] 参考：dffge552/english-learn.app 写作批改 + 翻译练习

## 阶段七：复习系统 ✅ 基础版

- [x] 错题本自动收集与重测
- [x] 错题列表展示（按错误次数排序，支持标记已掌握）
- [ ] 集成 FSRS 间隔重复算法（基于 vocnet 方案）
- [ ] 复习卡片生成（听/说/读/写混合出题）
- [ ] 艾宾浩斯复习曲线可视化
- [ ] 学习数据自动沉淀（每日学习量 / 掌握度 / 连续打卡）

## 阶段八：习题集与题库 ✅ 基础版

- [x] 收集习题资源
  - [x] IELTS 雅思阅读理解题（参考 LuchoBazz/ielts-ai-dataset）
  - [x] CET4/CET6 词汇语法题（自建 + 参考 wamich/english-exem-md）
  - [x] TOEFL 词汇题
- [x] 统一习题数据格式（type / question / options / answer / explanation / difficulty / category）
- [x] 习题练习模式（按类型 / 难度 / 考试类别筛选）
- [x] 模拟考试模式（10分钟计时 / 20题 / 成绩报告）
- [x] 听力题支持 TTS 播放
- [x] 答题解析展示
- [x] 练习记录保存到数据库
- [ ] 扩充更多真题（四六级历年真题、雅思全套模拟）
- [ ] 按考试场次组卷（如 cet4-2023-12-1）

## 阶段九：数据统计与用户档案 ✅ 基础版

- [x] 学习仪表盘（今日学习概览 / 各技能进度）
- [x] 技能分布统计（听/说/读/写练习次数）
- [x] 最近练习记录列表
- [x] 连续打卡天数统计
- [x] 累计学习天数统计
- [x] 学习日历热力图（近12周，GitHub 风格）
- [x] 首页实时数据展示（连续打卡 / 今日练习 / 正确率）
- [ ] 词汇掌握度跟踪（听说读写分项 0-5 级，参考 vocnet）
- [ ] 错题分布与薄弱项分析
- [ ] 导出 / 导入学习数据

## 阶段十：优化与部署 ✅ 基础版

- [x] 深色模式（Material 3 dynamic color + 手动切换）
- [x] 设置页面（主题切换 / TTS 语速 / 每日目标 / 数据管理）
- [x] 离线支持（本地数据库 + 资源预加载，完全离线可用）
- [x] 安卓 Debug APK 构建成功
- [ ] 横屏适配与平板布局
- [ ] 性能优化（懒加载 / 列表虚拟化）
- [ ] Release APK 签名打包与发布

---

## 资源参考清单

| 资源 | 仓库 | 用途 |
|------|------|------|
| 综合平台参考 | RealKai42/qwerty-learner | 打字练习 + 词库架构 |
| 全功能参考 | mutou2025/echolearner | 听写 + 口语跟读 + 复习 |
| 单词练习 | zyronon/TypeWords | 跟写/听写/自测/默写模式 |
| 词库（中文释义） | KyleBing/english-vocabulary | CET/考研/托福/SAT JSON |
| 词库（含例句） | zhenghaoyang24/english-vocabulary | 10万词 + 14万例句 |
| 高频词表 | first20hours/google-10000-english | 10000 高频词 |
| 词汇管理平台 | eslsoft/vocnet | FSRS 算法 + 分项掌握度 |
| 听力专项 | pengxiaohua/listenly | 听写 + 影子跟读 + AI 打分 |
| 听力平台 | YusufOzaslan/AI-Listen | GPT-4 对话 + TTS + 出题 |
| 雅思题库 | LuchoBazz/ielts-ai-dataset | 听力/阅读/写作 JSON 题库 |
| 四六级真题 | wamich/english-exem-md | 历年真题 Markdown |
| 雅思资料 | zeeklog/IELTS | 真题 + 范文 + 音频 |
| AI 测验 | WanMuhafidzFaldi/gadet-english-quiz | 语法/词汇/阅读/听力测验 |
| 写作批改 | dffge552/english-learn.app | AI 写作评分 + 翻译练习 |
| 资源合集 | yvoronoy/awesome-english | 英语学习资源大全 |

---

## 技术栈

- **框架**: Flutter 3.x + Dart 3.x
- **UI**: Material 3 (MaterialApp)
- **路由**: go_router
- **状态管理**: Riverpod (flutter_riverpod)
- **本地存储**: Isar / sqflite
- **复习算法**: FSRS (fsrs_dart 或自实现)
- **语音**: flutter_tts (TTS) + speech_to_text (STT)
- **音频播放**: just_audio
- **网络**: dio (可选，用于 AI API 调用)
- **AI（可选）**: Groq / Gemini / OpenAI API
- **平台**: Android 优先（后续支持 iOS）
