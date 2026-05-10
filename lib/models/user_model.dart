class UserModel {
  final String uid;
  final String branchCode;
  final String branchName;
  final String email;
  final String? location;

  UserModel({
    required this.uid,
    required this.branchCode,
    required this.branchName,
    required this.email,
    this.location,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'branchCode': branchCode,
      'branchName': branchName,
      'email': email,
      'location': location,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      branchCode: map['branchCode'] ?? '',
      branchName: map['branchName'] ?? '',
      email: map['email'] ?? '',
      location: map['location'],
    );
  }
}
