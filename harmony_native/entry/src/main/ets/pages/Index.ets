import common from '@ohos.app.ability.common';
import preferences from '@ohos.data.preferences';
import promptAction from '@ohos.promptAction';
import util from '@ohos.util';
import { textToSpeech } from '@kit.CoreSpeechKit';

interface Word {
  word: string;
  definition: string;
  phonetic_us?: string;
  definition_en?: string;
  part_of_speech?: string;
  level?: string;
  exchange?: string;
}

interface ExampleSentence {
  en: string;
  cn: string;
}

interface QuizQuestion {
  type: string;
  question: string;
  options: string[];
  correct_index: number;
  explanation?: string;
  difficulty?: string;
  category?: string;
}

interface ReadingQuestion {
  question: string;
  options: string[];
  answer: number;
}

interface ReadingArticle {
  title: string;
  level: string;
  text: string[] | string;
  questions: ReadingQuestion[];
}

interface SkillEntry {
  key: string;
  title: string;
  subtitle: string;
  icon: string;
  color: string;
}

class StudyStats {
  vocabularyTotal: number = 0;
  vocabularyKnown: number = 0;
  quizTotal: number = 0;
  quizCorrect: number = 0;
  readingTotal: number = 0;
  readingCorrect: number = 0;
  streak: number = 0;
  lastStudyDate: string = '';

  static from(value: StudyStats): StudyStats {
    const next = new StudyStats();
    next.vocabularyTotal = value.vocabularyTotal;
    next.vocabularyKnown = value.vocabularyKnown;
    next.quizTotal = value.quizTotal;
    next.quizCorrect = value.quizCorrect;
    next.readingTotal = value.readingTotal;
    next.readingCorrect = value.readingCorrect;
    next.streak = value.streak;
    next.lastStudyDate = value.lastStudyDate;
    return next;
  }
}

@Entry
@Component
struct Index {
  @State activePage: string = 'home';
  @State isLoading: boolean = true;
  @State loadMessage: string = '正在加载本地词库...';
  @State stats: StudyStats = new StudyStats();
  @State roundWords: Word[] = [];
  @State wordIndex: number = 0;
  @State showDefinition: boolean = false;
  @State selectedLevel: string = '全部';
  @State knownInRound: number = 0;
  @State unknownInRound: number = 0;
  @State quizQuestions: QuizQuestion[] = [];
  @State quizIndex: number = 0;
  @State quizSelected: number = -1;
  @State quizAnswered: boolean = false;
  @State quizCorrect: number = 0;
  @State readingIndex: number = 0;
  @State readingQuestionIndex: number = 0;
  @State readingSelected: number = -1;
  @State readingAnswered: boolean = false;
  @State readingCorrect: number = 0;
  @State showReadingText: boolean = true;
  @State isSpeaking: boolean = false;
  @State ttsStatus: string = '语音未初始化';
  @State wordStatus: Record<string, string> = {};
  @State knownWordsCount: number = 0;
  @State unknownWordsCount: number = 0;
  @State reviewMode: boolean = false;
  @State reviewWords: Word[] = [];
  @State reviewIndex: number = 0;
  @State reviewShowDefinition: boolean = false;

  private wordBank: Word[] = [];
  private quizBank: QuizQuestion[] = [];
  private readingBank: ReadingArticle[] = [];
  private examplesMap: Record<string, ExampleSentence[]> = {};
  private pref?: preferences.Preferences;
  private ttsEngine?: textToSpeech.TextToSpeechEngine;
  private ttsLastError: string = '';
  private levels: string[] = ['全部', 'CET4', 'CET6', '考研', 'TOEFL'];
  private skills: SkillEntry[] = [
    { key: 'vocabulary', title: '背单词', subtitle: '随机抽词 · 卡片翻转', icon: 'Aa', color: '#4F46E5' },
    { key: 'quiz', title: '习题练习', subtitle: '词汇 · 语法 · 阅读', icon: '?', color: '#16A34A' },
    { key: 'reading', title: '阅读练习', subtitle: '文章 · 理解题', icon: 'R', color: '#0F766E' },
    { key: 'review', title: '单词复习', subtitle: '掌握 · 生词', icon: 'Re', color: '#9333EA' },
    { key: 'stats', title: '学习统计', subtitle: '进度 · 正确率', icon: '%', color: '#EA580C' }
  ];

  aboutToAppear(): void {
    this.bootstrap();
  }

  aboutToDisappear(): void {
    try {
      if (this.ttsEngine) {
        this.ttsEngine.shutdown();
      }
    } catch (_err) {
    }
  }

  private privacyPolicyMessage(): string {
    return '隐私政策\n\n' +
      '生效日期：2026年9月25日\n\n' +
      'HEIDI英语学习（包名 com.englishlearning.suiyunhai）是一款完全离线运行的单机学习工具。我们不会收集、存储、传输或与任何第三方共享您的任何个人信息或使用数据。您的所有学习数据仅保存在您本人设备上。\n\n' +
      '1. 我们不收集的信息\n本应用不会收集个人身份信息、设备标识、位置、通讯录、相册、麦克风数据，以及您的学习记录、答题结果、浏览行为等使用数据。\n\n' +
      '2. 本地存储的数据\n为提供背单词进度、答题正确率、阅读完成情况、连续学习天数等功能，本应用使用 HarmonyOS 本地首选项（Preferences）保存学习统计数据。这些数据仅保存在您本人设备上，不会上传服务器，卸载应用时会被系统清除。\n\n' +
      '3. 权限说明\n本应用仅申请网络权限（INTERNET），用于调用系统内置 TTS 引擎临时请求语音数据，不涉及个人信息上传。无网络时会自动回退离线模式。\n\n' +
      '4. 第三方服务\n本应用不集成第三方统计、广告或社交 SDK。TTS 能力由 HarmonyOS CoreSpeechKit 提供，遵循系统级隐私规范。\n\n' +
      '5. 未成年人保护\n本应用不收集个人信息，不含社交、支付、广告功能，不会对未成年人隐私造成风险。\n\n' +
      '6. 联系我们\n开发者：隋云海\n邮箱：1325574780@qq.com\n\n' +
      '请仔细阅读并确认是否同意本隐私政策。如不同意，我们将无法为您提供服务。\n\n' +
      '完整隐私政策请访问：https://english-learning-privacy.pages.dev';
  }

