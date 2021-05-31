import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fab_circular_menu/fab_circular_menu.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:qrscan/qrscan.dart' as scan;
import 'package:animated_multi_select/animated_multi_select.dart';
import 'package:flutter/cupertino.dart';
import 'package:kf_drawer/kf_drawer.dart';
import 'package:flutter/material.dart';
import 'package:select_dialog/select_dialog.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_datetime_picker/flutter_datetime_picker.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';

class BuildReport extends KFDrawerContent {
  @override
  _BuildReportState createState() => _BuildReportState();
}

class _BuildReportState extends State<BuildReport> {
  final GlobalKey<FabCircularMenuState> _fabCircleKey = GlobalKey<
      FabCircularMenuState>();
  GlobalKey<ScaffoldState> _globalKey = GlobalKey<ScaffoldState>();
  DateTime date;
  String name;
  int device = 4;
  String url =
      'https://spreadsheets.google.com/feeds/cells/1mWP4vOOjxK5aZNJFsTRzoUURXVISkQcTUC0FY7ym17I/1/public/full?alt=json';
  GlobalKey<FormState> _formkey = GlobalKey<FormState>();
  bool _isUsing = false;
  Map<String, Widget> widgetList = {};
  List<String> element;
  List<String> materials;
  List<List> selectedMaterialsControllers = [];
  List<String> checkedData = [];
  List<List> selectedMaterialsData = [];
  Map<String, dynamic> resultData = {};

