import 'package:flutter/material.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'results_screen.dart';
import '../models/citizen_model.dart';
import '../models/scan_model.dart';

class ScanScreen extends StatefulWidget {
  @override
  _ScanScreenState createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final _idController = TextEditingController();
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void dispose() {
    _idController.dispose();
    super.dispose();
  }

  Future<void> _scanBarcode() async {
    try {
      String barcodeScanRes = await FlutterBarcodeScanner.scanBarcode(
        '#FF6666',
        'إلغاء',
        true,
        ScanMode.BARCODE,
      );

      if (barcodeScanRes != '-1') {
        _processId(barcodeScanRes);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'حدث خطأ أثناء المسح: ${e.toString()}';
      });
    }
  }

  Future<void> _processId(String id) async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // الحصول على الموقع الحالي
      Position position = await _determinePosition();
      
      // البحث عن المواطن في قاعدة البيانات
      final citizenDoc = await FirebaseFirestore.instance
          .collection('citizens')
          .doc(id)
          .get();

      if (!citizenDoc.exists) {
        setState(() {
          _errorMessage = 'لم يتم العثور على مواطن بهذا الرقم';
          _isLoading = false;
        });
        return;
      }

      // إنشاء نموذج المواطن
      final citizenData = citizenDoc.data() as Map<String, dynamic>;
      final citizen = CitizenModel.fromMap(citizenData, id);

      // إنشاء سجل للمسح
      final scanId = FirebaseFirestore.instance.collection('scans').doc().id;
      final scan = ScanModel(
        scanId: scanId,
        userId: FirebaseAuth.instance.currentUser!.uid,
        citizenId: id,
        timestamp: DateTime.now(),
        location: GeoPoint(position.latitude, position.longitude),
        result: citizen.status,
        violationDetails: citizen.status == 'violator' && citizen.violations.isNotEmpty
            ? citizen.violations.join(', ')
            : '',
      );

      // حفظ سجل المسح في قاعدة البيانات
      await FirebaseFirestore.instance
          .collection('scans')
          .doc(scanId)
          .set(scan.toMap());

      // تحديث آخر فحص للمواطن
      await FirebaseFirestore.instance
          .collection('citizens')
          .doc(id)
          .update({
        'lastChecked': FieldValue.serverTimestamp(),
      });

      // الانتقال إلى شاشة النتائج
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ResultsScreen(citizen: citizen, scan: scan),
        ),
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'حدث خطأ: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('خدمات الموقع غير مفعلة');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('تم رفض إذن الموقع');
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      return Future.error('تم رفض إذن الموقع بشكل دائم');
    }

    return await Geolocator.getCurrentPosition();
  }

  void _manualSearch() {
    if (_idController.text.isNotEmpty) {
      _processId(_idController.text.trim());
    } else {
      setState(() {
        _errorMessage = 'يرجى إدخال رقم الهوية';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(
            Icons.qr_code_scanner,
            size: 100,
            color: Theme.of(context).primaryColor,
          ),
          SizedBox(height: 32),
          Text(
            'مسح باركود الهوية',
            style: Theme.of(context).textTheme.headline6,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _scanBarcode,
            icon: Icon(Icons.camera_alt),
            label: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text(
                'بدء المسح الضوئي',
                style: TextStyle(fontSize: 18),
              ),
            ),
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          SizedBox(height: 32),
          Text(
            'أو أدخل رقم الهوية يدوياً',
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),
          TextField(
            controller: _idController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'رقم الهوية',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              suffixIcon: IconButton(
                icon: Icon(Icons.search),
                onPressed: _isLoading ? null : _manualSearch,
              ),
            ),
          ),
          SizedBox(height: 16),
          if (_errorMessage.isNotEmpty)
            Text(
              _errorMessage,
              style: TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
          if (_isLoading)
            Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}

