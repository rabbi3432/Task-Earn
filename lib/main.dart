import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:app_links/app_links.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:file_picker/file_picker.dart';
import 'package:startapp_sdk/startapp.dart';
import 'vpn_guard.dart';

const supabaseProjectRef = 'gzamivqrrflogjjvhbej';
const supabaseUrl = 'https://$supabaseProjectRef.supabase.co';
const supabaseKey = 'sb_publishable_emPACnJ0LsZ1GjParqjJVA_wDO3faQg';

String? pendingReferralCode;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: supabaseUrl, publishableKey: supabaseKey);
  final appLinks = AppLinks();
  try {
    final initial = await appLinks.getInitialLink();
    if (initial != null && initial.scheme == 'taskearn') {
      pendingReferralCode = initial.queryParameters['ref'];
    }
  } catch (_) {}
  appLinks.uriLinkStream.listen((uri) {
    if (uri.scheme == 'taskearn' && uri.queryParameters['ref'] != null) {
      pendingReferralCode = uri.queryParameters['ref'];
    }
  });
  runApp(const VpnGuard(child: TaskEarnApp()));
}

final supabase = Supabase.instance.client;

String authEmailFromPhone(String mobile) =>
    'phone_${mobile.replaceAll(RegExp(r'[^0-9]'), '')}@taskearn.local';

String normalizePhone(String mobile) => mobile.trim();

class TaskEarnApp extends StatelessWidget {
  const TaskEarnApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Task Earn',
    theme: ThemeData(
      useMaterial3:true,
      colorScheme:ColorScheme.fromSeed(seedColor:const Color(0xFF5B4BFF),brightness:Brightness.light),
      scaffoldBackgroundColor:const Color(0xFFF5F7FC),
      cardTheme:CardThemeData(elevation:0,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(20))),
      appBarTheme:const AppBarTheme(backgroundColor:Color(0xFFF5F7FC),surfaceTintColor:Colors.transparent),
      navigationBarTheme:const NavigationBarThemeData(backgroundColor:Colors.white,indicatorColor:Color(0xFFDDE7FF)),
    ),
    home: supabase.auth.currentSession == null ? const LoginPage() : const Shell(),
  );
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override State<LoginPage> createState() => _LoginPageState();
}
class _LoginPageState extends State<LoginPage> {
  final phone = TextEditingController(), password = TextEditingController();
  bool loading = false, obscure = true;
  @override void dispose(){phone.dispose();password.dispose();super.dispose();}
  Future<void> login() async {
    final mobile=normalizePhone(phone.text), pass=password.text;
    if(!RegExp(r'^01[3-9][0-9]{8}$').hasMatch(mobile)||pass.length<6){
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('সঠিক মোবাইল নম্বর ও পাসওয়ার্ড দিন'))); return;
    }
    setState(()=>loading=true);
    try {
      await supabase.auth.signInWithPassword(email:authEmailFromPhone(mobile),password:pass);
      final uid=supabase.auth.currentUser?.id;
      if(uid!=null){final p=await supabase.from('profiles').select('is_blocked').eq('id',uid).maybeSingle();if(p?['is_blocked']==true){await supabase.auth.signOut();throw const AuthException('আপনার অ্যাকাউন্টটি Admin দ্বারা Block করা হয়েছে।');}}
      if(mounted) Navigator.pushAndRemoveUntil(context,MaterialPageRoute(builder:(_)=>const Shell()),(_)=>false);
    } on AuthException catch(e) { if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.message))); }
    finally { if(mounted)setState(()=>loading=false); }
  }
  @override Widget build(BuildContext context)=>Scaffold(body:SafeArea(child:ListView(padding:const EdgeInsets.all(24),children:[
    const SizedBox(height:60),const Icon(Icons.task_alt,size:76),const SizedBox(height:12),
    const Center(child:Text('Task Earn',style:TextStyle(fontSize:32,fontWeight:FontWeight.bold))),
    const Center(child:Text('Complete tasks • Track earnings')),const SizedBox(height:32),
    TextField(controller:phone,keyboardType:TextInputType.phone,decoration:const InputDecoration(labelText:'মোবাইল নম্বর (01XXXXXXXXX)',border:OutlineInputBorder())),
    const SizedBox(height:16),
    TextField(controller:password,obscureText:obscure,decoration:InputDecoration(labelText:'পাসওয়ার্ড',border:const OutlineInputBorder(),suffixIcon:IconButton(onPressed:()=>setState(()=>obscure=!obscure),icon:Icon(obscure?Icons.visibility:Icons.visibility_off)))),
    const SizedBox(height:16),FilledButton(onPressed:loading?null:login,child:Text(loading?'লগইন হচ্ছে...':'লগইন')),
    TextButton(onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const RegisterPage())),child:const Text('নতুন অ্যাকাউন্ট তৈরি করুন')),
  ])));
}

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});
  @override State<RegisterPage> createState()=>_RegisterPageState();
}
class _RegisterPageState extends State<RegisterPage>{
  final name=TextEditingController(),phone=TextEditingController(),password=TextEditingController(),confirm=TextEditingController(),referral=TextEditingController();
  @override void initState(){super.initState();if(pendingReferralCode!=null){referral.text=pendingReferralCode!;pendingReferralCode=null;}}
  bool agree=false,loading=false,obscure=true,obscureConfirm=true;
  @override void dispose(){name.dispose();phone.dispose();password.dispose();confirm.dispose();referral.dispose();super.dispose();}
  Future<void> submit() async {
    final fullName=name.text.trim(),mobile=normalizePhone(phone.text),pass=password.text,confirmPass=confirm.text,refCode=referral.text.trim();
    if(fullName.length<2||!RegExp(r'^01[3-9][0-9]{8}$').hasMatch(mobile)||pass.length<6||pass!=confirmPass||!agree){
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('সব তথ্য সঠিকভাবে পূরণ করুন'))); return;
    }
    setState(()=>loading=true);
    try {
      final res=await supabase.auth.signUp(email:authEmailFromPhone(mobile),password:pass,data:{'full_name':fullName,'phone':mobile});
      final user=res.user;
      if(user==null) throw const AuthException('অ্যাকাউন্ট তৈরি হয়নি।');
      if(res.session==null) throw const AuthException('অ্যাকাউন্ট তৈরি হয়েছে, কিন্তু লগইন session পাওয়া যায়নি।');
      await supabase.from('profiles').update({'full_name':fullName,'phone':mobile}).eq('id',user.id);
      if(refCode.isNotEmpty) await supabase.rpc('claim_referral',params:{'p_code':refCode});
      if(mounted) Navigator.pushAndRemoveUntil(context,MaterialPageRoute(builder:(_)=>const Shell()),(_)=>false);
    } on AuthException catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.message)));}
    on PostgrestException catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('প্রোফাইল সংরক্ষণ হয়নি: ${e.message}')));}
    finally{if(mounted)setState(()=>loading=false);}
  }
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('Create Account')),body:ListView(padding:const EdgeInsets.all(20),children:[
    TextField(controller:name,decoration:const InputDecoration(labelText:'পূর্ণ নাম',border:OutlineInputBorder())),const SizedBox(height:12),
    TextField(controller:phone,keyboardType:TextInputType.phone,decoration:const InputDecoration(labelText:'মোবাইল নম্বর (01XXXXXXXXX)',border:OutlineInputBorder())),const SizedBox(height:12),
    TextField(controller:password,obscureText:obscure,decoration:InputDecoration(labelText:'পাসওয়ার্ড (কমপক্ষে ৬ অক্ষর)',border:const OutlineInputBorder(),suffixIcon:IconButton(onPressed:()=>setState(()=>obscure=!obscure),icon:Icon(obscure?Icons.visibility:Icons.visibility_off)))),const SizedBox(height:12),
    TextField(controller:confirm,obscureText:obscureConfirm,decoration:InputDecoration(labelText:'পাসওয়ার্ড আবার লিখুন',border:const OutlineInputBorder(),suffixIcon:IconButton(onPressed:()=>setState(()=>obscureConfirm=!obscureConfirm),icon:Icon(obscureConfirm?Icons.visibility:Icons.visibility_off)))),const SizedBox(height:12),
    TextField(controller:referral,decoration:const InputDecoration(labelText:'Referral code (ঐচ্ছিক)',hintText:'বন্ধুর referral code',border:OutlineInputBorder())),
    CheckboxListTile(value:agree,onChanged:(v)=>setState(()=>agree=v??false),contentPadding:EdgeInsets.zero,title:const Text('Terms ও Privacy Policy-তে সম্মত')),
    FilledButton(onPressed:loading?null:submit,child:Text(loading?'অ্যাকাউন্ট তৈরি হচ্ছে...':'অ্যাকাউন্ট তৈরি করুন')),
  ]));
}

