class AppUser {
  final String id;
  final String name;
  final String email;

  AppUser({required this.id, required this.name, required this.email});

  factory AppUser.fromMap(String id, Map<String, dynamic> data) {
    return AppUser(
      id: id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
    );
  }
}
