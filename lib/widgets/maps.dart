import 'package:flutter/material.dart';

import 'package:google_maps_webservice/places.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart' as LocationManager;
import 'package:url_launcher/url_launcher.dart';

class Maps extends StatefulWidget {
  Maps({Key key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _MapsState();
  }
}

class _MapsState extends State<Maps> {
  static String kGoogleApiKey = "AIzaSyAP2X_vG7-hXWunjAhzOyAj7BGwYOTSbU4";
  GoogleMapsPlaces _places = GoogleMapsPlaces(apiKey: kGoogleApiKey);

  static final CameraPosition _berlin = CameraPosition(
    target: LatLng(52.521918, 13.413215),
    zoom: 10.0,
  );

  GoogleMapController controller;
  Map<MarkerId, Marker> markers = <MarkerId, Marker>{};
  Map<String, PlacesSearchResult> foundPlaces = <String, PlacesSearchResult>{};

  bool markerIsTabbed = false;
  String name = "";
  String desc = "";
  String oh = "";
  String photo;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              // todo: go back to previous page
            }),
        title: Text('Apotheken in Ihrer Nähe'),
        actions: <Widget>[
          IconButton(
              icon: Icon(Icons.arrow_forward),
              onPressed: () {
                // todo: go to next page
              }),
        ],
      ),
      body: Stack(
        children: <Widget>[
          _googleMapsContainer(context),
          _buildContainer(),
        ],
      ),
    );
  }

  Widget _googleMapsContainer(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height,
      width: MediaQuery.of(context).size.width,
      child: GoogleMap(
        initialCameraPosition: _berlin,
        mapType: MapType.normal,
        onMapCreated: _onMapCreated,
        onCameraMove: (position) {

        },
        markers: Set<Marker>.of(markers.values),
      ),
    );
  }

  Widget _buildContainer() {
    return Visibility(
        visible: markerIsTabbed,
        child:Align(
          alignment: Alignment.bottomLeft,
          child: Container(
            margin: EdgeInsets.symmetric(vertical: 20.0),
            height: 150.0,
            width:  300.0,
            child: Column(
              //scrollDirection: Axis.horizontal,
              children: <Widget>[
                SizedBox(width: 10.0),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: _boxes(photo),
                ),
              ],
          ),
        ),
      )
    );
  }

  Widget _boxes(String _image) {
    return  GestureDetector(
      onTap: () {
        //_gotoLocation(lat,long);
      },
      child:Container(
        child: new FittedBox(
          fit: BoxFit.fill,
          child: Material(
              color: Colors.white,
              elevation: 14.0,
              borderRadius: BorderRadius.circular(24.0),
              shadowColor: Color(0x802196F3),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Container(
                    width: 80,
                    height: 80,
                    child: ClipRRect(
                      borderRadius: new BorderRadius.circular(30.0),
                      child: Image(
                        fit: BoxFit.fill,
                        image: _apoImage(),//NetworkImage(buildPhotoURL(photo)),
                      ),
                    ),),
                  Container(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: detailsContainer(name, desc, oh),
                    ),
                  ),

                ],)
          ),
        ),
      ),
    );
  }

  NetworkImage _apoImage() {
    NetworkImage image = new NetworkImage("https://www.abda.de/fileadmin/_processed_/d/3/csm_Apo_Logo_Neu_HKS13_neues_BE_42f1ed22ad.jpg");
    /*try {
      image = new NetworkImage(buildPhotoURL(photo));
    } catch(Exception) {
      image = new NetworkImage("https://www.abda.de/fileadmin/_processed_/d/3/csm_Apo_Logo_Neu_HKS13_neues_BE_42f1ed22ad.jpg");
    }*/
    return image;
  }

  String buildPhotoURL(String photoReference) {
    return "https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photoreference=${photoReference}&key=${kGoogleApiKey}";
  }

  Widget detailsContainer(String nameA, String descA, String openingHours) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: Container(
              child: Text(nameA,
                style: TextStyle(
                    color: Color(0xff6200ee),
                    fontSize: 20.0,
                    fontWeight: FontWeight.bold),
              )),
        ),
        SizedBox(height:5.0),
        Container(
            child: Text(
              descA,
              style: TextStyle(
                color: Colors.black54,
                fontSize: 12.0,
              ),
            )),
        SizedBox(height:5.0),
        Container(
            child: Text(
              openingHours,
              style: TextStyle(
                  color: Colors.black54,
                  fontSize: 12.0,
                  fontWeight: FontWeight.bold),
            )),
        SizedBox(height:5.0),
        Container(
            child: IconButton(
              icon: Icon(Icons.call),
              tooltip: "Apotheke anrufen",
              onPressed: () => launch("tel://017655595223"),
            )),
      ],
    );
  }

  Future _onMapCreated(GoogleMapController mapsController) async {
    controller = mapsController;

    // move to current location
    var location = await getCurrentLocation();
    controller.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(
      target: LatLng(location.latitude, location.longitude),
      zoom: 13.0,
    )));
    addMarker("Mein Standort", LatLng(location.latitude, location.longitude));

    // add markers
    final loc = Location(location.latitude, location.longitude);
    final result = await _places.searchByText("apotheke", location: loc, radius: 1000);

    setState(() {
      if (result.status == "OK") {
        result.results.forEach((f){
          if(!foundPlaces.containsKey(f.id)) {
            foundPlaces[f.id] = f;
          }
          print(f.name);
          addMarker(f.id, LatLng(f.geometry.location.lat, f.geometry.location.lng), place: f);
        });
      }
    });
  }

  Future<LatLng> getCurrentLocation() async {
    final location = LocationManager.Location();
    try {
      var currentloc = await location.getLocation();
      final lat = currentloc.latitude;
      final lng = currentloc.longitude;
      return LatLng(lat, lng);
    } catch (e) {
      return _berlin.target;
    }
  }

  void addMarker(var id, LatLng latlng, {PlacesSearchResult place}) {
    final MarkerId markerId = MarkerId(id);
    Marker marker;

    if(id == "Mein Standort") {
      marker = Marker(
          markerId: markerId,
          position: latlng,
          infoWindow: InfoWindow(title: id, snippet: '')
      );
    } else {
      if(place.openingHours != null) {
        oh = place.openingHours.openNow? 'Jetzt geöffnet' : 'Momentan geschlossen';
        marker = Marker(
          markerId: markerId,
          position: latlng,
          infoWindow: InfoWindow(title: place.name, snippet: oh),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          onTap: () {
            _onMarkerTapped(id);
          },
        );
      }
    }

    if(marker != null) {
      setState(() {
        // adding a new marker to map
        if(!markers.containsKey(markerId)) {
          markers[markerId] = marker;
        }
      });
    }
  }

  Future _onMarkerTapped(id) async {
    print(markerIsTabbed);
    setState(() {
      markerIsTabbed = true;
      if(foundPlaces[id].photos.length != 0) {
        try{
          photo = foundPlaces[id].photos.first.photoReference;
          print(photo);
        } catch (Exception) { }
      }
      name = foundPlaces[id].name;
      desc = foundPlaces[id].formattedAddress;
    });
  }
}