import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stronzflix/utils/initializable.dart';

abstract class LocalStorage extends Initializable {
    late final SharedPreferences _prefs;

    final Map<String, dynamic> _data;
    dynamic operator [](String key) => this._data[key]!;
    operator []=(String key, dynamic value) => this._data[key] = value;

    LocalStorage(this._data);

    @override
    @mustCallSuper
    Future<void> construct() async {
        this._prefs = await SharedPreferences.getInstance();
        for (var key in this._data.keys) {
            if (this._data[key] is String)
                this._data[key] = this._prefs.getString(key) ?? this._data[key]!;
            else if(this._data[key] is List<String>)
                this._data[key] = this._prefs.getStringList(key) ?? this._data[key]!;
            else if(this._data[key] is double)
                this._data[key] = this._prefs.getDouble(key) ?? this._data[key]!;
            else
                throw Exception("Invalid data type");
        }
    }

    @mustCallSuper
    Future<void> save() async {
        for (var key in this._data.keys)
            if (this._data[key] is String)
                await this._prefs.setString(key, this._data[key]);
            else if(this._data[key] is List<String>)
                await this._prefs.setStringList(key, this._data[key]);
            else if(this._data[key] is double)
                await this._prefs.setDouble(key, this._data[key]);
            else
                throw Exception("Invalid data type");
    }
}