  private async checkPrivacyPolicy(): Promise<void> {
    if (!this.pref) {
      return;
    }
    const accepted = await this.pref.get('privacyAccepted', false) as boolean;
    if (accepted) {
      return;
    }
    try {
      const result = await promptAction.showDialog({
        title: '隐私政策',
        message: this.privacyPolicyMessage(),
        buttons: [
          { text: '不同意并退出', color: '#64748B' },
          { text: '已阅读并同意', color: '#4F46E5' }
        ]
      });
      if (result.index === 1) {
        await this.pref.put('privacyAccepted', true);
        await this.pref.flush();
      } else {
        promptAction.showToast({ message: '需要同意隐私政策才能继续使用' });
        await (getContext(this) as common.UIAbilityContext).terminateSelf();
      }
    } catch (_err) {
      promptAction.showToast({ message: '需要同意隐私政策才能继续使用' });
      await (getContext(this) as common.UIAbilityContext).terminateSelf();
    }
  }

  async bootstrap(): Promise<void> {
    try {
      await this.loadStudyStats();
      await this.initTts();
      this.wordBank = await this.loadJson<Word[]>('data/words_all.json');
      this.quizBank = await this.loadJson<QuizQuestion[]>('data/quizzes.json');
      this.readingBank = await this.loadJson<ReadingArticle[]>('data/readings.json');
      this.examplesMap = await this.loadJson<Record<string, ExampleSentence[]>>('data/examples.json');
      this.startVocabularyRound();
      this.startQuizRound();
      this.pickReadingArticle();
      this.isLoading = false;
      await this.checkPrivacyPolicy();
    } catch (err) {
      this.loadMessage = `加载失败：${JSON.stringify(err)}`;
      promptAction.showToast({ message: '学习数据加载失败，请检查 rawfile 数据。' });
    }
  }

  private async initTts(): Promise<boolean> {
    if (this.ttsEngine) {
      return true;
    }

    const candidates: textToSpeech.CreateEngineParams[] = [
      { language: 'en-US', person: 8, online: 1, extraParams: { 'style': 'interaction-broadcast', 'locate': 'CN', 'name': 'EnglishLearningTts' } },
      { language: 'en-US', person: 8, online: 0, extraParams: { 'style': 'interaction-broadcast', 'locate': 'CN', 'name': 'EnglishLearningTts' } },
      { language: 'en-US', person: 0, online: 1, extraParams: { 'style': 'interaction-broadcast', 'locate': 'CN', 'name': 'EnglishLearningTts' } },
      { language: 'en-US', person: 1, online: 1, extraParams: { 'style': 'interaction-broadcast', 'locate': 'CN', 'name': 'EnglishLearningTts' } },
      { language: 'en-US', person: 2, online: 1, extraParams: { 'style': 'interaction-broadcast', 'locate': 'CN', 'name': 'EnglishLearningTts' } },
      { language: 'en-US', person: 0, online: 0, extraParams: { 'style': 'interaction-broadcast', 'locate': 'CN', 'name': 'EnglishLearningTts' } },
      { language: 'en_US', person: 0, online: 1, extraParams: { 'style': 'interaction-broadcast', 'locate': 'CN', 'name': 'EnglishLearningTts' } },
      { language: 'zh-CN', person: 0, online: 1, extraParams: { 'style': 'interaction-broadcast', 'locate': 'CN', 'name': 'EnglishLearningTts' } }
    ];

    let engine: textToSpeech.TextToSpeechEngine | undefined = undefined;
    for (const candidate of candidates) {
      engine = await this.createTtsEngine(candidate);
      if (engine) {
        break;
      }
    }
    if (!engine) {
      this.ttsStatus = this.ttsLastError.length > 0 ? `TTS 失败：${this.ttsLastError}` : 'TTS 初始化失败';
      return false;
    }

    engine.setListener({
      onStart: (_requestId: string, _response: textToSpeech.StartResponse): void => {
        this.isSpeaking = true;
        this.ttsStatus = '正在播放';
      },
      onComplete: (_requestId: string, _response: textToSpeech.CompleteResponse): void => {
        this.isSpeaking = false;
        this.ttsStatus = '播放完成';
      },
      onStop: (_requestId: string, _response: textToSpeech.StopResponse): void => {
        this.isSpeaking = false;
        this.ttsStatus = '已停止';
      },
      onError: (_requestId: string, errorCode: number, errorMessage: string): void => {
        this.isSpeaking = false;
        this.ttsStatus = `播放失败 ${errorCode}`;
        promptAction.showToast({ message: `TTS 播放失败：${errorMessage}` });
      }
    });

    this.ttsEngine = engine;
    this.ttsStatus = 'TTS 已就绪';
    return true;
  }

  private async createTtsEngine(params: textToSpeech.CreateEngineParams): Promise<textToSpeech.TextToSpeechEngine | undefined> {
    try {
      const engine = await textToSpeech.createEngine(params);
      this.ttsLastError = '';
      return engine;
    } catch (err) {
      const value = err as Error;
      this.ttsLastError = `${params.language}/${params.person}/${params.online}: ${value.message ?? JSON.stringify(err)}`;
      return undefined;
    }
  }

  private async speakText(text: string): Promise<void> {
    const content = text.trim();
    if (content.length === 0) {
      return;
    }
    const ready = await this.initTts();
    if (!ready || !this.ttsEngine) {
      promptAction.showToast({ message: '当前设备 TTS 不可用，请检查系统语音服务。' });
      return;
    }
    try {
      if (this.ttsEngine.isBusy()) {
        this.ttsEngine.stop();
      }
      this.ttsEngine.speak(this.normalizeSpeechText(content), {
        requestId: `tts_${Date.now()}_${Math.floor(Math.random() * 10000)}`
      });
    } catch (err) {
      this.isSpeaking = false;
      this.ttsStatus = '播放失败';
      promptAction.showToast({ message: `播放失败：${JSON.stringify(err)}` });
    }
  }

