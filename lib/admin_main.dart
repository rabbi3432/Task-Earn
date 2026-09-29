import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const supabaseProjectRef = 'gzamivqrrflogjjvhbej';
const supabaseUrl = 'https://$supabaseProjectRef.supabase.co';
const supabaseKey = 'sb_publishable_emPACnJ0LsZ1GjParqjJVA_wDO3faQg';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: supabaseUrl, publishableKey: supabaseKey);
  runApp(const AdminApp());
}

final supabase = Supabase.instance.client;
String authEmailFromPhone(String p) => 'phone_${p.replaceAll(RegExp(r'[^0-9]'), '')}@taskearn.local';

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Task Earn Admin',
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF087F68)),
      useMaterial3: true,
      scaffoldBackgroundColor: Colors.white,
      cardTheme: const CardThemeData(elevation: 0),
      appBarTheme: const AppBarTheme(backgroundColor: Colors.white, surfaceTintColor: Colors.white),
    ),
    home: supabase.auth.currentSession == null ? const AdminLogin() : const AdminGate(),
  );
}

class AdminLogin extends StatefulWidget {
  const AdminLogin({super.key});
  @override State<AdminLogin> createState() => _AdminLoginState();
}
class _AdminLoginState extends State<AdminLogin> {
  final phone = TextEditingController(), pass = TextEditingController();
  bool loading = false, obscure = true;
  @override void dispose(){phone.dispose(); pass.dispose(); super.dispose();}
  Future<void> login() async {
    final p = phone.text.trim(), pw = pass.text;
    if (!RegExp(r'^01[3-9][0-9]{8}$').hasMatch(p) || pw.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('সঠিক মোবাইল নম্বর ও পাসওয়ার্ড দিন')));
      return;
    }
    setState(() => loading = true);
    try {
      await supabase.auth.signInWithPassword(email: authEmailFromPhone(p), password: pw);
      final me = supabase.auth.currentUser;
      if (me == null) throw const AuthException('Login session পাওয়া যায়নি।');
      final profile = await supabase.from('profiles').select('role,is_blocked').eq('id', me.id).maybeSingle();
      if (profile == null || profile['role'] != 'admin') { await supabase.auth.signOut(); throw const AuthException('এই অ্যাকাউন্টে Admin access নেই।'); }
      if (profile['is_blocked'] == true) { await supabase.auth.signOut(); throw const AuthException('Admin accountটি blocked।'); }
      if (mounted) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const AdminGate()), (_) => false);
    } on AuthException catch(e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch(e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Login failed: $e')));
    } finally { if(mounted) setState(() => loading = false); }
  }
  @override Widget build(BuildContext context) => Scaffold(
    body: SafeArea(child: ListView(padding: const EdgeInsets.all(24), children: [
      const SizedBox(height: 70), const Icon(Icons.admin_panel_settings, size: 80),
      const Center(child: Text('Task Earn Admin', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold))),
      const SizedBox(height: 30),
      TextField(controller: phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Admin mobile', border: OutlineInputBorder())),
      const SizedBox(height: 12),
      TextField(controller: pass, obscureText: obscure, decoration: InputDecoration(labelText: 'Password', border: const OutlineInputBorder(), suffixIcon: IconButton(onPressed: () => setState(() => obscure = !obscure), icon: Icon(obscure ? Icons.visibility : Icons.visibility_off)))),
      const SizedBox(height: 16),
      FilledButton(onPressed: loading ? null : login, child: Text(loading ? 'Checking...' : 'Admin Login')),
    ])),
  );
}

