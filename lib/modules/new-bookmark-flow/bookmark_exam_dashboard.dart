import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:shusruta_lms/modules/login/store/verify_otp_phone.dart';
import 'package:shusruta_lms/modules/new-bookmark-flow/bookmark_exam_screen.dart';
import 'package:shusruta_lms/modules/new-bookmark-flow/bookmark_module.dart';
import 'package:shusruta_lms/modules/new-bookmark-flow/store/new_bookmark_store.dart';

import '../../app/routes.dart';
import '../../helpers/app_tokens.dart';
import '../../helpers/colors.dart';

/// BookMarkExamDashboardScreen — the landing dashboard for a bookmark
/// exam topic. Shows total bookmark question count, a Solve-All CTA and
/// a list of user-created Custom Modules (with inline delete-dialog),
/// plus a primary CTA to create a new module.
///
/// Public surface preserved exactly:
///   • class [BookMarkExamDashboardScreen]
///   • final fields `type`, `id`, `title`, `questionCount`, `isCustome`
///   • const constructor with all five required params (note the
///     legacy `isCustome` spelling — unchanged)
///   • [SingleTickerProviderStateMixin] on the state
///   • state fields [tabIndex], `_controller`
///   • initState still calls
///     `store.ongetAllMyCustomTestApiCall(widget.type)` and spins up a
///     length-2 [TabController] with a listener syncing [tabIndex]
///   • [WillPopScope] pushes [Routes.dashboard] and returns false
///   • Solve-All CTA pushes [BookmarkExamScreen] with
///     `{isAll:true, id:widget.id, time:"03:00:00",
///       name:"All Questions", question:bookmarkQCount,
///       type:widget.type, isCustom:widget.isCustome}`
///   • Module tile tap pushes [BookmarkExamScreen] with
///     `{isCustom:widget.isCustome, isAll:false, id:d.id,
///       time:d.time_duration, name:d.testName,
///       question:d.questionCount, type:widget.type}`
///   • Delete dialog calls
///     `store.ongetCustomADeleteApiCall(type, id)` then
///     `store.ongetAllMyCustomTestApiCall(type)` with the double-pop
///   • Bottom "Create New Module" CTA pushes
///     [BookMarkModuleScreen]`(id:widget.id, type:widget.type)`
class BookMarkExamDashboardScreen extends StatefulWidget {
  const BookMarkExamDashboardScreen({
    super.key,
    required this.type,
    required this.id,
    required this.title,
    required this.questionCount,
    required this.isCustome,
  });
  final String type;
  final String title;
  final String id;
  final int questionCount;
  final bool isCustome;

  @override
  State<BookMarkExamDashboardScreen> createState() =>
      _BookMarkExamDashboardScreenState();
}

