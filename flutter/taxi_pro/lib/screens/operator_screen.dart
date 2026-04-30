import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../app_locale.dart' show AppUiRole, restoreUiRoleLocale;
import '../l10n/app_localizations.dart';
import '../l10n/place_localization.dart';
import '../l10n/ride_status_localization.dart';
import '../services/taxi_app_service.dart';
import '../theme/taxi_app_theme.dart';
import '../widgets/locale_popup_menu.dart';
import 'unified_login_screen.dart';

class _C {
  static const yellow = Color(0xFFFFC200);
  static const yellowSoft = Color(0xFFFFF8E0);
  static const yellowDeep = Color(0xFFE6A800);
  static const charcoal = Color(0xFF1A1A1A);
  static const bgWarm = Color(0xFFFAF8F2);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceAlt = Color(0xFFF5F1E8);
  static const border = Color(0xFFDDD8C8);
  static const textStrong = Color(0xFF111111);
  static const textMid = Color(0xFF3F3F3F);
  static const textSoft = Color(0xFF5C5C5C);
  static const danger = Color(0xFFB91C1C);
  static const dangerBg = Color(0xFFFFE4E4);
  static const info = Color(0xFF1D4ED8);
  static const success = Color(0xFF15803D);
}

InputDecoration _fd(String label, {Widget? suffixIcon}) => InputDecoration(
  labelText: label,
  suffixIcon: suffixIcon,
  filled: true,
  fillColor: _C.surfaceAlt,
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: _C.border, width: 1.4),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: _C.yellow, width: 2),
  ),
);

class _Module extends StatelessWidget {
  const _Module({required this.child, this.accent = false});
  final Widget child;
  final bool accent;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: _C.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: accent ? _C.yellowDeep : _C.border, width: accent ? 2 : 1),
          boxShadow: [BoxShadow(color: _C.charcoal.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 3))],
        ),
        child: Padding(padding: const EdgeInsets.all(16), child: child),
      );
}

Widget _kpiChip({required IconData icon, required String label}) => Container(
  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  decoration: BoxDecoration(
    color: _C.yellowSoft,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: _C.yellowDeep),
  ),
  child: Row(mainAxisSize: MainAxisSize.min, children: [
    Icon(icon, size: 16, color: _C.charcoal),
    const SizedBox(width: 6),
    Text(label, style: const TextStyle(color: _C.charcoal, fontWeight: FontWeight.w700, fontSize: 12)),
  ]),
);

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    required this.icon,
    this.color = _C.charcoal,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: color.withOpacity(0.7),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
}

Widget _rowInfoCard({
  required IconData icon,
  required Widget content,
  Widget? trailing,
  Color iconBg = _C.surfaceAlt,
  Color iconColor = _C.charcoal,
}) =>
    Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _C.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _C.border),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: _C.border),
            ),
            child: Icon(icon, color: iconColor, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(child: content),
          if (trailing != null) ...[const SizedBox(width: 8), trailing],
        ],
      ),
    );

Widget _b2bStatusPill({required bool enabled}) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: enabled ? _C.yellowSoft : _C.dangerBg,
        borderRadius: BorderRadius.circular(50),
      ),
      child: Text(
        enabled ? 'Active' : 'Paused',
        style: TextStyle(
          color: enabled ? _C.charcoal : _C.danger,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );

class _SectionHead extends StatelessWidget {
  const _SectionHead(this.title, {this.subtitle, this.trailing});
  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            Container(width: 4, height: 20, decoration: BoxDecoration(color: _C.yellow, borderRadius: BorderRadius.circular(4))),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: _C.textStrong, fontWeight: FontWeight.w800, fontSize: 15)),
                  if (subtitle != null) Text(subtitle!, style: const TextStyle(color: _C.textSoft, fontSize: 12)),
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      );
}

class OperatorScreen extends StatefulWidget {
  const OperatorScreen({super.key, this.initialToken});
  final String? initialToken;

  @override
  State<OperatorScreen> createState() => _OperatorScreenState();
}

