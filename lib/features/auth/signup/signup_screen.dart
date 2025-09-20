import 'package:chemiq/core/ui/chemiq_toast.dart';
import 'package:chemiq/core/ui/widgets/primary_button.dart';
import 'package:chemiq/styles/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'signup_view_model.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _idController = TextEditingController();
  final _pwController = TextEditingController();
  final _pwConfirmController = TextEditingController();
  final _nicknameController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  // ✨ 각 TextField의 포커스를 관리하기 위한 FocusNode 추가
  final _idFocus = FocusNode();
  final _pwFocus = FocusNode();
  final _pwConfirmFocus = FocusNode();
  final _nicknameFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    final viewModel = ref.read(signUpViewModelProvider.notifier);
    _idController.addListener(() => viewModel.validateId(_idController.text));
    _pwController.addListener(() => viewModel.validatePassword(_pwController.text));
    _pwConfirmController.addListener(() => viewModel.validateConfirmPassword(_pwConfirmController.text));
    _nicknameController.addListener(() => viewModel.validateNickname(_nicknameController.text));
  }

  @override
  void dispose() {
    _idController.dispose();
    _pwController.dispose();
    _pwConfirmController.dispose();
    _nicknameController.dispose();
    // ✨ FocusNode도 dispose 처리
    _idFocus.dispose();
    _pwFocus.dispose();
    _pwConfirmFocus.dispose();
    _nicknameFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(signUpViewModelProvider);
    final viewModel = ref.read(signUpViewModelProvider.notifier);

    ref.listen(signUpViewModelProvider, (previous, next) {
      if (next.signUpSuccess) {
        showChemiQToast('회원가입 성공! 로그인 해주세요.', type: ToastType.success);
        context.pop();
      }
      if (next.errorMessage != null) {
        showChemiQToast(next.errorMessage!, type: ToastType.error);
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('회원가입')),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(context),
              const SizedBox(height: 32),

              // 아이디 필드
              _buildTextField(
                controller: _idController,
                focusNode: _idFocus,
                label: '아이디',
                hintText: '아이디',
                prefixIcon: const Icon(Icons.person_outline),
                helperWidget: _buildIdHelperText(state),
                maxLength: 12,
                textInputAction: TextInputAction.next,
                onEditingComplete: () => _pwFocus.requestFocus(),
              ),
              const SizedBox(height: 24),
              // 비밀번호 필드
              _buildTextField(
                controller: _pwController,
                focusNode: _pwFocus,
                label: '비밀번호',
                hintText: '비밀번호',
                prefixIcon: const Icon(Icons.lock_outline),
                obscureText: !_isPasswordVisible,
                helperWidget: _buildPasswordRequirements(state.passwordRequirements),
                maxLength: 12,
                textInputAction: TextInputAction.next,
                onEditingComplete: () => _pwConfirmFocus.requestFocus(),
                suffixIcon: IconButton(
                  icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off, color: Colors.grey),
                  onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                ),
              ),
              const SizedBox(height: 24),
              // 비밀번호 확인 필드
              _buildTextField(
                controller: _pwConfirmController,
                focusNode: _pwConfirmFocus,
                label: '비밀번호 확인',
                hintText: '비밀번호 확인',
                prefixIcon: const Icon(Icons.lock_outline),
                obscureText: !_isConfirmPasswordVisible,
                helperWidget: _buildConfirmPasswordHelperText(state),
                maxLength: 12,
                textInputAction: TextInputAction.next,
                onEditingComplete: () => _nicknameFocus.requestFocus(),
                suffixIcon: IconButton(
                  icon: Icon(_isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off, color: Colors.grey),
                  onPressed: () => setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
                ),
              ),
              const SizedBox(height: 24),
              // 닉네임 필드
              _buildTextField(
                controller: _nicknameController,
                focusNode: _nicknameFocus,
                label: '닉네임',
                hintText: '닉네임',
                prefixIcon: const Icon(Icons.badge_outlined),
                helperWidget: _buildNicknameHelperText(state),
                maxLength: 6,
                textInputAction: TextInputAction.done,
                onEditingComplete: () {
                  _nicknameFocus.unfocus();
                  if (state.isFormValid) viewModel.signUp();
                },
              ),
              const SizedBox(height: 40),
              // 가입하기 버튼
              PrimaryButton(
                text: '가입하기',
                isLoading: state.isLoading,
                onPressed: state.isFormValid ? () => viewModel.signUp() : null,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      children: [
        const SizedBox(height: 16),
        Image.asset(
          'assets/images/cr.png',
          height: 50,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 12),
        Text(
          '새로운 여정을 시작해요',
          style: textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(
          '파트너와 함께 특별한 습관을 만들어보세요!',
          style: textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
        ),
      ],
    );
  }

  // ✨ FocusNode, textInputAction, onEditingComplete, prefixIcon 파라미터 추가
  Widget _buildTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    String? hintText,
    bool obscureText = false,
    required Widget helperWidget,
    int? maxLength,
    Widget? prefixIcon,
    Widget? suffixIcon,
    TextInputAction? textInputAction,
    VoidCallback? onEditingComplete,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[700])),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          focusNode: focusNode,
          obscureText: obscureText,
          maxLength: maxLength,
          textInputAction: textInputAction,
          onEditingComplete: onEditingComplete,
          decoration: InputDecoration(
            hintText: hintText,
            helperStyle: const TextStyle(height: 0),
            errorStyle: const TextStyle(height: 0),
            counterText: "",
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
          ),
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.only(left: 4.0),
          child: helperWidget,
        ),
      ],
    );
  }

  // 동적 헬퍼 텍스트 (색상 변경)
  Widget _buildHelperText(String text, {Color color = Colors.grey}) {
    return Text(text, style: TextStyle(color: color, fontSize: 12));
  }

  // 아이디 헬퍼 텍스트
  Widget _buildIdHelperText(SignUpState state) {
    if (state.memberId.isEmpty) {
      return _buildHelperText("공백 없이 5~12자로 입력해주세요.");
    }
    if (state.isIdValid) {
      return _buildHelperText("멋진 아이디네요!", color: AppColors.secondary);
    } else {
      return _buildHelperText("5~12자 사이로 입력해주세요.", color: Colors.redAccent);
    }
  }

  // 비밀번호 확인 헬퍼 텍스트
  Widget _buildConfirmPasswordHelperText(SignUpState state) {
    if (state.confirmPassword.isEmpty) return const SizedBox.shrink();
    if (state.doPasswordsMatch) {
      return _buildHelperText("비밀번호가 일치합니다.", color: AppColors.secondary);
    } else {
      return _buildHelperText("비밀번호가 일치하지 않습니다.", color: Colors.redAccent);
    }
  }

  // 닉네임 헬퍼 텍스트
  Widget _buildNicknameHelperText(SignUpState state) {
    if (state.nickname.isEmpty) {
      return _buildHelperText("공백 없이 2~6자로 입력해주세요.");
    }
    if (state.isNicknameValid) {
      return _buildHelperText("사용 가능한 닉네임입니다.", color: AppColors.secondary);
    } else {
      return _buildHelperText("2~6자 사이로 입력해주세요.", color: Colors.redAccent);
    }
  }

  // 비밀번호 규칙 체크리스트 (2x2 그리드 레이아웃으로 수정)
  Widget _buildPasswordRequirements(List<PasswordRequirement> requirements) {
    if (requirements.length < 4) return const SizedBox.shrink();

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildRequirementRow(requirements[0].text, requirements[0].met)),
            const SizedBox(width: 16),
            Expanded(child: _buildRequirementRow(requirements[1].text, requirements[1].met)),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(child: _buildRequirementRow(requirements[2].text, requirements[2].met)),
            const SizedBox(width: 16),
            Expanded(child: _buildRequirementRow(requirements[3].text, requirements[3].met)),
          ],
        ),
      ],
    );
  }

  // 체크리스트의 각 행
  Widget _buildRequirementRow(String text, bool met) {
    final color = met ? AppColors.secondary : Colors.grey;
    final icon = met ? Icons.check_circle : Icons.radio_button_unchecked;
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 8),
        Text(text, style: TextStyle(color: color, fontSize: 12)),
      ],
    );
  }
}