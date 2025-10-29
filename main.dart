import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import 'dart:io';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isDarkMode = false;
  double _fontSize = 16.0;
  int _selectedIndex = 0;
  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool('isDarkMode') ?? false;
      _fontSize = prefs.getDouble('fontSize') ?? 16.0;
    });
  }

  void _updateTheme(bool value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', value);
    setState(() {
      _isDarkMode = value;
    });
  }

  void _updateFontSize(double size) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('fontSize', size);
    setState(() {
      _fontSize = size;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: _isDarkMode ? ThemeData.dark() : ThemeData.light(),
      routes: {
        '/': (ctx) => MainScreen(
          selectedIndex: _selectedIndex,
          onTabChanged: (i) => setState(() => _selectedIndex = i),
          isDarkMode: _isDarkMode,
          onThemeChange: _updateTheme,
          fontSize: _fontSize,
          onFontSizeChange: _updateFontSize,
        ),
      },
      // Use onGenerateRoute for custom argument passing
      onGenerateRoute: (RouteSettings settings) {
        if (settings.name == '/note_detail') {
          final args = settings.arguments;
          if (args is Map<String, dynamic>) {
            final Note note = args['note'];
            final Database db = args['db'];
            final double fontSize = args['fontSize'] ?? 16.0;
            return MaterialPageRoute(
              builder: (context) => NoteDetailScreen(
                note: note,
                db: db,
                fontSize: fontSize,
              ),
            );
          } else {
            return MaterialPageRoute(
              builder: (context) => Scaffold(
                body: Center(child: Text('No note found.')),
              ),
            );
          }
        }
        return null;
      },
    );
  }
}

class MainScreen extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTabChanged;
  final bool isDarkMode;
  final Function(bool) onThemeChange;
  final double fontSize;
  final Function(double) onFontSizeChange;
  const MainScreen({
    Key? key,
    required this.selectedIndex,
    required this.onTabChanged,
    required this.isDarkMode,
    required this.onThemeChange,
    required this.fontSize,
    required this.onFontSizeChange,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screens = [
      UsernameScreen(fontSize: fontSize),
      CounterScreen(fontSize: fontSize),
      ThemeSettingScreen(
        isDarkMode: isDarkMode,
        onThemeChange: onThemeChange,
        fontSize: fontSize,
        onFontSizeChange: onFontSizeChange,
      ),
      NotesScreen(fontSize: fontSize),
      FileStorageDemo(fontSize: fontSize),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('All Persistence Demo')),
      body: IndexedStack(index: selectedIndex, children: screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: onTabChanged,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Username"),
          BottomNavigationBarItem(icon: Icon(Icons.plus_one), label: "Counter"),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Settings"),
          BottomNavigationBarItem(icon: Icon(Icons.note), label: "Notes"),
          BottomNavigationBarItem(icon: Icon(Icons.insert_drive_file), label: "File"),
        ],
      ),
    );
  }
}

// 1. Username SharedPreferences
class UsernameScreen extends StatefulWidget {
  final double fontSize;
  const UsernameScreen({Key? key, required this.fontSize}) : super(key: key);
  @override
  State<UsernameScreen> createState() => _UsernameScreenState();
}

class _UsernameScreenState extends State<UsernameScreen> {
  final _controller = TextEditingController();
  String _savedUsername = "";

  @override
  void initState() {
    super.initState();
    _loadUsername();
  }

  void _loadUsername() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _savedUsername = prefs.getString('username') ?? "";
      _controller.text = _savedUsername;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Builder(builder: (ctx) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(labelText: "Enter username"),
              style: TextStyle(fontSize: widget.fontSize),
            ),
            ElevatedButton(
              onPressed: () async {
                SharedPreferences prefs = await SharedPreferences.getInstance();
                await prefs.setString('username', _controller.text);
                setState(() {
                  _savedUsername = _controller.text;
                });
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text("Username saved!")),
                );
              },
              child: const Text("Save"),
            ),
            const SizedBox(height: 16),
            Text("Saved username: $_savedUsername",
                style: TextStyle(fontSize: widget.fontSize)),
          ],
        ),
      );
    });
  }
}

// 2. Counter SharedPreferences
class CounterScreen extends StatefulWidget {
  final double fontSize;
  const CounterScreen({Key? key, required this.fontSize}) : super(key: key);
  @override
  State<CounterScreen> createState() => _CounterScreenState();
}

class _CounterScreenState extends State<CounterScreen> {
  int _counter = 0;
  @override
  void initState() {
    super.initState();
    _loadCounter();
  }
  void _loadCounter() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _counter = prefs.getInt('counter') ?? 0;
    });
  }

  void _incrementCounter() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _counter++;
      prefs.setInt('counter', _counter);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Counter value: $_counter',
              style: TextStyle(fontSize: widget.fontSize)),
          ElevatedButton(
            onPressed: _incrementCounter,
            child: const Text('Increment'),
          ),
        ],
      ),
    );
  }
}

// 3. Theme toggle and font size settings
class ThemeSettingScreen extends StatelessWidget {
  final bool isDarkMode;
  final Function(bool) onThemeChange;
  final double fontSize;
  final Function(double) onFontSizeChange;
  const ThemeSettingScreen({
    Key? key,
    required this.isDarkMode,
    required this.onThemeChange,
    required this.fontSize,
    required this.onFontSizeChange
  }) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        SwitchListTile(
          title: const Text("Enable Dark Mode"),
          value: isDarkMode,
          onChanged: onThemeChange,
        ),
        const SizedBox(height: 16),
        Text("Font size: ${fontSize.toInt()}"),
        Slider(
          min: 12, max: 32,
          value: fontSize,
          divisions: 10,
          label: fontSize.toInt().toString(),
          onChanged: onFontSizeChange,
        ),
      ]),
    );
  }
}

