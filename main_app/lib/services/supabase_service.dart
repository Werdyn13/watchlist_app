import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  final client = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getMoviesPage({
    required int offset,
    required int limit,
    required String filter,
    required String search,
  }) async {
    var query = client.from('movies').select();

    if (filter == 'film' || filter == 'serial') {
      query = query.eq('type', filter.capitalize());
    } else if (filter == 'watched') {
      query = query.eq('watched', true);
    }

    if (search.isNotEmpty) {
      query = query.ilike('title', '%$search%');
    }

    final data = await query
        .order('watched', ascending: false)
        .order('id', ascending: false)
        .range(offset, offset + limit - 1);

    return List<Map<String, dynamic>>.from(data as List);
  }

  Future<void> addMovie(Map<String, dynamic> movie) =>
      client.from('movies').insert(movie);

  Future<void> updateMovie(int id, Map<String, dynamic> movie) =>
      client.from('movies').update(movie).eq('id', id);

  Future<void> deleteMovie(int id) =>
      client.from('movies').delete().eq('id', id);

  Future<void> toggleWatched(int id, bool current) =>
      client.from('movies').update({'watched': !current}).eq('id', id);
}

extension StringCasingExtension on String {
  String capitalize() => length > 0 ? '${this[0].toUpperCase()}${substring(1).toLowerCase()}' : '';
}