import 'dart:io';

import 'package:flutter/material.dart';

class ResourceImage extends StatelessWidget {
    final Uri uri;
    final BoxFit? fit;
    
    const ResourceImage({
        super.key,
        required this.uri,
        this.fit
    });

    @override
    Widget build(BuildContext context) {
        return this.uri.scheme == "http" || this.uri.scheme == "https"
            ? Image.network(
                this.uri.toString(),
                fit: this.fit,
            )
            : Image.file(
                File.fromUri(uri),
                fit: this.fit,
            );
    }
}

ImageProvider<Object> resourceImageProvider({required Uri uri}) {
    return uri.scheme == "http" || uri.scheme == "https"
        ? NetworkImage(
            uri.toString(),
        ) as ImageProvider<Object>
        : FileImage(
            File.fromUri(uri),
        ) as ImageProvider<Object>;
}
