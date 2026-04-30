import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../helpers/app_tokens.dart';
import '../../api_service/api_service.dart';

/// Reset Progress — Apple-minimalistic destructive-action surface.
///
/// Visual recipe:
///  • Plain scaffold, no bottom-strip / blue accents.
///  • Section header explains the action.
///  • Each module is a tile with a tinted leading icon, label, and a checkbox
///    on the trailing edge. Tiles are grouped on a single soft surface card,
///    separated by 0.5pt hairlines.
///  • Primary CTA pinned to bottom uses [AppTokens.danger] when armed and
///    fades to [AppTokens.surface3] when no module is selected.
class DeleteHistoryScreen extends StatelessWidget {
  static Route<dynamic> route(RouteSettings settings) {
    return MaterialPageRoute(builder: (_) => const DeleteHistoryScreen());
  }

  const DeleteHistoryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<DeleteHistoryProvider>(
      create: (_) => DeleteHistoryProvider(),
      child: const DeleteHistoryView(),
    );
  }
}

class DeleteHistoryView extends StatelessWidget {
  const DeleteHistoryView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DeleteHistoryProvider>(context);
    return Scaffold(
      backgroundColor: AppTokens.scaffold(context),
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: AppTokens.scaffold(context),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: AppTokens.ink(context), size: 18),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text('Reset Progress', style: AppTokens.titleLg(context)),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              AppTokens.s24, AppTokens.s8, AppTokens.s24, AppTokens.s24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pick the modules you want to clear. This cannot be undone.',
                style: AppTokens.body(context),
              ),
              const SizedBox(height: AppTokens.s20),

              // Single soft-surface card holding all module rows.
              Expanded(
                child: SingleChildScrollView(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTokens.surface(context),
                      borderRadius: AppTokens.radius16,
                      border: Border.all(
                        color: AppTokens.border(context),
                        width: 0.5,
                      ),
                    ),
                    child: Column(
                      children: List.generate(
                        provider.historyTypes.length,
                        (index) {
                          final type = provider.historyTypes[index];
                          final isLast =
                              index == provider.historyTypes.length - 1;
                          return _ModuleRow(
                            type: type,
                            checked:
                                provider.selectedTypes.contains(type.key),
                            onTap: () => provider.toggleType(type.key),
                            isLast: isLast,
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),

              if (provider.errorMessage != null) ...[
                const SizedBox(height: AppTokens.s12),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppTokens.s12, vertical: AppTokens.s8),
                  decoration: BoxDecoration(
                    color: AppTokens.dangerSoft(context),
                    borderRadius: AppTokens.radius12,
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline_rounded,
                          color: AppTokens.danger(context), size: 18),
                      const SizedBox(width: AppTokens.s8),
                      Expanded(
                        child: Text(
                          provider.errorMessage!,
                          style: AppTokens.caption(context).copyWith(
                            color: AppTokens.danger(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: AppTokens.s16),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: provider.isLoading || provider.selectedTypes.isEmpty
                      ? null
                      : () => provider.deleteSelected(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: provider.selectedTypes.isEmpty
                        ? AppTokens.surface3(context)
                        : AppTokens.danger(context),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppTokens.surface3(context),
                    disabledForegroundColor: AppTokens.muted(context),
                    elevation: 0,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: AppTokens.radius16,
                    ),
                  ),
                  child: provider.isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          provider.selectedTypes.isEmpty
                              ? 'Select modules to reset'
                              : 'Reset ${provider.selectedTypes.length} module${provider.selectedTypes.length == 1 ? '' : 's'}',
                          style: AppTokens.titleSm(context).copyWith(
                            color: provider.selectedTypes.isEmpty
                                ? AppTokens.muted(context)
                                : Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModuleRow extends StatelessWidget {
  const _ModuleRow({
    Key? key,
    required this.type,
    required this.checked,
    required this.onTap,
    required this.isLast,
  }) : super(key: key);

  final HistoryType type;
  final bool checked;
  final VoidCallback onTap;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppTokens.s16, vertical: AppTokens.s12),
          decoration: BoxDecoration(
            border: isLast
                ? null
                : Border(
                    bottom: BorderSide(
                      color: AppTokens.border(context),
                      width: 0.5,
                    ),
                  ),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: type.color.withOpacity(0.14),
                  borderRadius: AppTokens.radius12,
                ),
                child: Icon(type.icon, color: type.color, size: 18),
              ),
              const SizedBox(width: AppTokens.s12),
              Expanded(
                child: Text(
                  type.label,
                  style: AppTokens.titleSm(context),
                ),
              ),
              const SizedBox(width: AppTokens.s8),
              _AppleCheckbox(checked: checked, onTap: onTap),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppleCheckbox extends StatelessWidget {
  const _AppleCheckbox({
    Key? key,
    required this.checked,
    required this.onTap,
  }) : super(key: key);

  final bool checked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: checked ? AppTokens.accent(context) : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(
            color: checked
                ? AppTokens.accent(context)
                : AppTokens.borderStrong(context),
            width: 1.4,
          ),
        ),
        child: checked
            ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
            : null,
      ),
    );
  }
}

class DeleteHistoryProvider extends ChangeNotifier {
  // List of selectable history types
  final List<HistoryType> historyTypes = [
    HistoryType(
        key: 'video',
        label: 'Videos',
        icon: Icons.ondemand_video_rounded,
        color: const Color(0xFF1E88E5)),
    HistoryType(
        key: 'mcq',
        label: 'MCQ Bank',
        icon: Icons.quiz_outlined,
        color: const Color(0xFFE89B20)),
    HistoryType(
        key: 'mock',
        label: 'Mock Exams',
        icon: Icons.assignment_outlined,
        color: const Color(0xFFE23B3B)),
    HistoryType(
        key: 'pdf',
        label: 'Notes',
        icon: Icons.picture_as_pdf_outlined,
        color: const Color(0xFF33AD48)),
    HistoryType(
        key: 'customExam',
        label: 'Custom Modules',
        icon: Icons.edit_note_rounded,
        color: const Color(0xFF8E44AD)),
    HistoryType(
        key: 'mcqBookmark',
        label: 'MCQ Bank Bookmarks',
        icon: Icons.bookmark_outline_rounded,
        color: const Color(0xFFE89B20)),
    HistoryType(
        key: 'mockBookmark',
        label: 'Mock Exam Bookmarks',
        icon: Icons.bookmark_border_rounded,
        color: const Color(0xFF14A38B)),
  ];

  final Set<String> selectedTypes = {};
  bool isLoading = false;
  String? errorMessage;

  void toggleType(String key) {
    if (selectedTypes.contains(key)) {
      selectedTypes.remove(key);
    } else {
      selectedTypes.add(key);
    }
    errorMessage = null;
    notifyListeners();
  }

  /// Calls the backend API to delete selected history types.
  Future<void> deleteSelected(BuildContext context) async {
    if (selectedTypes.isEmpty) return;

    // Confirmation prompt — Apple HIG-style destructive dialog.
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTokens.surface(ctx),
        shape: RoundedRectangleBorder(borderRadius: AppTokens.radius16),
        title: Text('Reset progress?', style: AppTokens.titleLg(ctx)),
        content: Text(
          'This will permanently clear data for the modules you selected. '
          'You will not be able to undo this.',
          style: AppTokens.body(ctx),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancel',
                style: AppTokens.titleSm(ctx).copyWith(
                  color: AppTokens.ink2(ctx),
                )),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Reset',
                style: AppTokens.titleSm(ctx).copyWith(
                  color: AppTokens.danger(ctx),
                  fontWeight: FontWeight.w700,
                )),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final api = ApiService();
      await api.deleteAllHistory(selectedTypes.toList());
      isLoading = false;
      selectedTypes.clear();
      notifyListeners();
      if (!context.mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppTokens.surface(ctx),
          shape: RoundedRectangleBorder(borderRadius: AppTokens.radius16),
          title: Row(
            children: [
              Icon(Icons.check_circle_rounded,
                  color: AppTokens.success(ctx), size: 22),
              const SizedBox(width: AppTokens.s8),
              Text('All set', style: AppTokens.titleLg(ctx)),
            ],
          ),
          content: Text(
            'Your selected progress has been cleared.',
            style: AppTokens.body(ctx),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text('OK',
                  style: AppTokens.titleSm(ctx).copyWith(
                    color: AppTokens.accent(ctx),
                    fontWeight: FontWeight.w700,
                  )),
            ),
          ],
        ),
      );
    } catch (e) {
      isLoading = false;
      errorMessage = 'Couldn’t reset right now. Please try again.';
      notifyListeners();
    }
  }
}

class HistoryType {
  final String key;
  final String label;
  final IconData icon;
  final Color color;
  const HistoryType(
      {required this.key,
      required this.label,
      required this.icon,
      required this.color});
}
