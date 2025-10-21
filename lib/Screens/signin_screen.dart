import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:spotify_clone/widgets/custom_appbar.dart';
import 'package:spotify_clone/widgets/register_and_sigin/field_button.dart';
import 'package:spotify_clone/widgets/register_and_sigin/text_field.dart';
import '../widgets/register_and_sigin/auth_redirect_text.dart';
import '../widgets/register_and_sigin/or_divider.dart';
import '../widgets/register_and_sigin/social_login_button.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isPasswordVisible = true;
  bool _isLoading = false;

  void _togglePasswordVisibility() {
    setState(() {
      _isPasswordVisible = !_isPasswordVisible;
    });
  }

  Future<void> _signIn() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final supabase = Supabase.instance.client;

        final response = await supabase.auth.signInWithPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        final user = response.user;
        if (user == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đăng nhập thất bại')),
          );
          return;
        }

        // 🔹 Lấy role từ bảng users
        final userId = user.id;
        final data = await supabase
            .from('users')
            .select('role')
            .eq('id', userId)
            .single();

        final role = data['role'] ?? 'user';

        // 🔹 Điều hướng theo quyền
        if (role == 'admin') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đăng nhập với vai trò ADMIN')),
          );
          Navigator.pushReplacementNamed(context, '/admin');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đăng nhập thành công')),
          );
          Navigator.pushReplacementNamed(context, '/main');
        }
      } on AuthException catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: ${e.message}')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi không xác định: $e')),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        onBack: () {
          Navigator.pop(context);
        },
        title: 'SIGN IN',
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    const Text(
                      'Sign In',
                      style:
                      TextStyle(fontWeight: FontWeight.bold, fontSize: 30),
                    ),
                    const SizedBox(height: 49),
                    CustomTextField(
                      label: 'Enter Your Email',
                      controller: _emailController,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập email';
                        }
                        if (!value.contains('@')) {
                          return 'Email không hợp lệ';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    CustomTextField(
                      label: 'Password',
                      controller: _passwordController,
                      isPassword: true,
                      obscureText: _isPasswordVisible,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Mật khẩu không được để trống';
                        }
                        if (value.length < 6) {
                          return 'Mật khẩu phải dài hơn 6 kí tự';
                        }
                        return null;
                      },
                      onTogglePassword: _togglePasswordVisibility,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(left: 47.0, bottom: 15),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      overlayColor: Colors.transparent,
                      splashFactory: NoSplash.splashFactory,
                    ),
                    onPressed: () {},
                    child: const Text('Recovery Password',
                        style: TextStyle(fontSize: 14)),
                  ),
                ),
              ),
              FieldButton(type: 'sign in', action: _isLoading ? null : _signIn),
              const SizedBox(height: 15),
              const OrDivider(),
              const SocialLoginButton(),
              const SizedBox(height: 15),
              const AuthRedirectText(type: 'signin'),
            ],
          ),
        ),
      ),
    );
  }
}
