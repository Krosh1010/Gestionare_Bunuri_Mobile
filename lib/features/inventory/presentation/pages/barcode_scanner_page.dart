import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../../core/constants/app_colors.dart';

class BarcodeScannerPage extends StatefulWidget {
  const BarcodeScannerPage({super.key});

  @override
  State<BarcodeScannerPage> createState() => _BarcodeScannerPageState();
}

class _BarcodeScannerPageState extends State<BarcodeScannerPage> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );

  bool _hasScanned = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_hasScanned) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
      _hasScanned = true;
      final String code = barcodes.first.rawValue!;
      Navigator.of(context).pop(code);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Scanează cod de bare'),
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Camera preview
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),

          // Overlay cu fereastră de scanare
          _buildScanOverlay(),

          // Instrucțiuni în partea de jos
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.8),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Poziționează codul de bare în cadru',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Scanarea se face automat',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  // Buton pentru toggle lanternă
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildControlButton(
                        icon: Icons.flash_on_rounded,
                        label: 'Lanternă',
                        onTap: () => _controller.toggleTorch(),
                      ),
                      const SizedBox(width: 32),
                      _buildControlButton(
                        icon: Icons.cameraswitch_rounded,
                        label: 'Cameră',
                        onTap: () => _controller.switchCamera(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanOverlay() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scanAreaSize = constraints.maxWidth * 0.75;
        final top = (constraints.maxHeight - scanAreaSize) / 2 - 40;
        final left = (constraints.maxWidth - scanAreaSize) / 2;

        return Stack(
          children: [
            // Zona întunecată din jur
            ColorFiltered(
              colorFilter: ColorFilter.mode(
                Colors.black.withValues(alpha: 0.5),
                BlendMode.srcOut,
              ),
              child: Stack(
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.black,
                      backgroundBlendMode: BlendMode.dstOut,
                    ),
                  ),
                  Positioned(
                    top: top,
                    left: left,
                    child: Container(
                      width: scanAreaSize,
                      height: scanAreaSize,
                      decoration: BoxDecoration(
                        color: Colors.red, // orice culoare, va fi decupată
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Colțurile cadrului de scanare
            Positioned(
              top: top,
              left: left,
              child: _buildCorner(Alignment.topLeft),
            ),
            Positioned(
              top: top,
              right: left,
              child: _buildCorner(Alignment.topRight),
            ),
            Positioned(
              bottom: constraints.maxHeight - top - scanAreaSize,
              left: left,
              child: _buildCorner(Alignment.bottomLeft),
            ),
            Positioned(
              bottom: constraints.maxHeight - top - scanAreaSize,
              right: left,
              child: _buildCorner(Alignment.bottomRight),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCorner(Alignment alignment) {
    const size = 28.0;
    const thickness = 3.5;

    BorderSide side(bool show) =>
        show ? const BorderSide(color: AppColors.primary, width: thickness) : BorderSide.none;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        border: Border(
          top: side(alignment == Alignment.topLeft || alignment == Alignment.topRight),
          bottom: side(alignment == Alignment.bottomLeft || alignment == Alignment.bottomRight),
          left: side(alignment == Alignment.topLeft || alignment == Alignment.bottomLeft),
          right: side(alignment == Alignment.topRight || alignment == Alignment.bottomRight),
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

