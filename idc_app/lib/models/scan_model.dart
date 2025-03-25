import 'package:cloud_firestore/cloud_firestore.dart';

class ScanModel {
  final String scanId;
  final String userId;
  final String citizenId;
  final DateTime timestamp;
  final GeoPoint location;
  final String result; // 'regular' or 'violator'
  final String violationDetails;

  ScanModel({
    required this.scanId,
    required this.userId,
    required this.citizenId,
    required this.timestamp,
    required this.location,
    required this.result,
    required this.violationDetails,
  });

  factory ScanModel.fromMap(Map<String, dynamic> map) {
    return ScanModel(
      scanId: map['scanId'] ?? '',
      userId: map['userId'] ?? '',
      citizenId: map['citizenId'] ?? '',
      timestamp: (map['timestamp'] as dynamic).toDate(),
      location: map['location'] ?? GeoPoint(0, 0),
      result: map['result'] ?? '',
      violationDetails: map['violationDetails'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'scanId': scanId,
      'userId': userId,
      'citizenId': citizenId,
      'timestamp': timestamp,
      'location': location,
      'result': result,
      'violationDetails': violationDetails,
    };
  }
}