class StartIoBanner extends StatefulWidget{const StartIoBanner({super.key});@override State<StartIoBanner> createState()=>_StartIoBannerState();}
class _StartIoBannerState extends State<StartIoBanner>{
 final StartAppSdk _sdk=StartAppSdk();StartAppBannerAd? _ad;bool _loading=true;String? _error;
 @override void initState(){super.initState();_load();}
 Future<void> _load()async{if(!mounted)return;setState(()=>_loading=true);try{
   await _sdk.setTestAdsEnabled(kDebugMode);
   final ad=await _sdk.loadBannerAd(
     StartAppBannerType.BANNER,
     onAdImpression:()=>debugPrint('Start.io banner impression received'),
     onAdClicked:()=>debugPrint('Start.io banner clicked'),
   );
   if(mounted)setState(()=>_ad=ad);
 }catch(e,st){
   debugPrint('Start.io banner load failed: $e');
   debugPrintStack(stackTrace:st);
   if(mounted)setState(()=>_error=e.toString());
 }finally{if(mounted)setState(()=>_loading=false);}}
 @override void dispose(){_ad?.dispose();super.dispose();}
 @override Widget build(BuildContext context){final ad=_ad;if(ad==null)return SizedBox(height:50,child:Center(child:Text(_loading?'বিজ্ঞাপন লোড হচ্ছে...':(_error!=null?'বিজ্ঞাপন এই মুহূর্তে পাওয়া যায়নি':'বিজ্ঞাপন লোড হচ্ছে...'),style:TextStyle(fontSize:12,color:Theme.of(context).colorScheme.primary))));return SizedBox(height:50,width:double.infinity,child:Center(child:StartAppBanner(ad)));}
}
class Shell extends StatefulWidget{
  const Shell({super.key});
  @override State<Shell> createState()=>_ShellState();
}
class _ShellState extends State<Shell>{
  int index=0;
  final pages=const[HomePage(),TasksPage(),RewardsPage(),WalletPage(),ProfilePage()];
  static const sectionColors=[
    Color(0xFF2563EB),Color(0xFF059669),Color(0xFFEA580C),Color(0xFF7C3AED),Color(0xFFDB2777),
  ];
  static const sectionTints=[
    Color(0xFFEFF6FF),Color(0xFFECFDF5),Color(0xFFFFF7ED),Color(0xFFF5F3FF),Color(0xFFFDF2F8),
  ];
  @override Widget build(BuildContext context){
    final color=sectionColors[index], tint=sectionTints[index];
    final sectionTheme=Theme.of(context).copyWith(
      colorScheme:ColorScheme.fromSeed(seedColor:color,brightness:Brightness.light),
      scaffoldBackgroundColor:tint,
      appBarTheme:AppBarTheme(backgroundColor:tint,surfaceTintColor:Colors.transparent,foregroundColor:color),
      cardTheme:CardThemeData(elevation:0,color:Colors.white,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(20))),
      navigationBarTheme:NavigationBarThemeData(
        backgroundColor:Colors.white,indicatorColor:color.withValues(alpha:.16),
        labelTextStyle:WidgetStatePropertyAll(TextStyle(color:color,fontWeight:FontWeight.w700)),
      ),
    );
    return Theme(data:sectionTheme,child:Scaffold(
      body:Column(children:[
        const SafeArea(bottom:false,child:StartIoBanner()),
        Expanded(child:IndexedStack(index:index,children:pages)),
      ]),
      bottomNavigationBar:NavigationBar(
        height:72,selectedIndex:index,onDestinationSelected:(i)=>setState(()=>index=i),
        destinations:const[
          NavigationDestination(icon:Icon(Icons.home_outlined),selectedIcon:Icon(Icons.home),label:'Home'),
          NavigationDestination(icon:Icon(Icons.credit_card_outlined),selectedIcon:Icon(Icons.credit_card),label:'Earn'),
          NavigationDestination(icon:Icon(Icons.card_giftcard),selectedIcon:Icon(Icons.redeem),label:'Rewards'),
          NavigationDestination(icon:Icon(Icons.account_balance_wallet_outlined),selectedIcon:Icon(Icons.account_balance_wallet),label:'Wallet'),
          NavigationDestination(icon:Icon(Icons.person_outline),selectedIcon:Icon(Icons.person),label:'Profile'),
        ]),
    ));
  }
}

