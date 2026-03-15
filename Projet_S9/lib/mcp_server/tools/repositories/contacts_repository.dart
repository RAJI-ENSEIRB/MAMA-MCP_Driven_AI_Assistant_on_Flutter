import 'dart:convert';
import 'dart:io';
import '../../../auth/google_auth_service.dart';

class ContactsRepository {
  static const String _peopleApiUrl =
      'https://people.googleapis.com/v1/people/me/connections'
      '?personFields=names,emailAddresses,phoneNumbers';

  Future<List<Map<String, dynamic>>> getContacts() async {
    final user = GoogleAuthService.currentUser;
    if (user == null) {
      throw Exception("NOT_CONNECTED");
    }

    final token = await GoogleAuthService.getAccessToken();
    if (token == null) {
      throw Exception("NOT_CONNECTED");
    }

    final client = HttpClient();
    final request = await client.getUrl(Uri.parse(_peopleApiUrl));

    request.headers.set('Authorization', 'Bearer $token');

    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();

    final json = jsonDecode(body);

    final connections = json['connections'] as List<dynamic>?;

    if (connections == null) return [];

    return connections.map((c) {
      final name = c['names']?[0]?['displayName'];
      final email = c['emailAddresses']?[0]?['value'];
      final phone = c['phoneNumbers']?[0]?['value'];

      return {'name': name, 'email': email, 'phone': phone};
    }).toList();
  }
}
