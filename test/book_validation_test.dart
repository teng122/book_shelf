import 'package:flutter_test/flutter_test.dart';
import 'package:bookshelf/book_validation.dart';

void main() {
  group('book field validation', () {
    test('requires a non-blank title and applies the title limit', () {
      expect(validateBookTitle('   '), 'Title is required');
      expect(validateBookTitle('A' * 100), isNull);
      expect(
        validateBookTitle('A' * 101),
        'Title must be at most 100 characters',
      );
    });

    test('requires a non-blank author and applies the author limit', () {
      expect(validateBookAuthor(' \t '), 'Author is required');
      expect(validateBookAuthor('A' * 60), isNull);
      expect(
        validateBookAuthor('A' * 61),
        'Author must be at most 60 characters',
      );
    });

    test('accepts only listed genres and statuses', () {
      expect(validateBookGenre(null), 'Please choose a genre');
      expect(validateBookGenre('Fiction'), isNull);
      expect(validateBookGenre('Romance'), 'Please choose a genre');
      expect(validateBookStatus(null), 'Please choose a status');
      expect(validateBookStatus('Finished'), isNull);
      expect(validateBookStatus('Paused'), 'Please choose a status');
    });

    test(
      'rating is optional but must be an integer from zero through five',
      () {
        expect(validateBookRating(''), isNull);
        expect(validateBookRating('0'), isNull);
        expect(validateBookRating('5'), isNull);
        expect(
          validateBookRating('2.5'),
          'Rating must be a whole number from 0 to 5',
        );
        expect(
          validateBookRating('6'),
          'Rating must be a whole number from 0 to 5',
        );
      },
    );

    test('notes are limited to 300 characters', () {
      expect(validateBookNotes('N' * 300), isNull);
      expect(
        validateBookNotes('N' * 301),
        'Notes must be at most 300 characters',
      );
    });
  });

  group('authentication field validation', () {
    test('validates required and well-formed email addresses', () {
      expect(validateEmail(''), 'Email is required');
      expect(
        validateEmail('not-an-email'),
        'Please enter a valid email address',
      );
      expect(validateEmail('reader@example.com'), isNull);
    });

    test('checks password length only for registration', () {
      expect(validatePassword(''), 'Password is required');
      expect(
        validatePassword('12345', requireMinimumLength: true),
        'Password must be at least 6 characters',
      );
      expect(validatePassword('12345'), isNull);
    });

    test('validates password confirmation', () {
      expect(
        validatePasswordConfirmation('', 'secret'),
        'Confirm password is required',
      );
      expect(
        validatePasswordConfirmation('different', 'secret'),
        'Passwords do not match',
      );
      expect(validatePasswordConfirmation('secret', 'secret'), isNull);
    });
  });
}
