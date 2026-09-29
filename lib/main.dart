import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:app_links/app_links.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

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
  runApp(const TaskEarnApp());
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
      colorScheme:ColorScheme.fromSeed(seedColor:const Color(0xFF2255D9),brightness:Brightness.light),
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

class Shell extends StatefulWidget{
  const Shell({super.key});
  @override State<Shell> createState()=>_ShellState();
}
class _ShellState extends State<Shell>{
  int index=0;
  final pages=const[HomePage(),TasksPage(),RewardsPage(),WalletPage(),ProfilePage()];
  @override Widget build(BuildContext context)=>Scaffold(body:IndexedStack(index:index,children:pages),bottomNavigationBar:NavigationBar(
    height:72,selectedIndex:index,onDestinationSelected:(i)=>setState(()=>index=i),
    destinations:const[
      NavigationDestination(icon:Icon(Icons.home_outlined),selectedIcon:Icon(Icons.home),label:'Home'),
      NavigationDestination(icon:Icon(Icons.credit_card_outlined),selectedIcon:Icon(Icons.credit_card),label:'Earn'),
      NavigationDestination(icon:Icon(Icons.card_giftcard),selectedIcon:Icon(Icons.redeem),label:'Rewards'),
      NavigationDestination(icon:Icon(Icons.account_balance_wallet_outlined),selectedIcon:Icon(Icons.account_balance_wallet),label:'Wallet'),
      NavigationDestination(icon:Icon(Icons.person_outline),selectedIcon:Icon(Icons.person),label:'Mine'),
    ]));
}

