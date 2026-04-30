// ignore_for_file: deprecated_member_use, library_private_types_in_public_api, dead_null_aware_expression

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

/// "Offline Notes" topic-list screen. Reads previously-downloaded
/// notes (grouped by `topicId`) from the local Hive store via
/// `DbHelper.getAllNotesGroupedByTopicId(subcategoryId)` and renders
/// them as tap-through tiles that push into `Routes.downloadedNotesTitle`.
///
/// Preserved public contract:
///   • Constructor `OfflineTopicList({super.key, this.subcategoryId})`
///     with nullable `String? subcategoryId`.
///   • Static `route(RouteSettings)` factory reading
///     `arguments['subcategoryId']` and returning a `CupertinoPageRoute`.
///   • Navigator push target `Routes.downloadedNotesTitle` with
///     `{ 'topicId': notesCat?.topicId }` — preserved.
///   • `NotesCategoryStore.onSearchApiCall(keyword, "PDF")` search call
///     preserved.
///   • Hero header "Offline Notes" with back arrow preserved.
class OfflineTopicList extends StatefulWidget {
  const OfflineTopicList({super.key, this.subcategoryId});

  final String? subcategoryId;

  @override
  State<OfflineTopicList> createState() => _OfflineTopicListState();

  static Route<dynamic> route(RouteSettings routeSettings) {
    final arguments = routeSettings.arguments as Map<String, dynamic>;
    return CupertinoPageRoute(
      builder: (_) => OfflineTopicList(
        subcategoryId: arguments['subcategoryId'],
      ),
    );
  }
}

class _OfflineTopicListState extends State<OfflineTopicList> {
  String filterValue = '';
  String query = '';
  final FocusNode _focusNode = FocusNode();
  List<NotesOfflineDataModel>? notesList;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChanged);
    _getOfflineData();
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
    notesList = await dbHelper
        .getAllNotesGroupedByTopicId(widget.subcategoryId ?? "");
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
                  else
                    Expanded(
                      child: ListView.builder(
                        itemCount: notesList?.length,
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        physics: const BouncingScrollPhysics(),
                        itemBuilder: (BuildContext context, int index) {
                          final NotesOfflineDataModel? notesCat =
                              notesList?[index];
                          final String topicName = notesCat?.topicName ?? "";
                          if (query.isNotEmpty &&
                              (!topicName
                                  .toLowerCase()
                                  .contains(query.toLowerCase()))) {
                            return Container();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(
                                bottom: AppTokens.s8),
                            child: _TopicTile(
                              topicName: topicName,
                              onTap: () {
                                Navigator.of(context).pushNamed(
                                  Routes.downloadedNotesTitle,
                                  arguments: {
                                    'topicId': notesCat?.topicId,
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

class _TopicTile extends StatelessWidget {
  const _TopicTile({required this.topicName, required this.onTap});

  final String topicName;
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
                  "assets/image/notetopic.svg",
                  color: AppTokens.accent(context),
                ),
              ),
              const SizedBox(width: AppTokens.s16),
              Expanded(
                child: Text(
                  topicName,
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
