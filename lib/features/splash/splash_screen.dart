import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hulu_coffee_pos/core/config/theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _logoCtrl;
  late final AnimationController _textCtrl;
  late final AnimationController _barCtrl;

  late final Animation<double> _logoScale;
  late final Animation<double> _logoFade;
  late final Animation<double> _textFade;
  late final Animation<Offset> _textSlide;
  late final Animation<double> _badgeFade;
  late final Animation<double> _barProgress;

  @override
  void initState() {
    super.initState();

    _logoCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _textCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _barCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800));

    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _logoCtrl, curve: Curves.elasticOut));
    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _logoCtrl, curve: const Interval(0, 0.4)));

    _textFade = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _textCtrl, curve: Curves.easeOut));
    _textSlide =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
            CurvedAnimation(parent: _textCtrl, curve: Curves.easeOut));

    _badgeFade = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
            parent: _textCtrl,
            curve: const Interval(0.5, 1.0, curve: Curves.easeOut)));

    _barProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _barCtrl, curve: Curves.easeInOut));

    // Staggered start
    _logoCtrl.forward();
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _textCtrl.forward();
    });
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _barCtrl.forward();
    });

    // Navigate after animations
    Future.delayed(const Duration(milliseconds: 2400), () {
      if (mounted) context.goNamed('dashboard');
    });
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    _textCtrl.dispose();
    _barCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppTheme.surface, AppTheme.surfaceContainerLow],
              ),
            ),
          ),

          // Decorative circles
          Positioned(
            top: -80, left: -80,
            child: Container(
              width: 260, height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primary.withValues(alpha: 0.05),
              ),
            ),
          ),
          Positioned(
            bottom: -100, right: -100,
            child: Container(
              width: 300, height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryContainer.withValues(alpha: 0.08),
              ),
            ),
          ),

          // Main content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated Logo
                ScaleTransition(
                  scale: _logoScale,
                  child: FadeTransition(
                    opacity: _logoFade,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: AppTheme.primary.withValues(alpha: 0.15),
                            width: 2),
                      ),
                      child: Center(
                        child: Container(
                          width: 52,
                          height: 52,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [AppTheme.primary, AppTheme.primaryContainer],
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
                          child: const Icon(Icons.coffee_rounded,
                              color: Colors.white, size: 28),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Animated Text
                SlideTransition(
                  position: _textSlide,
                  child: FadeTransition(
                    opacity: _textFade,
                    child: Column(children: [
                      Text(
                        'Hulu',
                        style: Theme.of(context)
                            .textTheme
                            .displayLarge
                            ?.copyWith(letterSpacing: -1.5, height: 1),
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
                    ]),
                  ),
                ),
                const SizedBox(height: 20),

                // Animated Badge
                FadeTransition(
                  opacity: _badgeFade,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(
                          color: AppTheme.outlineVariant.withValues(alpha: 0.3)),
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        BoxShadow(
                            color: AppTheme.onSurface.withValues(alpha: 0.05),
                            blurRadius: 2)
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
                ),
                const SizedBox(height: 64),

                // Animated Loading Bar
                AnimatedBuilder(
                  animation: _barProgress,
                  builder: (_, __) => SizedBox(
                    width: 160,
                    height: 6,
                    child: Stack(children: [
                      Container(
                        decoration: BoxDecoration(
                            color: AppTheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(100)),
                      ),
                      FractionallySizedBox(
                        widthFactor: _barProgress.value,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                                colors: [AppTheme.primaryContainer, AppTheme.primary]),
                            borderRadius: BorderRadius.circular(100),
                            boxShadow: const [
                              BoxShadow(color: Color(0x44003466), blurRadius: 8)
                            ],
                          ),
                        ),
                      ),
                    ]),
                  ),
                ),
                const SizedBox(height: 14),

                // Loading text with sync icon
                FadeTransition(
                  opacity: _textFade,
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    AnimatedBuilder(
                      animation: _barCtrl,
                      builder: (_, child) => Transform.rotate(
                        angle: _barCtrl.value * 6.28,
                        child: child,
                      ),
                      child: Icon(Icons.sync,
                          size: 13,
                          color: AppTheme.onSurfaceVariant.withValues(alpha: 0.6)),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'LOADING',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppTheme.onSurfaceVariant.withValues(alpha: 0.6),
                            letterSpacing: 1.5,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ]),
                ),
              ],
            ),
          ),

          // Footer
          Positioned(
            bottom: 32, left: 0, right: 0,
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.lock, size: 11,
                  color: AppTheme.onSurfaceVariant.withValues(alpha: 0.35)),
              const SizedBox(width: 6),
              Text(
                'ENCRYPTED CONNECTION',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppTheme.onSurfaceVariant.withValues(alpha: 0.35),
                      letterSpacing: 1.0,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}
