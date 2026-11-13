/// Supabase implementation of [HomeRemoteDataSource].
///
/// This is the ONLY file in the home feature that imports
/// Supabase. Everything above it (repository, use cases, Cubit,
/// UI) works with plain [ReportModel]/[ReportCommentModel]
/// objects and never sees a Supabase type — that is the Clean
/// Architecture boundary.
///
/// The Supabase import is prefixed (`supabase.`) on purpose:
/// the Supabase package also has a class called `AuthException`,
/// and the app has its own in `core/errors/exceptions.dart`.
///
/// QUERY SHAPE: every read embeds the relations in ONE query
/// (author + photos + helpers + comments + statuses), so the
/// feed never does N+1 queries — one round-trip per screen.
/// Counts are the embedded lists' lengths (see [ReportModel]).
library;

import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../../../../core/errors/exceptions.dart';
import '../../../../core/services/supabase_service.dart';
import '../../domain/entities/report_enums.dart';
import '../models/report_comment_model.dart';
import '../models/report_model.dart';
import 'home_remote_data_source.dart';

class SupabaseHomeRemoteDataSource implements HomeRemoteDataSource {
  SupabaseHomeRemoteDataSource(this._supabaseService);

  final SupabaseService _supabaseService;

  /// The client. Throws [SupabaseNotConfiguredException] when the
  /// app was started without `--dart-define` keys — the
  /// repository turns that into a [NotConfiguredFailure] and the
  /// UI shows the demo-mode message instead of crashing.
  supabase.SupabaseClient get _client => _supabaseService.client;

  /// The id of the signed-in user (null for guests). Guests can
  /// read the feed, but they have no helper/status/like state.
  String? get _currentUserId => _client.auth.currentUser?.id;

  /// One select string for reports, reused by every read: the
  /// report row + author profile + photos + the three relation
  /// lists the model counts from. `author:profiles!author_id`
  /// follows the `author_id` foreign key to the profiles table.
  static const String _reportSelect =
      '*, '
      'author:profiles!author_id(id, full_name, username, avatar_url), '
      'report_photos(storage_path, position), '
      'report_helpers(user_id), '
      'report_comments(id), '
      'report_statuses(user_id, status)';

  /// One select string for comments: the comment row + author
  /// profile + the likes list the model counts from.
  static const String _commentSelect =
      '*, '
      'author:profiles!author_id(id, full_name, username, avatar_url), '
      'comment_likes(user_id)';

  static const String _bucket = 'report-photos';

  /// Public URL of a photo in the `report-photos` bucket (the
  /// bucket is public, so no signed URL is needed).
  String _photoUrl(String path) =>
      _client.storage.from(_bucket).getPublicUrl(path);

