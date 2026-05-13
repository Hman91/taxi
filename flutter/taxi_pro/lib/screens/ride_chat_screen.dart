import 'package:flutter/material.dart';

import '../app_locale.dart';
import '../l10n/app_localizations.dart';
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
  static const yellowDeep = Color(0xFFE6A800);
  static const charcoal = Color(0xFF1A1A1A);
  static const success = Color(0xFF1A7A4A);
  static const successBg = Color(0xFFD4EDDA);
  static const info = Color(0xFF1E3A8A);
  static const infoBg = Color(0xFFDEEBFF);
}

class _ChatAvatar extends StatelessWidget {
  const _ChatAvatar({required this.label, required this.mine});

  final String label;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        gradient: mine
            ? const LinearGradient(colors: [_C.yellow, Color(0xFFFFD84D)])
            : const LinearGradient(colors: [Colors.white, _C.panelSoft]),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: mine ? _C.yellowDeep : _C.border),
      ),
      child: Center(
        child: Text(
          label,
          style: const TextStyle(
            color: _C.charcoal,
            fontWeight: FontWeight.w900,
            fontSize: 10,
          ),
        ),
      ),
    );
  }
}

class RideChatScreen extends StatefulWidget {
  const RideChatScreen({
    super.key,
    required this.token,
    required this.myUserId,
    required this.rideId,
    required this.conversationId,
    this.showDriverQuickReplies = false,
  });

  final String token;
  final int myUserId;
  final int rideId;
  final int conversationId;
  final bool showDriverQuickReplies;

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
  static const List<String> _driverQuickReplies = [
    'أنا في الطريق',
    'وصلت',
    'أنا أمام الفندق',
    'أنا أمام المطار',
    'أنا عند المدخل',
    'أنا بالخارج',
    'أنا قريب منك',
    'سأصل بعد دقيقتين',
    'تأخير بسيط',
    'أين أنت؟',
    'أرسل موقعك',
    'أنا بانتظارك',
    'تفضل بالخروج',
    'أنا عند البوابة',
    'وصلت إلى الموقع',
    'اتصل بي عند الوصول',
    'تم التأكيد',
    'الرحلة جاهزة',
    'شكرًا لك',
    'يوم سعيد',
    'للمطار ✈️',
    'أنا في قاعة الوصول',
    'أنا عند بوابة الوصول',
    'أنا في موقف التاكسي',
    'أحمل لافتة باسمك',
    'هل استلمت أمتعتك؟',
    'بأسلوب احترافي',
    'مرحبًا، أنا سائقك',
    'يسعدني خدمتك',
    'في خدمتك دائمًا',
    'رحلة موفقة',
    'أهلاً وسهلاً بك',
  ];

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

