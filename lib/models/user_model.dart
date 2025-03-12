// lib/models/user_model.dart
class UserModel {
  final String id;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final AuthType authType;

  UserModel({
    required this.id,
    required this.email,
    this.displayName,
    this.photoUrl,
    required this.authType,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'authType': authType.toString(),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'],
      email: map['email'],
      displayName: map['displayName'],
      photoUrl: map['photoUrl'],
      authType: _getAuthTypeFromString(map['authType']),
    );
  }
}

enum AuthType { email, google, facebook }

AuthType _getAuthTypeFromString(String authType) {
  switch (authType) {
    case 'AuthType.email':
      return AuthType.email;
    case 'AuthType.google':
      return AuthType.google;
    case 'AuthType.facebook':
      return AuthType.facebook;
    default:
      return AuthType.email;
  }
}