class HomePage extends StatefulWidget{const HomePage({super.key});@override State<HomePage> createState()=>_HomePageState();}
class _HomePageState extends State<HomePage>{
 bool loading=true;double balance=0,earned=0;int available=0,pending=0,approved=0;List<Map<String,dynamic>> banners=[],rules=[];Map<String,dynamic>? support;
 @override void initState(){super.initState();load();}
 Future<void> load()async{setState(()=>loading=true);try{final uid=supabase.auth.currentUser!.id;final r=await Future.wait([supabase.from('wallet_transactions').select('amount,type').eq('user_id',uid),supabase.from('tasks').select('id').eq('is_active',true),supabase.from('task_submissions').select('status,task_id').eq('user_id',uid),supabase.from('app_content').select().eq('is_active',true).order('sort_order'),supabase.from('support_settings').select().eq('id',1).maybeSingle()]);double b=0,en=0;for(final x in r[0] as List){final a=(x['amount'] as num).toDouble();b+=a;if(x['type']=='task_reward')en+=a;}int p=0,ap=0;final submitted=<dynamic>{};for(final x in r[2] as List){submitted.add(x['task_id']);if(x['status']=='pending')p++;if(x['status']=='approved')ap++;}final open=(r[1] as List).where((x)=>!submitted.contains(x['id'])).length;if(mounted)setState((){balance=b;earned=en;available=open;pending=p;approved=ap;banners=List<Map<String,dynamic>>.from((r[3] as List).where((x)=>x['content_type']=='banner'));rules=List<Map<String,dynamic>>.from((r[3] as List).where((x)=>x['content_type']=='rule'));support=r[4] as Map<String,dynamic>?;});}catch(err){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Dashboard লোড হয়নি: $err')));}finally{if(mounted)setState(()=>loading=false);}}
 Widget stat(IconData i,String t,String v)=>Expanded(child:Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Icon(i),const SizedBox(height:8),Text(v,style:const TextStyle(fontSize:22,fontWeight:FontWeight.bold)),Text(t,style:const TextStyle(fontSize:12))]))));
 @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('Home',style:TextStyle(fontSize:27,fontWeight:FontWeight.w800)),actions:[IconButton(onPressed:load,icon:const Icon(Icons.headset_mic_outlined))]),body:RefreshIndicator(onRefresh:load,child:ListView(padding:const EdgeInsets.all(16),children:[
 Card(child:Padding(padding:const EdgeInsets.all(22),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('Available Balance'),Text(loading?'...':'৳${balance.toStringAsFixed(2)}',style:const TextStyle(fontSize:34,fontWeight:FontWeight.w800)),Text('Total earned: ৳${earned.toStringAsFixed(2)}')]))),
 Row(children:[stat(Icons.task_alt,'Available','$available'),const SizedBox(width:8),stat(Icons.hourglass_top,'Pending','$pending')]),Row(children:[stat(Icons.verified_outlined,'Approved','$approved'),const SizedBox(width:8),stat(Icons.account_balance_wallet_outlined,'Wallet','৳${balance.toStringAsFixed(0)}')]),
 const SizedBox(height:16),
 if(banners.isNotEmpty)...[const Text('ঘোষণা',style:TextStyle(fontSize:20,fontWeight:FontWeight.w800)),const SizedBox(height:8),...banners.map((b)=>Container(margin:const EdgeInsets.only(bottom:10),padding:const EdgeInsets.all(18),decoration:BoxDecoration(gradient:const LinearGradient(colors:[Color(0xFF2255D9),Color(0xFF6B35E8)]),borderRadius:BorderRadius.circular(20)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(b['title'].toString(),style:const TextStyle(color:Colors.white,fontSize:20,fontWeight:FontWeight.bold)),if((b['body']??'').toString().isNotEmpty)Text(b['body'].toString(),style:const TextStyle(color:Colors.white))]))),],
 if(rules.isNotEmpty)...[const SizedBox(height:10),const Text('নিয়মাবলী',style:TextStyle(fontSize:20,fontWeight:FontWeight.w800)),Card(child:Column(children:rules.map((x)=>ListTile(leading:const Icon(Icons.verified_outlined,color:Color(0xFF2255D9)),title:Text(x['title'].toString()),subtitle:(x['body']??'').toString().isEmpty?null:Text(x['body'].toString()))).toList()))],
 if(support!=null)...[const SizedBox(height:10),const Text('কাস্টমার কেয়ার',style:TextStyle(fontSize:20,fontWeight:FontWeight.w800)),Card(child:Column(children:[if((support?['telegram_channel_url']??'').toString().isNotEmpty)ListTile(leading:const Icon(Icons.campaign),title:const Text('Telegram Channel'),trailing:const Icon(Icons.open_in_new),onTap:()=>launchUrl(Uri.parse(support!['telegram_channel_url'].toString()),mode:LaunchMode.externalApplication)),if((support?['telegram_account']??'').toString().isNotEmpty)ListTile(leading:const Icon(Icons.support_agent),title:Text(support!['telegram_account'].toString()),subtitle:Text(support?['support_message']?.toString()??''),onTap:(){final a=support!['telegram_account'].toString().replaceAll('@','');launchUrl(Uri.parse('https://t.me/$a'),mode:LaunchMode.externalApplication);})]))],
 const SizedBox(height:20),const Text('Tutorials',style:TextStyle(fontSize:22,fontWeight:FontWeight.w800)),const Card(child:Column(children:[ListTile(leading:CircleAvatar(child:Text('1')),title:Text('Task বেছে নিন')),Divider(height:1),ListTile(leading:CircleAvatar(child:Text('2')),title:Text('কাজ শেষ করে Proof জমা দিন')),Divider(height:1),ListTile(leading:CircleAvatar(child:Text('3')),title:Text('Approve হলে Reward Wallet-এ পাবেন'))]))
 ])));
}

