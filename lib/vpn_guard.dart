import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class VpnGuard extends StatefulWidget {
  final Widget child;
  const VpnGuard({super.key, required this.child});
  @override
  State<VpnGuard> createState() => _VpnGuardState();
}

class _VpnGuardState extends State<VpnGuard> with WidgetsBindingObserver {
  static const _channel = MethodChannel('taskearn/security');
  bool? _vpnActive;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _check();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _check();
  }

  Future<void> _check() async {
    try {
      final active = await _channel.invokeMethod<bool>('isVpnActive') ?? false;
      if (mounted) setState(() => _vpnActive = active);
    } catch (_) {
      if (mounted) setState(() => _vpnActive = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_vpnActive == null) {
      return const MaterialApp(debugShowCheckedModeBanner: false, home: Scaffold(body: Center(child: CircularProgressIndicator())));
    }
    if (_vpnActive == true) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.vpn_lock, size: 72),
                    const SizedBox(height: 18),
                    const Text('VPN ব্যবহার নিষিদ্ধ', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    const Text('Task Earn ব্যবহার করতে VPN বন্ধ করুন। VPN বন্ধ করার পর আবার চেষ্টা করুন.', textAlign: TextAlign.center),
                    const SizedBox(height: 20),
                    FilledButton(onPressed: _check, child: const Text('আবার পরীক্ষা করুন')),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }
    return widget.child;
  }
}
