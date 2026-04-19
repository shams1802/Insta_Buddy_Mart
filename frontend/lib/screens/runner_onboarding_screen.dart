import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/auth_provider.dart';

class RunnerOnboardingScreen extends StatefulWidget {
  const RunnerOnboardingScreen({super.key});

  @override
  State<RunnerOnboardingScreen> createState() => _RunnerOnboardingScreenState();
}

class _RunnerOnboardingScreenState extends State<RunnerOnboardingScreen> {
  int _step = 0;
  final _phone = TextEditingController();
  final _email = TextEditingController();
  bool _idUploaded = false;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    _phone.text = auth.userPhone;
    _email.text = auth.userEmail;
  }

  @override
  void dispose() {
    _phone.dispose();
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final kyc = auth.kycCompleted;
    final runner = auth.isRunner;

    return Scaffold(
      appBar: AppBar(title: const Text('Become a Runner')),
      body: Stepper(
        currentStep: _step,
        onStepContinue: () {
          if (_step < 2) {
            setState(() => _step++);
          } else {
            final auth = context.read<AuthProvider>();
            auth.setUserProfile({...?auth.userProfile, 'isRunner': true, 'kycCompleted': true});
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('KYC marked complete (demo). Welcome, Runner!'), backgroundColor: AppTheme.successColor),
            );
            Navigator.pop(context);
          }
        },
        onStepCancel: () {
          if (_step > 0) {
            setState(() => _step--);
          } else {
            Navigator.pop(context);
          }
        },
        controlsBuilder: (context, details) {
          return Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Row(
              children: [
                FilledButton(onPressed: details.onStepContinue, child: Text(_step < 2 ? 'Continue' : 'Finish')),
                const SizedBox(width: 12),
                if (_step > 0) OutlinedButton(onPressed: details.onStepCancel, child: const Text('Back')),
              ],
            ),
          );
        },
        steps: [
          Step(
            title: const Text('Phone verification'),
            subtitle: Text(runner ? 'Verified (demo)' : 'We will send an OTP in production'),
            content: TextField(
              controller: _phone,
              enabled: false,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Phone number', hintText: '+91 …'),
            ),
            isActive: _step >= 0,
          ),
          Step(
            title: const Text('Email verification'),
            content: TextField(
              controller: _email,
              enabled: false,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email', hintText: 'runner@example.com'),
            ),
            isActive: _step >= 1,
          ),
          Step(
            title: const Text('Upload ID proof'),
            subtitle: const Text('Aadhaar / Driving licence (demo: tap upload)'),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                OutlinedButton.icon(
                  onPressed: () => setState(() => _idUploaded = true),
                  icon: const Icon(Icons.upload_file),
                  label: Text(_idUploaded ? 'Document attached (demo)' : 'Choose file'),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Chip(
                      label: Text(kyc ? 'KYC: Completed' : 'KYC: Pending'),
                      backgroundColor: kyc ? AppTheme.successColor.withValues(alpha: 0.2) : AppTheme.warningColor.withValues(alpha: 0.2),
                    ),
                    const SizedBox(width: 8),
                    Chip(label: Text(runner ? 'Runner' : 'Requester')),
                  ],
                ),
              ],
            ),
            isActive: _step >= 2,
          ),
        ],
      ),
    );
  }
}
