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

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override State<LoginPage> createState() => _LoginPageState();
}
class _LoginPageState extends State<LoginPage> {
  final email = TextEditingController();
  final password = TextEditingController();
  bool hidden = true, loading = false;
  @override void dispose(){ email.dispose(); password.dispose(); super.dispose(); }
  Future<void> signIn() async {
    if (!email.text.contains('@') || password.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('সঠিক ইমেইল ও পাসওয়ার্ড দিন')));
      return;
    }
    setState(()=>loading=true);
    try {
      await supabase.auth.signInWithPassword(email: email.text.trim(), password: password.text);
      if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const Shell()));
    } on AuthException catch(e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally { if(mounted) setState(()=>loading=false); }
  }
  @override Widget build(BuildContext context)=>Scaffold(body:SafeArea(child:ListView(padding:const EdgeInsets.all(24),children:[
    const SizedBox(height:70), const Icon(Icons.task_alt,size:76), const SizedBox(height:12),
    const Center(child:Text('Task Earn',style:TextStyle(fontSize:32,fontWeight:FontWeight.bold))),
    const Center(child:Text('Complete tasks • Track earnings')), const SizedBox(height:32),
    TextField(controller:email,keyboardType:TextInputType.emailAddress,decoration:const InputDecoration(labelText:'ইমেইল',border:OutlineInputBorder())),
    const SizedBox(height:12),
    TextField(controller:password,obscureText:hidden,decoration:InputDecoration(labelText:'পাসওয়ার্ড',border:const OutlineInputBorder(),suffixIcon:IconButton(onPressed:()=>setState(()=>hidden=!hidden),icon:Icon(hidden?Icons.visibility:Icons.visibility_off)))),
    const SizedBox(height:20),
    FilledButton(onPressed:loading?null:signIn,child:Text(loading?'অপেক্ষা করুন...':'Login')),
    TextButton(onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const RegisterPage())),child:const Text('নতুন অ্যাকাউন্ট তৈরি করুন')),
  ])));
}

class RegisterPage extends StatefulWidget { const RegisterPage({super.key}); @override State<RegisterPage> createState()=>_RegisterPageState(); }
class _RegisterPageState extends State<RegisterPage> {
  final name=TextEditingController(),phone=TextEditingController(),email=TextEditingController(),pass=TextEditingController(),confirm=TextEditingController();
  bool agree=false,loading=false;
  @override void dispose(){for(final c in [name,phone,email,pass,confirm]){c.dispose();}super.dispose();}
  Future<void> submit() async {
    final bdPhone=RegExp(r'^01[3-9][0-9]{8}$').hasMatch(phone.text.trim());
    if(name.text.trim().length<2||!bdPhone||!email.text.contains('@')||pass.text.length<6||pass.text!=confirm.text||!agree){
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('সব তথ্য সঠিকভাবে পূরণ করুন'))); return;
    }
    setState(()=>loading=true);
    try {
      final res=await supabase.auth.signUp(email:email.text.trim(),password:pass.text,data:{'full_name':name.text.trim(),'phone':phone.text.trim()});
      if(!mounted)return;
      if(res.session!=null){
        Navigator.pushAndRemoveUntil(context,MaterialPageRoute(builder:(_)=>const Shell()),(_)=>false);
      } else {
        showDialog(context:context,builder:(_)=>AlertDialog(title:const Text('ইমেইল যাচাই করুন'),content:const Text('আপনার ইমেইলে confirmation link পাঠানো হয়েছে। Verify করার পর Login করুন।'),actions:[TextButton(onPressed:(){Navigator.pop(context);Navigator.pop(context);},child:const Text('OK'))]));
      }
    } on AuthException catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.message)));}
    finally{if(mounted)setState(()=>loading=false);}
  }
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('Create Account')),body:ListView(padding:const EdgeInsets.all(20),children:[
    TextField(controller:name,decoration:const InputDecoration(labelText:'পূর্ণ নাম',border:OutlineInputBorder())),const SizedBox(height:12),
    TextField(controller:phone,keyboardType:TextInputType.phone,decoration:const InputDecoration(labelText:'মোবাইল নম্বর (01XXXXXXXXX)',border:OutlineInputBorder())),const SizedBox(height:12),
    TextField(controller:email,keyboardType:TextInputType.emailAddress,decoration:const InputDecoration(labelText:'ইমেইল',border:OutlineInputBorder())),const SizedBox(height:12),
    TextField(controller:pass,obscureText:true,decoration:const InputDecoration(labelText:'পাসওয়ার্ড (কমপক্ষে ৬ অক্ষর)',border:OutlineInputBorder())),const SizedBox(height:12),
    TextField(controller:confirm,obscureText:true,decoration:const InputDecoration(labelText:'পাসওয়ার্ড আবার লিখুন',border:OutlineInputBorder())),
    CheckboxListTile(value:agree,onChanged:(v)=>setState(()=>agree=v??false),contentPadding:EdgeInsets.zero,title:const Text('Terms ও Privacy Policy-তে সম্মত')),
    FilledButton(onPressed:loading?null:submit,child:Text(loading?'অপেক্ষা করুন...':'Register')),
  ]));
}

