// Cortex AI v2/v3 — MobX store
//
// Plain Dart MobX store (no codegen — uses Observable<T> directly so the
// dev doesn't need to run build_runner). Mirrors the InternetStore base
// pattern that every other store in the app extends.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:mobx/mobx.dart';

import '../../../models/cortex_models.dart';
import '../../dashboard/store/internet_check_store.dart';
import '../cortex_service.dart';

class CortexStore extends InternetStore {
  final CortexService _service = CortexService();

  // ── Usage ───────────────────────────────────────────────────────────────
  final Observable<CortexUsage> usage = Observable<CortexUsage>(CortexUsage.empty());

  Future<void> refreshUsage() async {
    try {
      final u = await _service.getUsage();
      runInAction(() => usage.value = u);
    } catch (e) {
      debugPrint('[CortexStore] refreshUsage failed: $e');
    }
  }

  // ── Chat list ──────────────────────────────────────────────────────────
  final ObservableList<CortexChat> chats = ObservableList<CortexChat>();
  final Observable<bool> chatsLoading = Observable<bool>(false);

  Future<void> loadChats({String? contextKind, bool? archived}) async {
    runInAction(() => chatsLoading.value = true);
    try {
      final list = await _service.listChats(contextKind: contextKind, archived: archived);
      runInAction(() {
        chats.clear();
        chats.addAll(list);
      });
    } catch (e) {
      debugPrint('[CortexStore] loadChats failed: $e');
    } finally {
      runInAction(() => chatsLoading.value = false);
    }
  }

  // ── Active chat (open in viewer) ───────────────────────────────────────
  final Observable<CortexChat?> activeChat = Observable<CortexChat?>(null);
  final ObservableList<CortexMessage> activeMessages = ObservableList<CortexMessage>();
  final Observable<bool> chatLoading = Observable<bool>(false);
  final Observable<bool> sending = Observable<bool>(false);
  // The id of the temp/assistant message currently being streamed in. Null
  // when not streaming. The UI reads this to show a typing indicator + apply
  // delta updates to the right bubble.
  final Observable<String?> streamingMessageId = Observable<String?>(null);
  StreamSubscription<CortexStreamEvent>? _streamSub;

  Future<void> openChat(String chatId) async {
    runInAction(() => chatLoading.value = true);
    try {
      final data = await _service.getChat(chatId);
      final chat = CortexChat.fromJson(data['chat'] as Map<String, dynamic>);
      final msgs = (data['messages'] as List? ?? [])
          .map((m) => CortexMessage.fromJson(m as Map<String, dynamic>))
          .where((m) => m.role != 'system') // don't show system context to user
          .toList();
      runInAction(() {
        activeChat.value = chat;
        activeMessages.clear();
        activeMessages.addAll(msgs);
      });
    } catch (e) {
      debugPrint('[CortexStore] openChat failed: $e');
    } finally {
      runInAction(() => chatLoading.value = false);
    }
  }

  void closeActiveChat() {
    _streamSub?.cancel();
    runInAction(() {
      activeChat.value = null;
      activeMessages.clear();
      streamingMessageId.value = null;
    });
  }

  // Send a message with streaming. Optimistic-appends both bubbles; the
  // assistant bubble's text grows as deltas arrive. On `done` we capture
  // input/output tokens; on `meta` we replace the optimistic IDs with real
  // ones from the server.
  Future<void> sendMessageStreaming(String content, {List<String>? images}) async {
    final chat = activeChat.value;
    if (chat == null || content.trim().isEmpty) return;

    runInAction(() => sending.value = true);

    // Optimistic user bubble
    final tmpUserId = '__tmp_user_${DateTime.now().millisecondsSinceEpoch}';
    final tmpAsstId = '__tmp_asst_${DateTime.now().millisecondsSinceEpoch}';
    final userMsg = CortexMessage(
      id: tmpUserId,
      chatId: chat.id,
      userId: chat.userId,
      role: 'user',
      content: content,
      images: images ?? const [],
      createdAt: DateTime.now(),
    );
    final asstStub = CortexMessage(
      id: tmpAsstId,
      chatId: chat.id,
      userId: chat.userId,
      role: 'assistant',
      content: '',
      createdAt: DateTime.now(),
    );
    runInAction(() {
      activeMessages.add(userMsg);
      activeMessages.add(asstStub);
      streamingMessageId.value = tmpAsstId;
    });

    // Stream
    final completer = Completer<void>();
    _streamSub?.cancel();
    _streamSub = _service.streamMessage(chat.id, content, images: images).listen((ev) {
      if (ev is CortexDelta) {
        runInAction(() {
          final idx = activeMessages.indexWhere((m) => m.id == streamingMessageId.value);
          if (idx == -1) return;
          activeMessages[idx] = activeMessages[idx].withAppendedText(ev.text);
        });
      } else if (ev is CortexMeta) {
        // Replace optimistic IDs with real server IDs
        runInAction(() {
          if (ev.userMessageId != null) {
            final ui = activeMessages.indexWhere((m) => m.id == tmpUserId);
            if (ui != -1) activeMessages[ui] = _replaceId(activeMessages[ui], ev.userMessageId!);
          }
          if (ev.assistantMessageId != null) {
            final ai = activeMessages.indexWhere((m) => m.id == streamingMessageId.value);
            if (ai != -1) {
              activeMessages[ai] = _replaceId(activeMessages[ai], ev.assistantMessageId!);
              streamingMessageId.value = ev.assistantMessageId;
            }
          }
        });
      } else if (ev is CortexDone) {
        // Final token tally — useful for analytics
      } else if (ev is CortexError) {
        runInAction(() {
          final idx = activeMessages.indexWhere((m) => m.id == streamingMessageId.value);
          if (idx != -1) {
            activeMessages[idx] = _replaceContent(
              activeMessages[idx],
              activeMessages[idx].content.isEmpty
                  ? '⚠️ ${ev.message}'
                  : '${activeMessages[idx].content}\n\n⚠️ ${ev.message}',
            );
          }
        });
      }
    }, onDone: () {
      runInAction(() {
        sending.value = false;
        streamingMessageId.value = null;
      });
      // Refresh usage badge after each turn
      refreshUsage();
      completer.complete();
    }, onError: (e) {
      runInAction(() {
        sending.value = false;
        streamingMessageId.value = null;
      });
      completer.complete();
    });
    return completer.future;
  }