class AdminGate extends StatefulWidget {
  const AdminGate({super.key});
  @override State<AdminGate> createState() => _AdminGateState();
}
class _AdminGateState extends State<AdminGate> {
  bool loading = true, ok = false;
  String? error;
  @override void initState(){super.initState(); check();}
  Future<void> check() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) { error = 'Session পাওয়া যায়নি।'; return; }
      final profile = await supabase.from('profiles').select('role,phone,full_name').eq('id', user.id).maybeSingle();
      if (profile == null) { error = 'এই লগইন অ্যাকাউন্টের profile পাওয়া যায়নি।'; return; }
      ok = profile['role'] == 'admin';
      if (!ok) error = 'এই অ্যাকাউন্টে Admin access নেই।';
    } catch(e) {
      error = 'Admin যাচাই করা যায়নি: $e';
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }
  Future<void> backToLogin() async {
    await supabase.auth.signOut();
    if (mounted) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const AdminLogin()), (_) => false);
  }
  @override Widget build(BuildContext context) {
    if (loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (ok) return const AdminPanel();
    return Scaffold(
      appBar: AppBar(title: const Text('Admin verification')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 54),
              const SizedBox(height: 12),
              Text(error ?? 'Admin access পাওয়া যায়নি', textAlign: TextAlign.center),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: backToLogin,
                child: const Text('Back to login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AdminPanel extends StatefulWidget {
  const AdminPanel({super.key});
  @override State<AdminPanel> createState() => _AdminPanelState();
}
class _AdminPanelState extends State<AdminPanel> {
  int tab = 0;
  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Task Earn Admin', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
      actions: [IconButton(onPressed: () => setState(() {}), icon: const Icon(Icons.refresh)), IconButton(onPressed: () async { await supabase.auth.signOut(); if(mounted) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const AdminLogin()), (_) => false); }, icon: const Icon(Icons.logout))],
    ),
    body: [const DashboardTab(), const UsersTab(), const TasksTab(), const SubmissionsTab(), const WithdrawalsTab(), const ContentTab()][tab],
    bottomNavigationBar: NavigationBar(
      height: 72, selectedIndex: tab, onDestinationSelected: (i) => setState(() => tab = i),
      destinations: const [
        NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Dashboard'),
        NavigationDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people), label: 'Users'),
        NavigationDestination(icon: Icon(Icons.assignment_outlined), selectedIcon: Icon(Icons.assignment), label: 'Tasks'),
        NavigationDestination(icon: Icon(Icons.fact_check_outlined), selectedIcon: Icon(Icons.fact_check), label: 'Submissions'),
        NavigationDestination(icon: Icon(Icons.payments_outlined), selectedIcon: Icon(Icons.payments), label: 'Withdrawals'),
        NavigationDestination(icon: Icon(Icons.campaign_outlined), selectedIcon: Icon(Icons.campaign), label: 'Content'),
      ],
    ),
  );
}

class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key});
  @override State<DashboardTab> createState() => _DashboardTabState();
}
class _DashboardTabState extends State<DashboardTab> {
  bool loading = true; String? error;
  int tasks = 0, activeTasks = 0, submissions = 0, pendingSubmissions = 0, withdrawals = 0, pendingWithdrawals = 0, users = 0, referrals = 0;
  @override void initState(){super.initState(); load();}
  Future<void> load() async {
    setState(() { loading = true; error = null; });
    try {
      final r = await Future.wait([
        supabase.from('tasks').select('id,is_active'),
        supabase.from('task_submissions').select('id,status'),
        supabase.from('withdrawal_requests').select('id,status'),
        supabase.from('profiles').select('id'),
        supabase.from('referrals').select('id'),
      ]);
      final ts = List<Map<String,dynamic>>.from(r[0]);
      final ss = List<Map<String,dynamic>>.from(r[1]);
      final ws = List<Map<String,dynamic>>.from(r[2]);
      final us = List<Map<String,dynamic>>.from(r[3]);
      final rs = List<Map<String,dynamic>>.from(r[4]);
      if (mounted) setState(() {
        tasks = ts.length; activeTasks = ts.where((x) => x['is_active'] == true).length;
        submissions = ss.length; pendingSubmissions = ss.where((x) => x['status'] == 'pending').length;
        withdrawals = ws.length; pendingWithdrawals = ws.where((x) => x['status'] == 'pending').length;
        users = us.length; referrals = rs.length;
      });
    } catch(e) { if(mounted) setState(() => error = 'Dashboard data লোড হয়নি: $e'); }
    finally { if(mounted) setState(() => loading = false); }
  }
  Widget card(IconData icon, String title, String value) => Expanded(child: Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, size: 28), const SizedBox(height: 10), Text(value, style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w800)), Text(title)]))));
  @override Widget build(BuildContext context) => loading
    ? const Center(child: CircularProgressIndicator())
    : RefreshIndicator(onRefresh: load, child: ListView(padding: const EdgeInsets.all(16), children: [
        const Text('Dashboard', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800)),
        const SizedBox(height: 6), const Text('Task Earn Admin control center'),
        if(error != null) Padding(padding: const EdgeInsets.only(top: 14), child: Text(error!, style: const TextStyle(color: Colors.red))),
        const SizedBox(height: 18),
        Row(children: [card(Icons.assignment, 'Total Tasks', '$tasks'), const SizedBox(width: 10), card(Icons.check_circle, 'Active Tasks', '$activeTasks')]),
        Row(children: [card(Icons.fact_check, 'Submissions', '$submissions'), const SizedBox(width: 10), card(Icons.pending_actions, 'Pending Submissions', '$pendingSubmissions')]),
        Row(children: [card(Icons.payments, 'Withdrawals', '$withdrawals'), const SizedBox(width: 10), card(Icons.hourglass_top, 'Pending Withdrawals', '$pendingWithdrawals')]),
        Row(children: [card(Icons.people, 'Users', '$users'), const SizedBox(width: 10), card(Icons.share, 'Referrals', '$referrals')]),
        const SizedBox(height: 18),
        const Card(child: ListTile(leading: Icon(Icons.info_outline), title: Text('Admin actions'), subtitle: Text('Tasks তৈরি/এডিট, submission approve/reject এবং withdrawal review করুন।'))),
      ]));
}

