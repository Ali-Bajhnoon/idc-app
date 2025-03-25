import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Firebase Test',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: FirebaseTestPage(),
    );
  }
}

class FirebaseTestPage extends StatefulWidget {
  @override
  _FirebaseTestPageState createState() => _FirebaseTestPageState();
}

class _FirebaseTestPageState extends State<FirebaseTestPage> {
  String _status = 'اضغط على الزر لاختبار الاتصال بـ Firebase';

  Future<void> testFirestore() async {
    try {
      setState(() {
        _status = 'جاري الاتصال بـ Firestore...';
      });
      
      final collection = FirebaseFirestore.instance.collection('test');
      await collection.add({
        'message': 'Hello Firebase!',
        'timestamp': FieldValue.serverTimestamp(),
      });
      
      setState(() {
        _status = 'تم الاتصال بـ Firestore بنجاح! ✅';
      });
    } catch (e) {
      setState(() {
        _status = 'خطأ في الاتصال بـ Firestore: $e ❌';
      });
      print('خطأ في الاتصال بـ Firestore: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('اختبار Firebase'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                _status,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            ),
            ElevatedButton(
              onPressed: testFirestore,
              child: Text('اختبار الاتصال بـ Firestore'),
            ),
          ],
        ),
      ),
    );
  }
}
