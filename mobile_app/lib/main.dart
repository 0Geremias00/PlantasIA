import 'dart:io';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_animate/flutter_animate.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PlantIA Doctor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        primaryColor: const Color(0xFF10B981),
        useMaterial3: true,
        textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF10B981),
          brightness: Brightness.dark,
          surface: const Color(0xFF1E293B),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

// ---------------------------------------------------------------------------
// SPLASH SCREEN (Pantalla de Carga Estilo Web)
// ---------------------------------------------------------------------------
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const HomeScreen(),
            transitionsBuilder: (_, a, __, c) =>
                FadeTransition(opacity: a, child: c),
            transitionDuration: const Duration(milliseconds: 800),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Stack(
        children: [
          // Fondo gradiente sutil
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.0,
                colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo animado
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF10B981).withOpacity(0.3),
                        blurRadius: 40,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: Image.asset('assets/logo.png', width: 120)
                      .animate(onPlay: (c) => c.repeat())
                      .shimmer(duration: 2000.ms, color: Colors.white24)
                      .animate()
                      .fadeIn(duration: 800.ms)
                      .scale(duration: 800.ms, curve: Curves.easeOutBack),
                ),
                const SizedBox(height: 30),

                // Título
                Text(
                  'PLANT DOCTOR',
                  style: GoogleFonts.cinzel(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    color: Colors.white,
                  ),
                ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2),

                Text(
                  'DISEASE DETECTION AI',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    letterSpacing: 4,
                    color: const Color(0xFF10B981),
                  ),
                ).animate().fadeIn(delay: 800.ms),

                const SizedBox(height: 50),

                // Barra de carga personalizada
                SizedBox(
                  width: 200,
                  height: 4,
                  child: const LinearProgressIndicator(
                    backgroundColor: Color(0xFF334155),
                    color: Color(0xFF10B981),
                  ),
                ).animate().fadeIn(delay: 1000.ms),

                const SizedBox(height: 15),
                const Text(
                  "INITIALIZING SYSTEMS...",
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 10,
                    letterSpacing: 1.5,
                  ),
                ).animate().fadeIn(delay: 1200.ms),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// HOME SCREEN (Diseño Premium Glassmorphism)
