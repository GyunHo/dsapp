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

class BuildReportDetail extends KFDrawerContent {
  final DocumentSnapshot documentSnapshot;

  BuildReportDetail(this.documentSnapshot);

  @override
  _BuildReportDetailState createState() => _BuildReportDetailState();
}

class _BuildReportDetailState extends State<BuildReportDetail> {
  final GlobalKey<FabCircularMenuState> _fabCircleKey =
  GlobalKey<FabCircularMenuState>();
  DateTime date;
  String name;
  int device;
  String url =
      'https://spreadsheets.google.com/feeds/cells/1mWP4vOOjxK5aZNJFsTRzoUURXVISkQcTUC0FY7ym17I/1/public/full?alt=json';
  GlobalKey<FormState> _formkey = GlobalKey<FormState>();
  List<TextEditingController> etc = [];

  Map<String, Widget> widgetList = {};
  List<String> initElement = [];
  List<String> checkElement;
  List<String> materials;

  List<List> selectedMaterialsControllers = [];
  List<List> selectedMaterialsData = [];
  List<String> checkedData = [];
  Map<String, dynamic> resultData = {};

  @override
  void initState() {
    Map<String, dynamic> document = widget.documentSnapshot.data();
    resultData = document;
    device = document['device'] ?? 4;
    Timestamp initDate = document['시설일'];
    date = initDate.toDate();
    etc.add(TextEditingController(text: '${document['국소명'] ?? '이름없는 국소'}'));
    etc.add(TextEditingController(text: '${document['시설자'] ?? '시설자 불분명'}'));
    etc.add(TextEditingController(text: '${document['기타의견'] ?? ''}'));

    List<dynamic> semiel = jsonDecode(document['check']);

    for (var i in semiel) {
      initElement.add(i.toString());
      checkedData.add(i.toString());
    }

    List<dynamic> materials = jsonDecode(document['material']);

    for (List i in materials) {
      selectedMaterialsData.add(i);

      List<TextEditingController> con = List.generate(i.length, (index) {
        return TextEditingController(text: i[index]);
      });
      selectedMaterialsControllers.add(con);
    }

    getJson().then((re) {
      for (var i in checkElement) {
        widgetList[i] = Text(
          i.toString(),
          overflow: TextOverflow.fade,
        );
      }
    });
    User user = FirebaseAuth.instance.currentUser;

    FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get()
        .then((doc) {
      name = doc?.data()['name'] ?? '이름없음';
    });
    ;

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery
        .of(context)
        .size;
    return Scaffold(
      floatingActionButton: FabCircularMenu(
        key: _fabCircleKey,
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
                if (_formkey.currentState.validate() && date != null) {
                  _formkey.currentState.save();
                  resultData['check'] = jsonEncode(checkedData);
                  resultData['material'] = jsonEncode(selectedMaterialsData);
                  if (name == resultData['작성자']) {
                    FirebaseFirestore.instance
                        .runTransaction((Transaction transaction) async {
                      transaction
                          .update(widget.documentSnapshot.reference, resultData);
                    }).whenComplete(() {
                      Navigator.of(context).pop(true);
                    }).catchError((e) {
                      Scaffold.of(context).showSnackBar(SnackBar(
                        content: Text("수정 실패 하였습니다. 다시 시도해 주세요"),
                      ));
                    });
                  }
                }
              },
              child: Text(
                name == resultData['작성자'] ? '수정' : '수정불가',
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
          '${widget.documentSnapshot.data()['국소명'] ?? '이름없는 국소'}',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black,
      ),
      body: checkElement == null
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
                      child: textThing("국소명", 0, val: true),
                      flex: 2,
                    ),
                    Flexible(
                      child: textThing("시설자", 1, val: true),
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
                            currentTime: date ?? null,
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
                  mainList: checkElement,
                  onSelectionChanged: (selectedList) {
                    checkedData = selectedList;
                  },
                  widgetList: widgetList,
                  initialSelectionList: initElement ?? [],
                ),
                etcText(2),
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

  Widget etcText(int index) {
    return Column(
      children: <Widget>[
        SizedBox(
          height: 2.0,
        ),
        TextFormField(
          controller: etc[index],
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

  Widget textThing(String title, int index, {bool val = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 5.0),
      child: TextFormField(
        controller: etc[index],
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
      checkElement = checkData;
      materials = materialData;
    });
  }
}
