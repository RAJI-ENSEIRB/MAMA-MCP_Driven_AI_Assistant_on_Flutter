import 'dart:core'; 

class OwnEvent {
  String description;
  DateTime startofevent;
  DateTime endofevent;
  List<Map<String,dynamic>> attendeespeople;

  OwnEvent(this.description,this.startofevent,this.endofevent,this.attendeespeople);

  Map<String, dynamic> toJson() {
    return {
      'Description': description,
      'Start_of_event': startofevent.toString(),
      'End_of_event': endofevent.toString(),
      'Attendees_people': attendeespeople
    };
 }
}