class TasksPage extends StatefulWidget{const TasksPage({super.key});@override State<TasksPage> createState()=>_TasksPageState();}
class _TasksPageState extends State<TasksPage>{
 bool loading=true;List<Map<String,dynamic>> tasks=[],mine=[];
 @override void initState(){super.initState();loadTasks();}
 Future<void> loadTasks()async{setState(()=>loading=true);try{final uid=supabase.auth.currentUser!.id;final r=await Future.wait([supabase.from('tasks').select('id,title,description,reward,max_submissions').eq('is_active',true).order('created_at',ascending:false),supabase.from('task_submissions').select('id,task_id,status,reward_amount,created_at,tasks(title)').eq('user_id',uid).order('created_at',ascending:false)]);if(mounted)setState((){tasks=List<Map<String,dynamic>>.from(r[0]);mine=List<Map<String,dynamic>>.from(r[1]);});}catch(x){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Task লোড হয়নি: $x')));}finally{if(mounted)setState(()=>loading=false);}}
 Color sc(String s)=>s=='approved'?Colors.green:s=='rejected'?Colors.red:Colors.orange;
 @override Widget build(BuildContext context)=>DefaultTabController(length:2,child:Scaffold(appBar:AppBar(title:const Text('Tasks',style:TextStyle(fontWeight:FontWeight.bold)),bottom:const TabBar(tabs:[Tab(text:'Available'),Tab(text:'My Tasks')]),actions:[IconButton(onPressed:loadTasks,icon:const Icon(Icons.refresh))]),body:loading?const Center(child:CircularProgressIndicator()):TabBarView(children:[
 RefreshIndicator(
  onRefresh: loadTasks,
  child: tasks.isEmpty
    ? ListView(children: const [SizedBox(height:180), Center(child:Text('এখন কোনো Task নেই'))])
    : ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: tasks.length,
        itemBuilder: (context,i) {
          final t=tasks[i];
          final done=mine.any((m)=>m['task_id']==t['id']);
          final reward=(t['reward'] as num?)?.toDouble()??0;
          return Card(child:ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(child:Icon(done?Icons.check:Icons.bolt)),
            title: Text(t['title']??'Task',style:const TextStyle(fontWeight:FontWeight.bold)),
            subtitle: Text(t['description']??'',maxLines:2,overflow:TextOverflow.ellipsis),
            trailing: Column(mainAxisAlignment:MainAxisAlignment.center,children:[
              Text('৳${reward.toStringAsFixed(2)}',style:const TextStyle(fontWeight:FontWeight.bold)),
              Text(done?'Submitted':'View')
            ]),
            onTap: () async {
              await Navigator.push(context,MaterialPageRoute(builder:(_)=>TaskDetailsPage(task:t)));
              await loadTasks();
            },
          ));
        },
      ),
 ),
 RefreshIndicator(onRefresh:loadTasks,child:mine.isEmpty?ListView(children:const[SizedBox(height:180),Center(child:Text('এখনও কোনো Task submit করেননি'))]):ListView.builder(padding:const EdgeInsets.all(12),itemCount:mine.length,itemBuilder:(context,i){final r=mine[i],st=r['status']?.toString()??'pending';return Card(child:ListTile(leading:Icon(st=='approved'?Icons.check_circle:st=='rejected'?Icons.cancel:Icons.hourglass_top,color:sc(st)),title:Text((r['tasks']?['title']??'Task').toString(),style:const TextStyle(fontWeight:FontWeight.bold)),subtitle:Text('Reward: ৳${r['reward_amount']}'),trailing:Chip(label:Text(st.toUpperCase()))));}))
 ])));
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
            .select('id,status,reward_amount,created_at,tasks(title)')
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
          (value, r) => value + ((r['reward_amount'] as num?)?.toDouble() ?? 0),
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
                          trailing: Text('৳${r['reward_amount']}'),
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
  final proof=TextEditingController(); bool submitting=false,alreadySubmitted=false,checking=true;
  @override void initState(){super.initState();checkSubmission();}
  @override void dispose(){proof.dispose();super.dispose();}
  Future<void> checkSubmission() async {
    try {
      final uid=supabase.auth.currentUser!.id;
      final rows=await supabase.from('task_submissions').select('id,status').eq('task_id',widget.task['id']).eq('user_id',uid).limit(1);
      if(mounted)setState(()=>alreadySubmitted=rows.isNotEmpty);
    } catch(_){ } finally {if(mounted)setState(()=>checking=false);}
  }
  Future<void> submit() async {
    if(proof.text.trim().isEmpty){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('কাজের প্রমাণ/Proof লিখুন')));return;}
    setState(()=>submitting=true);
    try {
      await supabase.rpc('submit_task',params:{'p_task_id':widget.task['id'],'p_proof':proof.text.trim()});
      if(mounted){setState(()=>alreadySubmitted=true);ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Task জমা হয়েছে। Admin review করবে।')));}
    } on PostgrestException catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.message)));}
    finally{if(mounted)setState(()=>submitting=false);}
  }
  @override Widget build(BuildContext context){
    final t=widget.task; final reward=(t['reward'] as num?)?.toDouble()??0;
    return Scaffold(appBar:AppBar(title:const Text('Task Details')),body:ListView(padding:const EdgeInsets.all(20),children:[
      Text(t['title']??'Task',style:const TextStyle(fontSize:25,fontWeight:FontWeight.bold)),
      const SizedBox(height:12),Card(child:ListTile(leading:const Icon(Icons.payments),title:const Text('Reward'),subtitle:Text('৳${reward.toStringAsFixed(2)}',style:const TextStyle(fontSize:20,fontWeight:FontWeight.bold)))),
      const SizedBox(height:16),const Text('Task instructions',style:TextStyle(fontSize:18,fontWeight:FontWeight.bold)),const SizedBox(height:8),
      Text(t['description']??'No instructions provided.'),const SizedBox(height:24),
      if(checking)const Center(child:CircularProgressIndicator()) else if(alreadySubmitted)
        const Card(child:ListTile(leading:Icon(Icons.hourglass_top),title:Text('Task already submitted'),subtitle:Text('Admin review করার অপেক্ষায় আছে।')))
      else ...[
        const Text('Proof / কাজের প্রমাণ',style:TextStyle(fontSize:18,fontWeight:FontWeight.bold)),const SizedBox(height:8),
        TextField(controller:proof,maxLines:5,decoration:const InputDecoration(hintText:'আপনার কাজের প্রমাণ এখানে লিখুন বা প্রয়োজনীয় তথ্য দিন',border:OutlineInputBorder())),
        const SizedBox(height:16),FilledButton.icon(onPressed:submitting?null:submit,icon:const Icon(Icons.send),label:Text(submitting?'জমা হচ্ছে...':'Task Submit')),
      ],
    ]));
  }
}

