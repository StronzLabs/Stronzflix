import 'dart:async';

import 'package:flutter/material.dart';

class LoadingDialog {
    static LoadedData<T> load<T>(Future<T> future) {
        return LoadedData(future: future);
    }
}

class LoadedData<T> {
    final Future<T> future;
    
    const LoadedData({required this.future});

    Future<R> then<R>(FutureOr<R> Function(T) onValue, {Function? onError}) {
        return future.then(onValue, onError: onError);
    }

    void thenPush(BuildContext context, Widget Function(BuildContext, T) builder) {
        showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const Dialog(
                backgroundColor: Colors.transparent,
                child: Center(
                    child: CircularProgressIndicator(),
                )
            )
        );
        this.future.then((value) {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (context) => builder(context, value)));
        });
    }
}
