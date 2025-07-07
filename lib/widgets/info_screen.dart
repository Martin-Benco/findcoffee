import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class InfoScreen extends StatelessWidget {
  const InfoScreen({Key? key}) : super(key: key);

  Future<String> _loadInfoText() async {
    try {
      return await rootBundle.loadString('assets/info.txt');
    } catch (e) {
      return 'Nepodarilo sa načítať informácie.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Zistiť viac'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: FutureBuilder<String>(
        future: _loadInfoText(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          
          if (snapshot.hasError) {
            return const Center(
              child: Text(
                'Nepodarilo sa načítať informácie.',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
            );
          }
          
          final infoText = snapshot.data ?? 'Nepodarilo sa načítať informácie.';
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Text(
              infoText,
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