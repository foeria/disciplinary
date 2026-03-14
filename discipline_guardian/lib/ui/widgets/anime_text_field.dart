import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 动漫风格输入框组件
/// 特点：圆角边框、底部横线、聚焦动画、支持密码模式
class AnimeTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String? hintText;
  final String? labelText;
  final String? errorText;
  final bool obscureText;
  final bool enabled;
  final bool showPasswordToggle;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final FormFieldValidator<String>? validator;
  final List<TextInputFormatter>? inputFormatters;
  final int maxLines;
  final int? maxLength;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final Color focusColor;
  final Color borderColor;
  final Color errorColor;

  const AnimeTextField({
    super.key,
    this.controller,
    this.hintText,
    this.labelText,
    this.errorText,
    this.obscureText = false,
    this.enabled = true,
    this.showPasswordToggle = true,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.done,
    this.onChanged,
    this.onSubmitted,
    this.validator,
    this.inputFormatters,
    this.maxLines = 1,
    this.maxLength,
    this.prefixIcon,
    this.suffixIcon,
    this.focusColor = const Color(0xFFFF6B9D),
    this.borderColor = const Color(0xFFE0E0E0),
    this.errorColor = const Color(0xFFE53935),
  });

  @override
  State<AnimeTextField> createState() => _AnimeTextFieldState();
}

class _AnimeTextFieldState extends State<AnimeTextField>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _borderAnimation;
  late Animation<double> _labelAnimation;
  bool _isFocused = false;
  bool _obscureText = false;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _obscureText = widget.obscureText;
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _borderAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _labelAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
    if (_isFocused) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasError = widget.errorText != null && widget.errorText!.isNotEmpty;
    final activeColor = hasError ? widget.errorColor : widget.focusColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.labelText != null) ...[
          AnimatedBuilder(
            animation: _labelAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, -12 * _labelAnimation.value),
                child: Text(
                  widget.labelText!,
                  style: TextStyle(
                    fontSize: 12 + (4 * _labelAnimation.value),
                    color: _isFocused
                        ? activeColor
                        : Colors.grey.shade600,
                    fontWeight:
                        _isFocused ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
        ],
        AnimatedBuilder(
          animation: _borderAnimation,
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Color.lerp(
                    widget.borderColor,
                    activeColor,
                    _borderAnimation.value,
                  )!,
                  width: _isFocused ? 2 : 1,
                ),
              ),
              child: child,
            );
          },
          child: TextField(
            controller: widget.controller,
            focusNode: _focusNode,
            obscureText: _obscureText,
            enabled: widget.enabled,
            keyboardType: widget.keyboardType,
            textInputAction: widget.textInputAction,
            onChanged: widget.onChanged,
            onSubmitted: widget.onSubmitted,
            inputFormatters: widget.inputFormatters,
            maxLines: widget.obscureText ? 1 : widget.maxLines,
            maxLength: widget.maxLength,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF333333),
            ),
            decoration: InputDecoration(
              hintText: widget.hintText,
              hintStyle: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 16,
              ),
              prefixIcon: widget.prefixIcon,
              suffixIcon: _buildSuffixIcon(hasError),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              counterText: '',
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 6),
          Text(
            widget.errorText!,
            style: TextStyle(
              fontSize: 12,
              color: widget.errorColor,
            ),
          ),
        ],
      ],
    );
  }

  Widget? _buildSuffixIcon(bool hasError) {
    if (widget.suffixIcon != null) {
      return widget.suffixIcon;
    }

    if (widget.obscureText && widget.showPasswordToggle) {
      return IconButton(
        icon: Icon(
          _obscureText ? Icons.visibility_off : Icons.visibility,
          color: Colors.grey.shade500,
        ),
        onPressed: _togglePasswordVisibility,
      );
    }

    return null;
  }
}

/// 动漫风格密码输入框（带数字键盘）
class AnimePasswordField extends StatefulWidget {
  final TextEditingController? controller;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onCompleted;
  final int pinLength;
  final bool showError;

  const AnimePasswordField({
    super.key,
    this.controller,
    this.errorText,
    this.onChanged,
    this.onCompleted,
    this.pinLength = 4,
    this.showError = true,
  });

  @override
  State<AnimePasswordField> createState() => _AnimePasswordFieldState();
}

class _AnimePasswordFieldState extends State<AnimePasswordField> {
  late List<TextEditingController> _controllers;
  late List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      widget.pinLength,
      (_) => TextEditingController(),
    );
    _focusNodes = List.generate(
      widget.pinLength,
      (_) => FocusNode(),
    );
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _onDigitEntered(int index, String value) {
    if (value.isNotEmpty) {
      _controllers[index].text = value[value.length - 1];
      if (index < widget.pinLength - 1) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
        _notifyCompleted();
      }
    }
    widget.onChanged?.call(_getFullCode());
  }

  void _notifyCompleted() {
    final code = _getFullCode();
    if (code.length == widget.pinLength) {
      widget.onCompleted?.call(code);
    }
  }

  String _getFullCode() {
    return _controllers.map((c) => c.text).join();
  }

  @override
  Widget build(BuildContext context) {
    final hasError = widget.showError &&
        widget.errorText != null &&
        widget.errorText!.isNotEmpty;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.pinLength, (index) {
            return Container(
              width: 56,
              height: 64,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: hasError
                      ? const Color(0xFFE53935)
                      : _focusNodes[index].hasFocus
                          ? const Color(0xFFFF6B9D)
                          : const Color(0xFFE0E0E0),
                  width: 2,
                ),
              ),
              child: TextField(
                controller: _controllers[index],
                focusNode: _focusNodes[index],
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 1,
                obscureText: true,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  counterText: '',
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                onChanged: (value) => _onDigitEntered(index, value),
              ),
            );
          }),
        ),
        if (hasError) ...[
          const SizedBox(height: 12),
          Text(
            widget.errorText!,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFFE53935),
            ),
          ),
        ],
      ],
    );
  }
}
