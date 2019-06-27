import 'package:flutte/components/bottomSheet.dart' as bs;
import 'package:flutte/screens/home/bottomSheetSwitch.dart';
import 'package:flutte/utils/db.dart';
import 'package:flutte/utils/texts.dart';
import 'package:flutte/utils/utils.dart';
import 'package:flutter/material.dart';

class Home extends StatefulWidget {
  @override
  _StateHome createState() => _StateHome();
}

class _StateHome extends State<Home> {
  String Function(String) _loc;

  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _listKey = GlobalKey<AnimatedListState>();
  int _dismissibleKey = 0;

  DateTime _date = Utils.time.getDateOnly();
  List<Transaction> _data = [];

  bool _switchValue = false;

  double dbSumTotal = 0.0;
  double dbSumMonth = 0.0;
  double dbSumDay = 0.0;

  @override
  void initState() {
    super.initState();

    _getDatabaseData();
  }

  void _addTransaction() async {
    final data = await bs.showModalBottomSheet<SheetData>(
      context: context,
      resizeToAvoidBottomPadding: true,
      builder: (BuildContext context) {
        return BottomSheetSwitch(
          switchValue: _switchValue,
          valueChanged: (bool value) {
            _switchValue = value;
          },
        );
      },
    );

    if (data != null && data.amount != null) {
      DBProvider.db.insertTransaction(Transaction(data.amount, data.note, data.date, data.category));
      _getDatabaseData();
    }
  }

  void _selectDate() async {
    final date = await showDatePicker(
        context: context, initialDate: DateTime.now(), firstDate: DateTime(2019), lastDate: DateTime(2038));
    setState(() => _date = Utils.time.getDateOnly(date));
    _getDatabaseData();
  }

  Widget _buildListItem(int itemIndex, Animation animation) {
    var item = _data[itemIndex];

    return SizeTransition(
      sizeFactor: animation,
      child: Card(
        child: Row(
          children: [
            Container(
              width: 8,
              height: 75,
              decoration: BoxDecoration(
                color: Utils.text.colorForBalance(item.amount, zero: Colors.grey),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(4),
                  bottomLeft: Radius.circular(4),
                ),
              ),
            ),
            Expanded(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8),
                margin: EdgeInsets.only(left: 8),
                color: ThemeData.dark().cardColor,
                child: ListTile(
                  contentPadding: EdgeInsets.only(right: 8),
                  trailing: Text(
                    '${item.amount}',
                    style: TextStyle(fontSize: 16),
                  ),
                  title: Text(item.category?.id == null
                      ? '${_loc('${item.category}')}'
                      : '${_loc('${item.category.nameParent}')} - ${_loc('${item.category}')}'),
                  subtitle: Text(item.note),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  int lastRemoved = 0;

  void _removeListItem(int index) {
    lastRemoved = DateTime.now().millisecondsSinceEpoch;

    DBProvider.db.deleteTransaction(_data[index].id);
    _listKey.currentState.removeItem(index, (_, __) => Container());
    _data.removeAt(index);

    Future.delayed(Duration(seconds: 1), () {
      if (DateTime.now().millisecondsSinceEpoch - lastRemoved > 900) {
        _getDatabaseData(reloadList: false);
      }
    });
  }

  void _getDatabaseData({bool reloadList = true}) async {
    var sumTotal = await DBProvider.db.getSumTotal();
    var sumMonth = await DBProvider.db.getSumMonthTotal(_date);
    var sumDay = await DBProvider.db.getSumDayTotal(_date);

    if (reloadList) {
      var dataDay = await DBProvider.db.getDay(_date);

      final l = _data.length;
      _data.insertAll(l, dataDay.reversed);
      for (int offset = 0; offset < dataDay.length; offset++) {
        _listKey.currentState.insertItem(l + offset);
      }
      for (var i = 0; i < l; i++) {
        _data.removeAt(0);
        _listKey.currentState.removeItem(0, (context, animation) {
          return _buildListItem(0, animation);
        });
      }
    }

    setState(() {
      dbSumTotal = sumTotal;
      dbSumMonth = sumMonth;
      dbSumDay = sumDay;
    });
  }

  @override
  Widget build(BuildContext context) {
    _loc = Locals.of(context).loc;

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        centerTitle: true,
        title: GestureDetector(
          child: Text(
            Utils.time.getFormattedDateByWords(
              _date,
              yesterday: _loc('yesterday'),
              today: _loc('today'),
              tomorrow: _loc('tomorrow'),
            ),
          ),
          onTap: _selectDate,
        ),
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    _loc('name'),
                    style: TextStyle(fontSize: 24, color: Colors.white),
                  ),
                  Text(
                    _loc('subtitle'),
                    style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w200),
                  ),
                ],
              ),
              decoration: BoxDecoration(color: Colors.lightBlue.shade800),
            )
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addTransaction,
        child: Icon(Icons.add),
      ),
      body: Column(
        // HACK FOR CASTING SHADOWS
        verticalDirection: VerticalDirection.up,
        children: [
          Expanded(
            child: AnimatedList(
              padding: EdgeInsets.only(bottom: 50, top: 4),
              key: _listKey,
              initialItemCount: _data.length,
              itemBuilder: (context, index, animation) => Dismissible(
                    key: Key((++_dismissibleKey + index).toString()),
                    child: _buildListItem(index, animation),
                    onDismissed: (DismissDirection _) => _removeListItem(index),
                    background: Center(
                      child: Text(
                        _loc('deleteTransaction'),
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 18),
                      ),
                    ),
                  ),
            ),
          ),
          Container(
            height: 200,
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(color: Color.fromRGBO(0, 0, 0, .18), spreadRadius: 3, blurRadius: 1),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  children: [
                    AnimatedDefaultTextStyle(
                      child: Text(_loc('total')),
                      style: TextStyle(color: Utils.text.colorForBalance(dbSumTotal).withOpacity(.5)),
                      duration: Duration(milliseconds: 300),
                    ),
                    Text(
                      '$dbSumTotal',
                      style: TextStyle(fontSize: 28),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Column(
                      children: [
                        Text(
                          '$dbSumMonth',
                          style: TextStyle(
                            fontSize: 16,
                          ),
                        ),
                        AnimatedDefaultTextStyle(
                          child: Text(_loc('thisMonth')),
                          style: TextStyle(color: Utils.text.colorForBalance(dbSumMonth).withOpacity(.5)),
                          duration: Duration(milliseconds: 300),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        Text(
                          '$dbSumDay',
                          style: TextStyle(
                            fontSize: 16,
                          ),
                        ),
                        AnimatedDefaultTextStyle(
                          child: Text(_loc('thisDay')),
                          style: TextStyle(color: Utils.text.colorForBalance(dbSumDay).withOpacity(.5)),
                          duration: Duration(milliseconds: 300),
                        ),
                      ],
                    ),
                  ],
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
