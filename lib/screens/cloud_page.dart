import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dsapp/db/bloc.dart';
import 'package:flutter/material.dart';
import 'package:kf_drawer/kf_drawer.dart';
import 'package:provider/provider.dart';

class CloudPage extends KFDrawerContent {
  @override
  _CloudPageState createState() => _CloudPageState();
}

class _CloudPageState extends State<CloudPage> {
  @override
  Widget build(BuildContext context) {
    final bloc = Provider.of<Bloc>(context);
    return Scaffold(
      resizeToAvoidBottomPadding: false,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        centerTitle: true,
        title: Text('클라우드'),
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
        stream: FirebaseFirestore.instance
            .collection('documents')
            .orderBy('updatedate', descending: true)
            .snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData)
            return Center(child: CircularProgressIndicator());
          bloc.setDocumentSnapshot(snapshot.data.docs);
          return FirestoreListView();
        },
      ),
    );
  }
}

class FirestoreListView extends StatefulWidget {
  @override
  _FirestoreListViewState createState() => _FirestoreListViewState();
}

class _FirestoreListViewState extends State<FirestoreListView> {
  TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final bloc = Provider.of<Bloc>(context);
    List<DocumentSnapshot> _list = _controller.text.isEmpty
        ? bloc.getDocumentSnapshot()
        : bloc.getQueryList();
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: <Widget>[
          TextFormField(
            controller: _controller,
            onChanged: (query) {
              bloc.setQueryList(query);
            },
            decoration: InputDecoration(
                hintText: "검색",
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: BorderSide(color: Colors.black, width: 4.0))),
          ),
          SizedBox(
            height: 10.0,
          ),
          Flexible(
            child: GestureDetector(
              onTap: () {
                FocusScope.of(context).requestFocus(FocusNode());
              },
              child: ListView.builder(
                itemCount: _list.length,
                itemBuilder: (BuildContext context, int index) {
                  String doc = _list[index].data()['document'].toString();
                  return InkWell(
                    onLongPress: () async {
                      await FirebaseFirestore.instance
                          .runTransaction((Transaction transaction) {
                        transaction.delete(_list[index].reference);
                        return null;
                      });
                    },
                    onTap: () async {
                      await bloc
                          .showDocument(context, _list[index])
                          .then((res) {
                        Scaffold.of(context).showSnackBar(SnackBar(
                          content: Text(res),
                          duration: Duration(milliseconds: 1000),
                        ));
                      }).catchError((e) {
                        print("클라우드 페이지에서 다이어로그 팝시 리턴 String 없음");
                        return null;
                      });
                    },
                    child: Card(
                      elevation: 3.0,
                      child: Padding(
                        padding: EdgeInsets.all(15.0),
                        child: Container(child: Text(doc.toString())),
                      ),
                    ),
                  );

//              return ListTile(
//                title: Container(
//                  decoration: BoxDecoration(
//                    borderRadius: BorderRadius.circular(5.0),
//                    border: Border.all(color: Colors.black),
//                  ),
//                  padding: EdgeInsets.all(5.0),
//                  child: Row(
//                    children: <Widget>[
//                      Expanded(
//                        child: !_list[index].data['editing']
//                            ? Text(title)
//                            : TextFormField(
//                          autofocus: true,
//                                maxLines: null,
//                                initialValue: docs,
//                                onFieldSubmitted: (String val) {
//                                  Firestore.instance.runTransaction(
//                                      (Transaction transaction) async {
//                                    DocumentSnapshot snapshot =
//                                        await transaction
//                                            .get(_list[index].reference);
//                                    await transaction.update(
//                                        snapshot.reference, {
//                                      'title': val,
//                                      'editing': !_list[index].data['editing']
//                                    });
//                                  });
//                                },
//                              ),
//                      ),
//                    ],
//                  ),
//                ),
//                onTap: () {
//
//                  return Firestore.instance
//                      .runTransaction((Transaction transaction) async {
//                    DocumentSnapshot snapshot =
//                    await transaction.get(_list[index].reference);
//
//                    await transaction.update(
//                        snapshot.reference, {'editing': !snapshot['editing']});
//                  });
//                }
//              );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
