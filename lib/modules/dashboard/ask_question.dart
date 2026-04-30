import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:typewritertext/typewritertext.dart';

import '../../app/routes.dart';
import '../../helpers/app_tokens.dart';
import '../../models/ask_question_model.dart';
import '../bookmarks/store/bookmark_store.dart';
import '../reports/store/report_by_category_store.dart';
import '../subscriptionplans/store/subscription_store.dart';
import '../widgets/no_internet_connection.dart';
import 'store/home_store.dart';

/// AskQuestionScreen — Cortex.AI chat surface.
///
/// Apple-minimalistic redesign:
///  • Clean AppBar with AI avatar and "Always active" subtitle.
///  • Soft-surface message bubbles (user: brand accent, AI: surface).
///  • System keyboard (no more custom number pad on a free-form
///    natural-language input — the previous implementation forced
///    KeyboardType.email which was wrong anyway).
///  • Empty state with cortex AI hero image.
class AskQuestionScreen extends StatefulWidget {
  final bool fromHome;
  const AskQuestionScreen({super.key, this.fromHome = false});

  @override
  State<AskQuestionScreen> createState() => _AskQuestionScreenState();
  static Route<dynamic> route(RouteSettings routeSettings) {
    final arguments = routeSettings.arguments as Map<String, dynamic>;
    return CupertinoPageRoute(
      builder: (_) =>
          AskQuestionScreen(fromHome: arguments['fromhome'] ?? false),
    );
  }
}

class _AskQuestionScreenState extends State<AskQuestionScreen> {
  final TextEditingController _explainController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isThinking = false;
  List<AskQuestionModel> _messages = [];

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final loginStore = Provider.of<HomeStore>(context, listen: false);
    final subStore = Provider.of<SubscriptionStore>(context, listen: false);
    final bookStore = Provider.of<BookMarkStore>(context, listen: false);

