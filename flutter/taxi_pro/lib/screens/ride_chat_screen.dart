import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/chat_message.dart';
import '../repositories/chat_repository.dart';
import '../services/taxi_app_service.dart';

class RideChatScreen extends StatefulWidget {
  const RideChatScreen({
    super.key,
    required this.token,
    required this.myUserId,
    required this.rideId,
    required this.conversationId,
  });

  final String token;
  final int myUserId;
  final int rideId;
  final int conversationId;

  @override
  State<RideChatScreen> createState() => _RideChatScreenState();
}

class _RideChatScreenState extends State<RideChatScreen> {
  final _api = TaxiAppService();
  final _repo = ChatRepository();
  final _textCtrl = TextEditingController();
  final _scroll = ScrollController();
  final _seenIds = <int>{};

  List<ChatMessage> _messages = [];
  String? _error;
  bool _loading = true;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _repo.loadMessages(
        token: widget.token,
        conversationId: widget.conversationId,
      );
      for (final m in list) {
        _seenIds.add(m.id);
      }
      if (!mounted) return;
      setState(() {
        _messages = list;
        _loading = false;
      });
      _repo.socket.connect(
        widget.token,
        onReceiveMessage: _onIncoming,
        onRideStatus: _onRideStatus,
        onError: (_) {},
      );
      _repo.socket.joinConversation(widget.conversationId);
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToEnd());
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  void _onIncoming(Map<String, dynamic> data) {
    final m = ChatMessage.fromJson(data);
    if (_seenIds.contains(m.id)) return;
    _seenIds.add(m.id);
    if (!mounted) return;
    setState(() => _messages = [..._messages, m]);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToEnd());
  }

  void _onRideStatus(Map<String, dynamic> data) {
    final ride = data['ride'];
    if (ride is! Map) return;
    final id = (ride['id'] as num?)?.toInt();
    if (id != widget.rideId || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppLocalizations.of(context)!.rideStatusFmt(ride['status']?.toString() ?? ''),
        ),
      ),
    );
  }

  void _scrollToEnd() {
    if (!_scroll.hasClients) return;
    _scroll.jumpTo(_scroll.position.maxScrollExtent);
  }

  Future<void> _syncLanguage(BuildContext context) async {
    final lang = Localizations.localeOf(context).languageCode;
    try {
      await _api.patchPreferredLanguage(token: widget.token, preferredLanguage: lang);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.profileLanguageSynced)),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _send() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      _repo.socket.sendMessage(conversationId: widget.conversationId, text: text);
      _textCtrl.clear();
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  void dispose() {
    _repo.socket.leaveConversation(widget.conversationId);
    _repo.socket.disconnect();
    _textCtrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.chatScreenTitle),
        actions: [
          IconButton(
            tooltip: l.syncPreferredLanguage,
            onPressed: () => _syncLanguage(context),
            icon: const Icon(Icons.translate),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_loading) LinearProgressIndicator(minHeight: 2, color: Colors.amber.shade800),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            ),
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: _messages.length,
              itemBuilder: (context, i) {
                final m = _messages[i];
                final mine = m.senderUserId == widget.myUserId;
                return Align(
                  alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.82),
                    decoration: BoxDecoration(
                      color: mine ? Colors.amber.shade100 : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(m.displayText),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textCtrl,
                      decoration: InputDecoration(
                        hintText: l.messageFieldHint,
                        border: const OutlineInputBorder(),
                        isDense: true,
                      ),
                      minLines: 1,
                      maxLines: 4,
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _sending ? null : _send,
                    child: Text(l.sendChatMessage),
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
