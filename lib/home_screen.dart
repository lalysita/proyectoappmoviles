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
  final List<Note> _notes = [];
  String? _privateNotesPin;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPrivatePin();
  }

  Future<void> _loadPrivatePin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      setState(() {
        _privateNotesPin = prefs.getString('private_notes_pin');
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error al cargar PIN: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _logout() {
    Navigator.of(context).pushReplacementNamed('/login');
  }

  void _goToProfile() {
    Navigator.of(context).pushNamed('/profile');
  }

  Future<void> _goToPrivateNotes() async {
    if (_isLoading) return;

    final privateNotes = _notes.where((note) => note.isPrivate).toList();

    try {
      final prefs = await SharedPreferences.getInstance();
if (!mounted) return; // ✅ Check antes de usar context
final savedPin = prefs.getString('private_notes_pin');

if (savedPin == null) {
  final result = await showDialog(
    context: context, // ✅ Ya es seguro usarlo
    barrierDismissible: false,
    builder: (context) => PrivateNotesAuthDialog(
      expectedPin: null,
      firstTimeSetup: true,
    ),
  );
  if (!mounted) return;
  if (result is! String) return;
}


      final result = await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) =>
            PrivateNotesAuthDialog(expectedPin: _privateNotesPin),
      );

      if (result == true) {
        if (!mounted) return;
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => _buildPrivateNotesScreen(privateNotes),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error al acceder a notas privadas: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al acceder a notas privadas: $e')),
      );
    }
  }

  Widget _buildPrivateNotesScreen(List<Note> privateNotes) {
    return PrivateNotesScreen(
      initialPrivateNotes: privateNotes,
      onNotesUpdated: (updatedPrivateNotes) {
        setState(() {
          _notes.removeWhere((note) => note.isPrivate);
          _notes.addAll(updatedPrivateNotes);
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final publicNotes = _notes.where((note) => !note.isPrivate).toList();

    if (_isLoading) {
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
      body: publicNotes.isEmpty
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

          if (!mounted) return;

          if (result != null && result is Note) {
            setState(() {
              _notes.add(result);
            });
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class PrivateNotesScreen extends StatefulWidget {
  final List<Note> initialPrivateNotes;
  final Function(List<Note>) onNotesUpdated;

  const PrivateNotesScreen({
    super.key,
    required this.initialPrivateNotes,
    required this.onNotesUpdated,
  });

  @override
  State<PrivateNotesScreen> createState() => _PrivateNotesScreenState();
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

    if (!mounted) return;

    if (result != null && result is Note) {
      setState(() {
        final index = _privateNotes.indexWhere((n) => n == note);
        if (index != -1) {
          _privateNotes[index] = result;
        }
      });
      widget.onNotesUpdated(_privateNotes);
    }
  }

  void _deleteNote(Note note) {
    setState(() {
      _privateNotes.remove(note);
    });
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
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const EditNoteScreen()),
              );

              if (!mounted) return;

              if (result != null && result is Note) {
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

                widget.onNotesUpdated(_privateNotes);
              }
            },
          ),
        ],
      ),
      body: _privateNotes.isEmpty
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
