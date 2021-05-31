import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class QualityCheckBloc extends ChangeNotifier {
  String _spreadSheetUrl =
      'https://spreadsheets.google.com/feeds/list/1leg0EydCOkzSMoDgWe9ac9PYLK_msjgrT9sV9SQFkjk/od6/public/values?alt=json';
  String _inComingUrl =
      'https://teamroom.nate.com/api/webhook/6c16f7a3/gmFLfSSH3g3N1oSCflGy3pdD';
  String _userName='';

  getCurrentUserName() => _userName;
  setCurrentUserName(String name) =>_userName=name;

  sendTeamRoom(String massage) async {
    http.Response response =
        await http.post(getIncomingUrl(), body: {'content': massage});
    return response.statusCode;
  }

  getSheetUrl() => _spreadSheetUrl;

  setIncomingUrl(String url) {
    _inComingUrl = url;
    notifyListeners();
  }

  getIncomingUrl() => _inComingUrl;

  Future<String> getUserName(String uid) async {
    DocumentSnapshot snapshot =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();


    return snapshot.data()['name'] ?? "이름없음";
  }

  Future<String> addCheckList(Map<String, dynamic> data) async {
    Map<String, dynamic> dummy = data;
    List<dynamic> vals = dummy.values.toList();
    List<dynamic> keys = dummy.keys.toList();
    String badMassage = '';
    String reporterInfo = '';
    for (var i = 0; i < vals.length; i++) {
      try {
        if (vals[i]['점검결과'] != '양호' || vals[i]['기타의견'] != '없음') {
          badMassage += '${keys[i]}\n';
          badMassage += '${vals[i]}\n';
        }
      } catch (e) {
        reporterInfo += '${keys[i]} = ${vals[i].toString()}\n';
      }
    }

    for (var i in vals) {
      try {
        if (i['점검결과'] != '양호') {
          dummy['최종결과'] = '불량';
          break;
        } else {
          dummy['최종결과'] = '양호';
        }
      } on Exception catch (_) {} catch (e) {
        print(e);
      }
    }
    String res = '';
    CollectionReference collectionReference =
        FirebaseFirestore.instance.collection('checklist');

    await collectionReference.doc().set(dummy).whenComplete(() {
      if (dummy['최종결과'] == '양호' && badMassage != '') {
        String sendOkMassage = reporterInfo + badMassage;
        sendTeamRoom(sendOkMassage);
        res = "성공";
      }

      if (dummy['최종결과'] == '양호' && badMassage == '') {
        String sendOkMassage = reporterInfo;
        sendOkMassage += '점검결과 = 전체 양호';
        sendTeamRoom(sendOkMassage);
        res = "성공";
      }

      if (dummy['최종결과'] == '불량') {
        String sendBadMassage = reporterInfo + badMassage;
        sendTeamRoom(sendBadMassage);
        res = "성공";
      }
    }).catchError((e) {
      res = "실패";
    });
    return res;
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