  private stopSpeaking(): void {
    try {
      if (this.ttsEngine && this.ttsEngine.isBusy()) {
        this.ttsEngine.stop();
      }
      this.isSpeaking = false;
      this.ttsStatus = '已停止';
    } catch (_err) {
      this.isSpeaking = false;
    }
  }

  private normalizeSpeechText(text: string): string {
    const cleaned = text.replace(/\s+/g, ' ').trim();
    return cleaned.length > 900 ? `${cleaned.substring(0, 900)}.` : cleaned;
  }

  private speakCurrentWord(): void {
    if (this.roundWords.length > 0) {
      this.speakText(this.currentWord().word);
    }
  }

  private speakCurrentWordDetail(): void {
    if (this.roundWords.length === 0) {
      return;
    }
    const word = this.currentWord();
    const example = this.firstExampleEn(word.word);
    this.speakText(`${word.word}. ${word.definition_en ?? word.definition}. ${example}`);
  }

  private speakCurrentQuiz(): void {
    if (this.quizQuestions.length === 0) {
      return;
    }
    const q = this.currentQuizQuestion();
    this.speakText(`${q.question}. ${q.options.join('. ')}`);
  }

  private speakCurrentReading(): void {
    if (this.readingBank.length === 0) {
      return;
    }
    const article = this.currentReadingArticle();
    this.speakText(`${article.title}. ${this.articleText(article)}`);
  }

  private speakCurrentReadingQuestion(article: ReadingArticle): void {
    const q = article.questions[this.readingQuestionIndex];
    this.speakText(`${q.question}. ${q.options.join('. ')}`);
  }

  private async loadJson<T>(path: string): Promise<T> {
    const context = getContext(this) as common.UIAbilityContext;
    const content = await context.resourceManager.getRawFileContent(path);
    const decoder = new util.TextDecoder('utf-8', { ignoreBOM: true });
    return JSON.parse(decoder.decodeWithStream(content)) as T;
  }

  private async loadStudyStats(): Promise<void> {
    const context = getContext(this) as common.UIAbilityContext;
    this.pref = await preferences.getPreferences(context, 'english_learning_stats');
    const raw = await this.pref.get('stats', '') as string;
    if (raw.length > 0) {
      const parsed = JSON.parse(raw) as StudyStats;
      const next = new StudyStats();
      next.vocabularyTotal = parsed.vocabularyTotal ?? 0;
      next.vocabularyKnown = parsed.vocabularyKnown ?? 0;
      next.quizTotal = parsed.quizTotal ?? 0;
      next.quizCorrect = parsed.quizCorrect ?? 0;
      next.readingTotal = parsed.readingTotal ?? 0;
      next.readingCorrect = parsed.readingCorrect ?? 0;
      next.streak = parsed.streak ?? 0;
      next.lastStudyDate = parsed.lastStudyDate ?? '';
      this.stats = next;
    }
    const marks = await this.pref.get('wordStatus', '') as string;
    if (marks.length > 0) {
      try {
        this.wordStatus = JSON.parse(marks) as Record<string, string>;
      } catch (_err) {
        this.wordStatus = {};
      }
    }
    this.refreshWordCounts();
  }

  private async saveStats(): Promise<void> {
    this.touchStudyDate();
    if (this.pref) {
      await this.pref.put('stats', JSON.stringify(this.stats));
      await this.pref.flush();
    }
  }

  private touchStudyDate(): void {
    const today = this.todayKey();
    const yesterday = this.offsetDateKey(-1);
    const next = StudyStats.from(this.stats);
    if (next.lastStudyDate !== today) {
      next.streak = next.lastStudyDate === yesterday ? next.streak + 1 : 1;
      next.lastStudyDate = today;
      this.stats = next;
    }
  }

  private todayKey(): string {
    const d = new Date();
    return `${d.getFullYear()}-${this.pad(d.getMonth() + 1)}-${this.pad(d.getDate())}`;
  }

  private offsetDateKey(offsetDays: number): string {
    const d = new Date(Date.now() + offsetDays * 24 * 60 * 60 * 1000);
    return `${d.getFullYear()}-${this.pad(d.getMonth() + 1)}-${this.pad(d.getDate())}`;
  }

  private pad(value: number): string {
    return value < 10 ? `0${value}` : `${value}`;
  }

  private shuffled<T>(items: T[]): T[] {
    const result = items.slice();
    for (let i = result.length - 1; i > 0; i--) {
      const j = Math.floor(Math.random() * (i + 1));
      const temp = result[i];
      result[i] = result[j];
      result[j] = temp;
    }
    return result;
  }

  private startVocabularyRound(): void {
    const source = this.selectedLevel === '全部'
      ? this.wordBank
      : this.wordBank.filter((item: Word) => item.level === this.selectedLevel);
    this.roundWords = this.shuffled(source).slice(0, 20);
    this.wordIndex = 0;
    this.showDefinition = false;
    this.knownInRound = 0;
    this.unknownInRound = 0;
  }

  private setWordStatus(word: string, status: string): void {
    const next: Record<string, string> = {};
    const keys = Object.keys(this.wordStatus);
    for (const key of keys) {
      next[key] = this.wordStatus[key];
    }
    next[word] = status;
    this.wordStatus = next;
    this.refreshWordCounts();
    this.saveWordStatus();
  }

  private refreshWordCounts(): void {
    this.knownWordsCount = this.countByStatus('known');
    this.unknownWordsCount = this.countByStatus('unknown');
  }

  private async saveWordStatus(): Promise<void> {
    if (this.pref) {
      await this.pref.put('wordStatus', JSON.stringify(this.wordStatus));
      await this.pref.flush();
    }
  }

  private countByStatus(status: string): number {
    let count = 0;
    const keys = Object.keys(this.wordStatus);
    for (const key of keys) {
      if (this.wordStatus[key] === status) {
        count += 1;
      }
    }
    return count;
  }

  private unmarkedCount(): number {
    const rest = this.wordBank.length - this.knownWordsCount - this.unknownWordsCount;
    return rest > 0 ? rest : 0;
  }