class HomePage extends StatefulWidget{const HomePage({super.key});@override State<HomePage> createState()=>_HomePageState();}
class _HomePageState extends State<HomePage>{
 bool loading=true;double balance=0,earned=0;int available=0,pending=0,approved=0;List<Map<String,dynamic>> banners=[],rules=[];Map<String,dynamic>? support;
 @override void initState(){super.initState();load();}
 Future<void> load()async{setState(()=>loading=true);try{final uid=supabase.auth.currentUser!.id;final r=await Future.wait([supabase.from('wallet_transactions').select('amount,type').eq('user_id',uid),supabase.from('tasks').select('id').eq('is_active',true),supabase.from('task_submissions').select('status,task_id').eq('user_id',uid),supabase.from('app_content').select().eq('is_active',true).order('sort_order'),supabase.from('support_settings').select().eq('id',1).maybeSingle()]);double b=0,en=0;for(final x in r[0] as List){final a=(x['amount'] as num).toDouble();b+=a;if(x['type']=='task_reward')en+=a;}int p=0,ap=0;final submitted=<dynamic>{};for(final x in r[2] as List){submitted.add(x['task_id']);if(x['status']=='pending')p++;if(x['status']=='approved')ap++;}final open=(r[1] as List).where((x)=>!submitted.contains(x['id'])).length;if(mounted)setState((){balance=b;earned=en;available=open;pending=p;approved=ap;banners=List<Map<String,dynamic>>.from((r[3] as List).where((x)=>x['content_type']=='banner'));rules=List<Map<String,dynamic>>.from((r[3] as List).where((x)=>x['content_type']=='rule'));support=r[4] as Map<String,dynamic>?;});}catch(err){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Dashboard লোড হয়নি: $err')));}finally{if(mounted)setState(()=>loading=false);}}
 Widget stat(IconData i,String t,String v,Color c)=>Expanded(child:Container(margin:const EdgeInsets.symmetric(vertical:4),decoration:BoxDecoration(color:c.withValues(alpha:.12),borderRadius:BorderRadius.circular(22),border:Border.all(color:c.withValues(alpha:.22))),child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[CircleAvatar(backgroundColor:c.withValues(alpha:.16),child:Icon(i,color:c)),const SizedBox(height:8),Text(v,style:TextStyle(fontSize:22,fontWeight:FontWeight.bold,color:c)),Text(t,style:const TextStyle(fontSize:12,fontWeight:FontWeight.w600))]))));
 @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('Home',style:TextStyle(fontSize:27,fontWeight:FontWeight.w800)),actions:[IconButton(onPressed:load,icon:const Icon(Icons.headset_mic_outlined))]),body:RefreshIndicator(onRefresh:load,child:ListView(padding:const EdgeInsets.all(16),children:[
 Container(padding:const EdgeInsets.all(22),decoration:BoxDecoration(gradient:const LinearGradient(colors:[Color(0xFF165DFF),Color(0xFF7B3FF2)]),borderRadius:BorderRadius.circular(26),boxShadow:[BoxShadow(color:const Color(0xFF165DFF).withValues(alpha:.20),blurRadius:18,offset:const Offset(0,8))]),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('Available Balance',style:TextStyle(color:Colors.white70,fontWeight:FontWeight.w600)),Text(loading?'...':'৳${balance.toStringAsFixed(2)}',style:const TextStyle(color:Colors.white,fontSize:34,fontWeight:FontWeight.w800)),Text('Total earned: ৳${earned.toStringAsFixed(2)}',style:const TextStyle(color:Colors.white70))])),
 Row(children:[stat(Icons.task_alt,'Available','$available',const Color(0xFF00A86B)),const SizedBox(width:8),stat(Icons.hourglass_top,'Pending','$pending',const Color(0xFFFF9F1C))]),Row(children:[stat(Icons.verified_outlined,'Approved','$approved',const Color(0xFF7B3FF2)),const SizedBox(width:8),stat(Icons.account_balance_wallet_outlined,'Wallet','৳${balance.toStringAsFixed(0)}',const Color(0xFF0077B6))]),
 const SizedBox(height:16),
 if(banners.isEmpty)Container(height:150,decoration:BoxDecoration(gradient:const LinearGradient(colors:[Color(0xFFE8EEFF),Color(0xFFF1E8FF)]),borderRadius:BorderRadius.circular(22)),child:const Center(child:Column(mainAxisSize:MainAxisSize.min,children:[Icon(Icons.campaign_outlined,size:36,color:Color(0xFF6B35E8)),SizedBox(height:8),Text('বিজ্ঞাপন / ব্যানার',style:TextStyle(fontSize:18,fontWeight:FontWeight.bold)),Text('Admin Panel থেকে বিজ্ঞাপন প্রকাশ করুন',style:TextStyle(fontSize:12))]))),
 if(banners.isNotEmpty)...[const Text('ঘোষণা',style:TextStyle(fontSize:20,fontWeight:FontWeight.w800)),const SizedBox(height:8),...banners.map((b)=>Container(margin:const EdgeInsets.only(bottom:10),padding:const EdgeInsets.all(18),decoration:BoxDecoration(gradient:const LinearGradient(colors:[Color(0xFF2255D9),Color(0xFF6B35E8)]),borderRadius:BorderRadius.circular(20)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[if((b['image_url']??'').toString().isNotEmpty)ClipRRect(borderRadius:BorderRadius.circular(14),child:Image.network(b['image_url'].toString(),height:150,width:double.infinity,fit:BoxFit.cover,errorBuilder:(c,e,st)=>const SizedBox.shrink())),if((b['image_url']??'').toString().isNotEmpty)const SizedBox(height:10),Text(b['title'].toString(),style:const TextStyle(color:Colors.white,fontSize:20,fontWeight:FontWeight.bold)),if((b['body']??'').toString().isNotEmpty)Text(b['body'].toString(),style:const TextStyle(color:Colors.white)),if((b['target_url']??'').toString().isNotEmpty)Align(alignment:Alignment.centerRight,child:TextButton.icon(style:TextButton.styleFrom(foregroundColor:Colors.white),onPressed:()=>launchUrl(Uri.parse(b['target_url'].toString()),mode:LaunchMode.externalApplication),icon:const Icon(Icons.open_in_new),label:const Text('দেখুন')))]))),],
 if(rules.isNotEmpty)...[const SizedBox(height:10),const Text('নিয়মাবলী',style:TextStyle(fontSize:20,fontWeight:FontWeight.w800)),Card(child:Column(children:rules.map((x)=>ListTile(leading:const Icon(Icons.verified_outlined,color:Color(0xFF2255D9)),title:Text(x['title'].toString()),subtitle:(x['body']??'').toString().isEmpty?null:Text(x['body'].toString()))).toList()))],
 if(support!=null)...[const SizedBox(height:10),const Text('কাস্টমার কেয়ার',style:TextStyle(fontSize:20,fontWeight:FontWeight.w800)),Card(child:Column(children:[if((support?['telegram_channel_url']??'').toString().isNotEmpty)ListTile(leading:const Icon(Icons.campaign),title:const Text('Telegram Channel'),trailing:const Icon(Icons.open_in_new),onTap:()=>launchUrl(Uri.parse(support!['telegram_channel_url'].toString()),mode:LaunchMode.externalApplication)),if((support?['telegram_account']??'').toString().isNotEmpty)ListTile(leading:const Icon(Icons.support_agent),title:Text(support!['telegram_account'].toString()),subtitle:Text(support?['support_message']?.toString()??''),onTap:(){final a=support!['telegram_account'].toString().replaceAll('@','');launchUrl(Uri.parse('https://t.me/$a'),mode:LaunchMode.externalApplication);})]))],
 const SizedBox(height:20),const Text('Tutorials',style:TextStyle(fontSize:22,fontWeight:FontWeight.w800)),Container(decoration:BoxDecoration(color:const Color(0xFFFFF4E6),borderRadius:BorderRadius.circular(22)),child:const Column(children:[ListTile(leading:CircleAvatar(backgroundColor:Color(0xFFFFD8A8),child:Text('1')),title:Text('Task বেছে নিন')),Divider(height:1),ListTile(leading:CircleAvatar(backgroundColor:Color(0xFFCCF2E4),child:Text('2')),title:Text('কাজ শেষ করে Proof জমা দিন')),Divider(height:1),ListTile(leading:CircleAvatar(backgroundColor:Color(0xFFE1D5FF),child:Text('3')),title:Text('Approve হলে Reward Wallet-এ পাবেন'))]))
 ])));
}

