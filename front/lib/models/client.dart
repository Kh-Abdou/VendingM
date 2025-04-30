class Client {
  final String id; // Changed from int to String to match MongoDB ObjectID
  final String name;
  final String email;
  final double credit;
  final String role; // Changed from "type" to "role" to match your backend

  Client({
    required this.id,
    required this.name,
    required this.email,
    required this.credit,
    required this.role, // Changed from "type" to "role"
  });

  factory Client.fromJson(Map<String, dynamic> json) {
    return Client(
      id: json['_id'], // Changed from "id" to "_id" to match MongoDB
      name: json['name'],
      email: json['email'],
      credit: json['credit'] != null
          ? (json['credit'] is int
              ? json['credit'].toDouble()
              : (json['credit'] is String
                  ? double.tryParse(json['credit']) ?? 0.0
                  : json['credit']))
          : 0.0,
      role: json['role'] ?? 'client', // Changed from "type" to "role"
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'credit': credit,
      'role': role, // Changed from "type" to "role"
    };
  }
}
