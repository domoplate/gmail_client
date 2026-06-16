class EmailConfig {
  final String id;
  final String orgName;
  final String webClientId;
  final String iosClientId;
  final String androidClientId;

  const EmailConfig({
    required this.id,
    required this.orgName,
    required this.webClientId,
    required this.iosClientId,
    required this.androidClientId,
  });

  factory EmailConfig.fromJson(Map<String, dynamic> json) {
    return EmailConfig(
      id: json['id'] ?? '',
      orgName: json['org_name'] ?? '',
      webClientId: json['google_web_client_id'] ?? '',
      iosClientId: json['google_ios_client_id'] ?? '',
      androidClientId: json['google_android_client_id'] ?? '',
    );
  }
}
