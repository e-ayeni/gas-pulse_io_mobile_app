import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../models/cylinder.dart';
import '../../models/cylinder_type.dart';
import '../../providers/cylinder_provider.dart';
import '../../theme/app_theme.dart';

class AddCylinderScreen extends StatefulWidget {
  final String siteId;
  const AddCylinderScreen({super.key, required this.siteId});

  @override
  State<AddCylinderScreen> createState() => _AddCylinderScreenState();
}

class _AddCylinderScreenState extends State<AddCylinderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _tareCtrl = TextEditingController();
  final _thresholdCtrl = TextEditingController(text: '20');
  CylinderType? _selectedType;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    context.read<CylinderProvider>().loadCylinderTypes();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _tareCtrl.dispose();
    _thresholdCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a cylinder type')),
      );
      return;
    }

    setState(() => _saving = true);

    final request = CreateCylinderRequest(
      friendlyName: _nameCtrl.text.trim(),
      cylinderTypeId: _selectedType!.id,
      customTareWeightGrams: _tareCtrl.text.trim().isNotEmpty
          ? (double.tryParse(_tareCtrl.text.trim())! * 1000).round()
          : null,
      alertThresholdPercent: int.tryParse(_thresholdCtrl.text.trim()),
    );

    final success = await context.read<CylinderProvider>().createCylinder(widget.siteId, request);
    if (mounted) {
      setState(() => _saving = false);
      if (success) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cylinder added')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to add cylinder'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cylTypes = context.watch<CylinderProvider>().cylinderTypes;

    return Scaffold(
      appBar: AppBar(title: const Text('Add Cylinder')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameCtrl,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Cylinder Name',
                  hintText: 'e.g. Kitchen Gas, Generator',
                  prefixIcon: Icon(Icons.propane_tank_outlined),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter a name' : null,
              ),
              const SizedBox(height: 24),
              const Text('Cylinder Type', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              const SizedBox(height: 8),
              if (cylTypes.isEmpty)
                const Center(child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ))
              else
                ...cylTypes.map((type) {
                  final isSelected = _selectedType?.id == type.id;
                  return Card(
                    color: isSelected ? AppColors.primary.withAlpha(20) : null,
                    margin: const EdgeInsets.only(bottom: 6),
                    child: ListTile(
                      leading: Icon(
                        isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                        color: isSelected ? AppColors.primary : Colors.grey,
                      ),
                      title: Text(type.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                      subtitle: Text(
                        'Gas: ${type.fullGasWeightKg} kg  |  Empty: ${type.tareWeightKg} kg',
                        style: const TextStyle(fontSize: 12),
                      ),
                      onTap: () => setState(() => _selectedType = type),
                    ),
                  );
                }),
              const SizedBox(height: 20),
              TextFormField(
                controller: _tareCtrl,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Custom Tare Weight (kg, optional)',
                  hintText: 'Leave blank to use default',
                  prefixIcon: Icon(Icons.scale),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _thresholdCtrl,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: 'Low Gas Alert Threshold (%)',
                  prefixIcon: Icon(Icons.notifications_active_outlined),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  final n = int.tryParse(v.trim());
                  if (n == null || n < 5 || n > 50) return 'Enter 5-50';
                  return null;
                },
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        height: 20, width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Add Cylinder'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
