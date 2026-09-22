import 'package:flutter/material.dart';
import 'dart:isolate';
import 'dart:async';
import 'dart:math';

void isolatePrimeEntry(SendPort sendPort) {
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

Future<double> runPrimeTest() async {
  final Stopwatch sw = Stopwatch()..start();
  final receivePort = ReceivePort();
  final isolate = await Isolate.spawn(isolatePrimeEntry, receivePort.sendPort);
  try {
    final result =
        await receivePort.first.timeout(const Duration(seconds: 40)) as int;
    sw.stop();
    final double usedMs = sw.elapsedMicroseconds / 1000.0;
    final double safeMs = max(usedMs, 0.001);
    double score = 3000 * 1000 / safeMs;
    print("质数数量：$result");
    return score;
  } on TimeoutException {
    sw.stop();
    print("质数测试超时！");
    return 0;
  } finally {
    receivePort.close();
    isolate.kill();
  }
}

Future<double> runCalcTest() async {
  final Stopwatch sw = Stopwatch()..start();
  try {
    int sumResult = await Isolate.run(
      () => isolateCalcTask(500, 10000, 50000),
    ).timeout(const Duration(seconds: 20));
    sw.stop();
    final double usedMs = sw.elapsedMicroseconds / 1000.0;
    final double safeMs = max(usedMs, 0.001);
    double score = 500 * 1000 / safeMs;
    print("计算总和：$sumResult");
    return score;
  } on TimeoutException {
    sw.stop();
    print("四则测试超时！");
    return 0;
  }
}

Future<double> runMultiCoreTest({required int coreCount}) async {
  final Stopwatch sw = Stopwatch()..start();
  List<Future<int>> tasks = [];
  for (int i = 0; i < coreCount; i++) {
    final receivePort = ReceivePort();
    // 强制类型转换，修复编译报错
    Future<int> task = receivePort.first
        .timeout(const Duration(seconds: 40))
        .then((value) => value as int);
    tasks.add(task);
    await Isolate.spawn(isolatePrimeEntry, receivePort.sendPort);
  }
  try {
    final res = await Future.wait(tasks);
    sw.stop();
    final double usedMs = sw.elapsedMicroseconds / 1000.0;
    final double safeMs = max(usedMs, 0.001);
    double score = (coreCount * 3000) / safeMs * 1000;
    print("多核结果：$res");
    return score;
  } on TimeoutException {
    sw.stop();
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
    return MaterialApp(
      home: const BenchPage(),
      debugShowCheckedModeBanner: false,
    );
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
  String logTextEn = "Ready";
  double scorePrime = 0.0;
  double scoreCalc = 0.0;
  double totalScore = 0.0;
  double multiScore = 0;

  Future<void> runSingleCoreAll() async {
    if (isRunning) return;
    setState(() {
      isRunning = true;
      logText = "开始单核跑分...";
      logTextEn = "Starting single-core benchmark...";
    });

    scorePrime = await runPrimeTest();
    if (scorePrime <= 0) {
      setState(() {
        logText = "阶段1超时失败";
        logTextEn = "Stage 1 timed out";
        isRunning = false;
      });
      return;
    }
    setState(() {
      logText = "阶段1质数完成";
      logTextEn = "Stage 1 Primes completed: ${scorePrime.toStringAsFixed(2)}";
    });

    scoreCalc = await runCalcTest();
    if (scoreCalc <= 0) {
      setState(() {
        logText = "阶段2超时失败";
        logTextEn = "Stage 2 timed out";
        isRunning = false;
      });
      return;
    }
    setState(() {
      logText = "阶段2四则完成";
      logTextEn = "Stage 2 Math completed: ${scoreCalc.toStringAsFixed(2)}";
    });

    totalScore = (scorePrime + scoreCalc) / 2;
    setState(() {
      logText = "✅ 单核总分";
      logTextEn = "✅ Single-core total score: ${totalScore.toStringAsFixed(2)}";
      isRunning = false;
    });
  }

  Future<void> runMultiCore() async {
    if (isRunning) return;
    setState(() {
      isRunning = true;
      logText = "多核4线程开始";
      logTextEn = "Starting multi-core 4-thread benchmark";
    });

    multiScore = await runMultiCoreTest(coreCount: 4);
    setState(() {
      if (multiScore <= 0) {
        logText = "多核超时失败";
        logTextEn = "Multi-core benchmark timed out";
      } else {
        logText = "✅ 多核分数";
        logTextEn = "✅ Multi-core score: ${multiScore.toStringAsFixed(2)}";
      }
      isRunning = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          children: [
            Text("Dart 跑分测试"),
            Text("Dart Benchmark", style: TextStyle(fontSize: 12)),
          ],
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                logText,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                logTextEn,
                style: const TextStyle(fontSize: 14, color: Colors.black54),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: 240,
                child: ElevatedButton(
                  onPressed: isRunning ? null : runSingleCoreAll,
                  child: const Column(
                    children: [
                      Text("开始单核跑分"),
                      Text(
                        "Start Single-Core Benchmark",
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: 240,
                child: ElevatedButton(
                  onPressed: isRunning ? null : runMultiCore,
                  child: const Column(
                    children: [
                      Text("开始多核跑分（4核）"),
                      Text(
                        "Start Multi-Core Benchmark (4 Cores)",
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
