import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'core/services/api_constants.dart';

class NetworkDebugScreen extends StatefulWidget {
  const NetworkDebugScreen({Key? key}) : super(key: key);

  @override
  State<NetworkDebugScreen> createState() => _NetworkDebugScreenState();
}

class _NetworkDebugScreenState extends State<NetworkDebugScreen> {
  String _result = "Appuyez sur le bouton pour tester";
  bool _isLoading = false;

  Future<void> _testConnection() async {
    setState(() {
      _isLoading = true;
      _result = "Test en cours...";
    });

    try {
      // Afficher l'URL du backend
      final baseUrl = ApiConstants.baseUrl;
      String testResult = "URL de base: $baseUrl\n\n";
      
      // Test de la connectivité internet
      try {
        final internetResult = await InternetAddress.lookup('google.com');
        if (internetResult.isNotEmpty && internetResult[0].rawAddress.isNotEmpty) {
          testResult += "✅ Connexion Internet: OK\n";
        } else {
          testResult += "❌ Connexion Internet: Erreur\n";
        }
      } catch (e) {
        testResult += "❌ Connexion Internet: Erreur ($e)\n";
      }
      
      // Test du serveur backend
      try {
        final response = await http.get(Uri.parse("$baseUrl"))
          .timeout(const Duration(seconds: 5));
        
        testResult += "✅ Serveur backend: ${response.statusCode} - ${response.body.substring(0, 50)}...\n";
      } catch (e) {
        testResult += "❌ Serveur backend: Erreur ($e)\n";
        
        // Tester d'autres adresses IP possibles
        try {
          testResult += "\nTest avec d'autres adresses IP:\n";
          
          final ips = [
            'http://192.168.0.128:8000',
            'http://192.168.1.9:8000', 
            'http://localhost:8000',
            'http://127.0.0.1:8000'
          ];
          
          for (final ip in ips) {
            try {
              final response = await http.get(Uri.parse(ip))
                .timeout(const Duration(seconds: 2));
              testResult += "✅ $ip: ${response.statusCode}\n";
            } catch (e) {
              testResult += "❌ $ip: Erreur\n";
            }
          }
        } catch (e) {
          testResult += "Erreur lors du test des autres IP: $e\n";
        }
      }
      
      setState(() {
        _result = testResult;
      });
    } catch (e) {
      setState(() {
        _result = "Erreur générale: $e";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test de Connectivité Réseau'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Cet outil teste la connexion au serveur backend',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _testConnection,
              child: _isLoading 
                ? const SizedBox(
                    width: 20, 
                    height: 20, 
                    child: CircularProgressIndicator(strokeWidth: 2)
                  )
                : const Text('Tester la connexion'),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _result,
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 