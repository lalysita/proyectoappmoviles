import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class Note {
  String title;
  String content;
  Color color;
  bool isPrivate;
  String? pin;
  DateTime createdAt;
  DateTime modifiedAt;

  Note({
    required this.title,
    required this.content,
    required this.color,
    required this.isPrivate,
    this.pin,
    required this.createdAt,
    required this.modifiedAt,
  });
}

class EditNoteScreen extends StatefulWidget {
  final Note? note; // Si es null, es una nota nueva

  const EditNoteScreen({super.key, this.note});

  @override
  State<EditNoteScreen> createState() => _EditNoteScreenState();
}

class _EditNoteScreenState extends State<EditNoteScreen> {
  // Paleta de colores agradables
  final List<Color> _colorPalette = [
    Colors.white,
    Color(0xFFFFF8E1), // Amarillo suave
    Color(0xFFE1F5FE), // Azul suave
    Color(0xFFE8F5E9), // Verde suave
    Color(0xFFFCE4EC), // Rosa suave
    Color(0xFFEDE7F6), // Púrpura suave
    Color(0xFFFBE9E7), // Naranja suave
    Color(0xFFEFEBE9), // Marrón suave
  ];

  late TextEditingController _titleController;
  late TextEditingController _contentController;
  bool _isPrivate = false;
  String? _pin;
  late Color _selectedColor;
  late DateTime _createdAt;
  late DateTime _modifiedAt;
  final FocusNode _focusNode = FocusNode();

  // Textos con formato
  bool _isBold = false;
  bool _isItalic = false;
  bool _isUnderlined = false;
  bool _isHighlighted = false;

  // Registro de imágenes seleccionadas
  List<String> _imagePaths = [];

