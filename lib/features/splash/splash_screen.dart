import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _cardFade;
  late Animation<Offset> _cardSlide;
  late Animation<double> _cardScale;

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _cardFade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);

    _cardSlide = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _cardScale = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _controller.forward();

    Timer(const Duration(milliseconds: 3000), () {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
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
      backgroundColor: const Color(0xFFF0F7F0),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: FadeTransition(
            opacity: _cardFade,
            child: SlideTransition(
              position: _cardSlide,
              child: ScaleTransition(
                scale: _cardScale,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4CAF50).withValues(alpha: 0.18),
                        blurRadius: 40,
                        spreadRadius: 2,
                        offset: const Offset(0, 12),
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.07),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // ── Green image section ──────────────────────
                        Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFF81C784),
                                Color(0xFF4CAF50),
                                Color(0xFF2E7D32),
                              ],
                            ),
                          ),
                          padding:
                              const EdgeInsets.fromLTRB(20, 32, 20, 0),
                          child: Column(
                            children: [
                              // Tagline inside card
                              const Text(
                                "Let's Enter New Era of",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                  fontFamily: 'Inter',
                                  letterSpacing: 0.4,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'POULTRY FARMING',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  fontFamily: 'Inter',
                                  letterSpacing: 2.5,
                                ),
                              ),
                              const SizedBox(height: 16),
                              // Farmer image
                              Image.asset(
                                'assets/images/splash_farmer.png',
                                height: 280,
                                fit: BoxFit.contain,
                              ),
                            ],
                          ),
                        ),

                        // ── White bottom section ─────────────────────
                        Container(
                          color: Colors.white,
                          padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // App logo + name row
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 52,
                                    height: 52,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFF81C784),
                                          Color(0xFF2E7D32),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius:
                                          BorderRadius.circular(16),
                                    ),
                                    child: const Center(
                                      child: Text(
                                        '🥚',
                                        style: TextStyle(fontSize: 28),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  const Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'GoldenYolk',
                                        style: TextStyle(
                                          fontSize: 26,
                                          fontWeight: FontWeight.w900,
                                          color: Color(0xFF2E7D32),
                                          fontFamily: 'Inter',
                                          letterSpacing: -0.5,
                                        ),
                                      ),
                                      Text(
                                        'Poultry Farm Manager',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                          fontFamily: 'Inter',
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              // Progress bar
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: const LinearProgressIndicator(
                                  backgroundColor: Color(0xFFE8F5E9),
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(
                                          Color(0xFF4CAF50)),
                                  minHeight: 5,
                                ),
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                'Loading your farm...',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                  fontFamily: 'Inter',
                                ),
                              ),
                            ],
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
      ),
    );
  }
}
