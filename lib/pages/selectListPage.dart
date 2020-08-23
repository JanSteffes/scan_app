import 'package:flutter/material.dart';
import 'package:scan_app/models/ListItem.dart';

class SelectListPage extends StatefulWidget {
  @override
  _SelectListPageState createState() => _SelectListPageState();
}

class _SelectListPageState extends State<SelectListPage> {
  List<ListItem<String>> list;
  @override
  void initState() {
    super.initState();
    populateData();
  }

  void populateData() {
    list = [];
    for (int i = 0; i < 10; i++) list.add(ListItem<String>("item $i"));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("List Selection"),
      ),
      body: ListView.builder(
        itemCount: list.length,
        itemBuilder: _getListItemTile,
      ),
    );
  }

  Widget _getListItemTile(BuildContext context, int index) {
    return GestureDetector(
      onTap: () {
        if (list.any((item) => item.isSelected)) {
          setState(() {
            list[index].isSelected = !list[index].isSelected;
          });
        }
      },
      onLongPress: () {
        setState(() {
          list[index].isSelected = true;
        });
      },
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 4),
        color: list[index].isSelected ? Colors.red[100] : Colors.white,
        child: ListTile(
          title: Text(list[index].data),
        ),
      ),
    );
  }
}
