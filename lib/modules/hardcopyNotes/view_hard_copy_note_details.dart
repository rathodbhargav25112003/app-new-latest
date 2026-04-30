// ignore_for_file: deprecated_member_use, unused_import

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../helpers/app_tokens.dart';
import '../../helpers/colors.dart';
import 'model/get_all_book_model.dart';

/// View notes / book details — redesigned with AppTokens. Constructor,
/// static route arguments contract preserved.
class ViewHardCopyNoteDetailsScreen extends StatefulWidget {
  final GetAllBookModel getBookSub;
  const ViewHardCopyNoteDetailsScreen({super.key, required this.getBookSub});

  @override
  State<ViewHardCopyNoteDetailsScreen> createState() =>
      _ViewHardCopyNoteDetailsScreenState();

  static Route<dynamic> route(RouteSettings routeSettings) {
    final arguments = routeSettings.arguments as Map<String, dynamic>;
    return CupertinoPageRoute(
      builder: (_) => ViewHardCopyNoteDetailsScreen(
        getBookSub: arguments['bookDetails'],
      ),
    );
  }
}

class _ViewHardCopyNoteDetailsScreenState
    extends State<ViewHardCopyNoteDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    final notes = widget.getBookSub.notesOverview ?? [];
    return Scaffold(
      backgroundColor: AppTokens.scaffold(context),
      body: Column(
        children: [
          _Header(onBack: () => Navigator.pop(context)),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppTokens.s16,
                AppTokens.s16,
                AppTokens.s16,
                AppTokens.s24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _BookHeroCard(book: widget.getBookSub),
                  const SizedBox(height: AppTokens.s20),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text('Notes Overview',
                          style: AppTokens.titleSm(context)),
                      const SizedBox(width: AppTokens.s8),
                      Text(
                        '(${notes.length} volumes)',
                        style: AppTokens.caption(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTokens.s12),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: notes.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppTokens.s8),
                    itemBuilder: (_, index) {
                      final note = notes[index];
                      return _NoteRow(
                        index: index + 1,
                        chapterName: note.chapterName ?? '',
                        chapter: note.chapter?.toString() ?? '',
                        pageNumber: note.pageNumber ?? '',
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Header
// ---------------------------------------------------------------------------

class _Header extends StatelessWidget {
  final VoidCallback onBack;
  const _Header({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTokens.brand, AppTokens.brand2],
        ),
        boxShadow: [
          BoxShadow(
            color: AppTokens.brand.withOpacity(0.25),
            blurRadius: 24,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppTokens.s12,
            AppTokens.s8,
            AppTokens.s16,
            AppTokens.s16,
          ),
          child: Row(
            children: [
              Material(
                color: Colors.white.withOpacity(0.18),
                borderRadius: AppTokens.radius12,
                child: InkWell(
                  borderRadius: AppTokens.radius12,
                  onTap: onBack,
                  child: const SizedBox(
                    height: 40,
                    width: 40,
                    child: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppTokens.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Notes',
                      style: AppTokens.overline(context).copyWith(
                        color: Colors.white.withOpacity(0.75),
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Select Notes',
                      style: AppTokens.titleLg(context).copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Book hero card
// ---------------------------------------------------------------------------

class _BookHeroCard extends StatelessWidget {
  final GetAllBookModel book;
  const _BookHeroCard({required this.book});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTokens.surface(context),
        borderRadius: AppTokens.radius20,
        border: Border.all(color: AppTokens.border(context)),
        boxShadow: AppTokens.shadow1(context),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              color: AppTokens.surface2(context),
              child: Image.asset(
                'assets/image/viewNote.png',
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Icon(
                  Icons.sticky_note_2_outlined,
                  size: 48,
                  color: AppTokens.muted(context),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppTokens.s16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        book.bookName ?? '',
                        style: AppTokens.titleMd(context),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppTokens.s8),
                      Row(
                        children: [
                          if ((book.bookType ?? '').isNotEmpty) ...[
                            Text(
                              book.bookType ?? '',
                              style: AppTokens.caption(context),
                            ),
                            const SizedBox(width: AppTokens.s8),
                          ],
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppTokens.s8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppTokens.accent(context),
                              borderRadius: AppTokens.radius8,
                            ),
                            child: Text(
                              '${book.volume ?? 0} Volumes',
                              style: AppTokens.caption(context).copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppTokens.s12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Price', style: AppTokens.overline(context)),
                    const SizedBox(height: 2),
                    Text(
                      '₹${book.price?.toInt() ?? 0}',
                      style: AppTokens.displayMd(context).copyWith(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppTokens.accent(context),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Note row
// ---------------------------------------------------------------------------

class _NoteRow extends StatelessWidget {
  final int index;
  final String chapterName;
  final String chapter;
  final String pageNumber;

  const _NoteRow({
    required this.index,
    required this.chapterName,
    required this.chapter,
    required this.pageNumber,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppTokens.s8,
        AppTokens.s8,
        AppTokens.s12,
        AppTokens.s8,
      ),
      decoration: BoxDecoration(
        color: AppTokens.surface(context),
        borderRadius: AppTokens.radius12,
        border: Border.all(color: AppTokens.border(context)),
      ),
      child: Row(
        children: [
          Container(
            height: 34,
            width: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTokens.brand, AppTokens.brand2],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: Text(
              index.toString().padLeft(2, '0'),
              style: AppTokens.body(context).copyWith(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: AppTokens.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  chapterName,
                  style: AppTokens.body(context).copyWith(
                    color: AppTokens.ink(context),
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  chapter.isEmpty ? 'Chapter' : 'Chapter $chapter',
                  style: AppTokens.caption(context),
                ),
              ],
            ),
          ),
          if (pageNumber.isNotEmpty) ...[
            const SizedBox(width: AppTokens.s8),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTokens.s8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: AppTokens.surface2(context),
                borderRadius: AppTokens.radius8,
              ),
              child: Text(
                pageNumber,
                style: AppTokens.caption(context).copyWith(
                  color: AppTokens.ink2(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
