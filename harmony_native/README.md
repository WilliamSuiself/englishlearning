# 英语学习工具鸿蒙原生版

这是从当前 Flutter 英语学习项目拆出的原生 HarmonyOS / ArkTS 版本，目录可直接用 DevEco Studio 打开。

## 已实现功能

- 首页：学习概览、技能入口、词库/题库/阅读材料数量统计
- 背单词：读取 `words_all.json`，支持 CET4、CET6、考研、TOEFL 过滤，卡片翻转显示释义和例句
- 习题练习：读取 `quizzes.json`，随机 10 题，显示答案反馈和解析
- 阅读练习：读取 `readings.json`，随机文章阅读并完成理解题
- 学习统计：使用 HarmonyOS Preferences 本地保存练习次数、正确率和连续学习天数
- TTS/语音播放：使用 HarmonyOS Core Speech Kit 朗读单词、释义例句、习题和阅读正文，支持停止播放

## 数据位置

原 Flutter 数据已复制到：

```text
entry/src/main/resources/rawfile/data/
```

包含：

- `words_all.json`
- `quizzes.json`
- `readings.json`
- `examples.json`

## 运行方式

1. 使用 DevEco Studio 打开 `harmony_native` 目录。
2. 等待 hvigor 同步依赖。
3. 在 `File > Project Structure > Signing Configs` 配置自动签名或使用你的调试证书。
4. 连接鸿蒙手机并打开开发者模式。
5. 选择 `entry` 模块，点击 Run 安装运行。

## 说明

当前 TTS 会优先尝试英语（美国）劳拉女声音色 `en-US/person:8`。如果设备未下载该英语音色包，会自动回退到系统可用的中文语境 TTS，保证至少可以播放。Flutter 版里的语音识别、SQLite 错题本等能力，需要后续接入 HarmonyOS 对应 Kit 或数据库后继续增强。