  private statValueFor(kind: string): number {
    switch (kind) {
      case 'streak':
        return this.stats.streak;
      case 'practices':
        return this.totalPractices();
      case 'bank':
        return this.wordBank.length;
      case 'known':
        return this.knownWordsCount;
      case 'unknown':
        return this.unknownWordsCount;
      case 'new':
        return this.unmarkedCount();
      default:
        return 0;
    }
  }

  private unknownWordList(): Word[] {
    return this.wordBank.filter((item: Word) => this.wordStatus[item.word] === 'unknown');
  }

  private startReview(): void {
    const list = this.unknownWordList();
    if (list.length === 0) {
      promptAction.showToast({ message: '暂无不认识的单词' });
      return;
    }
    this.reviewWords = this.shuffled(list);
    this.reviewIndex = 0;
    this.reviewShowDefinition = false;
    this.reviewMode = true;
  }

  private currentReviewWord(): Word {
    return this.reviewWords[this.reviewIndex];
  }

  private markReviewWord(known: boolean): void {
    if (this.reviewWords.length === 0) {
      return;
    }
    if (known) {
      this.setWordStatus(this.currentReviewWord().word, 'known');
    }
    if (this.reviewIndex >= this.reviewWords.length - 1) {
      this.reviewMode = false;
      promptAction.showToast({ message: `复习完成：共 ${this.reviewWords.length} 个单词` });
      return;
    }
    this.reviewIndex += 1;
    this.reviewShowDefinition = false;
  }

  private speakReviewWord(): void {
    if (this.reviewWords.length > 0) {
      this.speakText(this.currentReviewWord().word);
    }
  }

  private speakReviewWordDetail(): void {
    if (this.reviewWords.length === 0) {
      return;
    }
    const word = this.currentReviewWord();
    const example = this.firstExampleEn(word.word);
    this.speakText(`${word.word}. ${word.definition_en ?? word.definition}. ${example}`);
  }

  private markWord(known: boolean): void {
    if (known) {
      this.knownInRound += 1;
    } else {
      this.unknownInRound += 1;
    }
    if (this.roundWords.length > 0) {
      this.setWordStatus(this.currentWord().word, known ? 'known' : 'unknown');
    }
    const nextStats = StudyStats.from(this.stats);
    nextStats.vocabularyTotal += 1;
    nextStats.vocabularyKnown += known ? 1 : 0;
    this.stats = nextStats;
    this.saveStats();

    if (this.wordIndex >= this.roundWords.length - 1) {
      promptAction.showToast({ message: `本轮完成：认识 ${this.knownInRound}，不认识 ${this.unknownInRound}` });
      this.startVocabularyRound();
      return;
    }
    this.wordIndex += 1;
    this.showDefinition = false;
  }

  private startQuizRound(): void {
    this.quizQuestions = this.shuffled(this.quizBank).slice(0, 10);
    this.quizIndex = 0;
    this.quizSelected = -1;
    this.quizAnswered = false;
    this.quizCorrect = 0;
  }

  private selectQuizAnswer(index: number): void {
    if (this.quizAnswered || this.quizQuestions.length === 0) {
      return;
    }
    this.quizSelected = index;
    this.quizAnswered = true;
    if (index === this.quizQuestions[this.quizIndex].correct_index) {
      this.quizCorrect += 1;
    }
  }

  private nextQuizQuestion(): void {
    if (this.quizQuestions.length === 0) {
      return;
    }
    if (this.quizIndex >= this.quizQuestions.length - 1) {
      const nextStats = StudyStats.from(this.stats);
      nextStats.quizTotal += this.quizQuestions.length;
      nextStats.quizCorrect += this.quizCorrect;
      this.stats = nextStats;
      this.saveStats();
      promptAction.showToast({ message: `练习完成：${this.quizCorrect}/${this.quizQuestions.length}` });
      this.startQuizRound();
      return;
    }
    this.quizIndex += 1;
    this.quizSelected = -1;
    this.quizAnswered = false;
  }

  private pickReadingArticle(): void {
    if (this.readingBank.length === 0) {
      return;
    }
    this.readingIndex = Math.floor(Math.random() * this.readingBank.length);
    this.readingQuestionIndex = 0;
    this.readingSelected = -1;
    this.readingAnswered = false;
    this.readingCorrect = 0;
    this.showReadingText = true;
  }

  private articleText(article: ReadingArticle): string {
    if (Array.isArray(article.text)) {
      return article.text.join('\n\n');
    }
    return article.text;
  }

  private selectReadingAnswer(index: number): void {
    if (this.readingAnswered || this.readingBank.length === 0) {
      return;
    }
    const question = this.readingBank[this.readingIndex].questions[this.readingQuestionIndex];
    this.readingSelected = index;
    this.readingAnswered = true;
    if (index === question.answer) {
      this.readingCorrect += 1;
    }
  }

  private nextReadingQuestion(): void {
    const article = this.readingBank[this.readingIndex];
    if (this.readingQuestionIndex >= article.questions.length - 1) {
      const nextStats = StudyStats.from(this.stats);
      nextStats.readingTotal += article.questions.length;
      nextStats.readingCorrect += this.readingCorrect;
      this.stats = nextStats;
      this.saveStats();
      promptAction.showToast({ message: `阅读完成：${this.readingCorrect}/${article.questions.length}` });
      this.pickReadingArticle();
      return;
    }
    this.readingQuestionIndex += 1;
    this.readingSelected = -1;
    this.readingAnswered = false;
  }

  private totalPractices(): number {
    return this.stats.vocabularyTotal + this.stats.quizTotal + this.stats.readingTotal;
  }

  private totalAccuracy(): number {
    const total = this.stats.vocabularyTotal + this.stats.quizTotal + this.stats.readingTotal;
    if (total === 0) {
      return 0;
    }
    const correct = this.stats.vocabularyKnown + this.stats.quizCorrect + this.stats.readingCorrect;
    return Math.round(correct * 100 / total);
  }

  private optionColor(answered: boolean, selected: number, correct: number, index: number): string {
    if (!answered) {
      return '#FFFFFF';
    }
    if (index === correct) {
      return '#DCFCE7';
    }
    if (index === selected) {
      return '#FEE2E2';
    }
    return '#FFFFFF';
  }

  private currentWord(): Word {
    return this.roundWords[this.wordIndex];
  }

