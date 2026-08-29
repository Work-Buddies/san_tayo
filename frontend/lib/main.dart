import 'package:flutter/material.dart';

import 'core/config/api_endpoints.dart';
import 'core/network/api_client.dart';

void main() {
  runApp(const SanTayoApp());
}

class SanTayoApp extends StatelessWidget {
  const SanTayoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Sa'n Tayo",
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String status_text = 'Tap the button to check API connection.';
  bool is_loading = false;

  Future<void> check_health() async {
    setState(() {
      is_loading   = true;
      status_text  = 'Checking API...';
    });

    final res = await api_request('GET', ApiEndpoints.health);

    if (!mounted) {
      return;
    }

    setState(() {
      is_loading = false;

      if (res.code == 1 && res.data != null) {
        final app_name = res.data['app']?.toString() ?? "Sa'n Tayo";
        final status   = res.data['status']?.toString() ?? 'unknown';
        status_text    = '$app_name API is $status';
      } else {
        status_text = res.msg;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sa'n Tayo"),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                status_text,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: is_loading ? null : check_health,
                child: is_loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Check API Health'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