class TasksPage extends StatefulWidget {
  const TasksPage({super.key});
  @override State<TasksPage> createState() => _TasksPageState();
}
class _TasksPageState extends State<TasksPage> {
  bool loading = true;
  List<Map<String, dynamic>> tasks = [];
  List<Map<String, dynamic>> mine = [];
  @override void initState() { super.initState(); loadTasks(); }
  Future<void> loadTasks() async {
    setState(() => loading = true);
    try {
      final uid = supabase.auth.currentUser!.id;
      final results = await Future.wait([
        supabase.from('tasks').select('id,title,description,reward,max_submissions,task_type,ad_watch_seconds,target_url,daily_claim_limit,provider,provider_offer_id,provider_payout_usd,provider_currency,provider_conversion').eq('is_active', true).order('created_at', ascending: false),
        supabase.from('task_submissions').select('id,task_id,status,reward_points,reward_amount,created_at,tasks(title)').eq('user_id', uid).order('created_at', ascending: false),
      ]);
      final submitted = List<Map<String, dynamic>>.from(results[1]);
      final claimed = submitted.map((x) => x['task_id']).toSet();
      final available = List<Map<String, dynamic>>.from(results[0]).where((t) {
        if (t['task_type'] == 'ad_watch') return true;
        return !claimed.contains(t['id']);
      }).toList();
      if (mounted) setState(() { mine = submitted; tasks = available; });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Task লোড হয়নি: $e')));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }
  Color statusColor(String status) {
    if (status == 'approved') return Colors.green;
    if (status == 'rejected') return Colors.red;
    return Colors.orange;
  }
  @override Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Tasks', style: TextStyle(fontWeight: FontWeight.bold)),
          bottom: const TabBar(tabs: [Tab(text: 'Available'), Tab(text: 'My Tasks')]),
          actions: [IconButton(onPressed: loadTasks, icon: const Icon(Icons.refresh))],
        ),
        body: loading ? const Center(child: CircularProgressIndicator()) : TabBarView(
          children: [
            RefreshIndicator(
              onRefresh: loadTasks,
              child: tasks.isEmpty
                  ? ListView(children: const [SizedBox(height: 180), Center(child: Text('এখন কোনো Task নেই'))])
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: tasks.length,
                      itemBuilder: (context, index) {
                        final task = tasks[index];
                        final done = mine.any((m) => m['task_id'] == task['id']);
                        final isCpa = task['task_type'] == 'cpa_offer';
                        final isAd = task['task_type'] == 'ad_watch';
                        final reward = (task['reward'] as num?)?.toDouble() ?? 0;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isCpa
                                  ? const [Color(0xFFE8F8EE), Color(0xFFD7F1E1)]
                                  : isAd
                                      ? const [Color(0xFFFFF0D6), Color(0xFFFFD9A0)]
                                      : const [Color(0xFFE8F0FF), Color(0xFFD8E5FF)],
                            ),
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            leading: CircleAvatar(
                              radius: 26,
                              backgroundColor: isCpa ? Colors.green : isAd ? Colors.orange : Colors.indigo,
                              child: Icon(isCpa ? Icons.local_offer : isAd ? Icons.play_circle_fill : Icons.task_alt, color: Colors.white),
                            ),
                            title: Text(task['title']?.toString() ?? 'Task', style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(
                              isCpa
                                  ? '${task['description'] ?? ''}\nConversion: ${task['provider_conversion'] ?? 'Complete the required action'}'
                                  : (task['description'] ?? '').toString(),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('৳${reward.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                Text(done ? 'Submitted' : 'View'),
                              ],
                            ),
                            onTap: () async {
                              await Navigator.push(context, MaterialPageRoute(builder: (_) => TaskDetailsPage(task: task)));
                              await loadTasks();
                            },
                          ),
                        );
                      },
                    ),
            ),
            RefreshIndicator(
              onRefresh: loadTasks,
              child: mine.isEmpty
                  ? ListView(children: const [SizedBox(height: 180), Center(child: Text('এখনও কোনো Task submit করেননি'))])
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: mine.length,
                      itemBuilder: (context, index) {
                        final row = mine[index];
                        final status = row['status']?.toString() ?? 'pending';
                        return Card(
                          child: ListTile(
                            leading: Icon(
                              status == 'approved' ? Icons.check_circle : status == 'rejected' ? Icons.cancel : Icons.hourglass_top,
                              color: statusColor(status),
                            ),
                            title: Text((row['tasks']?['title'] ?? 'Task').toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('Points: ${row['reward_points'] ?? row['reward_amount'] ?? 0}'),
                            trailing: Chip(label: Text(status.toUpperCase())),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class CpaOffersPage extends StatefulWidget {
  const CpaOffersPage({super.key});
  @override State<CpaOffersPage> createState() => _CpaOffersPageState();
}

class _CpaOffersPageState extends State<CpaOffersPage> {
  bool loading = true;
  String? error;
  List<Map<String, dynamic>> offers = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() => loading = true);
    try {
      final uid = supabase.auth.currentUser!.id;
      final res = await supabase.functions.invoke(
        'cpalead-offers',
        body: {'subid': uid},
      );
      final data = res.data;
      if (data is Map && data['status'] == 'error') {
        throw Exception(data['message'] ?? data['error'] ?? 'CPAlead offers unavailable');
      }
      final list = data is Map ? data['offers'] : null;
      if (list is! List) throw Exception('কোনো CPA offer পাওয়া যায়নি');
      final parsed = list
          .whereType<Map>()
          .map((x) => Map<String, dynamic>.from(x))
          .toList();
      if (mounted) setState(() => offers = parsed);
    } catch (e) {
      if (mounted) setState(() => error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> openOffer(Map<String, dynamic> offer) async {
    final raw = offer['link']?.toString() ?? '';
    final uri = Uri.tryParse(raw);
    if (uri == null || !uri.hasScheme) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('অফারের লিংক পাওয়া যায়নি')),
        );
      }
      return;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('CPA Offers', style: TextStyle(fontWeight: FontWeight.bold)),
      actions: [IconButton(onPressed: load, icon: const Icon(Icons.refresh))],
    ),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: load,
            child: error != null
                ? ListView(children: [
                    const SizedBox(height: 180),
                    Center(child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text('CPAlead: $error', textAlign: TextAlign.center),
                    )),
                  ])
                : offers.isEmpty
                    ? ListView(children: const [
                        SizedBox(height: 180),
                        Center(child: Text('এই মুহূর্তে কোনো CPA offer নেই')),
                      ])
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: offers.length,
                        itemBuilder: (context, i) {
                          final o = offers[i];
                          final amount = (o['amount'] as num?)?.toDouble() ?? 0;
                          final currency = o['payout_currency']?.toString() ?? 'USD';
                          final type = o['payout_type']?.toString() ?? 'CPA';
                          final title = o['title']?.toString() ?? 'CPA Offer';
                          final desc = o['description']?.toString() ?? '';
                          final conversion = o['conversion']?.toString() ?? 'Conversion required';
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(children: [
                                    const CircleAvatar(child: Icon(Icons.local_offer)),
                                    const SizedBox(width: 12),
                                    Expanded(child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                                    Text('${amount.toStringAsFixed(2)} $currency',
                                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                                  ]),
                                  const SizedBox(height: 8),
                                  if (desc.isNotEmpty) Text(desc, maxLines: 3, overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 8),
                                  Text('কাজ: $conversion', style: const TextStyle(fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    child: FilledButton.icon(
                                      onPressed: () => openOffer(o),
                                      icon: const Icon(Icons.open_in_new),
                                      label: const Text('Offer শুরু করুন'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
  );
}

class RewardsPage extends StatefulWidget {
  const RewardsPage({super.key});
  @override State<RewardsPage> createState() => _RewardsPageState();
}

class _RewardsPageState extends State<RewardsPage> {
  bool loading = true;
  List<Map<String, dynamic>> rows = [];
  List<Map<String, dynamic>> referrals = [];
  double referralEarned = 0;
  String? referralCode;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() => loading = true);
    try {
      final uid = supabase.auth.currentUser!.id;
      final results = await Future.wait([
        supabase
            .from('task_submissions')
            .select('id,status,reward_points,reward_amount,created_at,tasks(title)')
            .eq('user_id', uid)
            .order('created_at', ascending: false),
        supabase.from('profiles').select('referral_code').eq('id', uid).single(),
        supabase
            .from('referrals')
            .select('id,referred_id,bonus_amount,status,created_at,rewarded_at')
            .eq('referrer_id', uid)
            .order('created_at', ascending: false),
        supabase
            .from('wallet_transactions')
            .select('amount')
            .eq('user_id', uid)
            .eq('type', 'referral_bonus'),
      ]);

      double income = 0;
      for (final item in (results[3] as List)) {
        income += (item['amount'] as num).toDouble();
      }

      final profileResult = results[1] as Map<String, dynamic>;
      if (mounted) {
        setState(() {
          rows = List<Map<String, dynamic>>.from(results[0] as List);
          referralCode = profileResult['referral_code']?.toString();
          referrals = List<Map<String, dynamic>>.from(results[2] as List);
          referralEarned = income;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Rewards লোড হয়নি: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  String? get referralLink {
    final code = referralCode;
    if (code == null || code.isEmpty) return null;
    return 'https://gzamivqrrflogjjvhbej.supabase.co/functions/v1/referral?ref=${Uri.encodeQueryComponent(code)}';
  }

  Future<void> copyReferralLink() async {
    final link = referralLink;
    if (link == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Referral link এখনও তৈরি হয়নি')),
      );
      return;
    }
    await Clipboard.setData(ClipboardData(text: link));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Referral link কপি হয়েছে')),
      );
    }
  }

  Future<void> shareReferral() async {
    final link = referralLink;
    final code = referralCode;
    if (link == null || code == null || code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Referral link এখনও তৈরি হয়নি')),
      );
      return;
    }
    await SharePlus.instance.share(
      ShareParams(
        title: 'Task Earn Referral',
        subject: 'Task Earn Referral',
        text: 'Task Earn-এ যোগ দিন এবং কাজ করে আয় করুন!\n\nReferral Link: $link\nReferral Code: $code',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final approved = rows
        .where((r) => r['status'] == 'approved')
        .fold<double>(
          0,
          (value, r) => value + ((r['reward_points'] ?? r['reward_amount'] as num?)?.toDouble() ?? 0),
        );

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Rewards',
          style: TextStyle(fontSize: 27, fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(onPressed: load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: load,
              child: ListView(
                padding: const EdgeInsets.all(18),
                children: [
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5F7EF),
                      borderRadius: BorderRadius.circular(26),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Total Rewards'),
                        Text(
                          '৳${approved.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const Text('Approved task rewards'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Refer & Earn',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text('আপনার Referral Link'),
                          SelectableText(
                            referralCode == null
                                ? 'লোড হচ্ছে...'
                                : 'taskearn://register?ref=$referralCode',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: copyReferralLink,
                                  icon: const Icon(Icons.copy),
                                  label: const Text('লিংক কপি'),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: FilledButton.icon(
                                  onPressed: shareReferral,
                                  icon: const Icon(Icons.share),
                                  label: const Text('শেয়ার করুন'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'শেয়ার করুন চাপলে Android-এর share menu থেকে Messenger, Telegram, WhatsAppসহ ইনস্টল করা অ্যাপ বেছে নিতে পারবেন।',
                            style: TextStyle(fontSize: 12),
                          ),
                          const Divider(height: 28),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('মোট রেফার'),
                                    Text(
                                      '${referrals.length}',
                                      style: const TextStyle(
                                        fontSize: 25,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('রেফার থেকে আয়'),
                                    Text(
                                      '৳${referralEarned.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontSize: 25,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'প্রতি সফল রেফারেলে বর্তমান বোনাস: ৳10',
                            style: TextStyle(color: Colors.grey.shade700),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Reward History',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  if (rows.isEmpty)
                    const ListTile(title: Text('এখনও কোনো reward activity নেই')),
                  if (rows.isNotEmpty)
                    ...rows.map(
                      (r) => Card(
                        child: ListTile(
                          leading: Icon(
                            r['status'] == 'approved'
                                ? Icons.card_giftcard
                                : Icons.hourglass_top,
                          ),
                          title: Text(
                            ((r['tasks'] as Map?)?['title'] ?? 'Task').toString(),
                          ),
                          subtitle: Text(r['status'].toString().toUpperCase()),
                          trailing: Text('${r['reward_points'] ?? r['reward_amount'] ?? 0} pts'),
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}

class TaskDetailsPage extends StatefulWidget{
  final Map<String,dynamic> task;
  const TaskDetailsPage({super.key,required this.task});
  @override State<TaskDetailsPage> createState()=>_TaskDetailsPageState();
}
class _TaskDetailsPageState extends State<TaskDetailsPage>{
  final proof=TextEditingController(),link=TextEditingController(); bool submitting=false,alreadySubmitted=false,checking=true,adLoading=false; List<PlatformFile> files=[]; final StartAppSdk startAppSdk=StartAppSdk(); StartAppRewardedVideoAd? rewardedAd;
  @override void initState(){super.initState();checkSubmission();if(widget.task['task_type']=='ad_watch')loadRewarded();}
  @override void dispose(){proof.dispose();link.dispose();rewardedAd?.dispose();super.dispose();}
  Future<void> checkSubmission()async{try{final uid=supabase.auth.currentUser!.id;final rows=await supabase.from('task_submissions').select('id').eq('task_id',widget.task['id']).eq('user_id',uid).limit(1);if(mounted)setState(()=>alreadySubmitted=rows.isNotEmpty);}finally{if(mounted)setState(()=>checking=false);}}
  Future<void> loadRewarded()async{if(adLoading)return;setState(()=>adLoading=true);try{await startAppSdk.setTestAdsEnabled(kDebugMode);final ad=await startAppSdk.loadRewardedVideoAd(
        prefs: const StartAppAdPreferences(adTag: 'taskearn_rewarded'),onAdNotDisplayed:(){if(mounted)setState(()=>rewardedAd=null);},onAdHidden:(){rewardedAd?.dispose();if(mounted){setState(()=>rewardedAd=null);loadRewarded();}},onVideoCompleted:(){claimAdReward();},onAdImpression:()=>debugPrint('Start.io rewarded impression received'));if(mounted)setState(()=>rewardedAd=ad);}catch(e,st){debugPrint('Start.io rewarded load failed: $e');debugPrintStack(stackTrace: st);if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('বিজ্ঞাপন লোড হয়নি: $e')));}finally{if(mounted)setState(()=>adLoading=false);}}
  Future<void> showRewarded()async{if(rewardedAd==null){await loadRewarded();}final ad=rewardedAd;if(ad==null){if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('এই মুহূর্তে বিজ্ঞাপন পাওয়া যায়নি। আবার চেষ্টা করুন।')));return;}ad.show();}
  Future<void> claimAdReward()async{try{final r=await supabase.rpc('claim_ad_task',params:{'p_task_id':widget.task['id']});if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('বিজ্ঞাপন সম্পূর্ণ। Reward ৳$r যোগ হয়েছে।')));}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Reward claim হয়নি: $e')));}}
  Future<void> openCpaOffer() async {
    try {
      final uid=supabase.auth.currentUser!.id;
      final providerId=widget.task['provider_offer_id'];
      if(providerId==null) throw Exception('CPAlead offer ID পাওয়া যায়নি');
      final res=await supabase.functions.invoke('cpalead-offers',body:{'subid':uid});
      final data=res.data;
      final list=data is Map?data['offers']:null;
      if(list is! List) throw Exception('CPAlead offer পাওয়া যায়নি');
      Map<String,dynamic>? match;
      for(final raw in list.whereType<Map>()){if(raw['id'].toString()==providerId.toString()){match=Map<String,dynamic>.from(raw);break;}}
      final raw=match?['link']?.toString()??'';
      final uri=Uri.tryParse(raw);
      if(uri==null||!uri.hasScheme) throw Exception('এই offer-এর tracking link পাওয়া যায়নি');
      await launchUrl(uri,mode:LaunchMode.externalApplication);
    }catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('CPAlead offer খোলা যায়নি: $e')));}
  }

  Future<void> pickFiles()async{final r=await FilePicker.platform.pickFiles(allowMultiple:true,withData:true,type:FileType.custom,allowedExtensions:['jpg','jpeg','png','webp','pdf','txt']);if(r!=null&&mounted)setState(()=>files=r.files);}
  Future<void> submit()async{
    final types=List<String>.from((widget.task['proof_types'] as List?) ?? const ['text']);
    if(types.isEmpty){types.add('text');}
    if(types.contains('text')&&proof.text.trim().isEmpty){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Text / Code proof দিন')));return;}
    if(types.contains('link')&&link.text.trim().isEmpty){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Proof Link / URL দিন')));return;}
    if((types.contains('photo')||types.contains('file'))&&files.isEmpty){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('প্রয়োজনীয় Photo / File নির্বাচন করুন')));return;}
    if(types.contains('photo')&&!files.any((f)=>['jpg','jpeg','png','webp'].contains((f.extension??'').toLowerCase()))){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Photo proof-এর জন্য JPG, PNG বা WEBP ছবি দিন')));return;}
    setState(()=>submitting=true);
    try{
      final uid=supabase.auth.currentUser!.id;final uploaded=<String>[];
      for(final f in files){if(f.bytes==null)continue;final safe=f.name.replaceAll(RegExp(r'[^A-Za-z0-9._-]'),'_');final path='$uid/${widget.task['id']}/${DateTime.now().microsecondsSinceEpoch}_$safe';await supabase.storage.from('task-proofs').uploadBinary(path,f.bytes!,fileOptions:const FileOptions(upsert:false));uploaded.add(path);}
      await supabase.rpc('submit_task_with_proofs',params:{'p_task_id':widget.task['id'],'p_proof':proof.text.trim(),'p_proof_link':link.text.trim(),'p_proof_files':uploaded});
      if(mounted){setState(()=>alreadySubmitted=true);ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('সব Proof সহ Task জমা হয়েছে।')));}
    }catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Submit হয়নি: $e')));}finally{if(mounted)setState(()=>submitting=false);}
  }
  @override Widget build(BuildContext context){final t=widget.task;final reward=(t['reward'] as num?)?.toDouble()??0;return Scaffold(appBar:AppBar(title:const Text('Task Details')),body:ListView(padding:const EdgeInsets.all(20),children:[
    Text(t['title']??'Task',style:const TextStyle(fontSize:25,fontWeight:FontWeight.bold)),const SizedBox(height:12),
    Card(child:ListTile(leading:const Icon(Icons.payments),title:const Text('Reward'),subtitle:Text('${reward.toStringAsFixed(2)} pts',style:const TextStyle(fontSize:20,fontWeight:FontWeight.bold)))),
    const SizedBox(height:16),const Text('Task instructions',style:TextStyle(fontSize:18,fontWeight:FontWeight.bold)),Text(t['description']??'No instructions provided.'),const SizedBox(height:18),
    Container(padding:const EdgeInsets.all(14),decoration:BoxDecoration(color:const Color(0xFFF1F5FF),borderRadius:BorderRadius.circular(16)),child:Row(children:[Icon(t['task_type']=='ad_watch'?Icons.ondemand_video:Icons.task_alt,color:Colors.indigo),const SizedBox(width:10),Expanded(child:Text(t['task_type']=='ad_watch'?'বিজ্ঞাপনটি সম্পূর্ণ দেখুন, তারপর এই পেইজে ফিরে Reward Claim করুন.':t['task_type']=='cpa_offer'?'CPAlead-এর tracking link দিয়ে offer শুরু করুন, কাজ শেষ হলে এখানে ফিরে Proof Submit করুন।':'নিচের বাটনে চাপলে কাজ সম্পন্ন করার পেইজ খুলবে। কাজ শেষ করে এখানে ফিরে Proof Submit করুন.'))])),const SizedBox(height:14),
    if((!alreadySubmitted||t['task_type']=='ad_watch')&&!checking)FilledButton.icon(onPressed:()async{if(t['task_type']=='ad_watch'){await showRewarded();return;}if(t['task_type']=='cpa_offer'){await openCpaOffer();return;}final raw=t['target_url']?.toString()??'';if(raw.isEmpty){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('এই Task-এর কাজের Link এখনও যোগ করা হয়নি')));return;}final uri=Uri.tryParse(raw);if(uri!=null)launchUrl(uri,mode:LaunchMode.externalApplication);},icon:Icon(t['task_type']=='ad_watch'?Icons.play_arrow:Icons.open_in_new),label:Text(t['task_type']=='ad_watch'?(adLoading?'বিজ্ঞাপন লোড হচ্ছে...':'বিজ্ঞাপন দেখুন'):t['task_type']=='cpa_offer'?'CPAlead Offer শুরু করুন':'টাস্ক সম্পন্ন করুন')),
    const SizedBox(height:24),
    if(checking)const Center(child:CircularProgressIndicator())else if(alreadySubmitted&&t['task_type']!='ad_watch')const Card(child:ListTile(leading:Icon(Icons.check_circle),title:Text('My Tasks-এ চলে গেছে'),subtitle:Text('এই Task আবার Claim করা যাবে না।')))else if(t['task_type']!='ad_watch') ...[
      const Text('Required Proof',style:TextStyle(fontSize:18,fontWeight:FontWeight.bold)),const SizedBox(height:8),
      Builder(builder:(context){
        final types=List<String>.from((t['proof_types'] as List?) ?? const ['text']);
        if(types.isEmpty)types.add('text');
        return Column(children:[
          if(types.contains('text'))TextField(controller:proof,maxLines:4,decoration:const InputDecoration(labelText:'Text / Code / বিস্তারিত Proof',border:OutlineInputBorder())),
          if(types.contains('text'))const SizedBox(height:10),
          if(types.contains('link'))TextField(controller:link,keyboardType:TextInputType.url,decoration:const InputDecoration(labelText:'Proof Link / URL',prefixIcon:Icon(Icons.link),border:OutlineInputBorder())),
          if(types.contains('link'))const SizedBox(height:10),
          if(types.contains('photo')||types.contains('file'))OutlinedButton.icon(onPressed:submitting?null:pickFiles,icon:const Icon(Icons.attach_file),label:Text(files.isEmpty?'Photo / File নির্বাচন করুন':'${files.length}টি File নির্বাচিত')),
          if(files.isNotEmpty)...files.map((f)=>ListTile(dense:true,leading:Icon((f.extension??'').toLowerCase()=='pdf'?Icons.picture_as_pdf:Icons.image_outlined),title:Text(f.name),trailing:IconButton(icon:const Icon(Icons.close),onPressed:()=>setState(()=>files.remove(f))))),
        ]);
      }),
      const SizedBox(height:14),FilledButton.icon(onPressed:submitting?null:submit,icon:const Icon(Icons.cloud_upload),label:Text(submitting?'Upload হচ্ছে...':'সব Proof Submit করুন')),
    ]
  ]));}
}

class WalletPage extends StatefulWidget{
 const WalletPage({super.key});
 @override State<WalletPage> createState()=>_WalletPageState();
}
class _WalletPageState extends State<WalletPage>{
 bool loading=true;
 double balance=0,points=0,rate=100,minPoints=1000;
 List<Map<String,dynamic>> tx=[],withdrawals=[];
 Map<String,dynamic>? payout;
 @override void initState(){super.initState();load();}
 Future<void> load()async{
  setState(()=>loading=true);
  try{
   final uid=supabase.auth.currentUser!.id;
   final r=await Future.wait([
    supabase.from('profiles').select('money_balance,points_balance').eq('id',uid).single(),
    supabase.from('point_settings').select('points_per_bdt,min_convert_points').eq('id',1).maybeSingle(),
    supabase.from('wallet_transactions').select('id,amount,points,type,description,created_at').eq('user_id',uid).order('created_at',ascending:false),
    supabase.from('withdrawal_requests').select('id,amount,method,account_number,status,created_at').eq('user_id',uid).order('created_at',ascending:false),
    supabase.from('user_payout_accounts').select().eq('user_id',uid).maybeSingle(),
   ]);
   final p=r[0] as Map<String,dynamic>; final st=r[1] as Map<String,dynamic>?;
   if(mounted)setState((){
    balance=((p['money_balance']??0) as num).toDouble();
    points=((p['points_balance']??0) as num).toDouble();
    rate=((st?['points_per_bdt']??100) as num).toDouble();
    minPoints=((st?['min_convert_points']??1000) as num).toDouble();
    tx=List<Map<String,dynamic>>.from(r[2] as List);
    withdrawals=List<Map<String,dynamic>>.from(r[3] as List);
    payout=r[4] as Map<String,dynamic>?;
   });
  }catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Wallet লোড হয়নি: $e')));}
  finally{if(mounted)setState(()=>loading=false);}
 }
 Future<void> convertPoints()async{
  final c=TextEditingController();
  final ok=await showDialog<bool>(context:context,builder:(ctx)=>AlertDialog(
   title:const Text('Points → টাকা'),
   content:Column(mainAxisSize:MainAxisSize.min,children:[
    Text('বর্তমান: '+points.toStringAsFixed(2)+' Points'),
    Text('Rate: '+rate.toStringAsFixed(2)+' Points = ৳1'),
    Text('Minimum: '+minPoints.toStringAsFixed(2)+' Points'),
    const SizedBox(height:12),
    TextField(controller:c,keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:const InputDecoration(labelText:'কত Points convert করবেন?',border:OutlineInputBorder())),
   ]),
   actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('Cancel')),FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('Convert'))],
  ));
  if(ok!=true){c.dispose();return;}
  final n=double.tryParse(c.text.trim());c.dispose();
  if(n==null||n<=0)return;
  try{await supabase.rpc('convert_points',params:{'p_points':n});if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(n.toStringAsFixed(2)+' Points টাকায় convert হয়েছে')));await load();}
  catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Conversion হয়নি: $e')));}
 }
 Future<void> addPayout()async{
  String method='bkash';final acc=TextEditingController(),name=TextEditingController(),bank=TextEditingController();
  final ok=await showDialog<bool>(context:context,builder:(c)=>StatefulBuilder(builder:(c,setD)=>AlertDialog(
   title:const Text('উত্তোলন অ্যাকাউন্ট যুক্ত করুন'),
   content:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[
    const Text('এই অ্যাকাউন্টটি অন্য কোনো Task Earn ইউজার ব্যবহার করতে পারবে না।'),
    DropdownButtonFormField<String>(initialValue:method,items:const[DropdownMenuItem(value:'bkash',child:Text('bKash')),DropdownMenuItem(value:'nagad',child:Text('Nagad')),DropdownMenuItem(value:'bank',child:Text('Bank'))],onChanged:(v)=>setD(()=>method=v??'bkash')),
    TextField(controller:acc,decoration:const InputDecoration(labelText:'Account number')),
    TextField(controller:name,decoration:const InputDecoration(labelText:'Account holder name')),
    if(method=='bank')TextField(controller:bank,decoration:const InputDecoration(labelText:'Bank name')),
   ])),
   actions:[TextButton(onPressed:()=>Navigator.pop(c,false),child:const Text('Cancel')),FilledButton(onPressed:()=>Navigator.pop(c,true),child:const Text('Save'))],
  )));
  if(ok!=true||acc.text.trim().isEmpty)return;
  try{await supabase.from('user_payout_accounts').insert({'user_id':supabase.auth.currentUser!.id,'method':method,'account_number':acc.text.trim(),'account_name':name.text.trim(),'bank_name':bank.text.trim()});await load();}
  catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('অ্যাকাউন্ট যোগ হয়নি। $e')));}
 }
 Future<void> withdraw(double amount)async{try{await supabase.rpc('request_fixed_withdrawal',params:{'p_amount':amount});if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('৳'+amount.toStringAsFixed(0)+' উত্তোলন অনুরোধ জমা হয়েছে')));await load();}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString())));}}
 Widget pack(double amount)=>Expanded(child:Padding(padding:const EdgeInsets.all(4),child:FilledButton.tonal(onPressed:payout!=null&&balance>=amount?()=>withdraw(amount):null,child:Padding(padding:const EdgeInsets.symmetric(vertical:18),child:Text('৳'+amount.toStringAsFixed(0),style:const TextStyle(fontSize:20,fontWeight:FontWeight.bold))))));
 @override Widget build(BuildContext context){
  if(loading)return const Scaffold(body:Center(child:CircularProgressIndicator()));
  return Scaffold(
   appBar:AppBar(title:const Text('Wallet',style:TextStyle(fontSize:27,fontWeight:FontWeight.w800)),actions:[IconButton(onPressed:load,icon:const Icon(Icons.refresh))]),
   body:RefreshIndicator(onRefresh:load,child:ListView(padding:const EdgeInsets.all(16),children:[
    Container(padding:const EdgeInsets.all(22),decoration:BoxDecoration(gradient:const LinearGradient(colors:[Color(0xFF7C3AED),Color(0xFFEC4899)]),borderRadius:BorderRadius.circular(24)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('Wallet Balance',style:TextStyle(color:Colors.white70)),Text('৳'+balance.toStringAsFixed(2),style:const TextStyle(color:Colors.white,fontSize:34,fontWeight:FontWeight.bold)),const SizedBox(height:6),Text(points.toStringAsFixed(2)+' Points',style:const TextStyle(color:Colors.white,fontSize:18,fontWeight:FontWeight.w700))])),
    const SizedBox(height:14),
    Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('Points Conversion',style:TextStyle(fontSize:20,fontWeight:FontWeight.bold)),const SizedBox(height:6),Text(rate.toStringAsFixed(2)+' Points = ৳1 • Minimum '+minPoints.toStringAsFixed(2)+' Points'),const SizedBox(height:12),FilledButton.icon(onPressed:points>=minPoints?convertPoints:null,icon:const Icon(Icons.currency_exchange),label:const Text('Points থেকে টাকায় Convert করুন'))]))),
    const SizedBox(height:16),const Text('উত্তোলন অ্যাকাউন্ট',style:TextStyle(fontSize:20,fontWeight:FontWeight.bold)),
    payout==null?Card(child:ListTile(leading:const Icon(Icons.account_balance_wallet_outlined),title:const Text('প্রথম উত্তোলনের আগে অ্যাকাউন্ট যুক্ত করুন'),subtitle:const Text('একটি payout account শুধু একজন ইউজার ব্যবহার করতে পারবেন।'),trailing:FilledButton(onPressed:addPayout,child:const Text('যুক্ত করুন')))):Card(child:ListTile(leading:const Icon(Icons.verified),title:Text(payout!['method'].toString().toUpperCase()+' • '+payout!['account_number'].toString()),subtitle:Text(payout!['account_name']?.toString()??''),trailing:const Chip(label:Text('Linked')))),
    const SizedBox(height:16),const Text('উত্তোলন প্যাকেজ',style:TextStyle(fontSize:20,fontWeight:FontWeight.bold)),const SizedBox(height:8),Row(children:[pack(200),pack(300),pack(500)]),const Padding(padding:EdgeInsets.symmetric(vertical:8),child:Text('শুধু ৳২০০, ৳৩০০ অথবা ৳৫০০ প্যাকেজে উত্তোলন করা যাবে।',style:TextStyle(fontSize:12))),
    const Divider(height:28),const Text('Transactions',style:TextStyle(fontSize:18,fontWeight:FontWeight.bold)),
    if(tx.isEmpty)const ListTile(title:Text('কোনো transaction নেই')),
    ...tx.map((r){final amount=((r['amount']??0) as num).toDouble();final pts=((r['points']??0) as num).toDouble();final title=r['description']?.toString().isNotEmpty==true?r['description'].toString():r['type'].toString();return ListTile(leading:Icon(pts!=0?Icons.stars:amount>=0?Icons.add_circle_outline:Icons.remove_circle_outline),title:Text(title),trailing:Column(mainAxisAlignment:MainAxisAlignment.center,crossAxisAlignment:CrossAxisAlignment.end,children:[if(pts!=0)Text((pts>=0?'+':'')+pts.toStringAsFixed(2)+' pts'),if(amount!=0)Text((amount>=0?'+':'')+'৳'+amount.toStringAsFixed(2))]));}),
    if(withdrawals.isNotEmpty)...[const Divider(),const Text('Withdrawal requests',style:TextStyle(fontSize:18,fontWeight:FontWeight.bold)),...withdrawals.map((w){final amount=(w['amount'] as num).toDouble();return ListTile(title:Text(w['method'].toString().toUpperCase()+' • ৳'+amount.toStringAsFixed(2)),subtitle:Text(w['account_number'].toString()),trailing:Text(w['status'].toString()));})],
   ])),
  );
 }
}
class AdminPage extends StatefulWidget{const AdminPage({super.key});@override State<AdminPage> createState()=>_AdminPageState();}
class _AdminPageState extends State<AdminPage>{
 bool loading=true;List<Map<String,dynamic>> submissions=[],withdrawals=[],tasks=[],content=[];Map<String,dynamic>? support;
 @override void initState(){super.initState();load();}
 Future<void> load()async{setState(()=>loading=true);try{final r=await Future.wait([supabase.from('task_submissions').select('id,task_id,user_id,proof,status,reward_amount,tasks(title),profiles(full_name,phone)').order('created_at',ascending:false),supabase.from('withdrawal_requests').select('id,user_id,amount,method,account_number,status,profiles(full_name,phone)').order('created_at',ascending:false),supabase.from('tasks').select('id,title,reward,is_active').order('created_at',ascending:false),supabase.from('app_content').select().order('sort_order'),supabase.from('support_settings').select().eq('id',1).maybeSingle()]);if(mounted)setState((){submissions=List<Map<String,dynamic>>.from(r[0] as List);withdrawals=List<Map<String,dynamic>>.from(r[1] as List);tasks=List<Map<String,dynamic>>.from(r[2] as List);content=List<Map<String,dynamic>>.from(r[3] as List);support=r[4] as Map<String,dynamic>?;});}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString())));}finally{if(mounted)setState(()=>loading=false);}}
 Future<void> reviewTask(Map<String,dynamic>x,bool ok)async{try{await supabase.rpc(ok?'approve_task_submission':'reject_task_submission',params:{'p_submission_id':x['id'],'p_note':''});await load();}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString())));}}
 Future<void> reviewWithdrawal(Map<String,dynamic>x,bool ok)async{try{await supabase.rpc('review_withdrawal',params:{'p_withdrawal_id':x['id'],'p_approve':ok,'p_note':''});await load();}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString())));}}
 Future<void> addTask()async{final title=TextEditingController(),desc=TextEditingController(),reward=TextEditingController();final ok=await showDialog<bool>(context:context,builder:(c)=>AlertDialog(title:const Text('Create Task'),content:Column(mainAxisSize:MainAxisSize.min,children:[TextField(controller:title,decoration:const InputDecoration(labelText:'Title')),TextField(controller:desc,decoration:const InputDecoration(labelText:'Description')),TextField(controller:reward,decoration:const InputDecoration(labelText:'Reward'))]),actions:[TextButton(onPressed:()=>Navigator.pop(c,false),child:const Text('Cancel')),FilledButton(onPressed:()=>Navigator.pop(c,true),child:const Text('Create'))]));if(ok!=true)return;final r=double.tryParse(reward.text);if(title.text.trim().isEmpty||r==null)return;await supabase.from('tasks').insert({'title':title.text.trim(),'description':desc.text.trim(),'reward':r});await load();}
 @override Widget build(BuildContext context){final ps=submissions.where((x)=>x['status']=='pending').length,pw=withdrawals.where((x)=>x['status']=='pending').length;return Scaffold(appBar:AppBar(title:const Text('Admin Panel'),actions:[IconButton(onPressed:load,icon:const Icon(Icons.refresh))]),body:loading?const Center(child:CircularProgressIndicator()):DefaultTabController(length:5,child:Column(children:[Padding(padding:const EdgeInsets.all(8),child:Text('Pending tasks: '+ps.toString()+'   •   Pending withdrawals: '+pw.toString())),const TabBar(isScrollable:true,tabs:[Tab(text:'Submissions'),Tab(text:'Withdrawals'),Tab(text:'Tasks'),Tab(text:'Content'),Tab(text:'Support')]),Expanded(child:TabBarView(children:[_subs(),_withdrawals(),_tasks(),_content(),_support()]))])));}
 Widget _subs()=>ListView.builder(itemCount:submissions.length,itemBuilder:(c,i){final x=submissions[i],st=x['status'].toString(),p=x['profiles'] as Map<String,dynamic>?;return Card(child:ListTile(title:Text((x['tasks']?['title']??'Task').toString()),subtitle:Text((p?['full_name']??'User').toString()+' • '+st),trailing:st=='pending'?Row(mainAxisSize:MainAxisSize.min,children:[IconButton(onPressed:()=>reviewTask(x,false),icon:const Icon(Icons.close)),IconButton(onPressed:()=>reviewTask(x,true),icon:const Icon(Icons.check))]):Text(st)));});
 Widget _withdrawals()=>ListView.builder(itemCount:withdrawals.length,itemBuilder:(c,i){final x=withdrawals[i],st=x['status'].toString(),p=x['profiles'] as Map<String,dynamic>?;return Card(child:ListTile(title:Text(x['method'].toString().toUpperCase()+' • ৳'+x['amount'].toString()),subtitle:Text((p?['full_name']??'User').toString()+' • '+x['account_number'].toString()),trailing:st=='pending'?Row(mainAxisSize:MainAxisSize.min,children:[IconButton(onPressed:()=>reviewWithdrawal(x,false),icon:const Icon(Icons.close)),IconButton(onPressed:()=>reviewWithdrawal(x,true),icon:const Icon(Icons.check))]):Text(st)));});
 Widget _tasks()=>ListView(padding:const EdgeInsets.all(12),children:[FilledButton.icon(onPressed:addTask,icon:const Icon(Icons.add),label:const Text('Create New Task')),...tasks.map((x)=>Card(child:ListTile(title:Text(x['title'].toString()),subtitle:Text('Reward ৳'+x['reward'].toString()))))]);
 Future<void> addContent() async {String type='banner';final title=TextEditingController(),body=TextEditingController(),image=TextEditingController(),target=TextEditingController();final ok=await showDialog<bool>(context:context,builder:(c)=>StatefulBuilder(builder:(c,setD)=>AlertDialog(title:const Text('Banner / Rule যোগ করুন'),content:Column(mainAxisSize:MainAxisSize.min,children:[DropdownButtonFormField<String>(initialValue:type,items:const[DropdownMenuItem(value:'banner',child:Text('Banner')),DropdownMenuItem(value:'rule',child:Text('Rule'))],onChanged:(v)=>setD(()=>type=v??'banner')),TextField(controller:title,decoration:const InputDecoration(labelText:'Title')),TextField(controller:body,maxLines:3,decoration:const InputDecoration(labelText:'Text')),TextField(controller:image,decoration:const InputDecoration(labelText:'Banner image URL (optional)')),TextField(controller:target,decoration:const InputDecoration(labelText:'Ad / target URL (optional)'))]),actions:[TextButton(onPressed:()=>Navigator.pop(c,false),child:const Text('Cancel')),FilledButton(onPressed:()=>Navigator.pop(c,true),child:const Text('Save'))])));if(ok==true&&title.text.trim().isNotEmpty){await supabase.from('app_content').insert({'content_type':type,'title':title.text.trim(),'body':body.text.trim(),'image_url':image.text.trim().isEmpty?null:image.text.trim(),'target_url':target.text.trim().isEmpty?null:target.text.trim()});await load();}}
 Future<void> toggleContent(Map<String,dynamic>x,bool v)async{await supabase.from('app_content').update({'is_active':v,'updated_at':DateTime.now().toIso8601String()}).eq('id',x['id']);await load();}
 Future<void> deleteContent(dynamic id)async{await supabase.from('app_content').delete().eq('id',id);await load();}
 Widget _content()=>ListView(padding:const EdgeInsets.all(12),children:[FilledButton.icon(onPressed:addContent,icon:const Icon(Icons.add_photo_alternate),label:const Text('Banner / Rule যোগ করুন')),...content.map((x)=>Card(child:ListTile(leading:Icon(x['content_type']=='banner'?Icons.image_outlined:Icons.rule),title:Text(x['title'].toString()),subtitle:Text(x['content_type'].toString()),trailing:Row(mainAxisSize:MainAxisSize.min,children:[Switch(value:x['is_active']==true,onChanged:(v)=>toggleContent(x,v)),IconButton(onPressed:()=>deleteContent(x['id']),icon:const Icon(Icons.delete_outline))]))))]);
 Future<void> editSupport()async{final ch=TextEditingController(text:support?['telegram_channel_url']?.toString()??''),ac=TextEditingController(text:support?['telegram_account']?.toString()??''),msg=TextEditingController(text:support?['support_message']?.toString()??'');final ok=await showDialog<bool>(context:context,builder:(c)=>AlertDialog(title:const Text('Customer Care Settings'),content:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[TextField(controller:ch,decoration:const InputDecoration(labelText:'Telegram Channel URL')),TextField(controller:ac,decoration:const InputDecoration(labelText:'Telegram Account (@username)')),TextField(controller:msg,maxLines:3,decoration:const InputDecoration(labelText:'Support message'))])),actions:[TextButton(onPressed:()=>Navigator.pop(c,false),child:const Text('Cancel')),FilledButton(onPressed:()=>Navigator.pop(c,true),child:const Text('Save'))]));if(ok==true){await supabase.from('support_settings').upsert({'id':1,'telegram_channel_url':ch.text.trim(),'telegram_account':ac.text.trim(),'support_message':msg.text.trim(),'updated_at':DateTime.now().toIso8601String()});await load();}}
 Widget _support()=>ListView(padding:const EdgeInsets.all(16),children:[Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('Telegram Customer Care',style:TextStyle(fontSize:20,fontWeight:FontWeight.bold)),const SizedBox(height:12),Text('Channel: ${support?['telegram_channel_url']??'Not set'}'),Text('Account: ${support?['telegram_account']??'Not set'}'),const SizedBox(height:12),FilledButton.icon(onPressed:editSupport,icon:const Icon(Icons.edit),label:const Text('Edit Settings'))])))]);
}

