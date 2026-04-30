import 'package:flutter/material.dart';

import '../app_locale.dart';
import '../l10n/app_localizations.dart';
import '../theme/taxi_app_theme.dart';
import '../l10n/ride_status_localization.dart';
import '../models/chat_message.dart';
import '../repositories/chat_repository.dart';
import '../services/taxi_app_service.dart';

class _C {
  static const bgTop = Color(0xFFFAF8F2);
  static const bgBottom = Color(0xFFF7F3E8);
  static const panel = Color(0xFFFFFFFF);
  static const panelSoft = Color(0xFFF5F1E8);
  static const border = Color(0xFFDDD8C8);
  static const textStrong = Color(0xFF1A1A1A);
  static const textSoft = Color(0xFF5C5C5C);
  static const danger = Color(0xFFFF6B6B);
  static const yellow = Color(0xFFFFC200);
  static const yellowSoft = Color(0xFFFFF8E0);
  static const yellowDeep = Color(0xFFE6A800);
  static const charcoal = Color(0xFF1A1A1A);
}

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
  bool _socketReady = false;

  Widget _module({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: _C.panel,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _C.border),
        boxShadow: [
          BoxShadow(
            color: _C.charcoal.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }

  String _timeLabel(String? iso) {
    if (iso == null || iso.trim().isEmpty) return '';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '';
    final local = dt.toLocal();
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  void _connectSocket() {
    _repo.socket.connect(
      widget.token,
      transports: const ['polling'],
      onReceiveMessage: _onIncoming,
      onRideStatus: _onRideStatus,
      onConnected: () {
        _repo.socket.joinConversation(widget.conversationId);
        if (!mounted) return;
        setState(() {
          _socketReady = true;
          if (_error == 'chat_socket_connect_error' ||
              _error == 'chat_socket_not_connected') {
            _error = null;
          }
        });
      },
      onDisconnected: () {
        if (!mounted) return;
        setState(() => _socketReady = false);
      },
      onError: (data) {
        if (!mounted) return;
        setState(() {
          _error = (data['code'] ?? 'chat_socket_error').toString();
        });
      },
      onConnectError: (err) {
        if (!mounted) return;
        setState(() {
          _socketReady = false;
          _error = 'chat_socket_connect_error';
        });
      },
    );
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
      _connectSocket();
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
    final message = (data['message'] as String?)?.trim();
    final l = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message?.isNotEmpty == true
            ? message!
            : l.rideStatusFmt(
                localizedRideStatusLabel(l, ride['status']?.toString()),
              )),
      ),
    );
  }

  void _scrollToEnd() {
    if (!_scroll.hasClients) return;
    _scroll.jumpTo(_scroll.position.maxScrollExtent);
  }

  String _localizedChatError(BuildContext context, String raw) {
    final code = raw.trim();
    final lang = Localizations.localeOf(context).languageCode.toLowerCase();
    if (code == 'chat_socket_not_connected' || code == 'chat_socket_connect_error') {
      if (lang.startsWith('ar')) return 'الاتصال غير متاح حاليا. حاول مجددا.';
      if (lang.startsWith('fr')) return 'Connexion indisponible. Reessayez.';
      if (lang.startsWith('es')) return 'Conexion no disponible. Intentalo de nuevo.';
      if (lang.startsWith('de')) return 'Verbindung nicht verfugbar. Bitte erneut versuchen.';
      if (lang.startsWith('it')) return 'Connessione non disponibile. Riprova.';
      if (lang.startsWith('ru')) return 'Соединение недоступно. Попробуйте снова.';
      if (lang.startsWith('zh')) return '连接不可用，请重试。';
      return 'Connection unavailable. Please try again.';
    }
    if (code == 'forbidden' || code == 'unauthorized' || code == 'chat_not_open') {
      return AppLocalizations.of(context)!.chatUnavailable;
    }
    return code;
  }

  Future<void> _syncLanguage(BuildContext context) async {
    final lang = Localizations.localeOf(context).languageCode;
    applyPreferredLanguageToApp(lang);
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
      final sent = await _repo.sendMessage(
        token: widget.token,
        conversationId: widget.conversationId,
        text: text,
      );
      if (!_seenIds.contains(sent.id)) {
        _seenIds.add(sent.id);
        if (mounted) {
          setState(() => _messages = [..._messages, sent]);
        }
      }
      _textCtrl.clear();
      if (_error != null) {
        setState(() => _error = null);
      }
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToEnd());
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
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
      backgroundColor: _C.bgBottom,
      appBar: AppBar(
        backgroundColor: _C.charcoal,
        elevation: 0,
        foregroundColor: _C.yellow,
        centerTitle: true,
        title: Text(
          l.chatScreenTitle,
          style: const TextStyle(fontWeight: FontWeight.w800, color: _C.yellow),
        ),
        actions: [
          TextButton.icon(
            style: TextButton.styleFrom(
              foregroundColor: _C.yellow,
              textStyle: const TextStyle(fontWeight: FontWeight.w700),
            ),
            onPressed: () => _syncLanguage(context),
            icon: const Icon(Icons.translate, size: 18),
            label: Text(l.language),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [_C.bgTop, _C.bgBottom],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
        children: [
          if (_loading)
            LinearProgressIndicator(
              minHeight: 2,
              color: _C.yellow,
              backgroundColor: _C.border,
            ),
          if (_error != null)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: _C.danger.withOpacity(0.16),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _C.danger.withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, color: _C.danger, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _localizedChatError(context, _error!),
                      style: const TextStyle(color: _C.danger, fontSize: 12.5),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
              child: _module(
                child: ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  itemCount: _messages.length,
                  itemBuilder: (context, i) {
                    final m = _messages[i];
                    final mine = m.senderUserId == widget.myUserId;
                    final ts = _timeLabel(m.createdAt);
                    return Align(
                      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.82),
                        decoration: BoxDecoration(
                          gradient: mine
                              ? const LinearGradient(
                                  colors: [_C.yellow, Color(0xFFFFD84D)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : null,
                          color: mine ? null : _C.panelSoft,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: mine ? _C.yellowDeep.withOpacity(0.35) : _C.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!mine && (m.senderName ?? '').trim().isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Text(
                                  (m.senderName ?? '').trim(),
                                  style: const TextStyle(
                                    color: _C.textSoft,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            Text(
                              m.displayText,
                              style: TextStyle(
                                color: _C.textStrong,
                                fontWeight: mine ? FontWeight.w500 : FontWeight.w400,
                              ),
                            ),
                            if (ts.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 5),
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    ts,
                                    style: TextStyle(
                                      color: mine ? _C.textStrong.withOpacity(0.72) : _C.textSoft,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
              child: _module(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _textCtrl,
                          decoration: InputDecoration(
                            hintText: l.messageFieldHint,
                            hintStyle: const TextStyle(color: _C.textSoft),
                            filled: true,
                            fillColor: _C.panelSoft,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: _C.border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: _C.border),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: _C.yellowDeep, width: 2),
                            ),
                            isDense: true,
                          ),
                          style: const TextStyle(color: _C.textStrong),
                          minLines: 1,
                          maxLines: 4,
                          onSubmitted: (_) => _send(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: _C.yellow,
                          foregroundColor: _C.charcoal,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                        onPressed: _sending ? null : _send,
                        icon: const Icon(Icons.send_rounded, size: 16),
                        label: Text(
                          l.sendChatMessage,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }
}