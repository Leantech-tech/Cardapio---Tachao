import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../theme/app_theme.dart';

class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  bool _isScanning = true;
  final MobileScannerController _controller = MobileScannerController(
    facing: CameraFacing.front,
    detectionSpeed: DetectionSpeed.normal,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (!_isScanning) return;

    final barcode = capture.barcodes.firstOrNull;
    final rawValue = barcode?.rawValue;

    if (rawValue != null && rawValue.isNotEmpty) {
      setState(() => _isScanning = false);
      _controller.stop();
      Navigator.pop(context, rawValue);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          // Overlay escuro com área de scan
          Column(
            children: [
              // Top area
              Container(
                color: Colors.black.withValues(alpha: 0.5),
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 16,
                  bottom: 24,
                  left: 20,
                  right: 20,
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close, color: Colors.white, size: 28),
                        ),
                        const Spacer(),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Escaneie a comanda',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Posicione o código de barras da comanda na área abaixo.',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              // Scan area
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Container(color: Colors.black.withValues(alpha: 0.5)),
                    ),
                    Container(
                      width: 280,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.tachaoRed, width: 2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    Expanded(
                      child: Container(color: Colors.black.withValues(alpha: 0.5)),
                    ),
                  ],
                ),
              ),
              // Bottom area
              Container(
                color: Colors.black.withValues(alpha: 0.5),
                padding: EdgeInsets.only(
                  top: 24,
                  bottom: MediaQuery.of(context).padding.bottom + 32,
                  left: 20,
                  right: 20,
                ),
                child: Column(
                  children: [
                    if (_isScanning)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppTheme.tachaoRed,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Procurando código de barras...',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                        ],
                      )
                    else
                      Text(
                        'Código detectado!',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.greenAccent,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