class ProfilePage extends StatefulWidget{
  const ProfilePage({super.key});
  @override State<ProfilePage> createState()=>_ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>{
  bool loading=true;
  bool isAdmin=false;

  @override
  void initState(){
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final uid=supabase.auth.currentUser!.id;
      final r=await supabase.from('profiles').select('phone,role').eq('id',uid).single();
      if(mounted) setState(()=>isAdmin=r['role']=='admin');
    } catch (_) {
      // Keep the normal profile view when the profile lookup is unavailable.
    } finally {
      if(mounted) setState(()=>loading=false);
    }
  }

  Future<void> logout(BuildContext context) async {
    await supabase.auth.signOut();
    if(context.mounted){
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder:(_)=>const LoginPage()),
        (_)=>false,
      );
    }
  }

  @override
  Widget build(BuildContext context){
    final user=supabase.auth.currentUser;
    final phone=user?.userMetadata?['phone']?.toString() ?? 'User';
    return Scaffold(
      appBar:AppBar(
        title:const Text('Profile',style:TextStyle(fontSize:27,fontWeight:FontWeight.w800)),
        actions:[IconButton(onPressed:load,icon:const Icon(Icons.refresh))],
      ),
      body:ListView(
        children:[
          const SizedBox(height:8),
          ListTile(
            leading:const CircleAvatar(child:Icon(Icons.person)),
            title:Text(user?.userMetadata?['full_name']?.toString() ?? 'Task Earn User'),
            subtitle:Text(phone),
          ),
          const Divider(),
          FutureBuilder<Map<String,dynamic>?>(future:supabase.from('support_settings').select().eq('id',1).maybeSingle(),builder:(context,snap){final x=snap.data;if(x==null)return const SizedBox.shrink();final channel=(x['telegram_channel_url']??'').toString(),account=(x['telegram_account']??'').toString();return Card(margin:const EdgeInsets.fromLTRB(16,8,16,8),child:Column(children:[const ListTile(leading:Icon(Icons.support_agent),title:Text('Customer Support'),subtitle:Text('Telegram-এর মাধ্যমে সহায়তা নিন')),if(channel.isNotEmpty)ListTile(leading:const Icon(Icons.campaign_outlined),title:const Text('Telegram Channel'),trailing:const Icon(Icons.open_in_new),onTap:()=>launchUrl(Uri.parse(channel),mode:LaunchMode.externalApplication)),if(account.isNotEmpty)ListTile(leading:const Icon(Icons.telegram),title:Text(account),subtitle:Text((x['support_message']??'').toString()),trailing:const Icon(Icons.chat_outlined),onTap:()=>launchUrl(Uri.parse('https://t.me/${account.replaceAll('@','')}'),mode:LaunchMode.externalApplication))]));}),
          FutureBuilder<Map<String,dynamic>?>(future:supabase.from('profiles').select('referral_code,referred_by').eq('id',user!.id).maybeSingle(),builder:(context,snap){final p=snap.data;return Card(margin:const EdgeInsets.all(16),child:ListTile(leading:const Icon(Icons.people_alt_outlined),title:const Text('Refer & Earn'),subtitle:Text('আপনার Referral Code: ${p?['referral_code']??'...'}\nবন্ধুকে এই কোড দিলে সে আপনার রেফারেল হিসেবে যুক্ত হবে।'),));}),
          if(!loading && isAdmin)
            ListTile(
              leading:const Icon(Icons.admin_panel_settings),
              title:const Text('Admin Panel'),
              subtitle:const Text('Tasks, submissions ও withdrawals পরিচালনা'),
              onTap:()=>Navigator.push(
                context,
                MaterialPageRoute(builder:(_)=>const AdminPage()),
              ),
            ),
          ListTile(
            leading:const Icon(Icons.logout),
            title:const Text('Logout'),
            onTap:()=>logout(context),
          ),
        ],
      ),
    );
  }
}
