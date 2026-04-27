class SettingsModel {
  final String id;
  final String userId;
  final String key;
  final String value;

  const SettingsModel({
    required this.id,
    required this.userId,
    required this.key,
    required this.value,
  });

  factory SettingsModel.fromJson(Map<String, dynamic> json) {
    return SettingsModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      key: json['key'] as String,
      value: json['value'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'key': key,
      'value': value,
    };
  }
}
