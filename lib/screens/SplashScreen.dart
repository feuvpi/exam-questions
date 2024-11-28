import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'menu_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 2000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0.0, 0.5, curve: Curves.easeOutBack),
      ),
    );

    _controller.forward();

    // Navigate to MenuScreen after animation
    Future.delayed(Duration(milliseconds: 2500), () {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => MenuScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = 0.0;
            const end = 1.0;
            var fade = Tween(begin: begin, end: end)
                .animate(CurvedAnimation(parent: animation, curve: Curves.easeOut));
            return FadeTransition(opacity: fade, child: child);
          },
          transitionDuration: Duration(milliseconds: 500),
        ),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF232F3E),
              Color(0xFF1A222E),
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Decorative elements
              Positioned(
                top: -100,
                right: -100,
                child: Transform.rotate(
                  angle: -0.2,
                  child: Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      color: Color(0xFFFF9900).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(150),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: -150,
                left: -150,
                child: Container(
                  width: 400,
                  height: 400,
                  decoration: BoxDecoration(
                    color: Color(0xFFFF9900).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(200),
                  ),
                ),
              ),
              // Main content
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _scaleAnimation.value,
                          child: FadeTransition(
                            opacity: _fadeAnimation,
                            child: Column(
                              children: [
                                // Logo
                                Container(
                                  width: 180,
                                  height: 180,
                                  child: SvgPicture.string(
                                    '''<?xml version="1.0" encoding="UTF-8"?>
                                    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 200 200">
  <!-- Cloud shape -->
  <path d="M140 100c0-22-18-40-40-40-18 0-33 12-38 28-2-1-4-1-6-1-11 0-20 9-20 20s9 20 20 20h84c11 0 20-9 20-20s-9-20-20-20c0 4 0 8 0 13z" 
        fill="#37475A" /> <!-- Lighter AWS blue -->
  
  <!-- Form icon - even larger -->
  <rect x="50" y="65" width="55" height="62" fill="#FF9900" rx="5" />
  <rect x="62" y="77" width="31" height="5" fill="white" />
  <rect x="62" y="89" width="31" height="5" fill="white" />
  <rect x="62" y="101" width="31" height="5" fill="white" />
</svg>''',
                                  ),
                                ),
                                SizedBox(height: 24),
                                // App name
                                Text(
                                  'AWS Certification',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Prep Quiz',
                                  style: TextStyle(
                                    color: Color(0xFFFF9900),
                                    fontSize: 24,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}