  /// Runs [fn] and converts every Supabase error into an
  /// [AppException] the repository can map: Postgrest / Storage
  /// errors become [ServerException], an [AppException] passes
  /// through unchanged (e.g. "not configured", "no signed-in
  /// user"), anything else becomes a [ServerException] so the
  /// Cubit never sees a raw framework type.
  Future<T> _guard<T>(Future<T> Function() fn) async {
    try {
      return await fn();
    } on AppException {
      rethrow;
    } on supabase.PostgrestException catch (e) {
      throw ServerException(e.message);
    } on supabase.StorageException catch (e) {
      throw ServerException(e.message);
    } on Exception catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<ReportModel>> getReports({ReportCategory? category}) {
    return _guard(() async {
      var query = _client.from('reports').select(_reportSelect);
      if (category != null) {
        query = query.eq('category', category.value);
      }
      final List<dynamic> rows = await query.order(
        'created_at',
        ascending: false,
      );
      return rows
          .whereType<Map<String, dynamic>>()
          .map(
            (row) => ReportModel.fromJson(
              row,
              currentUserId: _currentUserId,
              photoUrlFor: _photoUrl,
            ),
          )
          .toList();
    });
  }

  @override
  Future<ReportModel> getReport(String reportId) {
    return _guard(() async {
      final Map<String, dynamic>? row = await _client
          .from('reports')
          .select(_reportSelect)
          .eq('id', reportId)
          .maybeSingle();
      if (row == null) {
        throw const ServerException('Report not found.');
      }
      return ReportModel.fromJson(
        row,
        currentUserId: _currentUserId,
        photoUrlFor: _photoUrl,
      );
    });
  }

  @override
  Future<ReportModel> createReport({
    required ReportCategory category,
    required ReportPriority priority,
    required AnimalType animalType,
    required String description,
    String? locationText,
    List<Uint8List> photos = const <Uint8List>[],
  }) {
    return _guard(() async {
      final String? userId = _currentUserId;
      if (userId == null) {
        throw const AuthException('No signed-in user.');
      }
      // Photos are uploaded FIRST (their paths do not depend on
      // the report id — they use a timestamp), so a failed upload
      // fails the whole creation before any row exists.
      final int timestamp = DateTime.now().millisecondsSinceEpoch;
      final List<String> paths = <String>[];
      for (int i = 0; i < photos.length; i++) {
        final String path = '$userId/${timestamp}_$i.jpg';
        await _client.storage
            .from(_bucket)
            .uploadBinary(
              path,
              photos[i],
              fileOptions: const supabase.FileOptions(
                contentType: 'image/jpeg',
                upsert: true,
              ),
            );
        paths.add(path);
      }
      // Then the report row itself...
      final Map<String, dynamic> row = await _client
          .from('reports')
          .insert(<String, dynamic>{
            'author_id': userId,
            'category': category.value,
            'priority': priority.value,
            'animal_type': animalType.value,
            'description': description,
            'location_text': locationText,
          })
          .select(_reportSelect)
          .single();
      final String reportId = row['id'] as String;
      // ...and the photo rows that link the uploads to it.
      if (paths.isNotEmpty) {
        await _client.from('report_photos').insert(
          <Map<String, dynamic>>[
            for (int i = 0; i < paths.length; i++)
              <String, dynamic>{
                'report_id': reportId,
                'storage_path': paths[i],
                'position': i,
              },
          ],
        );
      }
      // Re-read the report so the returned model has its photos
      // (as public URLs) and counts, like every other read.
      return getReport(reportId);
    });
  }

  @override
  Future<bool> toggleHelper(String reportId) {
    return _guard(() async {
      final String? userId = _currentUserId;
      if (userId == null) {
        throw const AuthException('No signed-in user.');
      }
      // Is there already a helper row for this user? If yes,
      // "Help" is on — pressing again deletes it (toggle off).
      final Map<String, dynamic>? existing = await _client
          .from('report_helpers')
          .select('user_id')
          .eq('report_id', reportId)
          .eq('user_id', userId)
          .maybeSingle();
      if (existing != null) {
        await _client
            .from('report_helpers')
            .delete()
            .eq('report_id', reportId)
            .eq('user_id', userId);
        return false;
      }
      await _client.from('report_helpers').insert(<String, dynamic>{
        'report_id': reportId,
        'user_id': userId,
      });
      return true;
    });
  }

  @override
  Future<ReportStatus> setReportStatus(
    String reportId,
    ReportStatus status,
  ) {
    return _guard(() async {
      final String? userId = _currentUserId;
      if (userId == null) {
        throw const AuthException('No signed-in user.');
      }
      // Upsert on the (report_id, user_id) primary key: one row
      // per user per report, always the latest status.
      await _client.from('report_statuses').upsert(
        <String, dynamic>{
          'report_id': reportId,
          'user_id': userId,
          'status': status.value,
        },
        onConflict: 'report_id,user_id',
      );
      return status;
    });
  }

  @override
  Future<List<ReportCommentModel>> getComments(String reportId) {
    return _guard(() async {
      final List<dynamic> rows = await _client
          .from('report_comments')
          .select(_commentSelect)
          .eq('report_id', reportId)
          .order('created_at', ascending: true);
      return rows
          .whereType<Map<String, dynamic>>()
          .map(
            (row) => ReportCommentModel.fromJson(
              row,
              currentUserId: _currentUserId,
            ),
          )
          .toList();
    });
  }

  @override
  Future<ReportCommentModel> addComment({
    required String reportId,
    required String body,
    String? parentId,
  }) {
    return _guard(() async {
      final String? userId = _currentUserId;
      if (userId == null) {
        throw const AuthException('No signed-in user.');
      }
      // The comment stores the user's CURRENT status on this
      // report (if any) — that is what colours its bubble and
      // labels it in Figma ("Sighted", "Rescued", ...).
      final Map<String, dynamic>? statusRow = await _client
          .from('report_statuses')
          .select('status')
          .eq('report_id', reportId)
          .eq('user_id', userId)
          .maybeSingle();
      final Map<String, dynamic> row = await _client
          .from('report_comments')
          .insert(<String, dynamic>{
            'report_id': reportId,
            'author_id': userId,
            'parent_id': parentId,
            'body': body,
            'status': statusRow?['status'] as String?,
          })
          .select(_commentSelect)
          .single();
      return ReportCommentModel.fromJson(
        row,
        currentUserId: userId,
      );
    });
  }

  @override
  Future<bool> toggleCommentLike(String commentId) {
    return _guard(() async {
      final String? userId = _currentUserId;
      if (userId == null) {
        throw const AuthException('No signed-in user.');
      }
      final Map<String, dynamic>? existing = await _client
          .from('comment_likes')
          .select('user_id')
          .eq('comment_id', commentId)
          .eq('user_id', userId)
          .maybeSingle();
      if (existing != null) {
        await _client
            .from('comment_likes')
            .delete()
            .eq('comment_id', commentId)
            .eq('user_id', userId);
        return false;
      }
      await _client.from('comment_likes').insert(<String, dynamic>{
        'comment_id': commentId,
        'user_id': userId,
      });
      return true;
    });
  }
}