  // Non-streaming fallback (used when streaming fails / is disabled)
  Future<void> sendMessageSimple(String content, {List<String>? images}) async {
    final chat = activeChat.value;
    if (chat == null) return;
    runInAction(() => sending.value = true);
    try {
      final data = await _service.sendMessage(chat.id, content, images: images);
      final user = CortexMessage.fromJson(data['user_message'] as Map<String, dynamic>);
      final asst = CortexMessage.fromJson(data['assistant_message'] as Map<String, dynamic>);
      runInAction(() {
        activeMessages.add(user);
        activeMessages.add(asst);
      });
      refreshUsage();
    } catch (e) {
      debugPrint('[CortexStore] sendMessageSimple failed: $e');
      rethrow;
    } finally {
      runInAction(() => sending.value = false);
    }
  }

  // Create a chat (and optionally fire the first message) — handy for
  // mode/MCQ entry points.
  Future<CortexChat?> startChat({
    required String contextKind,
    String? questionId,
    String? examId,
    String? userExamId,
    String? topicName,
    String? subtopicName,
    String? firstMessage,
    String? title,
  }) async {
    try {
      final data = await _service.createChat(
        contextKind: contextKind,
        questionId: questionId,
        examId: examId,
        userExamId: userExamId,
        topicName: topicName,
        subtopicName: subtopicName,
        firstMessage: firstMessage,
        title: title,
      );
      final chat = CortexChat.fromJson(data['chat'] as Map<String, dynamic>);
      // Append optimistic state if first_reply is included
      runInAction(() {
        activeChat.value = chat;
        activeMessages.clear();
      });
      if (data['first_reply'] != null) {
        final reply = data['first_reply'] as Map<String, dynamic>;
        final user = CortexMessage.fromJson(reply['user_message'] as Map<String, dynamic>);
        final asst = CortexMessage.fromJson(reply['assistant_message'] as Map<String, dynamic>);
        runInAction(() {
          activeMessages.add(user);
          activeMessages.add(asst);
        });
      }
      refreshUsage();
      return chat;
    } catch (e) {
      debugPrint('[CortexStore] startChat failed: $e');
      return null;
    }
  }

  // Find an existing MCQ-anchored chat for this question, or create one.
  // Used by the in-MCQ Ask Cortex panel so subsequent taps reuse the chat.
  Future<CortexChat?> findOrCreateMcqChat({
    required String questionId,
    String? examId,
    String? userExamId,
  }) async {
    try {
      final all = await _service.listChats(contextKind: 'mcq');
      final found = all.firstWhere(
        (c) => c.contextQuestionId == questionId,
        orElse: () => CortexChat(id: '', userId: '', title: '', contextKind: ''),
      );
      if (found.id.isNotEmpty) {
        await openChat(found.id);
        return found;
      }
      return await startChat(
        contextKind: 'mcq',
        questionId: questionId,
        examId: examId,
        userExamId: userExamId,
      );
    } catch (e) {
      debugPrint('[CortexStore] findOrCreateMcqChat failed: $e');
      return null;
    }
  }

