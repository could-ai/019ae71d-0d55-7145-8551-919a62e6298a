import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calculadora Avícola',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.grey.shade100,
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const ChickenCalculatorScreen(),
      },
    );
  }
}

class ChickenCalculatorScreen extends StatefulWidget {
  const ChickenCalculatorScreen({super.key});

  @override
  State<ChickenCalculatorScreen> createState() => _ChickenCalculatorScreenState();
}

class _ChickenCalculatorScreenState extends State<ChickenCalculatorScreen> {
  // Controladores para los campos de texto
  final TextEditingController _loadedWeightController = TextEditingController();
  final TextEditingController _emptyWeightController = TextEditingController();
  final TextEditingController _chickenCountController = TextEditingController();

  // Variables para el cálculo
  double? _netWeightTotal;
  double? _averageWeightPerChicken;

  // Variables para reconocimiento de voz
  late stt.SpeechToText _speech;
  bool _isListening = false;
  bool _speechAvailable = false;
  String _currentLocaleId = '';

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _initSpeech();
  }

  // Inicializar el servicio de voz
  void _initSpeech() async {
    try {
      bool available = await _speech.initialize(
        onStatus: (status) => debugPrint('Speech Status: $status'),
        onError: (errorNotification) => debugPrint('Speech Error: $errorNotification'),
      );
      if (mounted) {
        setState(() {
          _speechAvailable = available;
        });
        // Intentar obtener locales en español si es posible, sino usa el del sistema
        var locales = await _speech.locales();
        var systemLocale = await _speech.systemLocale();
        _currentLocaleId = systemLocale?.localeId ?? '';
        
        // Buscar español preferentemente
        for(var locale in locales) {
            if(locale.localeId.toLowerCase().contains('es')) {
                _currentLocaleId = locale.localeId;
                break;
            }
        }
      }
    } catch (e) {
      debugPrint("Error inicializando voz: $e");
    }
  }

  // Función para escuchar y escribir en un controlador específico
  void _listenToField(TextEditingController controller) async {
    if (!_speechAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El reconocimiento de voz no está disponible o permisos denegados.')),
      );
      return;
    }

    if (_isListening) {
      _speech.stop();
      setState(() => _isListening = false);
    } else {
      setState(() => _isListening = true);
      _speech.listen(
        localeId: _currentLocaleId,
        onResult: (result) {
          setState(() {
            // Intentamos limpiar el texto para obtener solo números
            String text = result.recognizedWords;
            // Reemplazar comas por puntos para decimales si es necesario
            text = text.replaceAll(',', '.');
            // Extraer solo números y puntos
            String numbersOnly = text.replaceAll(RegExp(r'[^0-9.]'), '');
            
            controller.text = numbersOnly;
            
            if (result.finalResult) {
              _isListening = false;
              _calculate(); // Recalcular automáticamente al terminar de hablar
            }
          });
        },
      );
    }
  }

  void _calculate() {
    // Obtener valores, si están vacíos usar 0
    double loaded = double.tryParse(_loadedWeightController.text) ?? 0;
    double empty = double.tryParse(_emptyWeightController.text) ?? 0;
    int count = int.tryParse(_chickenCountController.text) ?? 0;

    setState(() {
      if (loaded > 0 && empty >= 0 && count > 0) {
        _netWeightTotal = loaded - empty;
        _averageWeightPerChicken = _netWeightTotal! / count;
      } else {
        _netWeightTotal = null;
        _averageWeightPerChicken = null;
      }
    });
  }

  void _clearAll() {
    _loadedWeightController.clear();
    _emptyWeightController.clear();
    _chickenCountController.clear();
    setState(() {
      _netWeightTotal = null;
      _averageWeightPerChicken = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calculadora de Peso Avícola', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _clearAll,
            tooltip: 'Limpiar todo',
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Ingrese los datos del camión',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal),
            ),
            const SizedBox(height: 20),
            
            // Campo: Peso Cargado
            _buildInputCard(
              label: 'Peso Cargado (kg)',
              icon: FontAwesomeIcons.truckMoving,
              controller: _loadedWeightController,
              color: Colors.blue.shade100,
            ),
            
            const SizedBox(height: 15),

            // Campo: Peso Vacío
            _buildInputCard(
              label: 'Peso Vacío / Tara (kg)',
              icon: FontAwesomeIcons.truck,
              controller: _emptyWeightController,
              color: Colors.orange.shade100,
            ),

            const SizedBox(height: 15),

            // Campo: Cantidad de Pollos
            _buildInputCard(
              label: 'Cantidad de Pollos',
              icon: FontAwesomeIcons.kiwiBird,
              controller: _chickenCountController,
              isInteger: true,
              color: Colors.green.shade100,
            ),

            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: _calculate,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              child: const Text('CALCULAR'),
            ),

            const SizedBox(height: 30),

            // Resultados
            if (_netWeightTotal != null && _averageWeightPerChicken != null) ...[
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                color: Colors.teal.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      _buildResultRow('Peso Neto Total:', '${_netWeightTotal!.toStringAsFixed(2)} kg'),
                      const Divider(),
                      const SizedBox(height: 10),
                      const Text('Peso Promedio por Pollo', style: TextStyle(fontSize: 16, color: Colors.grey)),
                      const SizedBox(height: 5),
                      Text(
                        '${_averageWeightPerChicken!.toStringAsFixed(3)} kg',
                        style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.teal),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      floatingActionButton: _isListening 
        ? FloatingActionButton(
            onPressed: () {
              _speech.stop();
              setState(() => _isListening = false);
            },
            backgroundColor: Colors.red,
            child: const Icon(Icons.mic_off),
          ) 
        : null,
    );
  }

  Widget _buildInputCard({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    required Color color,
    bool isInteger = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 5, offset: const Offset(0, 3)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 80,
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(15), bottomLeft: Radius.circular(15)),
            ),
            child: Icon(icon, color: Colors.black54, size: 28),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15.0),
              child: TextField(
                controller: controller,
                keyboardType: TextInputType.numberWithOptions(decimal: !isInteger),
                onChanged: (_) => _calculate(), // Cálculo en tiempo real opcional
                decoration: InputDecoration(
                  labelText: label,
                  border: InputBorder.none,
                  fillColor: Colors.transparent,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),
          IconButton(
            icon: Icon(_isListening ? Icons.mic_none : Icons.mic, color: Colors.teal),
            onPressed: () => _listenToField(controller),
            tooltip: 'Dictar valor',
          ),
        ],
      ),
    );
  }

  Widget _buildResultRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
