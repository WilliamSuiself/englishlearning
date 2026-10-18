import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:english_learning_app/services/router.dart';

const _mockReadings = '''
[
  {
    "title": "Test Article A",
    "level": "easy",
    "text": ["Paragraph one.", "Paragraph two."],
    "questions": [
      {
        "question": "Question A1",
        "options": ["A1 opt0", "A1 opt1", "A1 opt2", "A1 opt3"],
        "answer": 0
      },
      {
        "question": "Question A2",
        "options": ["A2 opt0", "A2 opt1", "A2 opt2", "A2 opt3"],
        "answer": 1
      },
      {
        "question": "Question A3",
        "options": ["A3 opt0", "A3 opt1", "A3 opt2", "A3 opt3"],
        "answer": 2
      }
    ]
  }
]
''';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', (ByteData? message) async {
      final key = utf8.decode(message!.buffer.asUint8List());
      if (key == 'assets/data/readings.json') {
        return ByteData.view(
          Uint8List.fromList(utf8.encode(_mockReadings)).buffer,
        );
      }
      return null;
    });
  });

  tearDownAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', null);
  });

  testWidgets('ReadingPage advances to next question inside go_router', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 800));
    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: goRouter,
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    // Navigate to reading
    tester.element(find.byType(NavigationBar)).visitAncestorElements((element) {
      // ignore
      return false;
    });
    // Direct navigation via go_router
    goRouter.go('/reading');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Start answering
    await tester.tap(find.text('开始答题'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Question A1'), findsOneWidget);

    // Select an answer
    await tester.tap(find.text('A1 opt1'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Tap continue
    await tester.tap(find.text('下一题'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Question A2'), findsOneWidget);
  });
}
