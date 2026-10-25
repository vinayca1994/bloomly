import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../data/models.dart';
import '../../data/providers.dart';

class AddressesScreen extends ConsumerStatefulWidget {
  const AddressesScreen({super.key});

  @override
  ConsumerState<AddressesScreen> createState() => _AddressesScreenState();
}

class _AddressesScreenState extends ConsumerState<AddressesScreen> {
  final _label = TextEditingController(text: 'Home');
  final _line = TextEditingController();
  final _landmark = TextEditingController();
  final _area = TextEditingController();
  final _city = TextEditingController();
  final _pincode = TextEditingController();
  String? _editingId;
  String? _error;
  var _form = false;

  @override
  void dispose() {
    _label.dispose();
    _line.dispose();
    _landmark.dispose();
    _area.dispose();
    _city.dispose();
    _pincode.dispose();
    super.dispose();
  }

  void _clearForm({required String city}) {
    _editingId = null;
    _label.text = 'Home';
    _line.clear();
    _landmark.clear();
    _area.clear();
    _city.text = city;
    _pincode.clear();
    _error = null;
  }

  void _openNew(String city) {
    _clearForm(city: city);
    _form = true;
  }

  void _fillForm(Address address) {
    _editingId = address.id;
    _label.text = address.label;
    _line.text = address.line;
    _landmark.text = address.landmark;
    _area.text = address.area;
    _city.text = address.city;
    _pincode.text = address.pincode;
    _error = null;
    _form = true;
  }

  String get _saveAs {
    final label = _label.text.trim().toLowerCase();
    if (label == 'home') return 'Home';
    if (label == 'work') return 'Work';
    return 'Other';
  }