  private firstExampleEn(word: string): string {
    const examples = this.examplesMap[word] ?? [];
    return examples.length > 0 ? examples[0].en : '';
  }

  private firstExampleCn(word: string): string {
    const examples = this.examplesMap[word] ?? [];
    return examples.length > 0 ? examples[0].cn : '';
  }

  private hasExample(word: string): boolean {
    return (this.examplesMap[word] ?? []).length > 0;
  }

  private currentQuizQuestion(): QuizQuestion {
    return this.quizQuestions[this.quizIndex];
  }

  private currentReadingArticle(): ReadingArticle {
    return this.readingBank[this.readingIndex];
  }

  private progressPercent(correct: number, total: number): number {
    return total === 0 ? 0 : Math.round(correct * 100 / total);
  }

  build() {
    Column() {
      if (this.isLoading) {
        this.LoadingPage();
      } else {
        this.Header();
        this.MainContent();
        this.BottomNav();
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F6F7FB')
  }

  @Builder
  LoadingPage() {
    Column() {
      LoadingProgress()
        .width(48)
        .height(48)
        .color('#4F46E5')
      Text(this.loadMessage)
        .fontSize(16)
        .fontColor('#475569')
        .margin({ top: 16 })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  Header() {
    Row() {
      Column() {
        Text('HEIDI英语学习')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor('#0F172A')
        Text('原生鸿蒙版')
          .fontSize(13)
          .fontColor('#64748B')
          .margin({ top: 4 })
      }
      .alignItems(HorizontalAlign.Start)
      Blank()
      Column() {
        Text(`${this.totalAccuracy()}%`)
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor('#4F46E5')
        Text('正确率')
          .fontSize(12)
          .fontColor('#64748B')
      }
      .margin({ right: 10 })
      Button(this.isSpeaking ? '停止' : this.ttsStatus)
        .fontSize(12)
        .height(34)
        .backgroundColor(this.isSpeaking ? '#EF4444' : '#EEF2FF')
        .fontColor(this.isSpeaking ? '#FFFFFF' : '#4F46E5')
        .onClick(() => {
          if (this.isSpeaking) {
            this.stopSpeaking();
          }
        })
    }
    .width('100%')
    .padding({ left: 20, right: 20, top: 16, bottom: 12 })
    .backgroundColor('#FFFFFF')
  }

  @Builder
  MainContent() {
    if (this.activePage === 'home') {
      this.HomePage();
    } else if (this.activePage === 'vocabulary') {
      this.VocabularyPage();
    } else if (this.activePage === 'quiz') {
      this.QuizPage();
    } else if (this.activePage === 'reading') {
      this.ReadingPage();
    } else if (this.activePage === 'review') {
      this.ReviewPage();
    } else {
      this.StatsPage();
    }
  }

  @Builder
  HomePage() {
    Scroll() {
      Column() {
        Row() {
          Text('欢迎回来')
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF')
          Blank()
          Text('每天进步一点点')
            .fontSize(13)
            .fontColor('#E0E7FF')
        }
        .width('100%')
        .padding(20)
        .borderRadius(24)
        .backgroundColor('#4F46E5')

        Row() {
          this.StatCard('连续打卡', 'streak', '天', '#F97316');
          this.StatCard('累计练习', 'practices', '次', '#2563EB');
          this.StatCard('本地词库', 'bank', '词', '#16A34A');
        }
        .margin({ top: 16 })

        Text('技能练习')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#0F172A')
          .width('100%')
          .margin({ top: 24, bottom: 12 })

        Grid() {
          ForEach(this.skills, (item: SkillEntry) => {
            GridItem() {
              this.SkillCard(item);
            }
          }, (item: SkillEntry) => item.key)
        }
        .columnsTemplate('1fr 1fr')
        .columnsGap(12)
        .rowsGap(12)
        .height(444)
      }
      .padding(16)
    }
    .layoutWeight(1)
  }

  @Builder
  StatCard(label: string, kind: string, unit: string, color: string) {
    Column() {
      Text(`${this.statValueFor(kind)}`)
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .fontColor(color)
      Text(unit)
        .fontSize(11)
        .fontColor('#94A3B8')
      Text(label)
        .fontSize(12)
        .fontColor('#475569')
        .margin({ top: 6 })
    }
    .layoutWeight(1)
    .height(92)
    .justifyContent(FlexAlign.Center)
    .backgroundColor('#FFFFFF')
    .borderRadius(18)
    .margin({ right: 8 })
  }

  @Builder
  SkillCard(item: SkillEntry) {
    Column() {
      Text(item.icon)
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFFFFF')
        .width(52)
        .height(52)
        .textAlign(TextAlign.Center)
        .backgroundColor(item.color)
        .borderRadius(18)
      Text(item.title)
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#0F172A')
        .margin({ top: 14 })
      Text(item.subtitle)
        .fontSize(12)
        .fontColor('#64748B')
        .margin({ top: 6 })
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .height(140)
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(22)
    .onClick(() => {
      this.activePage = item.key;
    })
  }

  @Builder
  VocabularyPage() {
    Column() {
      Row() {
        ForEach(this.levels, (level: string) => {
          Text(level)
            .fontSize(14)
            .fontColor(this.selectedLevel === level ? '#FFFFFF' : '#334155')
            .padding({ left: 14, right: 14, top: 8, bottom: 8 })
            .backgroundColor(this.selectedLevel === level ? '#4F46E5' : '#FFFFFF')
            .borderRadius(18)
            .margin({ right: 8 })
            .onClick(() => {
              this.selectedLevel = level;
              this.startVocabularyRound();
            })
        }, (level: string) => level)
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 14, bottom: 8 })

      if (this.roundWords.length > 0) {
        Progress({ value: this.wordIndex + 1, total: this.roundWords.length, type: ProgressType.Linear })
          .width('90%')
          .color('#4F46E5')
          .backgroundColor('#E2E8F0')
        Text(`${this.wordIndex + 1}/${this.roundWords.length}`)
          .fontSize(12)
          .fontColor('#64748B')
          .margin({ top: 6 })

        Column() {
          Text(this.currentWord().word)
            .fontSize(42)
            .fontWeight(FontWeight.Bold)
            .fontColor('#0F172A')
          Text(this.currentWord().phonetic_us ? `/${this.currentWord().phonetic_us}/` : '点击卡片查看释义')
            .fontSize(16)
            .fontColor('#64748B')
            .margin({ top: 10 })
          Row() {
            Button('单词发音')
              .height(38)
              .fontSize(14)
              .backgroundColor('#4F46E5')
              .onClick(() => this.speakCurrentWord())
            Button('朗读详情')
              .height(38)
              .fontSize(14)
              .backgroundColor('#0F766E')
              .margin({ left: 10 })
              .onClick(() => this.speakCurrentWordDetail())
          }
          .margin({ top: 16 })

          if (this.showDefinition) {
            Scroll() {
              Column() {
                Text(this.currentWord().part_of_speech ? this.currentWord().part_of_speech : '')
                  .fontSize(14)
                  .fontColor('#4F46E5')
                Text(this.currentWord().definition)
                  .fontSize(22)
                  .fontWeight(FontWeight.Medium)
                  .fontColor('#0F172A')
                  .textAlign(TextAlign.Center)
                  .margin({ top: 8 })
                Text(this.currentWord().definition_en ? this.currentWord().definition_en : '')
                  .fontSize(14)
                  .fontColor('#64748B')
                  .textAlign(TextAlign.Center)
                  .margin({ top: 10 })
                this.ExampleBlock(this.currentWord().word);
              }
              .width('100%')
            }
            .layoutWeight(1)
            .width('100%')
            .align(Alignment.Top)
            .margin({ top: 22 })
          }
        }
        .layoutWeight(1)
        .width('92%')
        .justifyContent(this.showDefinition ? FlexAlign.Start : FlexAlign.Center)
        .padding(24)
        .backgroundColor('#FFFFFF')
        .borderRadius(28)
        .margin({ top: 18, bottom: 16 })
        .onClick(() => {
          this.showDefinition = !this.showDefinition;
        })

        Row() {
          Button('不认识')
            .layoutWeight(1)
            .height(48)
            .backgroundColor('#EF4444')
            .onClick(() => this.markWord(false))
          Button('认识')
            .layoutWeight(1)
            .height(48)
            .backgroundColor('#16A34A')
            .margin({ left: 12 })
            .onClick(() => this.markWord(true))
        }
        .width('92%')
        .margin({ bottom: 16 })
      } else {
        Text('当前级别暂无词库数据')
          .fontSize(16)
          .fontColor('#64748B')
          .layoutWeight(1)
      }
    }
    .layoutWeight(1)
    .width('100%')
  }

  @Builder
  ExampleBlock(word: string) {
    if (this.hasExample(word)) {
      Column() {
        Text(this.firstExampleEn(word))
          .fontSize(14)
          .fontColor('#334155')
          .textAlign(TextAlign.Center)
        Text(this.firstExampleCn(word))
          .fontSize(13)
          .fontColor('#64748B')
          .textAlign(TextAlign.Center)
          .margin({ top: 6 })
      }
      .padding(14)
      .backgroundColor('#F8FAFC')
      .borderRadius(16)
      .margin({ top: 16 })
    }
  }

  @Builder
  QuizPage() {
    if (this.quizQuestions.length > 0) {
      Column() {
        Text(`第 ${this.quizIndex + 1}/${this.quizQuestions.length} 题 · ${this.currentQuizQuestion().category ?? '综合'} · ${this.currentQuizQuestion().difficulty ?? 'mixed'}`)
          .fontSize(13)
          .fontColor('#64748B')
          .width('100%')
          .padding({ left: 20, top: 16 })
        Button('朗读题目和选项')
          .height(38)
          .fontSize(14)
          .backgroundColor('#4F46E5')
          .margin({ left: 20, right: 20, top: 10 })
          .onClick(() => this.speakCurrentQuiz())

        Scroll() {
          Column() {
            Text(this.currentQuizQuestion().question)
              .fontSize(22)
              .fontWeight(FontWeight.Bold)
              .fontColor('#0F172A')
              .lineHeight(32)
              .width('100%')

            ForEach(this.currentQuizQuestion().options, (option: string, index: number) => {
              Text(option)
                .fontSize(16)
                .fontColor('#0F172A')
                .width('100%')
                .padding(16)
                .backgroundColor(this.optionColor(this.quizAnswered, this.quizSelected, this.currentQuizQuestion().correct_index, index))
                .borderRadius(16)
                .border({ width: 1, color: this.quizSelected === index ? '#4F46E5' : '#E2E8F0' })
                .margin({ top: 12 })
                .onClick(() => this.selectQuizAnswer(index))
            }, (option: string, index: number) => `${index}-${option}`)

            if (this.quizAnswered) {
              Text(this.currentQuizQuestion().explanation ? this.currentQuizQuestion().explanation : '继续下一题。')
                .fontSize(14)
                .fontColor('#475569')
                .padding(14)
                .backgroundColor('#EEF2FF')
                .borderRadius(14)
                .margin({ top: 16 })
              Button(this.quizIndex >= this.quizQuestions.length - 1 ? '完成练习' : '下一题')
                .width('100%')
                .height(48)
                .backgroundColor('#4F46E5')
                .margin({ top: 16 })
                .onClick(() => this.nextQuizQuestion())
            }
          }
          .padding(20)
          .backgroundColor('#FFFFFF')
          .borderRadius(24)
          .margin(16)
          .width('100%')
        }
        .layoutWeight(1)
        .width('100%')

        Text(`本轮正确：${this.quizCorrect}`)
          .fontSize(14)
          .fontColor('#64748B')
          .margin({ bottom: 12 })
      }
      .layoutWeight(1)
    }
  }

  @Builder
  ReadingPage() {
    if (this.readingBank.length > 0) {
      if (this.showReadingText) {
        Column() {
          Row() {
            Text(this.currentReadingArticle().title)
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor('#0F172A')
              .maxLines(3)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .layoutWeight(1)
            Text(this.currentReadingArticle().level)
              .fontSize(12)
              .fontColor('#0F766E')
              .padding({ left: 10, right: 10, top: 5, bottom: 5 })
              .backgroundColor('#CCFBF1')
              .borderRadius(14)
              .margin({ left: 8 })
          }
          .width('100%')
          .padding(16)

          Scroll() {
            Text(this.articleText(this.currentReadingArticle()))
              .fontSize(17)
              .fontColor('#334155')
              .lineHeight(30)
              .padding({ left: 18, right: 18, bottom: 18 })
          }
          .layoutWeight(1)

          Row() {
            Button('换一篇')
              .layoutWeight(1)
              .height(48)
              .backgroundColor('#64748B')
              .onClick(() => this.pickReadingArticle())
            Button('朗读')
              .layoutWeight(1)
              .height(48)
              .backgroundColor('#4F46E5')
              .margin({ left: 12 })
              .onClick(() => this.speakCurrentReading())
            Button('开始答题')
              .layoutWeight(1)
              .height(48)
              .backgroundColor('#0F766E')
              .margin({ left: 12 })
              .onClick(() => {
                this.showReadingText = false;
                this.readingQuestionIndex = 0;
                this.readingSelected = -1;
                this.readingAnswered = false;
                this.readingCorrect = 0;
              })
          }
          .padding(16)
        }
        .layoutWeight(1)
      } else {
        this.ReadingQuestionPage(this.currentReadingArticle());
      }
    } else {
      Text('暂无阅读材料')
        .fontSize(16)
        .fontColor('#64748B')
        .layoutWeight(1)
    }
  }

  @Builder
  ReadingQuestionPage(article: ReadingArticle) {
    Column() {
      Text(`阅读题 ${this.readingQuestionIndex + 1}/${article.questions.length}`)
        .fontSize(13)
        .fontColor('#64748B')
        .width('100%')
        .padding({ left: 20, top: 16 })
      Button('朗读题目和选项')
        .height(38)
        .fontSize(14)
        .backgroundColor('#0F766E')
        .margin({ left: 20, right: 20, top: 10 })
        .onClick(() => this.speakCurrentReadingQuestion(article))
      Column() {
        Text(article.questions[this.readingQuestionIndex].question)
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor('#0F172A')
          .lineHeight(32)
          .width('100%')

        ForEach(article.questions[this.readingQuestionIndex].options, (option: string, index: number) => {
          Text(option)
            .fontSize(16)
            .fontColor('#0F172A')
            .width('100%')
            .padding(16)
            .backgroundColor(this.optionColor(this.readingAnswered, this.readingSelected, article.questions[this.readingQuestionIndex].answer, index))
            .borderRadius(16)
            .border({ width: 1, color: this.readingSelected === index ? '#0F766E' : '#E2E8F0' })
            .margin({ top: 12 })
            .onClick(() => this.selectReadingAnswer(index))
        }, (option: string, index: number) => `${index}-${option}`)

        if (this.readingAnswered) {
          Button(this.readingQuestionIndex >= article.questions.length - 1 ? '完成阅读' : '下一题')
            .width('100%')
            .height(48)
            .backgroundColor('#0F766E')
            .margin({ top: 18 })
            .onClick(() => this.nextReadingQuestion())
        }
      }
      .padding(20)
      .backgroundColor('#FFFFFF')
      .borderRadius(24)
      .margin(16)
      Blank()
    }
    .layoutWeight(1)
  }

  @Builder
  ReviewPage() {
    Column() {
      Text('单词复习')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor('#0F172A')
        .width('100%')
        .padding({ left: 16, right: 16, top: 16 })

      Row() {
        this.StatCard('已掌握', 'known', '词', '#16A34A');
        this.StatCard('不认识', 'unknown', '词', '#EF4444');
        this.StatCard('未学习', 'new', '词', '#64748B');
      }
      .width('100%')
      .padding({ left: 16, right: 8, top: 14, bottom: 6 })

      if (this.reviewMode && this.reviewWords.length > 0) {
        Progress({ value: this.reviewIndex + 1, total: this.reviewWords.length, type: ProgressType.Linear })
          .width('90%')
          .color('#9333EA')
          .backgroundColor('#E2E8F0')
        Text(`${this.reviewIndex + 1}/${this.reviewWords.length}`)
          .fontSize(12)
          .fontColor('#64748B')
          .margin({ top: 6 })

        Column() {
          Text(this.currentReviewWord().word)
            .fontSize(42)
            .fontWeight(FontWeight.Bold)
            .fontColor('#0F172A')
          Text(this.currentReviewWord().phonetic_us ? `/${this.currentReviewWord().phonetic_us}/` : '点击卡片查看释义')
            .fontSize(16)
            .fontColor('#64748B')
            .margin({ top: 10 })
          Row() {
            Button('单词发音')
              .height(38)
              .fontSize(14)
              .backgroundColor('#9333EA')
              .onClick(() => this.speakReviewWord())
            Button('朗读详情')
              .height(38)
              .fontSize(14)
              .backgroundColor('#0F766E')
              .margin({ left: 10 })
              .onClick(() => this.speakReviewWordDetail())
          }
          .margin({ top: 16 })

          if (this.reviewShowDefinition) {
            Scroll() {
              Column() {
                Text(this.currentReviewWord().part_of_speech ? this.currentReviewWord().part_of_speech : '')
                  .fontSize(14)
                  .fontColor('#9333EA')
                Text(this.currentReviewWord().definition)
                  .fontSize(22)
                  .fontWeight(FontWeight.Medium)
                  .fontColor('#0F172A')
                  .textAlign(TextAlign.Center)
                  .margin({ top: 8 })
                Text(this.currentReviewWord().definition_en ? this.currentReviewWord().definition_en : '')
                  .fontSize(14)
                  .fontColor('#64748B')
                  .textAlign(TextAlign.Center)
                  .margin({ top: 10 })
                this.ExampleBlock(this.currentReviewWord().word);
              }
              .width('100%')
            }
            .layoutWeight(1)
            .width('100%')
            .align(Alignment.Top)
            .margin({ top: 22 })
          }
        }
        .layoutWeight(1)
        .width('92%')
        .justifyContent(this.reviewShowDefinition ? FlexAlign.Start : FlexAlign.Center)
        .padding(24)
        .backgroundColor('#FFFFFF')
        .borderRadius(28)
        .margin({ top: 18, bottom: 16 })
        .onClick(() => {
          this.reviewShowDefinition = !this.reviewShowDefinition;
        })

        Row() {
          Button('仍不认识')
            .layoutWeight(1)
            .height(48)
            .backgroundColor('#EF4444')
            .onClick(() => this.markReviewWord(false))
          Button('认识了')
            .layoutWeight(1)
            .height(48)
            .backgroundColor('#16A34A')
            .margin({ left: 12 })
            .onClick(() => this.markReviewWord(true))
        }
        .width('92%')

        Button('结束复习')
          .width('92%')
          .height(40)
          .fontSize(14)
          .backgroundColor('#E2E8F0')
          .fontColor('#475569')
          .margin({ top: 10, bottom: 14 })
          .onClick(() => {
            this.reviewMode = false;
          })
      } else {
        Scroll() {
          Column() {
            Button(`开始复习（${this.unknownWordsCount} 个生词）`)
              .width('100%')
              .height(48)
              .backgroundColor(this.unknownWordsCount > 0 ? '#9333EA' : '#CBD5E1')
              .enabled(this.unknownWordsCount > 0)
              .onClick(() => this.startReview())

            Text('不认识的单词')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor('#0F172A')
              .width('100%')
              .margin({ top: 20, bottom: 10 })

            if (this.unknownWordList().length === 0) {
              Text('暂无生词。背单词时标记为"不认识"的单词会显示在这里。')
                .fontSize(14)
                .fontColor('#64748B')
                .lineHeight(22)
                .width('100%')
                .padding(16)
                .backgroundColor('#FFFFFF')
                .borderRadius(16)
            } else {
              ForEach(this.unknownWordList(), (item: Word) => {
                Row() {
                  Column() {
                    Text(item.word)
                      .fontSize(17)
                      .fontWeight(FontWeight.Bold)
                      .fontColor('#0F172A')
                    Text(item.part_of_speech ? `${item.part_of_speech} ${item.definition}` : item.definition)
                      .fontSize(13)
                      .fontColor('#64748B')
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                      .margin({ top: 4 })
                  }
                  .alignItems(HorizontalAlign.Start)
                  .layoutWeight(1)
                  Text(item.level ? item.level : '')
                    .fontSize(11)
                    .fontColor('#9333EA')
                    .padding({ left: 8, right: 8, top: 4, bottom: 4 })
                    .backgroundColor('#F3E8FF')
                    .borderRadius(10)
                }
                .width('100%')
                .padding(14)
                .backgroundColor('#FFFFFF')
                .borderRadius(16)
                .margin({ bottom: 10 })
                .onClick(() => this.speakText(item.word))
              }, (item: Word) => item.word)
            }
          }
          .padding({ left: 16, right: 16, bottom: 16 })
        }
        .layoutWeight(1)
        .width('100%')
      }
    }
    .layoutWeight(1)
    .width('100%')
  }

  @Builder
  StatsPage() {
    Scroll() {
      Column() {
        Text('学习统计')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor('#0F172A')
          .width('100%')
          .margin({ bottom: 16 })

        this.ProgressCard('背单词', this.stats.vocabularyKnown, this.stats.vocabularyTotal, '#4F46E5');
        this.ProgressCard('习题练习', this.stats.quizCorrect, this.stats.quizTotal, '#16A34A');
        this.ProgressCard('阅读练习', this.stats.readingCorrect, this.stats.readingTotal, '#0F766E');

        Column() {
          Text('数据来源')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor('#0F172A')
          Text(`词库：${this.wordBank.length} 个单词`)
            .fontSize(15)
            .fontColor('#475569')
            .margin({ top: 10 })
          Text(`题库：${this.quizBank.length} 道选择题`)
            .fontSize(15)
            .fontColor('#475569')
            .margin({ top: 6 })
          Text(`阅读：${this.readingBank.length} 篇文章`)
            .fontSize(15)
            .fontColor('#475569')
            .margin({ top: 6 })
          Text(`语音：${this.ttsStatus}`)
            .fontSize(15)
            .fontColor('#475569')
            .margin({ top: 6 })
        }
        .width('100%')
        .padding(18)
        .backgroundColor('#FFFFFF')
        .borderRadius(22)
        .margin({ top: 12 })
      }
      .padding(16)
    }
    .layoutWeight(1)
  }

  @Builder
  ProgressCard(title: string, correct: number, total: number, color: string) {
    Column() {
      Row() {
        Text(title)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#0F172A')
        Blank()
        Text(`${this.progressPercent(correct, total)}%`)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(color)
      }
      Progress({ value: this.progressPercent(correct, total), total: 100, type: ProgressType.Linear })
        .width('100%')
        .height(8)
        .color(color)
        .backgroundColor('#E2E8F0')
        .margin({ top: 12 })
      Text(`${correct}/${total}`)
        .fontSize(13)
        .fontColor('#64748B')
        .margin({ top: 8 })
    }
    .width('100%')
    .padding(18)
    .backgroundColor('#FFFFFF')
    .borderRadius(22)
    .margin({ bottom: 12 })
  }

  @Builder
  BottomNav() {
    Row() {
      this.NavItem('home', '首页');
      this.NavItem('vocabulary', '背词');
      this.NavItem('quiz', '练习');
      this.NavItem('reading', '阅读');
      this.NavItem('review', '复习');
      this.NavItem('stats', '统计');
    }
    .width('100%')
    .height(68)
    .padding({ left: 8, right: 8, top: 8, bottom: 8 })
    .backgroundColor('#FFFFFF')
  }

  @Builder
  NavItem(key: string, label: string) {
    Text(label)
      .fontSize(14)
      .fontWeight(this.activePage === key ? FontWeight.Bold : FontWeight.Regular)
      .fontColor(this.activePage === key ? '#4F46E5' : '#64748B')
      .textAlign(TextAlign.Center)
      .layoutWeight(1)
      .height(44)
      .padding({ top: 12 })
      .backgroundColor(this.activePage === key ? '#EEF2FF' : '#FFFFFF')
      .borderRadius(18)
      .onClick(() => {
        this.activePage = key;
      })
  }
}