class _BookMarkExamDashboardScreenState
    extends State<BookMarkExamDashboardScreen>
    with SingleTickerProviderStateMixin {
  int tabIndex = 0;
  TabController? _controller;

  @override
  void initState() {
    final store = Provider.of<BookmarkNewStore>(context, listen: false);
    store.ongetAllMyCustomTestApiCall(widget.type);
    _controller = TabController(
      length: 2,
      vsync: this,
      initialIndex: tabIndex,
    );
    _controller?.addListener(() {
      setState(() {
        tabIndex = _controller?.index ?? 0;
      });
    });
    super.initState();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = Provider.of<BookmarkNewStore>(context);

    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pushNamed(Routes.dashboard);
        return false;
      },
      child: Scaffold(
        backgroundColor: AppTokens.scaffold(context),
        bottomNavigationBar: Observer(builder: (_) {
          if (store.isLoading) {
            return const SizedBox.shrink();
          }
          final hasModules =
              !(store.bookmarkTestModel.value?.data.isEmpty ?? true);
          if (!hasModules) return const SizedBox.shrink();
          return _PrimaryCta(
            label: 'Create New Module',
            icon: Icons.add_rounded,
            loading: store.isLoading,
            enabled: !store.isLoading,
            onTap: () {
              Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (context) => BookMarkModuleScreen(
                    id: widget.id,
                    type: widget.type,
                  ),
                ),
              );
            },
          );
        }),
        body: Column(
          children: [
            _Header(
              title: widget.title,
              onBack: () => Navigator.of(context).pop(),
              countBuilder: () => Observer(builder: (_) {
                final count =
                    store.bookmarkTestModel.value?.bookmarkQCount ?? 0;
                return _HeaderCountChip(value: '$count Questions');
              }),
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppTokens.surface(context),
                  borderRadius: (Platform.isWindows || Platform.isMacOS)
                      ? null
                      : const BorderRadius.only(
                          topLeft: Radius.circular(28.8),
                          topRight: Radius.circular(28.8),
                        ),
                ),
                child: Observer(builder: (_) {
                  if (store.isLoading ||
                      store.bookmarkTestModel.value == null) {
                    return Center(
                      child: CircularProgressIndicator(
                        color: AppTokens.accent(context),
                      ),
                    );
                  }
                  final bookmarkQCount =
                      store.bookmarkTestModel.value!.bookmarkQCount;
                  final modules = store.bookmarkTestModel.value!.data;
                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                      AppTokens.s20,
                      AppTokens.s24,
                      AppTokens.s20,
                      AppTokens.s24,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _TotalsBanner(count: bookmarkQCount),
                        const SizedBox(height: AppTokens.s16),
                        _SectionCard(
                          icon: Icons.all_inclusive_rounded,
                          title: 'All Questions',
                          subtitle:
                              'Jump straight into the full bookmark pool with the timer set to 3 hours.',
                          child: _GradientCta(
                            label: 'Solve all questions',
                            icon: Icons.play_arrow_rounded,
                            loading: false,
                            onTap: () {
                              Navigator.push(
                                context,
                                CupertinoPageRoute(
                                  builder: (context) => BookmarkExamScreen(
                                    isAll: true,
                                    id: widget.id,
                                    time: '03:00:00',
                                    name: 'All Questions',
                                    question: bookmarkQCount.toString(),
                                    type: widget.type,
                                    isCustom: widget.isCustome,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: AppTokens.s16),
                        _SectionCard(
                          icon: Icons.auto_awesome_mosaic_rounded,
                          title: 'Custom modules',
                          subtitle: modules.isNotEmpty
                              ? 'Tap a module to run it, or swipe through your saved drills below.'
                              : null,
                          child: modules.isEmpty
                              ? _EmptyModules(
                                  onCreate: () {
                                    Navigator.push(
                                      context,
                                      CupertinoPageRoute(
                                        builder: (context) =>
                                            BookMarkModuleScreen(
                                          id: widget.id,
                                          type: widget.type,
                                        ),
                                      ),
                                    );
                                  },
                                )
                              : ConstrainedBox(
                                  constraints:
                                      const BoxConstraints(maxHeight: 420),
                                  child: SingleChildScrollView(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        for (int i = 0; i < modules.length; i++)
                                          _ModuleTile(
                                            title: modules[i].testName,
                                            questionCount:
                                                modules[i].questionCount,
                                            description: modules[i].Description,
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                CupertinoPageRoute(
                                                  builder: (context) =>
                                                      BookmarkExamScreen(
                                                    isCustom: widget.isCustome,
                                                    isAll: false,
                                                    id: modules[i].id,
                                                    time: modules[i]
                                                        .time_duration,
                                                    name:
                                                        modules[i].testName,
                                                    question: modules[i]
                                                        .questionCount
                                                        .toString(),
                                                    type: widget.type,
                                                  ),
                                                ),
                                              );
                                            },
                                            onDelete: () {
                                              _showDeleteDialog(
                                                context,
                                                store,
                                                modules[i].id,
                                              );
                                            },
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(
    BuildContext ctx,
    BookmarkNewStore store,
    String moduleId,
  ) {
    showDialog(
      context: ctx,
      builder: (dialogCtx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: FittedBox(
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.topCenter,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTokens.s24,
                    vertical: AppTokens.s24,
                  ),
                  decoration: BoxDecoration(
                    color: AppTokens.surface(ctx),
                    borderRadius: AppTokens.radius20,
                    boxShadow: AppTokens.shadow2(ctx),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: AppTokens.s20),
                      Text(
                        'Delete this test?',
                        style: AppTokens.titleMd(ctx),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'This will remove the module from your custom list.',
                        textAlign: TextAlign.center,
                        style: AppTokens.caption(ctx),
                      ),
                      const SizedBox(height: AppTokens.s16),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _DialogButton(
                            label: 'Delete',
                            emphasis: _DialogEmphasis.danger,
                            onTap: () async {
                              showLoadingDialog(ctx);
                              await store.ongetCustomADeleteApiCall(
                                widget.type,
                                moduleId,
                              );
                              await store.ongetAllMyCustomTestApiCall(
                                widget.type,
                              );
                              Navigator.pop(ctx);
                              Navigator.pop(ctx);
                            },
                          ),
                          const SizedBox(width: AppTokens.s12),
                          _DialogButton(
                            label: 'Cancel',
                            emphasis: _DialogEmphasis.primary,
                            onTap: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: -26,
                  child: Container(
                    height: 52,
                    width: 52,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppTokens.surface(ctx),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTokens.border(ctx)),
                      boxShadow: AppTokens.shadow1(ctx),
                    ),
                    child: SvgPicture.asset(
                      'assets/image/deleteAccount.svg',
                      height: 26,
                      width: 26,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Header
// ---------------------------------------------------------------------------

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.onBack,
    required this.countBuilder,
  });

  final String title;
  final VoidCallback onBack;
  final Widget Function() countBuilder;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTokens.brand, AppTokens.brand2],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppTokens.s12,
            AppTokens.s8,
            AppTokens.s20,
            AppTokens.s20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _BackChip(onTap: onBack),
                  const SizedBox(width: AppTokens.s8),
                  Expanded(
                    child: Text(
                      'BOOKMARK DASHBOARD',
                      style: AppTokens.overline(context).copyWith(
                        color: Colors.white.withOpacity(0.85),
                      ),
                    ),
                  ),
                  countBuilder(),
                ],
              ),
              const SizedBox(height: AppTokens.s20),
              Text(
                title,
                style: AppTokens.displayMd(context).copyWith(
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Solve every bookmark in one go, or spin up a tailored module — the choice is yours.',
                style: AppTokens.body(context).copyWith(
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BackChip extends StatelessWidget {
  const _BackChip({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.18),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withOpacity(0.22)),
          ),
          child: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 16,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _HeaderCountChip extends StatelessWidget {
  const _HeaderCountChip({required this.value});
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.s12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: AppTokens.radius12,
        border: Border.all(color: Colors.white.withOpacity(0.22)),
      ),
      child: Text(
        value,
        style: AppTokens.caption(context).copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Totals banner + section card
// ---------------------------------------------------------------------------

class _TotalsBanner extends StatelessWidget {
  const _TotalsBanner({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTokens.s16),
      decoration: BoxDecoration(
        color: AppTokens.accentSoft(context),
        borderRadius: AppTokens.radius16,
        border: Border.all(
          color: AppTokens.accent(context).withOpacity(0.22),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppTokens.accent(context),
              borderRadius: AppTokens.radius12,
            ),
            child: SvgPicture.asset(
              'assets/image/question.svg',
              width: 18,
              height: 18,
              // ignore: deprecated_member_use
              color: Colors.white,
            ),
          ),
          const SizedBox(width: AppTokens.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count',
                  style: AppTokens.displayMd(context).copyWith(
                    color: AppTokens.accent(context),
                    fontSize: 26,
                  ),
                ),
                Text(
                  'Bookmarked questions waiting',
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

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.child,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTokens.s16),
      decoration: BoxDecoration(
        color: AppTokens.surface(context),
        borderRadius: AppTokens.radius20,
        border: Border.all(color: AppTokens.border(context)),
        boxShadow: AppTokens.shadow1(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppTokens.accentSoft(context),
                  borderRadius: AppTokens.radius12,
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: AppTokens.accent(context),
                ),
              ),
              const SizedBox(width: AppTokens.s12),
              Expanded(
                child: Text(title, style: AppTokens.titleMd(context)),
              ),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(subtitle!, style: AppTokens.caption(context)),
          ],
          const SizedBox(height: AppTokens.s12),
          child,
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Module tile
// ---------------------------------------------------------------------------

class _ModuleTile extends StatelessWidget {
  const _ModuleTile({
    required this.title,
    required this.questionCount,
    required this.description,
    required this.onTap,
    required this.onDelete,
  });

  final String title;
  final int? questionCount;
  final String description;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final safeDesc =
        description.trim().isEmpty || description.trim() == 'null'
            ? 'No description added.'
            : description;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTokens.s12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppTokens.radius16,
          child: Container(
            padding: const EdgeInsets.all(AppTokens.s12),
            decoration: BoxDecoration(
              color: AppTokens.surface(context),
              borderRadius: AppTokens.radius16,
              border: Border.all(color: AppTokens.border(context)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 52,
                  width: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppTokens.accentSoft(context),
                    borderRadius: AppTokens.radius12,
                  ),
                  child: Image.asset(
                    'assets/image/setting.png',
                    width: 24,
                    height: 24,
                    color:
                        ThemeManager.currentTheme == AppTheme.Dark
                            ? AppColors.white
                            : AppTokens.accent(context),
                  ),
                ),
                const SizedBox(width: AppTokens.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTokens.titleSm(context),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${questionCount ?? 0} Questions',
                        style: AppTokens.caption(context).copyWith(
                          color: AppTokens.accent(context),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        safeDesc,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTokens.caption(context),
                      ),
                    ],
                  ),
                ),
                _DeleteChip(onTap: onDelete),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DeleteChip extends StatelessWidget {
  const _DeleteChip({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppTokens.dangerSoft(context),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.delete_outline_rounded,
            color: AppTokens.danger(context),
            size: 18,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty state + gradient CTAs + dialog buttons
// ---------------------------------------------------------------------------

class _EmptyModules extends StatelessWidget {
  const _EmptyModules({required this.onCreate});
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTokens.s16),
      child: Column(
        children: [
          Container(
            width: 76,
            height: 76,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppTokens.accentSoft(context),
              shape: BoxShape.circle,
            ),
            child: SvgPicture.asset(
              'assets/image/attemp.svg',
              width: 36,
              height: 36,
            ),
          ),
          const SizedBox(height: AppTokens.s12),
          Text(
            'No modules yet',
            style: AppTokens.titleMd(context),
          ),
          const SizedBox(height: 4),
          Text(
            'Spin up a custom drill from your bookmarked questions.',
            textAlign: TextAlign.center,
            style: AppTokens.caption(context),
          ),
          const SizedBox(height: AppTokens.s16),
          _GradientCta(
            label: 'Create custom module',
            icon: Icons.add_rounded,
            loading: false,
            onTap: onCreate,
          ),
        ],
      ),
    );
  }
}

class _GradientCta extends StatelessWidget {
  const _GradientCta({
    required this.label,
    required this.icon,
    required this.loading,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool loading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bool enabled = onTap != null && !loading;
    return SizedBox(
      height: 48,
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: AppTokens.radius12,
          child: Ink(
            decoration: BoxDecoration(
              gradient: enabled
                  ? const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppTokens.brand, AppTokens.brand2],
                    )
                  : null,
              color: enabled ? null : AppTokens.surface3(context),
              borderRadius: AppTokens.radius12,
              boxShadow: enabled ? AppTokens.shadow1(context) : null,
            ),
            child: Center(
              child: loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          icon,
                          size: 16,
                          color: enabled
                              ? Colors.white
                              : AppTokens.muted(context),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          label,
                          style: AppTokens.titleSm(context).copyWith(
                            color: enabled
                                ? Colors.white
                                : AppTokens.muted(context),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PrimaryCta extends StatelessWidget {
  const _PrimaryCta({
    required this.label,
    required this.icon,
    required this.enabled,
    required this.loading,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool enabled;
  final bool loading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          AppTokens.s20,
          AppTokens.s12,
          AppTokens.s20,
          AppTokens.s16,
        ),
        decoration: BoxDecoration(
          color: AppTokens.surface(context),
          border: Border(
            top: BorderSide(color: AppTokens.border(context)),
          ),
        ),
        child: SizedBox(
          height: 54,
          child: _GradientCta(
            label: label,
            icon: icon,
            loading: loading,
            onTap: enabled ? onTap : null,
          ),
        ),
      ),
    );
  }
}

enum _DialogEmphasis { danger, primary }

class _DialogButton extends StatelessWidget {
  const _DialogButton({
    required this.label,
    required this.emphasis,
    required this.onTap,
  });

  final String label;
  final _DialogEmphasis emphasis;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDanger = emphasis == _DialogEmphasis.danger;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppTokens.radius12,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTokens.s16,
            vertical: AppTokens.s12,
          ),
          decoration: BoxDecoration(
            color: isDanger
                ? AppTokens.dangerSoft(context)
                : AppTokens.accent(context),
            borderRadius: AppTokens.radius12,
          ),
          child: Text(
            label,
            style: AppTokens.titleSm(context).copyWith(
              color: isDanger ? AppTokens.danger(context) : Colors.white,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}