class UsersTab extends StatefulWidget {
  const UsersTab({super.key});
  @override State<UsersTab> createState()=>_UsersTabState();
}
class _UsersTabState extends State<UsersTab>{
  List<Map<String,dynamic>> rows=[]; bool loading=true; String? error;
  @override void initState(){super.initState();load();}
  Future<void> load() async{
    setState(()=>loading=true);
    try{
      final d=await supabase.from('profiles').select('id,full_name,phone,role,verification_status,is_blocked,referral_code,referred_by,created_at').order('created_at',ascending:false);
      if(mounted)setState(()=>rows=List<Map<String,dynamic>>.from(d));
    }catch(e){if(mounted)setState(()=>error='Users লোড হয়নি: $e');}
    finally{if(mounted)setState(()=>loading=false);}
  }
  Future<void> edit(Map<String,dynamic> u) async{
    final name=TextEditingController(text:u['full_name']?.toString()??'');
    String role=u['role']?.toString()??'user', status=u['verification_status']?.toString()??'unverified';
    bool blocked=u['is_blocked']==true;
    final ok=await showDialog<bool>(context:context,builder:(c)=>StatefulBuilder(builder:(c,setD)=>AlertDialog(
      title:const Text('Edit User'),
      content:SingleChildScrollView(child:Column(children:[
        TextField(controller:name,decoration:const InputDecoration(labelText:'Full name')),
        DropdownButtonFormField<String>(initialValue:role,decoration:const InputDecoration(labelText:'Role'),items:const[
          DropdownMenuItem(value:'user',child:Text('User')),DropdownMenuItem(value:'admin',child:Text('Admin'))],onChanged:(v)=>setD(()=>role=v??'user')),
        DropdownButtonFormField<String>(initialValue:status,decoration:const InputDecoration(labelText:'Verification'),items:const[
          DropdownMenuItem(value:'unverified',child:Text('Unverified')),DropdownMenuItem(value:'verified',child:Text('Verified')),DropdownMenuItem(value:'suspended',child:Text('Suspended'))],onChanged:(v)=>setD(()=>status=v??'unverified')),
        SwitchListTile(value:blocked,onChanged:(v)=>setD(()=>blocked=v),title:const Text('Block account')),
      ])),
      actions:[TextButton(onPressed:()=>Navigator.pop(c,false),child:const Text('Cancel')),FilledButton(onPressed:()=>Navigator.pop(c,true),child:const Text('Save'))],
    )));
    final fullName=name.text.trim();
    name.dispose();
    if(ok!=true)return;
    if(u['id'] == supabase.auth.currentUser?.id && (blocked || role != 'admin')) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('নিজের Admin account Block বা User role করা যাবে না।')));
      return;
    }
    try{
      await supabase.rpc('admin_update_user',params:{'p_user_id':u['id'],'p_full_name':fullName,'p_role':role,'p_verification_status':status,'p_is_blocked':blocked});
      await load();
    }catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('User update failed: $e')));}
  }
  @override Widget build(BuildContext context)=>loading?const Center(child:CircularProgressIndicator()):RefreshIndicator(
    onRefresh:load,
    child:ListView(padding:const EdgeInsets.all(12),children:[
      if(error!=null)Text(error!,style:const TextStyle(color:Colors.red)),
      Text('Total users: ${rows.length}',style:const TextStyle(fontSize:22,fontWeight:FontWeight.w800)),
      const SizedBox(height:10),
      ...rows.map((u)=>Card(child:ListTile(
        leading:CircleAvatar(child:Icon(u['is_blocked']==true?Icons.block:Icons.person)),
        title:Text(u['full_name']?.toString().isNotEmpty==true?u['full_name'].toString():'Unnamed user'),
        subtitle:Text('${u['phone']??''}\nRole: ${u['role']} • ${u['verification_status']}${u['is_blocked']==true?' • BLOCKED':''}\nReferral: ${u['referral_code']??''}'),
        isThreeLine:true,
        onTap:()=>edit(u),
      ))),
      const SizedBox(height:80),
    ]),
  );
}

