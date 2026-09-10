// features/fuel_station/services/favorite_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fuelwisee/features/fuel_station/models/favourite_model.dart';


class FavoriteService {
  final SupabaseClient _supabase = Supabase.instance.client;


  Future<List<Favorite>> getFavorites() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    final response = await _supabase
        .from('favourite_stations')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    return (response as List<dynamic>)
        .map((e) => Favorite.fromJson(e as Map<String, dynamic>))
        .toList();
  }


  Future<void> addFavorite(Favorite favorite) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    await _supabase.from('favourite_stations').insert({
      'user_id': user.id,
      'place_id': favorite.placeId,
      'station_name': favorite.stationName,
      'station_address': favorite.stationAddress,
      'latitude': favorite.latitude,
      'longitude': favorite.longitude,
      'custom_name': favorite.customName,
      'note': favorite.note,
    });
  }


  Future<void> removeFavorite(String placeId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    await _supabase
        .from('favourite_stations')
        .delete()
        .eq('user_id', user.id)
        .eq('place_id', placeId);
  }


  Future<void> updateFavorite(Favorite favorite) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    await _supabase
        .from('favourite_stations')
        .update({
      'custom_name': favorite.customName,
      'note': favorite.note,
    })
        .eq('user_id', user.id)
        .eq('place_id', favorite.placeId);
  }


  Future<bool> isFavorite(String placeId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return false;

    final response = await _supabase
        .from('favourite_stations')
        .select('id')
        .eq('user_id', user.id)
        .eq('place_id', placeId)
        .maybeSingle();

    return response != null;
  }


  Future<Favorite?> getFavorite(String placeId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    final response = await _supabase
        .from('favourite_stations')
        .select()
        .eq('user_id', user.id)
        .eq('place_id', placeId)
        .maybeSingle();

    if (response == null) return null;
    return Favorite.fromJson(response as Map<String, dynamic>);
  }
}