    await loginStore.onGetUserDetailsCall(context);
    await subStore.onGetSubscribedUserPlan();
    await bookStore.onBookMarkCategoryApiCall(context);
    await _refreshHistory();
  }

  Future<void> _refreshHistory() async {
    final store = Provider.of<ReportsCategoryStore>(context, listen: false);
    await store.onGetAllAskQuestion(context);
    if (!mounted) return;
    setState(() {
      _messages = store.getAllChatBotData
          .where((message) => message != null)
          .cast<AskQuestionModel>()
          .toList();
    });
  }

  Future<void> _sendMessage(String prompt) async {
    if (prompt.trim().isEmpty || _isThinking) return;
    setState(() {
      _messages.add(AskQuestionModel(question: prompt, answer: null));
      _isThinking = true;
      _explainController.clear();
    });
    final index = _messages.length - 1;
    final store = Provider.of<ReportsCategoryStore>(context, listen: false);
    await store.onGetExplanationCall(prompt);
    await store.onCreateAskQuestion(
        prompt, store.getExplanationText.value?.text ?? '');
    await _refreshHistory();
    if (!mounted) return;
    setState(() {
      if (_messages.length > index) {
        _messages[index].answer = store.getExplanationText.value?.text;
      }
      _isThinking = false;
    });
  }

  Future<void> _clearHistory() async {
    final store = Provider.of<ReportsCategoryStore>(context, listen: false);
    await store.onDeleteAllAskQuestion(context);
    await _refreshHistory();
  }

  Future<void> _confirmClear() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTokens.surface(ctx),
        shape: RoundedRectangleBorder(borderRadius: AppTokens.radius16),
        title: Text('Clear chat?', style: AppTokens.titleLg(ctx)),
        content: Text(
          'This removes all your past conversations with Cortex.AI.',
          style: AppTokens.body(ctx),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancel',
                style: AppTokens.titleSm(ctx)
                    .copyWith(color: AppTokens.ink2(ctx))),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Clear',
                style: AppTokens.titleSm(ctx).copyWith(
                  color: AppTokens.danger(ctx),
                  fontWeight: FontWeight.w700,
                )),
          ),
        ],
      ),
    );
    if (confirmed == true) await _clearHistory();
  }

  @override
  Widget build(BuildContext context) {
    final store = Provider.of<ReportsCategoryStore>(context);
    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pushNamed(Routes.dashboard);
        return false;
      },
      child: Scaffold(
        backgroundColor: AppTokens.scaffold(context),
        appBar: _buildAppBar(),
        body: store.isConnected
            ? Column(
                children: [
                  Expanded(
                    child: Observer(
                      builder: (_) {
                        if (_messages.isEmpty) return _buildEmpty();
                        return ListView.builder(
                          reverse: true,
                          padding: const EdgeInsets.fromLTRB(
                              AppTokens.s16,
                              AppTokens.s8,
                              AppTokens.s16,
                              AppTokens.s8),
                          itemCount: _messages.length,
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          itemBuilder: (ctx, i) {
                            final m = _messages.reversed.toList()[i];
                            return _buildMessage(m);
                          },
                        );
                      },
                    ),
                  ),
                  if (_isThinking)
                    Padding(
                      padding: const EdgeInsets.only(
                          left: AppTokens.s24, bottom: AppTokens.s8),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: TypeWriterText(
                          repeat: true,
                          text: Text(
                            'Cortex.AI is thinking…',
                            style: AppTokens.caption(context),
                          ),
                          maintainSize: false,
                          duration: const Duration(milliseconds: 100),
                        ),
                      ),
                    ),
                  _buildComposer(),
                ],
              )
            : const NoInternetScreen(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: AppTokens.scaffold(context),
      leading: widget.fromHome
          ? IconButton(
              icon: Icon(Icons.arrow_back_ios_new_rounded,
                  color: AppTokens.ink(context), size: 18),
              onPressed: () => Navigator.of(context).maybePop(),
            )
          : null,
      title: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppTokens.accent(context),
              shape: BoxShape.circle,
            ),
            child: Text('AI',
                style: AppTokens.titleSm(context).copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                )),
          ),
          const SizedBox(width: AppTokens.s12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Cortex.AI", style: AppTokens.titleLg(context)),
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Color(0xFF7DDE86),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text("Always active", style: AppTokens.caption(context)),
                ],
              ),
            ],
          ),
        ],
      ),
      centerTitle: false,
      actions: [
        IconButton(
          tooltip: 'Clear chat',
          icon: Icon(Icons.delete_outline_rounded,
              color: AppTokens.ink(context)),
          onPressed: _confirmClear,
        ),
        const SizedBox(width: AppTokens.s8),
      ],
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTokens.s24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset("assets/image/cortex_ai.png", width: 220),
            const SizedBox(height: AppTokens.s24),
            Text('Ask anything in NEET SS prep',
                style: AppTokens.titleLg(context)),
            const SizedBox(height: 6),
            Text(
              'Cortex.AI gives you concise, exam-relevant answers.',
              textAlign: TextAlign.center,
              style: AppTokens.body(context),
            ),
            const SizedBox(height: AppTokens.s20),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: AppTokens.s8,
              runSpacing: AppTokens.s8,
              children: [
                _SuggestionChip(
                    text: "Explain DKA management",
                    onTap: () => _sendMessage("Explain DKA management")),
                _SuggestionChip(
                    text: "Differentiate SLE vs RA",
                    onTap: () => _sendMessage("Differentiate SLE vs RA")),
                _SuggestionChip(
                    text: "Mnemonic for cranial nerves",
                    onTap: () => _sendMessage("Mnemonic for cranial nerves")),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessage(AskQuestionModel m) {
    final isUser = m.question?.isNotEmpty ?? false;
    final isAi = m.answer?.isNotEmpty ?? false;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isUser) ...[
          const SizedBox(height: AppTokens.s12),
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.78,
              ),
              padding: const EdgeInsets.symmetric(
                  horizontal: AppTokens.s16, vertical: AppTokens.s12),
              decoration: BoxDecoration(
                color: AppTokens.accent(context),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(6),
                ),
              ),
              child: Text(
                m.question ?? '',
                style: AppTokens.body(context).copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
        if (isAi) ...[
          const SizedBox(height: AppTokens.s12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppTokens.accentSoft(context),
                  shape: BoxShape.circle,
                ),
                child: SvgPicture.asset(
                  "assets/image/roboto.svg",
                  width: 18,
                  height: 18,
                  color: AppTokens.accent(context),
                ),
              ),
              const SizedBox(width: AppTokens.s8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(AppTokens.s12),
                  decoration: BoxDecoration(
                    color: AppTokens.surface(context),
                    border: Border.all(
                        color: AppTokens.border(context), width: 0.5),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(6),
                      topRight: Radius.circular(20),
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  child: Text(
                    m.answer ?? '',
                    style: AppTokens.body(context).copyWith(
                      color: AppTokens.ink(context),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildComposer() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
            AppTokens.s16, AppTokens.s8, AppTokens.s16, AppTokens.s12),
        decoration: BoxDecoration(
          color: AppTokens.scaffold(context),
          border: Border(
            top: BorderSide(
                color: AppTokens.border(context).withOpacity(0.6),
                width: 0.5),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _explainController,
                focusNode: _focusNode,
                cursorColor: AppTokens.accent(context),
                style: AppTokens.body(context),
                keyboardType: TextInputType.text,
                textInputAction: TextInputAction.send,
                textCapitalization: TextCapitalization.sentences,
                minLines: 1,
                maxLines: 4,
                onSubmitted: _sendMessage,
                decoration: InputDecoration(
                  isDense: true,
                  filled: true,
                  fillColor: AppTokens.surface(context),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppTokens.s16, vertical: 12),
                  hintText: 'Ask a clinical question…',
                  hintStyle: AppTokens.body(context).copyWith(
                    color: AppTokens.muted(context),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: AppTokens.radius20,
                    borderSide: BorderSide(
                        color: AppTokens.border(context), width: 0.5),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: AppTokens.radius20,
                    borderSide: BorderSide(
                        color: AppTokens.border(context), width: 0.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: AppTokens.radius20,
                    borderSide: BorderSide(
                        color: AppTokens.accent(context), width: 1.4),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppTokens.s8),
            GestureDetector(
              onTap: () => _sendMessage(_explainController.text),
              child: Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppTokens.accent(context),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.send_rounded,
                    color: Colors.white, size: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  const _SuggestionChip({Key? key, required this.text, required this.onTap})
      : super(key: key);
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppTokens.s12, vertical: 8),
        decoration: BoxDecoration(
          color: AppTokens.accentSoft(context),
          borderRadius: AppTokens.radius20,
        ),
        child: Text(
          text,
          style: AppTokens.caption(context).copyWith(
            color: AppTokens.accent(context),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
