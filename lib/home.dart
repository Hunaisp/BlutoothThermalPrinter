import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:flutter/services.dart';

class PrintScreen extends StatefulWidget {
  @override
  _PrintScreenState createState() => _PrintScreenState();
}

class _PrintScreenState extends State<PrintScreen> {
  GlobalKey _globalKey = GlobalKey();
  BlueThermalPrinter bluetooth = BlueThermalPrinter.instance;

  Future<Uint8List?> _captureScreen() async {
    RenderRepaintBoundary boundary =
    _globalKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    ui.Image image = await boundary.toImage(pixelRatio: 3.0);
    ByteData? byteData = await image.toByteData(format: ImageByteFormat.png);
    Uint8List? pngBytes = byteData?.buffer.asUint8List();
    return pngBytes;
  }

  Future<bool?> _isPrinterConnected() async {
    return await bluetooth.isConnected;
  }

  void _printScreen() async {
    try {
      bool? isConnected = await _isPrinterConnected();

      if (!isConnected!) {
        _showBluetoothConnectionDialog();
        return;
      }

      Uint8List? pngBytes = await _captureScreen();

      if (pngBytes != null) {
        await _sendToPrinter(pngBytes);
      }
    } on PlatformException catch (error) {
      if (error.code == 'write_error') {
        _showBluetoothConnectionDialog();
      }
    }
  }

  Future<void> _sendToPrinter(Uint8List pngBytes) async {
    String base64Image = base64Encode(pngBytes);

    try {
      await bluetooth.printCustom(base64Image, 2, 2); // Example: Scale 2x2
    } on PlatformException catch (error) {
      // Handle printer specific errors, if any
      print('Printer Error: $error');
    }
  }

  void _showBluetoothConnectionDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Bluetooth Printer'),
          content: Text('Connect to Bluetooth Printer'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Add your Bluetooth connection logic here
                // For example, navigate to the Bluetooth settings page
              },
              child: Text('Connect'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Print Screen'),
      ),
      body: RepaintBoundary(
        key: _globalKey,
        child: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              Text('Example Text 1'),
              Text('Example Text 2'),
              // Add more widgets here
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _printScreen,
        tooltip: 'Print',
        child: Icon(Icons.print),
      ),
    );
  }
}
