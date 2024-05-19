import 'package:flutter/material.dart';

class MultiselectDropDown<T> extends StatefulWidget {
    final Function(List<T>) onSelectChange;
    final List<T> options;
    final String Function(T)? labelFunction;
    
    const MultiselectDropDown({
        super.key,
        required this.options,
        required this.onSelectChange,
        this.labelFunction
    });
    
    @override
    State<MultiselectDropDown<T>> createState() => _MultiselectDropDownState<T>();
}
    
class _MultiselectDropDownState<T> extends State<MultiselectDropDown<T>> {   
 
    final List<T> _listOFSelectedItem = [];

    String _elementToString(T e) => super.widget.labelFunction != null ? super.widget.labelFunction!(e) : e.toString();

    @override
    Widget build(BuildContext context) {
        return Container(
            margin: const EdgeInsets.only(top: 10.0),
            decoration: BoxDecoration(
                border: Border.all()
            ),
            child: ExpansionTile(
                title: Text(
                    this._listOFSelectedItem.isEmpty ? "Seleziona..." : this._listOFSelectedItem.map(
                        this._elementToString  
                    ).join(", "),
                    style: const TextStyle(
                        fontWeight: FontWeight.w400,
                        fontSize: 15.0
                    )
                ),
                children: <Widget>[
                    Column(
                        mainAxisSize: MainAxisSize.min,
                        children: super.widget.options.map((e) => _ViewItem(
                            label: this._elementToString(e),
                            item: e,
                            selected: (val) => super.setState(() {
                                if (this._listOFSelectedItem.contains(val))
                                    this._listOFSelectedItem.remove(val);
                                else
                                    this._listOFSelectedItem.add(val);
                                super.widget.onSelectChange(this._listOFSelectedItem);
                            }),
                            itemSelected: this._listOFSelectedItem.contains(e),
                        )).toList()
                    )
                ]
            ),
        );
    }
}

class _ViewItem<T> extends StatelessWidget {
    final T item;
    final String label;
    final bool itemSelected;
    final Function(T) selected;

    const _ViewItem({
        required this.item,
        required this.itemSelected,
        required this.selected,
        required this.label,
    });
    
    @override
    Widget build(BuildContext context) {
        return Padding(
            padding: const EdgeInsets.only(left: 10, right: 10, bottom: 5),
            child: Row(
                children: [
                    SizedBox(
                        height: 24.0,
                        width: 24.0,
                        child: Checkbox(
                            value: itemSelected,
                            onChanged: (val) => selected(item),
                            splashRadius: 9,
                        ),
                    ),
                    const SizedBox(width: 10),
                    Text(this.label,
                        style: const TextStyle(
                            fontWeight: FontWeight.w400,
                            fontSize: 17.0
                        )
                    )
                ]
            )
        );
    }
}
