import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'book_model.dart';
import 'book_validation.dart';

final CollectionReference<Map<String, dynamic>> _books = FirebaseFirestore
    .instance
    .collection('books');

class BookListScreen extends StatefulWidget {
  const BookListScreen({super.key, required this.user});

  final User user;

  @override
  State<BookListScreen> createState() => _BookListScreenState();
}

class _BookListScreenState extends State<BookListScreen> {
  final _searchController = TextEditingController();
  String? _genre;
  String? _status;
  bool _favoritesOnly = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.user.email ?? 'BookShelf',
            overflow: TextOverflow.ellipsis,
          ),
          actions: [
            TextButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
            ),
            const SizedBox(width: 8),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _addBook,
          icon: const Icon(Icons.add),
          label: const Text('Add book'),
        ),
        body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _books
              .where('userId', isEqualTo: widget.user.uid)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('Unable to load books: ${snapshot.error}'),
                ),
              );
            }
            final books = snapshot.data!.docs.map(Book.fromDocument).toList()
              ..sort(_compareBooks);
            final visibleBooks = books.where(_matchesFilters).toList();
            return ListView(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 96),
              children: [
                Text(
                  'Your bookshelf',
                  style: Theme.of(context).textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text('Keep every story close at hand.'),
                const SizedBox(height: 18),
                _buildFilters(),
                const SizedBox(height: 12),
                _buildSummary(visibleBooks),
                const SizedBox(height: 12),
                if (visibleBooks.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 38),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.menu_book_outlined, size: 46),
                          SizedBox(height: 10),
                          Text('No books found'),
                        ],
                      ),
                    ),
                  )
                else
                  ...visibleBooks.map(
                    (book) => _BookCard(
                      book: book,
                      onFavoriteChanged: (favorite) =>
                          _setFavorite(book, favorite),
                      onTap: () => _openBook(book),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                labelText: 'Search title or author',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                        tooltip: 'Clear search',
                        icon: const Icon(Icons.close),
                      ),
              ),
            ),
            const SizedBox(height: 10),
            LayoutBuilder(
              builder: (context, constraints) {
                final width = (constraints.maxWidth - 10) / 2;
                return Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    SizedBox(
                      width: width,
                      child: _filterDropdown(
                        label: 'Genre',
                        value: _genre,
                        options: bookGenres,
                        onChanged: (value) => setState(() => _genre = value),
                      ),
                    ),
                    SizedBox(
                      width: width,
                      child: _filterDropdown(
                        label: 'Status',
                        value: _status,
                        options: bookStatuses,
                        onChanged: (value) => setState(() => _status = value),
                      ),
                    ),
                  ],
                );
              },
            ),
            Row(
              children: [
                Expanded(
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Favorites only'),
                    value: _favoritesOnly,
                    onChanged: (value) =>
                        setState(() => _favoritesOnly = value),
                  ),
                ),
                TextButton(
                  onPressed: _clearFilters,
                  child: const Text('Clear'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterDropdown({
    required String label,
    required String? value,
    required List<String> options,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: [
        const DropdownMenuItem<String>(value: null, child: Text('All')),
        ...options.map(
          (option) => DropdownMenuItem(value: option, child: Text(option)),
        ),
      ],
      onChanged: onChanged,
    );
  }

  Widget _buildSummary(List<Book> books) {
    final counts = <String, int>{};
    var favoriteCount = 0;
    for (final book in books) {
      counts.update(book.status, (count) => count + 1, ifAbsent: () => 1);
      if (book.favorite) favoriteCount++;
    }
    final statuses = counts.keys.toList()
      ..sort((first, second) {
        final countOrder = counts[second]!.compareTo(counts[first]!);
        if (countOrder != 0) return countOrder;
        return bookStatuses
            .indexOf(first)
            .compareTo(bookStatuses.indexOf(second));
      });

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 20,
              runSpacing: 6,
              children: [
                Text('Books: ${books.length}'),
                Text('Favorites: $favoriteCount'),
              ],
            ),
            for (final status in statuses)
              Padding(
                padding: const EdgeInsets.only(top: 5),
                child: Text('$status: ${counts[status]}'),
              ),
          ],
        ),
      ),
    );
  }

  bool _matchesFilters(Book book) {
    final query = _searchController.text.trim().toLowerCase();
    return (_genre == null || book.genre == _genre) &&
        (_status == null || book.status == _status) &&
        (!_favoritesOnly || book.favorite) &&
        (query.isEmpty ||
            book.title.toLowerCase().contains(query) ||
            book.author.toLowerCase().contains(query));
  }

  void _clearFilters() {
    _searchController.clear();
    setState(() {
      _genre = null;
      _status = null;
      _favoritesOnly = false;
    });
  }

  int _compareBooks(Book first, Book second) {
    final titleOrder = first.title.toLowerCase().compareTo(
      second.title.toLowerCase(),
    );
    if (titleOrder != 0) return titleOrder;
    return first.author.toLowerCase().compareTo(second.author.toLowerCase());
  }

  Future<void> _addBook() async {
    final added = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => BookFormScreen(userId: widget.user.uid),
      ),
    );
    if (added == true && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Book added')));
    }
  }

  Future<void> _openBook(Book book) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => BookDetailScreen(book: book)),
    );
  }

  Future<void> _setFavorite(Book book, bool favorite) async {
    try {
      await _books.doc(book.id).update({'favorite': favorite});
    } on FirebaseException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message ?? 'Unable to update favorite')),
      );
    }
  }

  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message ?? 'Unable to log out')),
      );
    }
  }
}

