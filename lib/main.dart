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

String authEmailFromPhone(String mobile) => 'phone_${mobile.replaceAll(RegExp(r'\\D'), '')}@taskearn.local';

String normalizePhone(String mobile) => mobile.trim();

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final phone = TextEditingController();
  final password = TextEditingController();
  bool loading = false;
  bool obscure = true;
  @override void dispose(){phone.dispose();password.dispose();super.dispose();}

  Future<void> login() async {
    final mobile = normalizePhone(phone.text);
    final pass = password.text;
    final bdPhone = RegExp(r'^01[3-9][0-9]{8}class Shell extends StatefulWidget{
  const Shell({super.key});
  @override State<Shell> createState()=>_ShellState();
}
class _ShellState extends State<Shell>{
  int index=0;
  final pages=const[HomePage(),TasksPage(),WalletPage(),ProfilePage()];
  @override Widget build(BuildContext context)=>Scaffold(
    body:pages[index],
    bottomNavigationBar:NavigationBar(
      selectedIndex:index,onDestinationSelected:(i)=>setState(()=>index=i),
      destinations:const[
        NavigationDestination(icon:Icon(Icons.home_outlined),label:'Home'),
        NavigationDestination(icon:Icon(Icons.assignment_outlined),label:'Tasks'),
        NavigationDestination(icon:Icon(Icons.account_balance_wallet_outlined),label:'Wallet'),
        NavigationDestination(icon:Icon(Icons.person_outline),label:'Profile'),
      ],
    ));
}

class HomePage extends StatelessWidget{
  const HomePage({super.key});
  @override Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:const Text('Task Earn')),
    body:ListView(padding:const EdgeInsets.all(16),children:[
      Card(child:Padding(padding:const EdgeInsets.all(20),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        const Text('Available balance'),
        const Text('৳0.00',style:TextStyle(fontSize:32,fontWeight:FontWeight.bold)),
        const SizedBox(height:12),
        FilledButton.icon(
          onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const VerificationPage())),
          icon:const Icon(Icons.verified_user_outlined),label:const Text('Verify account'),
        ),
      ]))),
      const ListTile(leading:Icon(Icons.assignment),title:Text('Available tasks'),subtitle:Text('Task system শিগগিরই যুক্ত হবে')),
    ]));
}

class TasksPage extends StatelessWidget{
  const TasksPage({super.key});
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('Tasks')),body:const Center(child:Text('No tasks available yet')));
}

class WalletPage extends StatelessWidget{
  const WalletPage({super.key});
  @override Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:const Text('Wallet')),
    body:ListView(padding:const EdgeInsets.all(16),children:const[
      Card(child:ListTile(title:Text('Balance'),subtitle:Text('৳0.00'))),
      FilledButton(onPressed:null,child:Text('Withdraw')),
    ]));
}

class ProfilePage extends StatelessWidget{
  const ProfilePage({super.key});
  Future<void> logout(BuildContext context) async{
    await supabase.auth.signOut();
    if(context.mounted)Navigator.pushAndRemoveUntil(context,MaterialPageRoute(builder:(_)=>const LoginPage()),(_)=>false);
  }
  @override Widget build(BuildContext context){
    final user=supabase.auth.currentUser;
    return Scaffold(appBar:AppBar(title:const Text('Profile')),body:ListView(children:[
      ListTile(leading:const Icon(Icons.email),title:Text(user?.email??'User')),
      const ListTile(leading:Icon(Icons.verified),title:Text('Verification status'),subtitle:Text('Not verified')),
      ListTile(leading:const Icon(Icons.logout),title:const Text('Logout'),onTap:()=>logout(context)),
    ]));
  }
}

class VerificationPage extends StatefulWidget{
  const VerificationPage({super.key});
  @override State<VerificationPage> createState()=>_VerificationPageState();
}
class _VerificationPageState extends State<VerificationPage>{
  bool loading=true,submitting=false;
  String status='unverified';
  @override void initState(){super.initState();loadStatus();}

