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
  final _area = TextEditingController();
  final _city = TextEditingController();
  final _pincode = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _label.dispose();
    _line.dispose();
    _area.dispose();
    _city.dispose();
    _pincode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final backend = ref.watch(backendProvider);
    final user = backend.currentUser;
    if (_city.text.isEmpty) _city.text = backend.store.city;
    final addresses = user == null ? <Address>[] : backend.addressesFor(user.id);

    return Scaffold(
      appBar: AppBar(title: const Text('Addresses')),
      body: user == null
          ? const Center(child: Text('Sign in to save an address.'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                for (final address in addresses)
                  Card(
                    color: BloomlyColors.card,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    child: ListTile(
                      title: Text(
                        address.isDefault ? '${address.label} · Default' : address.label,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(address.snapshot),
                      trailing: IconButton(
                        onPressed: () => backend.deleteAddress(address.id),
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                Text('New address', style: BloomlyType.display(24)),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _useLocation,
                  icon: const Icon(Icons.my_location),
                  label: Text(
                    ref.watch(placeProvider).requesting
                        ? 'Finding you…'
                        : 'Use current location',
                  ),
                ),
                if (ref.watch(placeProvider).error != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    ref.watch(placeProvider).error!,
                    style: const TextStyle(color: BloomlyColors.danger),
                  ),
                ],
                const SizedBox(height: 8),
                TextField(controller: _label, decoration: const InputDecoration(labelText: 'Label')),
                const SizedBox(height: 8),
                TextField(controller: _line, decoration: const InputDecoration(labelText: 'House / street')),
                const SizedBox(height: 8),
                TextField(controller: _area, decoration: const InputDecoration(labelText: 'Area')),
                const SizedBox(height: 8),
                TextField(controller: _city, decoration: const InputDecoration(labelText: 'City')),
                const SizedBox(height: 8),
                TextField(
                  controller: _pincode,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Pincode'),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(_error!, style: const TextStyle(color: BloomlyColors.danger)),
                ],
                const SizedBox(height: 12),
                FilledButton(onPressed: () => _save(user.id), child: const Text('Save address')),
              ],
            ),
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
    final sameCity = detected != null &&
        detected.city.trim().toLowerCase() == _city.text.trim().toLowerCase();
    await backend.saveAddress(
      Address(
        id: 'addr${DateTime.now().millisecondsSinceEpoch}',
        userId: userId,
        label: _label.text.trim().isEmpty ? 'Home' : _label.text.trim(),
        line: _line.text.trim(),
        area: _area.text.trim(),
        city: _city.text.trim(),
        pincode: _pincode.text.trim(),
        isDefault: existing.isEmpty,
        latitude: sameCity ? detected.latitude : null,
        longitude: sameCity ? detected.longitude : null,
      ),
    );
    _line.clear();
    _area.clear();
    _pincode.clear();
    setState(() => _error = null);
  }
}
