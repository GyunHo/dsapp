import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

class Bloc extends ChangeNotifier {
  String _inComingUrl =
      'https://teamroom.nate.com/api/webhook/bdb7d4dc/fspw77bjrmRMwhS3ioE6j3NZ';
  String _spreadSheetUrl =
      'https://spreadsheets.google.com/feeds/list/1EdkkgNyOy0CgA9R09TuANll2_fWYPoKjAfiB79ynpsQ/od6/public/values?alt=json';
  List<DocumentSnapshot> _snapshots;
  static GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String _barCodes = '';

  String getBarCodes() => _barCodes;

  void clearBarCodes() => _barCodes = '';

  void setBarCodes(String barcode) {
    if (!_barCodes.contains(barcode)) {
      _barCodes += '$barcode\n';
      notifyListeners();
    }
  }

  Future<void> joinUser(BuildContext context) async {
    Map<String, dynamic> userInfo = {'auth': false};
    String pw;
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0)),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text("가입"),
                IconButton(
                  icon: Icon(Icons.cancel),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                )
              ],
            ),
            content: Container(
              height: MediaQuery.of(context).size.height * 0.6,
              width: MediaQuery.of(context).size.width * 0.8,
              padding: EdgeInsets.all(10.0),
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: <Widget>[
                      TextFormField(
                        onSaved: (val) {
                          userInfo['email'] = val;
                        },
                        autovalidate: true,
                        decoration:
                            InputDecoration(hintText: "이메일", labelText: "이메일"),
                        validator: (val) {
                          if (!val.contains('@')) {
                            return "정확한 이메일을 입력하세요.";
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        onSaved: (val) {
                          pw = val;
                        },
                        autovalidate: true,
                        obscureText: true,
                        decoration: InputDecoration(
                          hintText: "비밀번호",
                          labelText: "비밀번호",
                        ),
                        validator: (val) {
                          if (val.isEmpty || val.length <= 6) {
                            return "6글자 이상 입력하세요.";
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        onSaved: (val) {
                          userInfo['name'] = val;
                        },
                        autovalidate: true,
                        decoration: InputDecoration(
                          hintText: "이름",
                          labelText: "이름",
                        ),
                        validator: (val) {
                          if (val.isEmpty) {
                            return "빈칸은 안됩니다";
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        onSaved: (val) {
                          userInfo['company'] = val;
                        },
                        autovalidate: true,
                        decoration: InputDecoration(
                          hintText: "회사",
                          labelText: "회사",
                        ),
                        validator: (val) {
                          if (val.isEmpty) {
                            return "빈칸은 안됩니다";
                          }
                          return null;
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: RaisedButton(
                          color: Colors.black,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0)),
                          child: Text(
                            '가입하기',
                            style: TextStyle(color: Colors.white),
                          ),
                          onPressed: () async {
                            if (_formKey.currentState.validate()) {
                              _formKey.currentState.save();
                              await FirebaseAuth.instance
                                  .createUserWithEmailAndPassword(
                                      email: userInfo['email'], password: pw)
                                  .then((UserCredential re) {
                                re.user.getIdToken().then((res) async {
                                  userInfo['token'] = res;
                                  await FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(re.user.uid)
                                      .set(userInfo);
                                });
                              });
                            }
                          },
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
          );
        });
  }

  Future<String> showDocument(
      BuildContext context, DocumentSnapshot document) async {
    TextEditingController controller =
        TextEditingController(text: document.data()['document']);
    return await showDialog(
        context: context,
        builder: (context) {
          Timestamp time = document.data()['updatedate'];

          return AlertDialog(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(document.data()['title']),
                    IconButton(
                        icon: Icon(Icons.cancel),
                        onPressed: () {
                          Navigator.pop(context);
                        })
                  ],
                ),
                Text(time.toDate().toString())
              ],
            ),
            actions: <Widget>[
              RaisedButton(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0)),
                onPressed: () async {
                  await Clipboard.setData(
                          ClipboardData(text: controller.text.toString()))
                      .whenComplete(() {
                    Navigator.pop(context, "내용 복사 완료");
                  }).catchError((e) {
                    Navigator.pop(context, "복사 오류 : $e");
                  });
                },
                child: Text("내용복사"),
                textColor: Colors.white,
                color: Colors.black,
              ),
              RaisedButton(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0)),
                onPressed: () async {
                  await updateReport(document, controller.text.toString())
                      .whenComplete(() {
                    String newMassage =
                        '/////내용수정발생/////\n' + '${controller.text.toString()}';
                    sendTeamRoom(newMassage);
                    Navigator.pop(context, "수정 완료");
                  }).catchError((e) {
                    print('내용 수정오류 : $e');
                    Navigator.pop(context, "내용 수정 오류");
                  });
                },
                child: Text("내용수정"),
                textColor: Colors.white,
                color: Colors.black,
              ),
            ],
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0)),
            content: Container(
                height: MediaQuery.of(context).size.height * 0.5,
                width: MediaQuery.of(context).size.width * 0.9,
                child: TextFormField(
                  controller: controller,
                  maxLines: null,
                  decoration: InputDecoration(
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0))),
                )),
          );
        });
  }

  setDocumentSnapshot(List<DocumentSnapshot> snapshots) =>
      _snapshots = snapshots;

  List<DocumentSnapshot> getDocumentSnapshot() => _snapshots;

  List<DocumentSnapshot> _queryList = [];

  setIncomingUrl(String url) {
    _inComingUrl = url;
    notifyListeners();
  }

  getIncomingUrl() => _inComingUrl;

  setSheetUrl(String url) {
    _spreadSheetUrl = url;
    notifyListeners();
  }

  getSheetUrl() => _spreadSheetUrl;

  sendTeamRoom(String massage) async {
    http.Response response =
        await http.post(getIncomingUrl(), body: {'content': massage});
    return response.statusCode;
  }

  getQueryList() => _queryList;

  setQueryList(String query) {
    _queryList.clear();
    List<DocumentSnapshot> dummy = [];
    for (DocumentSnapshot i in getDocumentSnapshot()) {
      if (i.data()['document'].toString().contains(query)) {
        dummy.add(i);
      }
    }
    _queryList = dummy;
    notifyListeners();
  }

  Future updateReport(DocumentSnapshot snapshot, String document) async {
    await FirebaseFirestore.instance
        .runTransaction((Transaction transaction) async {
      transaction.update(snapshot.reference,
          {'document': document, 'updatedate': DateTime.now()});
    });
  }

  Future<void> addReport({String title = "분류없음", String document = ""}) async {
    CollectionReference snapshot =
        FirebaseFirestore.instance.collection('documents');
    User user = FirebaseAuth.instance.currentUser;
    await FirebaseFirestore.instance
        .runTransaction((Transaction transaction) async {
      transaction.set(snapshot.doc(), {
        'creatdate': DateTime.now(),
        'updatedate': DateTime.now(),
        'uid': user.uid,
        'title': title,
        'document': document,
        'editing': false
      });
    }).whenComplete(() => print('complet'));
  }

  Future<Map<String, String>> getJson() async {
    http.Response response = await http.get(getSheetUrl());
    Map json = jsonDecode(response.body);
    List doc = json['feed']['entry'];
    List title = json['feed']['entry'][0].keys.toList().sublist(6);
    Map<String, String> res = {};
    for (String i in title) {
      String dummy = "";
      for (var x in doc) {
        if (x[i]['\$t'] != "") {
          dummy += "${x[i]['\$t']}\n";
        }
      }
      res[i.split("\$")[1]] = dummy;
    }
    return res;
  }
}
