class Event {
  final String id;
  final String name;

  Event({
    required this.id,
    required this.name,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'],
      name: json['name'],
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Event && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class EventCreate {
  final String name;

  EventCreate({
    required this.name,
  });
}