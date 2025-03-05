import 'package:cloud_firestore/cloud_firestore.dart';

enum MaritalStatus {
  single,
  married,
  divorced,
  widowed;

  String toDisplayString() {
    return name[0].toUpperCase() + name.substring(1);
  }
}

class Member {
  Member({
    required this.id,
    required this.name,
    this.imageUrl,
    this.occupation,
    this.maritalStatus,
    this.spouseName,
    this.birthDate,
    this.weddingDate,
    this.phoneNumber,
    this.email,
    this.address,
  });

  factory Member.fromFirestore(DocumentSnapshot doc) {
    final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Member(
      id: doc.id,
      name: data['name'] ?? '',
      imageUrl: data['photoUrl'] ?? data['imageUrl'],
      occupation: data['occupation'],
      maritalStatus: data['maritalStatus'] != null
          ? MaritalStatus.values.firstWhere(
              (e) => e.name == data['maritalStatus'],
              orElse: () => MaritalStatus.single)
          : null,
      spouseName: data['spouseName'],
      birthDate: data['dateOfBirth'] != null
          ? (data['dateOfBirth'] as Timestamp).toDate()
          : (data['birthDate'] != null
              ? (data['birthDate'] as Timestamp).toDate()
              : null),
      weddingDate: data['weddingDate'] != null
          ? (data['weddingDate'] as Timestamp).toDate()
          : null,
      phoneNumber: data['phoneNumber'],
      email: data['email'],
      address: data['address'],
    );
  }
  final String id;
  final String name;
  final String? imageUrl;
  final String? occupation;
  final MaritalStatus? maritalStatus;
  final String? spouseName;
  final DateTime? birthDate;
  final DateTime? weddingDate;
  final String? phoneNumber;
  final String? email;
  final String? address;

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'imageUrl': imageUrl,
      'occupation': occupation,
      'maritalStatus': maritalStatus?.name,
      'spouseName': spouseName,
      'birthDate': birthDate != null ? Timestamp.fromDate(birthDate!) : null,
      'weddingDate':
          weddingDate != null ? Timestamp.fromDate(weddingDate!) : null,
      'phoneNumber': phoneNumber,
      'email': email,
      'address': address,
    };
  }
}
