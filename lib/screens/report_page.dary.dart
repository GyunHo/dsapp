import 'package:dsapp/db/bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kf_drawer/kf_drawer.dart';
import 'package:provider/provider.dart';

class ReportPage extends KFDrawerContent {
  @override
  _ReportPageState createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  TextEditingController _textEditingController = TextEditingController();
  User user = FirebaseAuth.instance.currentUser;

  Map<String, String> work;
  String title = '';

  @override
  Widget build(BuildContext context) {
    final bloc = Provider.of<Bloc>(context);

    return Scaffold(
        appBar: AppBar(
          actions: <Widget>[
            IconButton(
                icon: Icon(Icons.delete),
                onPressed: () {
                  _textEditingController.clear();
                  title = '';
                }),
          ],
          backgroundColor: Colors.black,
          title: Text(
            "보고서 작성",
            style: TextStyle(color: Colors.white),
          ),
          leading: IconButton(
            onPressed: widget.onMenuPressed,
            icon: Icon(
              Icons.menu,
              color: Colors.white,
            ),
          ),
          centerTitle: true,
        ),
        body: FutureBuilder(
          future: bloc.getJson(),
          builder: (context, AsyncSnapshot<Map> snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              return Padding(
                padding: EdgeInsets.all(10.0),
                child: Container(
                  padding: EdgeInsets.all(4.0),
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(color: Colors.black, width: 2.0)),
                  child: Column(
                    children: <Widget>[
                      Container(
                          padding: EdgeInsets.all(4.0),
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8.0),
                              border:
                                  Border.all(color: Colors.black, width: 2.0)),
                          child: DropdownButton(
                            underline: SizedBox(),
                            isExpanded: true,
                            iconEnabledColor: Colors.grey,
                            hint: Text("보고서 유형 선택"),
                            items: snapshot.data.keys.map((title) {
                              return DropdownMenuItem(
                                  child: Text(title), value: title);
                            }).toList(),
                            onChanged: (value) {
                              title = value;
                              _textEditingController.text =
                                  snapshot.data[value];
                            },
                          )),
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.01,
                      ),
                      Expanded(
                        child: Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(4.0),
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8.0),
                                border: Border.all(
                                    color: Colors.black, width: 2.0)),
                            child: TextFormField(
                              controller: _textEditingController,
                              maxLines: null,
                              decoration:
                                  InputDecoration(border: InputBorder.none),
                            )),
                      ),
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.01,
                      ),
                      InkWell(
                          onTap: () {
                            bloc
                                .addReport(
                                    title:
                                        title == "" ? "분류없음" : title ?? '분류없음',
                                    document:
                                        _textEditingController.text ?? '내용없음')
                                .whenComplete(() {
                              bloc.sendTeamRoom(_textEditingController.text);
                              _textEditingController.clear();
                              return Scaffold.of(context).showSnackBar(SnackBar(
                                duration: Duration(milliseconds: 500),
                                content: Text("내용 복사/전송완료"),
                              ));
                            }).catchError((e) {
                              print(e);
                            });

                            Clipboard.setData(ClipboardData(
                                text: _textEditingController.text));
                          },
                          child: Card(
                            child: SizedBox(
                              child: Center(
                                child: Text("내용 복사 / 전송"),
                              ),
                              height: MediaQuery.of(context).size.height * 0.08,
                              width: double.infinity,
                            ),
                            elevation: 5.0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
                                side: BorderSide(
                                    color: Colors.black, width: 2.0)),
                          ))
                    ],
                  ),
                ),
              );
            } else {
              return Center(
                child: CircularProgressIndicator(),
              );
            }
          },
        ));
  }
}