class _BookCard extends StatelessWidget {
  const _BookCard({
    required this.book,
    required this.onFavoriteChanged,
    required this.onTap,
  });

  final Book book;
  final ValueChanged<bool> onFavoriteChanged;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
          child: Row(
            children: [
              const CircleAvatar(
                backgroundColor: Color(0xFFE8EFE8),
                child: Icon(Icons.book_outlined),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(book.author),
                    const SizedBox(height: 5),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        _Tag(text: book.genre),
                        _Tag(text: book.status),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => onFavoriteChanged(!book.favorite),
                tooltip: book.favorite ? 'Remove favorite' : 'Add favorite',
                icon: Icon(
                  book.favorite ? Icons.star_rounded : Icons.star_outline,
                  color: book.favorite ? const Color(0xFFE5A627) : null,
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFE8EFE8),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text, style: Theme.of(context).textTheme.labelSmall),
    );
  }
}

class BookFormScreen extends StatefulWidget {
  const BookFormScreen({super.key, required this.userId, this.book});

  final String userId;
  final Book? book;

  @override
  State<BookFormScreen> createState() => _BookFormScreenState();
}

class _BookFormScreenState extends State<BookFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _authorController;
  late final TextEditingController _ratingController;
  late final TextEditingController _notesController;
  String? _genre;
  String? _status;
  bool _favorite = false;
  bool _submitted = false;
  bool _busy = false;
  String? _saveError;

  bool get _editing => widget.book != null;

  @override
  void initState() {
    super.initState();
    final book = widget.book;
    _titleController = TextEditingController(text: book?.title ?? '');
    _authorController = TextEditingController(text: book?.author ?? '');
    _ratingController = TextEditingController(
      text: book?.rating?.toString() ?? '',
    );
    _notesController = TextEditingController(text: book?.notes ?? '');
    _genre = book?.genre;
    _status = book?.status;
    _favorite = book?.favorite ?? false;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _ratingController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_editing ? 'Edit Book' : 'Add Book')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          autovalidateMode: _submitted
              ? AutovalidateMode.onUserInteraction
              : AutovalidateMode.disabled,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
            children: [
              Text(
                _editing
                    ? 'Update your book details'
                    : 'Add a book to your shelf',
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: _titleController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: validateBookTitle,
                onChanged: (_) => _clearSaveError(),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _authorController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Author'),
                validator: validateBookAuthor,
                onChanged: (_) => _clearSaveError(),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _genre,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Genre'),
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('Choose genre'),
                  ),
                  ...bookGenres.map(
                    (genre) =>
                        DropdownMenuItem(value: genre, child: Text(genre)),
                  ),
                ],
                validator: validateBookGenre,
                onChanged: (value) => setState(() => _genre = value),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _status,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Status'),
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('Choose status'),
                  ),
                  ...bookStatuses.map(
                    (status) =>
                        DropdownMenuItem(value: status, child: Text(status)),
                  ),
                ],
                validator: validateBookStatus,
                onChanged: (value) => setState(() => _status = value),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _ratingController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: false,
                ),
                decoration: const InputDecoration(
                  labelText: 'Rating (optional)',
                  helperText: 'Enter a whole number from 0 to 5',
                ),
                validator: validateBookRating,
                onChanged: (_) => _clearSaveError(),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _notesController,
                minLines: 3,
                maxLines: 5,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  alignLabelWithHint: true,
                ),
                validator: validateBookNotes,
                onChanged: (_) => _clearSaveError(),
              ),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: _busy ? null : _save,
                child: _busy
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_editing ? 'Save' : 'Add Book'),
              ),
              if (_editing) ...[
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: _busy ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ],
              if (_saveError != null) ...[
                const SizedBox(height: 12),
                Text(
                  _saveError!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _clearSaveError() {
    if (_saveError != null) setState(() => _saveError = null);
  }

  Future<void> _save() async {
    setState(() {
      _submitted = true;
      _saveError = null;
    });
    if (!_formKey.currentState!.validate()) return;

    setState(() => _busy = true);
    final oldBook = widget.book;
    final title = _titleController.text.trim();
    final author = _authorController.text.trim();
    final id = Book.documentId(widget.userId, title, author);
    final book = Book(
      id: id,
      userId: widget.userId,
      title: title,
      author: author,
      genre: _genre!,
      status: _status!,
      rating: _ratingController.text.trim().isEmpty
          ? null
          : int.parse(_ratingController.text.trim()),
      favorite: _favorite,
      notes: _notesController.text.trim(),
      createdAt: oldBook?.createdAt ?? DateTime.now(),
    );

    try {
      final reference = _books.doc(id);
      if (_editing) {
        if (id == oldBook!.id) {
          await reference.set(book.toFirestore());
        } else {
          final oldReference = _books.doc(oldBook.id);
          await FirebaseFirestore.instance.runTransaction((transaction) async {
            final existing = await transaction.get(reference);
            await transaction.get(oldReference);
            if (existing.exists) throw const DuplicateBookException();
            transaction.set(reference, book.toFirestore());
            transaction.delete(oldReference);
          });
        }
      } else {
        await FirebaseFirestore.instance.runTransaction((transaction) async {
          final existing = await transaction.get(reference);
          if (existing.exists) throw const DuplicateBookException();
          transaction.set(
            reference,
            book.toFirestore(useServerTimestamp: true),
          );
        });
      }
      if (!mounted) return;
      Navigator.of(context).pop(_editing ? book : true);
    } on DuplicateBookException {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _saveError = 'This book is already on your bookshelf.';
      });
    } on FirebaseException catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _saveError = error.message ?? 'Unable to save the book.';
      });
    }
  }
}