class Shell extends StatefulWidget {const Shell({super.key});@override State<Shell> createState()=>_ShellState();}
class _ShellState extends State<Shell>{
  int index=0; final pages=const[HomePage(),TasksPage(),WalletPage(),ProfilePage()];
  @override Widget build(BuildContext context)=>Scaffold(body:pages[index],bottomNavigationBar:NavigationBar(selectedIndex:index,onDestinationSelected:(i)=>setState(()=>index=i),destinations:const[
    NavigationDestination(icon:Icon(Icons.home_outlined),label:'Home'),NavigationDestination(icon:Icon(Icons.assignment_outlined),label:'Tasks'),NavigationDestination(icon:Icon(Icons.account_balance_wallet_outlined),label:'Wallet'),NavigationDestination(icon:Icon(Icons.person_outline),label:'Profile')
  ]));
}
class HomePage extends StatelessWidget{const HomePage({super.key});@override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('Task Earn')),body:ListView(padding:const EdgeInsets.all(16),children:[
  Card(child:Padding(padding:const EdgeInsets.all(20),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('Available balance'),const Text('৳0.00',style:TextStyle(fontSize:32,fontWeight:FontWeight.bold)),const SizedBox(height:12),FilledButton.icon(onPressed:(){},icon:const Icon(Icons.verified_user_outlined),label:const Text('Verify account'))]))),
  const ListTile(leading:Icon(Icons.assignment),title:Text('Available tasks'),subtitle:Text('শিগগিরই task system যুক্ত হবে')),
]));}
class TasksPage extends StatelessWidget{const TasksPage({super.key});@override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('Tasks')),body:const Center(child:Text('No tasks available yet')));}
class WalletPage extends StatelessWidget{const WalletPage({super.key});@override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('Wallet')),body:ListView(padding:const EdgeInsets.all(16),children:const[Card(child:ListTile(title:Text('Balance'),subtitle:Text('৳0.00'))),FilledButton(onPressed:null,child:Text('Withdraw'))]));}
class ProfilePage extends StatelessWidget{
  const ProfilePage({super.key});
  Future<void> logout(BuildContext context) async {await supabase.auth.signOut();if(context.mounted)Navigator.pushAndRemoveUntil(context,MaterialPageRoute(builder:(_)=>const LoginPage()),(_)=>false);}
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('Profile')),body:ListView(children:[
    ListTile(leading:const Icon(Icons.email),title:Text(supabase.auth.currentUser?.email??'User')),
    const ListTile(leading:Icon(Icons.verified),title:Text('Verification status'),subtitle:Text('Not verified')),
    ListTile(leading:const Icon(Icons.logout),title:const Text('Logout'),onTap:()=>logout(context)),
  ]));
}
