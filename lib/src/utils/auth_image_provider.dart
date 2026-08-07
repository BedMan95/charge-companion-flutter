import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../api/api_client.dart';

class AuthNetworkImage extends ImageProvider<AuthNetworkImage> {
  const AuthNetworkImage(this.url, {this.scale = 1.0});

  final String url;
  final double scale;

  @override
  Future<AuthNetworkImage> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<AuthNetworkImage>(this);
  }

  @override
  ImageStreamCompleter loadImage(AuthNetworkImage key, ImageDecoderCallback decode) {
    final chunkEvents = StreamController<ImageChunkEvent>();

    return MultiFrameImageStreamCompleter(
      codec: _loadAsync(key, chunkEvents, decode),
      chunkEvents: chunkEvents.stream,
      scale: key.scale,
      informationCollector: () => <DiagnosticsNode>[
        DiagnosticsProperty<ImageProvider>('Image provider', this),
        DiagnosticsProperty<AuthNetworkImage>('Image key', key),
      ],
    );
  }

  Future<ui.Codec> _loadAsync(
    AuthNetworkImage key,
    StreamController<ImageChunkEvent> chunkEvents,
    ImageDecoderCallback decode,
  ) async {
    try {
      final token = await ApiClient.getToken();
      
      final response = await Dio().get<List<int>>(
        key.url,
        options: Options(
          responseType: ResponseType.bytes,
          headers: token != null ? {'Authorization': 'Bearer $token'} : null,
        ),
        onReceiveProgress: (int received, int total) {
          chunkEvents.add(ImageChunkEvent(
            cumulativeBytesLoaded: received,
            expectedTotalBytes: total,
          ));
        },
      );

      final bytes = Uint8List.fromList(response.data!);
      
      if (bytes.lengthInBytes == 0) {
        throw Exception('NetworkImage is an empty file: ${key.url}');
      }

      final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
      return decode(buffer);
    } catch (e) {
      scheduleMicrotask(() {
        chunkEvents.close();
      });
      rethrow;
    } finally {
      scheduleMicrotask(() {
        if (!chunkEvents.isClosed) {
          chunkEvents.close();
        }
      });
    }
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) return false;
    return other is AuthNetworkImage && other.url == url && other.scale == scale;
  }

  @override
  int get hashCode => Object.hash(url, scale);
}
