import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
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
  static List<Marker> markers = List.generate(
    17,
    (xi) => List.generate(
      17,
      (yi) => Marker(
        point: LatLng(46.0569 + 0.01 * (xi - 8), 14.5058 + 0.01 * (yi - 8)),
        builder: (context) => const Icon(Icons.location_on, color: Colors.red),
        anchorPos: AnchorPos.align(AnchorAlign.bottom),
      ),
    ).toList(),
  ).flattened.toList();
  MapController controller = MapController();
  MapMode mapMode = MapMode.nativeGM;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        child: Text(
          kMapModeLabel[mapMode]!,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        onPressed: () => setState(() {
          mapMode = MapMode.values[(mapMode.index + 1) % MapMode.values.length];
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(kMapModeDescription[mapMode]!)));
        }),
      ),
      body: FlutterMap(
        mapController: controller,
        options: MapOptions(
          interactiveFlags: kMapModeInteractiveFlags[mapMode]!,
          center: LatLng(46.0569, 14.5058),
          zoom: 11.5,
        ),
        children: [
          if (mapMode == MapMode.osm)
            TileLayer(
              maxNativeZoom: 18,
              urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
            ),
          MarkerLayer(markers: markers),
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
        if (message == null || mapMode != MapMode.nativeGM) return;
        final center = LatLng(message.getFloat64(0, Endian.little), message.getFloat64(8, Endian.little));
        final zoom = message.getFloat32(16, Endian.little);
        final rotation = message.getFloat32(20, Endian.little);
        controller.moveAndRotate(center, zoom, rotation);
      },
    );
  }
}

enum MapMode { nativeGM, osm }

const Map<MapMode, String> kMapModeLabel = {
  MapMode.nativeGM: 'GMS',
  MapMode.osm: 'OSM',
};
const Map<MapMode, String> kMapModeDescription = {
  MapMode.nativeGM: 'Native Google Map synchronized to FlutterMap',
  MapMode.osm: 'Flutter handles all touch events and map movements.',
};

const Map<MapMode, int> kMapModeInteractiveFlags = {
  MapMode.nativeGM: InteractiveFlag.none,
  MapMode.osm: InteractiveFlag.all & ~InteractiveFlag.rotate,
};
