const bookGenres = ['Fiction', 'Non-Fiction', 'Academic', 'Other'];
const bookStatuses = ['To Read', 'Reading', 'Finished'];

String? validateBookTitle(String? value) {
  final title = value?.trim() ?? '';
  if (title.isEmpty) return 'Title is required';
  if (title.length > 100) return 'Title must be at most 100 characters';
  return null;
}

String? validateBookAuthor(String? value) {
  final author = value?.trim() ?? '';
  if (author.isEmpty) return 'Author is required';
  if (author.length > 60) return 'Author must be at most 60 characters';
  return null;
}

String? validateBookGenre(String? value) =>
    bookGenres.contains(value) ? null : 'Please choose a genre';

String? validateBookStatus(String? value) =>
    bookStatuses.contains(value) ? null : 'Please choose a status';

String? validateBookRating(String? value) {
  final rating = value?.trim() ?? '';
  if (rating.isEmpty) return null;
  final number = int.tryParse(rating);
  if (number == null || number < 0 || number > 5) {
    return 'Rating must be a whole number from 0 to 5';
  }
  return null;
}

String? validateBookNotes(String? value) =>
    (value?.length ?? 0) > 300 ? 'Notes must be at most 300 characters' : null;

String? validateEmail(String? value) {
  final email = value?.trim() ?? '';
  if (email.isEmpty) return 'Email is required';
  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
    return 'Please enter a valid email address';
  }
  return null;
}

String? validatePassword(String? value, {bool requireMinimumLength = false}) {
  final password = value ?? '';
  if (password.isEmpty) return 'Password is required';
  if (requireMinimumLength && password.length < 6) {
    return 'Password must be at least 6 characters';
  }
  return null;
}

String? validatePasswordConfirmation(String? value, String password) {
  if (value == null || value.isEmpty) return 'Confirm password is required';
  if (value != password) return 'Passwords do not match';
  return null;
}
