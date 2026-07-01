import 'package:flutter/material.dart';

import '../config/api_config.dart';
import '../models/customer_session.dart';
import '../services/api_client.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    required this.apiClient,
    required this.onLoggedIn,
    super.key,
  });

  final ApiClient apiClient;
  final ValueChanged<CustomerSession> onLoggedIn;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController otpController = TextEditingController();
  final TextEditingController serverController = TextEditingController(text: ApiConfig.baseUrl);
  String? devOtp;
  bool otpRequested = false;
  bool isSubmitting = false;
  bool isTestingConnection = false;

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    otpController.dispose();
    serverController.dispose();
    super.dispose();
  }

  Future<bool> saveServerUrl() async {
    final value = serverController.text.trim();

    if (!value.startsWith('http://') && !value.startsWith('https://')) {
      showMessage('Server must start with http:// or https://');
      return false;
    }

    await ApiConfig.saveBaseUrl(value);

    if (mounted) {
      setState(() {});
      showMessage('Server URL saved.');
    }

    return true;
  }

  Future<void> testConnection() async {
    final saved = await saveServerUrl();

    if (!saved) {
      return;
    }

    setState(() => isTestingConnection = true);

    try {
      await widget.apiClient.testConnection();
      showMessage('Connection OK.');
    } catch (error) {
      showMessage(error.toString());
    } finally {
      if (mounted) {
        setState(() => isTestingConnection = false);
      }
    }
  }

  Future<void> requestOtp() async {
    if (phoneController.text.trim().isEmpty) {
      showMessage('Phone is required.');
      return;
    }

    setState(() => isSubmitting = true);

    try {
      final otp = await widget.apiClient.requestOtp(
        name: nameController.text.trim(),
        phone: phoneController.text.trim(),
      );
      setState(() {
        devOtp = otp;
        otpRequested = true;
        otpController.text = otp;
      });
      showMessage('OTP generated for demo.');
    } catch (error) {
      showMessage(error.toString());
    } finally {
      if (mounted) {
        setState(() => isSubmitting = false);
      }
    }
  }

  Future<void> verifyOtp() async {
    setState(() => isSubmitting = true);

    try {
      final session = await widget.apiClient.verifyOtp(
        phone: phoneController.text.trim(),
        otpCode: otpController.text.trim(),
      );
      widget.onLoggedIn(session);
    } catch (error) {
      showMessage(error.toString());
    } finally {
      if (mounted) {
        setState(() => isSubmitting = false);
      }
    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Customer Login')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Login by phone OTP',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          const Text('Demo mode returns OTP in the API response until SMS provider is connected.'),
          const SizedBox(height: 8),
          Text(
            'Server: ${ApiConfig.baseUrl}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const Text(
            'Build: 0.1.4+5',
            style: TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 12),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: const Text('Connection settings'),
            children: [
              TextField(
                controller: serverController,
                decoration: const InputDecoration(
                  labelText: 'Server URL',
                  helperText: 'Example: http://192.168.1.47:8000',
                ),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  OutlinedButton(
                    onPressed: isSubmitting ? null : () => saveServerUrl(),
                    child: const Text('Save Server'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: isSubmitting || isTestingConnection ? null : testConnection,
                    child: Text(isTestingConnection ? 'Testing...' : 'Test Connection'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          TextField(
            controller: nameController,
            decoration: const InputDecoration(labelText: 'Name'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: phoneController,
            decoration: const InputDecoration(labelText: 'Phone'),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: isSubmitting ? null : requestOtp,
            child: Text(isSubmitting ? 'Please wait...' : 'Request OTP'),
          ),
          if (otpRequested) ...[
            const SizedBox(height: 24),
            TextField(
              controller: otpController,
              decoration: const InputDecoration(labelText: 'OTP Code'),
              keyboardType: TextInputType.number,
            ),
            if (devOtp != null) ...[
              const SizedBox(height: 8),
              Text('Demo OTP: $devOtp'),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: isSubmitting ? null : verifyOtp,
              child: const Text('Verify and Continue'),
            ),
          ],
        ],
      ),
    );
  }
}
