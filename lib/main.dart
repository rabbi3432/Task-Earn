import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const supabaseUrl = 'https://gzamivqrrflogjjvhbej.supabase.co';
const supabaseKey = 'sb_publishable_emPACnJ0LsZ1GjParqjJVA_wDO3faQg';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: supabaseUrl, publishableKey: supabaseKey);
  runApp(const TaskEarnApp());
}

final supabase = Supabase.instance.client;

String authEmailFromPhone(String mobile) =>
    'phone_${mobile.replaceAll(RegExp(r'\\D'), '')}@taskearn.local';

String normalizePhone(String mobile) => mobile.trim();

class TaskEarnApp extends StatelessWidget {
  const TaskEarnApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Task Earn',
    theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
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
  final name=TextEditingController(),phone=TextEditingController(),password=TextEditingController(),confirm=TextEditingController();
  bool agree=false,loading=false,obscure=true,obscureConfirm=true;
  @override void dispose(){name.dispose();phone.dispose();password.dispose();confirm.dispose();super.dispose();}
  Future<void> submit() async {
    final fullName=name.text.trim(),mobile=normalizePhone(phone.text),pass=password.text,confirmPass=confirm.text;
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
      if(mounted) Navigator.pushAndRemoveUntil(context,MaterialPageRoute(builder:(_)=>const Shell()),(_)=>false);
    } on AuthException catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.message)));}
    on PostgrestException catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('প্রোফাইল সংরক্ষণ হয়নি: ${e.message}')));}
    finally{if(mounted)setState(()=>loading=false);}
  }
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('Create Account')),body:ListView(padding:const EdgeInsets.all(20),children:[
    TextField(controller:name,decoration:const InputDecoration(labelText:'পূর্ণ নাম',border:OutlineInputBorder())),const SizedBox(height:12),
    TextField(controller:phone,keyboardType:TextInputType.phone,decoration:const InputDecoration(labelText:'মোবাইল নম্বর (01XXXXXXXXX)',border:OutlineInputBorder())),const SizedBox(height:12),
    TextField(controller:password,obscureText:obscure,decoration:InputDecoration(labelText:'পাসওয়ার্ড (কমপক্ষে ৬ অক্ষর)',border:const OutlineInputBorder(),suffixIcon:IconButton(onPressed:()=>setState(()=>obscure=!obscure),icon:Icon(obscure?Icons.visibility:Icons.visibility_off)))),const SizedBox(height:12),
    TextField(controller:confirm,obscureText:obscureConfirm,decoration:InputDecoration(labelText:'পাসওয়ার্ড আবার লিখুন',border:const OutlineInputBorder(),suffixIcon:IconButton(onPressed:()=>setState(()=>obscureConfirm=!obscureConfirm),icon:Icon(obscureConfirm?Icons.visibility:Icons.visibility_off)))),
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
  final pages=const[HomePage(),TasksPage(),WalletPage(),ProfilePage()]; bool isAdmin=false; bool loadingRole=true;
  @override void initState(){super.initState();loadRole();}
  Future<void> loadRole() async { try { final uid=supabase.auth.currentUser!.id; final p=await supabase.from('profiles').select('role').eq('id',uid).maybeSingle(); if(mounted)setState((){isAdmin=p?['role']=='admin'; loadingRole=false;}); } catch(_){if(mounted)setState(()=>loadingRole=false);} }
  void openAdmin(){Navigator.push(context,MaterialPageRoute(builder:(_)=>const AdminPanelPage())).then((_)=>loadRole());}
  @override Widget build(BuildContext context)=>Scaffold(appBar:isAdmin&&index==0?AppBar(title:const Text('Task Earn'),actions:[IconButton(onPressed:openAdmin,icon:const Icon(Icons.admin_panel_settings))]):null,body:loadingRole?const Center(child:CircularProgressIndicator()):pages[index],bottomNavigationBar:NavigationBar(
    selectedIndex:index,onDestinationSelected:(i)=>setState(()=>index=i),
    destinations:const[
      NavigationDestination(icon:Icon(Icons.home_outlined),label:'Home'),
      NavigationDestination(icon:Icon(Icons.assignment_outlined),label:'Tasks'),
      NavigationDestination(icon:Icon(Icons.account_balance_wallet_outlined),label:'Wallet'),
      NavigationDestination(icon:Icon(Icons.person_outline),label:'Profile'),
    ]));
}

class HomePage extends StatefulWidget{
  const HomePage({super.key});
  @override State<HomePage> createState()=>_HomePageState();
}
class _HomePageState extends State<HomePage>{
  bool loading=true; double balance=0;
  @override void initState(){super.initState();load();}
  Future<void> load() async{try{final uid=supabase.auth.currentUser!.id;final d=await supabase.from('wallet_transactions').select('amount').eq('user_id',uid);double b=0;for(final r in d){b+=(r['amount'] as num).toDouble();}if(mounted)setState(()=>balance=b);}finally{if(mounted)setState(()=>loading=false);}}
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('Task Earn')),body:RefreshIndicator(onRefresh:load,child:ListView(padding:const EdgeInsets.all(16),children:[
    Card(child:Padding(padding:const EdgeInsets.all(20),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      const Text('Available balance'),Text(loading?'...':'৳${balance.toStringAsFixed(2)}',style:const TextStyle(fontSize:32,fontWeight:FontWeight.bold)),
    ]))),
    const ListTile(leading:Icon(Icons.assignment),title:Text('Available tasks'),subtitle:Text('Tasks নিচের Tasks মেনুতে দেখুন')),
  ])));
}

