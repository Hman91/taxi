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

class OperatorScreen extends StatefulWidget {
  const OperatorScreen({super.key});

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
          title: Text(row['driver_name']?.toString() ?? loc.operatorDriverNameLabel),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: modelCtrl,
                  decoration: InputDecoration(labelText: loc.operatorCarModelLabel),
                ),
                TextField(
                  controller: colorCtrl,
                  decoration: InputDecoration(labelText: loc.operatorCarColorLabel),
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
                  decoration: InputDecoration(
                    labelText: loc.operatorPhotoUrlOptional,
                  ),
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
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      restoreUiRoleLocale(AppUiRole.operator);
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
        color: TaxiAppColors.text,
        fontWeight: FontWeight.w700,
        fontSize: 15,
      );

  InputDecoration _operatorFieldDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(
        color: TaxiAppColors.textStrong,
        fontWeight: FontWeight.w600,
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(14)),
        borderSide: BorderSide(color: Color(0x448B1428)),
      ),
      enabledBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(14)),
        borderSide: BorderSide(color: Color(0x66991B1B)),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(14)),
        borderSide: BorderSide(color: TaxiAppColors.text, width: 1.75),
      ),
    );
  }

  Widget _driverMgmtSectionCard({
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 0,
      color: TaxiAppColors.cardFill,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: TaxiAppColors.cardBorder),
      ),
      clipBehavior: Clip.antiAlias,
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
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0x408B1428)),
                  ),
                  child: Icon(icon, color: TaxiAppColors.text, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: TaxiAppColors.textStrong,
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
    final letter = () {
      final n = (d['driver_name'] ?? '').toString().trim();
      if (n.isNotEmpty) return n[0].toUpperCase();
      final p = (d['phone'] ?? '').toString().trim();
      if (p.isNotEmpty) return p[0];
      return '?';
    }();
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

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0x55991B1B)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: _busy ? null : () => _editDriverAccount(d),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: TaxiAppColors.appBarFill,
                  foregroundColor: TaxiAppColors.textStrong,
                  child: Text(
                    letter,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title.isEmpty ? '—' : title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: TaxiAppColors.textStrong,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12.5,
                          height: 1.35,
                          color: TaxiAppColors.textSoft,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  color: TaxiAppColors.text,
                  onPressed: _busy ? null : () => _editDriverAccount(d),
                ),
              ],
            ),
          ),
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
        title: const Text('Create B2B account'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: codeCtrl, decoration: const InputDecoration(labelText: 'Code')),
              TextField(controller: labelCtrl, decoration: const InputDecoration(labelText: 'Label')),
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
              TextField(controller: pinCtrl, decoration: const InputDecoration(labelText: 'PIN')),
              TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone')),
              TextField(controller: hotelCtrl, decoration: const InputDecoration(labelText: 'Hotel')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Create')),
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
          title: const Text('Edit B2B account'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: codeCtrl, decoration: const InputDecoration(labelText: 'Code')),
                TextField(controller: labelCtrl, decoration: const InputDecoration(labelText: 'Label')),
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
                TextField(controller: pinCtrl, decoration: const InputDecoration(labelText: 'PIN')),
                TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone')),
                TextField(controller: hotelCtrl, decoration: const InputDecoration(labelText: 'Hotel')),
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
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
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
        FilledButton.tonal(
          onPressed: _busy ? null : _refreshAll,
          child: Text(l.adminLoadRidesBtn),
        ),
        const SizedBox(height: 12),
        Text(
          l.operatorArrivalsDemoHeading,
          style: _operatorHeadingTextStyle(),
        ),
        const SizedBox(height: 10),
        if (_flightArrivals.isEmpty)
          Text(l.operatorNoFlightArrivals)
        else
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(Colors.grey.shade200),
              border: TableBorder.all(color: Colors.grey.shade400),
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
                    DataCell(Text(r['flight_number']?.toString() ?? '')),
                    DataCell(Text(r['departure_airport']?.toString() ?? '')),
                    DataCell(Text(r['takeoff_time']?.toString() ?? '')),
                    DataCell(Text(r['expected_arrival']?.toString() ?? '')),
                    DataCell(Text(_arrivalAirportLabel(r))),
                  ],
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildLiveOrdersTab(AppLocalizations l) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          color: TaxiAppColors.cardFill,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: TaxiAppColors.cardBorder),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.operatorDispatchCenterHeading,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: TaxiAppColors.textStrong,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _adminRides.any(
                          (r) => (r['status'] ?? '').toString() == 'pending')
                      ? l.operatorDispatchPendingBlurb
                      : l.operatorDispatchIdleBlurb,
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Chip(
                      avatar: const Icon(Icons.hourglass_top, size: 16),
                      label:
                          Text(l.operatorChipPending(_countByStatus('pending'))),
                    ),
                    Chip(
                      avatar: const Icon(Icons.local_taxi, size: 16),
                      label: Text(
                          l.operatorChipAccepted(_countByStatus('accepted'))),
                    ),
                    Chip(
                      avatar: const Icon(Icons.route, size: 16),
                      label:
                          Text(l.operatorChipOngoing(_countByStatus('ongoing'))),
                    ),
                    Chip(
                      avatar: const Icon(Icons.check_circle, size: 16),
                      label: Text(
                          l.operatorChipCompleted(_countByStatus('completed'))),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.tonal(
          onPressed: _busy ? null : _refreshAll,
          child: Text(l.adminLoadRidesBtn),
        ),
        const SizedBox(height: 8),
        if (_adminRides.isEmpty) Text(l.adminNoRidesLoaded),
        ..._adminRides.map(
          (r) => Card(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              dense: true,
              leading: const Icon(Icons.directions_car),
              title: Text(
                localizedRideRouteRow(
                  l,
                  r['pickup']?.toString() ?? '',
                  r['destination']?.toString() ?? '',
                ),
              ),
              subtitle: Text(
                l.operatorRideSubtitleLine(
                  '${l.statusLinePrefix}${localizedRideStatusLabel(l, r['status']?.toString())}',
                  (r['driver_name'] ?? '').toString().trim().isEmpty
                      ? ''
                      : '${l.driverLabelPrefix}${r['driver_name']}',
                  (r['created_at'] ?? '').toString().trim().isEmpty
                      ? ''
                      : '${l.createdAtLinePrefix}${r['created_at']}',
                ),
              ),
              trailing: Text(
                (r['is_b2b'] == true)
                    ? '${l.roleB2b}: ${(r['b2b_guest_name'] ?? r['passenger_name'] ?? r['user_id'] ?? '-').toString()}'
                    : '${l.rolePassenger}: ${(r['passenger_name'] ?? r['user_id'] ?? '-').toString()}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          l.operatorCorporateBookingsSection,
          style: _operatorHeadingTextStyle(),
        ),
        const SizedBox(height: 8),
        FilledButton.tonal(
          onPressed: _busy ? null : _refreshAll,
          child: Text(l.operatorRefreshCorporateBookings),
        ),
        const SizedBox(height: 8),
        if (_adminB2bBookings.isEmpty) Text(l.noTripsLoaded),
        ..._adminB2bBookings.map(
          (b) => Card(
            color: Colors.white,
            child: ListTile(
              dense: true,
              title: Text(b['route']?.toString() ?? ''),
              subtitle: Text(
                l.adminB2bBookingRowSubtitle(
                  b['guest_name']?.toString() ?? '',
                  b['room_number']?.toString() ?? '-',
                  b['fare']?.toString() ?? '',
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        FilledButton.icon(
          onPressed: _busy ? null : _createB2bTenant,
          icon: const Icon(Icons.add_business_outlined),
          label: const Text('Create B2B account'),
        ),
        const SizedBox(height: 10),
        if (_adminB2b.isNotEmpty)
          ..._adminB2b.map(
            (b) => Card(
              color: Colors.white,
              child: SwitchListTile(
                dense: true,
                secondary: IconButton(
                  onPressed: _busy ? null : () => _editB2bTenant(b),
                  icon: const Icon(Icons.edit_outlined),
                ),
                title: Text(b['label']?.toString() ?? b['code']?.toString() ?? ''),
                subtitle: Text(
                  '${b['code']?.toString() ?? ''}'
                  '\nName: ${(b['contact_name'] ?? '').toString()} | PIN: ${(b['pin'] ?? '').toString()}'
                  '\nPhone: ${(b['phone'] ?? '').toString()} | Hotel: ${(b['hotel'] ?? '').toString()}',
                ),
                value: b['is_enabled'] == true,
                onChanged: _busy
                    ? null
                    : (v) => _api
                        .patchAdminB2bTenant(
                          token: _token!,
                          tenantId: (b['id'] as num).toInt(),
                          payload: {'is_enabled': v},
                        )
                        .then((_) => _refreshAll())
                        .catchError((e) => setState(() => _message = e.toString())),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDriverManagementTab(AppLocalizations l) {
    final pinIds = _driverPinAccounts
        .map((e) => (e['id'] as num?)?.toInt())
        .whereType<int>()
        .toList();

    final topUpStepper = Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x66991B1B)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: _busy
                ? null
                : () {
                    final v = double.tryParse(
                          _topUpAmountController.text
                              .trim()
                              .replaceAll(',', '.'),
                        ) ??
                        0;
                    _topUpAmountController.text =
                        (v > 1 ? v - 1 : 0).toStringAsFixed(2);
                  },
            icon: const Icon(Icons.remove_rounded),
            color: TaxiAppColors.textStrong,
          ),
          Expanded(
            child: TextField(
              controller: _topUpAmountController,
              textAlign: TextAlign.center,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 17,
                color: TaxiAppColors.textStrong,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              ),
            ),
          ),
          IconButton(
            onPressed: _busy
                ? null
                : () {
                    final v = double.tryParse(
                          _topUpAmountController.text
                              .trim()
                              .replaceAll(',', '.'),
                        ) ??
                        0;
                    _topUpAmountController.text =
                        (v + 1).toStringAsFixed(2);
                  },
            icon: const Icon(Icons.add_rounded),
            color: TaxiAppColors.textStrong,
          ),
        ],
      ),
    );

    return RefreshIndicator(
      color: TaxiAppColors.text,
      onRefresh: () async {
        await _refreshAll();
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          Row(
            children: [
              const Icon(Icons.groups_outlined, color: TaxiAppColors.text),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
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
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: TaxiAppColors.textStrong,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _driverMgmtSectionCard(
            icon: Icons.person_add_alt_1_outlined,
            title: _uiText(
              en: 'Create driver account',
              ar: 'إنشاء حساب سائق',
              fr: 'Creer un compte chauffeur',
              es: 'Crear cuenta de conductor',
              de: 'Fahrerkonto erstellen',
              it: 'Crea account autista',
              ru: 'Создать аккаунт водителя',
              zh: '创建司机账户',
            ),
            children: [
              TextField(
                controller: _newDriverPhone,
                keyboardType: TextInputType.phone,
                decoration: _operatorFieldDecoration(
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
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _newDriverName,
                textCapitalization: TextCapitalization.words,
                decoration: _operatorFieldDecoration(
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
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _newDriverPin,
                obscureText: true,
                decoration: _operatorFieldDecoration(
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
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _newDriverCarModel,
                decoration: _operatorFieldDecoration(
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
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _newDriverCarColor,
                decoration: _operatorFieldDecoration(
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
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _busy ? null : _pickNewDriverImage,
                icon: const Icon(Icons.photo_library),
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
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: TaxiAppColors.buttonDark,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
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
          const SizedBox(height: 14),
          const SizedBox(height: 22),
          Text(
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
            style: _operatorHeadingTextStyle(),
          ),
          const SizedBox(height: 8),
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
            ..._driverRatings.map(
              (row) => Card(
                color: Colors.white,
                child: ListTile(
                  dense: true,
                  leading: const Icon(Icons.star, color: Colors.amber),
                  title: Text((row['driver_name'] ?? '').toString()),
                  subtitle: Text(
                    '${_uiText(en: 'Avg', ar: 'المتوسط', fr: 'Moy', es: 'Prom', de: 'Durchschn', it: 'Media', ru: 'Средн', zh: '平均')}: ${row['rating_average']}'
                    ' (${row['rating_count']} ${_uiText(en: 'ratings', ar: 'تقييمات', fr: 'notes', es: 'calificaciones', de: 'Bewertungen', it: 'valutazioni', ru: 'оценок', zh: '评分')})',
                  ),
                ),
              ),
            ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(
                Icons.local_taxi_outlined,
                color: TaxiAppColors.text,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${l.roleDriver} (${_driverPinAccounts.length})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: TaxiAppColors.textStrong,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_driverPinAccounts.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.local_taxi_outlined,
                      size: 44,
                      color: TaxiAppColors.textSoft.withValues(alpha: 0.65),
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        l.operatorFillDriverFields,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: TaxiAppColors.textSoft,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ..._driverPinAccounts.map(
              (d) => _driverPinAccountTile(l, d),
            ),
        ],
      ),
    );
  }

  Widget _buildTripHistoryTab(AppLocalizations l) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            const Icon(Icons.inventory_2_outlined, color: TaxiAppColors.text),
            const SizedBox(width: 8),
            Text(
              l.operatorTripVaultHeading,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: TaxiAppColors.textStrong,
                fontSize: 16,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            Chip(
              avatar: const Icon(Icons.list_alt, size: 16),
              label: Text(l.operatorTripVaultTripsChip(_trips.length)),
            ),
            Chip(
              avatar: const Icon(Icons.payments, size: 16),
              label: Text(
                l.operatorTripVaultRevenueChip(
                  _tripVaultRevenue.toStringAsFixed(3),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        FilledButton.tonal(
          onPressed: _busy ? null : _refreshAll,
          child: Text(l.loginLoadTrips),
        ),
        const SizedBox(height: 8),
        if (_trips.isEmpty) Text(l.noTripsLoaded),
        ..._trips.map(
          (t) => Card(
            color: Colors.white,
            child: ListTile(
              title: Text('${t['route']}'),
              subtitle: Text(
                l.operatorTripSubtitle(
                  t['date'] as String,
                  t['fare'].toString(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final tc = _tabController;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.operatorTitle),
        actions: const [
          LocalePopupMenuButton(uiRole: AppUiRole.operator),
        ],
      ),
      body: _token == null
          ? ListView(
              padding: const EdgeInsets.all(16),
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
                const SizedBox(height: 8),
                TextField(
                  controller: _secretController,
                  obscureText: _obscureOperatorPassword,
                  decoration: InputDecoration(
                    labelText: _uiText(
                      en: 'Operator code',
                      ar: 'رمز الموظف',
                      fr: 'Code operateur',
                      es: 'Codigo de operador',
                      de: 'Operator-Code',
                      it: 'Codice operatore',
                      ru: 'Код оператора',
                      zh: '调度员代码',
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
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
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: TaxiAppColors.buttonDark,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
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
                if (_message != null) ...[
                  const SizedBox(height: 12),
                  Text(_message!, style: const TextStyle(color: Colors.red)),
                ],
              ],
            )
          : tc == null
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD1FAE5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF34D399)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Color(0xFF065F46)),
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
                                color: Color(0xFF065F46),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Container(
                        decoration: BoxDecoration(
                          color: TaxiAppColors.appBarFill,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: TaxiAppColors.cardBorder),
                        ),
                        child: TabBar(
                          controller: tc,
                          isScrollable: true,
                          indicatorColor: TaxiAppColors.text,
                          indicatorWeight: 3,
                          labelColor: TaxiAppColors.text,
                          unselectedLabelColor: TaxiAppColors.textStrong,
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
                          _buildTripHistoryTab(l),
                        ],
                      ),
                    ),
                    if (_message != null)
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(
                          _message!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                  ],
                ),
    );
  }
}
