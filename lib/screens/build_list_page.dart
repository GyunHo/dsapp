import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kf_drawer/kf_drawer.dart';
import 'package:flutter/material.dart';

import 'build_result_page.dart';

class BuildListPage extends KFDrawerContent {
  @override
  _BuildListPageState createState() => _BuildListPageState();
}

class _BuildListPageState extends State<BuildListPage> {
  List<DocumentSnapshot> filterLists = List<DocumentSnapshot>();
  TextEditingController _textEditingController = TextEditingController();

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        heroTag: "addbuild",
        backgroundColor: Colors.black,
        onPressed: () async {
          await Navigator.of(context).pushNamed("buildreport").then((re) {
            if (re == true) {
              Scaffold.of(context).showSnackBar(SnackBar(
                duration: Duration(milliseconds: 500),
                content: Text('저장에 성공 하였습니다.'),
              ));
            }
          });
        },
        child: Icon(
          Icons.add,
          color: Colors.white,
        ),
      ),
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          "시설내역서",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black,
        leading: IconButton(
          onPressed: widget.onMenuPressed,
          icon: Icon(
            Icons.menu,
            color: Colors.white,
          ),
        ),
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('buildlist').snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          List<DocumentSnapshot> docList = _textEditingController.text.isEmpty
              ? snapshot.data?.docs ?? []
              : filterLists;
          if (!snapshot.hasData) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: <Widget>[
                TextFormField(
                  decoration: InputDecoration(
                    hintText: "국소, 시설자, 자재명 등...",
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(width: 2.0),
                      borderRadius: BorderRadius.circular(5.0),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(width: 2.0),
                      borderRadius: BorderRadius.circular(5.0),
                    ),
                  ),
                  controller: _textEditingController,
                  onChanged: (query) {
                    setState(() {
                      queryFilter(snapshot.data, query);
                    });
                  },
                ),
                Expanded(
                  child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: docList.length,
                      itemBuilder: (context, index) {
                        Timestamp da = docList[index].data()['시설일'];
                        return Card(
                          elevation: 5.0,
                          child: ListTile(
                            onTap: () async {
                              await Navigator.of(context)
                                  .push(MaterialPageRoute(
                                      builder: (context) => BuildReportDetail(
                                          snapshot.data.docs[index])))
                                  .then((re) {
                                if (re == true) {
                                  Scaffold.of(context).showSnackBar(SnackBar(
                                    duration: Duration(milliseconds: 500),
                                    content: Text("내용 수정 완료"),
                                  ));
                                }
                              });
                            },
                            title: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text('${docList[index].data()['국소명']}'),
                                Text('시설 : ${docList[index].data()['시설자']}')
                              ],
                            ),
                            subtitle: Text('${da?.toDate() ?? 'noDate'}'),
                          ),
                        );
                      }),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void queryFilter(QuerySnapshot snapshot, String query) {
    filterLists.clear();
    List<DocumentSnapshot> documentSnapshot = snapshot.docs;
    for (var i in documentSnapshot) {
      List<dynamic> candidates = [];
      List<dynamic> check = jsonDecode(i.data()['check']);
      List<dynamic> materials = jsonDecode(i.data()['material']);
      candidates.addAll(check);
      candidates.add(i.data()['국소명']);
      candidates.add(i.data()['시설자']);
      candidates.add(i.data()['작성자']);
      for (var mat in materials) {
        candidates.add(mat[0]);
      }
      for (var q in candidates) {
        if (q.toString().contains(query)) {
          filterLists.add(i);
          break;
        }
      }
    }
  }
}
