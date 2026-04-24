import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:front_inventarios/services/local_db_service.dart';
import 'package:front_inventarios/pages/main_page.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingContent> _contents = [
    OnboardingContent(
      title: 'Activos Globales',
      description: 'Gestiona todo el inventario de la empresa desde un solo lugar, con visibilidad completa de cada equipo.',
      image: 'assets/onboarding/1activos.png',
    ),
    OnboardingContent(
      title: 'Categorización Inteligente',
      description: 'Dividimos los activos en 4 categorías específicas (PC, Comunicación, Genérico y Software) para un control técnico preciso.',
      image: 'assets/onboarding/2categorias.png',
    ),
    OnboardingContent(
      title: 'Identificación Rápida',
      description: 'Escanea códigos QR o series para consultar la información y el historial de cualquier activo al instante.',
      image: 'assets/onboarding/3scancode.png',
    ),
    OnboardingContent(
      title: 'Mantenimientos Eficientes',
      description: 'Programa y supervisa el estado de mantenimiento de los equipos para garantizar su operatividad constante.',
      image: 'assets/onboarding/4control.png',
    ),
  ];

  Future<void> _completeOnboarding() async {
    try {
      final db = await LocalDbService.instance.database;
      await db.insert(
        'cache_storage',
        {
          'collection': 'auth_config',
          'id': 'has_seen_onboarding',
          'json_data': 'true',
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      debugPrint('Error saving onboarding state: $e');
    }
    
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MainPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemCount: _contents.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.all(40.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Image.asset(
                        _contents[index].image,
                        fit: BoxFit.contain,
                        cacheWidth: 400, // Limita el tamaño en memoria RAM
                        errorBuilder: (context, error, stackTrace) {
                          debugPrint('Error cargando imagen: $error');
                          return const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.broken_image, size: 80, color: Colors.grey),
                              SizedBox(height: 16),
                              Text('Requiere reiniciar la app', style: TextStyle(color: Colors.grey)),
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 40),
                    Expanded(
                      flex: 2,
                      child: Column(
                        children: [
                          Text(
                            _contents[index].title,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1465bd),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            _contents[index].description,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          
          // Botón Saltar
          if (_currentPage < _contents.length - 1)
            Positioned(
              top: 50,
              right: 20,
              child: TextButton(
                onPressed: _completeOnboarding,
                child: const Text(
                  'SALTAR',
                  style: TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

          // Controles inferiores
          Positioned(
            bottom: 50,
            left: 40,
            right: 40,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Indicadores
                Row(
                  children: List.generate(
                    _contents.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: 8,
                      width: _currentPage == index ? 24 : 8,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: _currentPage == index 
                            ? const Color(0xFF1465bd) 
                            : Colors.grey.shade300,
                      ),
                    ),
                  ),
                ),
                
                // Botón Siguiente / Empezar
                ElevatedButton(
                  onPressed: () {
                    if (_currentPage == _contents.length - 1) {
                      _completeOnboarding();
                    } else {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.ease,
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1465bd),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    _currentPage == _contents.length - 1 ? 'EMPEZAR' : 'SIGUIENTE',
                    style: const TextStyle(fontWeight: FontWeight.bold),
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

class OnboardingContent {
  final String title;
  final String description;
  final String image;

  OnboardingContent({
    required this.title,
    required this.description,
    required this.image,
  });
}
