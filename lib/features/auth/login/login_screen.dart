import 'package:chemiq/core/ui/chemiq_toast.dart';
import 'package:chemiq/core/ui/widgets/primary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'login_view_model.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  late final TextEditingController _memberIdController;
  late final TextEditingController _passwordController;
  bool _isPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _memberIdController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _memberIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loginState = ref.watch(loginViewModelProvider);
    final loginViewModel = ref.read(loginViewModelProvider.notifier);

    ref.listen(loginViewModelProvider, (previous, next) {
      if (next.error != null) {
        showChemiQToast(next.error!, type: ToastType.error);
      }
    });

    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        // ✨ 레이아웃 구조를 더 단순하고 안정적인 방식으로 변경합니다.
        child: SafeArea(
          child: SingleChildScrollView(
            child: SizedBox(
              // 화면의 최소 높이를 실제 기기 높이로 설정하여 Column이 수직 정렬될 공간을 확보합니다.
              height: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Column(
                  children: [
                    const Spacer(flex: 2),
                    _buildHeader(context, textTheme),
                    const SizedBox(height: 48),
                    _buildLoginForm(context, _memberIdController, _passwordController),
                    const SizedBox(height: 24),
                    PrimaryButton(
                      text: '로그인',
                      isLoading: loginState.isLoading,
                      onPressed: () {
                        loginViewModel.login(
                          _memberIdController.text.trim(),
                          _passwordController.text.trim(),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    _buildSignUpLink(context),
                    const Spacer(),
                    const Text(
                      'ChemiQ와 함께',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ✨ 1. 로고와 슬로건을 표시하는 위젯
  Widget _buildHeader(BuildContext context, TextTheme textTheme) {
    return Column(
      children: [
        const SizedBox(height: 16),
        // ✨ 로고 이미지를 표시합니다. (assets/images/chemiq_logo_text.png 파일 필요)
        Image.asset(
          'assets/images/chemiq_logo-cr.png',
          height: 100,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 12),
        Text(
          '함께 달성하는 특별한 습관',
          style: textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(
          '로그인하여 파트너와 미션을 시작해요!',
          style: textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
        ),
      ],
    );
  }

  // ✨ 2. 아이디와 비밀번호 입력 폼 위젯
  Widget _buildLoginForm(
      BuildContext context,
      TextEditingController idController,
      TextEditingController pwController,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('아이디', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[700])),
        const SizedBox(height: 8),
        TextField(
          controller: idController,
          decoration: const InputDecoration(
            hintText: '아이디',
          ),
        ),
        const SizedBox(height: 16),
        Text('비밀번호', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[700])),
        const SizedBox(height: 8),
        TextField(
          controller: pwController,
          obscureText: !_isPasswordVisible,
          decoration: InputDecoration(
            hintText: '비밀번호',
            suffixIcon: IconButton(
              icon: Icon(
                _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                color: Colors.grey,
              ),
              onPressed: () {
                setState(() {
                  _isPasswordVisible = !_isPasswordVisible;
                });
              },
            ),
          ),

        ),
      ],
    );
  }

  // ✨ 4. 회원가입 페이지로 이동하는 링크 위젯
  Widget _buildSignUpLink(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '아직 계정이 없으신가요?',
          style: TextStyle(color: Colors.grey[600]),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => context.push('/signup'),
          child: Text(
            '회원가입하기',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }
}

