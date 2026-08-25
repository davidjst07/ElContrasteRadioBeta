import 'package:flutter/material.dart';

import 'package:elcontrasteapp/presentation/pages/home/home_page.dart';

class SplashScreen extends StatefulWidget {
  /// Se llama justo después de reemplazar el splash por HomePage.
  /// Usado por main.dart para coordinar deep links/notificaciones que
  /// podrían estar esperando a que el splash termine (ver _splashDone).
  final VoidCallback? onNavigatedToHome;

  const SplashScreen({super.key, this.onNavigatedToHome});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const _animationDuration = Duration(milliseconds: 800);
  static const _holdDuration = Duration(milliseconds: 700);

  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: _animationDuration,
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _scale = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    _controller.forward();
    _navigateToHomeAfterDelay();
  }

  Future<void> _navigateToHomeAfterDelay() async {
    await Future.delayed(_animationDuration + _holdDuration);
    if (!mounted) return;
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const HomePage()));
    widget.onNavigatedToHome?.call();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: FadeTransition(
          opacity: _fade,
          child: ScaleTransition(
            scale: _scale,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset('assets/icon/jyd3.png', width: 220),
                const SizedBox(height: 12),
                Text(
                  'jyd-producciones.com',
                  style: TextStyle(
                    color: Colors.black.withValues(alpha: 0.6),
                    fontSize: 14,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
