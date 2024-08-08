import 'package:flutter/material.dart';
import 'package:stronzflix/stronzflix.dart';
import 'package:stronzflix/utils/platform.dart';

void main() async {
    WidgetsFlutterBinding.ensureInitialized();
    await SPlatform.checkTV();
    runApp(const Stronzflix());
} 