class TasksPage extends StatefulWidget{
  const TasksPage({super.key});
  @override State<TasksPage> createState()=>_TasksPageState();
}
class _TasksPageState extends State<TasksPage>{
  bool loading=true; List<Map<String,dynamic>> tasks=[];
  @override void initState(){super.initState();loadTasks();}
  Future<void> loadTasks() async {
    try {
      final data=await supabase.from('tasks').select('id,title,description,reward,max_submissions').eq('is_active',true).order('created_at',ascending:false);
      if(mounted)setState(()=>tasks=List<Map<String,dynamic>>.from(data));
    } catch(e) {
      if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Task লোড হয়নি: $e')));
    } finally {if(mounted)setState(()=>loading=false);}
  }
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('Available Tasks'),actions:[IconButton(onPressed:loadTasks,icon:const Icon(Icons.refresh))]),
    body:loading?const Center(child:CircularProgressIndicator()):tasks.isEmpty?const Center(child:Text('এখন কোনো Task নেই')):RefreshIndicator(
      onRefresh:loadTasks,child:ListView.builder(padding:const EdgeInsets.all(12),itemCount:tasks.length,itemBuilder:(context,i){
        final t=tasks[i]; final reward=(t['reward'] as num?)?.toDouble()??0;
        return Card(child:ListTile(contentPadding:const EdgeInsets.all(16),leading:const CircleAvatar(child:Icon(Icons.task_alt)),
          title:Text(t['title']??'Task',style:const TextStyle(fontWeight:FontWeight.bold)),
          subtitle:Padding(padding:const EdgeInsets.only(top:6),child:Text(t['description']??'')),
          trailing:Column(mainAxisAlignment:MainAxisAlignment.center,children:[Text('৳${reward.toStringAsFixed(2)}',style:const TextStyle(fontWeight:FontWeight.bold)),const SizedBox(height:6),const Text('View')]),
          onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>TaskDetailsPage(task:t))).then((_)=>loadTasks()),
        ));
      })),
    );
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
      final uid=supabase.auth.currentUser!.id;
      await supabase.from('task_submissions').insert({'task_id':widget.task['id'],'user_id':uid,'proof':proof.text.trim(),'reward_amount':(widget.task['reward'] as num?)?.toDouble()??0});
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
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('Wallet'),actions:[IconButton(onPressed:load,icon:const Icon(Icons.refresh))]),body:loading?const Center(child:CircularProgressIndicator()):RefreshIndicator(onRefresh:load,child:ListView(padding:const EdgeInsets.all(16),children:[
    Card(child:ListTile(title:const Text('Available balance'),subtitle:Text('৳${balance.toStringAsFixed(2)}',style:const TextStyle(fontSize:26,fontWeight:FontWeight.bold)))),
    FilledButton(onPressed:balance>0?withdraw:null,child:const Text('Withdraw')),
    const SizedBox(height:18),const Text('Transactions',style:TextStyle(fontSize:18,fontWeight:FontWeight.bold)),
    if(tx.isEmpty)const ListTile(title:Text('কোনো transaction নেই')) else ...tx.map((r){final a=(r['amount'] as num).toDouble();return ListTile(leading:Icon(a>=0?Icons.add_circle_outline:Icons.remove_circle_outline),title:Text(r['description']?.toString().isNotEmpty==true?r['description'].toString():r['type'].toString()),trailing:Text('${a>=0?'+':''}৳${a.toStringAsFixed(2)}'));}),
    if(withdrawals.isNotEmpty)...[const Divider(),const Text('Withdrawal requests',style:TextStyle(fontSize:18,fontWeight:FontWeight.bold)),...withdrawals.map((w)=>ListTile(title:Text('${w['method'].toString().toUpperCase()} • ৳${(w['amount'] as num).toStringAsFixed(2)}'),subtitle:Text(w['account_number'].toString()),trailing:Text(w['status'].toString())))]
  ])));
}

