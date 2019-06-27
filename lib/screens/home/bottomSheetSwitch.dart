import 'package:flutte/utils/db.dart';
import 'package:flutte/utils/texts.dart';
import 'package:flutte/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BottomSheetSwitch extends StatefulWidget {
  BottomSheetSwitch({@required this.switchValue, @required this.valueChanged});

  final bool switchValue;
  final ValueChanged<bool> valueChanged;

  @override
  _BottomSheetSwitch createState() => _BottomSheetSwitch();
}

class _BottomSheetSwitch extends State<BottomSheetSwitch> {
  String Function(String) _loc;

  List<CategoryParent> _categories = List();

  SheetData _data;
  bool _switchValue;

  @override
  void initState() {
    _data = SheetData();
    _switchValue = widget.switchValue;
    super.initState();

    _loadCategories().then((cat) => setState(() => _categories = cat));
  }

  Future<List<CategoryParent>> _loadCategories() async => await DBProvider.db.getCategories();

  Future<Category> _showCategoriesDialog() async {
    final cats = List<Widget>();

    cats.addAll(_categories.map((c) => ExpansionTile(
          title: Text(_loc('$c')),
          children: c.children
              .map((m) => ListTile(
                    title: Text(_loc('$m')),
                    onTap: () => Navigator.of(context).pop<Category>(m),
                  ))
              .toList(),
        )));
    cats.add(ListTile(
      title: Text('Other'),
      onTap: () => Navigator.of(context).pop<Category>(Category.empty()),
    ));

    return await showDialog<Category>(
        context: context,
        barrierDismissible: false,
        builder: (context) => SimpleDialog(
              title: Text(_loc('categorySelect')),
              contentPadding: EdgeInsets.all(16),
              children: cats,
            ));
  }

  @override
  Widget build(BuildContext context) {
    _loc = Locals.of(context).loc;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 10,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                _switchValue = !_switchValue;
                widget.valueChanged(!_switchValue);
              });
            },
            child: SwitchListTile(
              title: _switchValue ? Text(_loc('received')) : Text(_loc('spent')),
              subtitle: Text(_loc('selectMode')),
              activeColor: Colors.lightGreenAccent,
              inactiveThumbColor: Colors.redAccent,
              inactiveTrackColor: Colors.redAccent.shade700.withOpacity(.5),
              value: _switchValue,
              onChanged: (bool value) => setState(() {
                    _switchValue = value;
                    widget.valueChanged(value);
                  }),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_loc('category')),
              FlatButton(
                onPressed: () => _showCategoriesDialog().then((c) => setState(() => _data.category = c)),
                child: Text(_data.category?.id == null
                    ? '${_loc('${_data.category}')}'
                    : '${_loc('${_data.category.nameParent}')} - ${_loc('${_data.category}')}'),
                color: Colors.blueAccent,
              ),
            ],
          ),
          Container(
            padding: EdgeInsets.symmetric(vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_loc('dateAndTime')),
                GestureDetector(
                  onTap: () {
                    showDatePicker(
                            context: context,
                            initialDate: _data.date ?? DateTime.now(),
                            firstDate: DateTime(2019),
                            lastDate: DateTime(2038))
                        .then((newDate) {
                      showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(_data.date ?? DateTime.now()),
                      ).then((newTime) {
                        var tempDate = _data.date;
                        if (newDate != null) tempDate = Utils.time.setDate(tempDate ?? DateTime.now(), newDate);

                        if (newTime != null) tempDate = Utils.time.setTime(tempDate, newTime.hour, newTime.minute);

                        setState(() {
                          _data.date = tempDate;
                        });
                      });
                    });
                  },
                  child: Text(Utils.time.getFormattedDateTimeByWords(_data.date ?? DateTime.now())),
                ),
              ],
            ),
          ),
          TextField(
            inputFormatters: [
              TextInputFormatter.withFunction((v1, v2) {
                final rgx = RegExp(r'^\d*[.,]?\d*$');
                return rgx.hasMatch(v2.text) ? v2 : v1;
              })
            ],
            keyboardType: TextInputType.numberWithOptions(signed: false, decimal: true),
            decoration: InputDecoration(
              border: UnderlineInputBorder(),
              labelText: _loc('amount'),
            ),
            onChanged: (String s) => _data.amount = (num.tryParse(s)?.toDouble() ?? 0.0),
          ),
          TextField(
            inputFormatters: [LengthLimitingTextInputFormatter(64)],
            decoration: InputDecoration(
              border: UnderlineInputBorder(),
              labelText: _loc('note'),
            ),
            onChanged: (String s) => _data.note = s ?? '',
          ),
          RaisedButton(
            child: Text(_loc('save')),
            onPressed: () {
              _data.amount *= (_switchValue ? 1 : -1);
              Navigator.pop<SheetData>(context, _data);
            },
          )
        ],
      ),
    );
  }
}

class SheetData {
  DateTime date = DateTime.now();
  double amount;
  String note;
  Category category = Category.empty();
}