  String _initials(String? name, bool mine) {
    final source = (name ?? '').trim();
    if (source.isEmpty) return mine ? 'ME' : '?';
    final parts =
        source.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    String first(String value) => value.isEmpty ? '?' : value[0].toUpperCase();
    if (parts.length == 1) return first(parts.first);
    return '${first(parts.first)}${first(parts.last)}';
  }

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  void _connectSocket() {
    _repo.socket.connect(
      widget.token,
      onReceiveMessage: _onIncoming,
      onRideStatus: _onRideStatus,
      onConnected: () {
        _repo.socket.joinConversation(widget.conversationId);
      },
      onError: (data) {
        if (!mounted) return;
        final code = (data['code'] ?? 'chat_socket_error').toString();
        // Socket transport / auth issues are non-fatal: messages still send via REST.
        if (code == 'unauthorized') {
          setState(() => _error = code);
          return;
        }
        debugPrint('Chat socket server error: $data');
      },
      onConnectError: (dynamic err) {
        debugPrint('Chat socket connect_error: $err');
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
    if (code == 'chat_socket_not_connected' ||
        code == 'chat_socket_connect_error') {
      if (lang.startsWith('ar')) return 'الاتصال غير متاح حاليا. حاول مجددا.';
      if (lang.startsWith('fr')) return 'Connexion indisponible. Reessayez.';
      if (lang.startsWith('es'))
        return 'Conexion no disponible. Intentalo de nuevo.';
      if (lang.startsWith('de'))
        return 'Verbindung nicht verfugbar. Bitte erneut versuchen.';
      if (lang.startsWith('it')) return 'Connessione non disponibile. Riprova.';
      if (lang.startsWith('ru'))
        return 'Соединение недоступно. Попробуйте снова.';
      if (lang.startsWith('zh')) return '连接不可用，请重试。';
      return 'Connection unavailable. Please try again.';
    }
    if (code == 'forbidden' ||
        code == 'unauthorized' ||
        code == 'chat_not_open') {
      return AppLocalizations.of(context)!.chatUnavailable;
    }
    return code;
  }

  Future<void> _syncLanguage(BuildContext context) async {
    final lang = Localizations.localeOf(context).languageCode;
    applyPreferredLanguageToApp(lang);
    try {
      await _api.patchPreferredLanguage(
          token: widget.token, preferredLanguage: lang);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(AppLocalizations.of(context)!.profileLanguageSynced)),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
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

  void _applyQuickReply(String phrase) {
    _textCtrl.value = TextEditingValue(
      text: phrase,
      selection: TextSelection.collapsed(offset: phrase.length),
    );
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
        backgroundColor: _C.yellow,
        elevation: 0,
        foregroundColor: _C.charcoal,
        centerTitle: true,
        title: Column(
          children: [
            Text(
              l.chatScreenTitle,
              style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  color: _C.charcoal,
                  fontSize: 16),
            ),
            const Text(
              'Live conversation',
              style: TextStyle(
                  color: _C.textStrong,
                  fontWeight: FontWeight.w600,
                  fontSize: 10.5),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            style: TextButton.styleFrom(
              foregroundColor: _C.charcoal,
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
            Container(
              margin: const EdgeInsets.fromLTRB(14, 12, 14, 0),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFFFFF), Color(0xFFFFF8E0)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: _C.border),
                boxShadow: [
                  BoxShadow(
                    color: _C.charcoal.withOpacity(0.07),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _C.successBg,
                    borderRadius: BorderRadius.circular(17),
                    border: Border.all(color: _C.success.withOpacity(0.18)),
                  ),
                  child: const Icon(Icons.forum_rounded,
                      color: _C.success, size: 21),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l.chatScreenTitle,
                          style: const TextStyle(
                            color: _C.textStrong,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${_messages.length} messages · Ride #${widget.rideId}',
                          style: const TextStyle(
                            color: _C.textSoft,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ]),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(
                    color: _C.successBg,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: _C.success.withOpacity(0.18)),
                  ),
                  child: const Text(
                    'Online',
                    style: TextStyle(
                        color: _C.success,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w900),
                  ),
                ),
              ]),
            ),
            if (_loading)
              LinearProgressIndicator(
                minHeight: 2,
                color: _C.yellow,
                backgroundColor: _C.border,
              ),
            if (_error != null)
              Container(
                margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: _C.danger.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _C.danger.withOpacity(0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        color: _C.danger, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _localizedChatError(context, _error!),
                        style:
                            const TextStyle(color: _C.danger, fontSize: 12.5),
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 12),
                    itemCount: _messages.length,
                    itemBuilder: (context, i) {
                      final m = _messages[i];
                      final mine = m.senderUserId == widget.myUserId;
                      final ts = _timeLabel(m.createdAt);
                      return AnimatedPadding(
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.easeOutCubic,
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: mine
                              ? MainAxisAlignment.end
                              : MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (!mine) ...[
                              _ChatAvatar(
                                  label: _initials(m.senderName, mine),
                                  mine: false),
                              const SizedBox(width: 7),
                            ],
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 13, vertical: 10),
                                constraints: BoxConstraints(
                                    maxWidth: MediaQuery.sizeOf(context).width *
                                        0.76),
                                decoration: BoxDecoration(
                                  gradient: mine
                                      ? const LinearGradient(
                                          colors: [
                                            _C.yellow,
                                            Color(0xFFFFD84D)
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        )
                                      : const LinearGradient(
                                          colors: [Colors.white, _C.panelSoft],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(20),
                                    topRight: const Radius.circular(20),
                                    bottomLeft: Radius.circular(mine ? 20 : 6),
                                    bottomRight: Radius.circular(mine ? 6 : 20),
                                  ),
                                  border: Border.all(
                                      color: mine
                                          ? _C.yellowDeep.withOpacity(0.35)
                                          : _C.border),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _C.charcoal.withOpacity(0.06),
                                      blurRadius: 14,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (!mine &&
                                        (m.senderName ?? '').trim().isNotEmpty)
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 4),
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
                                        height: 1.25,
                                        fontWeight: mine
                                            ? FontWeight.w700
                                            : FontWeight.w500,
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
                                              color: mine
                                                  ? _C.textStrong
                                                      .withOpacity(0.72)
                                                  : _C.textSoft,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            if (mine) ...[
                              const SizedBox(width: 7),
                              _ChatAvatar(
                                  label: _initials(m.senderName, mine),
                                  mine: true),
                            ],
                          ],
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
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.96),
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(color: _C.border),
                    boxShadow: [
                      BoxShadow(
                          color: _C.charcoal.withOpacity(0.10),
                          blurRadius: 22,
                          offset: const Offset(0, 10))
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                    child: Column(
                      children: [
                        if (widget.showDriverQuickReplies)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: SizedBox(
                              height: 34,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: _driverQuickReplies.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(width: 6),
                                itemBuilder: (context, index) {
                                  final phrase = _driverQuickReplies[index];
                                  return ActionChip(
                                    label: Text(
                                      phrase,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: _C.textStrong,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    side: const BorderSide(color: _C.border),
                                    backgroundColor: _C.panelSoft,
                                    onPressed: () => _applyQuickReply(phrase),
                                  );
                                },
                              ),
                            ),
                          ),
                        Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: _C.panelSoft,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: _C.border),
                              ),
                              child: const Icon(Icons.add_rounded,
                                  color: _C.textSoft, size: 20),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _textCtrl,
                                decoration: InputDecoration(
                                  hintText: l.messageFieldHint,
                                  hintStyle:
                                      const TextStyle(color: _C.textSoft),
                                  filled: true,
                                  fillColor: _C.panelSoft,
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 10),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(18),
                                    borderSide:
                                        const BorderSide(color: _C.border),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(18),
                                    borderSide:
                                        const BorderSide(color: _C.border),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(18),
                                    borderSide: const BorderSide(
                                        color: _C.yellowDeep, width: 2),
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
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: _sending ? _C.panelSoft : _C.yellow,
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: _sending
                                    ? []
                                    : [
                                        BoxShadow(
                                            color: _C.yellow.withOpacity(0.32),
                                            blurRadius: 14,
                                            offset: const Offset(0, 6))
                                      ],
                              ),
                              child: IconButton(
                                onPressed: _sending ? null : _send,
                                icon: const Icon(Icons.send_rounded, size: 19),
                                color: _C.charcoal,
                                tooltip: l.sendChatMessage,
                              ),
                            ),
                          ],
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
