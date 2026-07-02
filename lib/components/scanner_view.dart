import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

class ScannerView extends StatefulWidget {
  final String title;

  const ScannerView({super.key, required this.title});

  @override
  State<ScannerView> createState() => _ScannerViewState();
}

class _ScannerViewState extends State<ScannerView> {
  final MobileScannerController _controller = MobileScannerController();
  bool _hasScanned = false;
  bool _permissionGranted = false;
  bool _permissionChecked = false;

  @override
  void initState() {
    super.initState();
    _requestCameraPermission();
  }

  Future<void> _requestCameraPermission() async {
    if (kIsWeb) {
      setState(() {
        _permissionGranted = true;
        _permissionChecked = true;
      });
      return;
    }

    final status = await Permission.camera.request();
    if (!mounted) return;
    setState(() {
      _permissionGranted = status.isGranted;
      _permissionChecked = true;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          widget.title,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        actions: [
          if (_permissionGranted && !kIsWeb) ...[
            IconButton(
              onPressed: () => _controller.toggleTorch(),
              icon: ValueListenableBuilder(
                valueListenable: _controller,
                builder: (context, state, child) {
                  return Icon(
                    state.torchState == TorchState.on
                        ? Icons.flash_on_rounded
                        : Icons.flash_off_rounded,
                    color: Colors.white,
                  );
                },
              ),
            ),
            IconButton(
              onPressed: () => _controller.switchCamera(),
              icon: const Icon(Icons.cameraswitch_rounded, color: Colors.white),
            ),
          ],
        ],
      ),
      body: !_permissionChecked
          // Loading saat cek permission
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : !_permissionGranted
          // Tampilan jika permission ditolak
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt_outlined,
                        color: Colors.white,
                        size: 48,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Izin Kamera Diperlukan',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Aplikasi membutuhkan akses kamera untuk melakukan scan barcode.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.7),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      onPressed: () async {
                        // Buka settings jika sudah permanently denied
                        final status = await Permission.camera.status;
                        if (status.isPermanentlyDenied) {
                          await openAppSettings();
                        } else {
                          await _requestCameraPermission();
                        }
                      },
                      icon: const Icon(Icons.settings_rounded),
                      label: Text(
                        'Beri Izin Kamera',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF667EEA),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Batal',
                        style: GoogleFonts.poppins(
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          // Kamera aktif
          : Stack(
              children: [
                MobileScanner(
                  controller: _controller,
                  onDetect: (capture) {
                    if (_hasScanned) return;
                    final barcode = capture.barcodes.firstOrNull;
                    if (barcode?.rawValue != null) {
                      _hasScanned = true;
                      Navigator.pop(context, barcode!.rawValue);
                    }
                  },
                ),
                CustomPaint(
                  painter: _ScannerOverlayPainter(),
                  child: const SizedBox.expand(),
                ),
                Positioned(
                  bottom: 60,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Arahkan kamera ke barcode / QR code',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

// Overlay dengan kotak scan di tengah
class _ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const double scanBoxSize = 250;
    final double left = (size.width - scanBoxSize) / 2;
    final double top = (size.height - scanBoxSize) / 2;
    final scanRect = Rect.fromLTWH(left, top, scanBoxSize, scanBoxSize);

    // Dim area luar kotak
    final dimPaint = Paint()..color = Colors.black.withValues(alpha: 0.55);
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
        Path()..addRRect(
          RRect.fromRectAndRadius(scanRect, const Radius.circular(12)),
        ),
      ),
      dimPaint,
    );

    // Border kotak scan
    final borderPaint = Paint()
      ..color = const Color(0xFF667EEA)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawRRect(
      RRect.fromRectAndRadius(scanRect, const Radius.circular(12)),
      borderPaint,
    );

    // Corner accent
    const double cornerLen = 24;
    const double cornerRadius = 6;
    final cornerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    // Top-left
    canvas.drawLine(
      Offset(left + cornerRadius, top),
      Offset(left + cornerLen, top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(left, top + cornerRadius),
      Offset(left, top + cornerLen),
      cornerPaint,
    );
    // Top-right
    canvas.drawLine(
      Offset(left + scanBoxSize - cornerLen, top),
      Offset(left + scanBoxSize - cornerRadius, top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(left + scanBoxSize, top + cornerRadius),
      Offset(left + scanBoxSize, top + cornerLen),
      cornerPaint,
    );
    // Bottom-left
    canvas.drawLine(
      Offset(left + cornerRadius, top + scanBoxSize),
      Offset(left + cornerLen, top + scanBoxSize),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(left, top + scanBoxSize - cornerLen),
      Offset(left, top + scanBoxSize - cornerRadius),
      cornerPaint,
    );
    // Bottom-right
    canvas.drawLine(
      Offset(left + scanBoxSize - cornerLen, top + scanBoxSize),
      Offset(left + scanBoxSize - cornerRadius, top + scanBoxSize),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(left + scanBoxSize, top + scanBoxSize - cornerLen),
      Offset(left + scanBoxSize, top + scanBoxSize - cornerRadius),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
