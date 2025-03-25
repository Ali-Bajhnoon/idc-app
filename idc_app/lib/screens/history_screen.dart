import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/scan_model.dart';
import 'scan_details_screen.dart';

class HistoryScreen extends StatefulWidget {
  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _filterStatus = 'all';
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildFilters(),
          SizedBox(height: 16),
          Expanded(
            child: _buildScansList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'تصفية النتائج',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'الحالة',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    value: _filterStatus,
                    items: [
                      DropdownMenuItem(value: 'all', child: Text('الكل')),
                      DropdownMenuItem(value: 'regular', child: Text('نظامي')),
                      DropdownMenuItem(value: 'violator', child: Text('مخالف')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _filterStatus = value!;
                      });
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _startDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setState(() {
                          _startDate = date;
                        });
                      }
                    },
                    icon: Icon(Icons.calendar_today),
                    label: Text(_startDate == null
                        ? 'من تاريخ'
                        : DateFormat('yyyy-MM-dd').format(_startDate!)),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: TextButton.icon(
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _endDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setState(() {
                          _endDate = date;
                        });
                      }
                    },
                    icon: Icon(Icons.calendar_today),
                    label: Text(_endDate == null
                        ? 'إلى تاريخ'
                        : DateFormat('yyyy-MM-dd').format(_endDate!)),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    setState(() {});
                  },
                  child: Text('تطبيق'),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _filterStatus = 'all';
                      _startDate = null;
                      _endDate = null;
                    });
                  },
                  child: Text('إعادة ضبط'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScansList() {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    
    Query query = FirebaseFirestore.instance
        .collection('scans')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true);
    
    if (_filterStatus != 'all') {
      query = query.where('result', isEqualTo: _filterStatus);
    }
    
    if (_startDate != null) {
      query = query.where('timestamp', isGreaterThanOrEqualTo: _startDate);
    }
    
    if (_endDate != null) {
      // إضافة يوم واحد للحصول على نهاية اليوم
      final endDatePlusOne = _endDate!.add(Duration(days: 1));
      query = query.where('timestamp', isLessThan: endDatePlusOne);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('حدث خطأ: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('لا توجد عمليات مسح'));
        }

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final data = doc.data() as Map<String, dynamic>;
            final scan = ScanModel.fromMap(data);
            
            return Card(
              margin: EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: scan.result == 'violator' ? Colors.red : Colors.green,
                  child: Icon(
                    scan.result == 'violator' ? Icons.warning : Icons.check,
                    color: Colors.white,
                  ),
                ),
                title: Text('رقم الهوية: ${scan.citizenId}'),
                subtitle: Text(
                  'التاريخ: ${DateFormat('yyyy-MM-dd HH:mm').format(scan.timestamp)}',
                ),
                trailing: Icon(Icons.arrow_forward_ios),
                onTap: () async {
                  // الحصول على بيانات المواطن
                  final citizenDoc = await FirebaseFirestore.instance
                      .collection('citizens')
                      .doc(scan.citizenId)
                      .get();
                  
                  if (citizenDoc.exists) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ScanDetailsScreen(
                          scan: scan,
                          citizenData: citizenDoc.data() as Map<String, dynamic>,
                        ),
                      ),
                    );
                  }
                },
              ),
            );
          },
        );
      },
    );
  }
}
