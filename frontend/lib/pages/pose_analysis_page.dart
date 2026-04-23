import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/pose_analysis_service.dart';

class PoseAnalysisPage extends StatefulWidget {
  final String? exerciseName;

  const PoseAnalysisPage({super.key, this.exerciseName});

  @override
  State<PoseAnalysisPage> createState() => _PoseAnalysisPageState();
}

class _PoseAnalysisPageState extends State<PoseAnalysisPage> {
  CameraController? _cameraController;
  final PoseAnalysisService _poseService = PoseAnalysisService();
  
  bool _isInitializing = true;
  bool _isProcessing = false;
  String? _error;
  
  PoseAnalysisResult? _currentResult;
  int _repCount = 0;
  String _phase = 'Ready';
  List<String> _feedback = [];
  double _fps = 0.0;
  
  Timer? _frameTimer;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        setState(() {
          _error = 'Camera permission denied';
          _isInitializing = false;
        });
        return;
      }

      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() {
          _error = 'No cameras found';
          _isInitializing = false;
        });
        return;
      }

      final camera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        camera,
        ResolutionPreset.high,  // Changed from medium to high for better pose detection
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      await _cameraController!.initialize();

      final connected = await _poseService.connect();
      if (!connected) {
        setState(() {
          _error = 'Failed to connect to pose analysis service';
          _isInitializing = false;
        });
        return;
      }

      if (widget.exerciseName != null) {
        debugPrint('🎯 Setting exercise: ${widget.exerciseName}');
        await _poseService.setExercise(widget.exerciseName!);
      } else {
        // Default to push-up if no exercise specified
        debugPrint('🎯 No exercise specified, defaulting to push-up');
        await _poseService.setExercise('push-up');
      }

      _poseService.resultsStream.listen(
        (result) {
          debugPrint('📊 Received result: Reps=${result.repCount}, Phase=${result.phase}');
          if (mounted) {
            setState(() {
              _currentResult = result;
              _repCount = result.repCount;
              _phase = result.phase;
              _feedback = result.feedback;
              _fps = result.fps;
            });
          }
        },
        onError: (error) {
          debugPrint('❌ Pose analysis error: $error');
        },
      );

      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }

      _startFrameStreaming();
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to initialize: $e';
          _isInitializing = false;
        });
      }
    }
  }

  void _startFrameStreaming() {
    if (_cameraController?.value.isInitialized != true) {
      debugPrint('❌ Camera not initialized, cannot start streaming');
      return;
    }
    
    debugPrint('📹 Starting frame streaming...');
    _cameraController!.startImageStream((CameraImage image) async {
      if (!_isProcessing) {
        _isProcessing = true;
        try {
          debugPrint('📤 Sending frame: ${image.width}x${image.height}, format: ${image.format.group}');
          await _poseService.sendFrame(image);
        } catch (e) {
          debugPrint('❌ Error sending frame: $e');
        } finally {
          // Add small delay to avoid overwhelming the server (10 FPS)
          await Future.delayed(const Duration(milliseconds: 100));
          _isProcessing = false;
        }
      }
    });
  }

  Future<void> _resetSession() async {
    await _poseService.resetSession();
    if (mounted) {
      setState(() {
        _repCount = 0;
        _phase = 'Ready';
        _feedback = [];
        _currentResult = null;
      });
    }
  }

  Future<void> _finishWorkout() async {
    final summary = await _poseService.getSessionSummary();
    
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Workout Complete'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total Reps: $_repCount'),
            if (summary != null) ...[
              const SizedBox(height: 8),
              Text('Duration: ${summary['duration'] ?? 'N/A'}'),
              Text('Form Score: ${summary['avg_form_score'] ?? 'N/A'}'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context, _repCount);
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _frameTimer?.cancel();
    if (_cameraController?.value.isStreamingImages == true) {
      _cameraController?.stopImageStream().catchError((_) {});
    }
    _cameraController?.dispose();
    _poseService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          widget.exerciseName ?? 'Pose Analysis',
          style: const TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetSession,
          ),
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _finishWorkout,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isInitializing) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(_error!, style: const TextStyle(color: Colors.white)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Go Back'),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        if (_cameraController?.value.isInitialized == true)
          SizedBox.expand(child: CameraPreview(_cameraController!)),
        SafeArea(
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    const Text('REPS', style: TextStyle(color: Colors.white70)),
                    Text('$_repCount', style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(_phase, style: const TextStyle(color: Colors.white, fontSize: 16)),
              ),
              const Spacer(),
              if (_feedback.isNotEmpty)
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('FORM TIPS', style: TextStyle(color: Colors.amber)),
                      const SizedBox(height: 8),
                      ..._feedback.map((tip) => Text('• $tip', style: const TextStyle(color: Colors.white70))),
                    ],
                  ),
                ),
              Text('${_fps.toStringAsFixed(1)} FPS', style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }
}