  @override
  void initState() {
    super.initState();

    if (widget.note != null) {
      _titleController = TextEditingController(text: widget.note!.title);
      _contentController = TextEditingController(text: widget.note!.content);
      _isPrivate = widget.note!.isPrivate;
      _pin = widget.note!.pin;
      _selectedColor = widget.note!.color;
      _createdAt = widget.note!.createdAt;
      _modifiedAt = DateTime.now(); // Se actualiza al editar
    } else {
      _titleController = TextEditingController();
      _contentController = TextEditingController();
      _selectedColor = _colorPalette[0]; // Blanco por defecto
      _createdAt = DateTime.now();
      _modifiedAt = DateTime.now();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _setPinDialog() async {
    final TextEditingController pinController = TextEditingController(
      text: _pin,
    );

    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Establecer PIN de 4 dígitos'),
          content: TextField(
            controller: pinController,
            keyboardType: TextInputType.number,
            maxLength: 4,
            decoration: InputDecoration(
              hintText: 'Ingresa un PIN de 4 dígitos',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                if (pinController.text.length == 4 &&
                    int.tryParse(pinController.text) != null) {
                  setState(() {
                    _pin = pinController.text;
                  });
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Por favor ingresa exactamente 4 dígitos numéricos',
                      ),
                    ),
                  );
                }
              },
              child: Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _imagePaths.add(image.path);
      });

      // En una implementación más completa, aquí se agregaría código para
      // insertar la referencia a la imagen en el texto o guardarla asociada a la nota
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Imagen seleccionada: ${image.path}')),
      );
    }
  }

  void _saveNote() {
    final Note editedNote = Note(
      title:
          _titleController.text.isEmpty
              ? 'Nota sin título'
              : _titleController.text,
      content: _contentController.text,
      color: _selectedColor,
      isPrivate: _isPrivate,
      pin: _isPrivate ? _pin : null,
      createdAt: _createdAt,
      modifiedAt: DateTime.now(),
    );

    // Aquí se guardaría la nota en la base de datos

    Navigator.pop(context, editedNote);
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Scaffold(
      backgroundColor: _selectedColor,
      appBar: AppBar(
        backgroundColor: _selectedColor,
        title: TextField(
          controller: _titleController,
          decoration: InputDecoration(
            hintText: 'Título de la nota',
            border: InputBorder.none,
          ),
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        actions: [
          // Botón de privacidad
          IconButton(
            icon: Icon(_isPrivate ? Icons.lock : Icons.lock_open),
            tooltip: 'Privacidad',
            onPressed: () {
              setState(() {
                _isPrivate = !_isPrivate;
                if (_isPrivate && _pin == null) {
                  _setPinDialog();
                }
              });
            },
          ),
          // Paleta de colores
          IconButton(
            icon: Icon(Icons.color_lens),
            tooltip: 'Cambiar color',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: Text('Elegir color de fondo'),
                    content: Container(
                      width: 300,
                      height: 100,
                      child: GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemCount: _colorPalette.length,
                        itemBuilder: (context, index) {
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedColor = _colorPalette[index];
                              });
                              Navigator.pop(context);
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: _colorPalette[index],
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              );
            },
          ),
          // Botón de guardar
          IconButton(
            icon: Icon(Icons.save),
            tooltip: 'Guardar',
            onPressed: _saveNote,
          ),
        ],
      ),
      body: Column(
        children: [
          // Información de fechas
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  'Creada: ${dateFormat.format(_createdAt)} • ',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                Text(
                  'Modificada: ${dateFormat.format(_modifiedAt)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),

          // Barra de herramientas de formato simplificada
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // Botón para texto en negrita
                  IconButton(
                    icon: Icon(Icons.format_bold),
                    color: _isBold ? Colors.blue : null,
                    onPressed: () {
                      setState(() {
                        _isBold = !_isBold;
                      });
                      // Aquí se implementaría la lógica para aplicar el formato
                    },
                  ),
                  // Botón para texto en cursiva
                  IconButton(
                    icon: Icon(Icons.format_italic),
                    color: _isItalic ? Colors.blue : null,
                    onPressed: () {
                      setState(() {
                        _isItalic = !_isItalic;
                      });
                      // Aquí se implementaría la lógica para aplicar el formato
                    },
                  ),
                  // Botón para texto subrayado
                  IconButton(
                    icon: Icon(Icons.format_underlined),
                    color: _isUnderlined ? Colors.blue : null,
                    onPressed: () {
                      setState(() {
                        _isUnderlined = !_isUnderlined;
                      });
                      // Aquí se implementaría la lógica para aplicar el formato
                    },
                  ),
                  // Botón para texto resaltado
                  IconButton(
                    icon: Icon(Icons.highlight),
                    color: _isHighlighted ? Colors.blue : null,
                    onPressed: () {
                      setState(() {
                        _isHighlighted = !_isHighlighted;
                      });
                      // Aquí se implementaría la lógica para aplicar el formato
                    },
                  ),
                  // Botón para agregar imágenes
                  IconButton(icon: Icon(Icons.image), onPressed: _pickImage),
                ],
              ),
            ),
          ),

          // Editor de texto simplificado
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _contentController,
                focusNode: _focusNode,
                maxLines: null,
                decoration: InputDecoration(
                  hintText: 'Escribe tu nota aquí...',
                  border: InputBorder.none,
                ),
                style: TextStyle(
                  fontWeight: _isBold ? FontWeight.bold : FontWeight.normal,
                  fontStyle: _isItalic ? FontStyle.italic : FontStyle.normal,
                  decoration:
                      _isUnderlined
                          ? TextDecoration.underline
                          : TextDecoration.none,
                  backgroundColor: _isHighlighted ? Colors.yellow[100] : null,
                ),
                expands: true,
              ),
            ),
          ),

          // Vista previa de imágenes
          if (_imagePaths.isNotEmpty)
            Container(
              height: 80,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _imagePaths.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: 60,
                        color: Colors.grey[300],
                        child: Center(child: Text('Imagen ${index + 1}')),
                        // En una implementación más completa, aquí se mostraría la imagen
                        // Image.file(File(_imagePaths[index]), fit: BoxFit.cover),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
