import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:isolate';

int isolatePrimeTask(int endNum) {
  int primeCount = 0;
  bool isPrime;
  double sqrtN;
  int startNum = 2;

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
  return primeCount;
}

int isolateCalcTask(int perTypeCount, int calcMin, int calcMax) {
  Random random = Random();
  double sum = 0;

  for (int i = 0; i < perTypeCount; i++) {
    int a = random.nextInt(calcMax - calcMin) + calcMin;
    int b = random.nextInt(calcMax - calcMin) + calcMin;
    sum += a + b;
  }
  for (int i = 0; i < perTypeCount; i++) {
    int a = random.nextInt(calcMax - calcMin) + calcMin;
    int b = random.nextInt(calcMax - calcMin) + calcMin;
    sum += a - b;
  }
  for (int i = 0; i < perTypeCount; i++) {
    int a = random.nextInt(calcMax - calcMin) + calcMin;
    int b = random.nextInt(calcMax - calcMin) + calcMin;
    sum += a * b;
  }
  for (int i = 0; i < perTypeCount; i++) {
    int a = random.nextInt(calcMax - calcMin) + calcMin;
    int b = random.nextInt(calcMax - calcMin) + calcMin;
    if (b != 0) {
      sum += a / b;
    }
  }
  return sum.toInt();
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
    final Stopwatch sw = Stopwatch()..start();
    // 全部计算放到Isolate，并且接收返回值，编译器无法删除
    int primeCount = await Isolate.run(() => isolatePrimeTask(primeEnd));
    sw.stop();
    final double usedMs = sw.elapsedMicroseconds / 1000.0;
    final double safeMs = max(usedMs, 0.001);
    double score = basePrimeMs * 1000 / safeMs;
    print("质数数量：$primeCount");
    return score;
  }

  Future<double> runCalcTest() async {
    final Stopwatch sw = Stopwatch()..start();
    int sumResult = await Isolate.run(
      () => isolateCalcTask(perTypeCount, calcMin, calcMax),
    );
    sw.stop();
    final double usedMs = sw.elapsedMicroseconds / 1000.0;
    final double safeMs = max(usedMs, 0.001);
    double score = baseCalcMs * 1000 / safeMs;
    print("计算总和：$sumResult");
    return score;
  }

  Future<double> runMultiTest() async {
    final Stopwatch sw = Stopwatch()..start();
    // 多隔离测试，新开isolate跑质数
    int primeCount = await Isolate.run(() => isolatePrimeTask(primeEnd));
    sw.stop();
    final double usedMs = sw.elapsedMicroseconds / 1000.0;
    final double safeMs = max(usedMs, 0.001);
    double score = baseMultiMs * 1000 / safeMs;
    print("多隔离质数数量：$primeCount");
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
