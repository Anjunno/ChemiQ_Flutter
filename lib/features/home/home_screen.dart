import 'package:chemiq/data/models/submission_detail_dto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../auth/provider/auth_state_provider.dart';
import 'home_screen_view_model.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // 화면이 처음 렌더링된 후, 오늘의 미션 데이터를 불러옵니다.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(homeViewModelProvider.notifier).fetchTodayMission();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(homeViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ChemiQ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_edu_outlined),
            onPressed: () {
              context.push('/timeline');
            },
            tooltip: '타임라인 보기',
          ),
          IconButton(
            icon: const Icon(Icons.person_outline_rounded),
            onPressed: () => context.push('/mypage'),
            tooltip: '마이페이지',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              // 전역 AuthStateNotifier의 logout 메서드를 호출하여 안전하게 로그아웃 처리합니다.
              ref.read(authStateProvider.notifier).logout();
            },
            tooltip: '로그아웃',
          ),
        ],
        // TODO: 나중에 마이페이지 등으로 가는 버튼을 여기에 추가할 수 있습니다.
      ),
      // 화면을 아래로 당겨서 새로고침하는 기능을 추가합니다.
      body: RefreshIndicator(
        onRefresh: () => ref.read(homeViewModelProvider.notifier).fetchTodayMission(),
        child: _buildBody(state),
      ),
    );
  }

  // 화면의 본문을 상태에 따라 다르게 그리는 메서드입니다.
  Widget _buildBody(HomeState state) {
    // 로딩 중일 때
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    // 에러가 발생했을 때
    if (state.error != null) {
      return Center(
        child: Text(state.error!, style: const TextStyle(color: Colors.red)),
      );
    }
    // 미션이 없을 때
    if (state.dailyMission == null) {
      return const Center(
        child: Text(
          '오늘 할당된 미션이 없어요. 😌\n내일 다시 확인해주세요!',
          textAlign: TextAlign.center,
        ),
      );
    }

    // 데이터가 성공적으로 로드되었을 때
    final mission = state.dailyMission!;
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Text(
          DateFormat('yyyy년 MM월 dd일').format(mission.missionDate),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
        ),
        const SizedBox(height: 8),
        Text(
          mission.missionTitle,
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        const SizedBox(height: 24),
        // '나의 제출' 카드를 그립니다.
        _buildSubmissionCard(
          context: context,
          title: '나의 제출',
          submission: mission.mySubmission,
          onPressed: () {
            context.push(
              '/mission_submission/${mission.dailyMissionId}',
              extra: mission.missionTitle,
            );
          },
        ),
        const SizedBox(height: 16),
        // '파트너의 제출' 카드를 그립니다.
        _buildSubmissionCard(
          context: context,
          title: '파트너의 제출',
          submission: mission.partnerSubmission,
          onPressed: () { /* 파트너 카드는 버튼이 없으므로 비워둡니다 */ },
        ),
      ],
    );
  }

  /// '나의 제출' 또는 '파트너의 제출' 카드를 그리는 공통 위젯입니다.
  Widget _buildSubmissionCard({
    required BuildContext context,
    required String title,
    required SubmissionDetailDto? submission,
    required VoidCallback onPressed,
  }) {
    // 이 카드가 파트너의 카드인지 확인하는 변수입니다.
    bool isPartnerCard = title == '파트너의 제출';

    // InkWell 위젯으로 감싸서 탭 효과와 이벤트를 추가합니다.
    return InkWell(
      // 파트너의 카드이고, 제출물이 존재하며, 아직 내가 평가하지 않았을 경우에만 탭 이벤트를 활성화합니다.
      onTap: (isPartnerCard && submission != null && submission.score == null)
          ? () {
        // 평가 화면으로 이동합니다.
        // 경로에 제출물 ID를 포함하고, extra를 통해 제출물 전체 데이터를 전달합니다.
        context.push(
          '/evaluation/${submission.submissionId}',
          extra: submission,
        );
      }
          : null, // 조건이 맞지 않으면 탭 이벤트를 비활성화합니다.
      borderRadius: BorderRadius.circular(12), // 탭 효과가 카드 모양과 일치하도록 설정
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleLarge),
                  // ✨ 파트너 카드이고 제출물이 있을 때, 평가 여부에 따라 다른 위젯을 보여줍니다.
                  if (isPartnerCard && submission != null)
                    if (submission.score != null)
                    // 평가를 이미 했다면 별점을 보여줍니다.
                      _buildStarRating(submission.score!)
                    else
                    // 아직 평가하지 않았다면 '평가하기' 아이콘을 보여줍니다.
                      const Icon(Icons.edit_note_rounded, color: Colors.grey),
                ],
              ),
              const SizedBox(height: 16),
              // 제출물 유무에 따라 다른 위젯을 보여줍니다.
              if (submission == null)
                Center(
                  child: title == '나의 제출'
                      ? ElevatedButton.icon(
                    icon: const Icon(Icons.add_a_photo_outlined),
                    label: const Text('미션 제출하기'),
                    onPressed: onPressed,
                  )
                      : const Text('아직 제출하지 않았어요.'),
                )
              else
              // 제출물이 있을 경우, 이미지와 글 내용을 보여줍니다.
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        submission.imageUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: 200,
                        loadingBuilder: (context, child, progress) {
                          return progress == null ? child : const Center(child: CircularProgressIndicator());
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.broken_image, size: 48);
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(submission.content),
                    const SizedBox(height: 8),
                    Text(
                      DateFormat('yyyy.MM.dd HH:mm').format(submission.createdAt),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// ✨ 점수를 받아 별점 아이콘 목록을 만들어주는 헬퍼 위젯입니다.
  Widget _buildStarRating(double score) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        IconData icon;
        if (index >= score) {
          icon = Icons.star_border; // 빈 별
        } else if (index > score - 1 && index < score) {
          icon = Icons.star_half; // 반쪽 별
        } else {
          icon = Icons.star; // 꽉 찬 별
        }
        return Icon(icon, color: Colors.amber, size: 20);
      }),
    );
  }
}

