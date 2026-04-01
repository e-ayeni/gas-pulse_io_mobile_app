import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/liquid_cylinder.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(flex: 2),
              const LiquidCylinder(
                fillPercent: 65,
                width: 120,
                height: 180,
              ),
              const SizedBox(height: 32),
              const Text(
                'GasPulse',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryDark,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Smart LPG Cylinder Monitoring',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
              const Spacer(flex: 2),
              ElevatedButton.icon(
                onPressed: () => context.go('/home'),
                icon: const Icon(Icons.bluetooth),
                label: const Text('Get Started'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => context.push('/login'),
                icon: const Icon(Icons.cloud_outlined),
                label: const Text('Sign In for Cloud Features'),
              ),
              const SizedBox(height: 8),
              Text(
                'Sign in to access predictions, remote alerts,\nand multi-site management',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
