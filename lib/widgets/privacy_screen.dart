import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({Key? key}) : super(key: key);

  Future<String> _loadPrivacyText() async {
    try {
      return await rootBundle.loadString('assets/privacy.txt');
    } catch (e) {
      return 'Nepodarilo sa načítať zásady ochrany súkromia.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Súkromie'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: FutureBuilder<String>(
        future: _loadPrivacyText(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          
          if (snapshot.hasError) {
            return const Center(
              child: Text(
                'Nepodarilo sa načítať zásady ochrany súkromia.',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
            );
          }
          
          final privacyText = snapshot.data ?? 'Nepodarilo sa načítať zásady ochrany súkromia.';
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Text(
              privacyText,
              style: const TextStyle(
                fontSize: 16,
                height: 1.5,
              ),
            ),
          );
        },
      ),
    );
  }
} 