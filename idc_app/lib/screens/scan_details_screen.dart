import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/scan_model.dart';
import '../models/citizen_model.dart';

class ScanDetailsScreen extends StatelessWidget {
  final ScanModel scan;
  final Map<String, dynamic> citizenData;

  ScanDetailsScreen({
    required this.scan,
    required this.citizenData,
  });

  @override
  Widget build(BuildContext context) {
    final citizen = CitizenModel.fromMap(citizenData, scan.citizenId);
    final bool isViolator = citizen.status == 'violator';

    return Scaffold(
      appBar: AppBar(
        title: Text('تفاصيل عملية المسح'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: isViolator ? Colors.red : Colors.green,
                        child: Icon(
                          isViolator ? Icons.warning : Icons.check,
                          size: 50,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        isViolator ? 'مخالف' : 'موظف نظامي',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: isViolator ? Colors.red : Colors.green,
                        ),
                      ),
                      SizedBox(height: 24),
                      _buildInfoRow('رقم الهوية:', citizen.citizenId),
                      _buildInfoRow('الاسم الكامل:', citizen.fullName),
                      _buildInfoRow(
                        'تاريخ المسح:',
                        DateFormat('yyyy-MM-dd HH:mm').format(scan.timestamp),
                      ),
                      _buildInfoRow(
                        'الموقع:',
                        '${scan.location.latitude}, ${scan.location.longitude}',
                      ),
                      if (isViolator && citizen.violations.isNotEmpty) ...[
                        SizedBox(height: 16),
                        Text(
                          'المخالفات:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        ...citizen.violations.map((violation) => Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Row(
                                children: [
                                  Icon(Icons.error, color: Colors.red, size: 16),
                                  SizedBox(width: 8),
                                  Expanded(child: Text(violation)),
                                ],
                              ),
                            )),
                      ],
                    ],
                  ),
                ),
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Text(
                    'العودة',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
