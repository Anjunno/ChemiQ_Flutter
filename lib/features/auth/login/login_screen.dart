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

  // ✨ 각 TextField의 포커스를 관리하기 위한 FocusNode를 추가합니다.
  late final FocusNode _idFocusNode;
  late final FocusNode _passwordFocusNode;

  @override
  void initState() {
    super.initState();
    _memberIdController = TextEditingController();
    _passwordController = TextEditingController();

    _idFocusNode = FocusNode();
    _passwordFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _memberIdController.dispose();
    _passwordController.dispose();
    _idFocusNode.dispose();
    _passwordFocusNode.dispose();
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
        child: SafeArea(
          child: SingleChildScrollView(
            child: SizedBox(
              height: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Column(
                  children: [
                    const Spacer(flex: 2),
                    _buildHeader(context, textTheme),
                    const SizedBox(height: 48),
                    // FocusNode를 전달합니다.
                    _buildLoginForm(context, _memberIdController, _passwordController),
                    const SizedBox(height: 24),
                    PrimaryButton(
                      text: '로그인',
                      isLoading: loginState.isLoading,
                      onPressed: () async {
                        // 로그인 버튼을 누르면 키보드가 내려가도록 합니다.
                        _passwordFocusNode.unfocus();
                        await loginViewModel.login(
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

  Widget _buildHeader(BuildContext context, TextTheme textTheme) {
    return Column(
      children: [
        const SizedBox(height: 16),
        Image.asset(
          'assets/images/chemiQQ_clear.png',
          height: 100,
          // color: Theme.of(context).colorScheme.primary,
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

  // ✨ FocusNode를 사용하여 키보드 동작을 제어합니다.
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
          focusNode: _idFocusNode,
          decoration: const InputDecoration(
            hintText: '아이디',
            // ✨ 아이디 필드에 아이콘 추가
            prefixIcon: Icon(Icons.person_outline),
          ),
          // 키보드의 '완료' 버튼을 '다음' 버튼으로 변경합니다.
          textInputAction: TextInputAction.next,
          // '다음' 버튼을 누르면 비밀번호 필드로 포커스를 이동시킵니다.
          onEditingComplete: () => _passwordFocusNode.requestFocus(),
        ),
        const SizedBox(height: 16),
        Text('비밀번호', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[700])),
        const SizedBox(height: 8),
        TextField(
          controller: pwController,
          focusNode: _passwordFocusNode,
          obscureText: !_isPasswordVisible,
          decoration: InputDecoration(
            hintText: '비밀번호',
            // ✨ 비밀번호 필드에 아이콘 추가
            prefixIcon: const Icon(Icons.lock_outline),
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
          // 키보드의 '완료' 버튼을 누르면 키보드를 내립니다.
          onEditingComplete: () => _passwordFocusNode.unfocus(),
        ),
      ],
    );
  }

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

