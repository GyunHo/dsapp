import 'package:flutter/material.dart';
import 'package:kf_drawer/kf_drawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong/latlong.dart';
import 'package:location/location.dart';

class SensingMap extends KFDrawerContent {
  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<SensingMap> {
  MapController mapController = MapController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          "센싱 중계기",
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          onPressed: widget.onMenuPressed,
          icon: Icon(Icons.menu),
        ),
        centerTitle: true,
      ),
      body: FlutterMap(
        mapController: mapController,
        options: new MapOptions(
          center: LatLng(36.2930394, 127.3389981),
          zoom: 16.0,
        ),
        layers: [
          new TileLayerOptions(
            urlTemplate:
                "https://api.mapbox.com/styles/v1/desnait/ck32w5yz100bs1coes1gpknzl/tiles/256/{z}/{x}/{y}@2x?access_token=pk.eyJ1IjoiZGVzbmFpdCIsImEiOiJjazJ5Y2JnYjYwMm5hM2hyM3ppcHN5bzkyIn0.R5OsMp9UtdAALEvFLkhPYg",
            additionalOptions: {
              'accessToken':
                  'pk.eyJ1IjoiZGVzbmFpdCIsImEiOiJjazJ5Y2JnYjYwMm5hM2hyM3ppcHN5bzkyIn0.R5OsMp9UtdAALEvFLkhPYg',
              'id': 'mapbox.mapbox-streets-v8',
            },
          ),
          new MarkerLayerOptions(
            markers: [
              new Marker(
                  width: 80,
                  height: 80,
                  point: LatLng(36.293036, 127.335971),
                  builder: (ctx) => Icon(
                        Icons.my_location,
                        size: 50.0,
                        color: Colors.red,
                      )),
            ],
          ),
        ],
      ),
    );
  }
}
