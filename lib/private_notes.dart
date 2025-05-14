import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrivateNotesAuthDialog extends StatefulWidget {
  final String? expectedPin;
  final bool firstTimeSetup;

  const PrivateNotesAuthDialog({
  super.key,
  this.expectedPin,
  this.firstTimeSetup = false,
});


  @override
  PrivateNotesAuthDialogState createState() => PrivateNotesAuthDialogState();
}

class PrivateNotesAuthDialogState extends State<PrivateNotesAuthDialog> {
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _confirmPinController = TextEditingController();
  bool _isPinError = false;
  late bool _isSetupMode;

  @override
  void initState() {
    super.initState();
    _isSetupMode = widget.expectedPin == null || widget.firstTimeSetup;
  }

  Future<void> _validatePin() async {
    final prefs = await SharedPreferences.getInstance();
    final pin = _pinController.text;

    if (_isSetupMode) {
      final confirmPin = _confirmPinController.text;

      if (pin.length == 4 && int.tryParse(pin) != null) {
        if (confirmPin == pin) {
          await prefs.setString('private_notes_pin', pin);
          if (mounted) Navigator.of(context).pop(pin);
        } else {
          _showSnackBar('Los PINs no coinciden');
        }
      } else {
        _showSnackBar('Ingresa un PIN de 4 dígitos válido');
      }
    } else {
      final savedPin = prefs.getString('private_notes_pin');
      if (pin == savedPin) {
        if (mounted) Navigator.of(context).pop(true);
      } else {
        if (mounted) {
          setState(() {
            _isPinError = true;
          });
        }
      }
    }
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isSetupMode ? 'Configurar PIN de Notas Privadas' : 'Acceso a Notas Privadas'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _pinController,
            keyboardType: TextInputType.number,
            maxLength: 4,
            obscureText: true,
            decoration: InputDecoration(
              hintText: _isSetupMode ? 'Ingresa un nuevo PIN de 4 dígitos' : 'Ingresa tu PIN de 4 dígitos',
              errorText: _isPinError ? 'PIN incorrecto' : null,
            ),
            onSubmitted: (_) => _validatePin(),
          ),
          if (_isSetupMode)
            TextField(
              controller: _confirmPinController,
              keyboardType: TextInputType.number,
              maxLength: 4,
              obscureText: true,
              decoration: const InputDecoration(hintText: 'Confirma tu PIN'),
              onSubmitted: (_) => _validatePin(),
            ),
        ],
      ),
      actions: [
        if (!_isSetupMode)
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
        ElevatedButton(
          onPressed: _validatePin,
          child: Text(_isSetupMode ? 'Guardar' : 'Acceder'),
        ),
      ],
    );
  }
}

// Extensión para eliminar el PIN almacenado
extension PrivateNotesAuth on BuildContext {
  Future<void> removePrivateNotePin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('private_notes_pin');
  }
}
