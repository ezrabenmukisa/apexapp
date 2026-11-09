import 'dart:io';

import 'package:app/core/files/documents.dart';
import 'package:app/features/evidence/presentation/bloc/document_viewer_cubit.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockCache extends Mock implements DocumentCache {}

class _MockActions extends Mock implements DocumentActions {}

void main() {
  late _MockCache cache;
  late _MockActions actions;
  final doc = DocumentRef.fromUrl('https://s3.test/r/invoice.pdf?sig=1');
  final file = File('/tmp/invoice.pdf');

  setUpAll(() {
    registerFallbackValue(doc);
    registerFallbackValue(file);
  });

  setUp(() {
    cache = _MockCache();
    actions = _MockActions();
  });

  DocumentViewerCubit build() => DocumentViewerCubit(doc, cache, actions);

  blocTest<DocumentViewerCubit, DocumentViewerState>(
    'loads the file for the viewer',
    build: build,
    setUp: () => when(() => cache.fetch(doc)).thenAnswer((_) async => file),
    act: (cubit) => cubit.load(),
    expect: () => [
      const DocumentViewerState(),
      DocumentViewerState(file: file),
    ],
  );

  blocTest<DocumentViewerCubit, DocumentViewerState>(
    'a download problem shows its explanation (with retry)',
    build: build,
    setUp: () => when(
      () => cache.fetch(doc),
    ).thenThrow(const DocumentException('This link has expired.')),
    act: (cubit) => cubit.load(),
    skip: 1,
    expect: () => [const DocumentViewerState(error: 'This link has expired.')],
  );

  blocTest<DocumentViewerCubit, DocumentViewerState>(
    'save confirms where it went; cancelling says nothing',
    build: build,
    seed: () => DocumentViewerState(file: file),
    setUp: () {
      var calls = 0;
      when(() => actions.save(file, doc)).thenAnswer((_) async => ++calls == 1);
    },
    act: (cubit) async {
      await cubit.save();
      await cubit.save();
    },
    expect: () => [
      DocumentViewerState(file: file, busy: true),
      DocumentViewerState(file: file, message: 'Saved invoice.pdf.'),
      DocumentViewerState(file: file, busy: true),
      DocumentViewerState(file: file),
    ],
  );

  blocTest<DocumentViewerCubit, DocumentViewerState>(
    'share opens the system share sheet with the file',
    build: build,
    seed: () => DocumentViewerState(file: file),
    setUp: () => when(() => actions.share(file, doc)).thenAnswer((_) async {}),
    act: (cubit) => cubit.share(),
    verify: (_) => verify(() => actions.share(file, doc)).called(1),
  );

  blocTest<DocumentViewerCubit, DocumentViewerState>(
    'nothing to share before the file is ready',
    build: build,
    act: (cubit) => cubit.share(),
    expect: () => <DocumentViewerState>[],
    verify: (_) => verifyNever(() => actions.share(any(), any())),
  );
}