  Future<void> loadStatus() async{
    try{
      final uid=supabase.auth.currentUser!.id;
      final profile=await supabase.from('profiles').select('verification_status').eq('id',uid).single();
      final requests=await supabase.from('verification_requests').select('status').eq('user_id',uid).order('created_at',ascending:false).limit(1);
      if(!mounted)return;
      setState((){
        status=(profile['verification_status'] as String?)??'unverified';
        if(status=='unverified'&&requests.isNotEmpty)status=(requests.first['status'] as String?)??status;
        loading=false;
      });
    }catch(_){if(mounted)setState(()=>loading=false);}
  }

  Future<void> apply() async{
    setState(()=>submitting=true);
    try{
      await supabase.from('verification_requests').insert({'user_id':supabase.auth.currentUser!.id});
      if(mounted){
        setState(()=>status='pending');
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Verification আবেদন জমা হয়েছে')));
      }
    }on PostgrestException catch(e){
      if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.message)));
    }finally{if(mounted)setState(()=>submitting=false);}
  }

  String label()=>switch(status){'pending'=>'Pending','verified'=>'Verified','rejected'=>'Rejected',_=>'Not verified'};

  @override Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:const Text('Account Verification')),
    body:loading?const Center(child:CircularProgressIndicator()):ListView(padding:const EdgeInsets.all(20),children:[
      Card(child:ListTile(
        leading:Icon(status=='verified'?Icons.verified:Icons.verified_user_outlined),
        title:const Text('Verification status'),subtitle:Text(label()),
      )),
      const SizedBox(height:16),
      const Text('Verification আবেদন admin review করবে। আবেদন করলেই account verified হবে না।'),
      const SizedBox(height:16),
      if(status=='unverified'||status=='rejected')FilledButton(
        onPressed:submitting?null:apply,
        child:Text(submitting?'অপেক্ষা করুন...':'Apply for verification'),
      ),
      if(status=='pending')const FilledButton(onPressed:null,child:Text('Review pending')),
    ]));
}
).hasMatch(mobile);
    if(!bdPhone || pass.length < 6){
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('সঠিক মোবাইল নম্বর ও কমপক্ষে ৬ অক্ষরের পাসওয়ার্ড দিন')));
      return;
    }
    setState(()=>loading=true);
    try{
      await supabase.auth.signInWithPassword(
        email: authEmailFromPhone(mobile),
        password: pass,
      );
      if(!mounted)return;
      Navigator.pushAndRemoveUntil(context,MaterialPageRoute(builder:(_)=>const Shell()),(_)=>false);
    }on AuthException catch(e){
      if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.message)));
    }finally{if(mounted)setState(()=>loading=false);}
  }

  @override Widget build(BuildContext context)=>Scaffold(
    body:SafeArea(child:ListView(padding:const EdgeInsets.all(24),children:[
      const SizedBox(height:70),const Icon(Icons.task_alt,size:76),const SizedBox(height:12),
      const Center(child:Text('Task Earn',style:TextStyle(fontSize:32,fontWeight:FontWeight.bold))),
      const Center(child:Text('Complete tasks • Track earnings')),const SizedBox(height:32),
      TextField(controller:phone,keyboardType:TextInputType.phone,decoration:const InputDecoration(labelText:'মোবাইল নম্বর (01XXXXXXXXX)',border:OutlineInputBorder())),
      const SizedBox(height:16),
      TextField(controller:password,obscureText:obscure,decoration:InputDecoration(labelText:'পাসওয়ার্ড',border:const OutlineInputBorder(),suffixIcon:IconButton(onPressed:()=>setState(()=>obscure=!obscure),icon:Icon(obscure?Icons.visibility:Icons.visibility_off)))),
      const SizedBox(height:16),
      FilledButton(onPressed:loading?null:login,child:Text(loading?'লগইন হচ্ছে...':'লগইন')),
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

  Future<void> submit() async{
    final fullName=name.text.trim(),mobile=normalizePhone(phone.text),pass=password.text,confirmPass=confirm.text;
    final bdPhone=RegExp(r'^01[3-9][0-9]{8}class Shell extends StatefulWidget{
  const Shell({super.key});
  @override State<Shell> createState()=>_ShellState();
}
class _ShellState extends State<Shell>{
  int index=0;
  final pages=const[HomePage(),TasksPage(),WalletPage(),ProfilePage()];
  @override Widget build(BuildContext context)=>Scaffold(
    body:pages[index],
    bottomNavigationBar:NavigationBar(
      selectedIndex:index,onDestinationSelected:(i)=>setState(()=>index=i),
      destinations:const[
        NavigationDestination(icon:Icon(Icons.home_outlined),label:'Home'),
        NavigationDestination(icon:Icon(Icons.assignment_outlined),label:'Tasks'),
        NavigationDestination(icon:Icon(Icons.account_balance_wallet_outlined),label:'Wallet'),
        NavigationDestination(icon:Icon(Icons.person_outline),label:'Profile'),
      ],
    ));
}

class HomePage extends StatelessWidget{
  const HomePage({super.key});
  @override Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:const Text('Task Earn')),
    body:ListView(padding:const EdgeInsets.all(16),children:[
      Card(child:Padding(padding:const EdgeInsets.all(20),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        const Text('Available balance'),
        const Text('৳0.00',style:TextStyle(fontSize:32,fontWeight:FontWeight.bold)),
        const SizedBox(height:12),
        FilledButton.icon(
          onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const VerificationPage())),
          icon:const Icon(Icons.verified_user_outlined),label:const Text('Verify account'),
        ),
      ]))),
      const ListTile(leading:Icon(Icons.assignment),title:Text('Available tasks'),subtitle:Text('Task system শিগগিরই যুক্ত হবে')),
    ]));
}

