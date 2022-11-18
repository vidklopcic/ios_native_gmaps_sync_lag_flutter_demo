import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:collection/collection.dart';

void main() {
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IOS Native Gmaps Sync Lag Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const Home(),
    );
  }
}

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  Offset? lastLatLng;
  Offset offset = Offset.zero;
  int delay = 12;

  List<Widget> get markers => List.generate(
        20,
        (xi) => List.generate(
          20,
          (yi) => Positioned(
            left: (10 + 20 * xi + offset.dx) % MediaQuery.of(context).size.width,
            top: (100 + 20 * yi + offset.dy) % MediaQuery.of(context).size.height,
            child: const Icon(Icons.location_on, color: Colors.red),
          ),
        ).toList(),
      ).flattened.toList().cast<Widget>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: markers +
            <Widget>[
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  margin: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white54,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(onPressed: () => setState(() => delay--), icon: const Icon(Icons.remove)),
                      Text('${delay}ms', style: const TextStyle(fontWeight: FontWeight.bold)),
                      IconButton(onPressed: () => setState(() => delay++), icon: const Icon(Icons.add)),
                    ],
                  ),
                ),
              )
            ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    ServicesBinding.instance.defaultBinaryMessenger.setMessageHandler(
      'com.vidklopcic.ios_native_gmaps_sync_lag_flutter_demo/maps',
      (message) {
        if (message == null) return;
        Offset currOffset = Offset(
          -message.getFloat64(8, Endian.little) * 2000,
          message.getFloat64(0, Endian.little) * 3000,
        );
        if (lastLatLng != null) {
          offset += currOffset - lastLatLng!;
          Future.delayed(Duration(milliseconds: delay)).then(
            (value) => setState(() {}),
          );
        }
        lastLatLng = currOffset;
      },
    );
  }
}
