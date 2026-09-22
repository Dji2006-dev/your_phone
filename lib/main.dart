import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:isolate';

void isolatePrimeTask(SendPort sendPort) {
  int primeCount = 0;
  bool isPrime;
  double sqrtN;
  int startNum = 2;
  int endNum = 100000;

  for (int n = startNum; n <= endNum; n++) {
    isPrime = true;
    sqrtN = sqrt(n);
    for (int j = 2; j <= sqrtN; j++) {
      if (n % j == 0) {
        isPrime = false;
        break;
      }
    }
    if (isPrime) {
      primeCount++;
    }
  }
  sendPort.send(primeCount);
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: const BenchPage());
  }
}

class BenchPage extends StatefulWidget {
  const BenchPage({super.key});

  @override
  State<BenchPage> createState() => _BenchPageState();
}

class _BenchPageState extends State<BenchPage> {
  // ✅ 把你那一堆变量、常量，粘贴到这个大括号里面！
  // 这里就是放 isRunning、logText、所有final常量的地方
  bool isRunning = false;
  String logText = "就绪";
  double scorePrime = 0.0;
  double scoreCalc = 0.0;
  double scoreMulti = 0.0;
  double totalScore = 0.0;
  final int primeStart = 2;
  final int primeEnd = 100000;
  final int calcMin = 10000;
  final int calcMax = 50000;
  final int perTypeCount = 500;
  final int basePrimeMs = 3000;
  final int baseCalcMs = 500;
  final int baseMultiMs = 3000;
  Future<double> runPrimeTest() async {
    final Stopwatch start = Stopwatch()..start();
    int primeCount = 0;
    bool isPrime;
    double sqrtN;

    for (int n = primeStart; n <= primeEnd; n++) {
      isPrime = true;
      sqrtN = sqrt(n);
      for (int j = 2; j <= sqrtN; j++) {
        if (n % j == 0) {
          isPrime = false;
          break;
        }
      }
      if (isPrime) {
        primeCount++;
      }
    }

    final int usedMs = start.elapsed.inMilliseconds;
    double score = basePrimeMs * 1000 / usedMs;
    return score;
  }

  Future<double> runCalcTest() async {
    final DateTime start = DateTime.now();
    Random random = Random();
    double sum = 0;

    // 加法
    for (int i = 0; i < perTypeCount; i++) {
      int a = random.nextInt(calcMax - calcMin) + calcMin;
      int b = random.nextInt(calcMax - calcMin) + calcMin;
      sum += a + b;
    }
    // 减法
    for (int i = 0; i < perTypeCount; i++) {
      int a = random.nextInt(calcMax - calcMin) + calcMin;
      int b = random.nextInt(calcMax - calcMin) + calcMin;
      sum += a - b;
    }
    // 乘法
    for (int i = 0; i < perTypeCount; i++) {
      int a = random.nextInt(calcMax - calcMin) + calcMin;
      int b = random.nextInt(calcMax - calcMin) + calcMin;
      sum += a * b;
    }
    // 除法（防止除0）
    for (int i = 0; i < perTypeCount; i++) {
      int a = random.nextInt(calcMax - calcMin) + calcMin;
      int b = random.nextInt(calcMax - calcMin) + calcMin;
      if (b != 0) {
        sum += a / b;
      }
    }

    final int usedMs = DateTime.now().difference(start).inMilliseconds;
    double score = baseCalcMs * 1000 / usedMs;
    return score;
  }

  Future<double> runMultiTest() async {
    final DateTime start = DateTime.now();

    final ReceivePort receivePort = ReceivePort();
    await Isolate.spawn(isolatePrimeTask, receivePort.sendPort);

    await receivePort.first;
    receivePort.close();

    final int usedMs = DateTime.now().difference(start).inMilliseconds;
    double score = baseMultiMs * 1000 / usedMs;
    return score;
  }

  Future<void> runAllBenchmark() async {
    if (isRunning) return;
    setState(() {
      isRunning = true;
      logText = "开始跑分...";
    });

    scorePrime = await runPrimeTest();
    setState(() {
      logText = "阶段1完成，分数：${scorePrime.toStringAsFixed(2)}";
    });

    scoreCalc = await runCalcTest();
    setState(() {
      logText = "阶段2完成，分数：${scoreCalc.toStringAsFixed(2)}";
    });

    scoreMulti = await runMultiTest();
    setState(() {
      logText = "阶段3完成，分数：${scoreMulti.toStringAsFixed(2)}";
    });

    totalScore = (scorePrime + scoreCalc + scoreMulti) / 3;
    setState(() {
      logText = "跑分全部完成！总分：${totalScore.toStringAsFixed(2)}";
      isRunning = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Dart Benchmark")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(logText, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: isRunning ? null : runAllBenchmark,
              child: const Text("开始跑分"),
            ),
          ],
        ),
      ),
    );
  }
}
