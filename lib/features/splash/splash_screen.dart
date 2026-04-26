import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hulu_coffee_pos/core/config/theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Simulate loading/syncing
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        // Normally we'd check auth state here, for now redirect to Login
        context.goNamed('login');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: Stack(
        children: [
          // Background Gradient to replicate subtle styling from HTML
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppTheme.surface,
                  AppTheme.surfaceContainerLow,
                ],
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo placeholder
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.primary.withOpacity(0.1),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppTheme.primary,
                            AppTheme.primaryContainer,
                          ],
                        ),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(48),
                          bottomRight: Radius.circular(48),
                          topRight: Radius.circular(8),
                          bottomLeft: Radius.circular(8),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x33003466),
                            blurRadius: 32,
                            offset: Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Transform.rotate(
                        angle: -45 * 3.1415926535 / 180,
                        child: Center(
                          child: Transform.rotate(
                            angle: 45 * 3.1415926535 / 180,
                            child: Container(
                              width: 2,
                              height: 24,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.4),
                                borderRadius: BorderRadius.circular(100),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Hulu',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        letterSpacing: -1.5,
                        height: 1,
                      ),
                ),
                Text(
                  'COFFEE',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppTheme.primaryContainer,
                        letterSpacing: 2.0,
                        fontWeight: FontWeight.bold,
                        height: 1,
                      ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: AppTheme.outlineVariant.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.onSurface.withOpacity(0.05),
                        blurRadius: 2,
                      )
                    ],
                  ),
                  child: Text(
                    'POINT OF SALE',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppTheme.onSurfaceVariant,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                const SizedBox(height: 64),
                SizedBox(
                  width: 160,
                  height: 6,
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(100),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: 0.4,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                AppTheme.primaryContainer,
                                AppTheme.primary,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(100),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x66003466),
                                blurRadius: 8,
                              )
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.sync,
                      size: 14,
                      color: AppTheme.onSurfaceVariant.withOpacity(0.7),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'SYNCING WORKSPACE',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppTheme.onSurfaceVariant.withOpacity(0.7),
                            letterSpacing: 1.5,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 32,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.lock,
                  size: 12,
                  color: AppTheme.onSurfaceVariant.withOpacity(0.4),
                ),
                const SizedBox(width: 6),
                Text(
                  'ENCRYPTED CONNECTION',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppTheme.onSurfaceVariant.withOpacity(0.4),
                        letterSpacing: 1.0,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
