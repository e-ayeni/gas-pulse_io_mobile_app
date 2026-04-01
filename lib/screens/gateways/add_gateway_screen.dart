import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../models/gateway.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class AddGatewayScreen extends StatefulWidget {
  final String siteId;
  const AddGatewayScreen({super.key, required this.siteId});

  @override
  State<AddGatewayScreen> createState() => _AddGatewayScreenState();
}

class _AddGatewayScreenState extends State<AddGatewayScreen> {
  final _formKey = GlobalKey<FormState>();
  final _deviceIdCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _deviceIdCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      await context.read<ApiService>().registerGateway(
            widget.siteId,
            RegisterGatewayRequest(
              deviceId: _deviceIdCtrl.text.trim(),
              name: _nameCtrl.text.trim().isEmpty ? null : _nameCtrl.text.trim(),
            ),
          );
      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gateway registered')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to register gateway'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Gateway')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'The gateway device ID is printed on the back of your GasPulse gateway box, or shown during its setup.',
                          style: TextStyle(fontSize: 13, color: Colors.blue.shade800),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _deviceIdCtrl,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Gateway Device ID',
                  hintText: 'e.g. GW-001',
                  prefixIcon: Icon(Icons.router_outlined),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter the device ID' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameCtrl,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: 'Name (optional)',
                  hintText: 'e.g. Kitchen Gateway',
                  prefixIcon: Icon(Icons.label_outline),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        height: 20, width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Register Gateway'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