  @override
  void initState() {
    getJson().then((re) {
      for (var i in element) {
        widgetList[i] = Text(
          i.toString(),
          overflow: TextOverflow.fade,
        );
      }
    });
    String userUID = FirebaseAuth.instance.currentUser.uid;
    String username = FirebaseFirestore.instance.collection('users').doc(userUID).get().then((value) => value.data()['name']??'이름없음').toString();
    resultData['작성자'] = username;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery
        .of(context)
        .size;
    return ModalProgressHUD(
      inAsyncCall: _isUsing,
      child: Scaffold(
        key: _globalKey,
        floatingActionButton: FabCircularMenu(
          key:_fabCircleKey,
          ringColor: Colors.black.withOpacity(0.1),
          fabColor: Colors.black,
          fabOpenColor: Colors.red,
          fabMargin: EdgeInsets.all(10.0),
          children: <Widget>[
            OutlineButton(
              onPressed: () {
                addMaterials("설치");
                _fabCircleKey.currentState.close();
              },
              child: Text('설치'),
            ),
            OutlineButton(
              onPressed: () {
                addMaterials("철거");
                _fabCircleKey.currentState.close();
              },
              child: Text('철거'),
            ),
          ],
          ringDiameter: size.width * 0.8,
          ringWidth: size.width * 0.25,
        ),
        appBar: AppBar(
          actions: <Widget>[
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: RaisedButton(
                onPressed: () async {
                  _onToggle();
                  if (_formkey.currentState.validate() && date != null) {
                    _formkey.currentState.save();
                    resultData['device'] = device;
                    resultData['check'] = jsonEncode(checkedData);
                    resultData['material'] = jsonEncode(selectedMaterialsData);
                    FirebaseFirestore.instance
                        .collection('buildlist')
                        .add(resultData)
                        .whenComplete(() {
                      Navigator.pop(context, true);
                    }).catchError((e) {
                      _offToggle();
                      _globalKey.currentState.showSnackBar(SnackBar(
                        content: Text('저장에 실패 했습니다. 다시 시도 하세요.'),
                      ));
                    });
                  } else {
                    _offToggle();
                    _globalKey.currentState.showSnackBar(SnackBar(
                      content: Text('국소명, 시설자명, 날짜는 필수 입니다.'),
                    ));
                  }
                },
                child: Text(
                  '저장',
                ),
                color: Colors.white,
              ),
            )
          ],
          centerTitle: true,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios),
            onPressed: () {
              Navigator.pop(context, 'false');
            },
          ),
          title: Text(
            '시설내역서 작성',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.black,
        ),
        body: element == null
            ? Center(
          child: CircularProgressIndicator(),
        )
            : Padding(
          padding: const EdgeInsets.all(5.0),
          child: Container(
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10.0),
                border: Border.all(color: Colors.black)),
            padding: EdgeInsets.all(8.0),
            child: Form(
              key: _formkey,
              child: Column(
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Flexible(
                        child: textThing("국소명", val: true),
                        flex: 2,
                      ),
                      Flexible(
                        child: textThing("시설자", val: true),
                        flex: 1,
                      ),
                    ],
                  ),
                  Row(
                    children: <Widget>[
                      Text('시설일 : '),
                      FlatButton(
                        onPressed: () async {
                          await DatePicker.showDatePicker(context,
                              onConfirm: (writedate) {
                                resultData['시설일'] = writedate;
                                setState(() {
                                  date = writedate;
                                });
                              }, locale: LocaleType.ko);
                        },
                        child: Text(
                          date == null
                              ? '날짜선택'
                              : '${date.year}년 ${date.month}월 ${date.day}일',
                          style: TextStyle(color: Colors.blue),
                        ),
                      ),
                    ],
                  ),
                  MultiSelectChip(
                    reverseScroll: false,
                    color: Colors.greenAccent,
                    width: 80,
                    height: 50,
                    borderRadius: BorderRadius.circular(10),
                    borderWidth: 2,
                    mainList: element,
                    onSelectionChanged: (selectedList) {
                      checkedData = selectedList;
                    },
                    widgetList: widgetList,
                    initialSelectionList: [],
                  ),
                  etcText(),
                  Expanded(
                    child: ListView.separated(
                        shrinkWrap: true,
                        separatorBuilder: (context, index) {
                          return Divider(
                            color: Colors.red,
                            thickness: 2.0,
                          );
                        },
                        itemCount: selectedMaterialsData.length,
                        itemBuilder: (context, index) {
                          return InkWell(
                            child: selectItem(index),
                            onLongPress: () {
                              deleteMaterials(index);
                            },
                          );
                        }),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget selectItem(int index) {
    return Card(
      elevation: 10.0,
      child: ListTile(
        contentPadding: EdgeInsets.all(0),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              selectedMaterialsData[index][1].toString(),
              style: TextStyle(color: Colors.red),
            ),
            Text(selectedMaterialsData[index][0].toString())
          ],
        ),
        subtitle: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(device, (inindex) {
            TextEditingController _controller =
            selectedMaterialsControllers[index][inindex + 2];
            return Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(2.0),
                  child: Column(
                    children: <Widget>[
                      TextFormField(
                        controller: _controller,
                        keyboardType: TextInputType.numberWithOptions(),
                        onSaved: (val) {
                          selectedMaterialsData[index][inindex + 2] = val;
                        },
                        decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            labelText: "${inindex + 1}번",
                            hintText: "${inindex + 1}번"),
                      ),
                      InkWell(
                        child: Text(
                          "바코드스캔",
                          style: TextStyle(color: Colors.blue),
                        ),
                        onTap: () async {
                          await scan.scan().then((barcode) {
                            _controller.text = barcode;
                          });
                        },
                      ),
                    ],
                  ),
                ));
          }),
        ),
      ),
    );
  }

  addMaterials(String classfication) async {
    await SelectDialog.showModal(context, items: materials, onChange: (val) {
      if (val != '' || val != null) {
        List mat = List.generate(device + 2, (index) {
          return '';
        });
        List<TextEditingController> con = List.generate(device + 2, (index) {
          return TextEditingController();
        });
        selectedMaterialsControllers.add(con);
        mat[0] = val;
        mat[1] = classfication;
        setState(() {
          selectedMaterialsData.add(mat);
        });
      }
    });
  }

  deleteMaterials(int index) {
    setState(() {
      selectedMaterialsData.removeAt(index);
      selectedMaterialsControllers.removeAt(index);
    });
  }

  Widget textThing(String title, {bool val = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 5.0),
      child: TextFormField(
        onChanged: (str) {
          resultData[title] = str;
        },
        decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
            hintText: title,
            labelText: title),
        autovalidate: val,
        validator: (value) {
          if (val && value.isEmpty) {
            return "$title 필수!";
          } else {
            return null;
          }
        },
        onSaved: (value) {},
      ),
    );
  }

  Widget etcText() {
    return Column(
      children: <Widget>[
        SizedBox(
          height: 2.0,
        ),
        TextFormField(
          decoration: InputDecoration(
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(width: 2.0),
                borderRadius: BorderRadius.circular(5.0),
              ),
              border:
              OutlineInputBorder(borderRadius: BorderRadius.circular(5.0)),
              labelText: "기타 의견",
              hintText: "기타 의견"),
          maxLines: null,
          onSaved: (val) {
            resultData['기타의견'] = val;
          },
        ),
      ],
    );
  }

  Future getJson() async {
    http.Response response = await http.get(url);
    Map<dynamic, dynamic> jsonData = jsonDecode(response.body);
    List<dynamic> data = jsonData['feed']['entry'];
    List<String> checkData = [];
    List<String> materialData = [];
    for (var i in data) {
      if (i['gs\$cell']['col'] == '2') {
        checkData.add(i['gs\$cell']['inputValue'].toString());
      }
      if (i['gs\$cell']['col'] == '1') {
        materialData.add(i['gs\$cell']['inputValue'].toString());
      }
    }
    setState(() {
      element = checkData;
      materials = materialData;
    });
  }

  void _onToggle() {
    setState(() {
      _isUsing = true;
    });
  }

  void _offToggle() {
    setState(() {
      _isUsing = false;
    });
  }
}
