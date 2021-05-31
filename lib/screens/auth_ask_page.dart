import 'package:flutter/material.dart';
import 'package:kf_drawer/kf_drawer.dart';


class AskAuth extends KFDrawerContent {
  @override
  _AskAuthState createState() => _AskAuthState();
}

class _AskAuthState extends State<AskAuth> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text('사용자 허가가 필요합니다'),
      ),
    );
  }
}