class TasksTab extends StatefulWidget { const TasksTab({super.key}); @override State<TasksTab> createState()=>_TasksTabState(); }
class _TasksTabState extends State<TasksTab> {
  List<Map<String,dynamic>> rows=[]; bool loading=true; String? error;
  @override void initState(){super.initState();load();}
  Future<void> load() async { setState((){loading=true;error=null;}); try { final d=await supabase.from('tasks').select().order('created_at',ascending:false); if(mounted)setState(()=>rows=List<Map<String,dynamic>>.from(d)); } catch(e){if(mounted)setState(()=>error='Tasks লোড হয়নি: $e');} finally{if(mounted)setState(()=>loading=false);} }
  Future<void> edit([Map<String,dynamic>? t]) async {
    final title=TextEditingController(text:t?['title']?.toString()??''), desc=TextEditingController(text:t?['description']?.toString()??''), reward=TextEditingController(text:t?['reward']?.toString()??''), max=TextEditingController(text:t?['max_submissions']?.toString()??'');
    bool active=t?['is_active']??true;
    final yes=await showDialog<bool>(context:context,builder:(x)=>StatefulBuilder(builder:(x,setD)=>AlertDialog(title:Text(t==null?'Create Task':'Edit Task'),content:SingleChildScrollView(child:Column(children:[TextField(controller:title,decoration:const InputDecoration(labelText:'Title')),TextField(controller:desc,maxLines:4,decoration:const InputDecoration(labelText:'Instructions')),TextField(controller:reward,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Reward')),TextField(controller:max,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Max submissions')),SwitchListTile(value:active,onChanged:(v)=>setD(()=>active=v),title:const Text('Active'))])),actions:[TextButton(onPressed:()=>Navigator.pop(x,false),child:const Text('Cancel')),FilledButton(onPressed:()=>Navigator.pop(x,true),child:const Text('Save'))])));
    if(yes!=true){ title.dispose(); desc.dispose(); reward.dispose(); max.dispose(); return; }
    final data={'title':title.text.trim(),'description':desc.text.trim(),'reward':double.tryParse(reward.text)??0,'max_submissions':int.tryParse(max.text),'is_active':active};
    title.dispose(); desc.dispose(); reward.dispose(); max.dispose();
    try {
      if(t==null){await supabase.from('tasks').insert(data);}else{await supabase.from('tasks').update(data).eq('id',t['id']);}
      await load();
    } catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Task save হয়নি: $e')));}
  }
  @override Widget build(BuildContext context)=>Scaffold(
    body: loading?const Center(child:CircularProgressIndicator()):RefreshIndicator(onRefresh:load,child:ListView(padding:const EdgeInsets.all(12),children:[
      if(error!=null)Text(error!,style:const TextStyle(color:Colors.red)),
      Row(children:[const Expanded(child:Text('Tasks',style:TextStyle(fontSize:26,fontWeight:FontWeight.w800))),FilledButton.icon(onPressed:()=>edit(),icon:const Icon(Icons.add),label:const Text('Add Task'))]),
      const SizedBox(height:12),
      if(rows.isEmpty)const Card(child:Padding(padding:EdgeInsets.all(24),child:Center(child:Text('এখনও কোনো Task নেই। নিচের + বাটনে চাপ দিয়ে Task তৈরি করুন।')))),
      ...rows.map((r)=>Card(child:ListTile(title:Text(r['title'].toString()),subtitle:Text('৳${r['reward']} • ${r['is_active']==true?'Active':'Inactive'}'),trailing:const Icon(Icons.edit_outlined),onTap:()=>edit(r)))),const SizedBox(height:90)])),
    floatingActionButton: FloatingActionButton.extended(onPressed:()=>edit(),icon:const Icon(Icons.add),label:const Text('Add Task')),
  );
}

