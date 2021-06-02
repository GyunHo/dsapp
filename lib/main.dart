import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dsapp/db/bloc.dart';
import 'package:dsapp/db/quality_check_bloc.dart';
import 'package:dsapp/screens/auth_ask_page.dart';
import 'package:dsapp/screens/auth_page.dart';
import 'package:dsapp/screens/build_report_page.dart';
import 'package:dsapp/screens/cloud_page.dart';
import 'package:dsapp/screens/main_widget_page.dart';
import 'package:dsapp/screens/quality_check_page.dart';
import 'package:dsapp/screens/quality_result_page_.dart';
import 'package:dsapp/screens/report_page.dary.dart';
import 'package:dsapp/screens/sensingmap_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return MaterialApp(
            home: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        if (!snapshot.hasData) {
          return MaterialApp(
            home: AuthPage(),
            debugShowCheckedModeBanner: false,
          );
        } else {
          String uid = snapshot.data.uid;
          return StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(uid)
                .snapshots(),
            builder: (BuildContext con, AsyncSnapshot<DocumentSnapshot> snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return MaterialApp(
                  home: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              if (snap.data?.data()['auth'] ?? false) {
                return MultiProvider(
                  providers: [
                    ChangeNotifierProvider<Bloc>(create: (_) => Bloc()),
                    ChangeNotifierProvider<QualityCheckBloc>(
                        create: (_) => QualityCheckBloc())
                  ],
                  child: MaterialApp(
                    debugShowCheckedModeBanner: false,
                    initialRoute: "main",
                    routes: {
                      "main": (context) => MainWidget(),
                      "report": (context) => ReportPage(),
                      "sensing": (context) => SensingMap(),
                      "cloud": (context) => CloudPage(),
                      "qualitycheck": (context) => QualityCheckPage(),
                      "qualityresultdetail": (context) => QualityResultDetail(),
                      "buildreport": (context) => BuildReport()
                    },
                  ),
                );
              } else {
                return MaterialApp(
                  debugShowCheckedModeBanner: false,
                  home: AskAuth(),
                );
              }
            },
          );
        }
      },
    );
  }
}
