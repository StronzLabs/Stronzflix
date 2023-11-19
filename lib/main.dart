import 'package:flutter/material.dart';
import 'package:stronzflix/backend/streamingcommunity.dart';
import 'package:stronzflix/backend/vixxcloud.dart';
import 'package:stronzflix/stronzflix.dart';
import 'package:fvp/fvp.dart';

void main() {
    StreamingCommunity.instance;
    VixxCloud.instance;
    registerWith(options: {'platforms': ['android', 'linux', 'windows']});
    runApp(const Stronzflix());
}
