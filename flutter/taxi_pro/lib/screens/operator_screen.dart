import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../app_locale.dart' show AppUiRole, restoreUiRoleLocale;
import '../l10n/app_localizations.dart';
import '../l10n/place_localization.dart';
import '../l10n/ride_status_localization.dart';
import '../services/taxi_app_service.dart';
import '../widgets/locale_popup_menu.dart';

class OperatorScreen extends StatefulWidget {
  const OperatorScreen({super.key});

  @override
  State<OperatorScreen> createState() => _OperatorScreenState();
}

class _OperatorScreenState extends State<OperatorScreen> {
  final _api = TaxiAppService();
  final _imagePicker = ImagePicker();
  final _secretController = TextEditingController(text: 'Operator2026');
  final _newDriverPhone = TextEditingController();
  final _newDriverName = TextEditingController();
  final _newDriverPin = TextEditingController();
  String? _token;
  String? _message;
  List<Map<String, dynamic>> _trips = [];
  List<Map<String, dynamic>> _adminRides = [];
  List<Map<String, dynamic>> _adminDrivers = [];
  List<Map<String, dynamic>> _adminUsers = [];
  List<Map<String, dynamic>> _driverPinAccounts = [];
  List<Map<String, dynamic>> _adminB2bBookings = [];
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
      final drivers = await _api.listAdminDriverLocations(t);
      final users = await _api.listAdminUsers(t);
      final driverPins = await _api.listAdminDriverPinAccounts(t);
      final b2bBookings = await _api.listAdminB2bBookings(t);
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
        _adminDrivers = drivers;
        _adminUsers = users;
        _driverPinAccounts = driverPins;
        _adminB2bBookings = b2bBookings;
      });
    } catch (e) {
      setState(() => _message = e.toString());
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _toggleUser(Map<String, dynamic> user) async {
    final t = _token;
    if (t == null) return;
    final idRaw = user['id'];
    if (idRaw is! num) return;
    final current = (user['is_enabled'] == true);
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await _api.setAdminUserEnabled(
        token: t,
        userId: idRaw.toInt(),
        isEnabled: !current,
      );
      await _refreshAll();
    } catch (e) {
      setState(() => _message = e.toString());
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
    final loc = AppLocalizations.of(context)!;
    if (phone.isEmpty || name.isEmpty || pin.isEmpty) {
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
      );
      _newDriverPhone.clear();
      _newDriverName.clear();
      _newDriverPin.clear();
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
    final modelCtrl =
        TextEditingController(text: row['car_model']?.toString() ?? '');
    final colorCtrl =
        TextEditingController(text: row['car_color']?.toString() ?? '');
    final photoCtrl =
        TextEditingController(text: row['photo_url']?.toString() ?? '');
    bool autoDeduct = row['auto_deduct_enabled'] == true;
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
                  controller: walletCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration:
                      InputDecoration(labelText: loc.operatorWalletBalanceLabel),
                ),
                TextField(
                  controller: ownerRateCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration:
                      InputDecoration(labelText: loc.operatorOwnerCommissionLabel),
                ),
                TextField(
                  controller: b2bRateCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration:
                      InputDecoration(labelText: loc.operatorB2bCommissionLabel),
                ),
                SwitchListTile(
                  dense: true,
                  title: Text(loc.operatorAutoDeductEnabled),
                  value: autoDeduct,
                  onChanged: (v) => setSt(() => autoDeduct = v),
                ),
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
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image(
                      image: _imageProviderFromString(selectedPhotoData),
                      height: 90,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
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
      walletCtrl.dispose();
      ownerRateCtrl.dispose();
      b2bRateCtrl.dispose();
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
          'wallet_balance': double.tryParse(walletCtrl.text.trim()) ?? 0.0,
          'owner_commission_rate':
              double.tryParse(ownerRateCtrl.text.trim()) ?? 10.0,
          'b2b_commission_rate':
              double.tryParse(b2bRateCtrl.text.trim()) ?? 5.0,
          'auto_deduct_enabled': autoDeduct,
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
      walletCtrl.dispose();
      ownerRateCtrl.dispose();
      b2bRateCtrl.dispose();
      modelCtrl.dispose();
      colorCtrl.dispose();
      photoCtrl.dispose();
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      restoreUiRoleLocale(AppUiRole.operator);
    });
  }

  @override
  void dispose() {
    _secretController.dispose();
    _newDriverPhone.dispose();
    _newDriverName.dispose();
    _newDriverPin.dispose();
    super.dispose();
  }

  ImageProvider _imageProviderFromString(String value) {
    final trimmed = value.trim();
    if (trimmed.startsWith('data:image/')) {
      final commaIdx = trimmed.indexOf(',');
      if (commaIdx > 0 && commaIdx + 1 < trimmed.length) {
        final b64 = trimmed.substring(commaIdx + 1);
        return MemoryImage(base64Decode(b64));
      }
    }
    return NetworkImage(trimmed);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
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
                TextField(
                  controller: _secretController,
                  obscureText: true,
                  decoration: InputDecoration(labelText: l.operatorCode),
                ),
                FilledButton(
                  onPressed: _busy ? null : _login,
                  child: Text(l.loginLoadTrips),
                ),
                if (_message != null)
                  Text(_message!, style: const TextStyle(color: Colors.red)),
              ],
            )
          : DefaultTabController(
              length: 4,
              child: Column(
                children: [
                  TabBar(
                    tabs: [
                      Tab(text: l.operatorTabDispatch),
                      Tab(text: l.operatorTabDrivers),
                      Tab(text: l.operatorTabB2b),
                      Tab(text: l.operatorTabTripVault),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        ListView(
                          padding: const EdgeInsets.all(12),
                          children: [
                            Card(
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
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      _adminRides.any((r) =>
                                              (r['status'] ?? '').toString() == 'pending')
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
                                          label: Text(l.operatorChipPending(
                                              _countByStatus('pending'))),
                                        ),
                                        Chip(
                                          avatar: const Icon(Icons.local_taxi, size: 16),
                                          label: Text(l.operatorChipAccepted(
                                              _countByStatus('accepted'))),
                                        ),
                                        Chip(
                                          avatar: const Icon(Icons.route, size: 16),
                                          label: Text(l.operatorChipOngoing(
                                              _countByStatus('ongoing'))),
                                        ),
                                        Chip(
                                          avatar: const Icon(Icons.check_circle, size: 16),
                                          label: Text(l.operatorChipCompleted(
                                              _countByStatus('completed'))),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            FilledButton.tonal(
                              onPressed: _busy ? null : _refreshAll,
                              child: Text(l.adminLoadRidesBtn),
                            ),
                            if (_adminRides.isEmpty) Text(l.adminNoRidesLoaded),
                            ..._adminRides.map(
                              (r) => Card(
                                child: ListTile(
                                  dense: true,
                                  leading: const Icon(Icons.directions_car),
                                  title: Text(localizedRideRouteRow(
                                    l,
                                    r['pickup']?.toString() ?? '',
                                    r['destination']?.toString() ?? '',
                                  )),
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
                                ),
                              ),
                            ),
                          ],
                        ),
                        ListView(
                          padding: const EdgeInsets.all(12),
                          children: [
                            FilledButton.tonal(
                              onPressed: _busy ? null : _refreshAll,
                              child: Text(l.adminLoadDriversBtn),
                            ),
                            const SizedBox(height: 8),
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(10),
                                child: Text(
                                  l.operatorDriversOnlineCount(_adminDrivers.length),
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                            if (_adminDrivers.isEmpty)
                              Text(l.adminNoDriversData),
                            ..._adminDrivers.map(
                              (d) => ListTile(
                                dense: true,
                                title: Text(d['email']?.toString() ?? ''),
                                subtitle: Text(
                                  l.driverLocationRow(
                                    d['last_lat']?.toString() ?? '—',
                                    d['last_lng']?.toString() ?? '—',
                                  ),
                                ),
                              ),
                            ),
                            const Divider(),
                            TextField(
                              controller: _newDriverPhone,
                              decoration:
                                  InputDecoration(labelText: l.operatorPhoneLabel),
                            ),
                            TextField(
                              controller: _newDriverName,
                              decoration: InputDecoration(
                                  labelText: l.operatorDriverNameLabel),
                            ),
                            TextField(
                              controller: _newDriverPin,
                              decoration:
                                  InputDecoration(labelText: l.operatorPinLabel),
                              obscureText: true,
                            ),
                            const SizedBox(height: 8),
                            FilledButton(
                              onPressed: _busy ? null : _createDriverAccount,
                              child: Text(l.operatorCreateDriverAccount),
                            ),
                            ..._driverPinAccounts.map(
                              (d) => ListTile(
                                dense: true,
                                title: Text(
                                    '${d['driver_name'] ?? ''} (${d['phone'] ?? ''})'),
                                subtitle: Text(() {
                                  final walletS =
                                      (d['wallet_balance'] ?? 0).toString();
                                  final ownerS =
                                      (d['owner_commission_rate'] ?? 10).toString();
                                  final b2bS =
                                      (d['b2b_commission_rate'] ?? 5).toString();
                                  var line = l.operatorDriverWalletLine(
                                    walletS,
                                    ownerS,
                                    b2bS,
                                  );
                                  final model = (d['car_model'] ?? '').toString().trim();
                                  final color = (d['car_color'] ?? '').toString().trim();
                                  if (model.isNotEmpty) {
                                    line += l.operatorDriverCarLine(model);
                                  }
                                  if (color.isNotEmpty) {
                                    line += l.operatorDriverCarColorAppend(color);
                                  }
                                  return line;
                                }()),
                                trailing: IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: _busy
                                      ? null
                                      : () => _editDriverAccount(d),
                                ),
                              ),
                            ),
                            const Divider(),
                            ..._adminUsers.map(
                              (u) => SwitchListTile(
                                dense: true,
                                title: Text(u['email']?.toString() ?? ''),
                                subtitle: Text(u['role']?.toString() ?? ''),
                                value: u['is_enabled'] == true,
                                onChanged: _busy ? null : (_) => _toggleUser(u),
                              ),
                            ),
                          ],
                        ),
                        ListView(
                          padding: const EdgeInsets.all(12),
                          children: [
                            FilledButton.tonal(
                              onPressed: _busy ? null : _refreshAll,
                              child: Text(l.operatorRefreshCorporateBookings),
                            ),
                            const SizedBox(height: 8),
                            if (_adminB2bBookings.isEmpty) Text(l.noTripsLoaded),
                            ..._adminB2bBookings.map(
                              (b) => ListTile(
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
                          ],
                        ),
                        ListView(
                          padding: const EdgeInsets.all(12),
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.inventory_2_outlined),
                                const SizedBox(width: 8),
                                Text(
                                  l.operatorTripVaultHeading,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
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
                                  label: Text(l.operatorTripVaultRevenueChip(
                                      _tripVaultRevenue.toStringAsFixed(3))),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (_trips.isEmpty) Text(l.noTripsLoaded),
                            ..._trips.map(
                              (t) => ListTile(
                                title: Text('${t['route']}'),
                                subtitle: Text(l.operatorTripSubtitle(
                                  t['date'] as String,
                                  t['fare'].toString(),
                                )),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (_message != null)
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(_message!,
                          style: const TextStyle(color: Colors.red)),
                    ),
                ],
              ),
            ),
    );
  }
}