// 4–8. SQLite CRUD: Notes and navigation
class Note {
  final int? id;
  String title;
  String content;
  Note({this.id, required this.title, required this.content});

  Map<String, dynamic> toMap() =>
      {'id': id, 'title': title, 'content': content};

  static Note fromMap(Map<String, dynamic> map) =>
      Note(id: map['id'], title: map['title'], content: map['content']);
}

class NotesScreen extends StatefulWidget {
  final double fontSize;
  const NotesScreen({Key? key, required this.fontSize}) : super(key: key);
  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  Database? _db;
  List<Note> _notes = [];

  @override
  void initState() {
    super.initState();
    _initDb();
  }

  Future<void> _initDb() async {
    Directory dir = await getApplicationDocumentsDirectory();
    String path = join(dir.path, 'notes.db');
    _db = await openDatabase(path, version: 1,
        onCreate: (db, v) async {
          await db.execute(
              'CREATE TABLE notes(id INTEGER PRIMARY KEY, title TEXT, content TEXT);'
          );
        }
    );
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    if (_db != null) {
      final result = await _db!.query('notes');
      setState(() {
        _notes = result.map((e) => Note.fromMap(e)).toList();
      });
    }
  }

  Future<void> _addDummyNote() async {
    if (_db != null) {
      await _db!.insert('notes', {'title': 'Demo', 'content': 'Demo content'});
      _loadNotes();
    }
  }

  Future<void> _deleteNote(int id) async {
    if (_db != null) {
      await _db!.delete('notes', where: 'id = ?', whereArgs: [id]);
      _loadNotes();
    }
  }

  void _editNote(BuildContext context, Note note) async {
    await Navigator.pushNamed(context, '/note_detail', arguments: {
      'note': note,
      'db': _db,
      'fontSize': widget.fontSize,
    });
    _loadNotes();
  }

  void _confirmDelete(BuildContext ctx, int id) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text("Delete note?"),
        content: const Text("Confirm deletion."),
        actions: [
          TextButton(
              onPressed: () {
                _deleteNote(id);
                Navigator.pop(ctx);
              },
              child: const Text("Yes")
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("No"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Builder(builder: (ctx) {
      return Column(
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            ElevatedButton(
              onPressed: _addDummyNote,
              child: const Text("Add Note"),
            ),
            ElevatedButton(
              onPressed: _loadNotes,
              child: const Text("View Notes"),
            ),
          ]),
          Expanded(
            child: ListView.builder(
              itemCount: _notes.length,
              itemBuilder: (c, i) {
                final note = _notes[i];
                return ListTile(
                  title: Text(note.title, style: TextStyle(fontSize: widget.fontSize)),
                  subtitle: Text(note.content, style: TextStyle(fontSize: widget.fontSize)),
                  onTap: () => _editNote(context, note),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _confirmDelete(ctx, note.id!),
                  ),
                );
              },
            ),
          ),
        ],
      );
    });
  }
}


class NoteDetailScreen extends StatefulWidget {
  final Note note;
  final Database db;
  final double fontSize;
  const NoteDetailScreen({
    Key? key,
    required this.note,
    required this.db,
    required this.fontSize,
  }) : super(key: key);

  @override
  State<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends State<NoteDetailScreen> {
  late TextEditingController titleCtrl;
  late TextEditingController contentCtrl;

  @override
  void initState() {
    super.initState();
    titleCtrl = TextEditingController(text: widget.note.title);
    contentCtrl = TextEditingController(text: widget.note.content);
  }

  void _saveEdits(BuildContext ctx) async {
    await widget.db.update(
        'notes',
        {'title': titleCtrl.text, 'content': contentCtrl.text},
        where: 'id = ?', whereArgs: [widget.note.id]
    );
    if (!mounted) return;
    Navigator.pop(ctx);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Note')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: titleCtrl, style: TextStyle(fontSize: widget.fontSize)),
            TextField(controller: contentCtrl, style: TextStyle(fontSize: widget.fontSize)),
            ElevatedButton(
              onPressed: () => _saveEdits(context),
              child: const Text("Save"),
            ),
          ],
        ),
      ),
    );
  }
}



// 9. File Storage Demo (read/write small file)
class FileStorageDemo extends StatefulWidget {
  final double fontSize;
  const FileStorageDemo({Key? key, required this.fontSize}) : super(key: key);
  @override
  State<FileStorageDemo> createState() => _FileStorageDemoState();
}

class _FileStorageDemoState extends State<FileStorageDemo> {
  String _fileContent = "";

  Future<File> _getFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File(join(dir.path, 'user_data.txt'));
  }
  Future<void> _writeFile() async {
    final file = await _getFile();
    await file.writeAsString("Hello from file storage at ${DateTime.now()}");
    _readFile();
  }
  Future<void> _readFile() async {
    final file = await _getFile();
    final exists = await file.exists();
    if (!exists) {
      setState(() { _fileContent = "(no content yet)"; });
      return;
    }
    final data = await file.readAsString();
    setState(() { _fileContent = data; });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        ElevatedButton(onPressed: _writeFile, child: const Text("Write File")),
        ElevatedButton(onPressed: _readFile, child: const Text("Read File")),
        const SizedBox(height: 16),
        Text("File contents:\n$_fileContent", style: TextStyle(fontSize: widget.fontSize)),
      ]),
    );
  }
}
