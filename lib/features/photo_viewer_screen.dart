import 'package:chemiq/core/ui/chemiq_toast.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gal/gal.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_view/photo_view.dart';

class PhotoViewerScreen extends StatefulWidget {
  final String imageUrl;

  const PhotoViewerScreen({super.key, required this.imageUrl});

  @override
  State<PhotoViewerScreen> createState() => _PhotoViewerScreenState();
}

class _PhotoViewerScreenState extends State<PhotoViewerScreen> {
  bool _isSaving = false;

  // ✨ 개선된 이미지 저장 로직
  Future<void> _saveImage() async {
    setState(() => _isSaving = true);

    // 1. 현재 권한 상태를 먼저 확인합니다.
    var status = await Permission.photos.status;

    // 2. 권한이 부여되지 않았다면, 사용자에게 요청합니다.
    if (!status.isGranted) {
      status = await Permission.photos.request();
    }

    // 3. 최종 권한 상태에 따라 분기 처리합니다.
    if (status.isGranted) {
      // 권한이 있으면 이미지 저장 시도
      try {
        final response = await Dio().get(
          widget.imageUrl,
          options: Options(responseType: ResponseType.bytes),
        );
        await Gal.putImageBytes(Uint8List.fromList(response.data));
        showChemiQToast('사진이 갤러리에 저장되었어요!', type: ToastType.success);
      } catch (e) {
        showChemiQToast('사진 저장에 실패했어요. 다시 시도해주세요.', type: ToastType.error);
      }
    } else if (status.isPermanentlyDenied) {
      // 권한이 영구적으로 거부되었다면, 설정으로 이동하도록 안내합니다.
      _showSettingsDialog();
    } else {
      // 권한이 단순히 거부되었다면, 토스트 메시지로 알려줍니다.
      showChemiQToast('사진을 저장하려면 앨범 접근 권한이 필요해요.', type: ToastType.error);
      _showSettingsDialog();
    }

    setState(() => _isSaving = false);
  }


  // ✨ 사용자를 앱 설정으로 안내하는 다이얼로그
  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('권한이 필요해요'),
        content: const Text('사진을 저장하기 위해 앨범 접근 권한이 필요합니다. 앱 설정 화면으로 이동하여 권한을 허용해주세요.'),
        actions: <Widget>[
          TextButton(
            child: const Text('취소'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: const Text('설정으로 이동'),
            onPressed: () {
              Navigator.of(context).pop();
              openAppSettings(); // permission_handler가 제공하는 설정 화면 이동 함수
            },
          ),
        ],
      ),
    );
  }

  // ✨ _requestPermission 헬퍼 함수는 _saveImage 로직에 통합되어 더 이상 필요하지 않습니다.

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          _isSaving
              ? const Padding(
            padding: EdgeInsets.only(right: 20.0),
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
            ),
          )
              : IconButton(
            icon: const Icon(Icons.download_for_offline_outlined),
            onPressed: _saveImage,
            tooltip: '사진 저장',
          ),
        ],
      ),
      body: PhotoView(
        imageProvider: NetworkImage(widget.imageUrl),
        minScale: PhotoViewComputedScale.contained,
        maxScale: PhotoViewComputedScale.covered * 2.0,
        heroAttributes: PhotoViewHeroAttributes(tag: widget.imageUrl),
      ),
    );
  }
}