class TasksPage extends StatelessWidget{
  const TasksPage({super.key});
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('Tasks')),body:const Center(child:Text('No tasks available yet')));
}

class WalletPage extends StatelessWidget{
  const WalletPage({super.key});
  @override Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:const Text('Wallet')),
    body:ListView(padding:const EdgeInsets.all(16),children:const[
      Card(child:ListTile(title:Text('Balance'),subtitle:Text('৳0.00'))),
      FilledButton(onPressed:null,child:Text('Withdraw')),
    ]));
}

class ProfilePage extends StatelessWidget{
  const ProfilePage({super.key});
  Future<void> logout(BuildContext context) async{
    await supabase.auth.signOut();
    if(context.mounted)Navigator.pushAndRemoveUntil(context,MaterialPageRoute(builder:(_)=>const LoginPage()),(_)=>false);
  }
  @override Widget build(BuildContext context){
    final user=supabase.auth.currentUser;
    return Scaffold(appBar:AppBar(title:const Text('Profile')),body:ListView(children:[
      ListTile(leading:const Icon(Icons.email),title:Text(user?.email??'User')),
      const ListTile(leading:Icon(Icons.verified),title:Text('Verification status'),subtitle:Text('Not verified')),
      ListTile(leading:const Icon(Icons.logout),title:const Text('Logout'),onTap:()=>logout(context)),
    ]));
  }
}

class VerificationPage extends StatefulWidget{
  const VerificationPage({super.key});
  @override State<VerificationPage> createState()=>_VerificationPageState();
}
class _VerificationPageState extends State<VerificationPage>{
  bool loading=true,submitting=false;
  String status='unverified';
  @override void initState(){super.initState();loadStatus();}

  Future<void> loadStatus() async{
    try{
      final uid=supabase.auth.currentUser!.id;
      final profile=await supabase.from('profiles').select('verification_status').eq('id',uid).single();
      final requests=await supabase.from('verification_requests').select('status').eq('user_id',uid).order('created_at',ascending:false).limit(1);
      if(!mounted)return;
      setState((){
        status=(profile['verification_status'] as String?)??'unverified';
        if(status=='unverified'&&requests.isNotEmpty)status=(requests.first['status'] as String?)??status;
        loading=false;
      });
    }catch(_){if(mounted)setState(()=>loading=false);}
  }

