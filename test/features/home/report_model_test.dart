/// Unit tests for the home models: the JSON mapping of a
/// report row (with its embedded relations) and the grouping of
/// a flat comment list into a tree.
///
/// These tests pin the Supabase select shape: if the query in
/// `SupabaseHomeRemoteDataSource` changes, these tests fail
/// first — before any widget or Cubit test.
library;

import 'package:baytari/features/home/data/models/report_comment_model.dart';
import 'package:baytari/features/home/data/models/report_model.dart';
import 'package:baytari/features/home/domain/entities/report_enums.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ReportModel maps a full embedded row', () {
    final model = ReportModel.fromJson(
      <String, dynamic>{
        'id': 'r1',
        'author': <String, dynamic>{
          'id': 'u1',
          'full_name': 'Merhan Assem',
          'username': 'merhan',
          'avatar_url': 'https://example.com/a.jpg',
        },
        'category': 'stray',
        'priority': 'high',
        'animal_type': 'dog',
        'description': 'A small brown dog',
        'location_text': '45 Nile Street, Cairo',
        'latitude': 30.05,
        'longitude': 31.25,
        'created_at': '2026-11-13T10:00:00Z',
        'report_photos': <Map<String, dynamic>>[
          <String, dynamic>{
            'storage_path': 'u1/1_0.jpg',
            'position': 1,
          },
          <String, dynamic>{
            'storage_path': 'u1/1_1.jpg',
            'position': 0,
          },
        ],
        'report_helpers': <Map<String, dynamic>>[
          <String, dynamic>{'user_id': 'me'},
          <String, dynamic>{'user_id': 'u2'},
        ],
        'report_comments': <Map<String, dynamic>>[
          <String, dynamic>{'id': 'c1'},
        ],
        'report_statuses': <Map<String, dynamic>>[
          <String, dynamic>{'user_id': 'me', 'status': 'sighted'},
        ],
      },
      currentUserId: 'me',
      photoUrlFor: (path) => 'https://cdn.example.com/$path',
    );

    expect(model.author.displayName, 'Merhan Assem');
    expect(model.category, ReportCategory.stray);
    expect(model.priority, ReportPriority.high);
    // Photos are ordered by `position`, not by row order, and
    // the storage paths became public URLs.
    expect(model.photoUrls, <String>[
      'https://cdn.example.com/u1/1_1.jpg',
      'https://cdn.example.com/u1/1_0.jpg',
    ]);
    // Counts are the embedded lists' lengths.
    expect(model.helpersCount, 2);
    expect(model.commentsCount, 1);
    // The current user is a helper and set a status.
    expect(model.isHelper, isTrue);
    expect(model.myStatus, ReportStatus.sighted);
  });

  test('ReportModel tolerates a missing author and no relations', () {
    final model = ReportModel.fromJson(
      <String, dynamic>{
        'id': 'r2',
        'category': 'adoption',
        'priority': 'low',
        'animal_type': 'cat',
        'description': 'Kittens',
      },
    );
    expect(model.author.displayName, '');
    expect(model.photoUrls, isEmpty);
    expect(model.helpersCount, 0);
    expect(model.isHelper, isFalse);
    expect(model.myStatus, isNull);
  });

  test('ReportModel falls back on unknown enum strings', () {
    final model = ReportModel.fromJson(
      <String, dynamic>{
        'id': 'r3',
        'category': 'weird',
        'priority': 'weird',
        'animal_type': 'weird',
        'description': 'x',
      },
    );
    expect(model.category, ReportCategory.stray);
    expect(model.priority, ReportPriority.mid);
    expect(model.animalType, AnimalType.other);
  });

  test('ReportCommentModel groups one level of replies', () {
    final flat = <ReportCommentModel>[
      ReportCommentModel.fromJson(
        <String, dynamic>{
          'id': 'c1',
          'report_id': 'r1',
          'author': <String, dynamic>{
            'id': 'u1',
            'full_name': 'Adam Ali',
          },
          'body': 'On my way.',
          'parent_id': null,
          'status': null,
          'comment_likes': <Map<String, dynamic>>[
            <String, dynamic>{'user_id': 'me'},
          ],
        },
        currentUserId: 'me',
      ),
      ReportCommentModel.fromJson(
        <String, dynamic>{
          'id': 'c2',
          'report_id': 'r1',
          'author': <String, dynamic>{
            'id': 'u2',
            'full_name': 'Maha K',
          },
          'body': 'Great job!',
          'parent_id': null,
          'status': 'rescued',
          'comment_likes': <dynamic>[],
        },
      ),
      ReportCommentModel.fromJson(
        <String, dynamic>{
          'id': 'c3',
          'report_id': 'r1',
          'author': <String, dynamic>{
            'id': 'u3',
            'full_name': 'Sam Leo',
          },
          'body': 'Agreed!',
          'parent_id': 'c2',
          'status': null,
          'comment_likes': <dynamic>[],
        },
      ),
    ];
    final grouped = ReportCommentModel.groupReplies(flat);
    expect(grouped.map((c) => c.id), <String>['c1', 'c2']);
    expect(grouped[0].likeCount, 1);
    expect(grouped[0].likedByMe, isTrue);
    expect(grouped[1].status, ReportStatus.rescued);
    expect(grouped[1].replies.map((c) => c.id), <String>['c3']);
  });
}
