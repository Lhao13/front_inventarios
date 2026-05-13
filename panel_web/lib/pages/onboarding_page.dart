// Onboarding no se usa en el panel web - stub mínimo
import 'package:flutter/material.dart';

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});
  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('Onboarding - No disponible en panel web')));
  }
}

class OnboardingContent {
  final String title;
  final String description;
  final String image;
  OnboardingContent({required this.title, required this.description, required this.image});
}

