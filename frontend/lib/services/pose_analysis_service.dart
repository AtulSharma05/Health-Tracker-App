import 'dart:async';
import 'dart:convert';
import 'package:camera/camera.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import '../config/api_config.dart';

class PoseAnalysisService {
  WebSocketChannel? _channel;
  final StreamController<PoseAnalysisResult> _resultsController = 
      StreamController<PoseAnalysisResult>.broadcast();
  final StreamController<Map<String, dynamic>> _summaryController =
      StreamController<Map<String, dynamic>>.broadcast();
  
  bool _isConnected = false;
  String? _currentExercise;
  
  Stream<PoseAnalysisResult> get resultsStream => _resultsController.stream;
  bool get isConnected => _isConnected;
  String? get currentExercise => _currentExercise;

  /// Connect to the pose analysis WebSocket
  Future<bool> connect() async {
    try {
      final wsUrl = ApiConfig.poseWebSocketUrl;
      debugPrint('Connecting to pose analysis: $wsUrl');
      
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      
      _channel!.stream.listen(
        (data) {
          try {
            debugPrint('Received message: $data');
            final Map<String, dynamic> message = json.decode(data);
            
            if (message['type'] == 'analysis') {
              final result = PoseAnalysisResult.fromJson(message['data']);
              _resultsController.add(result);
            } else if (message['type'] == 'summary') {
              _summaryController.add(message['data'] as Map<String, dynamic>);
            } else if (message['type'] == 'error') {
              debugPrint('Server error: ${message['message']}');
              _resultsController.addError(message['message'] ?? 'Unknown error');
            }
          } catch (e) {
            debugPrint('Error parsing pose analysis message: $e');
          }
        },
        onError: (error) {
          debugPrint('WebSocket error: $error');
          _isConnected = false;
        },
        onDone: () {
          debugPrint('WebSocket connection closed');
          _isConnected = false;
        },
      );
      
      _isConnected = true;
      debugPrint('WebSocket connected successfully');
      return true;
    } catch (e) {
      debugPrint('Failed to connect to pose analysis: $e');
      _isConnected = false;
      return false;
    }
  }

  /// Set the exercise to analyze
  Future<void> setExercise(String exerciseName) async {
    if (!_isConnected) {
      throw Exception('Not connected to pose analysis service');
    }
    
    _currentExercise = exerciseName;
    
    final message = {
      'type': 'set_exercise',
      'exercise_name': exerciseName,
    };
    
    debugPrint('🏋️ Setting exercise to: $exerciseName');
    debugPrint('📤 Sending message: ${json.encode(message)}');
    _channel?.sink.add(json.encode(message));
    debugPrint('✅ Exercise message sent');
  }

  /// Send a frame for analysis
  Future<void> sendFrame(CameraImage image) async {
    if (!_isConnected) {
      debugPrint('Not connected, skipping frame');
      return;
    }
    
    try {
      // Convert CameraImage to base64
      final base64Frame = await _convertImageToBase64(image);
      
      final message = {
        'type': 'frame',
        'frame': base64Frame,
      };
      
      _channel?.sink.add(json.encode(message));
      debugPrint('Frame sent to server');
    } catch (e) {
      debugPrint('Error sending frame: $e');
    }
  }

  /// Get session summary
  Future<Map<String, dynamic>?> getSessionSummary() async {
    if (!_isConnected) return null;
    
    final completer = Completer<Map<String, dynamic>?>();
    
    // Listen for summary response
    StreamSubscription? subscription;
    subscription = _summaryController.stream.listen((data) {
      if (!completer.isCompleted) {
        completer.complete(data);
        subscription?.cancel();
      }
    });
    
    // Request summary
    final message = {'type': 'get_summary'};
    _channel?.sink.add(json.encode(message));
    debugPrint('Requested session summary');
    
    // Timeout after 5 seconds
    return completer.future.timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        subscription?.cancel();
        debugPrint('Summary request timed out');
        return null;
      },
    );
  }

  /// Reset the current session
  Future<void> resetSession() async {
    if (!_isConnected) return;
    
    final message = {'type': 'reset'};
    _channel?.sink.add(json.encode(message));
    _currentExercise = null;
  }

  /// Disconnect from the service
  void disconnect() {
    _channel?.sink.close();
    _isConnected = false;
    _currentExercise = null;
  }

  /// Convert CameraImage to base64 string
  Future<String> _convertImageToBase64(CameraImage image) async {
    try {
      img.Image? convertedImage;
      
      // Handle different image formats
      if (image.format.group == ImageFormatGroup.yuv420) {
        convertedImage = _convertYUV420(image);
      } else if (image.format.group == ImageFormatGroup.bgra8888) {
        convertedImage = _convertBGRA8888(image);
      } else {
        throw UnsupportedError('Unsupported format: ${image.format.group}');
      }
      
      if (convertedImage == null) {
        throw Exception('Failed to convert image');
      }
      
      // Encode to JPEG with quality 85
      final jpegBytes = img.encodeJpg(convertedImage, quality: 85);
      
      // Convert to base64
      return base64Encode(jpegBytes);
    } catch (e) {
      debugPrint('Error converting image: $e');
      rethrow;
    }
  }

  img.Image? _convertYUV420(CameraImage image) {
    final int width = image.width;
    final int height = image.height;
    
    final img.Image imgImage = img.Image(width: width, height: height);
    
    final int uvRowStride = image.planes[1].bytesPerRow;
    final int uvPixelStride = image.planes[1].bytesPerPixel ?? 1;
    
    for (int h = 0; h < height; h++) {
      for (int w = 0; w < width; w++) {
        final int uvIndex = uvPixelStride * (w / 2).floor() + uvRowStride * (h / 2).floor();
        final int index = h * width + w;
        
        final y = image.planes[0].bytes[index];
        final u = image.planes[1].bytes[uvIndex];
        final v = image.planes[2].bytes[uvIndex];
        
        // YUV to RGB conversion
        int r = (y + v * 1436 / 1024 - 179).round().clamp(0, 255);
        int g = (y - u * 46549 / 131072 + 44 - v * 93604 / 131072 + 91).round().clamp(0, 255);
        int b = (y + u * 1814 / 1024 - 227).round().clamp(0, 255);
        
        imgImage.setPixelRgb(w, h, r, g, b);
      }
    }
    
    return imgImage;
  }
  
  img.Image? _convertBGRA8888(CameraImage image) {
    final bytes = image.planes[0].bytes;
    return img.Image.fromBytes(
      width: image.width,
      height: image.height,
      bytes: bytes.buffer,
      order: img.ChannelOrder.bgra,
    );
  }

  void dispose() {
    disconnect();
    _resultsController.close();
    _summaryController.close();
  }
}

class PoseAnalysisResult {
  final int repCount;
  final String phase;
  final double confidence;
  final List<String> feedback;
  final Map<String, dynamic>? formAnalysis;
  final double fps;

  PoseAnalysisResult({
    required this.repCount,
    required this.phase,
    required this.confidence,
    required this.feedback,
    this.formAnalysis,
    required this.fps,
  });

  factory PoseAnalysisResult.fromJson(Map<String, dynamic> json) {
    return PoseAnalysisResult(
      repCount: json['rep_count'] ?? 0,
      phase: json['phase'] ?? 'unknown',
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      feedback: (json['feedback'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      formAnalysis: json['form_analysis'] as Map<String, dynamic>?,
      fps: (json['fps'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rep_count': repCount,
      'phase': phase,
      'confidence': confidence,
      'feedback': feedback,
      'form_analysis': formAnalysis,
      'fps': fps,
    };
  }
}