class WalletPage extends StatefulWidget{
  const WalletPage({super.key});
  @override State<WalletPage> createState()=>_WalletPageState();
}
class _WalletPageState extends State<WalletPage>{
  bool loading=true; double balance=0; List<Map<String,dynamic>> tx=[]; List<Map<String,dynamic>> withdrawals=[];
  @override void initState(){super.initState();load();}
  Future<void> load() async{try{final uid=supabase.auth.currentUser!.id;final d=await supabase.from('wallet_transactions').select('id,amount,type,description,created_at').eq('user_id',uid).order('created_at',ascending:false);final w=await supabase.from('withdrawal_requests').select('id,amount,method,account_number,status,created_at').eq('user_id',uid).order('created_at',ascending:false);double b=0;for(final r in d){b+=(r['amount'] as num).toDouble();}if(mounted)setState((){tx=List<Map<String,dynamic>>.from(d);withdrawals=List<Map<String,dynamic>>.from(w);balance=b;});}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Wallet লোড হয়নি: $e')));}finally{if(mounted)setState(()=>loading=false);}}
  Future<void> withdraw() async{final amount=TextEditingController();final account=TextEditingController();String method='bkash';final ok=await showDialog<bool>(context:context,builder:(ctx)=>StatefulBuilder(builder:(ctx,setD)=>AlertDialog(title:const Text('Withdraw'),content:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[Text('Balance: ৳${balance.toStringAsFixed(2)}'),TextField(controller:amount,keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:const InputDecoration(labelText:'Amount')),DropdownButtonFormField<String>(initialValue:method,items:const[DropdownMenuItem(value:'bkash',child:Text('bKash')),DropdownMenuItem(value:'nagad',child:Text('Nagad'))],onChanged:(v)=>setD(()=>method=v??'bkash')),TextField(controller:account,keyboardType:TextInputType.phone,decoration:const InputDecoration(labelText:'Account number'))])),actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('Cancel')),FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('Request'))])));if(ok!=true)return;final a=double.tryParse(amount.text.trim());if(a==null||a<=0||!RegExp(r'^01[3-9][0-9]{8}$').hasMatch(account.text.trim())){if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Amount ও account number সঠিক দিন')));return;}try{await supabase.rpc('request_withdrawal',params:{'p_amount':a,'p_method':method,'p_account_number':account.text.trim()});if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Withdrawal request জমা হয়েছে')));await load();}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Withdraw হয়নি: $e')));}}
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('Wallet Services',style:TextStyle(fontSize:27,fontWeight:FontWeight.w800)),actions:[IconButton(onPressed:load,icon:const Icon(Icons.refresh))]),body:loading?const Center(child:CircularProgressIndicator()):RefreshIndicator(onRefresh:load,child:ListView(padding:const EdgeInsets.all(16),children:[
    Container(decoration:BoxDecoration(color:const Color(0xFFE5F7EF),borderRadius:BorderRadius.circular(24)),child:ListTile(title:const Text('Available balance'),subtitle:Text('৳${balance.toStringAsFixed(2)}',style:const TextStyle(fontSize:26,fontWeight:FontWeight.bold)))),
    FilledButton(onPressed:balance>0?withdraw:null,child:const Text('Withdraw')),
    const SizedBox(height:18),const Text('Transactions',style:TextStyle(fontSize:18,fontWeight:FontWeight.bold)),
    if(tx.isEmpty)const ListTile(title:Text('কোনো transaction নেই')) else ...tx.map((r){final a=(r['amount'] as num).toDouble();return ListTile(leading:Icon(a>=0?Icons.add_circle_outline:Icons.remove_circle_outline),title:Text(r['description']?.toString().isNotEmpty==true?r['description'].toString():r['type'].toString()),trailing:Text('${a>=0?'+':''}৳${a.toStringAsFixed(2)}'));}),
    if(withdrawals.isNotEmpty)...[const Divider(),const Text('Withdrawal requests',style:TextStyle(fontSize:18,fontWeight:FontWeight.bold)),...withdrawals.map((w)=>ListTile(title:Text('${w['method'].toString().toUpperCase()} • ৳${(w['amount'] as num).toStringAsFixed(2)}'),subtitle:Text(w['account_number'].toString()),trailing:Text(w['status'].toString())))]
  ])));
}

