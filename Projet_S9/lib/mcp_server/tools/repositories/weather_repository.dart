import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherRepository {
  Future<Map<String, dynamic>> fetchLatLonFrance({ //Résulat asynchrone (temps d'attente de la requête réseau HTTP)
    String? city, String? postalCode, double? lat, double? lon
  }) async { //Future avec async
    if(lat != null && lon != null) {
      return {'lat': lat, 'lon': lon, 'name': city ?? '', 'country_code': ''};
    }
    final query=(postalCode?.trim().isNotEmpty == true) ? postalCode!.trim() : city?.trim() ?? ''; //null-safety
    if(query.isEmpty) {
      throw Exception('City or postal code must be provided');
    }

    final geoUrl='https://geocoding-api.open-meteo.com/v1/search'
        '?name=${Uri.encodeComponent(query)}'
        '&count=1&language=fr&country=FR'; //Expl: https://geocoding-api.open-meteo.com/v1/search?name=Paris&count=1&language=fr&country=FR

    final res = await http.get(Uri.parse(geoUrl)); //attente de la réponse HTTP pour Future
    if (res.statusCode != 200) {
      throw Exception('Erreur géocodage (${res.statusCode})');
    }
    final data = jsonDecode(res.body);
    final results = (data['results'] as List?) ?? [];
    if (results.isEmpty) {
      throw Exception('Localisation introuvable en France pour "$query".');
    }
    final r = results.first;
    return {
      'lat': (r['latitude'] as num).toDouble(),
      'lon': (r['longitude'] as num).toDouble(),
      'name': r['name'],
      'country_code': r['country_code'],
    };
  }

  Future<Map<String, dynamic>> fetchWeather(double lat, double lon) async {
    final url =
        'https://api.open-meteo.com/v1/forecast'
        '?latitude=$lat&longitude=$lon'
        '&current_weather=true&timezone=auto'; //Expl: https://api.open-meteo.com/v1/forecast?latitude=79&longitude=89&current_weather=true&timezone=auto
    final res = await http.get(Uri.parse(url)).timeout(
      const Duration(seconds: 10),
      onTimeout: () => throw Exception('Weather request timed out'),
    );
    if (res.statusCode != 200) {
      throw Exception('Erreur météo (${res.statusCode})');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> fetchDailyForecast(double lat, double lon, int forecastDays) async {
    final dailyVars=[
      'temperature_2m_max',
      'temperature_2m_min',
      'precipitation_sum'
    ].join(','); //chaîne de caractères séparée par des virgules pour l'url

    final url =
        'https://api.open-meteo.com/v1/forecast'
        '?latitude=$lat&longitude=$lon'
        '&timezone=auto'
        '&daily=$dailyVars';
    final res = await http.get(Uri.parse(url)).timeout(
      const Duration(seconds: 10),
      onTimeout: () => throw Exception('Forecast request timed out'),
    );
    if (res.statusCode != 200) {
      throw Exception('Erreur prévision (${res.statusCode})');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Object getDailyValue(Map<String, dynamic> daily, String key, int index) {
    return daily[key][index];
  }

  Future<Map<String, dynamic>> fetchPastWeather(double lat, double lon, int pastDays) async {
    final dailyVars=[
      'temperature_2m_max',
      'temperature_2m_min',
      'precipitation_sum'
    ].join(','); //chaîne de caractères séparée par des virgules pour l'url

    final url =
        'https://api.open-meteo.com/v1/forecast'
        '?latitude=$lat&longitude=$lon'
        '&timezone=auto'
        '&daily=$dailyVars'
        '&past_days=$pastDays'; //Expl: https://api.open-meteo.com/v1/forecast?latitude=79&longitude=89&timezone=auto&daily=temperature_2m_max,temperature_2m_min,precipitation_sum&past_days=3

    final res = await http.get(Uri.parse(url)).timeout(
      const Duration(seconds: 10),
      onTimeout: () => throw Exception('Past weather request timed out'),
    );
    if (res.statusCode != 200) {
      throw Exception('Erreur météo passée (${res.statusCode})');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  String formatDate(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }
}