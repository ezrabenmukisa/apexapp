import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:pdfx/pdfx.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/files/documents.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/snackbar.dart';
import '../../../../core/widgets/common.dart';
import '../bloc/document_viewer_cubit.dart';

/// Shows a receipt in the app: PDFs page by page (scroll and pinch to
/// zoom), images zoomable. Share and save are secondary actions.
class DocumentViewerPage extends StatelessWidget {
  const DocumentViewerPage({super.key, required this.doc});

  final DocumentRef doc;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => getIt<DocumentViewerCubit>(param1: doc)..load(),
    child: _DocumentViewerView(doc: doc),
  );
}

class _DocumentViewerView extends StatelessWidget {
  const _DocumentViewerView({required this.doc});

  final DocumentRef doc;

  @override
  Widget build(BuildContext context) =>
      BlocConsumer<DocumentViewerCubit, DocumentViewerState>(
        listenWhen: (a, b) => b.message != null && a.message != b.message,
        listener: (context, state) => context.showMessage(state.message!),
        builder: (context, state) {
          final cubit = context.read<DocumentViewerCubit>();
          final ready = state.file != null && !state.busy;
          return Scaffold(
            backgroundColor: AppColors.sunk,
            body: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    color: AppColors.surface,
                    padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
                    child: Row(
                      children: [
                        IconButton(
                          tooltip: 'Close',
                          onPressed: () => context.pop(),
                          icon: const Icon(Icons.close),
                        ),
                        Expanded(
                          child: Text(
                            doc.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.label.copyWith(fontSize: 15),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Share',
                          onPressed: ready ? cubit.share : null,
                          icon: const Icon(Icons.share_outlined),
                        ),
                        IconButton(
                          tooltip: 'Save to device',
                          onPressed: ready ? cubit.save : null,
                          icon: state.busy
                              ? const SizedBox.square(
                                  dimension: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.download_outlined),
                        ),
                      ],
                    ),
                  ),
                  const Divider(),
                  Expanded(child: _body(state, cubit)),
                ],
              ),
            ),
          );
        },
      );

  Widget _body(DocumentViewerState state, DocumentViewerCubit cubit) {
    final file = state.file;
    if (state.error != null) {
      return ErrorView(message: state.error!, onRetry: cubit.load);
    }
    if (file == null) return const LoadingView();
    if (doc.isPdf) return _PdfPages(file: file);
    if (doc.isImage) {
      return InteractiveViewer(
        maxScale: 6,
        child: Center(child: Image.file(file, fit: BoxFit.contain)),
      );
    }
    return const Center(
      child: EmptyState(
        icon: Icons.insert_drive_file_outlined,
        title: 'Preview not available',
        message: 'Use Share or Save to open it in another app.',
      ),
    );
  }
}

/// Every page of a PDF in one scrollable, pinch-to-zoom column, rendered by
/// the phone's own PDF engine (Android PdfRenderer / Apple PDFKit).
class _PdfPages extends StatefulWidget {
  const _PdfPages({required this.file});

  final File file;

  @override
  State<_PdfPages> createState() => _PdfPagesState();
}

class _PdfPagesState extends State<_PdfPages> {
  late final _controller = PdfControllerPinch(
    document: PdfDocument.openFile(widget.file.path),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PdfViewPinch(
    controller: _controller,
    padding: 12,
    maxScale: 6,
    backgroundDecoration: const BoxDecoration(color: AppColors.sunk),
    builders: PdfViewPinchBuilders<DefaultBuilderOptions>(
      options: const DefaultBuilderOptions(),
      documentLoaderBuilder: (_) => const LoadingView(),
      pageLoaderBuilder: (_) => const LoadingView(),
      errorBuilder: (_, _) => const Center(
        child: EmptyState(
          icon: Icons.picture_as_pdf_outlined,
          title: 'This PDF can\'t be shown',
          message: 'Use Share or Save to open it in another app.',
        ),
      ),
    ),
  );
}