  Future<void> apply() async{
    setState(()=>submitting=true);
    try{
      await supabase.from('verification_requests').insert({'user_id':supabase.auth.currentUser!.id});
      if(mounted){
        setState(()=>status='pending');
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Verification আবেদন জমা হয়েছে')));
      }
    }on PostgrestException catch(e){
      if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.message)));
    }finally{if(mounted)setState(()=>submitting=false);}
  }

  String label()=>switch(status){'pending'=>'Pending','verified'=>'Verified','rejected'=>'Rejected',_=>'Not verified'};

  @override Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:const Text('Account Verification')),
    body:loading?const Center(child:CircularProgressIndicator()):ListView(padding:const EdgeInsets.all(20),children:[
      Card(child:ListTile(
        leading:Icon(status=='verified'?Icons.verified:Icons.verified_user_outlined),
        title:const Text('Verification status'),subtitle:Text(label()),
      )),
      const SizedBox(height:16),
      const Text('Verification আবেদন admin review করবে। আবেদন করলেই account verified হবে না।'),
      const SizedBox(height:16),
      if(status=='unverified'||status=='rejected')FilledButton(
        onPressed:submitting?null:apply,
        child:Text(submitting?'অপেক্ষা করুন...':'Apply for verification'),
      ),
      if(status=='pending')const FilledButton(onPressed:null,child:Text('Review pending')),
    ]));
}
).hasMatch(mobile);
    if(fullName.length<2||!bdPhone||pass.length<6||pass!=confirmPass||!agree){
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('সব তথ্য সঠিকভাবে পূরণ করুন')));
      return;
    }
    setState(()=>loading=true);
    try{
      final authEmail=authEmailFromPhone(mobile);
      final res=await supabase.auth.signUp(
        email:authEmail,
        password:pass,
        data:{'full_name':fullName,'phone':mobile},
      );
      final user=res.user;
      if(user==null){
        throw const AuthException('অ্যাকাউন্ট তৈরি হয়নি। আবার চেষ্টা করুন।');
      }
      if(res.session==null){
        throw const AuthException('Supabase-এ Email confirmation চালু আছে। এটি বন্ধ করে আবার চেষ্টা করুন।');
      }
      await supabase.from('profiles').upsert({
        'id':user.id,
        'full_name':fullName,
        'phone':mobile,
        'verification_status':'unverified',
      });
      if(!mounted)return;
      Navigator.pushAndRemoveUntil(context,MaterialPageRoute(builder:(_)=>const Shell()),(_)=>false);
    }on AuthException catch(e){
      if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.message)));
    }on PostgrestException catch(e){
      if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('প্রোফাইল সংরক্ষণ হয়নি: '+e.message)));
    }finally{if(mounted)setState(()=>loading=false);}
  }

  @override Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:const Text('Create Account')),
    body:ListView(padding:const EdgeInsets.all(20),children:[
      TextField(controller:name,decoration:const InputDecoration(labelText:'পূর্ণ নাম',border:OutlineInputBorder())),
      const SizedBox(height:12),
      TextField(controller:phone,keyboardType:TextInputType.phone,decoration:const InputDecoration(labelText:'মোবাইল নম্বর (01XXXXXXXXX)',border:OutlineInputBorder())),
      const SizedBox(height:12),
      TextField(controller:password,obscureText:obscure,decoration:InputDecoration(labelText:'পাসওয়ার্ড (কমপক্ষে ৬ অক্ষর)',border:const OutlineInputBorder(),suffixIcon:IconButton(onPressed:()=>setState(()=>obscure=!obscure),icon:Icon(obscure?Icons.visibility:Icons.visibility_off)))),
      const SizedBox(height:12),
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
  final pages=const[HomePage(),TasksPage(),WalletPage(),ProfilePage()];
  @override Widget build(BuildContext context)=>Scaffold(
    body:pages[index],
    bottomNavigationBar:NavigationBar(
      selectedIndex:index,onDestinationSelected:(i)=>setState(()=>index=i),
      destinations:const[
        NavigationDestination(icon:Icon(Icons.home_outlined),label:'Home'),
        NavigationDestination(icon:Icon(Icons.assignment_outlined),label:'Tasks'),
        NavigationDestination(icon:Icon(Icons.account_balance_wallet_outlined),label:'Wallet'),
        NavigationDestination(icon:Icon(Icons.person_outline),label:'Profile'),
      ],
    ));
}

class HomePage extends StatelessWidget{
  const HomePage({super.key});
  @override Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:const Text('Task Earn')),
    body:ListView(padding:const EdgeInsets.all(16),children:[
      Card(child:Padding(padding:const EdgeInsets.all(20),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        const Text('Available balance'),
        const Text('৳0.00',style:TextStyle(fontSize:32,fontWeight:FontWeight.bold)),
        const SizedBox(height:12),
        FilledButton.icon(
          onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const VerificationPage())),
          icon:const Icon(Icons.verified_user_outlined),label:const Text('Verify account'),
        ),
      ]))),
      const ListTile(leading:Icon(Icons.assignment),title:Text('Available tasks'),subtitle:Text('Task system শিগগিরই যুক্ত হবে')),
    ]));
}