class _OperatorScreenState extends State<OperatorScreen>
    with SingleTickerProviderStateMixin {
  final _api = TaxiAppService();
  final _imagePicker = ImagePicker();
  final _secretController = TextEditingController(text: 'Operator2026');
  final _newDriverPhone = TextEditingController();
  final _newDriverName = TextEditingController();
  final _newDriverPin = TextEditingController();
  final _newDriverCarModel = TextEditingController();
  final _newDriverCarColor = TextEditingController();
  String _newDriverPhotoData = '';
  final _topUpAmountController = TextEditingController(text: '10');
  TabController? _tabController;
  bool _obscureOperatorPassword = true;
  String? _token;
  String? _message;
  List<Map<String, dynamic>> _trips = [];
  List<Map<String, dynamic>> _adminRides = [];
  List<Map<String, dynamic>> _driverPinAccounts = [];
  List<Map<String, dynamic>> _adminB2b = [];
  List<Map<String, dynamic>> _adminB2bBookings = [];
  List<Map<String, dynamic>> _flightArrivals = [];
  List<Map<String, dynamic>> _driverRatings = [];
  int? _topUpAccountId;
  bool _busy = false;
  Widget _appBarHomeLogo() => GestureDetector(
        onTap: () {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const UnifiedLoginScreen()),
          );
        },
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(color: _C.yellow, borderRadius: BorderRadius.circular(9)),
          child: const Icon(Icons.local_taxi_rounded, color: _C.charcoal, size: 18),
        ),
      );

  int _countByStatus(String status) => _adminRides
      .where((r) => (r['status'] ?? '').toString().trim() == status)
      .length;

  double get _tripVaultRevenue => _trips.fold<double>(
      0.0, (sum, t) => sum + ((t['fare'] as num?)?.toDouble() ?? 0.0));

  Future<void> _login() async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final r = await _api.login(
          role: 'operator', secret: _secretController.text.trim());
      _token = r.accessToken;
      await _refreshAll();
    } catch (e) {
      setState(() => _message = e.toString());
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _refreshAll() async {
    final t = _token;
    if (t == null) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final trips = await _api.listTrips(t);
      final rides = await _api.listAdminRides(t);
      final driverPins = await _api.listAdminDriverPinAccounts(t);
      final b2bTenants = await _api.listAdminB2bTenants(t);
      final b2bBookings = await _api.listAdminB2bBookings(t);
      final flights = await _api.listAdminTunisiaFlightArrivals(t);
      final ratings = await _api.listAdminDriverRatings(t);
      setState(() {
        _trips = trips
            .map(
              (e) => {
                'id': e.id,
                'date': e.date,
                'route': e.route,
                'fare': e.fare,
                'status': e.status,
              },
            )
            .toList();
        _adminRides = rides;
        _driverPinAccounts = driverPins;
        _adminB2b = b2bTenants;
        _adminB2bBookings = b2bBookings;
        _flightArrivals = flights;
        _driverRatings = ratings;
        final ids = driverPins
            .map((e) => (e['id'] as num?)?.toInt())
            .whereType<int>()
            .toList();
        if (_topUpAccountId != null &&
            !ids.contains(_topUpAccountId)) {
          _topUpAccountId = null;
        }
        _topUpAccountId ??= ids.isEmpty ? null : ids.first;
      });
    } catch (e) {
      final msg = e.toString();
      setState(
        () => _message = msg.contains('phone_exists_or_invalid')
            ? _uiText(
                en: 'Phone already exists or invalid.',
                ar: 'رقم الهاتف موجود مسبقا أو غير صالح.',
                fr: 'Le numero existe deja ou est invalide.',
                es: 'El telefono ya existe o no es valido.',
                de: 'Telefon existiert bereits oder ist ungueltig.',
                it: 'Il telefono esiste gia o non e valido.',
                ru: 'Телефон уже существует или недействителен.',
                zh: '电话号码已存在或无效。',
              )
            : msg,
      );
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _createDriverAccount() async {
    final t = _token;
    if (t == null) return;
    final phone = _newDriverPhone.text.trim();
    final name = _newDriverName.text.trim();
    final pin = _newDriverPin.text.trim();
    final carModel = _newDriverCarModel.text.trim();
    final carColor = _newDriverCarColor.text.trim();
    final photoUrl = _newDriverPhotoData.trim();
    final loc = AppLocalizations.of(context)!;
    if (phone.isEmpty ||
        name.isEmpty ||
        pin.isEmpty ||
        carModel.isEmpty ||
        carColor.isEmpty) {
      setState(() => _message = loc.operatorFillDriverFields);
      return;
    }
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await _api.createAdminDriverPinAccount(
        token: t,
        phone: phone,
        pin: pin,
        driverName: name,
        carModel: carModel,
        carColor: carColor,
        photoUrl: photoUrl,
      );
      _newDriverPhone.clear();
      _newDriverName.clear();
      _newDriverPin.clear();
      _newDriverCarModel.clear();
      _newDriverCarColor.clear();
      _newDriverPhotoData = '';
      await _refreshAll();
    } catch (e) {
      setState(() => _message = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _editDriverAccount(Map<String, dynamic> row) async {
    final t = _token;
    if (t == null) return;
    final id = (row['id'] as num?)?.toInt();
    if (id == null) return;
    final modelCtrl =
        TextEditingController(text: row['car_model']?.toString() ?? '');
    final colorCtrl =
        TextEditingController(text: row['car_color']?.toString() ?? '');
    final photoCtrl =
        TextEditingController(text: row['photo_url']?.toString() ?? '');
    String selectedPhotoData = photoCtrl.text.trim();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final loc = AppLocalizations.of(ctx)!;
        return StatefulBuilder(
          builder: (ctx, setSt) => AlertDialog(
          backgroundColor: _C.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: _C.border)),
          title: Text(row['driver_name']?.toString() ?? loc.operatorDriverNameLabel),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: modelCtrl,
                  decoration: _fd(loc.operatorCarModelLabel),
                ),
                TextField(
                  controller: colorCtrl,
                  decoration: _fd(loc.operatorCarColorLabel),
                ),
                const SizedBox(height: 8),
                if (selectedPhotoData.isNotEmpty)
                  Builder(
                    builder: (_) {
                      final provider = _imageProviderFromString(selectedPhotoData);
                      if (provider == null) return const SizedBox.shrink();
                      return Center(
                        child: SizedBox(
                          width: 220,
                          height: 90,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image(
                              image: provider,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await _imagePicker.pickImage(
                      source: ImageSource.gallery,
                      imageQuality: 80,
                      maxWidth: 1600,
                    );
                    if (picked == null) return;
                    final bytes = await picked.readAsBytes();
                    final name = picked.name.toLowerCase();
                    final ext = name.contains('.') ? name.split('.').last : 'jpeg';
                    final mime = ext == 'png'
                        ? 'image/png'
                        : ext == 'webp'
                            ? 'image/webp'
                            : 'image/jpeg';
                    final dataUrl = 'data:$mime;base64,${base64Encode(bytes)}';
                    if (!mounted) return;
                    setSt(() {
                      selectedPhotoData = dataUrl;
                    });
                  },
                  icon: const Icon(Icons.photo_library),
                  label: Text(loc.operatorPickFromGallery),
                ),
                if (selectedPhotoData.isNotEmpty &&
                    selectedPhotoData.startsWith('data:image/'))
                  TextButton.icon(
                    onPressed: () => setSt(() => selectedPhotoData = ''),
                    icon: const Icon(Icons.delete_outline),
                    label: Text(loc.operatorRemovePickedImage),
                  ),
                TextField(
                  controller: photoCtrl,
                  decoration: _fd(loc.operatorPhotoUrlOptional),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(loc.operatorCancel),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: _C.yellow,
                foregroundColor: _C.charcoal,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(loc.operatorSave),
            ),
          ],
          ),
        );
      },
    );
    if (ok != true) {
      modelCtrl.dispose();
      colorCtrl.dispose();
      photoCtrl.dispose();
      return;
    }
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await _api.patchAdminDriverPinAccount(
        token: t,
        accountId: id,
        payload: {
          'car_model': modelCtrl.text.trim(),
          'car_color': colorCtrl.text.trim(),
          'photo_url': selectedPhotoData.isNotEmpty
              ? selectedPhotoData
              : photoCtrl.text.trim(),
        },
      );
      await _refreshAll();
    } catch (e) {
      setState(() => _message = e.toString());
    } finally {
      modelCtrl.dispose();
      colorCtrl.dispose();
      photoCtrl.dispose();
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      restoreUiRoleLocale(AppUiRole.operator);
      final t = widget.initialToken;
      if (t != null && t.isNotEmpty && _token == null) {
        _token = t;
        _refreshAll();
      }
    });
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _secretController.dispose();
    _newDriverPhone.dispose();
    _newDriverName.dispose();
    _newDriverPin.dispose();
    _newDriverCarModel.dispose();
    _newDriverCarColor.dispose();
    _topUpAmountController.dispose();
    super.dispose();
  }

  ImageProvider<Object>? _imageProviderFromString(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    if (trimmed.startsWith('data:image/')) {
      final commaIdx = trimmed.indexOf(',');
      if (commaIdx > 0 && commaIdx + 1 < trimmed.length) {
        try {
          final b64 = trimmed.substring(commaIdx + 1);
          return MemoryImage(base64Decode(b64));
        } catch (_) {
          return null;
        }
      }
      return null;
    }
    return Uri.tryParse(trimmed)?.hasScheme == true ? NetworkImage(trimmed) : null;
  }

  Future<void> _pickNewDriverImage() async {
    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1600,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    final name = picked.name.toLowerCase();
    final ext = name.contains('.') ? name.split('.').last : 'jpeg';
    final mime = ext == 'png'
        ? 'image/png'
        : ext == 'webp'
            ? 'image/webp'
            : 'image/jpeg';
    if (!mounted) return;
    setState(() {
      _newDriverPhotoData = 'data:$mime;base64,${base64Encode(bytes)}';
    });
  }

  TextStyle _operatorHeadingTextStyle() => const TextStyle(
        color: _C.textStrong,
        fontWeight: FontWeight.w700,
        fontSize: 15,
      );

  InputDecoration _operatorFieldDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: _C.textMid, fontWeight: FontWeight.w600),
      filled: true,
      fillColor: _C.surfaceAlt,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(14)),
        borderSide: BorderSide(color: _C.border),
      ),
      enabledBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(14)),
        borderSide: BorderSide(color: _C.border, width: 1.4),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(14)),
        borderSide: BorderSide(color: _C.yellow, width: 2),
      ),
    );
  }

  Widget _driverMgmtSectionCard({
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _C.border),
        boxShadow: [BoxShadow(color: _C.charcoal.withOpacity(0.07), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _C.yellowSoft,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _C.yellowDeep),
                  ),
                  child: Icon(icon, color: _C.charcoal, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: _C.textStrong,
                      height: 1.25,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _driverPinAccountTile(AppLocalizations l, Map<String, dynamic> d) {
    final title =
        '${d['driver_name'] ?? ''} (${d['phone'] ?? ''})'.trim();
    final subtitle = () {
      var line = _uiText(
        en: 'Driver profile',
        ar: 'ملف السائق',
        fr: 'Profil chauffeur',
        es: 'Perfil del conductor',
        de: 'Fahrerprofil',
        it: 'Profilo autista',
        ru: 'Профиль водителя',
        zh: '司机资料',
      );
      final model = (d['car_model'] ?? '').toString().trim();
      final color = (d['car_color'] ?? '').toString().trim();
      if (model.isNotEmpty) line += l.operatorDriverCarLine(model);
      if (color.isNotEmpty) line += l.operatorDriverCarColorAppend(color);
      return line;
    }();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.border),
        boxShadow: [BoxShadow(color: _C.charcoal.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: _busy ? null : () => _editDriverAccount(d),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(color: _C.surfaceAlt, borderRadius: BorderRadius.circular(12), border: Border.all(color: _C.border)),
                child: const Icon(Icons.local_taxi_outlined, color: _C.charcoal, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title.isEmpty ? '—' : title,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: _C.textStrong),
                ),
              ),
              IconButton(
                onPressed: _busy ? null : () => _editDriverAccount(d),
                icon: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(color: _C.charcoal, borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.edit_outlined, color: Colors.white, size: 15),
                ),
                padding: EdgeInsets.zero,
              ),
            ]),
            if (subtitle.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(color: _C.surfaceAlt, borderRadius: BorderRadius.circular(10)),
                child: Text(subtitle, style: const TextStyle(color: _C.textMid, fontSize: 11, height: 1.4)),
              ),
            ],
          ]),
        ),
      ),
    );
  }

  Future<void> _createB2bTenant() async {
    final t = _token;
    if (t == null) return;
    final codeCtrl = TextEditingController();
    final labelCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final pinCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final hotelCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _C.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: _C.border)),
        title: const Text('Create B2B account'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: codeCtrl, decoration: _fd('Code')),
              TextField(controller: labelCtrl, decoration: _fd('Label')),
              TextField(controller: nameCtrl, decoration: _fd('Name')),
              TextField(controller: pinCtrl, decoration: _fd('PIN')),
              TextField(controller: phoneCtrl, decoration: _fd('Phone')),
              TextField(controller: hotelCtrl, decoration: _fd('Hotel')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: _C.yellow,
              foregroundColor: _C.charcoal,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    if (ok == true) {
      setState(() {
        _busy = true;
        _message = null;
      });
      try {
        await _api.createAdminB2bTenant(
          token: t,
          code: codeCtrl.text.trim(),
          label: labelCtrl.text.trim(),
          contactName: nameCtrl.text.trim(),
          pin: pinCtrl.text.trim(),
          phone: phoneCtrl.text.trim(),
          hotel: hotelCtrl.text.trim(),
        );
        await _refreshAll();
      } catch (e) {
        setState(() => _message = e.toString());
      } finally {
        if (mounted) setState(() => _busy = false);
      }
    }
    codeCtrl.dispose();
    labelCtrl.dispose();
    nameCtrl.dispose();
    pinCtrl.dispose();
    phoneCtrl.dispose();
    hotelCtrl.dispose();
  }

  Future<void> _editB2bTenant(Map<String, dynamic> row) async {
    final t = _token;
    if (t == null) return;
    final id = (row['id'] as num?)?.toInt();
    if (id == null) return;
    final codeCtrl = TextEditingController(text: (row['code'] ?? '').toString());
    final labelCtrl = TextEditingController(text: (row['label'] ?? '').toString());
    final nameCtrl = TextEditingController(text: (row['contact_name'] ?? '').toString());
    final pinCtrl = TextEditingController(text: (row['pin'] ?? '').toString());
    final phoneCtrl = TextEditingController(text: (row['phone'] ?? '').toString());
    final hotelCtrl = TextEditingController(text: (row['hotel'] ?? '').toString());
    bool enabled = row['is_enabled'] == true;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          backgroundColor: _C.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: _C.border)),
          title: const Text('Edit B2B account'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: codeCtrl, decoration: _fd('Code')),
                TextField(controller: labelCtrl, decoration: _fd('Label')),
                TextField(controller: nameCtrl, decoration: _fd('Name')),
                TextField(controller: pinCtrl, decoration: _fd('PIN')),
                TextField(controller: phoneCtrl, decoration: _fd('Phone')),
                TextField(controller: hotelCtrl, decoration: _fd('Hotel')),
                SwitchListTile(
                  dense: true,
                  title: const Text('Enabled'),
                  value: enabled,
                  onChanged: (v) => setSt(() => enabled = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: _C.yellow,
                foregroundColor: _C.charcoal,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    if (ok == true) {
      setState(() {
        _busy = true;
        _message = null;
      });
      try {
        await _api.patchAdminB2bTenant(
          token: t,
          tenantId: id,
          payload: {
            'code': codeCtrl.text.trim(),
            'label': labelCtrl.text.trim(),
            'contact_name': nameCtrl.text.trim(),
            'pin': pinCtrl.text.trim(),
            'phone': phoneCtrl.text.trim(),
            'hotel': hotelCtrl.text.trim(),
            'is_enabled': enabled,
          },
        );
        await _refreshAll();
      } catch (e) {
        setState(() => _message = e.toString());
      } finally {
        if (mounted) setState(() => _busy = false);
      }
    }
    codeCtrl.dispose();
    labelCtrl.dispose();
    nameCtrl.dispose();
    pinCtrl.dispose();
    phoneCtrl.dispose();
    hotelCtrl.dispose();
  }

  Future<void> _setB2bEnabled(Map<String, dynamic> tenant, bool enabled) async {
    final t = _token;
    final id = (tenant['id'] as num?)?.toInt();
    if (t == null || id == null) return;
    try {
      await _api.patchAdminB2bTenant(
        token: t,
        tenantId: id,
        payload: {'is_enabled': enabled},
      );
      await _refreshAll();
    } catch (e) {
      if (!mounted) return;
      setState(() => _message = e.toString());
    }
  }

  String _arrivalAirportLabel(Map<String, dynamic> row) {
    final code = Localizations.localeOf(context).languageCode;
    if (code == 'ar') {
      return row['arrival_airport_ar']?.toString() ??
          row['arrival_airport_en']?.toString() ??
          '';
    }
    return row['arrival_airport_en']?.toString() ??
        row['arrival_airport_ar']?.toString() ??
        '';
  }

  String _uiText({
    required String en,
    required String ar,
    required String fr,
    required String es,
    required String de,
    required String it,
    required String ru,
    required String zh,
  }) {
    final code = Localizations.localeOf(context).languageCode.toLowerCase();
    if (code.startsWith('ar')) return ar;
    if (code.startsWith('fr')) return fr;
    if (code.startsWith('es')) return es;
    if (code.startsWith('de')) return de;
    if (code.startsWith('it')) return it;
    if (code.startsWith('ru')) return ru;
    if (code.startsWith('zh')) return zh;
    return en;
  }

  Widget _buildArrivalsTab(AppLocalizations l) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: _C.charcoal,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
          ),
          onPressed: _busy ? null : _refreshAll,
          child: Text(l.adminLoadRidesBtn),
        ),
        const SizedBox(height: 16),
        _SectionHead(l.operatorTabTodaysArrivals),
        if (_flightArrivals.isEmpty)
          _Module(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(children: [
                  const Icon(Icons.flight_land_rounded, size: 40, color: _C.textSoft),
                  const SizedBox(height: 8),
                  Text(l.operatorNoFlightArrivals, style: const TextStyle(color: _C.textSoft)),
                ]),
              ),
            ),
          )
        else
          _Module(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(_C.charcoal),
                headingTextStyle: const TextStyle(color: _C.yellow, fontWeight: FontWeight.w700, fontSize: 12, letterSpacing: 0.5),
                border: TableBorder(horizontalInside: BorderSide(color: _C.border)),
                columns: [
                  DataColumn(label: Text(l.operatorColFlightNumber)),
                  DataColumn(label: Text(l.operatorColDepartureAirport)),
                  DataColumn(label: Text(l.operatorColTakeoffTime)),
                  DataColumn(label: Text(l.operatorColExpectedArrival)),
                  DataColumn(label: Text(l.operatorColArrivalAirportTn)),
                ],
                rows: _flightArrivals.map((r) {
                  return DataRow(
                    cells: [
                      DataCell(Text(r['flight_number']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
                      DataCell(Text(r['departure_airport']?.toString() ?? '', style: const TextStyle(fontSize: 13))),
                      DataCell(Text(r['takeoff_time']?.toString() ?? '', style: const TextStyle(fontSize: 13))),
                      DataCell(Text(r['expected_arrival']?.toString() ?? '', style: const TextStyle(fontSize: 13))),
                      DataCell(Text(_arrivalAirportLabel(r), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildLiveOrdersTab(AppLocalizations l) {
    return RefreshIndicator(
      color: _C.yellow,
      onRefresh: _refreshAll,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        children: [
          _Module(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionHead('Dispatch & monitoring', subtitle: 'Live operational overview'),
                  Text(
                    _adminRides.any((r) => (r['status'] ?? '').toString() == 'pending')
                        ? 'There are pending requests that need assigning.'
                        : 'No pending requests right now.',
                    style: const TextStyle(color: _C.textSoft),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _StatChip(label: 'Pending', value: '${_countByStatus('pending')}', icon: Icons.hourglass_top, color: _C.yellowDeep),
                      _StatChip(label: 'Accepted', value: '${_countByStatus('accepted')}', icon: Icons.local_taxi, color: _C.charcoal),
                      _StatChip(label: 'Ongoing', value: '${_countByStatus('ongoing')}', icon: Icons.route, color: _C.info),
                      _StatChip(label: 'Completed', value: '${_countByStatus('completed')}', icon: Icons.check_circle, color: _C.success),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _Module(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _SectionHead('App rides', subtitle: '${_adminRides.length} rides'),
              if (_adminRides.isEmpty)
                Padding(padding: const EdgeInsets.only(top: 4), child: Text(l.adminNoRidesLoaded, style: const TextStyle(color: _C.textSoft)))
              else
                ..._adminRides.take(30).map((r) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(color: _C.surfaceAlt, borderRadius: BorderRadius.circular(12), border: Border.all(color: _C.border)),
                  child: Row(children: [
                    Container(width: 34, height: 34, decoration: BoxDecoration(color: _C.surfaceAlt, borderRadius: BorderRadius.circular(9), border: Border.all(color: _C.border)), child: const Center(child: Icon(Icons.local_taxi_outlined, color: _C.charcoal, size: 16))),
                    const SizedBox(width: 10),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(localizedRideRouteRow(l, r['pickup']?.toString() ?? '', r['destination']?.toString() ?? ''), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                      const SizedBox(height: 2),
                      Text(l.operatorRideSubtitleLine('${l.statusLinePrefix}${localizedRideStatusLabel(l, r['status']?.toString())}', ((r['driver_name'] ?? r['driver_id'] ?? '').toString().trim().isEmpty) ? '' : '${l.driverLabelPrefix}${(r['driver_name'] ?? r['driver_id']).toString()}', (r['created_at'] ?? '').toString().trim().isEmpty ? '' : '${l.createdAtLinePrefix}${r['created_at']}'), style: const TextStyle(color: _C.textSoft, fontSize: 11)),
                    ])),
                    Text(
                      (r['is_b2b'] == true)
                          ? '${l.roleB2b}: ${(r['b2b_guest_name'] ?? r['passenger_name'] ?? r['user_id'] ?? '-').toString()}'
                          : '${l.rolePassenger}: ${(r['passenger_name'] ?? r['user_id'] ?? '-').toString()}',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                    ),
                  ]),
                )),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildB2bTab(AppLocalizations l) {
    final enabled = _adminB2b.where((b) => b['is_enabled'] == true).toList();
    final paused = _adminB2b.where((b) => b['is_enabled'] != true).toList();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SectionHead(l.operatorCorporateBookingsSection, subtitle: '${_adminB2bBookings.length} bookings'),
        Row(
          children: [
            Expanded(
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: _C.charcoal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                ),
                onPressed: _busy ? null : _refreshAll,
                child: Text(l.operatorRefreshCorporateBookings),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: _C.yellow,
                  foregroundColor: _C.charcoal,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                ),
                onPressed: _busy ? null : _createB2bTenant,
                icon: const Icon(Icons.add_business_outlined),
                label: const Text('Create B2B account', style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _Module(
          child: _adminB2bBookings.isEmpty
              ? Text(l.noTripsLoaded, style: const TextStyle(color: _C.textSoft))
              : Column(
                  children: _adminB2bBookings
                      .map(
                        (b) => _rowInfoCard(
                          icon: Icons.hotel_rounded,
                          iconBg: _C.charcoal,
                          iconColor: _C.yellow,
                          content: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                b['route']?.toString() ?? '',
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                l.adminB2bBookingRowSubtitle(
                                  b['guest_name']?.toString() ?? '',
                                  b['room_number']?.toString() ?? '-',
                                  b['fare']?.toString() ?? '',
                                ),
                                style: const TextStyle(color: _C.textSoft, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
        ),
        _SectionHead(_uiText(
          en: 'Hostel Accounts (B2B)',
          ar: 'حسابات الفنادق (B2B)',
          fr: 'Comptes hôtels (B2B)',
          es: 'Cuentas de hotel (B2B)',
          de: 'Hotelkonten (B2B)',
          it: 'Account hotel (B2B)',
          ru: 'Аккаунты отелей (B2B)',
          zh: '酒店账户 (B2B)',
        ), subtitle: '${_adminB2b.length} accounts'),
        if (_adminB2b.isEmpty)
          const Text('No B2B accounts yet', style: TextStyle(color: _C.textSoft))
        else ...[
          if (enabled.isNotEmpty) ...[
            _SectionHead('Active Hotels', subtitle: '${enabled.length} accounts'),
            ...enabled.map((b) {
              final label = b['label']?.toString() ?? b['code']?.toString() ?? '';
              final code = b['code']?.toString() ?? '';
              final contact = (b['contact_name'] ?? '').toString();
              final pin = (b['pin'] ?? '').toString();
              final phone = (b['phone'] ?? '').toString();
              final hotel = (b['hotel'] ?? '').toString();
              return _Module(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(color: _C.charcoal, borderRadius: BorderRadius.circular(9)),
                          child: const Icon(Icons.hotel_rounded, color: _C.yellow, size: 16),
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14))),
                        _b2bStatusPill(enabled: true),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('Code: $code', style: const TextStyle(color: _C.textSoft, fontSize: 11)),
                    Text('Name: $contact | PIN: $pin', style: const TextStyle(color: _C.textSoft, fontSize: 11)),
                    Text('Phone: $phone | Hotel: $hotel', style: const TextStyle(color: _C.textSoft, fontSize: 11)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: _C.charcoal,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                            ),
                            onPressed: _busy ? null : () => _editB2bTenant(b),
                            icon: const Icon(Icons.edit_outlined),
                            label: const Text('Edit'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: _C.dangerBg,
                              foregroundColor: _C.danger,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                            ),
                            onPressed: _busy ? null : () => _setB2bEnabled(b, false),
                            child: const Text('Pause'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ],
          if (paused.isNotEmpty) ...[
            const SizedBox(height: 4),
            _SectionHead('Paused Hotels', subtitle: '${paused.length} accounts'),
            ...paused.map((b) {
              final label = b['label']?.toString() ?? b['code']?.toString() ?? '';
              final code = b['code']?.toString() ?? '';
              final contact = (b['contact_name'] ?? '').toString();
              final pin = (b['pin'] ?? '').toString();
              final phone = (b['phone'] ?? '').toString();
              final hotel = (b['hotel'] ?? '').toString();
              return _Module(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(color: _C.surfaceAlt, borderRadius: BorderRadius.circular(9), border: Border.all(color: _C.border)),
                          child: const Icon(Icons.hotel_rounded, color: _C.charcoal, size: 16),
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14))),
                        _b2bStatusPill(enabled: false),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('Code: $code', style: const TextStyle(color: _C.textSoft, fontSize: 11)),
                    Text('Name: $contact | PIN: $pin', style: const TextStyle(color: _C.textSoft, fontSize: 11)),
                    Text('Phone: $phone | Hotel: $hotel', style: const TextStyle(color: _C.textSoft, fontSize: 11)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: _C.charcoal,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                            ),
                            onPressed: _busy ? null : () => _editB2bTenant(b),
                            icon: const Icon(Icons.edit_outlined),
                            label: const Text('Edit'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFFD4EDDA),
                              foregroundColor: _C.charcoal,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                            ),
                            onPressed: _busy ? null : () => _setB2bEnabled(b, true),
                            child: const Text('Activate'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ],
    );
  }

  Widget _buildDriverManagementTab(AppLocalizations l) {
    return RefreshIndicator(
      color: _C.yellow,
      onRefresh: () async {
        await _refreshAll();
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        children: [
          _Module(
            accent: true,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _SectionHead(
                _uiText(
                  en: 'Driver management',
                  ar: 'إدارة السائقين',
                  fr: 'Gestion des chauffeurs',
                  es: 'Gestion de conductores',
                  de: 'Fahrerverwaltung',
                  it: 'Gestione autisti',
                  ru: 'Управление водителями',
                  zh: '司机管理',
                ),
                subtitle: 'Profiles overview',
                trailing: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: _C.charcoal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                  ),
                  onPressed: _busy ? null : _refreshAll,
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('Refresh'),
                ),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _StatChip(label: 'Profiles', value: '${_driverPinAccounts.length}', icon: Icons.badge_outlined, color: _C.info),
                  _StatChip(label: 'Ratings', value: '${_driverRatings.length}', icon: Icons.star_outline_rounded, color: _C.yellowDeep),
                ],
              ),
            ]),
          ),
          const SizedBox(height: 4),
          _Module(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(color: _C.yellowSoft, borderRadius: BorderRadius.circular(10), border: Border.all(color: _C.yellowDeep)),
                  child: const Icon(Icons.person_add_alt_1_outlined, color: _C.charcoal, size: 18),
                ),
                title: Text(
                  _uiText(
                    en: 'Create driver account',
                    ar: 'إنشاء حساب سائق',
                    fr: 'Creer un compte chauffeur',
                    es: 'Crear cuenta de conductor',
                    de: 'Fahrerkonto erstellen',
                    it: 'Crea account autista',
                    ru: 'Создать аккаунт водителя',
                    zh: '创建司机账户',
                  ),
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                childrenPadding: const EdgeInsets.only(top: 8),
                children: [
                  TextField(
                    controller: _newDriverPhone,
                    keyboardType: TextInputType.phone,
                    decoration: _fd(
                      _uiText(
                        en: 'Phone',
                        ar: 'الهاتف',
                        fr: 'Telephone',
                        es: 'Telefono',
                        de: 'Telefon',
                        it: 'Telefono',
                        ru: 'Телефон',
                        zh: '电话',
                      ),
                      suffixIcon: const Icon(Icons.phone_outlined, size: 18),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _newDriverName,
                    textCapitalization: TextCapitalization.words,
                    decoration: _fd(
                      _uiText(
                        en: 'Driver name',
                        ar: 'اسم السائق',
                        fr: 'Nom du chauffeur',
                        es: 'Nombre del conductor',
                        de: 'Fahrername',
                        it: 'Nome autista',
                        ru: 'Имя водителя',
                        zh: '司机姓名',
                      ),
                      suffixIcon: const Icon(Icons.badge_outlined, size: 18),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _newDriverPin,
                    obscureText: true,
                    decoration: _fd(
                      _uiText(
                        en: 'PIN',
                        ar: 'رمز PIN',
                        fr: 'PIN',
                        es: 'PIN',
                        de: 'PIN',
                        it: 'PIN',
                        ru: 'PIN',
                        zh: 'PIN',
                      ),
                      suffixIcon: const Icon(Icons.pin_outlined, size: 18),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _newDriverCarModel,
                    decoration: _fd(
                      _uiText(
                        en: 'Car model',
                        ar: 'طراز السيارة',
                        fr: 'Modele de voiture',
                        es: 'Modelo del auto',
                        de: 'Automodell',
                        it: 'Modello auto',
                        ru: 'Модель авто',
                        zh: '车辆型号',
                      ),
                      suffixIcon: const Icon(Icons.directions_car_outlined, size: 18),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _newDriverCarColor,
                    decoration: _fd(
                      _uiText(
                        en: 'Car color',
                        ar: 'لون السيارة',
                        fr: 'Couleur de la voiture',
                        es: 'Color del auto',
                        de: 'Autofarbe',
                        it: 'Colore auto',
                        ru: 'Цвет авто',
                        zh: '车辆颜色',
                      ),
                      suffixIcon: const Icon(Icons.palette_outlined, size: 18),
                    ),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: _busy ? null : _pickNewDriverImage,
                    icon: const Icon(Icons.photo_library_outlined, size: 16),
                    label: Text(
                      _uiText(
                        en: 'Pick image from gallery',
                        ar: 'اختيار صورة من المعرض',
                        fr: 'Choisir une image depuis la galerie',
                        es: 'Elegir imagen de la galeria',
                        de: 'Bild aus Galerie waehlen',
                        it: 'Scegli immagine dalla galleria',
                        ru: 'Выбрать фото из галереи',
                        zh: '从图库选择图片',
                      ),
                    ),
                    style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)), side: const BorderSide(color: _C.border)),
                  ),
                  if (_newDriverPhotoData.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Builder(
                      builder: (_) {
                        final provider = _imageProviderFromString(_newDriverPhotoData);
                        if (provider == null) return const SizedBox.shrink();
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image(
                            image: provider,
                            height: 90,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                          ),
                        );
                      },
                    ),
                  ],
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: _C.yellow,
                        foregroundColor: _C.charcoal,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: _busy ? null : _createDriverAccount,
                      icon: const Icon(Icons.add_rounded),
                      label: Text(
                        _uiText(
                          en: 'Create driver account',
                          ar: 'إنشاء حساب سائق',
                          fr: 'Creer un compte chauffeur',
                          es: 'Crear cuenta de conductor',
                          de: 'Fahrerkonto erstellen',
                          it: 'Crea account autista',
                          ru: 'Создать аккаунт водителя',
                          zh: '创建司机账户',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ]),
          ),
          const SizedBox(height: 4),
          _Module(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _SectionHead('${l.roleDriver} (${_driverPinAccounts.length})', subtitle: 'Driver profiles (edit only)'),
              if (_driverPinAccounts.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.local_taxi_outlined,
                          size: 44,
                          color: _C.textSoft.withValues(alpha: 0.65),
                        ),
                        const SizedBox(height: 10),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            l.operatorFillDriverFields,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: _C.textSoft,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ..._driverPinAccounts.map((d) => _driverPinAccountTile(l, d)),
            ]),
          ),
          const SizedBox(height: 4),
          _Module(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _SectionHead(
                _uiText(
                  en: 'Driver ratings',
                  ar: 'تقييمات السائقين',
                  fr: 'Notes des chauffeurs',
                  es: 'Calificaciones de conductores',
                  de: 'Fahrerbewertungen',
                  it: 'Valutazioni autisti',
                  ru: 'Рейтинг водителей',
                  zh: '司机评分',
                ),
                subtitle: '${_driverRatings.length} profiles',
              ),
              if (_driverRatings.isEmpty)
                Text(
                  _uiText(
                    en: 'No ratings yet',
                    ar: 'لا توجد تقييمات بعد',
                    fr: 'Pas encore de notes',
                    es: 'Aun no hay calificaciones',
                    de: 'Noch keine Bewertungen',
                    it: 'Nessuna valutazione ancora',
                    ru: 'Пока нет оценок',
                    zh: '暂无评分',
                  ),
                )
              else
                ..._driverRatings.map((row) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(color: _C.surfaceAlt, borderRadius: BorderRadius.circular(12), border: Border.all(color: _C.border)),
                  child: Row(children: [
                    Container(width: 34, height: 34, decoration: BoxDecoration(color: _C.yellowSoft, borderRadius: BorderRadius.circular(9), border: Border.all(color: _C.yellowDeep)), child: const Center(child: Icon(Icons.star_rounded, color: _C.charcoal, size: 18))),
                    const SizedBox(width: 10),
                    Expanded(child: Text((row['driver_name'] ?? '').toString(), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Text('${row['rating_average']}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: _C.charcoal)),
                      Text('${row['rating_count']} ${_uiText(en: 'ratings', ar: 'تقييمات', fr: 'notes', es: 'califs.', de: 'Bewert.', it: 'valut.', ru: 'оценок', zh: '评分')}', style: const TextStyle(color: _C.textSoft, fontSize: 10)),
                    ]),
                  ]),
                )),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildTripHistoryTab(AppLocalizations l) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SectionHead(l.operatorTripVaultHeading, subtitle: '${_trips.length} trips'),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _kpiChip(icon: Icons.list_alt, label: l.operatorTripVaultTripsChip(_trips.length)),
            _kpiChip(icon: Icons.payments, label: l.operatorTripVaultRevenueChip(_tripVaultRevenue.toStringAsFixed(3))),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: _C.charcoal,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
            ),
            onPressed: _busy ? null : _refreshAll,
            child: Text(l.loginLoadTrips),
          ),
        ),
        const SizedBox(height: 8),
        _Module(
          child: _trips.isEmpty
              ? Text(l.noTripsLoaded, style: const TextStyle(color: _C.textSoft))
              : Column(
                  children: _trips
                      .map(
                        (t) => _rowInfoCard(
                          icon: Icons.receipt_long_rounded,
                          iconBg: _C.charcoal,
                          iconColor: _C.yellow,
                          content: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${t['route']}',
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                l.operatorTripSubtitle(
                                  t['date'] as String,
                                  t['fare'].toString(),
                                ),
                                style: const TextStyle(color: _C.textSoft, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final tc = _tabController;
    final isPhone = MediaQuery.of(context).size.width < 700;
    return Scaffold(
      backgroundColor: _C.bgWarm,
      appBar: AppBar(
        centerTitle: true,
        title: _appBarHomeLogo(),
        backgroundColor: _C.charcoal,
        foregroundColor: Colors.white,
        actions: const [
          LocalePopupMenuButton(uiRole: AppUiRole.operator),
        ],
      ),
      body: _token == null
          ? ListView(
              padding: EdgeInsets.all(isPhone ? 12 : 16),
              children: [
                _Module(
                  accent: true,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _uiText(
                            en: 'Employee password:',
                            ar: 'كلمة مرور الموظف:',
                            fr: 'Mot de passe employe :',
                            es: 'Contrasena del empleado:',
                            de: 'Mitarbeiterpasswort:',
                            it: 'Password dipendente:',
                            ru: 'Пароль сотрудника:',
                            zh: '员工密码：',
                          ),
                          style: _operatorHeadingTextStyle(),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _secretController,
                          obscureText: _obscureOperatorPassword,
                          decoration: _fd(
                            _uiText(
                              en: 'Operator code',
                              ar: 'رمز الموظف',
                              fr: 'Code operateur',
                              es: 'Codigo de operador',
                              de: 'Operator-Code',
                              it: 'Codice operatore',
                              ru: 'Код оператора',
                              zh: '调度员代码',
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureOperatorPassword
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                              onPressed: () => setState(() {
                                _obscureOperatorPassword = !_obscureOperatorPassword;
                              }),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: _C.yellow,
                              foregroundColor: _C.charcoal,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                            ),
                            onPressed: _busy ? null : _login,
                            child: Text(
                              _uiText(
                                en: 'Login & load trips',
                                ar: 'دخول وتحميل الرحلات',
                                fr: 'Connexion et chargement des courses',
                                es: 'Entrar y cargar viajes',
                                de: 'Anmelden & Fahrten laden',
                                it: 'Accedi e carica corse',
                                ru: 'Войти и загрузить поездки',
                                zh: '登录并加载行程',
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_message != null) ...[
                  const SizedBox(height: 12),
                  Text(_message!, style: const TextStyle(color: Colors.redAccent)),
                ],
              ],
            )
          : tc == null
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      margin: EdgeInsets.fromLTRB(isPhone ? 12 : 16, 12, isPhone ? 12 : 16, 0),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFFFFC200), Color(0xFFFFD84D)]),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _C.yellowDeep.withOpacity(0.55), width: 1.2),
                        boxShadow: [
                          BoxShadow(
                            color: _C.yellow.withOpacity(0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, color: _C.charcoal),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _uiText(
                                en: 'Welcome to the operating room.',
                                ar: 'مرحبًا بك في غرفة العمليات.',
                                fr: 'Bienvenue dans la salle des operations.',
                                es: 'Bienvenido a la sala de operaciones.',
                                de: 'Willkommen im Betriebsraum.',
                                it: 'Benvenuto nella sala operativa.',
                                ru: 'Добро пожаловать в диспетчерскую.',
                                zh: '欢迎来到运营控制室。',
                              ),
                              style: const TextStyle(
                                color: _C.charcoal,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: isPhone ? 8 : 12),
                      child: Container(
                        decoration: BoxDecoration(
                          color: _C.charcoal,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: TabBar(
                          controller: tc,
                          isScrollable: true,
                          indicatorColor: _C.yellow,
                          indicatorWeight: 3,
                          labelColor: _C.yellow,
                          unselectedLabelColor: Colors.white38,
                          labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: 0.3),
                          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
                          tabs: [
                            Tab(
                              text: '✈️  ${_uiText(en: "Today's arrivals", ar: "وصولات اليوم", fr: "Arrivees du jour", es: "Llegadas de hoy", de: "Heutige Ankuenfte", it: "Arrivi di oggi", ru: "Прилеты сегодня", zh: "今日到达")}',
                            ),
                            Tab(
                              text: '💸 ${_uiText(en: "Live orders", ar: "طلبات مباشرة", fr: "Commandes en direct", es: "Pedidos en vivo", de: "Live-Auftraege", it: "Ordini live", ru: "Заказы онлайн", zh: "实时订单")}',
                            ),
                            Tab(
                              text: '👤 ${_uiText(en: "Driver management", ar: "إدارة السائقين", fr: "Gestion des chauffeurs", es: "Gestion de conductores", de: "Fahrerverwaltung", it: "Gestione autisti", ru: "Управление водителями", zh: "司机管理")}',
                            ),
                            Tab(
                              text: '🏨 ${_uiText(en: "Hostel Accounts (B2B)", ar: "حسابات الفنادق (B2B)", fr: "Comptes hôtels (B2B)", es: "Cuentas de hotel (B2B)", de: "Hotelkonten (B2B)", it: "Account hotel (B2B)", ru: "Аккаунты отелей (B2B)", zh: "酒店账户 (B2B)")}',
                            ),
                            Tab(
                              text: '🗒️ ${_uiText(en: "Trip history", ar: "سجل الرحلات", fr: "Historique des courses", es: "Historial de viajes", de: "Fahrtenverlauf", it: "Storico viaggi", ru: "История поездок", zh: "行程历史")}',
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: TabBarView(
                        controller: tc,
                        children: [
                          _buildArrivalsTab(l),
                          _buildLiveOrdersTab(l),
                          _buildDriverManagementTab(l),
                          _buildB2bTab(l),
                          _buildTripHistoryTab(l),
                        ],
                      ),
                    ),
                    if (_message != null)
                      Container(
                        margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: _C.dangerBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _C.danger.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline_rounded, color: _C.danger, size: 16),
                            const SizedBox(width: 8),
                            Expanded(child: Text(_message!, style: const TextStyle(color: _C.danger, fontSize: 13))),
                          ],
                        ),
                      ),
                  ],
                ),
    );
  }
}
