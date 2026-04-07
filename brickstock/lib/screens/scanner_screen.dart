import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../models/lego_set.dart';
import '../services/api_service.dart';
import 'set_details_screen.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  bool _isProcessing = false;
  final ApiService _apiService = ApiService();
  final MobileScannerController _cameraController = MobileScannerController();

  Future<void> _handleBarcode(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
      final String barcodeValue = barcodes.first.rawValue!;
      
      setState(() {
        _isProcessing = true;
      });

      try {
        _cameraController.stop();

        final setJson = await _apiService.scanBarcode(barcodeValue);

        if (setJson != null && mounted) {
          final legoSet = LegoSet.fromJson(setJson);

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => SetDetailsScreen(legoSet: legoSet),
            ),
          );
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No se ha encontrado ningún set con este código')),
            );
            _cameraController.start();
            setState(() {
              _isProcessing = false;
            });
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error de conexión al escanear')),
          );
          _cameraController.start();
          setState(() {
            _isProcessing = false;
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escanear Set'),
        actions: [
          IconButton(
            color: Colors.white,
            icon: const Icon(Icons.cameraswitch), // Icono estático de girar cámara
            iconSize: 28.0,
            tooltip: 'Cambiar cámara',
            onPressed: () => _cameraController.switchCamera(), // La función sigue existiendo
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _cameraController,
            onDetect: _handleBarcode,
          ),
          Center(
            child: Container(
              width: 250,
              height: 150,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.red, width: 3),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Buscando en la base de datos...',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}