import 'dart:io';

import 'package:flutter/material.dart';

class ResourceImage extends StatelessWidget {
    final Uri uri;
    final BoxFit? fit;
    final double? width;
    final double? height;
    final AlignmentGeometry alignment;
    
    const ResourceImage({
        super.key,
        required this.uri,
        this.fit,
        this.width,
        this.height,
        this.alignment = Alignment.center,
    });

    @override
    Widget build(BuildContext context) {
        return this.uri.scheme == "http" || this.uri.scheme == "https"
            ? Image.network(
                this.uri.toString(),
                fit: this.fit,
                width: this.width,
                height: this.height,
                alignment: this.alignment,
            )
            : Image.file(
                File.fromUri(uri),
                fit: this.fit,
                width: this.width,
                height: this.height,
                alignment: this.alignment,
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
