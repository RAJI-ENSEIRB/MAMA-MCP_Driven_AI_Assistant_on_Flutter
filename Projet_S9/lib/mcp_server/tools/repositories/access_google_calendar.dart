//import 'dart:io';
//import 'package:googleapis/androidenterprise/v1.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:googleapis/calendar/v3.dart' as calendar;
import 'own_event.dart';
//import 'package:path/path.dart' as p;

Future<List<OwnEvent>> geteventscalendar(String? start, String? end) async{
  //final serviceAccountJson = File('/Users/nabla/Documents/Vs_code/Github_for_project/Project_S9/lib/mcp_server/repositories/service_account.json').readAsStringSync();
  //final accountCredentials = ServiceAccountCredentials.fromJson(serviceAccountJson);
  final accountCredentials  = ServiceAccountCredentials("calendar-reader@projectmcpserveurcalendars9.iam.gserviceaccount.com", ClientId("113768965237292995195"), "-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQDT4zfjhghLn+4i\nmU3jmWxDKhY1tMm4PB06SufngSc5xJ2Nz287T9mO+yeHGtqLuq8d3eyXLuVg81B8\nXRg8B0VhKTwiPaG4eZiI7XPcyOUr+iX3SdNvTrn3Yft0XTlbK/aiadzbvmvzALLD\nmKILf2A0BzTmdJipS8fbfcS9lDQ1ruJMxblym5y1sumwuqydjPDtQ50v5KPH4Erv\n/lh5xFUW+jIolRb4hY/+M3v0XF2IsW0Cn7+jCLCa8GH7Cj9hxwZHF6XNgQrnbVKE\nPHm5g81Xt4TfDZU8zk6djx1bJQXnuYVoE/6D39W0B3OhD7+/WRfsXzKs+NV7Buow\nww9Y33P/AgMBAAECggEAVudxE0T0XwwT0CX/f7N751o6LMHfIEyrki6JyfY7X+Kn\n2jNzhCieaxnQnwWhEEE7tKzCbkmCM87nunI2T9yNlKmka8jKbQ6WRMbbR/kvoWdi\nLfgeG592/6M0zoez0BSKfhecSZZi0RJ+v2F5SOzvyLcR99lnibw2luwRBs5j0YYP\nSJRbuXXMpCXmJ/2e37ZJcTLOHSKly13ujPf8mAkxWiCb+W27701D66chZs3ZERJK\nfDnzrL6Y7naZ8yIeoHH1b1G3yEISsJ7WJ7mESayuFv/xhW0Y37aaQG6hCQoTB4Lc\nQKTlxXNNpmA3KNajx2FYLMLWbL1IkxkPnjsMz6t2WQKBgQDxViIlD6h3DPkNgel5\nAqdBw/O5avhAfEVridTLAIP2ItEQuFilhJSMoBYZVf5/eSC/+nk9hJHe4/G5uvH1\nxqAFaW3cff5gIpVnIcBrO9nZMyl0j3i+MOZ76YztAQteU4u1IRlPyTYKUmK14BZ2\npnGqiWAXHTGtGDp3yfyDYxntNwKBgQDgwwW7H09qHjVx+PEvNhpzTaJa3gRAOlX4\n3zY6fHVTSeB9ff3UOwdqjSEkVRY0lkTdS2K3ENP1FOHEXOnuiraQeH0L5dQxYQ0E\nkMdwV999gWsSh/xwaIbMOzUauxxJjqWF1640qproUrdIujCZiCvsXAeT1aYRhRy8\nnn56crbTeQKBgQDtbewRwiHfXif4HgNwRif/D6VMmey6pIg3kFaFkXBCS2abqIGt\n9Y2f/C9BpdTH3IdX2DhHSZGpU2CRdVZukocETAEFl/8W3W9XE2GXHj7o7OiwACau\nFrXq2o8G7KwelNsxy+p3EGHWLc9nV5tCB+Zz/MtIcjRZMyjyiQmgyXLMaQKBgF7i\nlgHIFwuSkzd5Q8CNk58HsDmyLpM6zV6SRN9t+U3fC1GPJeA5x0i5Kbuf3A75PTs6\n/wKPrRty5Fi0bOGSV74nz4p9TRZHhWpfAIMx5ZyjTSN2myCNUBLaD/In+aon+ULG\nqbl8KIdZnBys1aWLMhfHRj+n20LcMiSCuJxS31HpAoGAGJjP0mrfuTdEB1tKmzPl\nBYc4QDXGEeQNyBF0E3WYv/7/pqPZ1Nc4r7hko0wpTW41IqC7udtxRo0y6EspB14o\nkzz9WzbAAx4EOpi2H7R9Ial8kG+p9CsgO0uYIwXMjy0eD8hgVRGfM9HDAr6cIMNa\nPsonI1WQEkqbJnP7xJ9fKaU=\n-----END PRIVATE KEY-----\n");
  const scopes = [calendar.CalendarApi.calendarReadonlyScope];

  final client = await clientViaServiceAccount(accountCredentials, scopes);

  final calendarApi = calendar.CalendarApi(client);

  const calendarId = 'fromcpserveurs9@gmail.com';

  var events = calendar.Events();

  if (start == null && end == null){
    events = await calendarApi.events.list(
      calendarId,
      orderBy: 'startTime',
      singleEvents: true,
    );
  }
  else if (start == null){
    final pe = end!.split("/");
    final dateMax = DateTime(int.parse(pe[2]),int.parse(pe[1]),int.parse(pe[0]),23,59,0);
    events = await calendarApi.events.list(
      calendarId,
      orderBy: 'startTime',
      singleEvents: true,
      timeMax: dateMax,
    );
  }
  else if (end==null){
    final ps = start.split("/");
    final dateMin = DateTime(int.parse(ps[2]),int.parse(ps[1]),int.parse(ps[0]),0,0,0);
    events = await calendarApi.events.list(
      calendarId,
      orderBy: 'startTime',
      singleEvents: true,
      timeMin: dateMin,
    );
  }
  else{
    final pe = end.split("/");
    final dateMax = DateTime(int.parse(pe[2]),int.parse(pe[1]),int.parse(pe[0]),23,59,0);
    final ps = start.split("/");
    final dateMin = DateTime(int.parse(ps[2]),int.parse(ps[1]),int.parse(ps[0]),0,0,0);
    events = await calendarApi.events.list(
      calendarId,
      orderBy: 'startTime',
      singleEvents: true,
      timeMin: dateMin,
      timeMax: dateMax,
    );
  }
  List<OwnEvent> listofevent = [];
  for (var item in events.items ?? []){
    final description = item.description ?? '(Aucune description)';
    final startofevents = item.start?.dateTime ?? item.start?.date;
    final endofevents = item.end?.dateTime ?? item.end?.date;
    final list_of_attendees = item.attendees;
    var attendeespeople = [{"":""}];
    if (list_of_attendees != null && list_of_attendees.isNotEmpty){
      for (var person in list_of_attendees){
        attendeespeople = [];
        attendeespeople.add({"email":person.email ?? "","name":person.displayName ?? ""});
      }
    }
    if (startofevents != null && endofevents != null) {
      listofevent.add(OwnEvent(description, startofevents, endofevents,attendeespeople));
    }
  }
  client.close();
  return listofevent;
}