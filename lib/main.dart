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
  bool loading = false;
  @override void dispose(){email.dispose();super.dispose();}

  Future<void> sendLoginOtp() async {
    final value=email.text.trim();
    if(!value.contains('@')||!value.contains('.')){
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('সঠিক ইমেইল দিন')));
      return;
    }
    setState(()=>loading=true);
    try{
      await supabase.auth.signInWithOtp(email:value,shouldCreateUser:false);
      if(!mounted)return;
      Navigator.push(context,MaterialPageRoute(builder:(_)=>OtpPage(email:value,isRegistration:false)));
    }on AuthException catch(e){
      if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.message)));
    }finally{if(mounted)setState(()=>loading=false);}
  }

  @override Widget build(BuildContext context)=>Scaffold(
    body:SafeArea(child:ListView(padding:const EdgeInsets.all(24),children:[
      const SizedBox(height:70),const Icon(Icons.task_alt,size:76),const SizedBox(height:12),
      const Center(child:Text('Task Earn',style:TextStyle(fontSize:32,fontWeight:FontWeight.bold))),
      const Center(child:Text('Complete tasks • Track earnings')),const SizedBox(height:32),
      TextField(controller:email,keyboardType:TextInputType.emailAddress,decoration:const InputDecoration(labelText:'ইমেইল',border:OutlineInputBorder())),
      const SizedBox(height:16),
      FilledButton(onPressed:loading?null:sendLoginOtp,child:Text(loading?'OTP পাঠানো হচ্ছে...':'ইমেইলে OTP পাঠান')),
      TextButton(onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const RegisterPage())),child:const Text('নতুন অ্যাকাউন্ট তৈরি করুন')),
    ])));
}

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});
  @override State<RegisterPage> createState()=>_RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage>{
  final name=TextEditingController(),phone=TextEditingController(),email=TextEditingController();
  bool agree=false,loading=false;
  @override void dispose(){name.dispose();phone.dispose();email.dispose();super.dispose();}

  Future<void> submit() async{
    final fullName=name.text.trim(),mobile=phone.text.trim(),mail=email.text.trim();
    final bdPhone=RegExp(r'^01[3-9][0-9]{8}$').hasMatch(mobile);
    if(fullName.length<2||!bdPhone||!mail.contains('@')||!mail.contains('.')||!agree){
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('সব তথ্য সঠিকভাবে পূরণ করুন')));
      return;
    }
    setState(()=>loading=true);
    try{
      await supabase.auth.signInWithOtp(
        email:mail,shouldCreateUser:true,
        data:{'full_name':fullName,'phone':mobile},
      );
      if(!mounted)return;
      Navigator.pushReplacement(context,MaterialPageRoute(builder:(_)=>OtpPage(
        email:mail,isRegistration:true,fullName:fullName,phone:mobile,
      )));
    }on AuthException catch(e){
      if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.message)));
    }finally{if(mounted)setState(()=>loading=false);}
  }

  @override Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:const Text('Create Account')),
    body:ListView(padding:const EdgeInsets.all(20),children:[
      TextField(controller:name,decoration:const InputDecoration(labelText:'পূর্ণ নাম',border:OutlineInputBorder())),
      const SizedBox(height:12),
      TextField(controller:phone,keyboardType:TextInputType.phone,decoration:const InputDecoration(labelText:'মোবাইল নম্বর (01XXXXXXXXX)',border:OutlineInputBorder())),
      const SizedBox(height:12),
      TextField(controller:email,keyboardType:TextInputType.emailAddress,decoration:const InputDecoration(labelText:'ইমেইল',border:OutlineInputBorder())),
      CheckboxListTile(value:agree,onChanged:(v)=>setState(()=>agree=v??false),contentPadding:EdgeInsets.zero,title:const Text('Terms ও Privacy Policy-তে সম্মত')),
      FilledButton(onPressed:loading?null:submit,child:Text(loading?'OTP পাঠানো হচ্ছে...':'রেজিস্টার ও OTP পাঠান')),
    ]));
}

class OtpPage extends StatefulWidget{
  final String email;
  final bool isRegistration;
  final String? fullName;
  final String? phone;
  const OtpPage({super.key,required this.email,required this.isRegistration,this.fullName,this.phone});
  @override State<OtpPage> createState()=>_OtpPageState();
}

class _OtpPageState extends State<OtpPage>{
  final code=TextEditingController();
  bool loading=false,resending=false;
  @override void dispose(){code.dispose();super.dispose();}

  Future<void> verify() async{
    final otp=code.text.trim();
    if(!RegExp(r'^\d{6}$').hasMatch(otp)){
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('৬ সংখ্যার OTP দিন')));
      return;
    }
    setState(()=>loading=true);
    try{
      await supabase.auth.verifyOTP(email:widget.email,token:otp,type:OtpType.email);
      final user=supabase.auth.currentUser;
      if(user!=null&&widget.isRegistration){
        await supabase.from('profiles').upsert({
          'id':user.id,
          'full_name':widget.fullName??'',
          'phone':widget.phone,
          'verification_status':'unverified',
        });
      }
      if(!mounted)return;
      Navigator.pushAndRemoveUntil(context,MaterialPageRoute(builder:(_)=>const Shell()),(_)=>false);
    }on AuthException catch(e){
      if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.message)));
    }on PostgrestException catch(e){
      if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('প্রোফাইল সংরক্ষণ হয়নি: '+e.message)));
    }finally{if(mounted)setState(()=>loading=false);}
  }

  Future<void> resend() async{
    setState(()=>resending=true);
    try{
      await supabase.auth.signInWithOtp(
        email:widget.email,
        shouldCreateUser:widget.isRegistration,
        data:widget.isRegistration?{'full_name':widget.fullName??'','phone':widget.phone??''}:null,
      );
      if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('নতুন OTP ইমেইলে পাঠানো হয়েছে')));
    }on AuthException catch(e){
      if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.message)));
    }finally{if(mounted)setState(()=>resending=false);}
  }

  @override Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:const Text('ইমেইল OTP')),
    body:ListView(padding:const EdgeInsets.all(24),children:[
      const Icon(Icons.mark_email_read_outlined,size:72),const SizedBox(height:16),
      const Text('৬ সংখ্যার OTP লিখুন',textAlign:TextAlign.center,style:TextStyle(fontSize:22,fontWeight:FontWeight.bold)),
      const SizedBox(height:8),
      Text('কোড পাঠানো হয়েছে: '+widget.email,textAlign:TextAlign.center),
      const SizedBox(height:24),
      TextField(controller:code,keyboardType:TextInputType.number,maxLength:6,textAlign:TextAlign.center,decoration:const InputDecoration(labelText:'OTP Code',border:OutlineInputBorder())),
      const SizedBox(height:12),
      FilledButton(onPressed:loading?null:verify,child:Text(loading?'যাচাই হচ্ছে...':'OTP যাচাই করুন')),
      TextButton(onPressed:resending?null:resend,child:Text(resending?'পাঠানো হচ্ছে...':'আবার OTP পাঠান')),
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
