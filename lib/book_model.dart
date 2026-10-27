import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

class Book {
  const Book({
    required this.id,
    required this.userId,
    required this.title,
    required this.author,
    required this.genre,
    required this.status,
    required this.favorite,
    required this.notes,
    required this.createdAt,
    this.rating,
  });

  final String id;
  final String userId;
  final String title;
  final String author;
  final String genre;
  final String status;
  final int? rating;
  final bool favorite;
  final String notes;
  final DateTime createdAt;

  factory Book.fromDocument(DocumentSnapshot<Map<String, dynamic>> document) {
    final data = document.data()!;
    final createdAt = data['createdAt'];
    return Book(
      id: document.id,
      userId: data['userId'] as String,
      title: data['title'] as String,
      author: data['author'] as String,
      genre: data['genre'] as String,
      status: data['status'] as String,
      rating: data['rating'] as int?,
      favorite: data['favorite'] as bool? ?? false,
      notes: data['notes'] as String? ?? '',
      createdAt: createdAt is Timestamp ? createdAt.toDate() : DateTime.now(),
    );
  }

  static String documentId(String userId, String title, String author) {
    final normalized =
        '${title.trim().toLowerCase()}\u0000'
        '${author.trim().toLowerCase()}';
    return '${userId}_${base64Url.encode(utf8.encode(normalized))}';
  }

  Map<String, Object?> toFirestore({bool useServerTimestamp = false}) {
    final data = <String, Object?>{
      'id': id,
      'userId': userId,
      'title': title.trim(),
      'author': author.trim(),
      'genre': genre,
      'status': status,
      'favorite': favorite,
      'notes': notes.trim(),
      'createdAt': useServerTimestamp
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(createdAt),
    };
    if (rating != null) data['rating'] = rating;
    return data;
  }
}
