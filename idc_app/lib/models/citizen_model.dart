class CitizenModel {
  final String citizenId;
  final String fullName;
  final String status; // 'regular' or 'violator'
  final List<String> violations;
  final DateTime? lastChecked;

  CitizenModel({
    required this.citizenId,
    required this.fullName,
    required this.status,
    required this.violations,
    this.lastChecked,
  });

  factory CitizenModel.fromMap(Map<String, dynamic> map, String id) {
    return CitizenModel(
      citizenId: id,
      fullName: map['fullName'] ?? '',
      status: map['status'] ?? 'regular',
      violations: List<String>.from(map['violations'] ?? []),
      lastChecked: map['lastChecked'] != null
          ? (map['lastChecked'] as dynamic).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'status': status,
      'violations': violations,
      'lastChecked': lastChecked,
    };
  }
}