class DuplicateBookException implements Exception {
  const DuplicateBookException();
}

class BookDetailScreen extends StatefulWidget {
  const BookDetailScreen({super.key, required this.book});

  final Book book;

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  late bool _favorite;
  late String _documentId;
  Book? _latestBook;

  @override
  void initState() {
    super.initState();
    _favorite = widget.book.favorite;
    _documentId = widget.book.id;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Detail'),
        actions: [
          IconButton(
            onPressed: _toggleFavorite,
            tooltip: _favorite ? 'Remove favorite' : 'Add favorite',
            icon: Icon(
              _favorite ? Icons.star_rounded : Icons.star_outline,
              color: _favorite ? const Color(0xFFE5A627) : null,
            ),
          ),
          IconButton(
            onPressed: _edit,
            tooltip: 'Edit',
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            onPressed: _delete,
            tooltip: 'Delete',
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _books.doc(_documentId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Unable to load book details: ${snapshot.error}'),
              ),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.data?.exists != true) {
            return const Center(child: Text('No books found'));
          }
          final current = Book.fromDocument(snapshot.data!);
          _latestBook = current;
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8EFE8),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Icon(Icons.menu_book_rounded, size: 56),
              ),
              const SizedBox(height: 20),
              Text(
                current.title,
                style: Theme.of(context).textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                current.author,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 18),
              _DetailRow(label: 'Genre', value: current.genre),
              _DetailRow(label: 'Status', value: current.status),
              _DetailRow(
                label: 'Rating',
                value: current.rating?.toString() ?? 'Not rated',
              ),
              _DetailRow(
                label: 'Favorite',
                value: current.favorite ? 'Yes' : 'No',
              ),
              _DetailRow(
                label: 'Notes',
                value: current.notes.isEmpty ? 'No notes' : current.notes,
              ),
              const SizedBox(height: 14),
              FilledButton.tonalIcon(
                onPressed: _edit,
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Edit'),
              ),
              OutlinedButton.icon(
                onPressed: _delete,
                icon: const Icon(Icons.delete_outline),
                label: const Text('Delete'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _edit() async {
    final current = _latestBook ?? widget.book;
    final updatedBook = await Navigator.of(context).push<Book>(
      MaterialPageRoute<Book>(
        builder: (_) => BookFormScreen(userId: current.userId, book: current),
      ),
    );
    if (updatedBook != null && mounted) {
      setState(() {
        _documentId = updatedBook.id;
        _favorite = updatedBook.favorite;
        _latestBook = updatedBook;
      });
    }
  }

  Future<void> _toggleFavorite() async {
    try {
      final reference = _books.doc(_documentId);
      final document = await reference.get();
      final current = Book.fromDocument(document);
      final favorite = !current.favorite;
      await reference.update({'favorite': favorite});
      if (mounted) {
        setState(() {
          _favorite = favorite;
          _latestBook = Book(
            id: current.id,
            userId: current.userId,
            title: current.title,
            author: current.author,
            genre: current.genre,
            status: current.status,
            rating: current.rating,
            favorite: favorite,
            notes: current.notes,
            createdAt: current.createdAt,
          );
        });
      }
    } on FirebaseException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message ?? 'Unable to update favorite')),
      );
    }
  }

  Future<void> _delete() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete book?'),
        content: const Text('This book will be removed from your bookshelf.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (shouldDelete != true) return;
    try {
      await _books.doc(_documentId).delete();
      if (mounted) Navigator.of(context).pop();
    } on FirebaseException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message ?? 'Unable to delete the book')),
      );
    }
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge
                ?.copyWith(color: const Color(0xFF526359)),
          ),
          const SizedBox(height: 3),
          Text(value, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }
}
