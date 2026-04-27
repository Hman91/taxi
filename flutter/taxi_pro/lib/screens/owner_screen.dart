import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';

import '../app_locale.dart' show AppUiRole, restoreUiRoleLocale;
import '../l10n/app_localizations.dart';
import '../l10n/place_localization.dart';
import '../l10n/ride_status_localization.dart';
import '../services/taxi_app_service.dart';
import '../theme/taxi_app_theme.dart';
import '../widgets/locale_popup_menu.dart';

/// Owner HQ — tabs: arrivals (demo), treasury, route & commission settings, B2B.
class OwnerScreen extends StatefulWidget {
  const OwnerScreen({super.key});

  @override
  State<OwnerScreen> createState() => _OwnerScreenState();
}

class _OwnerScreenState extends State<OwnerScreen>
    with SingleTickerProviderStateMixin {
  final _api = TaxiAppService();
  final _imagePicker = ImagePicker();
  final _secretController = TextEditingController(text: 'NabeulGold2026');
  final _newDriverPhone = TextEditingController();
  final _newDriverName = TextEditingController();
  final _newDriverPin = TextEditingController();
  final _newDriverCarModel = TextEditingController();
  final _newDriverCarColor = TextEditingController();
  String _newDriverPhotoData = '';
  final _topUpAmountController = TextEditingController(text: '10');
  int? _topUpAccountId;
  TabController? _tabController;

  bool _obscurePassword = true;
  String? _token;
  String? _message;
  bool _busy = false;

  Map<String, dynamic>? _metrics;
  Map<String, dynamic>? _adminMetrics;
  List<Map<String, dynamic>> _trips = [];
  List<Map<String, dynamic>> _adminRides = [];
  List<Map<String, dynamic>> _adminB2b = [];
  List<Map<String, dynamic>> _adminB2bBookings = [];
  List<Map<String, dynamic>> _flightArrivals = [];
  List<Map<String, dynamic>> _fareRoutes = [];
  List<Map<String, dynamic>> _driverWalletBreakdown = [];
  List<Map<String, dynamic>> _driverRatings = [];
  final Map<int, TextEditingController> _fareCtrls = {};
  double _commissionDemoPercent = 10.0;

  TextStyle _headingStyle() => const TextStyle(
        color: TaxiAppColors.text,
        fontWeight: FontWeight.w700,
        fontSize: 15,
      );

  void _syncFareControllers(List<Map<String, dynamic>> routes) {
    final ids = <int>{};
    for (final r in routes) {
      final idRaw = r['id'];
      if (idRaw is! num) continue;
      final id = idRaw.toInt();
      ids.add(id);
      final bf = r['base_fare'];
      final text =
          bf is num ? bf.toStringAsFixed(2) : bf?.toString() ?? '0.00';
      if (_fareCtrls.containsKey(id)) {
        _fareCtrls[id]!.text = text;
      } else {
        _fareCtrls[id] = TextEditingController(text: text);
      }
    }
    for (final k in _fareCtrls.keys.toList()) {
      if (!ids.contains(k)) {
        _fareCtrls.remove(k)?.dispose();
      }
    }
  }

  String _ownerDriverPinSubtitle(AppLocalizations l, Map<String, dynamic> d) {
    final walletS = (d['wallet_balance'] ?? 0).toString();
    final ownerS = (d['owner_commission_rate'] ?? 10).toString();
    final b2bS = (d['b2b_commission_rate'] ?? 5).toString();
    var line = l.operatorDriverWalletLine(walletS, ownerS, b2bS);
    final model = (d['car_model'] ?? '').toString().trim();
    final color = (d['car_color'] ?? '').toString().trim();
    if (model.isNotEmpty) line += l.operatorDriverCarLine(model);
    if (color.isNotEmpty) line += l.operatorDriverCarColorAppend(color);
    return line;
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

  Future<void> _login() async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final r = await _api.login(
          role: 'owner', secret: _secretController.text.trim());
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
    setState(() => _busy = true);
    try {
      final m = await _api.ownerMetrics(t);
      final trips = await _api.listTrips(t);
      final adminRides = await _api.listAdminRides(t);
      final adminB2b = await _api.listAdminB2bTenants(t);
      final adminB2bBookings = await _api.listAdminB2bBookings(t);
      final adminMetrics = await _api.adminOwnerMetrics(t);
      final flights = await _api.listAdminTunisiaFlightArrivals(t);
      final fareRoutes = await _api.listAdminFareRoutes(t);
      final driverWallets = await _api.listAdminDriverWalletBreakdown(t);
      final ratings = await _api.listAdminDriverRatings(t);
      if (!mounted) return;
      setState(() {
        _metrics = m;
        _adminMetrics = adminMetrics;
        _trips = trips
            .map(
              (e) => {
                'id': e.id,
                'date': e.date,
                'route': e.route,
                'fare': e.fare,
                'commission': e.commission,
                'type': e.type,
              },
            )
            .toList();
        _adminRides = adminRides;
        _adminB2b = adminB2b;
        _adminB2bBookings = adminB2bBookings;
        _flightArrivals = flights;
        _fareRoutes = fareRoutes;
        _driverWalletBreakdown = driverWallets;
        _driverRatings = ratings;
        final ids = driverWallets
            .map((e) => (e['id'] as num?)?.toInt())
            .whereType<int>()
            .toList();
        if (_topUpAccountId != null && !ids.contains(_topUpAccountId)) {
          _topUpAccountId = null;
        }
        _topUpAccountId ??= ids.isEmpty ? null : ids.first;
        _syncFareControllers(fareRoutes);
        _message = null;
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
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _saveFareRoute(int routeId) async {
    final t = _token;
    final ctrl = _fareCtrls[routeId];
    if (t == null || ctrl == null) return;
    final v = double.tryParse(ctrl.text.trim().replaceAll(',', '.'));
    if (v == null || v < 0) {
      setState(
        () => _message = _uiText(
          en: 'Invalid fare',
          ar: 'تعرفة غير صالحة',
          fr: 'Tarif invalide',
          es: 'Tarifa invalida',
          de: 'Ungueltiger Fahrpreis',
          it: 'Tariffa non valida',
          ru: 'Неверный тариф',
          zh: '无效费用',
        ),
      );
      return;
    }
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await _api.patchAdminFareRoute(
        token: t,
        routeId: routeId,
        baseFare: v,
      );
      await _refreshAll();
    } catch (e) {
      setState(() => _message = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _toggleB2b(Map<String, dynamic> tenant) async {
    final t = _token;
    if (t == null) return;
    final idRaw = tenant['id'];
    if (idRaw is! num) return;
    final current = (tenant['is_enabled'] == true);
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await _api.setAdminB2bEnabled(
        token: t,
        tenantId: idRaw.toInt(),
        isEnabled: !current,
      );
      await _refreshAll();
    } catch (e) {
      setState(() => _message = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
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
    final walletCtrl = TextEditingController(
      text: (row['wallet_balance'] ?? 0).toString(),
    );
    final ownerRateCtrl = TextEditingController(
      text: (row['owner_commission_rate'] ?? 10).toString(),
    );
    final b2bRateCtrl = TextEditingController(
      text: (row['b2b_commission_rate'] ?? 5).toString(),
    );
    final modelCtrl = TextEditingController(text: row['car_model']?.toString() ?? '');
    final colorCtrl = TextEditingController(text: row['car_color']?.toString() ?? '');
    bool autoDeduct = row['auto_deduct_enabled'] == true;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: Text((row['driver_name'] ?? 'Driver').toString()),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: walletCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(labelText: AppLocalizations.of(ctx)!.operatorWalletBalanceLabel),
                ),
                TextField(
                  controller: ownerRateCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(labelText: AppLocalizations.of(ctx)!.operatorOwnerCommissionLabel),
                ),
                TextField(
                  controller: b2bRateCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(labelText: AppLocalizations.of(ctx)!.operatorB2bCommissionLabel),
                ),
                SwitchListTile(
                  dense: true,
                  title: Text(AppLocalizations.of(ctx)!.operatorAutoDeductEnabled),
                  value: autoDeduct,
                  onChanged: (v) => setSt(() => autoDeduct = v),
                ),
                TextField(
                  controller: modelCtrl,
                  decoration: InputDecoration(labelText: AppLocalizations.of(ctx)!.operatorCarModelLabel),
                ),
                TextField(
                  controller: colorCtrl,
                  decoration: InputDecoration(labelText: AppLocalizations.of(ctx)!.operatorCarColorLabel),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(AppLocalizations.of(ctx)!.operatorCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(AppLocalizations.of(ctx)!.operatorSave),
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
        await _api.patchAdminDriverPinAccount(
          token: t,
          accountId: id,
          payload: {
            'wallet_balance': double.tryParse(walletCtrl.text.trim().replaceAll(',', '.')) ??
                (row['wallet_balance'] as num?)?.toDouble() ??
                0.0,
            'owner_commission_rate':
                double.tryParse(ownerRateCtrl.text.trim().replaceAll(',', '.')) ??
                    (row['owner_commission_rate'] as num?)?.toDouble() ??
                    10.0,
            'b2b_commission_rate':
                double.tryParse(b2bRateCtrl.text.trim().replaceAll(',', '.')) ??
                    (row['b2b_commission_rate'] as num?)?.toDouble() ??
                    5.0,
            'auto_deduct_enabled': autoDeduct,
            'car_model': modelCtrl.text.trim(),
            'car_color': colorCtrl.text.trim(),
          },
        );
        await _refreshAll();
      } catch (e) {
        setState(() => _message = e.toString());
      } finally {
        if (mounted) setState(() => _busy = false);
      }
    }
    walletCtrl.dispose();
    ownerRateCtrl.dispose();
    b2bRateCtrl.dispose();
    modelCtrl.dispose();
    colorCtrl.dispose();
  }

  Future<void> _rechargeDriverWallet() async {
    final t = _token;
    final id = _topUpAccountId;
    if (t == null || id == null) return;
    final amount =
        double.tryParse(_topUpAmountController.text.trim().replaceAll(',', '.')) ?? 0.0;
    if (amount <= 0) {
      setState(
        () => _message = _uiText(
          en: 'Invalid recharge amount',
          ar: 'مبلغ الشحن غير صالح',
          fr: 'Montant de recharge invalide',
          es: 'Importe de recarga invalido',
          de: 'Ungueltiger Aufladebetrag',
          it: 'Importo ricarica non valido',
          ru: 'Неверная сумма пополнения',
          zh: '充值金额无效',
        ),
      );
      return;
    }
    final row = _driverWalletBreakdown.firstWhere(
      (e) => (e['id'] as num?)?.toInt() == id,
      orElse: () => const <String, dynamic>{},
    );
    if (row.isEmpty) return;
    final current = (row['wallet_balance'] as num?)?.toDouble() ?? 0.0;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await _api.patchAdminDriverPinAccount(
        token: t,
        accountId: id,
        payload: {'wallet_balance': current + amount},
      );
      _topUpAmountController.text = '10';
      await _refreshAll();
    } catch (e) {
      setState(() => _message = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
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

  Widget _buildArrivalsTab(AppLocalizations l) {
    return RefreshIndicator(
      color: TaxiAppColors.text,
      onRefresh: _refreshAll,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          FilledButton.tonal(
            onPressed: _busy ? null : _refreshAll,
            child: Text(l.adminLoadRidesBtn),
          ),
          const SizedBox(height: 12),
          Text(
            l.operatorArrivalsDemoHeading,
            style: _headingStyle(),
          ),
          const SizedBox(height: 10),
          if (_flightArrivals.isEmpty)
            Text(l.operatorNoFlightArrivals)
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor:
                    WidgetStateProperty.all(Colors.blueGrey.shade700),
                headingTextStyle: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
                border: TableBorder.all(color: Colors.grey.shade400),
                columns: [
                  DataColumn(label: Text(l.operatorColFlightNumber)),
                  DataColumn(label: Text(l.operatorColDepartureAirport)),
                  DataColumn(label: Text(l.operatorColTakeoffTime)),
                  DataColumn(label: Text(l.operatorColExpectedArrival)),
                  DataColumn(label: Text(l.operatorColArrivalAirportTn)),
                ],
                rows: _flightArrivals.asMap().entries.map((e) {
                  final i = e.key;
                  final r = e.value;
                  return DataRow(
                    color: WidgetStateProperty.all(
                      i.isEven ? Colors.grey.shade50 : Colors.white,
                    ),
                    cells: [
                      DataCell(Text(
                        r['flight_number']?.toString() ?? '',
                        style: const TextStyle(
                            color: TaxiAppColors.textStrong),
                      )),
                      DataCell(Text(
                        r['departure_airport']?.toString() ?? '',
                        style: const TextStyle(
                            color: TaxiAppColors.textStrong),
                      )),
                      DataCell(Text(
                        r['takeoff_time']?.toString() ?? '',
                        style: const TextStyle(
                            color: TaxiAppColors.textStrong),
                      )),
                      DataCell(Text(
                        r['expected_arrival']?.toString() ?? '',
                        style: const TextStyle(
                            color: TaxiAppColors.textStrong),
                      )),
                      DataCell(Text(
                        _arrivalAirportLabel(r),
                        style: const TextStyle(
                            color: TaxiAppColors.textStrong),
                      )),
                    ],
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTreasuryTab(AppLocalizations l) {
    return RefreshIndicator(
      color: TaxiAppColors.text,
      onRefresh: _refreshAll,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          if (_metrics != null)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(
                  avatar: const Icon(Icons.payments, size: 16),
                  label: Text(
                    l.ownerProfitChip(
                      _metrics!['total_commission']?.toString() ?? '0',
                    ),
                  ),
                ),
                Chip(
                  avatar: const Icon(Icons.route, size: 16),
                  label: Text(
                    l.ownerTripsCountChip(
                      _metrics!['trip_count']?.toString() ?? '0',
                    ),
                  ),
                ),
                Chip(
                  avatar: const Icon(Icons.star, size: 16),
                  label: Text(
                    l.ownerRatingChip(
                      _metrics!['rating_average']?.toString() ?? '0',
                      _metrics!['rating_count']?.toString() ?? '0',
                    ),
                  ),
                ),
              ],
            ),
          if (_adminMetrics != null) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(
                  avatar: const Icon(Icons.payments, size: 16),
                  label: Text(
                    l.ownerCommissionChip(
                      _adminMetrics!['total_commission']?.toString() ?? '0',
                    ),
                  ),
                ),
                Chip(
                  avatar: const Icon(Icons.route, size: 16),
                  label: Text(
                    l.ownerTripsCountChip(
                      _adminMetrics!['trip_count']?.toString() ?? '0',
                    ),
                  ),
                ),
                Chip(
                  avatar: const Icon(Icons.star, size: 16),
                  label: Text(
                    l.ownerRatingChip(
                      _adminMetrics!['rating_average']?.toString() ?? '0',
                      _adminMetrics!['rating_count']?.toString() ?? '0',
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          FilledButton.tonal(
            onPressed: _busy ? null : _refreshAll,
            child: Text(l.adminLoadOwnerMetricsBtn),
          ),
          const Divider(height: 28),
          Text(
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
              fontWeight: FontWeight.w800,
              color: TaxiAppColors.textStrong,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  TextField(
                    controller: _newDriverPhone,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: _uiText(
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
                  TextField(
                    controller: _newDriverName,
                    decoration: InputDecoration(labelText: l.operatorDriverNameLabel),
                  ),
                  TextField(
                    controller: _newDriverPin,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: _uiText(
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
                  TextField(
                    controller: _newDriverCarModel,
                    decoration: InputDecoration(labelText: l.operatorCarModelLabel),
                  ),
                  TextField(
                    controller: _newDriverCarColor,
                    decoration: InputDecoration(labelText: l.operatorCarColorLabel),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _busy ? null : _pickNewDriverImage,
                    icon: const Icon(Icons.photo_library),
                    label: Text(l.operatorPickFromGallery),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _busy ? null : _createDriverAccount,
                      child: Text(
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
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: _topUpAccountId,
                          decoration: InputDecoration(labelText: l.operatorDriverNameLabel),
                          items: _driverWalletBreakdown
                              .map((d) => DropdownMenuItem<int>(
                                    value: (d['id'] as num?)?.toInt(),
                                    child: Text(
                                      '${d['driver_name'] ?? ''} (${d['phone'] ?? ''})',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ))
                              .toList(),
                          onChanged: _busy ? null : (v) => setState(() => _topUpAccountId = v),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 120,
                        child: TextField(
                          controller: _topUpAmountController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(labelText: 'DT'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _busy || _topUpAccountId == null ? null : _rechargeDriverWallet,
                      icon: const Icon(Icons.savings_outlined),
                      label: Text(
                        _uiText(
                          en: 'Recharge the balance',
                          ar: 'شحن الرصيد',
                          fr: 'Recharger le solde',
                          es: 'Recargar saldo',
                          de: 'Guthaben aufladen',
                          it: 'Ricarica saldo',
                          ru: 'Пополнить баланс',
                          zh: '充值余额',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.account_balance_wallet_outlined,
                color: TaxiAppColors.text,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l.ownerDriverPinWalletsHeading,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: TaxiAppColors.textStrong,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_driverWalletBreakdown.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                l.ownerDriverPinWalletsEmpty,
                style: const TextStyle(color: TaxiAppColors.textSoft),
              ),
            )
          else
            ..._driverWalletBreakdown.map(
              (d) => Card(
                color: Colors.white,
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: Color(0x55991B1B)),
                ),
                child: ListTile(
                  onTap: _busy ? null : () => _editDriverAccount(d),
                  dense: true,
                  leading: const Icon(
                    Icons.local_taxi_outlined,
                    color: TaxiAppColors.text,
                  ),
                  title: Text(
                    '${d['driver_name'] ?? ''} (${d['phone'] ?? ''})'.trim(),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: TaxiAppColors.textStrong,
                    ),
                  ),
                  subtitle: Text(
                    '${_ownerDriverPinSubtitle(l, d)}'
                    '\n${_uiText(en: 'Simple rides total', ar: 'إجمالي الرحلات العادية', fr: 'Total courses simples', es: 'Total viajes simples', de: 'Summe einfache Fahrten', it: 'Totale corse semplici', ru: 'Итого обычные поездки', zh: '普通行程总额')}: ${(d['gross_normal'] ?? 0).toString()} DT'
                    ' | ${_uiText(en: 'B2B rides total', ar: 'إجمالي رحلات B2B', fr: 'Total courses B2B', es: 'Total viajes B2B', de: 'Summe B2B-Fahrten', it: 'Totale corse B2B', ru: 'Итого B2B поездки', zh: 'B2B行程总额')}: ${(d['gross_b2b'] ?? 0).toString()} DT'
                    '\n${_uiText(en: 'Deducted from simple rides', ar: 'المخصوم من الرحلات العادية', fr: 'Retenu des courses simples', es: 'Descontado de viajes simples', de: 'Abzug aus einfachen Fahrten', it: 'Detratto da corse semplici', ru: 'Удержано с обычных поездок', zh: '普通行程扣除')}: ${(d['deducted_normal'] ?? 0).toString()} DT'
                    ' | ${_uiText(en: 'Deducted from B2B rides', ar: 'المخصوم من رحلات B2B', fr: 'Retenu des courses B2B', es: 'Descontado de viajes B2B', de: 'Abzug aus B2B-Fahrten', it: 'Detratto da corse B2B', ru: 'Удержано с B2B поездок', zh: 'B2B行程扣除')}: ${(d['deducted_b2b'] ?? 0).toString()} DT',
                    style: const TextStyle(
                      fontSize: 12.5,
                      height: 1.35,
                      color: TaxiAppColors.textSoft,
                    ),
                  ),
                  trailing: IconButton(
                    onPressed: _busy ? null : () => _editDriverAccount(d),
                    icon: const Icon(Icons.edit_outlined),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 14),
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
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: TaxiAppColors.textStrong,
              fontSize: 16,
            ),
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
          const Divider(height: 28),
          Text(
            l.ownerVaultHeading,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: TaxiAppColors.textStrong,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          if (_trips.isEmpty) Text(l.noTripsYet),
          ..._trips.map(
            (t) => Card(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: const BorderSide(color: Color(0x55991B1B)),
              ),
              child: ListTile(
                dense: true,
                leading: const Icon(Icons.receipt_long,
                    color: TaxiAppColors.text),
                title: Text(
                  l.ownerTripRouteFareRow(
                    t['route']?.toString() ?? '',
                    t['fare']?.toString() ?? '',
                  ),
                  style: const TextStyle(
                    color: TaxiAppColors.textStrong,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  l.tripListSubtitle(
                    t['date'] as String,
                    t['commission'].toString(),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l.adminRidesHeading,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: TaxiAppColors.textStrong,
            ),
          ),
          const SizedBox(height: 8),
          if (_adminRides.isEmpty) Text(l.adminNoRidesLoaded),
          ..._adminRides.take(30).map(
                (r) => Card(
                  color: Colors.white,
                  child: ListTile(
                    dense: true,
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
                        ((r['driver_name'] ?? r['driver_id'] ?? '').toString().trim().isEmpty)
                            ? ''
                            : '${l.driverLabelPrefix}${(r['driver_name'] ?? r['driver_id']).toString()}',
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
        ],
      ),
    );
  }

  Widget _buildSettingsTab(AppLocalizations l) {
    return RefreshIndicator(
      color: TaxiAppColors.text,
      onRefresh: _refreshAll,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 0,
            color: TaxiAppColors.cardFill,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: const BorderSide(color: TaxiAppColors.cardBorder),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.percent,
                          color: TaxiAppColors.text, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          l.ownerSettingsCommissionLabel,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: TaxiAppColors.textStrong,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l.ownerSettingsCommissionHint,
                    style: const TextStyle(
                      fontSize: 12,
                      color: TaxiAppColors.textSoft,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      _commissionDemoPercent.toStringAsFixed(2),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: TaxiAppColors.text,
                      ),
                    ),
                  ),
                  Slider(
                    value: _commissionDemoPercent.clamp(0.0, 40.0),
                    min: 0,
                    max: 40,
                    divisions: 400,
                    label: _commissionDemoPercent.toStringAsFixed(1),
                    activeColor: TaxiAppColors.text,
                    inactiveColor: TaxiAppColors.textSoft.withValues(alpha: 0.35),
                    onChanged: _busy
                        ? null
                        : (v) =>
                            setState(() => _commissionDemoPercent = v),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l.ownerSettingsRouteFaresHeading,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: TaxiAppColors.textStrong,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 10),
          if (_fareRoutes.isEmpty)
            Text(l.adminNoRidesLoaded)
          else
            ..._fareRoutes.map((r) {
              final id = (r['id'] as num).toInt();
              final label = localizedRideRouteRow(
                l,
                r['start']?.toString() ?? '',
                r['destination']?.toString() ?? '',
              );
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Card(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: const BorderSide(color: Color(0x55991B1B)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          label,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: TaxiAppColors.textStrong,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            IconButton(
                              onPressed: _busy
                                  ? null
                                  : () {
                                      final c = _fareCtrls[id];
                                      if (c == null) return;
                                      final v = double.tryParse(c.text
                                              .replaceAll(',', '.')) ??
                                          0;
                                      c.text = (v > 1 ? v - 1 : 0)
                                          .toStringAsFixed(2);
                                      setState(() {});
                                    },
                              icon: const Icon(Icons.remove_rounded),
                              color: TaxiAppColors.textStrong,
                            ),
                            Expanded(
                              child: TextField(
                                controller: _fareCtrls[id],
                                keyboardType: const TextInputType.numberWithOptions(
                                    decimal: true),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'[\d.,]')),
                                ],
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: const Color(0xFFF3F4F6),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: _busy
                                  ? null
                                  : () {
                                      final c = _fareCtrls[id];
                                      if (c == null) return;
                                      final v = double.tryParse(c.text
                                              .replaceAll(',', '.')) ??
                                          0;
                                      c.text = (v + 1).toStringAsFixed(2);
                                      setState(() {});
                                    },
                              icon: const Icon(Icons.add_rounded),
                              color: TaxiAppColors.textStrong,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: TaxiAppColors.buttonDark,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: _busy ? null : () => _saveFareRoute(id),
                            child: Text(l.ownerSaveRouteFare),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildB2bTab(AppLocalizations l) {
    return RefreshIndicator(
      color: TaxiAppColors.text,
      onRefresh: _refreshAll,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          FilledButton.tonal(
            onPressed: _busy ? null : _refreshAll,
            child: Text(l.operatorRefreshCorporateBookings),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: _busy ? null : _createB2bTenant,
            icon: const Icon(Icons.add_business_outlined),
            label: const Text('Create B2B account'),
          ),
          const SizedBox(height: 16),
          Text(
            l.ownerAdminOversightHeading,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: TaxiAppColors.textStrong,
            ),
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
          const Divider(height: 28),
          Text(
            l.ownerTabHostelB2b,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: TaxiAppColors.textStrong,
            ),
          ),
          const SizedBox(height: 8),
          ..._adminB2b.map(
            (b) => SwitchListTile(
              dense: true,
              title: Text(
                  b['label']?.toString() ?? b['code']?.toString() ?? ''),
              subtitle: Text(
                '${b['code']?.toString() ?? ''}'
                ' • ${_uiText(en: 'Wallet', ar: 'المحفظة', fr: 'Portefeuille', es: 'Billetera', de: 'Wallet', it: 'Portafoglio', ru: 'Кошелек', zh: '钱包')} ${(b['wallet_balance'] ?? 0).toString()} DT'
                '\nName: ${(b['contact_name'] ?? '').toString()} | PIN: ${(b['pin'] ?? '').toString()}'
                '\nPhone: ${(b['phone'] ?? '').toString()} | Hotel: ${(b['hotel'] ?? '').toString()}',
              ),
              value: b['is_enabled'] == true,
              onChanged: _busy ? null : (_) => _toggleB2b(b),
              secondary: IconButton(
                onPressed: _busy ? null : () => _editB2bTenant(b),
                icon: const Icon(Icons.edit_outlined),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      restoreUiRoleLocale(AppUiRole.owner);
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
    for (final c in _fareCtrls.values) {
      c.dispose();
    }
    _fareCtrls.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final tc = _tabController;

    return Scaffold(
      appBar: AppBar(
        title: Text(l.ownerAppBarTitle),
        actions: [
          const LocalePopupMenuButton(uiRole: AppUiRole.owner),
          if (_token != null)
            IconButton(
              onPressed: _busy ? null : _refreshAll,
              icon: const Icon(Icons.refresh),
            ),
        ],
      ),
      body: _token == null
          ? ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  l.ownerPasswordCeoLabel,
                  style: const TextStyle(
                    color: TaxiAppColors.text,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _secretController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: l.ownerPassword,
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () => setState(
                        () => _obscurePassword = !_obscurePassword,
                      ),
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
                    child: Text(l.loginLoadDashboard),
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
                          const Icon(Icons.check_circle,
                              color: Color(0xFF065F46)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              l.ownerWelcomeHq,
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
                            Tab(text: '✈️  ${l.operatorTabTodaysArrivals}'),
                            Tab(text: '💰 ${l.ownerTabTreasury}'),
                            Tab(text: '⚙️ ${l.ownerTabSettings}'),
                            Tab(text: '🏨 ${l.ownerTabHostelB2b}'),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: TabBarView(
                        controller: tc,
                        children: [
                          _buildArrivalsTab(l),
                          _buildTreasuryTab(l),
                          _buildSettingsTab(l),
                          _buildB2bTab(l),
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
