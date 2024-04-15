import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:usb_serial/usb_serial.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const StriderApp());
}

Future<void> requestPermission(Permission permission) async {
  if (await permission.isDenied) {
    await permission.request();
  }
}

class StriderApp extends StatelessWidget {
  const StriderApp({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations(
        [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);

    return MaterialApp(
      title: 'Strider',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MainPage(title: 'Controller'),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key, required this.title});

  final String title;

  @override
  State<MainPage> createState() => MainPageState();
}

bool connected = false;
double lastL = 0.0;
double lastR = 0.0;

late UsbPort port;

class MainPageState extends State<MainPage> {
  void _axisChange(bool lR, double value) {
    setState(() {
      if (lR) {
        lastL = value;
      } else {
        lastR = value;
      }
    });
    calculateInput();
  }

  void serialWrite(String input) {
    port.write(utf8.encode(input));
  }

  void calculateInput() {
    if (lastL > 0.125) {
      if (lastR > 0.125) {
        serialWrite("W");
      } else if (lastR < -0.125) {
        serialWrite("D");
      } else {
        serialWrite("Q");
      }
    } else if (lastL < -0.125) {
      if (lastR > 0.125) {
        serialWrite("A");
      } else if (lastR < -0.125) {
        serialWrite("S");
      } else {
        serialWrite("Y");
      }
    } else {
      if (lastR > 0.125) {
        serialWrite("E");
      } else if (lastR < -0.125) {
        serialWrite("C");
      } else {
        serialWrite("0");
      }
    }
  }

  @override
  void initState() {
    super.initState();

    setPort();
  }

  void setPort() async {
    List<UsbDevice> devices = await UsbSerial.listDevices();

    port = await devices[0].create() as UsbPort;

    port.open();

    port.setPortParameters(
        115200, UsbPort.DATABITS_8, UsbPort.STOPBITS_1, UsbPort.PARITY_NONE);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Row(children: [
        SizedBox(
          width: MediaQuery.of(context).size.width / 4,
          child: RotatedBox(
            quarterTurns: 3,
            child: Slider(
              value: lastL,
              min: -1.0,
              max: 1.0,
              divisions: 200,
              onChanged: (value) {
                _axisChange(true, value);
              },
              onChangeEnd: (value) {
                setState(() {
                  lastL = 0.0;
                  calculateInput();
                });
              },
            ),
          ),
        ),
        SizedBox(
          width: MediaQuery.of(context).size.width / 2,
          child: const FractionallySizedBox(
            widthFactor: 0.75,
          ),
        ),
        SizedBox(
          width: MediaQuery.of(context).size.width / 4,
          child: RotatedBox(
            quarterTurns: 3,
            child: Slider(
              value: lastR,
              min: -1.0,
              max: 1.0,
              divisions: 200,
              onChanged: (value) {
                _axisChange(false, value);
              },
              onChangeEnd: (value) {
                setState(() {
                  lastR = 0.0;
                  calculateInput();
                });
              },
            ),
          ),
        ),
      ]),
    );
  }
}