// ---------------------------------------------------------------------------
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  File? _image;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  Map<String, dynamic>? _result;
  final TextEditingController _urlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSavedUrl();
  }

  // Persistencia de URL
  Future<void> _loadSavedUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUrl = prefs.getString('server_url') ?? '';
    setState(() {
      _urlController.text = savedUrl;
    });
  }

  Future<void> _saveUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('server_url', url);
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          _image = File(pickedFile.path);
          _result = null;
        });
      }
    } catch (e) {
      _showSnack('Error al seleccionar imagen: $e', isError: true);
    }
  }

  Future<void> _analyzeImage() async {
    if (_image == null) return;

    String inputUrl = _urlController.text.trim();
    if (inputUrl.isEmpty) {
      _showSnack('⚠️ Configura la URL del servidor primero.', isError: true);
      return;
    }

    _saveUrl(inputUrl); // Guardar automáticamente

    // Normalizar URL
    String finalUrl = inputUrl;
    if (!finalUrl.startsWith('http'))
      finalUrl = 'http://$finalUrl'; // Asumir http si falta
    if (finalUrl.endsWith('/'))
      finalUrl = finalUrl.substring(0, finalUrl.length - 1);
    if (!finalUrl.endsWith('/predict')) finalUrl = '$finalUrl/predict';
    // Si usas el túnel localhost.run, a veces es HTTPS, pero el usuario puede poner la base.

    setState(() => _isLoading = true);

    try {
      final uri = Uri.parse(finalUrl);
      final request = http.MultipartRequest('POST', uri);
      request.files.add(
        await http.MultipartFile.fromPath('image', _image!.path),
      );

      // Timeout para no dejar esperando eternamente
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 15),
      );
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() => _result = data);
      } else {
        _showSnack(
          'Error del servidor (${response.statusCode})',
          isError: true,
        );
      }
    } catch (e) {
      _showSnack('No se pudo conectar. Verifica la URL.\n$e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.redAccent : const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _reset() {
    setState(() {
      _image = null;
      _result = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.spa_rounded, color: Color(0xFF10B981)),
            const SizedBox(width: 10),
            Text(
              'PlantIA',
              style: GoogleFonts.cinzel(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white54),
            onPressed: () => _showSettingsDialog(context),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          ),
        ),
        child: Stack(
          children: [
            // Blob decorativo (círculo de fondo)
            Positioned(
              top: -100,
              right: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF10B981).withOpacity(0.2),
                      blurRadius: 100,
                      spreadRadius: 20,
                    ),
                  ],
                ),
              ),
            ),

            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    // Tarjeta Principal (Imagen)
                    Expanded(
                      flex: 6,
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.1),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              if (_image != null)
                                Image.file(_image!, fit: BoxFit.cover)
                              else
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                          Icons.add_a_photo_outlined,
                                          size: 64,
                                          color: Colors.white.withOpacity(0.2),
                                        )
                                        .animate(
                                          onPlay: (c) =>
                                              c.repeat(reverse: true),
                                        )
                                        .scale(
                                          begin: const Offset(1, 1),
                                          end: const Offset(1.1, 1.1),
                                          duration: 2000.ms,
                                        ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Toca abajo para comenzar',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.4),
                                      ),
                                    ),
                                  ],
                                ),

                              // Overlay de scanner
                              if (_isLoading)
                                Container(
                                  color: Colors.black54,
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      color: Color(0xFF10B981),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Panel de Resultados (Si existe resultado)
                    if (_result != null && !_isLoading)
                      _buildResultPanel().animate().fadeIn().slideY(begin: 0.3),

                    // Botones de acción (Si NO hay resultado)
                    if (_result == null && !_isLoading) ...[
                      if (_image == null)
                        Row(
                          children: [
                            Expanded(
                              child: _buildGlassButton(
                                icon: Icons.camera_alt_outlined,
                                label: "Cámara",
                                onTap: () => _pickImage(ImageSource.camera),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildGlassButton(
                                icon: Icons.photo_library_outlined,
                                label: "Galería",
                                onTap: () => _pickImage(ImageSource.gallery),
                              ),
                            ),
                          ],
                        )
                      else
                        SizedBox(
                          width: double.infinity,
                          child:
                              ElevatedButton.icon(
                                onPressed: _analyzeImage,
                                icon: const Icon(Icons.analytics_rounded),
                                label: const Text(
                                  "ANALIZAR AHORA",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF10B981),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 18,
                                  ),
                                  elevation: 10,
                                  shadowColor: const Color(
                                    0xFF10B981,
                                  ).withOpacity(0.5),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              ).animate().shimmer(
                                duration: 1500.ms,
                                color: Colors.white24,
                              ),
                        ),

                      if (_image != null)
                        TextButton.icon(
                          onPressed: _reset,
                          icon: const Icon(
                            Icons.refresh,
                            color: Colors.white54,
                            size: 18,
                          ),
                          label: const Text(
                            "Cambiar foto",
                            style: TextStyle(color: Colors.white54),
                          ),
                        ).animate().fadeIn(),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          height: 120, // Botones grandes
          decoration: BoxDecoration(
            color: const Color(0xFF334155).withOpacity(0.5),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: const Color(0xFF10B981), size: 32),
              const SizedBox(height: 12),
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultPanel() {
    final label = _result!['label'] ?? 'Desconocido';
    final confidence = _result!['confidence'] ?? '0%';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF10B981), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withOpacity(0.2),
            blurRadius: 20,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, color: Color(0xFF10B981)),
              const SizedBox(width: 8),
              Text(
                "Análisis Completado",
                style: TextStyle(
                  color: const Color(0xFF10B981).withOpacity(0.8),
                  fontSize: 12,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            "Confianza: $confidence",
            style: const TextStyle(color: Colors.white54),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _reset,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.white24),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text(
                "Nueva Consulta",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text(
          "Configuración de Conexión",
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Ingresa la URL pública generada por 'tunnel.py' o la IP local de tu PC.",
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _urlController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.black26,
                hintText: "ej: https://...lhr.life",
                hintStyle: const TextStyle(color: Colors.white24),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                prefixIcon: const Icon(Icons.link, color: Color(0xFF10B981)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              "Cancelar",
              style: TextStyle(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _saveUrl(_urlController.text.trim());
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text("URL Guardada ✅")));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
            ),
            child: const Text("Guardar", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