class ProfilePage extends StatelessWidget{
  const ProfilePage({super.key});
  Future<void> logout(BuildContext context) async{await supabase.auth.signOut();if(context.mounted)Navigator.pushAndRemoveUntil(context,MaterialPageRoute(builder:(_)=>const LoginPage()),(_)=>false);}
  @override Widget build(BuildContext context){final user=supabase.auth.currentUser;return Scaffold(appBar:AppBar(title:const Text('Profile')),body:ListView(children:[
    ListTile(leading:const Icon(Icons.phone),title:Text(user?.userMetadata?['phone']?.toString()??'User')),
    const ListTile(leading:Icon(Icons.verified),title:Text('Verification status'),subtitle:Text('Not verified')),
    ListTile(leading:const Icon(Icons.admin_panel_settings),title:const Text('Admin Panel'),onTap:() async {final p=await supabase.from('profiles').select('role').eq('id',supabase.auth.currentUser!.id).maybeSingle();if(p?['role']=='admin'&&context.mounted)Navigator.push(context,MaterialPageRoute(builder:(_)=>const AdminPanelPage()));else if(context.mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Admin access নেই')));}),
    ListTile(leading:const Icon(Icons.logout),title:const Text('Logout'),onTap:()=>logout(context)),
  ]));}
}

class VerificationPage extends StatefulWidget{const VerificationPage({super.key});@override State<VerificationPage> createState()=>_VerificationPageState();}
class _VerificationPageState extends State<VerificationPage>{
  bool loading=true,submitting=false;String status='unverified';
  @override void initState(){super.initState();loadStatus();}
  Future<void> loadStatus() async{try{final uid=supabase.auth.currentUser!.id;final p=await supabase.from('profiles').select('verification_status').eq('id',uid).single();final r=await supabase.from('verification_requests').select('status').eq('user_id',uid).order('created_at',ascending:false).limit(1);if(mounted)setState((){status=(p['verification_status'] as String?)??'unverified';if(status=='unverified'&&r.isNotEmpty)status=(r.first['status'] as String?)??status;loading=false;});}catch(_){if(mounted)setState(()=>loading=false);}}
  Future<void> apply() async{setState(()=>submitting=true);try{await supabase.from('verification_requests').insert({'user_id':supabase.auth.currentUser!.id});if(mounted){setState(()=>status='pending');ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Verification আবেদন জমা হয়েছে')));}}on PostgrestException catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.message)));}finally{if(mounted)setState(()=>submitting=false);}}
  String label()=>switch(status){'pending'=>'Pending','verified'=>'Verified','rejected'=>'Rejected',_=>'Not verified'};
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('Account Verification')),body:loading?const Center(child:CircularProgressIndicator()):ListView(padding:const EdgeInsets.all(20),children:[
    Card(child:ListTile(leading:Icon(status=='verified'?Icons.verified:Icons.verified_user_outlined),title:const Text('Verification status'),subtitle:Text(label()))),
    const SizedBox(height:16),const Text('Verification আবেদন admin review করবে।'),const SizedBox(height:16),
    if(status=='unverified'||status=='rejected')FilledButton(onPressed:submitting?null:apply,child:Text(submitting?'অপেক্ষা করুন...':'Apply for verification')),
    if(status=='pending')const FilledButton(onPressed:null,child:Text('Review pending')),
  ]));
}

class AdminPanelPage extends StatefulWidget{const AdminPanelPage({super.key});@override State<AdminPanelPage> createState()=>_AdminPanelPageState();}
class _AdminPanelPageState extends State<AdminPanelPage>{int tab=0;@override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('Admin Panel')),body:tab==0?const AdminTasksTab():tab==1?const AdminSubmissionsTab():const AdminWithdrawalsTab(),bottomNavigationBar:NavigationBar(selectedIndex:tab,onDestinationSelected:(i)=>setState(()=>tab=i),destinations:const[NavigationDestination(icon:Icon(Icons.assignment),label:'Tasks'),NavigationDestination(icon:Icon(Icons.fact_check),label:'Submissions'),NavigationDestination(icon:Icon(Icons.payments),label:'Withdrawals')]));}

class AdminTasksTab extends StatefulWidget{const AdminTasksTab({super.key});@override State<AdminTasksTab> createState()=>_AdminTasksTabState();}
class _AdminTasksTabState extends State<AdminTasksTab>{bool loading=true;List<Map<String,dynamic>> tasks=[];@override void initState(){super.initState();load();}Future<void> load() async{try{final d=await supabase.from('tasks').select('id,title,description,reward,max_submissions,is_active').order('created_at',ascending:false);if(mounted)setState(()=>tasks=List<Map<String,dynamic>>.from(d));}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Tasks লোড হয়নি: $e')));}finally{if(mounted)setState(()=>loading=false);}}
Future<void> edit([Map<String,dynamic>? task]) async{final title=TextEditingController(text:task?['title']?.toString()??'');final desc=TextEditingController(text:task?['description']?.toString()??'');final reward=TextEditingController(text:task?['reward']?.toString()??'');final max=TextEditingController(text:task?['max_submissions']?.toString()??'');bool active=task?['is_active']??true;final ok=await showDialog<bool>(context:context,builder:(ctx)=>StatefulBuilder(builder:(ctx,setD)=>AlertDialog(title:Text(task==null?'Create Task':'Edit Task'),content:SingleChildScrollView(child:Column(children:[TextField(controller:title,decoration:const InputDecoration(labelText:'Task title')),TextField(controller:desc,maxLines:4,decoration:const InputDecoration(labelText:'Description')),TextField(controller:reward,keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:const InputDecoration(labelText:'Reward (৳)')),TextField(controller:max,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Max submissions (optional)')),SwitchListTile(value:active,onChanged:(v)=>setD(()=>active=v),title:const Text('Active'))])),actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('Cancel')),FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('Save'))])));if(ok!=true)return;final r=double.tryParse(reward.text.trim()),m=int.tryParse(max.text.trim());if(title.text.trim().isEmpty||r==null||r<0){if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Title ও Reward সঠিক দিন')));return;}try{if(task==null){await supabase.from('tasks').insert({'title':title.text.trim(),'description':desc.text.trim(),'reward':r,'max_submissions':m,'is_active':active});}else{await supabase.from('tasks').update({'title':title.text.trim(),'description':desc.text.trim(),'reward':r,'max_submissions':m,'is_active':active,'updated_at':DateTime.now().toIso8601String()}).eq('id',task['id']);}await load();}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Save হয়নি: $e')));}}
Future<void> deleteTask(Map<String,dynamic> t) async{final yes=await showDialog<bool>(context:context,builder:(c)=>AlertDialog(title:const Text('Delete Task?'),content:Text(t['title']??''),actions:[TextButton(onPressed:()=>Navigator.pop(c,false),child:const Text('Cancel')),FilledButton(onPressed:()=>Navigator.pop(c,true),child:const Text('Delete'))]));if(yes!=true)return;try{await supabase.from('tasks').delete().eq('id',t['id']);await load();}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Delete হয়নি: $e')));}}
@override Widget build(BuildContext context)=>Scaffold(body:loading?const Center(child:CircularProgressIndicator()):tasks.isEmpty?const Center(child:Text('কোনো Task নেই')):RefreshIndicator(onRefresh:load,child:ListView.builder(padding:const EdgeInsets.all(12),itemCount:tasks.length,itemBuilder:(c,i){final t=tasks[i];final reward=(t['reward'] as num?)?.toDouble()??0;return Card(child:ListTile(title:Text(t['title']??'',style:const TextStyle(fontWeight:FontWeight.bold)),subtitle:Text('৳${reward.toStringAsFixed(2)} • ${t['is_active']==true?'Active':'Inactive'}'),trailing:PopupMenuButton<String>(onSelected:(v){if(v=='edit')edit(t);if(v=='delete')deleteTask(t);},itemBuilder:(_)=>const[PopupMenuItem(value:'edit',child:Text('Edit')),PopupMenuItem(value:'delete',child:Text('Delete'))])));})),floatingActionButton:FloatingActionButton.extended(onPressed:()=>edit(),icon:const Icon(Icons.add),label:const Text('Create Task')));}

class AdminSubmissionsTab extends StatefulWidget{const AdminSubmissionsTab({super.key});@override State<AdminSubmissionsTab> createState()=>_AdminSubmissionsTabState();}
class _AdminSubmissionsTabState extends State<AdminSubmissionsTab>{bool loading=true;List<Map<String,dynamic>> rows=[];@override void initState(){super.initState();load();}Future<void> load() async{try{final d=await supabase.from('task_submissions').select('id,task_id,user_id,proof,status,reward_amount,admin_note,created_at,tasks(title)').order('created_at',ascending:false);if(mounted)setState(()=>rows=List<Map<String,dynamic>>.from(d));}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Submissions লোড হয়নি: $e')));}finally{if(mounted)setState(()=>loading=false);}}
Future<void> review(Map<String,dynamic> row,bool approve) async{final note=TextEditingController();final ok=await showDialog<bool>(context:context,builder:(c)=>AlertDialog(title:Text(approve?'Approve submission':'Reject submission'),content:TextField(controller:note,maxLines:3,decoration:const InputDecoration(labelText:'Admin note (optional)')),actions:[TextButton(onPressed:()=>Navigator.pop(c,false),child:const Text('Cancel')),FilledButton(onPressed:()=>Navigator.pop(c,true),child:Text(approve?'Approve':'Reject'))]));if(ok!=true)return;try{await supabase.rpc(approve?'approve_task_submission':'reject_task_submission',params:{'p_submission_id':row['id'],'p_note':note.text.trim().isEmpty?null:note.text.trim()});if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(approve?'Approved ও reward যোগ হয়েছে':'Rejected')));await load();}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Review হয়নি: $e')));}}
@override Widget build(BuildContext context)=>Scaffold(body:loading?const Center(child:CircularProgressIndicator()):rows.isEmpty?const Center(child:Text('কোনো submission নেই')):RefreshIndicator(onRefresh:load,child:ListView.builder(padding:const EdgeInsets.all(12),itemCount:rows.length,itemBuilder:(c,i){final r=rows[i];final task=r['tasks'];final reward=(r['reward_amount'] as num?)?.toDouble()??0;return Card(child:Padding(padding:const EdgeInsets.all(12),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(task is Map?task['title']?.toString()??'Task':'Task',style:const TextStyle(fontWeight:FontWeight.bold,fontSize:17)),const SizedBox(height:6),Text('User: ${r['user_id']}'),Text('Reward: ৳${reward.toStringAsFixed(2)}'),Text('Status: ${r['status']}'),const SizedBox(height:8),Text('Proof: ${r['proof']}'),if(r['admin_note']!=null&&r['admin_note'].toString().isNotEmpty)Text('Note: ${r['admin_note']}'),if(r['status']=='pending')Row(mainAxisAlignment:MainAxisAlignment.end,children:[TextButton(onPressed:()=>review(r,false),child:const Text('Reject')),FilledButton(onPressed:()=>review(r,true),child:const Text('Approve'))])])));})));}


class AdminWithdrawalsTab extends StatefulWidget{const AdminWithdrawalsTab({super.key});@override State<AdminWithdrawalsTab> createState()=>_AdminWithdrawalsTabState();}
class _AdminWithdrawalsTabState extends State<AdminWithdrawalsTab>{
 bool loading=true;List<Map<String,dynamic>> rows=[];@override void initState(){super.initState();load();}
 Future<void> load() async{try{final d=await supabase.from('withdrawal_requests').select('id,user_id,amount,method,account_number,status,admin_note,created_at').order('created_at',ascending:false);if(mounted)setState(()=>rows=List<Map<String,dynamic>>.from(d));}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Withdrawals লোড হয়নি: $e')));}finally{if(mounted)setState(()=>loading=false);}}
 Future<void> review(Map<String,dynamic> r,bool approve) async{final note=TextEditingController();final ok=await showDialog<bool>(context:context,builder:(ctx)=>AlertDialog(title:Text(approve?'Approve withdrawal':'Reject withdrawal'),content:TextField(controller:note,maxLines:3,decoration:const InputDecoration(labelText:'Admin note (optional)')),actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('Cancel')),FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:Text(approve?'Approve':'Reject'))]));if(ok!=true)return;try{await supabase.rpc('review_withdrawal',params:{'p_withdrawal_id':r['id'],'p_approve':approve,'p_note':note.text.trim().isEmpty?null:note.text.trim()});await load();}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Review হয়নি: $e')));}}
 @override Widget build(BuildContext context)=>loading?const Center(child:CircularProgressIndicator()):rows.isEmpty?const Center(child:Text('কোনো withdrawal request নেই')):RefreshIndicator(onRefresh:load,child:ListView.builder(padding:const EdgeInsets.all(12),itemCount:rows.length,itemBuilder:(ctx,i){final r=rows[i];return Card(child:Padding(padding:const EdgeInsets.all(12),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('${r['method'].toString().toUpperCase()} • ৳${(r['amount'] as num).toStringAsFixed(2)}',style:const TextStyle(fontWeight:FontWeight.bold)),Text('Account: ${r['account_number']}'),Text('Status: ${r['status']}'),if(r['status']=='pending')Row(mainAxisAlignment:MainAxisAlignment.end,children:[TextButton(onPressed:()=>review(r,false),child:const Text('Reject')),FilledButton(onPressed:()=>review(r,true),child:const Text('Approve'))])])));}));}
