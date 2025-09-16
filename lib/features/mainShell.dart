import 'package:chemiq/features/timeline/timeline_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'home/home_screen.dart';
import 'mission_status/mission_status_screen.dart';
import 'mypage/mypage_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  // ✨ PageView에 표시될 화면 목록에 MissionStatusScreen을 추가합니다.
  final List<Widget> _pages = const [
    HomeScreen(),
    MissionStatusScreen(), // 미션 현황 화면 추가
    TimelineScreen(),
    MyPageScreen(),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // ✨ AppBar 제목 로직에 '미션 현황'을 추가합니다.
  String _getTitleForIndex(int index) {
    switch (index) {
      case 0:
        return 'ChemiQ';
      case 1:
        return '퀘스트 현황'; // 탭 제목 추가
      case 2:
        return '타임라인';
      case 3:
        return '마이페이지';
      default:
        return 'ChemiQ';
    }
  }

  Future<bool> _onWillPop(BuildContext context) async {
    if (_currentIndex != 0) {
      _pageController.animateToPage(0, duration: const Duration(milliseconds: 200), curve: Curves.easeInOut);
      return false;
    }
    final shouldExit = await showModalBottomSheet<bool>(
        context: context,
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (context) => _buildExitConfirmSheet(context));
    if (shouldExit == true) {
      SystemNavigator.pop();
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final isHomeTab = _currentIndex == 0;

    return WillPopScope(
      onWillPop: () => _onWillPop(context),
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            _getTitleForIndex(_currentIndex),
            style: isHomeTab
                ? TextStyle(fontFamily: 'Pretendard', fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)
                : null,
          ),
          centerTitle: true,
        ),
        body: PageView(
          controller: _pageController,
          onPageChanged: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          children: _pages,
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            _pageController.animateToPage(
              index,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
            );
          },
          // ✨ 하단 탭 아이템 목록에 '미션 현황'을 추가합니다.
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: '홈'),
            BottomNavigationBarItem(icon: Icon(Icons.check_circle_outline), activeIcon: Icon(Icons.check_circle), label: '퀘스트 현황'),
            BottomNavigationBarItem(icon: Icon(Icons.calendar_today_outlined), activeIcon: Icon(Icons.calendar_today), label: '타임라인'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: '마이페이지'),
          ],
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Theme.of(context).colorScheme.primary,
          unselectedItemColor: Colors.grey[600],
        ),
      ),
    );
  }

  Widget _buildExitConfirmSheet(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "ChemiQ를 종료하시겠어요?",
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Text(
            "앱이 완전히 종료됩니다.\n다시 사용하려면 재실행해야 해요.",
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Theme.of(context).colorScheme.outline),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text("취소"),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text("앱 종료"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