  @override
  Widget build(BuildContext context) {
    final backend = ref.watch(backendProvider);
    final user = backend.currentUser;
    if (_city.text.isEmpty) _city.text = backend.store.city;
    final addresses = user == null ? <Address>[] : backend.addressesFor(user.id);
    final tokens = context.bloom;

    return Scaffold(
      appBar: AppBar(
        title: Text(_form ? (_editingId == null ? 'New address' : 'Edit address') : 'Saved addresses'),
        leading: _form
            ? IconButton(
                tooltip: 'Back',
                onPressed: () => setState(() {
                  _form = false;
                  _clearForm(city: backend.store.city);
                }),
                icon: const Icon(Icons.arrow_back),
              )
            : null,
      ),
      body: user == null
          ? const Center(child: Text('Sign in to save an address.'))
          : _form
          ? _formBody(tokens)
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                for (final address in addresses) ...[
                  _AddressCard(
                    address: address,
                    onEdit: () => setState(() => _fillForm(address)),
                    onDefault: address.isDefault
                        ? null
                        : () => backend.saveAddress(address.copyWith(isDefault: true)),
                    onDelete: () => backend.deleteAddress(address.id),
                  ),
                  const SizedBox(height: 12),
                ],
                OutlinedButton.icon(
                  onPressed: () => setState(() => _openNew(backend.store.city)),
                  icon: const Icon(Icons.add),
                  label: const Text('Add new address'),
                ),
              ],
            ),
      bottomNavigationBar: user == null || !_form
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: FilledButton(
                  onPressed: () => _save(user.id),
                  child: const Text('Save address'),
                ),
              ),
            ),
    );
  }

  Widget _formBody(BloomTokens tokens) {
    final place = ref.watch(placeProvider);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        DecoratedBox(
          decoration: BloomlyDecor.card(tokens),
          child: Column(
            children: [
              Container(
                height: 120,
                width: double.infinity,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: tokens.infoBg,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Icon(Icons.location_on, size: 36, color: tokens.primary),
              ),
              ListTile(
                leading: Icon(Icons.near_me_outlined, color: tokens.link),
                title: Text(
                  place.requesting ? 'Finding you…' : 'Use my current location',
                  style: TextStyle(color: tokens.link, fontWeight: FontWeight.w700),
                ),
                trailing: place.place == null
                    ? null
                    : Text('Detected', style: TextStyle(color: tokens.textSecondary, fontSize: 12)),
                onTap: place.requesting ? null : _useLocation,
              ),
            ],
          ),
        ),
        if (place.error != null) ...[
          const SizedBox(height: 8),
          Text(place.error!, style: TextStyle(color: tokens.danger)),
        ],
        const SizedBox(height: 16),
        TextField(
          controller: _line,
          decoration: const InputDecoration(labelText: 'House, flat or floor'),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _area,
          decoration: const InputDecoration(labelText: 'Street and area'),
        ),
        const SizedBox(height: 8),
        TextField(controller: _city, decoration: const InputDecoration(labelText: 'City')),
        const SizedBox(height: 8),
        TextField(
          controller: _pincode,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Pincode'),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _landmark,
          decoration: const InputDecoration(labelText: 'Landmark (optional)'),
        ),
        const SizedBox(height: 16),
        Text(
          'Save as',
          style: BloomlyType.uiText(13, weight: FontWeight.w800, color: tokens.textSecondary),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            for (final name in const ['Home', 'Work', 'Other'])
              ChoiceChip(
                showCheckmark: false,
                label: Text(name),
                selected: _saveAs == name,
                onSelected: (_) => setState(() {
                  if (name == 'Other' && _saveAs != 'Other') {
                    _label.text = '';
                  } else if (name != 'Other') {
                    _label.text = name;
                  }
                }),
              ),
          ],
        ),
        if (_saveAs == 'Other') ...[
          const SizedBox(height: 8),
          TextField(
            controller: _label,
            decoration: const InputDecoration(labelText: 'Label'),
            onChanged: (_) => setState(() {}),
          ),
        ],
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(_error!, style: TextStyle(color: tokens.danger)),
        ],
      ],
    );
  }

  Future<void> _useLocation() async {
    final detected = await ref.read(placeProvider).detect(announceLookupFailure: true);
    if (!mounted || detected == null || detected.city.isEmpty) return;
    setState(() {
      if (detected.area.isNotEmpty) _area.text = detected.area;
      _city.text = detected.city;
      if (detected.pincode.isNotEmpty) _pincode.text = detected.pincode;
      _error = null;
    });
  }

  Future<void> _save(String userId) async {
    if (_line.text.trim().isEmpty || _area.text.trim().isEmpty || _city.text.trim().isEmpty) {
      setState(() => _error = 'Add the street, area, and city.');
      return;
    }
    final backend = ref.read(backendProvider);
    final existing = backend.addressesFor(userId);
    final detected = ref.read(placeProvider).place;
    final sameCity =
        detected != null && detected.city.trim().toLowerCase() == _city.text.trim().toLowerCase();
    Address? editing;
    if (_editingId != null) {
      for (final address in existing) {
        if (address.id == _editingId) {
          editing = address;
          break;
        }
      }
    }
    final label = _label.text.trim().isEmpty ? 'Home' : _label.text.trim();
    await backend.saveAddress(
      Address(
        id: _editingId ?? 'addr${DateTime.now().millisecondsSinceEpoch}',
        userId: userId,
        label: label,
        line: _line.text.trim(),
        landmark: _landmark.text.trim(),
        area: _area.text.trim(),
        city: _city.text.trim(),
        pincode: _pincode.text.trim(),
        isDefault: editing?.isDefault ?? existing.isEmpty,
        latitude: sameCity ? detected.latitude : editing?.latitude,
        longitude: sameCity ? detected.longitude : editing?.longitude,
      ),
    );
    if (!mounted) return;
    setState(() {
      _form = false;
      _clearForm(city: backend.store.city);
    });
  }
}

class _AddressCard extends StatelessWidget {
  const _AddressCard({
    required this.address,
    required this.onEdit,
    required this.onDefault,
    required this.onDelete,
  });

  final Address address;
  final VoidCallback onEdit;
  final VoidCallback? onDefault;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final tokens = context.bloom;
    final icon = switch (address.label.toLowerCase()) {
      'home' => Icons.home_outlined,
      'work' => Icons.work_outline,
      _ => Icons.location_on_outlined,
    };
    return DecoratedBox(
      decoration: BloomlyDecor.card(tokens),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 4, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: tokens.text),
                const SizedBox(width: 8),
                Text(address.label, style: const TextStyle(fontWeight: FontWeight.w800)),
                if (address.isDefault) ...[
                  const SizedBox(width: 8),
                  Container(
                    height: 20,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: tokens.success.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'Default',
                      style: BloomlyType.uiText(11, weight: FontWeight.w800, color: tokens.success),
                    ),
                  ),
                ],
                const Spacer(),
                PopupMenuButton<String>(
                  tooltip: 'Address actions',
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        onEdit();
                      case 'default':
                        onDefault?.call();
                      case 'delete':
                        onDelete();
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                    if (onDefault != null)
                      const PopupMenuItem(value: 'default', child: Text('Set as default')),
                    const PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Text(address.snapshot, style: TextStyle(color: tokens.textSecondary)),
            ),
          ],
        ),
      ),
    );
  }
}
