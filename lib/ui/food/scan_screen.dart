import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../l10n/app_localizations.dart';

/// Pops with the first product barcode it sees.
class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final _controller = MobileScannerController(
    formats: const [BarcodeFormat.ean13, BarcodeFormat.ean8, BarcodeFormat.upcA, BarcodeFormat.upcE],
  );
  bool _done = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.transparent, title: Text(l.scanBarcode)),
      extendBodyBehindAppBar: true,
      body: MobileScanner(
        controller: _controller,
        errorBuilder: (ctx, error) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Text(l.cameraPermission, textAlign: TextAlign.center),
          ),
        ),
        onDetect: (capture) {
          final code = capture.barcodes.map((b) => b.rawValue).nonNulls.firstOrNull;
          if (code == null || _done) return;
          _done = true;
          Navigator.pop(context, code);
        },
      ),
    );
  }
}
