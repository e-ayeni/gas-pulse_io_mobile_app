import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../models/site.dart';
import '../../providers/site_provider.dart';
import '../../theme/app_theme.dart';

class AddSiteScreen extends StatefulWidget {
  const AddSiteScreen({super.key});

  @override
  State<AddSiteScreen> createState() => _AddSiteScreenState();
}

class _AddSiteScreenState extends State<AddSiteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _streetCtrl = TextEditingController();
  final _areaCtrl = TextEditingController();
  final _lgaCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _streetCtrl.dispose();
    _areaCtrl.dispose();
    _lgaCtrl.dispose();
    _stateCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final request = CreateSiteRequest(
      name: _nameCtrl.text.trim(),
      address: NigerianAddress(
        street: _streetCtrl.text.trim().isEmpty ? null : _streetCtrl.text.trim(),
        area: _areaCtrl.text.trim().isEmpty ? null : _areaCtrl.text.trim(),
        localGovernment: _lgaCtrl.text.trim().isEmpty ? null : _lgaCtrl.text.trim(),
        state: _stateCtrl.text.trim().isEmpty ? null : _stateCtrl.text.trim(),
      ),
    );

    final success = await context.read<SiteProvider>().createSite(request);
    if (mounted) {
      setState(() => _saving = false);
      if (success) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Site created')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to create site'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Site')),
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
                  labelText: 'Site Name',
                  hintText: 'e.g. Home, Office, Warehouse',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter a site name' : null,
              ),
              const SizedBox(height: 24),
              const Text('Address (optional)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              const SizedBox(height: 12),
              TextFormField(
                controller: _streetCtrl,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'Street'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _areaCtrl,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'Area'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _lgaCtrl,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(labelText: 'LGA'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _stateCtrl,
                      textInputAction: TextInputAction.done,
                      decoration: const InputDecoration(labelText: 'State'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        height: 20, width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Create Site'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
