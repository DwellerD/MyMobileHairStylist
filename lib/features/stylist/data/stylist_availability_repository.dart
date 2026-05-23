import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_client_provider.dart';
import '../../auth/domain/app_user.dart';
import '../domain/availability_models.dart';
import '../domain/stylist_models.dart';

/// Provides the stylist availability repository.
final stylistAvailabilityRepositoryProvider =
    Provider<StylistAvailabilityRepository>((ref) {
  return StylistAvailabilityRepository(ref.watch(supabaseClientProvider));
});

/// Manages CRUD operations on a stylist's availability_blocks rows.
class StylistAvailabilityRepository {
  StylistAvailabilityRepository(this._client);

  final SupabaseClient? _client;

  /// Load all availability blocks for this stylist within a date range.
  ///
  /// Returns blocks ordered by start_at ascending.
  Future<List<AvailabilityBlock>> loadAvailabilityBlocks({
    required String stylistProfileId,
    required DateTime rangeStart,
    required DateTime rangeEnd,
  }) async {
    final response = await _requireClient()
        .from('availability_blocks')
        .select('id, stylist_profile_id, block_type, start_at, end_at, notes, market_id, territory_id')
        .eq('stylist_profile_id', stylistProfileId)
        .gte('start_at', rangeStart.toUtc().toIso8601String())
        .lt('start_at', rangeEnd.toUtc().toIso8601String())
        .order('start_at');

    return (response as List<dynamic>)
        .map((dynamic row) => _mapBlock(row as Map<String, dynamic>))
        .toList(growable: false);
  }

  /// Create a new availability block.
  ///
  /// [blockType] must be one of: 'available', 'unavailable', 'time_off'.
  Future<AvailabilityBlock> createAvailabilityBlock({
    required AppUser appUser,
    required StylistProfileSummary stylistProfile,
    required String blockType,
    required DateTime startAt,
    required DateTime endAt,
    String? notes,
  }) async {
    if (!endAt.isAfter(startAt)) {
      throw Exception('End time must be after start time.');
    }

    final response = await _requireClient()
        .from('availability_blocks')
        .insert({
          'stylist_profile_id': stylistProfile.id,
          'market_id': stylistProfile.marketId,
          'territory_id': stylistProfile.territoryId,
          'block_type': blockType,
          'start_at': startAt.toUtc().toIso8601String(),
          'end_at': endAt.toUtc().toIso8601String(),
          'notes': _nullableText(notes),
        })
        .select('id, stylist_profile_id, block_type, start_at, end_at, notes, market_id, territory_id')
        .single();

      return _mapBlock(response);
  }

  /// Update an existing availability block's time range, type, or notes.
  Future<AvailabilityBlock> updateAvailabilityBlock({
    required String blockId,
    required String blockType,
    required DateTime startAt,
    required DateTime endAt,
    String? notes,
  }) async {
    if (!endAt.isAfter(startAt)) {
      throw Exception('End time must be after start time.');
    }

    final response = await _requireClient()
        .from('availability_blocks')
        .update({
          'block_type': blockType,
          'start_at': startAt.toUtc().toIso8601String(),
          'end_at': endAt.toUtc().toIso8601String(),
          'notes': _nullableText(notes),
        })
        .eq('id', blockId)
        .select('id, stylist_profile_id, block_type, start_at, end_at, notes, market_id, territory_id')
        .single();

      return _mapBlock(response);
  }

  /// Permanently delete an availability block.
  Future<void> deleteAvailabilityBlock({required String blockId}) async {
    await _requireClient()
        .from('availability_blocks')
        .delete()
        .eq('id', blockId);
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Private helpers
  // ──────────────────────────────────────────────────────────────────────────

  AvailabilityBlock _mapBlock(Map<String, dynamic> row) {
    return AvailabilityBlock(
      id: row['id'] as String,
      stylistProfileId: row['stylist_profile_id'] as String,
      blockType: row['block_type'] as String,
      startAt: DateTime.parse(row['start_at'] as String).toLocal(),
      endAt: DateTime.parse(row['end_at'] as String).toLocal(),
      notes: row['notes'] as String?,
      marketId: row['market_id'] as String?,
      territoryId: row['territory_id'] as String?,
    );
  }

  SupabaseClient _requireClient() {
    if (_client == null) {
      throw Exception(
        'Supabase is not configured. Add SUPABASE_URL and SUPABASE_ANON_KEY before testing availability.',
      );
    }
    return _client;
  }

  String? _nullableText(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    return value.trim();
  }
}
