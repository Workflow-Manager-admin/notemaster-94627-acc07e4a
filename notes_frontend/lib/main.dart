import 'package:flutter/material.dart';

// Configuration for theme colors
const Color kPrimaryColor = Color(0xFF1976D2);
const Color kSecondaryColor = Color(0xFF424242);
const Color kAccentColor = Color(0xFFFFB300);

// Note data model
class Note {
  int id;
  String title;
  String content;
  DateTime created;
  DateTime updated;

  Note({
    required this.id,
    required this.title,
    required this.content,
    required this.created,
    required this.updated,
  });

  // For use with add/edit forms
  Note.clone(Note note)
      : id = note.id,
        title = note.title,
        content = note.content,
        created = note.created,
        updated = note.updated;
}

// In-memory simulated storage (replace with backend integration as needed)
class NotesRepository extends ChangeNotifier {
  List<Note> _notes = [];
  int _autoIncrement = 1;

  List<Note> getAllNotesSorted([String? query]) {
    List<Note> filtered = _notes;
    if (query != null && query.trim().isNotEmpty) {
      filtered = _notes
          .where((note) =>
              note.title.toLowerCase().contains(query.toLowerCase()) ||
              note.content.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }
    filtered.sort((a, b) => b.updated.compareTo(a.updated));
    return filtered;
  }

  void addNote(String title, String content) {
    final now = DateTime.now();
    _notes.add(
      Note(
        id: _autoIncrement++,
        title: title,
        content: content,
        created: now,
        updated: now,
      ),
    );
    notifyListeners();
  }

  void updateNote(int id, String title, String content) {
    final idx = _notes.indexWhere((n) => n.id == id);
    if (idx != -1) {
      _notes[idx] = Note(
        id: id,
        title: title,
        content: content,
        created: _notes[idx].created,
        updated: DateTime.now(),
      );
      notifyListeners();
    }
  }

  void deleteNote(int id) {
    _notes.removeWhere((n) => n.id == id);
    notifyListeners();
  }

  Note? getNoteById(int id) {
    try {
      return _notes.firstWhere((n) => n.id == id);
    } catch (e) {
      return null;
    }
  }

  void addSample() {
    addNote(
      "Welcome to Notemaster",
      "Tap the + button to add your first note!\n\nEdit or delete notes by tapping them or the three-dot menu.",
    );
  }
}

void main() {
  runApp(NoteMasterApp());
}

/// PUBLIC_INTERFACE
class NoteMasterApp extends StatelessWidget {
  /// Main app root widget
  const NoteMasterApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Notemaster',
      theme: ThemeData(
        colorScheme: ColorScheme.light(
          primary: kPrimaryColor,
          secondary: kSecondaryColor,
          surface: Colors.white,
          background: Colors.white,
          error: Colors.red.shade700,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: kSecondaryColor,
          onBackground: kSecondaryColor,
          onError: Colors.white,
        ),
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: AppBarTheme(
          backgroundColor: kPrimaryColor,
          elevation: 0.5,
          iconTheme: const IconThemeData(color: Colors.white),
          titleTextStyle: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: kAccentColor,
          foregroundColor: Colors.black87,
        ),
        cardTheme: CardTheme(
          color: Colors.white,
          elevation: 2,
          margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: const BorderSide(width: 1, color: kSecondaryColor)),
        ),
        primaryColor: kPrimaryColor,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        fontFamily: 'Roboto',
      ),
      home: NotesHomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

/// PUBLIC_INTERFACE
class NotesHomeScreen extends StatefulWidget {
  /// Main screen displaying the notes list and search bar
  const NotesHomeScreen({Key? key}) : super(key: key);

  @override
  State<NotesHomeScreen> createState() => _NotesHomeScreenState();
}

class _NotesHomeScreenState extends State<NotesHomeScreen> {
  final NotesRepository repo = NotesRepository();
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Add a sample on start for empty state
    if (repo.getAllNotesSorted().isEmpty) {
      repo.addSample();
    }
    repo.addListener(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    final notes = repo.getAllNotesSorted(searchQuery);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notemaster'),
        backgroundColor: kPrimaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            tooltip: "Search notes",
            onPressed: () async {
              final result = await showSearch<String>(
                context: context,
                delegate: NotesSearchDelegate(repo: repo),
              );
              if (result != null) {
                setState(() {
                  searchQuery = result;
                });
              }
            },
          )
        ],
      ),
      body: notes.isEmpty
          ? Center(
              child: Text(
                'No notes found.',
                style: TextStyle(
                    color: kSecondaryColor.withAlpha(120), fontSize: 18),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 80),
              itemCount: notes.length,
              itemBuilder: (context, idx) =>
                  NoteCard(note: notes[idx], onTap: () => _openEditNote(notes[idx]), onDelete: () => _confirmDelete(notes[idx])),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNoteDialog,
        child: const Icon(Icons.add),
        tooltip: 'Create note',
        elevation: 2,
      ),
    );
  }

  void _addNoteDialog() async {
    final result = await Navigator.push<Note>(
      context,
      MaterialPageRoute(
        builder: (_) => NoteEditScreen(
          title: "Create Note",
          initialNote: Note(id: -1, title: '', content: '', created: DateTime.now(), updated: DateTime.now()),
        ),
        fullscreenDialog: true,
      ),
    );
    if (result != null) {
      repo.addNote(result.title, result.content);
    }
  }

  void _openEditNote(Note note) async {
    final result = await Navigator.push<Note>(
      context,
      MaterialPageRoute(
        builder: (_) => NoteEditScreen(
          title: "Edit Note",
          initialNote: Note.clone(note),
        ),
        fullscreenDialog: true,
      ),
    );
    if (result != null) {
      repo.updateNote(note.id, result.title, result.content);
    }
  }

  void _confirmDelete(Note note) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Delete Note"),
        content: Text("Are you sure you want to delete this note?"),
        actions: [
          TextButton(
            child: Text("Cancel", style: TextStyle(color: kSecondaryColor)),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          TextButton(
            child: Text("Delete", style: TextStyle(color: Colors.red[700])),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );
    if (confirm == true) {
      repo.deleteNote(note.id);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Note deleted'),
        duration: Duration(milliseconds: 900),
      ));
    }
  }
}

