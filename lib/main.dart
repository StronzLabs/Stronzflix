import 'package:flutter/material.dart';
import 'package:stronzflix/stronzflix.dart';
import 'package:sutils/sutils.dart';

void main() async {
    WidgetsFlutterBinding.ensureInitialized();
    await SUtils.ensureInitialized();
    runApp(const Stronzflix());
} 
