class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.createdAt,
  });

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'createdAt': createdAt,
    };
  }

  // Convert from Firestore document
  factory UserModel.fromFirestore(Map<String, dynamic> data, String docId) {
    return UserModel(
      uid: docId,
      email: data['email'] as String? ?? '',
      displayName: data['displayName'] as String? ?? '',
      createdAt: (data['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
    );
  }

  // Copy with method for immutability
  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    DateTime? createdAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
