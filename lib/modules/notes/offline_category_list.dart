// ignore_for_file: deprecated_member_use, library_private_types_in_public_api, avoid_print, unused_element

import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';

import 'package:shusruta_lms/app/routes.dart';
import 'package:shusruta_lms/helpers/app_tokens.dart';
import 'package:shusruta_lms/helpers/colors.dart';
import 'package:shusruta_lms/helpers/dbhelper.dart';
import 'package:shusruta_lms/models/notes_offline_data_model.dart';
import 'package:shusruta_lms/modules/notes/store/notes_category_store.dart';
import 'package:shusruta_lms/modules/subscriptionplans/store/subscription_store.dart';

/// "Offline Notes" root category list — the top of the offline browse
/// tree. Reads previously-downloaded PDF notes grouped by `categoryId`
/// from the local Hive store via
/// `DbHelper.getAllNotesGroupedByCategoryId()`, reconciles the locally
/// cached PDF topic IDs against the user's current subscription plan
/// via `SubscriptionStore.onGetSubscribedUserPlan()`, and purges any
/// cached notes that the user no longer has access to.
///
/// Preserved public contract:
///   • `const OfflineCategoryList({super.key})` — no arguments.
///   • Static `route(RouteSettings)` factory returning
///     `CupertinoPageRoute` (matches the RouteSettings signature used
///     by the rest of the app's routing layer).
///   • Navigator push `Routes.downloadedNotesSubCategory` with
///     `{ 'categoryId': categoryId }` preserved byte-for-byte.
///   • `NotesCategoryStore.onSearchApiCall(keyword, "PDF")` preserved.
///   • `_getSubscribedPlan()` reconciliation logic preserved:
///     computes the set difference between locally-cached PDF topic
///     IDs and `SubscriptionStore.subscribedPlan[*].pdf_topic_id`, then
///     calls `DbHelper.deleteAllNotesByTopicId(topicId)` for each
///     topic ID that is no longer in the plan, and reloads the list.
///   • Debug prints preserved byte-for-byte: `pdfTopicId $pdfTopicId`,
///     `offlinePdfTopicId $offlinePdfTopicId`,
///     `Ids not present in pdfTopicId: $difference`, and the if/else
///     debug dumps of `notesList?.map((e) => e.topicId)`.
///   • Legacy `_getofflineDataDelete()` private method kept (it is
///     unused but retained for future reactivation — the original file
///     also carried it).
class OfflineCategoryList extends StatefulWidget {
  const OfflineCategoryList({super.key});

  @override
  State<OfflineCategoryList> createState() => _OfflineCategoryListState();

  static Route<dynamic> route(RouteSettings routeSettings) {
    return CupertinoPageRoute(
      builder: (_) => const OfflineCategoryList(),
    );
  }
}

