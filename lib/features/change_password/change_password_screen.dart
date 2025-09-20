import 'package:chemiq/core/ui/chemiq_toast.dart';
import 'package:chemiq/core/ui/widgets/primary_button.dart';
import 'package:chemiq/styles/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'change_password_view_model.dart';

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _currentPwController = TextEditingController();
  final _newPwController = TextEditingController();
  final _newPwConfirmController = TextEditingController();

  // ✨ 각 TextField의 포커스를 관리하기 위한 FocusNode 추가
  final _currentPwFocus = FocusNode();
  final _newPwFocus = FocusNode();
  final _newPwConfirmFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    final viewModel = ref.read(changePasswordViewModelProvider.notifier);
    _currentPwController.addListener(() => viewModel.onCurrentPasswordChanged(_currentPwController.text));
    _newPwController.addListener(() => viewModel.validateNewPassword(_newPwController.text));
    _newPwConfirmController.addListener(() => viewModel.validateConfirmPassword(_newPwConfirmController.text));
  }

  @override
  void dispose() {
    _currentPwController.dispose();
    _newPwController.dispose();
    _newPwConfirmController.dispose();
    // ✨ FocusNode도 dispose 처리
    _currentPwFocus.dispose();
    _newPwFocus.dispose();
    _newPwConfirmFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(changePasswordViewModelProvider);
    final viewModel = ref.read(changePasswordViewModelProvider.notifier);

    ref.listen(changePasswordViewModelProvider, (previous, next) {
      final successMessage = next.successMessage;
      if (successMessage != null) {
        showChemiQToast(successMessage, type: ToastType.success);
        context.pop();
      }
      final errorMessage = next.errorMessage;
      if (errorMessage != null) {
        showChemiQToast(errorMessage, type: ToastType.error);
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('비밀번호 변경')),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTextField(
                controller: _currentPwController,
                focusNode: _currentPwFocus,
                label: '현재 비밀번호',
                hintText : '현재 비밀번호',
                prefixIcon: const Icon(Icons.lock_outline),
                obscureText: !state.isCurrentPasswordVisible,
                onToggleVisibility: viewModel.toggleCurrentPasswordVisibility,
                maxLength: state.passwordMaxLength,
                textInputAction: TextInputAction.next,
                onEditingComplete: () => _newPwFocus.requestFocus(),
              ),
              const SizedBox(height: 24),
              _buildTextField(
                controller: _newPwController,
                focusNode: _newPwFocus,
                label: '새 비밀번호',
                hintText : '새 비밀번호',
                prefixIcon: const Icon(Icons.lock_outline),
                obscureText: !state.isNewPasswordVisible,
                onToggleVisibility: viewModel.toggleNewPasswordVisibility,
                helperWidget: _buildPasswordRequirements(state.passwordRequirements),
                maxLength: state.passwordMaxLength,
                textInputAction: TextInputAction.next,
                onEditingComplete: () => _newPwConfirmFocus.requestFocus(),
              ),
              const SizedBox(height: 24),
              _buildTextField(
                controller: _newPwConfirmController,
                focusNode: _newPwConfirmFocus,
                label: '새 비밀번호 확인',
                hintText : '새 비밀번호 확인',
                prefixIcon: const Icon(Icons.lock_outline),
                obscureText: !state.isConfirmPasswordVisible,
                onToggleVisibility: viewModel.toggleConfirmPasswordVisibility,
                helperWidget: _buildConfirmPasswordHelperText(state),
                maxLength: state.passwordMaxLength,
                textInputAction: TextInputAction.done,
                onEditingComplete: () {
                  _newPwConfirmFocus.unfocus();
                  if (state.isFormValid) viewModel.changePassword();
                },
              ),
              const SizedBox(height: 40),
              PrimaryButton(
                text: '변경하기',
                isLoading: state.isLoading,
                onPressed: state.isFormValid ? () => viewModel.changePassword() : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✨ FocusNode 관련 파라미터 추가
  Widget _buildTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required String hintText,
    bool obscureText = true,
    VoidCallback? onToggleVisibility,
    Widget? helperWidget,
    int? maxLength,
    TextInputAction? textInputAction,
    VoidCallback? onEditingComplete,
    Widget? prefixIcon,
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
            hintText : hintText,
            helperStyle: const TextStyle(height: 0),
            errorStyle: const TextStyle(height: 0),
            counterText: "",
            prefixIcon: prefixIcon,
            suffixIcon: onToggleVisibility != null
                ? IconButton(
              icon: Icon(
                obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: Colors.grey,
              ),
              onPressed: onToggleVisibility,
            )
                : null,
          ),
        ),
        if (helperWidget != null) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 4.0),
            child: helperWidget,
          ),
        ],
      ],
    );
  }

  Widget _buildHelperText(String text, {Color color = Colors.grey}) {
    return Text(text, style: TextStyle(color: color, fontSize: 12));
  }

  Widget _buildConfirmPasswordHelperText(ChangePasswordState state) {
    if (state.confirmPassword.isEmpty) return const SizedBox.shrink();
    if (state.doPasswordsMatch) {
      return _buildHelperText("비밀번호가 일치합니다.", color: AppColors.secondary);
    } else {
      return _buildHelperText("비밀번호가 일치하지 않습니다.", color: Colors.redAccent);
    }
  }

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