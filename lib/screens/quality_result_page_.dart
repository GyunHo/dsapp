import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dsapp/db/quality_check_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:grouped_buttons/grouped_buttons.dart';
import 'package:provider/provider.dart';

class QualityResultDetail extends StatefulWidget {
  final DocumentSnapshot qualityResult;

  const QualityResultDetail({Key key, this.qualityResult}) : super(key: key);

  @override
  _QualityResultDetailState createState() => _QualityResultDetailState();
}

class _QualityResultDetailState extends State<QualityResultDetail> {
  String name, uid;
  Map<String, dynamic> check = Map();
  Map<String, dynamic> info = Map();

  Color switchColor(String res) {
    Color color;
    switch (res) {
      case "양호":
        color = Colors.white;
        break;
      case "불량":
        color = Colors.red.withOpacity(0.6);
        break;
      case "현장조치":
        color = Colors.yellow.withOpacity(0.6);
        break;
      case "조치완료":
        color = Colors.blue.withOpacity(0.6);
        break;
    }
    return color;
  }

  @override
  void initState() {
    User user = FirebaseAuth.instance.currentUser;
    String uid = user.uid;
    QualityCheckBloc().getUserName(uid).then((username) {
      name = username;
    });

    for (var i in widget.qualityResult.data().keys.toList()) {
      if (widget.qualityResult.data()[i] is Map) {
        check[i] = widget.qualityResult.data()[i];
      } else {
        info[i] = widget.qualityResult.data()[i];
      }
    }

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    List checkTitles = check.keys.toList();
    Timestamp time = info['점검일'];
    final bloc = Provider.of<QualityCheckBloc>(context);
    return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          actions: <Widget>[
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: OutlineButton(
                  borderSide: BorderSide(color: Colors.white, width: 3.0),
                  onPressed: () async {
                    await ask().then((res) {
                      if (res) {
                        FirebaseFirestore.instance
                            .runTransaction((Transaction transaction) async {
                          await transaction.update(
                              widget.qualityResult.reference, {
                            "최종결과": "조치완료",
                            "조치일": DateTime.now(),
                            "조치자": name
                          });
                          Navigator.pop(context, true);
                        }).whenComplete(() {
                          String message =
                              '조치 완료 보고\n국소명 : ${info['국소명']}\n점검 : ${info['점검자']}, ${time.toDate()}\n조치 : $name, ${DateTime.now()}';
                          print(message);
                          bloc.sendTeamRoom(message);
                        });
                      }
                    }).catchError((e) {
                      print("조치완료 쪽에서 실패");
                    });
                  },
                  child: Row(
                    children: <Widget>[
                      Icon(
                        Icons.save,
                        color: Colors.blue,
                      ),
                      Text(
                        "조치완료",
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  )),
            ),
          ],
          backgroundColor: Colors.black,
          centerTitle: true,
          title: Text(
            info['국소명'].toString(),
            style: TextStyle(color: Colors.white),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text("점검자 : ${info['점검자']}"),
                    Text("점검일 : ${time.toDate()}")
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                    itemCount: checkTitles.length,
                    itemBuilder: (BuildContext context, int index) {
                      String res = check[checkTitles[index]]['점검결과'];
                      return Card(
                        elevation: 5.0,
                        color: switchColor(res),
                        child: ListTile(
                            title: Text('${checkTitles[index]}'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                check[checkTitles[index]]['기타의견'] == '없음'
                                    ? SizedBox()
                                    : Card(
                                        child: Text(
                                            "점검의견 : ${check[checkTitles[index]]['기타의견']}"),
                                      ),
                                RadioButtonGroup(
                                  orientation:
                                      GroupedButtonsOrientation.HORIZONTAL,
                                  labels: ['양호', '불량', '현장조치'],
                                  picked: res,
                                  onSelected: (val) {
//                                    check[checkTitles[index]]['점검결과'] = val;
//                                    Firestore.instance.runTransaction(
//                                        (Transaction transaction) async {
//                                    Map ct = check[checkTitles[index]];
//                                    ct['점검결과'] = val;
//
//                                      await transaction.update(
//                                          widget.qualityResult.reference,
//                                          {checkTitles[index]: ct});
//                                    });
                                  },
                                ),
                              ],
                            )),
                      );
                    }),
              ),
            ],
          ),
        ));
  }

  Future<bool> ask() async {
    bool res = false;
    await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0)),
            title: Text("조치 완료 하시겠습니까?"),
            actions: <Widget>[
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: RaisedButton(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0)),
                  color: Colors.grey,
                  child: Text(
                    "취소",
                    style: TextStyle(color: Colors.white),
                  ),
                  onPressed: () {
                    Navigator.pop(context, false);
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: RaisedButton(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0)),
                  color: Colors.blue,
                  child: Text(
                    "조치완료",
                    style: TextStyle(color: Colors.white),
                  ),
                  onPressed: () {
                    Navigator.pop(context, true);
                  },
                ),
              ),
            ],
          );
        }).then((result) {
      res = result ?? false;
    });

    return res;
  }
}
