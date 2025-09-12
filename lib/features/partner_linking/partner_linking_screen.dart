import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'partner_linking_view_model.dart';

// 화면 전체를 상태 변화에 따라 다시 빌드할 필요가 없으므로 ConsumerStatefulWidget으로 변경
class PartnerLinkingScreen extends ConsumerStatefulWidget {
  const PartnerLinkingScreen({super.key});

  @override
  ConsumerState<PartnerLinkingScreen> createState() => _PartnerLinkingScreenState();
}

class _PartnerLinkingScreenState extends ConsumerState<PartnerLinkingScreen> {
  final partnerIdController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // 화면이 처음 빌드될 때 요청 목록을 불러옵니다.
    // addPostFrameCallback을 사용하여 빌드가 완료된 후 호출되도록 합니다.
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
      // ... 기존 스낵바 로직 (수정 없음) ...
    });

    final state = ref.watch(partnerLinkingViewModelProvider);
    final viewModel = ref.read(partnerLinkingViewModelProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('파트너 연결')),
      // 스크롤이 가능하도록 SingleChildScrollView로 감쌉니다.
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- 파트너 요청 보내기 UI ---
            const Text(
              '연결할 파트너의 아이디를 입력해주세요.',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: partnerIdController,
              decoration: const InputDecoration(labelText: '파트너 아이디', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: state.isRequesting ? null : () => viewModel.requestPartnership(partnerIdController.text.trim()),
              child: state.isRequesting ? const CircularProgressIndicator(color: Colors.white) : const Text('요청 보내기'),
            ),
            const Divider(height: 48),

            // --- 받은 요청 목록 UI ---
            const Text('받은 요청', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _buildRequestList(
              isLoading: state.areListsLoading,
              error: state.listError,
              itemCount: state.receivedRequests.length,
              itemBuilder: (context, index) {
                final request = state.receivedRequests[index];
                return Card(
                  child: ListTile(
                    title: Text('${request.requesterNickname}님의 요청'),
                    subtitle: Text(request.requesterId),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextButton(onPressed: () => viewModel.accept(request.partnershipId), child: const Text('수락')),
                        TextButton(onPressed: () => viewModel.reject(request.partnershipId), child: const Text('거절', style: TextStyle(color: Colors.red))),
                      ],
                    ),
                  ),
                );
              },
              emptyMessage: '받은 파트너 요청이 없어요.',
            ),
            const SizedBox(height: 32),

            // --- 보낸 요청 목록 UI ---
            const Text('보낸 요청', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _buildRequestList(
              isLoading: state.areListsLoading,
              error: state.listError,
              itemCount: state.sentRequests.length,
              itemBuilder: (context, index) {
                final request = state.sentRequests[index];
                return Card(
                  child: ListTile(
                    title: Text('${request.addresseeNickname}님에게 보낸 요청'),
                    subtitle: Text(request.addresseeId),
                    trailing: request.status == 'PENDING'
                        ? TextButton(onPressed: () => viewModel.cancel(request.partnershipId), child: const Text('취소'))
                        : Text(request.status, style: TextStyle(color: Colors.grey.shade600)),
                  ),
                );
              },
              emptyMessage: '보낸 파트너 요청이 없어요.',
            ),
          ],
        ),
      ),
    );
  }

  // 목록 UI를 그리는 공통 위젯
  Widget _buildRequestList({
    required bool isLoading,
    String? error,
    required int itemCount,
    required Widget Function(BuildContext, int) itemBuilder,
    required String emptyMessage,
  }) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (error != null) {
      return Center(child: Text(error, style: const TextStyle(color: Colors.red)));
    }
    if (itemCount == 0) {
      return Center(child: Text(emptyMessage, style: TextStyle(color: Colors.grey.shade600)));
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      itemBuilder: itemBuilder,
    );
  }
}

