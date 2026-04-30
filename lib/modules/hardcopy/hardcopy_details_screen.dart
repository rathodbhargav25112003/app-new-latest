// ignore_for_file: deprecated_member_use, unused_import

import 'dart:io';

import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../helpers/app_tokens.dart';
import '../../helpers/colors.dart';
import 'model/book_model.dart';

/// Hardcopy details — redesigned with AppTokens. Constructor, static
/// route, and all navigation targets (volumeIndex, newCheckoutPlan with
/// identical argument map) preserved.
class HardcopyDetailsScreen extends StatelessWidget {
  final BookModel book;

  const HardcopyDetailsScreen({
    super.key,
    required this.book,
  });

  static Route<dynamic> route(RouteSettings routeSettings) {
    final BookModel book = routeSettings.arguments as BookModel;
    return MaterialPageRoute(
      builder: (_) => HardcopyDetailsScreen(book: book),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;
    final contentWidth = isDesktop ? 800.0 : screenWidth;

    return Scaffold(
      backgroundColor: AppTokens.scaffold(context),
      body: Column(
        children: [
          _HardcopyHeader(onBack: () => Navigator.pop(context)),
          Expanded(
            child: Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: contentWidth,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    AppTokens.s16,
                    AppTokens.s16,
                    AppTokens.s16,
                    AppTokens.s16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _CoverCard(
                        image: book.bookImg,
                        title: book.bookName,
                        subtitle:
                            "${book.volume} Volumes · ${book.totalPage} Pages",
                      ),
                      const SizedBox(height: AppTokens.s16),
                      if (book.volumeDetails.isNotEmpty) ...[
                        Row(
                          children: [
                            Text(
                              'Volumes',
                              style: AppTokens.titleSm(context),
                            ),
                            const SizedBox(width: AppTokens.s8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppTokens.s8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppTokens.accentSoft(context),
                                borderRadius: AppTokens.radius8,
                              ),
                              child: Text(
                                '${book.volumeDetails.length}',
                                style: AppTokens.caption(context).copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppTokens.accent(context),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppTokens.s12),
                        for (int i = 0; i < book.volumeDetails.length; i++) ...[
                          _VolumeRow(
                            index: i + 1,
                            volume: book.volumeDetails[i],
                          ),
                          if (i != book.volumeDetails.length - 1)
                            const SizedBox(height: AppTokens.s8),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
          _CheckoutBar(book: book),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Header
// ---------------------------------------------------------------------------

class _HardcopyHeader extends StatelessWidget {
  final VoidCallback onBack;
  const _HardcopyHeader({required this.onBack});

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
                      'Hardcopy',
                      style: AppTokens.overline(context).copyWith(
                        color: Colors.white.withOpacity(0.75),
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Details',
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
// Cover card
// ---------------------------------------------------------------------------

class _CoverCard extends StatelessWidget {
  final String image;
  final String title;
  final String subtitle;

  const _CoverCard({
    required this.image,
    required this.title,
    required this.subtitle,
  });

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
          SizedBox(
            height: 180,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  image.isNotEmpty
                      ? image
                      : 'https://picsum.photos/400/200',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: AppTokens.surface2(context),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.menu_book_rounded,
                      size: 48,
                      color: AppTokens.muted(context),
                    ),
                  ),
                ),
                // Subtle dark overlay for legibility
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.2),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppTokens.s16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTokens.titleMd(context),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: AppTokens.caption(context),
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
// Volume row
// ---------------------------------------------------------------------------

class _VolumeRow extends StatelessWidget {
  final int index;
  final VolumeDetails volume;

  const _VolumeRow({required this.index, required this.volume});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTokens.s12),
      decoration: BoxDecoration(
        color: AppTokens.surface(context),
        borderRadius: AppTokens.radius12,
        border: Border.all(color: AppTokens.border(context)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTokens.brand, AppTokens.brand2],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: AppTokens.radius8,
            ),
            child: Text(
              index.toString().padLeft(2, '0'),
              style: AppTokens.body(context).copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.white,
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
                  volume.volumeName,
                  style: AppTokens.body(context).copyWith(
                    color: AppTokens.ink(context),
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${volume.notesOverview.length} chapter${volume.notesOverview.length == 1 ? '' : 's'}',
                  style: AppTokens.caption(context),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppTokens.s8),
          TextButton(
            onPressed: () {
              Navigator.of(context).pushNamed(
                Routes.volumeIndex,
                arguments: {
                  'volumeName': volume.volumeName,
                  'volumeNumber': volume.notesOverview.length,
                  'chapters': volume.notesOverview
                      .map((chapter) => {
                            'name': chapter.chapterName,
                            'number': chapter.chapter,
                            'pages': chapter.pageNumber,
                            'chapterFile': chapter.chapterFile,
                          })
                      .toList(),
                },
              );
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTokens.s8,
                vertical: 4,
              ),
              backgroundColor: AppTokens.accentSoft(context),
              shape: RoundedRectangleBorder(
                borderRadius: AppTokens.radius8,
              ),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'View Index',
                  style: AppTokens.caption(context).copyWith(
                    color: AppTokens.accent(context),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 2),
                Icon(
                  Icons.arrow_forward_rounded,
                  size: 14,
                  color: AppTokens.accent(context),
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
// Checkout bar
// ---------------------------------------------------------------------------

class _CheckoutBar extends StatelessWidget {
  final BookModel book;
  const _CheckoutBar({required this.book});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTokens.surface(context),
        border: Border(
          top: BorderSide(color: AppTokens.border(context)),
        ),
        boxShadow: AppTokens.shadow1(context),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppTokens.s16,
            AppTokens.s12,
            AppTokens.s16,
            AppTokens.s12,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Price',
                      style: AppTokens.overline(context),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '₹${book.price}',
                          style: AppTokens.displayMd(context).copyWith(
                            fontSize: 22,
                            color: AppTokens.accent(context),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (book.comboPrice != null &&
                            book.comboPrice != book.price) ...[
                          const SizedBox(width: AppTokens.s8),
                          Text(
                            '₹${book.comboPrice}',
                            style: AppTokens.caption(context).copyWith(
                              decoration: TextDecoration.lineThrough,
                              color: AppTokens.muted(context),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushNamed(
                    Routes.newCheckoutPlan,
                    arguments: {
                      'plans': [],
                      'books': [
                        {
                          'id': book.id,
                          'name': book.bookName,
                          'type': book.bookType,
                          'price': book.price,
                          'imageUrl': book.bookImg,
                          'height': book.height,
                          'width': book.breadth,
                          'length': book.length,
                          'weight': book.weight,
                        }
                      ],
                      'totalPrice': book.price,
                    },
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTokens.accent(context),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: AppTokens.radius12,
                  ),
                  minimumSize: const Size(140, 48),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTokens.s16,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.shopping_bag_outlined, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      'Buy now',
                      style: AppTokens.body(context).copyWith(
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
