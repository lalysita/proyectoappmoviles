import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'edit_note_screen.dart';
import 'private_notes.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Note> _notes = []; // Lista de todas las notas
  String? _privateNotesPin; // PIN para notas privadas
  bool _isLoading = true; // Añadir bandera de carga

  @override
  void initState() {
    super.initState();
    _loadPrivatePin();
  }

  Future<void> _loadPrivatePin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _privateNotesPin = prefs.getString('private_notes_pin');
        _isLoading = false; // Marcar carga como completada
      });
    } catch (e) {
      print('Error al cargar PIN: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _logout() {
    // Implementa aquí la lógica de cierre de sesión
    Navigator.of(context).pushReplacementNamed('/login');
  }

  void _goToProfile() {
    Navigator.of(context).pushNamed('/profile');
  }

  // Método para manejar el acceso a notas privadas con autenticación
  Future<void> _goToPrivateNotes() async {
    if (_isLoading) return; // Prevenir acciones mientras se carga

    // Obtener todas las notas privadas
    final privateNotes = _notes.where((note) => note.isPrivate).toList();

    try {
      final prefs = await SharedPreferences.getInstance();
      final savedPin = prefs.getString('private_notes_pin');

      // Si no hay PIN, solicitar configuración
      if (savedPin == null) {
        final result = await showDialog(
          context: context,
          barrierDismissible: false,
          builder:
              (context) => PrivateNotesAuthDialog(
                expectedPin: null,
                firstTimeSetup: true,
              ),
        );

        if (result is! String) {
          // Cancelado o sin configuración
          return;
        }
      }

      // Mostrar diálogo de autenticación
      final result = await showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => PrivateNotesAuthDialog(expectedPin: _privateNotesPin),
      );

      if (result == true) {
        // Navegar a la pantalla de notas privadas
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => _buildPrivateNotesScreen(privateNotes),
          ),
        );
      }
    } catch (e) {
      print('Error al acceder a notas privadas: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al acceder a notas privadas: $e')),
      );
    }
  }

  // Método para construir la pantalla de notas privadas
  Widget _buildPrivateNotesScreen(List<Note> privateNotes) {
    return PrivateNotesScreen(
      initialPrivateNotes: privateNotes,
      onNotesUpdated: (updatedPrivateNotes) {
        // Actualizar la lista de notas
        setState(() {
          // Eliminar las notas privadas antiguas
          _notes.removeWhere((note) => note.isPrivate);
          // Agregar las notas privadas actualizadas
          _notes.addAll(updatedPrivateNotes);
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Separar notas públicas
    final publicNotes = _notes.where((note) => !note.isPrivate).toList();

    if (_isLoading) {
      // Mostrar un indicador de carga mientras se inicializa
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Mis Notas',
          style: GoogleFonts.pacifico(
            textStyle: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(color: Theme.of(context).primaryColor),
              child: Text(
                'Menú',
                style: GoogleFonts.pacifico(
                  textStyle: const TextStyle(color: Colors.white, fontSize: 24),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Perfil'),
              onTap: _goToProfile,
            ),
            ListTile(
              leading: const Icon(Icons.lock),
              title: const Text('Notas Privadas'),
              onTap: _goToPrivateNotes,
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Cerrar Sesión'),
              onTap: _logout,
            ),
          ],
        ),
      ),
      body:
          publicNotes.isEmpty
              ? const Center(
                child: Text('No hay notas públicas aún. ¡Crea una!'),
              )
              : ListView.builder(
                itemCount: publicNotes.length,
                itemBuilder: (context, index) {
                  return Card(
                    margin: const EdgeInsets.all(8.0),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            publicNotes[index].title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(publicNotes[index].content),
                        ],
                      ),
                    ),
                  );
                },
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const EditNoteScreen()),
          );

          if (result != null && result is Note) {
            setState(() {
              // Agregar la nueva nota a la lista de notas
              _notes.add(result);
            });
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

// Este widget debería estar en un archivo separado, probablemente private_notes_screen.dart
class PrivateNotesScreen extends StatefulWidget {
  final List<Note> initialPrivateNotes;
  final Function(List<Note>) onNotesUpdated;

  const PrivateNotesScreen({
    super.key,
    required this.initialPrivateNotes,
    required this.onNotesUpdated,
  });

  @override
  _PrivateNotesScreenState createState() => _PrivateNotesScreenState();
}

class _PrivateNotesScreenState extends State<PrivateNotesScreen> {
  late List<Note> _privateNotes;

  @override
  void initState() {
    super.initState();
    _privateNotes = List.from(widget.initialPrivateNotes);
  }

  void _editNote(Note note) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditNoteScreen(note: note)),
    );

    if (result != null && result is Note) {
      setState(() {
        final index = _privateNotes.indexWhere((n) => n == note);
        if (index != -1) {
          _privateNotes[index] = result;
        }
      });

      // Notificar al padre de la actualización
      widget.onNotesUpdated(_privateNotes);
    }
  }

  void _deleteNote(Note note) {
    setState(() {
      _privateNotes.remove(note);
    });

    // Notificar al padre de la actualización
    widget.onNotesUpdated(_privateNotes);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notas Privadas', style: GoogleFonts.pacifico()),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              // Crear una nueva nota privada
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const EditNoteScreen()),
              );

              if (result != null && result is Note) {
                // Asegurar que la nota sea privada
                final privateNote = Note(
                  title: result.title,
                  content: result.content,
                  color: result.color,
                  isPrivate: true,
                  pin: result.pin,
                  createdAt: result.createdAt,
                  modifiedAt: result.modifiedAt,
                );

                setState(() {
                  _privateNotes.add(privateNote);
                });

                // Notificar al padre de la actualización
                widget.onNotesUpdated(_privateNotes);
              }
            },
          ),
        ],
      ),
      body:
          _privateNotes.isEmpty
              ? const Center(child: Text('No hay notas privadas'))
              : ListView.builder(
                itemCount: _privateNotes.length,
                itemBuilder: (context, index) {
                  final note = _privateNotes[index];
                  return Card(
                    margin: const EdgeInsets.all(8.0),
                    color: note.color,
                    child: ListTile(
                      title: Text(note.title),
                      subtitle: Text(note.content),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _editNote(note),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => _deleteNote(note),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
    );
  }
}
