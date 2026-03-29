import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'dart:math' as math;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Squat Pose Test',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const PoseTestScreen(),
    );
  }
}

class PoseTestScreen extends StatefulWidget {
  const PoseTestScreen({super.key});

  @override
  State<PoseTestScreen> createState() => _PoseTestScreenState();
}

class _PoseTestScreenState extends State<PoseTestScreen> {
  String _resultText = "กดปุ่มด้านล่างเพื่อเริ่มดึงพิกัดและคำนวณองศาท่า Squat";

  // ฟังก์ชันคำนวณหาองศาระหว่างข้อต่อ 3 จุด (ใช้หลักการ Trigonometry)
  double _calculateAngle(PoseLandmark first, PoseLandmark middle, PoseLandmark last) {
    double radians = math.atan2(last.y - middle.y, last.x - middle.x) -
        math.atan2(first.y - middle.y, first.x - middle.x);

    double degrees = radians * (180.0 / math.pi);
    
    // ปรับค่าให้เป็นบวกและอยู่ในช่วง 0-180 องศา
    degrees = degrees.abs();
    if (degrees > 180.0) {
      degrees = 360.0 - degrees;
    }
    
    return degrees;
  }

  // ฟังก์ชันหลักสำหรับดึงพิกัด
  Future<void> _extractSquatLandmarks() async {
    setState(() {
      _resultText = "กำลังประมวลผล...";
    });

    try {
      // 1. โหลดรูปภาพจากโฟลเดอร์ assets มาสร้างเป็นไฟล์ชั่วคราว
      final imagePath = await _getAssetPath('assets/images/squat.jpg');
      final inputImage = InputImage.fromFilePath(imagePath);

      // 2. เรียกใช้งาน ML Kit Pose Detector (ตั้งค่าแบบแม่นยำ - accurate)
      final options = PoseDetectorOptions(mode: PoseDetectionMode.single);
      final poseDetector = PoseDetector(options: options);

      // 3. ส่งรูปภาพให้ AI ประมวลผล
      final List<Pose> poses = await poseDetector.processImage(inputImage);

      if (poses.isEmpty) {
        setState(() {
          _resultText = "ไม่พบคนในรูปภาพครับ";
        });
        return;
      }

      // 4. ดึงข้อมูลพิกัดของคนแรกที่เจอในรูป
      final pose = poses.first;

      // ดึงพิกัดซีกซ้าย (สะโพก, เข่า, ข้อเท้า) สำหรับท่า Squat
      final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
      final leftKnee = pose.landmarks[PoseLandmarkType.leftKnee];
      final leftAnkle = pose.landmarks[PoseLandmarkType.leftAnkle];

      // 5. แสดงผลลัพธ์ออกทางหน้าจอ และ Print ลง Console
      if (leftHip != null && leftKnee != null && leftAnkle != null) {
        
        // 🌟 เรียกใช้ฟังก์ชันคำนวณองศาหัวเข่าตรงนี้
        double kneeAngle = _calculateAngle(leftHip, leftKnee, leftAnkle);

        String output = '''
ดึงพิกัดสำเร็จ! (แกน X, แกน Y)
สะโพกซ้าย: (${leftHip.x.toStringAsFixed(2)}, ${leftHip.y.toStringAsFixed(2)})
หัวเข่าซ้าย: (${leftKnee.x.toStringAsFixed(2)}, ${leftKnee.y.toStringAsFixed(2)})
ข้อเท้าซ้าย: (${leftAnkle.x.toStringAsFixed(2)}, ${leftAnkle.y.toStringAsFixed(2)})
-------------------
🔥 องศาหัวเข่า: ${kneeAngle.toStringAsFixed(2)} องศา 🔥
        ''';

        print(output); // แสดงใน Console ด้านล่างของ VS Code

        setState(() {
          _resultText = output; // แสดงบนหน้าจอแอป
        });
      }

      // ปิดการใช้งานเมื่อเสร็จสิ้นเพื่อคืนหน่วยความจำ
      poseDetector.close();
    } catch (e) {
      setState(() {
        _resultText = "เกิดข้อผิดพลาด: $e";
      });
      print("Error: $e");
    }
  }

  // ฟังก์ชันช่วยเหลือ: แปลง Asset เป็น File Path เพื่อให้ ML Kit อ่านได้
  Future<String> _getAssetPath(String assetName) async {
    final byteData = await rootBundle.load(assetName);
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/${assetName.split('/').last}');
    await file.writeAsBytes(byteData.buffer.asUint8List());
    return file.path;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ทดสอบดึงพิกัดท่า Squat')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _resultText,
                style: const TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _extractSquatLandmarks,
                child: const Text('ดึงพิกัดเดี๋ยวนี้'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}