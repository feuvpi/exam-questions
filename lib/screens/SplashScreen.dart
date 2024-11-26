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
                                    <svg viewBox="0 0 240 240" xmlns="http://www.w3.org/2000/svg">
                                      <circle cx="120" cy="120" r="120" fill="#232F3E"/>
                                      <path d="M60 140 C60 100, 120 90, 150 100 C180 85, 220 100, 220 130 C220 160, 180 170, 150 160 C120 180, 60 170, 60 140" fill="#FF9900" opacity="0.9"/>
                                      <circle cx="95" cy="125" r="8" fill="white"/>
                                      <circle cx="120" cy="125" r="8" fill="white"/>
                                      <circle cx="145" cy="125" r="8" fill="white"/>
                                      <line x1="95" y1="125" x2="120" y2="125" stroke="white" stroke-width="3"/>
                                      <line x1="120" y1="125" x2="145" y2="125" stroke="white" stroke-width="3"/>
                                      <path d="M115 160 L130 175 L160 145" fill="none" stroke="white" stroke-width="8" stroke-linecap="round" stroke-linejoin="round"/>
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