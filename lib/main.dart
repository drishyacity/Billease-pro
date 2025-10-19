import 'package:flutter/material.dart';
import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:get/get.dart';
import 'package:billease_pro/screens/auth/login_screen.dart';
import 'services/database_service.dart';
import 'services/backup_service.dart';
import 'package:billease_pro/utils/theme.dart';
import 'package:billease_pro/constants/app_constants.dart';
import 'package:billease_pro/controllers/bill_controller.dart';
import 'package:billease_pro/controllers/product_controller.dart';
import 'package:billease_pro/controllers/customer_controller.dart';
import 'services/supabase_service.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/onboarding/onboarding_basic_details_screen.dart';
import 'screens/windows/windows_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize desktop SQLite driver
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  await SupabaseService().initialize(
    url: 'https://jztnzcjxzavnkjfdlxov.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imp6dG56Y2p4emF2bmtqZmRseG92Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjA1MDIxNTUsImV4cCI6MjA3NjA3ODE1NX0.k7B-c2PUWOLEwuVGSCfzGn-tCkVw-Fw_hG875-JbA7k',
  );
  await DatabaseService().setCurrentUser(SupabaseService().currentUserId);
  // Init local database
  await DatabaseService().database;
  // Start auto-backups
  await BackupService().startAutoBackup();
  await BackupService().startNetworkSync();
  
  // Initialize controllers
  Get.put(BillController());
  Get.put(ProductController());
  Get.put(CustomerController());
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: AppConstants.appName,
      theme: AppTheme.lightTheme(),
      home: StreamBuilder(
        stream: SupabaseService().authStateChanges,
        builder: (context, snapshot) {
          final user = SupabaseService().currentUser;
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          if (user == null) {
            DatabaseService().setCurrentUser(null);
            return const LoginScreen();
          }
          DatabaseService().setCurrentUser(user.id);
          try {
            Get.find<ProductController>().loadInitialProducts();
          } catch (_) {}
          try {
            Get.find<BillController>().loadBills();
          } catch (_) {}
          try {
            Get.find<CustomerController>(); // add reload method if present
          } catch (_) {}
          return FutureBuilder(
            future: DatabaseService().getCompanyProfile(),
            builder: (context, profSnap) {
              if (profSnap.connectionState != ConnectionState.done) {
                return const Scaffold(body: Center(child: CircularProgressIndicator()));
              }
              if (profSnap.data == null) {
                return const OnboardingBasicDetailsScreen();
              }
              return Platform.isWindows
                  ? const WindowsShell()
                  : const DashboardScreen();
            },
          );
        },
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          //
          // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
          // action in the IDE, or press "p" in the console), to see the
          // wireframe for each widget.
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