class AdminPage extends StatefulWidget{const AdminPage({super.key});@override State<AdminPage> createState()=>_AdminPageState();}
class _AdminPageState extends State<AdminPage>{
 bool loading=true;List<Map<String,dynamic>> submissions=[],withdrawals=[],tasks=[],content=[];Map<String,dynamic>? support;
 @override void initState(){super.initState();load();}
 Future<void> load()async{setState(()=>loading=true);try{final r=await Future.wait([supabase.from('task_submissions').select('id,task_id,user_id,proof,status,reward_amount,tasks(title),profiles(full_name,phone)').order('created_at',ascending:false),supabase.from('withdrawal_requests').select('id,user_id,amount,method,account_number,status,profiles(full_name,phone)').order('created_at',ascending:false),supabase.from('tasks').select('id,title,reward,is_active').order('created_at',ascending:false),supabase.from('app_content').select().order('sort_order'),supabase.from('support_settings').select().eq('id',1).maybeSingle()]);if(mounted)setState((){submissions=List<Map<String,dynamic>>.from(r[0]);withdrawals=List<Map<String,dynamic>>.from(r[1]);tasks=List<Map<String,dynamic>>.from(r[2]);content=List<Map<String,dynamic>>.from(r[3]);support=r[4] as Map<String,dynamic>?;});}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString())));}finally{if(mounted)setState(()=>loading=false);}}
 Future<void> reviewTask(Map<String,dynamic>x,bool ok)async{try{await supabase.rpc(ok?'approve_task_submission':'reject_task_submission',params:{'p_submission_id':x['id'],'p_note':''});await load();}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString())));}}
 Future<void> reviewWithdrawal(Map<String,dynamic>x,bool ok)async{try{await supabase.rpc('review_withdrawal',params:{'p_withdrawal_id':x['id'],'p_approve':ok,'p_note':''});await load();}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString())));}}
 Future<void> addTask()async{final title=TextEditingController(),desc=TextEditingController(),reward=TextEditingController();final ok=await showDialog<bool>(context:context,builder:(c)=>AlertDialog(title:const Text('Create Task'),content:Column(mainAxisSize:MainAxisSize.min,children:[TextField(controller:title,decoration:const InputDecoration(labelText:'Title')),TextField(controller:desc,decoration:const InputDecoration(labelText:'Description')),TextField(controller:reward,decoration:const InputDecoration(labelText:'Reward'))]),actions:[TextButton(onPressed:()=>Navigator.pop(c,false),child:const Text('Cancel')),FilledButton(onPressed:()=>Navigator.pop(c,true),child:const Text('Create'))]));if(ok!=true)return;final r=double.tryParse(reward.text);if(title.text.trim().isEmpty||r==null)return;await supabase.from('tasks').insert({'title':title.text.trim(),'description':desc.text.trim(),'reward':r});await load();}
 @override Widget build(BuildContext context){final ps=submissions.where((x)=>x['status']=='pending').length,pw=withdrawals.where((x)=>x['status']=='pending').length;return Scaffold(appBar:AppBar(title:const Text('Admin Panel'),actions:[IconButton(onPressed:load,icon:const Icon(Icons.refresh))]),body:loading?const Center(child:CircularProgressIndicator()):DefaultTabController(length:5,child:Column(children:[Padding(padding:const EdgeInsets.all(8),child:Text('Pending tasks: '+ps.toString()+'   •   Pending withdrawals: '+pw.toString())),const TabBar(isScrollable:true,tabs:[Tab(text:'Submissions'),Tab(text:'Withdrawals'),Tab(text:'Tasks'),Tab(text:'Content'),Tab(text:'Support')]),Expanded(child:TabBarView(children:[_subs(),_withdrawals(),_tasks(),_content(),_support()]))])));}
 Widget _subs()=>ListView.builder(itemCount:submissions.length,itemBuilder:(c,i){final x=submissions[i],st=x['status'].toString(),p=x['profiles'] as Map<String,dynamic>?;return Card(child:ListTile(title:Text((x['tasks']?['title']??'Task').toString()),subtitle:Text((p?['full_name']??'User').toString()+' • '+st),trailing:st=='pending'?Row(mainAxisSize:MainAxisSize.min,children:[IconButton(onPressed:()=>reviewTask(x,false),icon:const Icon(Icons.close)),IconButton(onPressed:()=>reviewTask(x,true),icon:const Icon(Icons.check))]):Text(st)));});
 Widget _withdrawals()=>ListView.builder(itemCount:withdrawals.length,itemBuilder:(c,i){final x=withdrawals[i],st=x['status'].toString(),p=x['profiles'] as Map<String,dynamic>?;return Card(child:ListTile(title:Text(x['method'].toString().toUpperCase()+' • ৳'+x['amount'].toString()),subtitle:Text((p?['full_name']??'User').toString()+' • '+x['account_number'].toString()),trailing:st=='pending'?Row(mainAxisSize:MainAxisSize.min,children:[IconButton(onPressed:()=>reviewWithdrawal(x,false),icon:const Icon(Icons.close)),IconButton(onPressed:()=>reviewWithdrawal(x,true),icon:const Icon(Icons.check))]):Text(st)));});
 Widget _tasks()=>ListView(padding:const EdgeInsets.all(12),children:[FilledButton.icon(onPressed:addTask,icon:const Icon(Icons.add),label:const Text('Create New Task')),...tasks.map((x)=>Card(child:ListTile(title:Text(x['title'].toString()),subtitle:Text('Reward ৳'+x['reward'].toString()))))]);
 Future<void> addContent() async {String type='banner';final title=TextEditingController(),body=TextEditingController();final ok=await showDialog<bool>(context:context,builder:(c)=>StatefulBuilder(builder:(c,setD)=>AlertDialog(title:const Text('Banner / Rule যোগ করুন'),content:Column(mainAxisSize:MainAxisSize.min,children:[DropdownButtonFormField<String>(initialValue:type,items:const[DropdownMenuItem(value:'banner',child:Text('Banner')),DropdownMenuItem(value:'rule',child:Text('Rule'))],onChanged:(v)=>setD(()=>type=v??'banner')),TextField(controller:title,decoration:const InputDecoration(labelText:'Title')),TextField(controller:body,maxLines:3,decoration:const InputDecoration(labelText:'Text'))]),actions:[TextButton(onPressed:()=>Navigator.pop(c,false),child:const Text('Cancel')),FilledButton(onPressed:()=>Navigator.pop(c,true),child:const Text('Save'))])));if(ok==true&&title.text.trim().isNotEmpty){await supabase.from('app_content').insert({'content_type':type,'title':title.text.trim(),'body':body.text.trim()});await load();}}
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
        title:const Text('Mine',style:TextStyle(fontSize:27,fontWeight:FontWeight.w800)),
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
