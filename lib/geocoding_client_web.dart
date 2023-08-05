library geocoding_client_web;

import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:geocoding_client_interface/geocoding_client_interface.dart';
import 'package:geocoding_client_interface/not_found_geocoding_api_place.dart';
import 'package:geocoding_client_interface/place_mark.dart';
import 'package:google_maps/google_maps.dart' as gmap_web;
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';
import 'package:logger/logger.dart';

final logger = Logger(printer: PrettyPrinter());

class GeocodingClientWeb extends GeocodingClient {
  GeocodingClientWeb();

  static void registerWith(Registrar registrar) {
    GeocodingClient.instance = GeocodingClientWeb();
  }

  static const int searchResultLimit = 5;
  gmap_web.Geocoder geocoder = gmap_web.Geocoder();

  @visibleForTesting
  GeocodingClientWeb.withMockGeocoder({required this.geocoder});

  @override
  Future<List<PlaceMark>> getGeocode(String searchText) async {
    var geocoderRequest = gmap_web.GeocoderRequest()
      ..address = searchText
      ..region = "jp";
    var response = await geocoder.geocode(geocoderRequest);
    if (response.results != null && response.results!.isNotEmpty) {
      return response.results!
          .sublist(0, min(searchResultLimit, response.results!.length))
          .map((result) {
        String address = result?.formattedAddress ?? "";
        var lat = result?.geometry?.location?.lat;
        var lng = result?.geometry?.location?.lng;
        if (lat == null || lng == null) {
          return const PlaceMark(
              name: "dummy", address: "dummy", latLng: LatLng(0, 0));
        }
        var latLng = LatLng(lat.toDouble(), lng.toDouble());
        return PlaceMark(name: searchText, address: address, latLng: latLng);
      }).toList();
    } else {
      throw NotFoundGeocodingApiPlace();
    }
  }

  @override
  Future<PlaceMark> getPlaceMark(LatLng latLng) async {
    var latLngForWeb = gmap_web.LatLng(latLng.latitude, latLng.longitude);
    var geocoderRequest = gmap_web.GeocoderRequest()
      ..region = "jp"
      ..location = latLngForWeb;
    var response = await geocoder.geocode(geocoderRequest);
    if (response.results != null && response.results!.isNotEmpty) {
      gmap_web.GeocoderResult? result = response.results!.first;
      return PlaceMark(
        name: "名前を変更してね",
        address: result?.formattedAddress ?? "",
        latLng: latLng,
      );
    } else {
      throw NotFoundGeocodingApiPlace();
    }
  }
}
