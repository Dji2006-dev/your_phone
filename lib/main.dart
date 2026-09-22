import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:isolate';
import 'dart:async';

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

Future<double> runMultiCoreTest({
  required int coreCount,
  required int primeEnd,
}) async {
  final Stopwatch sw = Stopwatch()..start();
  try {
    List<Future<int>> taskList = [];
    for (int i = 0; i < coreCount; i++) {
      taskList.add(Isolate.run(() => isolatePrimeTask(primeEnd)));
    }
    List<int> res = await Future.wait(
      taskList,
    ).timeout(const Duration(seconds: 40));
    sw.stop();
    final double usedMs = sw.elapsedMicroseconds / 1000.0;
    final double safeMs = max(usedMs, 0.001);
    double score = (coreCount * 3000) / safeMs * 1000;
    print("多核任务结果：$res");
    return score;
  } on TimeoutException {
    sw.stop();
    print("多核测试超时！");
    return 0;
  }
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
  double multiCoreScore = 0.0;

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
    try {
      int primeCount = await Isolate.run(
        () => isolatePrimeTask(primeEnd),
      ).timeout(const Duration(seconds: 40));
      sw.stop();
      final double usedMs = sw.elapsedMicroseconds / 1000.0;
      final double safeMs = max(usedMs, 0.001);
      double score = basePrimeMs * 1000 / safeMs;
      print("质数数量：$primeCount");
      return score;
    } on TimeoutException {
      sw.stop();
      print("阶段1质数测试超时卡死！");
      return 0;
    }
  }

  Future<double> runCalcTest() async {
    final Stopwatch sw = Stopwatch()..start();
    try {
      int sumResult = await Isolate.run(
        () => isolateCalcTask(perTypeCount, calcMin, calcMax),
      ).timeout(const Duration(seconds: 20));
      sw.stop();
      final double usedMs = sw.elapsedMicroseconds / 1000.0;
      final double safeMs = max(usedMs, 0.001);
      double score = baseCalcMs * 1000 / safeMs;
      print("计算总和：$sumResult");
      return score;
    } on TimeoutException {
      sw.stop();
      print("阶段2四则运算超时！");
      return 0;
    }
  }

  Future<double> runMultiTest() async {
    final Stopwatch sw = Stopwatch()..start();
    try {
      int primeCount = await Isolate.run(
        () => isolatePrimeTask(primeEnd),
      ).timeout(const Duration(seconds: 40));
      sw.stop();
      final double usedMs = sw.elapsedMicroseconds / 1000.0;
      final double safeMs = max(usedMs, 0.001);
      double score = baseMultiMs * 1000 / safeMs;
      print("多隔离质数数量：$primeCount");
      return score;
    } on TimeoutException {
      sw.stop();
      print("阶段3隔离测试超时！");
      return 0;
    }
  }

  Future<void> runAllSingleCore() async {
    if (isRunning) return;
    setState(() {
      isRunning = true;
      logText = "开始单核跑分...";
    });

    scorePrime = await runPrimeTest();
    if (scorePrime <= 0) {
      setState(() {
        logText = "阶段1超时失败！";
        isRunning = false;
      });
      return;
    }
    setState(() {
      logText = "阶段1完成，质数分数：${scorePrime.toStringAsFixed(2)}";
    });

    scoreCalc = await runCalcTest();
    if (scoreCalc <= 0) {
      setState(() {
        logText = "阶段2超时失败！";
        isRunning = false;
      });
      return;
    }
    setState(() {
      logText = "阶段2完成，四则分数：${scoreCalc.toStringAsFixed(2)}";
    });

    scoreMulti = await runMultiTest();
    if (scoreMulti <= 0) {
      setState(() {
        logText = "阶段3超时失败！";
        isRunning = false;
      });
      return;
    }
    setState(() {
      logText = "阶段3完成，隔离分数：${scoreMulti.toStringAsFixed(2)}";
    });

    totalScore = (scorePrime + scoreCalc + scoreMulti) / 3;
    setState(() {
      logText = "✅单核总分：${totalScore.toStringAsFixed(2)}";
      isRunning = false;
    });
  }

  Future<void> runAllMultiCore() async {
    if (isRunning) return;
    setState(() {
      isRunning = true;
      logText = "开始多核跑分（4线程）";
    });
    multiCoreScore = await runMultiCoreTest(coreCount: 4, primeEnd: primeEnd);
    setState(() {
      if (multiCoreScore <= 0) {
        logText = "多核测试超时失败！";
      } else {
        logText = "✅多核跑分分数：${multiCoreScore.toStringAsFixed(2)}";
      }
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
              onPressed: isRunning ? null : runAllSingleCore,
              child: const Text("开始单核跑分"),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: isRunning ? null : runAllMultiCore,
              child: const Text("开始多核跑分（4核）"),
            ),
          ],
        ),
      ),
    );
  }
}