class _OfflineCategoryListState extends State<OfflineCategoryList> {
  String filterValue = '';
  String query = '';
  final FocusNode _focusNode = FocusNode();
  List<NotesOfflineDataModel>? notesList;
  bool isLoading = false;
  List<String>? pdfTopicId;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChanged);
    _getOfflineData();
    _getSubscribedPlan();
  }

  Future<void> _getSubscribedPlan() async {
    final store = Provider.of<SubscriptionStore>(context, listen: false);
    await store.onGetSubscribedUserPlan();
    if (store.subscribedPlan.isEmpty) {
      // _getofflineDataDelete();
      // Navigator.of(context).pushNamed(Routes.subscriptionList);
    } else if (store.subscribedPlan.isNotEmpty) {
      List<String>? offlinePdfTopicId;
      offlinePdfTopicId =
          (notesList?.map((e) => e.topicId).toList() ?? []).cast<String>();
      pdfTopicId = store.subscribedPlan
          .expand((e) => e?.pdf_topic_id ?? [])
          .cast<String>()
          .toList();
      debugPrint("pdfTopicId $pdfTopicId");
      debugPrint("offlinePdfTopicId $offlinePdfTopicId");
      List<String> difference = offlinePdfTopicId
          .where((element) => !pdfTopicId!.contains(element))
          .toList();

      debugPrint("Ids not present in pdfTopicId: $difference");
      if (pdfTopicId != offlinePdfTopicId) {
        debugPrint("if ${notesList?.map((e) => e.topicId)}");
        final dbHelper = DbHelper();
        for (var topicId in difference) {
          await dbHelper.deleteAllNotesByTopicId(topicId);
        }
        _getOfflineData();
      } else {
        debugPrint("else ${notesList?.map((e) => e.topicId)}");
      }
    } else {
      _getOfflineData();
    }
  }

  void _onFocusChanged() {
    if (!_focusNode.hasFocus) {
      _focusNode.unfocus();
    }
  }

  Future<void> _getOfflineData() async {
    setState(() {
      isLoading = true;
    });
    final dbHelper = DbHelper();
    notesList = await dbHelper.getAllNotesGroupedByCategoryId();
    setState(() {
      isLoading = false;
    });
  }

  /// Legacy helper retained from the original implementation. Currently
  /// unused but preserved for potential future reactivation — the
  /// original file carried this method and the delete call it wraps is
  /// commented out in-situ.
  Future<void> _getofflineDataDelete() async {
    setState(() {
      isLoading = true;
    });

    final dbHelper = DbHelper();
    // await dbHelper.deleteAllNotesByTopicIdWithSubcription(flatSet);
    // notesList?.clear();
    print("notes list $notesList?.length");
    // Silence the analyzer for the unused dbHelper local — original
    // intent was to route through the commented-out delete call.
    // ignore: unused_local_variable
    final _ = dbHelper;
    setState(() {
      isLoading = false;
    });
  }

  Future<void> searchCategory(String keyword) async {
    final store = Provider.of<NotesCategoryStore>(context, listen: false);
    await store.onSearchApiCall(keyword, "PDF");
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Platform.isWindows || Platform.isMacOS;
    return Scaffold(
      backgroundColor: AppTokens.scaffold(context),
      body: Column(
        children: [
          _HeroHeader(isDesktop: isDesktop),
          Expanded(
            child: Container(
              padding: const EdgeInsets.only(
                left: AppTokens.s20,
                right: AppTokens.s20,
                top: AppTokens.s24,
              ),
              decoration: BoxDecoration(
                color: AppTokens.scaffold(context),
                borderRadius: isDesktop
                    ? null
                    : const BorderRadius.only(
                        topLeft: Radius.circular(AppTokens.r28),
                        topRight: Radius.circular(AppTokens.r28),
                      ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (query.isNotEmpty)
                    Text(
                      'Results for "$query"',
                      style: AppTokens.body(context).copyWith(
                        fontWeight: FontWeight.w500,
                        color: AppTokens.ink(context),
                      ),
                    ),
                  const SizedBox(height: AppTokens.s8),
                  _SearchField(
                    focusNode: _focusNode,
                    onChanged: (value) {
                      setState(() {
                        query = value;
                      });
                    },
                  ),
                  const SizedBox(height: AppTokens.s16),
                  if (isLoading)
                    const Expanded(
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (notesList?.isEmpty ?? false)
                    Expanded(
                      child: Center(
                        child: Text(
                          "No Offline Notes Found",
                          style: AppTokens.body(context).copyWith(
                            fontWeight: FontWeight.w500,
                            color: AppTokens.muted(context),
                          ),
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.builder(
                        itemCount: notesList?.length ?? 0,
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        physics: const BouncingScrollPhysics(),
                        itemBuilder: (BuildContext context, int index) {
                          final NotesOfflineDataModel? notesCat =
                              notesList?[index];
                          final String categoryName =
                              notesCat?.categoryName ?? "";
                          final String categoryId =
                              notesCat?.categoryId ?? "";
                          if (query.isNotEmpty &&
                              (!categoryName
                                  .toLowerCase()
                                  .contains(query.toLowerCase()))) {
                            return Container();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(
                                bottom: AppTokens.s8),
                            child: _CategoryTile(
                              categoryName: categoryName,
                              onTap: () {
                                Navigator.of(context).pushNamed(
                                  Routes.downloadedNotesSubCategory,
                                  arguments: {
                                    'categoryId': categoryId,
                                  },
                                );
                              },
                            ),
                          );
                        },
                      ),
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

/// Brand-gradient hero strip with back arrow and "Offline Notes" title.
class _HeroHeader extends StatelessWidget {
  const _HeroHeader({required this.isDesktop});

  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTokens.brand, AppTokens.brand2],
        ),
      ),
      padding: isDesktop
          ? const EdgeInsets.symmetric(
              vertical: AppTokens.s24, horizontal: AppTokens.s24)
          : const EdgeInsets.only(
              top: AppTokens.s32 + AppTokens.s24,
              left: AppTokens.s20,
              right: AppTokens.s20,
              bottom: AppTokens.s20,
            ),
      child: Row(
        children: [
          IconButton(
            highlightColor: Colors.transparent,
            hoverColor: Colors.transparent,
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColors.white,
            ),
          ),
          const SizedBox(width: AppTokens.s8),
          Expanded(
            child: Text(
              "Offline Notes",
              style: AppTokens.titleSm(context).copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.focusNode, required this.onChanged});

  final FocusNode focusNode;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: TextField(
        focusNode: focusNode,
        onChanged: onChanged,
        style: AppTokens.body(context).copyWith(
          fontWeight: FontWeight.w500,
          color: AppTokens.ink(context),
        ),
        cursorColor: AppTokens.brand,
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppTokens.s16,
            vertical: AppTokens.s12,
          ),
          suffixIcon:
              Icon(CupertinoIcons.search, color: AppTokens.muted(context)),
          hintStyle: AppTokens.body(context).copyWith(
            fontWeight: FontWeight.w500,
            color: AppTokens.muted(context),
          ),
          hintText: 'Search',
          fillColor: AppTokens.surface(context),
          filled: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTokens.r12),
            borderSide: BorderSide(color: AppTokens.border(context)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTokens.r12),
            borderSide: const BorderSide(color: AppTokens.brand, width: 1.2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTokens.r12),
            borderSide: BorderSide(color: AppTokens.border(context)),
          ),
        ),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.categoryName, required this.onTap});

  final String categoryName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTokens.r12),
        child: Container(
          padding: const EdgeInsets.all(AppTokens.s16),
          decoration: BoxDecoration(
            color: AppTokens.surface(context),
            border: Border.all(color: AppTokens.border(context)),
            borderRadius: BorderRadius.circular(AppTokens.r12),
            boxShadow: AppTokens.shadow1(context),
          ),
          child: Row(
            children: [
              Container(
                height: AppTokens.s32 + AppTokens.s24,
                width: AppTokens.s32 + AppTokens.s24,
                padding: const EdgeInsets.all(AppTokens.s12),
                decoration: BoxDecoration(
                  color: AppTokens.accentSoft(context),
                  borderRadius: BorderRadius.circular(AppTokens.r12),
                ),
                child: SvgPicture.asset(
                  "assets/image/noteCategory.svg",
                  color: AppTokens.accent(context),
                ),
              ),
              const SizedBox(width: AppTokens.s16),
              Expanded(
                child: Text(
                  categoryName,
                  style: AppTokens.body(context).copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTokens.ink(context),
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppTokens.muted(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
