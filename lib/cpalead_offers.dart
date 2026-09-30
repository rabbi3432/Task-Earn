import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class CpaLeadOffersPage extends StatefulWidget {
  const CpaLeadOffersPage({super.key});
  @override
  State<CpaLeadOffersPage> createState() => _CpaLeadOffersPageState();
}

class _CpaLeadOffersPageState extends State<CpaLeadOffersPage> {
  bool loading = true;
  String? error;
  List<Map<String, dynamic>> offers = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    if (mounted) setState(() { loading = true; error = null; });
    try {
      final uid = Supabase.instance.client.auth.currentUser?.id;
      if (uid == null) throw Exception('আগে লগইন করুন');
      final response = await Supabase.instance.client.functions.invoke(
        'cpalead-offers',
        body: {'subid': uid},
      );
      final data = response.data;
      if (data is! Map || data['error'] != null) {
        throw Exception('CPAlead থেকে অফার পাওয়া যায়নি');
      }
      final list = data['offers'];
      offers = list is List
          ? list.whereType<Map>().map((x) => Map<String, dynamic>.from(x))
              .where((x) => (x['link'] ?? '').toString().startsWith('https://'))
              .toList()
          : [];
    } catch (e) {
      error = e.toString();
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> openOffer(Map<String, dynamic> offer) async {
    final uri = Uri.tryParse((offer['link'] ?? '').toString());
    if (uri == null || uri.scheme != 'https') return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (error != null) {
      return Center(child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('CPAlead অফার লোড হয়নি\n$error', textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton(onPressed: load, child: const Text('আবার চেষ্টা করুন')),
        ]),
      ));
    }
    if (offers.isEmpty) {
      return Center(child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('বাংলাদেশের Android ডিভাইসের জন্য এখন কোনো অফার পাওয়া যায়নি।', textAlign: TextAlign.center),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: load, child: const Text('Refresh')),
        ]),
      ));
    }
    return RefreshIndicator(
      onRefresh: load,
      child: ListView(padding: const EdgeInsets.all(12), children: [
        const Card(child: Padding(
          padding: EdgeInsets.all(12),
          child: Text('অফারের নির্দেশনা অনুসরণ করুন। Publisher payout আপনার Task Earn balance নয়; conversion tracking যুক্ত না হওয়া পর্যন্ত অটোমেটিক reward দেওয়া হবে না।'),
        )),
        ...offers.map((offer) => Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text((offer['title'] ?? 'CPAlead Offer').toString(),
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              if ((offer['description'] ?? '').toString().isNotEmpty)
                Text(offer['description'].toString()),
              if ((offer['conversion'] ?? '').toString().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text('Complete: ${offer['conversion']}'),
                ),
              const SizedBox(height: 8),
              Text('Publisher payout: ${offer['amount'] ?? '—'} ${offer['payout_currency'] ?? 'USD'}'),
              const SizedBox(height: 8),
              SizedBox(width: double.infinity, child: FilledButton(
                onPressed: () => openOffer(offer),
                child: const Text('Offer খুলুন'),
              )),
            ]),
          ),
        )),
      ]),
    );
  }
}