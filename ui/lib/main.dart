import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Glucowar',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const ScanPage(),
    );
  }
}

class RadarChartPage extends StatelessWidget {
  const RadarChartPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}

class BarcodePainter extends CustomPainter {
  final Barcode? barcode;

  BarcodePainter(this.barcode);

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()..addPolygon(barcode?.corners ?? [], true);
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.yellow.shade700.withOpacity(0.5);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant BarcodePainter oldDelegate) {
    return oldDelegate.barcode != barcode;
  }
}

class ScanPage extends StatefulWidget {
  const ScanPage({Key? key}) : super(key: key);

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  MobileScannerController cameraController = MobileScannerController();
  Barcode? current;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mobile Scanner'),
        actions: [
          IconButton(
            color: Colors.white,
            icon: ValueListenableBuilder(
              valueListenable: cameraController.torchState,
              builder: (context, state, child) {
                switch (state as TorchState) {
                  case TorchState.off:
                    return const Icon(Icons.flash_off, color: Colors.grey);
                  case TorchState.on:
                    return const Icon(Icons.flash_on, color: Colors.yellow);
                }
              },
            ),
            iconSize: 32.0,
            onPressed: () => cameraController.toggleTorch(),
          ),
          IconButton(
            color: Colors.white,
            icon: ValueListenableBuilder(
              valueListenable: cameraController.cameraFacingState,
              builder: (context, state, child) {
                switch (state as CameraFacing) {
                  case CameraFacing.front:
                    return const Icon(Icons.camera_front);
                  case CameraFacing.back:
                    return const Icon(Icons.camera_rear);
                }
              },
            ),
            iconSize: 32.0,
            onPressed: () => cameraController.switchCamera(),
          ),
        ],
      ),
      body: CustomPaint(
        foregroundPainter: BarcodePainter(current),
        child: MobileScanner(
          allowDuplicates: true,
          controller: cameraController,
          onDetect: (barcode, args) {
            setState(() {
              final s = args?.size;
              current = barcode;
            });
          },
        ),
      ),
    );
  }
}
