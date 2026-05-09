import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/models/fare_config.dart';
import '../../data/repositories/fare_repository.dart';

class FareSettingsScreen extends StatefulWidget {
  const FareSettingsScreen({super.key});

  @override
  State<FareSettingsScreen> createState() => _FareSettingsScreenState();
}

class _FareSettingsScreenState extends State<FareSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repo = FareRepository();
  late FareConfig _config;

  final _baseController = TextEditingController();
  final _kmController = TextEditingController();
  final _minController = TextEditingController();
  final _minFareController = TextEditingController();
  final _roundController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    _config = await _repo.getConfig();
    setState(() {
      _baseController.text = _config.baseFare.toString();
      _kmController.text = _config.pricePerKm.toString();
      _minController.text = _config.pricePerMinute.toString();
      _minFareController.text = _config.minimumFare.toString();
      _roundController.text = _config.roundTo.toString();
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final newConfig = FareConfig(
      baseFare: double.parse(_baseController.text),
      pricePerKm: double.parse(_kmController.text),
      pricePerMinute: double.parse(_minController.text),
      minimumFare: double.parse(_minFareController.text),
      roundTo: double.parse(_roundController.text),
    );

    await _repo.saveConfig(newConfig);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tarifas guardadas')),
      );
      Navigator.pop(context, newConfig);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Configurar Tarifas'),
        backgroundColor: Colors.grey[900],
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildField('Tarifa Base (\$)', _baseController, '15.00'),
              _buildField('Precio por Km (\$)', _kmController, '8.00'),
              _buildField('Precio por Minuto (\$)', _minController, '1.50'),
              _buildField('Tarifa Mínima (\$)', _minFareController, '20.00'),

              // CAMBIO: Campo de redondeo con explicación
              _buildField(
                'Redondeo (\$)',
                _roundController,
                '1.0',
                helper: '1.0 = pesos enteros, 10.0 = decenas, 0 = sin redondeo',
              ),

              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.yellow[700],
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'GUARDAR TARIFAS',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller,
    String hint, {
    String? helper,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        style: const TextStyle(color: Colors.white, fontSize: 18),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
        ],
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.grey),
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[700]),
          helperText: helper,
          helperStyle: TextStyle(color: Colors.grey[600], fontSize: 12),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey[700]!),
            borderRadius: BorderRadius.circular(12),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.yellow),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) return 'Requerido';
          if (double.tryParse(value) == null) return 'Número inválido';
          return null;
        },
      ),
    );
  }
}