/// PUBLIC_INTERFACE
class NoteEditScreen extends StatefulWidget {
  /// Full-screen modal for creating/editing notes
  final String title;
  final Note initialNote;

  const NoteEditScreen({required this.title, required this.initialNote, Key? key})
      : super(key: key);

  @override
  State<NoteEditScreen> createState() => _NoteEditScreenState();
}

class _NoteEditScreenState extends State<NoteEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late Note editingNote;

  @override
  void initState() {
    editingNote = Note.clone(widget.initialNote);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: kPrimaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(Icons.check, color: kAccentColor),
            tooltip: "Save",
            onPressed: _submitForm,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                initialValue: editingNote.title,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  floatingLabelBehavior: FloatingLabelBehavior.auto,
                  suffixIcon: Icon(Icons.title, size: 22),
                ),
                maxLength: 48,
                validator: (val) =>
                    val == null || val.trim().isEmpty ? "Title required" : null,
                onSaved: (val) => editingNote.title = val?.trim() ?? '',
              ),
              const SizedBox(height: 12),
              Expanded(
                child: TextFormField(
                  initialValue: editingNote.content,
                  decoration: const InputDecoration(
                    labelText: 'Note',
                    floatingLabelBehavior: FloatingLabelBehavior.auto,
                    alignLabelWithHint: true,
                  ),
                  keyboardType: TextInputType.multiline,
                  maxLines: null,
                  expands: true,
                  validator: (val) =>
                      val == null || val.trim().isEmpty ? "Enter note content" : null,
                  onSaved: (val) => editingNote.content = val ?? '',
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _submitForm,
        label: Text(widget.initialNote.id == -1 ? "Add Note" : "Save"),
        icon: Icon(Icons.save_alt),
        backgroundColor: kAccentColor,
        foregroundColor: Colors.black,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  void _submitForm() {
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState?.save();
      Navigator.of(context).pop(editingNote);
    }
  }
}

/// PUBLIC_INTERFACE
class NoteCard extends StatelessWidget {
  /// Card displaying a single note in the notes list
  final Note note;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const NoteCard(
      {required this.note, required this.onTap, required this.onDelete, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _NoteDetails(note: note),
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: kSecondaryColor, size: 22),
                onSelected: (value) {
                  if (value == "delete") {
                    onDelete();
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem<String>(
                    value: 'delete',
                    child: Text('Delete', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoteDetails extends StatelessWidget {
  final Note note;
  const _NoteDetails({required this.note, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final snippet = note.content.split('\n').take(3).join('\n');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          note.title,
          style: TextStyle(
              color: kPrimaryColor, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 4),
        Text(
          snippet,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: kSecondaryColor.withAlpha(210),
            fontSize: 15.5,
            height: 1.31,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _formatDate(note.updated),
          style: TextStyle(
              color: kSecondaryColor.withAlpha(98),
              fontSize: 13.5,
              fontStyle: FontStyle.italic),
        ),
      ],
    );
  }

  static String _formatDate(DateTime dt) {
    final now = DateTime.now();
    if (dt.year == now.year &&
        dt.month == now.month &&
        dt.day == now.day) {
      return "Today at ${_pad2(dt.hour)}:${_pad2(dt.minute)}";
    } else {
      return "${dt.year}-${_pad2(dt.month)}-${_pad2(dt.day)} ${_pad2(dt.hour)}:${_pad2(dt.minute)}";
    }
  }

  static String _pad2(int n) => n < 10 ? "0$n" : "$n";
}

/// PUBLIC_INTERFACE
class NotesSearchDelegate extends SearchDelegate<String> {
  /// Custom search interface for searching notes
  final NotesRepository repo;

  NotesSearchDelegate({required this.repo})
      : super(
          searchFieldLabel: "Search notes…",
          keyboardType: TextInputType.text,
          textInputAction: TextInputAction.search,
        );

  @override
  ThemeData appBarTheme(BuildContext context) {
    // Use custom theme, but primary for search
    final ThemeData theme = Theme.of(context);
    return theme.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: kPrimaryColor,
        elevation: 0.7,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      inputDecorationTheme: theme.inputDecorationTheme.copyWith(
        hintStyle: TextStyle(color: Colors.white70),
        border: InputBorder.none,
      ),
      textTheme: theme.textTheme.copyWith(
        titleLarge:
            TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
            icon: Icon(Icons.clear, color: Colors.white),
            onPressed: () => query = '')
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back, color: Colors.white),
      onPressed: () => close(context, query),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    var matches = repo.getAllNotesSorted(query);
    if (matches.isEmpty) {
      return Center(
          child: Text(
        "No matching notes.",
        style: TextStyle(color: kSecondaryColor.withAlpha(99), fontSize: 17),
      ));
    }
    return ListView.builder(
      itemCount: matches.length,
      itemBuilder: (ctx, idx) {
        final note = matches[idx];
        return NoteCard(
          note: note,
          onTap: () {
            close(context, query);
          },
          onDelete: () {
            // Optional: allow delete from search
            repo.deleteNote(note.id);
            showResults(context);
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return buildResults(context);
  }
}
