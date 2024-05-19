import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:stronzflix/stronzflix.dart';

void main() {
    MediaKit.ensureInitialized(); 
    runApp(const Stronzflix());
} 
