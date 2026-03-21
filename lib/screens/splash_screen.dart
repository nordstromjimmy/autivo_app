import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/premium/utils/premium_features.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Sync premium status in background
    _syncPremiumStatus();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _controller.forward();

    // Navigate to home after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    });
  }

  Future<void> _syncPremiumStatus() async {
    try {
      // Wait a bit for RevenueCat to initialize
      await Future.delayed(const Duration(seconds: 2));

      final premiumFeatures = ref.read(premiumFeaturesProvider);
      await premiumFeatures.syncPremiumToSupabase();
    } catch (e) {
      print('Failed to sync premium on startup: $e');
      // Don't block app startup if sync fails
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get screen size for responsive sizing
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.height < 600;
    final isTablet = size.shortestSide >= 600;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF0e8afd), // Blue
              const Color(0xFF00a3e8), // Darker blue
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        // Add SafeArea to avoid notch/status bar issues
        child: SafeArea(
          child: Center(
            // Wrap in SingleChildScrollView as safety net
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min, // Important!
                    children: [
                      // Responsive logo size
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: isTablet ? 300 : 200,
                          maxHeight: isTablet ? 300 : 200,
                        ),
                        child: Image.asset(
                          'assets/images/logo2.png',
                          fit: BoxFit.contain,
                        ),
                      ),

                      SizedBox(height: isSmallScreen ? 16 : 24),

                      // Responsive title size
                      Text(
                        'AUTIVO',
                        style: TextStyle(
                          fontSize: isTablet ? 80 : (isSmallScreen ? 48 : 64),
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: isTablet ? 12 : 8,
                        ),
                      ),

                      SizedBox(height: isSmallScreen ? 8 : 16),

                      // Responsive subtitle size
                      Text(
                        'Din bils digitala historia',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: isTablet ? 24 : (isSmallScreen ? 14 : 18),
                          color: Colors.white.withValues(alpha: 0.9),
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
