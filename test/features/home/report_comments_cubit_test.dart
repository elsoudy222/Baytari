/// Unit tests for [ReportCommentsCubit] and [CreateReportCubit].
///
/// Same pattern as the feed tests: real use cases, fake
/// repository, no Supabase, no widgets.
library;

import 'dart:typed_data';

import 'package:baytari/core/errors/failures.dart';
import 'package:baytari/features/home/domain/entities/report_comment.dart';
import 'package:baytari/features/home/domain/entities/report_enums.dart';
import 'package:baytari/features/home/domain/usecases/add_comment_usecase.dart';
import 'package:baytari/features/home/domain/usecases/create_report_usecase.dart';
import 'package:baytari/features/home/domain/usecases/get_comments_usecase.dart';
import 'package:baytari/features/home/domain/usecases/get_report_usecase.dart';
import 'package:baytari/features/home/domain/usecases/set_report_status_usecase.dart';
import 'package:baytari/features/home/domain/usecases/toggle_comment_like_usecase.dart';
import 'package:baytari/features/home/presentation/cubit/create_report_cubit.dart';
import 'package:baytari/features/home/presentation/cubit/create_report_state.dart';
import 'package:baytari/features/home/presentation/cubit/report_comments_cubit.dart';
import 'package:baytari/features/home/presentation/cubit/report_comments_state.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_home_repository.dart';

void main() {
  group('ReportCommentsCubit', () {
    late FakeHomeRepository repository;
    late ReportCommentsCubit cubit;

    setUp(() {
      repository = FakeHomeRepository()
        ..reportToReturn = testReport(helpersCount: 18)
        ..commentsToReturn = <ReportComment>[
          testComment(id: 'c1', body: 'On my way.'),
          testComment(
            id: 'c2',
            body: 'Great job reporting this!',
            replies: <ReportComment>[
              testComment(id: 'c2r1', parentId: 'c2', body: 'Agreed!'),
            ],
          ),
        ];
      cubit = ReportCommentsCubit(
        getReportUseCase: GetReportUseCase(repository),
        getCommentsUseCase: GetCommentsUseCase(repository),
        addCommentUseCase: AddCommentUseCase(repository),
        toggleCommentLikeUseCase: ToggleCommentLikeUseCase(repository),
        setReportStatusUseCase: SetReportStatusUseCase(repository),
      );
    });

    tearDown(() async {
      await cubit.close();
    });

    test('load reaches loaded with report and comments', () async {
      await cubit.load('report-1');
      expect(cubit.state.status, ReportCommentsStatus.loaded);
      expect(cubit.state.report?.helpersCount, 18);
      expect(cubit.state.comments.map((c) => c.id), <String>['c1', 'c2']);
      expect(cubit.state.comments[1].replies.length, 1);
    });

    test('load failure reaches failure', () async {
      repository.failure = const ServerFailure('boom');
      await cubit.load('report-1');
      expect(cubit.state.status, ReportCommentsStatus.failure);
      expect(cubit.state.errorMessage, 'boom');
    });

    test('postComment appends a top-level comment', () async {
      await cubit.load('report-1');
      await cubit.postComment('I can help tomorrow.');
      expect(cubit.state.comments.length, 3);
      expect(cubit.state.comments.last.body, 'I can help tomorrow.');
      expect(cubit.state.isPosting, isFalse);
    });

    test('postComment with a reply target nests under the parent',
        () async {
      await cubit.load('report-1');
      final parent = cubit.state.comments[0];
      cubit.setReplyingTo(parent);
      await cubit.postComment('Thank you!');
      expect(cubit.state.comments[0].replies.length, 1);
      expect(cubit.state.comments[0].replies.first.body, 'Thank you!');
      expect(cubit.state.replyingTo, isNull);
    });

    test('postComment failure keeps the reply target for retry',
        () async {
      await cubit.load('report-1');
      cubit.setReplyingTo(cubit.state.comments[0]);
      repository.failure = const ServerFailure('boom');
      await cubit.postComment('Thank you!');
      expect(cubit.state.comments[0].replies, isEmpty);
      expect(cubit.state.replyingTo, isNotNull);
      expect(cubit.state.errorMessage, 'boom');
    });

    test('toggleLike flips label and count on top and nested comments',
        () async {
      await cubit.load('report-1');
      await cubit.toggleLike('c1');
      expect(cubit.state.comments[0].likedByMe, isTrue);
      expect(cubit.state.comments[0].likeCount, 1);
      await cubit.toggleLike('c2r1');
      expect(cubit.state.comments[1].replies.first.likedByMe, isTrue);
    });

    test('setStatus updates the report status for the chips',
        () async {
      await cubit.load('report-1');
      await cubit.setStatus(ReportStatus.sighted);
      expect(cubit.state.report?.myStatus, ReportStatus.sighted);
    });
  });

  group('CreateReportCubit', () {
    late FakeHomeRepository repository;
    late CreateReportCubit cubit;

    setUp(() {
      repository = FakeHomeRepository();
      cubit = CreateReportCubit(
        createReportUseCase: CreateReportUseCase(repository),
      );
    });

    tearDown(() async {
      await cubit.close();
    });

    test('submit without choices fails validation, no network call',
        () async {
      cubit.setDescription('A brown dog');
      await cubit.submit();
      expect(cubit.state.status, CreateReportStatus.failure);
      expect(cubit.state.errorMessage, 'formIncomplete');
      expect(repository.calls, isNot(contains('createReport')));
    });

    test('submit without description fails validation', () async {
      cubit
        ..selectCategory(ReportCategory.stray)
        ..selectPriority(ReportPriority.high)
        ..selectAnimalType(AnimalType.dog);
      await cubit.submit();
      expect(cubit.state.status, CreateReportStatus.failure);
      expect(cubit.state.errorMessage, 'descriptionRequired');
      expect(repository.calls, isNot(contains('createReport')));
    });

    test('submit with a complete form succeeds', () async {
      cubit
        ..selectCategory(ReportCategory.stray)
        ..selectPriority(ReportPriority.urgent)
        ..selectAnimalType(AnimalType.cat)
        ..setDescription('Orange cat under a bench')
        ..setLocationText('14 Dam Street, Aswan');
      await cubit.submit();
      expect(cubit.state.status, CreateReportStatus.success);
      expect(repository.calls, contains('createReport'));
    });

    test('submit failure surfaces the server message', () async {
      repository.failure = const ServerFailure('boom');
      cubit
        ..selectCategory(ReportCategory.stray)
        ..selectPriority(ReportPriority.high)
        ..selectAnimalType(AnimalType.dog)
        ..setDescription('A brown dog');
      await cubit.submit();
      expect(cubit.state.status, CreateReportStatus.failure);
      expect(cubit.state.errorMessage, 'boom');
    });

    test('addPhotos and removePhoto manage the photo list', () {
      cubit.addPhotos(<Uint8List>[Uint8List(3), Uint8List(3)]);
      expect(cubit.state.photos.length, 2);
      cubit.removePhoto(0);
      expect(cubit.state.photos.length, 1);
    });
  });
}
