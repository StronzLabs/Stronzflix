import 'package:flutter/material.dart';

class LabeledCheckbox extends StatefulWidget {
    
    final Widget label;
    final void Function(bool)? onChanged;
    final bool initialValue;
    
    const LabeledCheckbox({
        super.key,
        required this.label,
        this.onChanged,
        required this.initialValue
    });

    @override
    State<StatefulWidget> createState() => _LabeledCheckboxState();

}

class _LabeledCheckboxState extends State<LabeledCheckbox> {

    late bool _checked = super.widget.initialValue;

    @override
    Widget build(BuildContext context) {
        return Row(
            children: [
                Checkbox(
                    value: this._checked,
                    onChanged: (value) {
                        super.setState(() => this._checked = value ?? false);
                        super.widget.onChanged?.call(this._checked);
                    },
                ),
                Flexible(
                    child: super.widget.label,
                )
            ],
        );
    }
}