class SubmissionsTab extends StatefulWidget { const SubmissionsTab({super.key}); @override State<SubmissionsTab> createState()=>_SubmissionsTabState(); }
class _SubmissionsTabState extends State<SubmissionsTab> {
  List<Map<String,dynamic>> rows=[]; bool loading=true; String? error;
  @override void initState(){super.initState();load();}
  Future<void> load() async { setState((){loading=true;error=null;}); try { final d=await supabase.from('task_submissions').select('id,user_id,proof,status,reward_amount,created_at,tasks(title)').order('created_at',ascending:false); if(mounted)setState(()=>rows=List<Map<String,dynamic>>.from(d)); } catch(e){if(mounted)setState(()=>error='Submissions লোড হয়নি: $e');} finally{if(mounted)setState(()=>loading=false);} }
  Future<void> review(Map<String,dynamic> r,bool yes) async { try { await supabase.rpc(yes?'approve_task_submission':'reject_task_submission',params:{'p_submission_id':r['id'],'p_note':null}); await load(); } catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Review failed: $e')));} }
  @override Widget build(BuildContext context)=>loading?const Center(child:CircularProgressIndicator()):RefreshIndicator(onRefresh:load,child:ListView(padding:const EdgeInsets.all(12),children:[if(error!=null)Text(error!,style:const TextStyle(color:Colors.red)),...rows.map((r)=>Card(child:ListTile(title:Text((r['tasks']?['title']??'Task').toString()),subtitle:Text('Proof: ${r['proof']}\nReward: ৳${r['reward_amount']}\nStatus: ${r['status']}'),isThreeLine:true,trailing:r['status']=='pending'?Wrap(children:[IconButton(onPressed:()=>review(r,false),icon:const Icon(Icons.close)),IconButton(onPressed:()=>review(r,true),icon:const Icon(Icons.check))]):null)))]));
}

class WithdrawalsTab extends StatefulWidget { const WithdrawalsTab({super.key}); @override State<WithdrawalsTab> createState()=>_WithdrawalsTabState(); }
class _WithdrawalsTabState extends State<WithdrawalsTab> {
  List<Map<String,dynamic>> rows=[]; bool loading=true; String? error;
  @override void initState(){super.initState();load();}
  Future<void> load() async { setState((){loading=true;error=null;}); try { final d=await supabase.from('withdrawal_requests').select().order('created_at',ascending:false); if(mounted)setState(()=>rows=List<Map<String,dynamic>>.from(d)); } catch(e){if(mounted)setState(()=>error='Withdrawals লোড হয়নি: $e');} finally{if(mounted)setState(()=>loading=false);} }
  Future<void> review(Map<String,dynamic> r,bool yes) async { try { await supabase.rpc('review_withdrawal',params:{'p_withdrawal_id':r['id'],'p_approve':yes,'p_note':null}); await load(); } catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Withdrawal review failed: $e')));} }
  @override Widget build(BuildContext context)=>loading?const Center(child:CircularProgressIndicator()):RefreshIndicator(onRefresh:load,child:ListView(padding:const EdgeInsets.all(12),children:[if(error!=null)Text(error!,style:const TextStyle(color:Colors.red)),...rows.map((r)=>Card(child:ListTile(title:Text('${r['method'].toString().toUpperCase()} • ৳${r['amount']}'),subtitle:Text('${r['account_number']}\nStatus: ${r['status']}'),isThreeLine:true,trailing:r['status']=='pending'?Wrap(children:[IconButton(onPressed:()=>review(r,false),icon:const Icon(Icons.close)),IconButton(onPressed:()=>review(r,true),icon:const Icon(Icons.check))]):null)))]));
}

class ContentTab extends StatefulWidget{const ContentTab({super.key});@override State<ContentTab> createState()=>_ContentTabState();}
class _ContentTabState extends State<ContentTab>{List<Map<String,dynamic>> rows=[];bool loading=true;@override void initState(){super.initState();load();}Future<void> load()async{final d=await supabase.from('app_content').select().order('created_at',ascending:false);if(mounted)setState((){rows=List<Map<String,dynamic>>.from(d);loading=false;});}Future<void> add(String type)async{final t=TextEditingController(),b=TextEditingController(),i=TextEditingController(),u=TextEditingController();final ok=await showDialog<bool>(context:context,builder:(c)=>AlertDialog(title:Text(type=='banner'?'নতুন বিজ্ঞাপন':'নতুন নোটিশ'),content:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[TextField(controller:t,decoration:const InputDecoration(labelText:'শিরোনাম')),TextField(controller:b,decoration:const InputDecoration(labelText:'বিস্তারিত')),if(type=='banner')TextField(controller:i,decoration:const InputDecoration(labelText:'Banner image URL')),if(type=='banner')TextField(controller:u,decoration:const InputDecoration(labelText:'Target URL'))])),actions:[TextButton(onPressed:()=>Navigator.pop(c,false),child:const Text('Cancel')),FilledButton(onPressed:()=>Navigator.pop(c,true),child:const Text('Publish'))]));if(ok==true&&t.text.trim().isNotEmpty){await supabase.from('app_content').insert({'content_type':type,'title':t.text.trim(),'body':b.text.trim(),'image_url':i.text.trim().isEmpty?null:i.text.trim(),'target_url':u.text.trim().isEmpty?null:u.text.trim(),'is_active':true});await load();}}Future<void> toggle(Map<String,dynamic> x,bool v)async{await supabase.from('app_content').update({'is_active':v}).eq('id',x['id']);await load();}Future<void> remove(Map<String,dynamic> x)async{await supabase.from('app_content').delete().eq('id',x['id']);await load();}@override Widget build(BuildContext context)=>loading?const Center(child:CircularProgressIndicator()):RefreshIndicator(onRefresh:load,child:ListView(padding:const EdgeInsets.all(12),children:[const Text('বিজ্ঞাপন ও নোটিশ',style:TextStyle(fontSize:26,fontWeight:FontWeight.w800)),Row(children:[Expanded(child:FilledButton.icon(onPressed:()=>add('banner'),icon:const Icon(Icons.campaign),label:const Text('বিজ্ঞাপন'))),const SizedBox(width:8),Expanded(child:FilledButton.tonalIcon(onPressed:()=>add('rule'),icon:const Icon(Icons.notifications),label:const Text('নোটিশ')))]),...rows.map((x)=>Card(child:ListTile(leading:Icon(x['content_type']=='banner'?Icons.campaign:Icons.notifications),title:Text(x['title']?.toString()??''),subtitle:Text((x['body']??'').toString()),trailing:Wrap(children:[Switch(value:x['is_active']==true,onChanged:(v)=>toggle(x,v)),IconButton(onPressed:()=>remove(x),icon:const Icon(Icons.delete_outline))])))]));}
