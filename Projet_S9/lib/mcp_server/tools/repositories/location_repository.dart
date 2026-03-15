import 'dart:convert';
import 'package:http/http.dart' as http;

class LocationRepository {
  // API gratuite ip-api.com (45 requêtes/minute)
  static const String _apiUrl = 'http://ip-api.com/json/';

  Future<Map<String, dynamic>> getCurrentLocation() async {
    try {
      final response = await http.get(Uri.parse(_apiUrl));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        return {
          'latitude': (data['lat'] as num).toDouble(),
          'longitude': (data['lon'] as num).toDouble(),
          'city': data['city'] as String? ?? '',
          'region': data['regionName'] as String? ?? '',
          'country': data['country'] as String? ?? '',
          'country_code': data['countryCode'] as String? ?? '',
          'postal_code': data['zip'] as String?,
          'timezone': data['timezone'] as String?,
        };
      } else {
        throw Exception('Erreur API: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Impossible de récupérer la localisation: $e');
    }
  }
}