class TasksPage extends StatelessWidget{
  const TasksPage({super.key});
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('Tasks')),body:const Center(child:Text('No tasks available yet')));
}

class WalletPage extends StatelessWidget{
  const WalletPage({super.key});
  @override Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:const Text('Wallet')),
    body:ListView(padding:const EdgeInsets.all(16),children:const[
      Card(child:ListTile(title:Text('Balance'),subtitle:Text('৳0.00'))),
      FilledButton(onPressed:null,child:Text('Withdraw')),
    ]));
}

class ProfilePage extends StatelessWidget{
  const ProfilePage({super.key});
  Future<void> logout(BuildContext context) async{
    await supabase.auth.signOut();
    if(context.mounted)Navigator.pushAndRemoveUntil(context,MaterialPageRoute(builder:(_)=>const LoginPage()),(_)=>false);
  }
  @override Widget build(BuildContext context){
    final user=supabase.auth.currentUser;
    return Scaffold(appBar:AppBar(title:const Text('Profile')),body:ListView(children:[
      ListTile(leading:const Icon(Icons.email),title:Text(user?.email??'User')),
      const ListTile(leading:Icon(Icons.verified),title:Text('Verification status'),subtitle:Text('Not verified')),
      ListTile(leading:const Icon(Icons.logout),title:const Text('Logout'),onTap:()=>logout(context)),
    ]));
  }
}

class VerificationPage extends StatefulWidget{
  const VerificationPage({super.key});
  @override State<VerificationPage> createState()=>_VerificationPageState();
}
class _VerificationPageState extends State<VerificationPage>{
  bool loading=true,submitting=false;
  String status='unverified';
  @override void initState(){super.initState();loadStatus();}

  Future<void> loadStatus() async{
    try{
      final uid=supabase.auth.currentUser!.id;
      final profile=await supabase.from('profiles').select('verification_status').eq('id',uid).single();
      final requests=await supabase.from('verification_requests').select('status').eq('user_id',uid).order('created_at',ascending:false).limit(1);
      if(!mounted)return;
      setState((){
        status=(profile['verification_status'] as String?)??'unverified';
        if(status=='unverified'&&requests.isNotEmpty)status=(requests.first['status'] as String?)??status;
        loading=false;
      });
    }catch(_){if(mounted)setState(()=>loading=false);}
  }

  Future<void> apply() async{
    setState(()=>submitting=true);
    try{
      await supabase.from('verification_requests').insert({'user_id':supabase.auth.currentUser!.id});
      if(mounted){
        setState(()=>status='pending');
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Verification আবেদন জমা হয়েছে')));
      }
    }on PostgrestException catch(e){
      if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.message)));
    }finally{if(mounted)setState(()=>submitting=false);}
  }

  String label()=>switch(status){'pending'=>'Pending','verified'=>'Verified','rejected'=>'Rejected',_=>'Not verified'};

  @override Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:const Text('Account Verification')),
    body:loading?const Center(child:CircularProgressIndicator()):ListView(padding:const EdgeInsets.all(20),children:[
      Card(child:ListTile(
        leading:Icon(status=='verified'?Icons.verified:Icons.verified_user_outlined),
        title:const Text('Verification status'),subtitle:Text(label()),
      )),
      const SizedBox(height:16),
      const Text('Verification আবেদন admin review করবে। আবেদন করলেই account verified হবে না।'),
      const SizedBox(height:16),
      if(status=='unverified'||status=='rejected')FilledButton(
        onPressed:submitting?null:apply,
        child:Text(submitting?'অপেক্ষা করুন...':'Apply for verification'),
      ),
      if(status=='pending')const FilledButton(onPressed:null,child:Text('Review pending')),
    ]));
}