  Future<void> deleteChat(String chatId) async {
    await _service.deleteChat(chatId);
    runInAction(() => chats.removeWhere((c) => c.id == chatId));
  }

  Future<void> patchChat(String chatId, {String? title, bool? pinned, bool? archived}) async {
    await _service.patchChat(chatId, title: title, pinned: pinned, archived: archived);
    final i = chats.indexWhere((c) => c.id == chatId);
    if (i != -1) {
      // Quick local mutation — full reload happens on next list refresh
      // (server is the source of truth)
    }
  }

  // ── Snippets ───────────────────────────────────────────────────────────
  final ObservableList<CortexMessage> snippets = ObservableList<CortexMessage>();

  Future<void> loadSnippets() async {
    final list = await _service.listSnippets();
    runInAction(() {
      snippets.clear();
      snippets.addAll(list);
    });
  }

  Future<bool> toggleSnippet(String messageId, {bool? save, String? note}) async {
    final saved = await _service.toggleSnippet(messageId, save: save, note: note);
    // Mutate local active message if present
    runInAction(() {
      final idx = activeMessages.indexWhere((m) => m.id == messageId);
      if (idx != -1) {
        final m = activeMessages[idx];
        activeMessages[idx] = CortexMessage(
          id: m.id,
          chatId: m.chatId,
          userId: m.userId,
          role: m.role,
          content: m.content,
          images: m.images,
          attachedQuestionId: m.attachedQuestionId,
          model: m.model,
          inputTokens: m.inputTokens,
          outputTokens: m.outputTokens,
          finishReason: m.finishReason,
          error: m.error,
          latencyMs: m.latencyMs,
          userRating: m.userRating,
          savedSnippet: saved,
          snippetNote: note ?? m.snippetNote,
          snippetSavedAt: saved ? DateTime.now() : null,
          suggestedFollowups: m.suggestedFollowups,
          mermaidSource: m.mermaidSource,
          generatedFlashcardsCount: m.generatedFlashcardsCount,
          createdAt: m.createdAt,
        );
      }
    });
    return saved;
  }

  // ── Memory ─────────────────────────────────────────────────────────────
  final Observable<CortexMemory> memory = Observable<CortexMemory>(CortexMemory.empty());

  Future<void> loadMemory() async {
    runInAction(() async => memory.value = await _service.getMemory());
  }

  Future<void> updateMemory({String? notes, CortexPreferences? preferences}) async {
    final updated = await _service.updateMemory(notes: notes, preferences: preferences);
    runInAction(() => memory.value = updated);
  }

  // ── Quick prompts ──────────────────────────────────────────────────────
  final Observable<CortexQuickPrompts> quickPrompts = Observable<CortexQuickPrompts>(CortexQuickPrompts());

  Future<void> loadQuickPrompts({String contextKind = 'general'}) async {
    final qp = await _service.getQuickPrompts(contextKind: contextKind);
    runInAction(() => quickPrompts.value = qp);
  }

  // ── Service passthroughs (UI calls these directly when no state caching needed) ──
  CortexService get service => _service;

  // ── Helpers ────────────────────────────────────────────────────────────
  CortexMessage _replaceId(CortexMessage m, String newId) => CortexMessage(
        id: newId,
        chatId: m.chatId,
        userId: m.userId,
        role: m.role,
        content: m.content,
        images: m.images,
        attachedQuestionId: m.attachedQuestionId,
        model: m.model,
        inputTokens: m.inputTokens,
        outputTokens: m.outputTokens,
        finishReason: m.finishReason,
        error: m.error,
        latencyMs: m.latencyMs,
        userRating: m.userRating,
        savedSnippet: m.savedSnippet,
        snippetNote: m.snippetNote,
        snippetSavedAt: m.snippetSavedAt,
        suggestedFollowups: m.suggestedFollowups,
        mermaidSource: m.mermaidSource,
        generatedFlashcardsCount: m.generatedFlashcardsCount,
        createdAt: m.createdAt,
      );

  CortexMessage _replaceContent(CortexMessage m, String newContent) => CortexMessage(
        id: m.id,
        chatId: m.chatId,
        userId: m.userId,
        role: m.role,
        content: newContent,
        images: m.images,
        attachedQuestionId: m.attachedQuestionId,
        model: m.model,
        inputTokens: m.inputTokens,
        outputTokens: m.outputTokens,
        finishReason: m.finishReason,
        error: m.error,
        latencyMs: m.latencyMs,
        userRating: m.userRating,
        savedSnippet: m.savedSnippet,
        snippetNote: m.snippetNote,
        snippetSavedAt: m.snippetSavedAt,
        suggestedFollowups: m.suggestedFollowups,
        mermaidSource: m.mermaidSource,
        generatedFlashcardsCount: m.generatedFlashcardsCount,
        createdAt: m.createdAt,
      );
}
