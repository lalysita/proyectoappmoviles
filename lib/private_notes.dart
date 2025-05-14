import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrivateNotesAuthDialog extends StatefulWidget {
  final String? expectedPin;
  final bool firstTimeSetup;

  const PrivateNotesAuthDialog({
    Key? key, // Se agregó Key? key para evitar un posible error.
    this.expectedPin,
    this.firstTimeSetup = false,
  }) : super(key: key); // Llama al constructor de la superclase con la key.

  @override
  _PrivateNotesAuthDialogState createState() => _PrivateNotesAuthDialogState();
}

class _PrivateNotesAuthDialogState extends State<PrivateNotesAuthDialog> {
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _confirmPinController = TextEditingController();
  bool _isPinError = false;
  bool _isSetupMode = false;

  @override
  void initState() {
    super.initState();
    // Si no hay PIN establecido, ir directamente al modo de configuración
    _isSetupMode = widget.expectedPin == null || widget.firstTimeSetup;
  }

  Future<void> _validatePin() async {
    final prefs = await SharedPreferences.getInstance();

    if (_isSetupMode) {
      // Modo de configuración de PIN
      if (_pinController.text.length == 4 &&
          int.tryParse(_pinController.text) != null) {
        if (_confirmPinController.text == _pinController.text) {
          // Guardar PIN
          await prefs.setString('private_notes_pin', _pinController.text);
          if (mounted) {
            // Verifica si el widget está montado antes de usar Navigator.
            Navigator.of(context).pop(_pinController.text);
          }
        } else {
          // PINs no coinciden
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Los PINs no coinciden')),
            );
          }
        }
      } else {
        // PIN inválido
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ingresa un PIN de 4 dígitos válido')),
          );
        }
      }
    } else {
      // Modo de validación de PIN existente
      final savedPin = prefs.getString('private_notes_pin');
      if (_pinController.text == savedPin) {
        // PIN correcto, permite el acceso
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      } else {
        // PIN incorrecto
        if (mounted) {
          //Es importante verificar que el widget está montado antes de llamar a `setState`.
          setState(() {
            _isPinError = true;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        _isSetupMode
            ? 'Configurar PIN de Notas Privadas'
            : 'Acceso a Notas Privadas',
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _pinController,
            keyboardType: TextInputType.number,
            maxLength: 4,
            obscureText: true,
            decoration: InputDecoration(
              hintText:
                  _isSetupMode
                      ? 'Ingresa un nuevo PIN de 4 dígitos'
                      : 'Ingresa tu PIN de 4 dígitos',
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

// Extensión para eliminar el PIN almacenado (opcional)
extension PrivateNotesAuth on BuildContext {
  Future<void> removePrivateNotePin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('private_notes_pin');
  }
}
