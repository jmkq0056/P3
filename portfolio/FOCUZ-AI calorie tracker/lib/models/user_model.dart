/// Model representing a user in the fitness app
class UserModel {
  final String id;
  final String? displayName;
  final String? email;
  final String? photoUrl;
  final int? age;
  final double? height; // in cm
  final double? weight; // in kg
  final String? gender;
  final DateTime? createdAt;
  final DateTime? lastLoginAt;
  final Map<String, dynamic>? preferences;
  final Map<String, dynamic>? healthData;

  UserModel({
    required this.id,
    this.displayName,
    this.email,
    this.photoUrl,
    this.age,
    this.height,
    this.weight,
    this.gender,
    this.createdAt,
    this.lastLoginAt,
    this.preferences,
    this.healthData,
  });

  /// Create a UserModel from a Map (e.g., from Firestore)
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      displayName: map['display_name'],
      email: map['email'],
      photoUrl: map['photo_url'],
      age: map['age'],
      height: map['height']?.toDouble(),
      weight: map['weight']?.toDouble(),
      gender: map['gender'],
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : null,
      lastLoginAt: map['last_login_at'] != null
          ? DateTime.parse(map['last_login_at'])
          : null,
      preferences: map['preferences'],
      healthData: map['health_data'],
    );
  }

  /// Convert UserModel to a Map (e.g., for Firestore)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'display_name': displayName,
      'email': email,
      'photo_url': photoUrl,
      'age': age,
      'height': height,
      'weight': weight,
      'gender': gender,
      'created_at': createdAt?.toIso8601String(),
      'last_login_at': lastLoginAt?.toIso8601String(),
      'preferences': preferences,
      'health_data': healthData,
    };
  }

  /// Create a copy of UserModel with some changes
  UserModel copyWith({
    String? id,
    String? displayName,
    String? email,
    String? photoUrl,
    int? age,
    double? height,
    double? weight,
    String? gender,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    Map<String, dynamic>? preferences,
    Map<String, dynamic>? healthData,
  }) {
    return UserModel(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      age: age ?? this.age,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      gender: gender ?? this.gender,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      preferences: preferences ?? this.preferences,
      healthData: healthData ?? this.healthData,
    );
  }
} 