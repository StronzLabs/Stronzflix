import 'package:flutter/material.dart';

class SelectDropDown<T> extends StatefulWidget {
    final String label;
    final List<T> options;
    final T? selectedValue;
    final Function(T) onSelected;
    final String Function(T)? stringify;
    
    const SelectDropDown({
        super.key,
        required this.label,
        required this.options,
        required this.selectedValue,
        required this.onSelected,
        this.stringify,
    });
    
    @override
    State<SelectDropDown<T>> createState() => _SelectDropDownState<T>();
}
    
class _SelectDropDownState<T> extends State<SelectDropDown<T>> {   
 
    late T? _selectedValue = super.widget.selectedValue;
    final ExpansionTileController _controller = ExpansionTileController();

    String _elementToString(T e) => super.widget.stringify != null ? super.widget.stringify!(e) : e.toString();


    @override
    Widget build(BuildContext context) {
        return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                Text(super.widget.label,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold
                    )
                ),
                const SizedBox(height: 10),
                Container(
                    decoration: BoxDecoration(
                        border: Border.all()
                    ),
                    child: ExpansionTile(
                        controller: this._controller,
                        title: Text(this._selectedValue == null
                            ? "Seleziona"
                            : this._elementToString(this._selectedValue as T)),
                        children: <Widget>[
                            Column(
                                mainAxisSize: MainAxisSize.min,
                                children: super.widget.options.where((element) => element != this._selectedValue) .map((e) => ListTile(
                                    title: Text(this._elementToString(e)),
                                    onTap: () {
                                        super.setState(() => this._selectedValue = e);
                                        super.widget.onSelected(e);
                                        this._controller.collapse();
                                    }
                                )).toList()
                            )
                        ]
                    ),
                )
            ],
        );
    }
}
