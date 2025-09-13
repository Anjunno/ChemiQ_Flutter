import 'package:cached_network_image/cached_network_image.dart';
import 'package:chemiq/core/ui/chemiq_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'partner_linking_view_model.dart';

class PartnerLinkingScreen extends ConsumerStatefulWidget {
  const PartnerLinkingScreen({super.key});

  @override
  ConsumerState<PartnerLinkingScreen> createState() => _PartnerLinkingScreenState();
}

class _PartnerLinkingScreenState extends ConsumerState<PartnerLinkingScreen> {
  final partnerIdController = TextEditingController();
  int _selectedTabIndex = 0; // 0: 받은 요청, 1: 보낸 요청

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(partnerLinkingViewModelProvider.notifier).fetchRequests();
    });
  }

  @override
  void dispose() {
    partnerIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(partnerLinkingViewModelProvider, (previous, next) {
      if (next.requestSuccess) {
        showChemiQToast('파트너 요청을 성공적으로 보냈어요! ', type: ToastType.success);
        partnerIdController.clear();
      }
      if (next.requestError != null) {
        showChemiQToast(next.requestError!, type: ToastType.error);
      }
    });

    final state = ref.watch(partnerLinkingViewModelProvider);
    final viewModel = ref.read(partnerLinkingViewModelProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('파트너 연결하기')),
      // ✨ 1. 화면 전체를 RefreshIndicator로 감싸 새로고침 기능을 추가합니다.
      body: RefreshIndicator(
        onRefresh: () => viewModel.fetchRequests(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(), // 스크롤이 항상 가능하도록 설정
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // --- 새로운 파트너 초대 섹션 ---
              _buildInviteCard(state, viewModel),
              const SizedBox(height: 24),

              // --- 받은 요청 / 보낸 요청 탭 ---
              _buildRequestTabs(state),
              const SizedBox(height: 16),

              // --- 선택된 탭에 따른 목록 표시 ---
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _selectedTabIndex == 0
                    ? _buildReceivedRequestList(state, viewModel)
                    : _buildSentRequestList(state, viewModel),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInviteCard(PartnerLinkingState state, PartnerLinkingViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          )
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            ),
            child: Icon(Icons.person_add_alt_1_outlined,
                color: Theme.of(context).colorScheme.primary, size: 28),
          ),
          const SizedBox(height: 12),
          Text(
            '새로운 파트너 초대하기',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            '파트너의 아이디를 입력해서 함께 미션을 시작해보세요!',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: partnerIdController,
                  decoration: InputDecoration(
                    hintText: '파트너 아이디를 입력하세요',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: state.isRequesting
                    ? null
                    : () => viewModel.requestPartnership(partnerIdController.text.trim()),
                style: ElevatedButton.styleFrom(
                  // ✨ 버튼 높이를 TextField와 맞추기 위해 padding 수정
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('요청 보내기'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRequestTabs(PartnerLinkingState state) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          _buildTabItem('받은 요청', 0, state.receivedRequests.length),
          _buildTabItem('보낸 요청', 1, state.sentRequests.length),
        ],
      ),
    );
  }

  Widget _buildTabItem(String title, int index, int count) {
    final isSelected = _selectedTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTabIndex = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : Colors.grey.shade600,
                ),
              ),
              if (count > 0) ...[
                const SizedBox(width: 6),
                CircleAvatar(
                  radius: 10,
                  backgroundColor: isSelected ? Colors.white : Colors.grey.shade400,
                  child: Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Theme.of(context).colorScheme.primary : Colors.white,
                    ),
                  ),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReceivedRequestList(PartnerLinkingState state, PartnerLinkingViewModel viewModel) {
    if (state.areListsLoading) return const Center(child: CircularProgressIndicator());
    if (state.receivedRequests.isEmpty) return const Center(child: Text('받은 요청이 없어요.'));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('받은 요청', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: state.receivedRequests.length,
          itemBuilder: (context, index) {
            final request = state.receivedRequests[index];
            return Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person)), // 프로필 사진
                title: Text('${request.requesterNickname}'),
                subtitle: const Text('요청을 받았어요'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ✨ 2. 일관성 있고 작은 버튼으로 수정합니다.
                    TextButton(
                      onPressed: () => viewModel.accept(request.partnershipId),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Theme.of(context).colorScheme.secondary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('수락'),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () => viewModel.reject(request.partnershipId),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey.shade700,
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('거절'),
                    ),
                  ],
                ),
              ),
            );
          },
        )
      ],
    );
  }

  Widget _buildSentRequestList(PartnerLinkingState state, PartnerLinkingViewModel viewModel) {
    if (state.areListsLoading) return const Center(child: CircularProgressIndicator());
    if (state.sentRequests.isEmpty) return const Center(child: Text('보낸 요청이 없어요.'));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('보낸 요청', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: state.sentRequests.length,
          itemBuilder: (context, index) {
            final request = state.sentRequests[index];
            return Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person)), // 프로필 사진
                title: Text('${request.addresseeNickname}'),
                subtitle: const Text('요청을 보냈어요'),
                trailing: request.status == 'PENDING'
                    ? TextButton(
                  onPressed: () => viewModel.cancel(request.partnershipId),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey.shade700,
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('취소'),
                )
                    : Text("거절됨", style: TextStyle(color: Colors.grey.shade600)),
              ),
            );
          },
        )
      ],
    );
  }
}

