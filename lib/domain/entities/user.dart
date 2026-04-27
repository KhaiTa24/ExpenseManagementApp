class User {
  final String id;
  final String email;
  final String? displayName;
  final String? uniqueIdentifier; // Định danh duy nhất để tìm kiếm
  final DateTime createdAt;

  const User({
    required this.id,
    required this.email,
    this.displayName,
    this.uniqueIdentifier,
    required this.createdAt,
  });
}
