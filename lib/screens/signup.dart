import 'package:flutter/material.dart';
import 'package:flutter_yong_sseotni/screens/start.dart';
import 'package:http/http.dart' as http;
//import 'dart:convert';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _birthdateController = TextEditingController();

  Future<void> _registerUser() async {
    final url = Uri.parse(
      'http://3.36.22.27:8080/Spring-yong_sseotni/api/user/join'
      '?login_provider=basic'
      '&user_email=${_emailController.text}'
      '&user_pw=${_passwordController.text}'
      '&user_nick=${_nicknameController.text}'
      '&user_birth=${_birthdateController.text}'
      '&target_amount=0',
    );

    try {
      final response = await http.post(url);

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('회원 가입 성공했습니다!')),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const StartPage()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('회원 가입 실패. 다시 시도해주세요.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('오류가 발생했습니다. 인터넷 연결을 확인하세요.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('회원 가입'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const SizedBox(height: 60),
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Text(
                      '회원 가입',
                      style: TextStyle(
                        fontSize: 35,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF12BC4C),
                      ),
                    ),
                    Positioned(
                      right: -85,
                      top: -85,
                      child: Image.asset(
                        'assets/yong_image.png',
                        height: 130,
                        width: 130,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 60),
                _buildEmailField(),
                const SizedBox(height: 15),
                _buildPasswordField(),
                const SizedBox(height: 15),
                _buildNicknameField(),
                const SizedBox(height: 15),
                _buildBirthdateField(),
                const SizedBox(height: 20),
                _buildSignUpButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        labelText: '이메일',
        prefixIcon: Icon(Icons.email),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return '이메일을 입력해주세요.';
        }
        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
          return '유효한 이메일 주소를 입력해주세요.';
        }
        return null;
      },
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: true,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        labelText: '비밀번호',
        prefixIcon: Icon(Icons.lock),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return '비밀번호를 입력해주세요.';
        }
        if (value.length < 6) {
          return '비밀번호는 최소 6자리 이상이어야 합니다.';
        }
        return null;
      },
    );
  }

  Widget _buildNicknameField() {
    return TextFormField(
      controller: _nicknameController,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        labelText: '닉네임',
        prefixIcon: Icon(Icons.person),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return '닉네임을 입력해주세요.';
        }
        return null;
      },
    );
  }

  Widget _buildBirthdateField() {
    return TextFormField(
      controller: _birthdateController,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        labelText: '생년월일',
        prefixIcon: Icon(Icons.calendar_today),
      ),
      readOnly: true,
      onTap: () async {
        DateTime? pickedDate = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(1900),
          lastDate: DateTime.now(),
        );

        if (pickedDate != null) {
          // pickedDate가 null이 아닌 경우에만 접근
          setState(() {
            _birthdateController.text =
                '${pickedDate.year}-${pickedDate.month}-${pickedDate.day}';
          });
        }
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return '생년월일을 입력해주세요.';
        }
        return null;
      },
    );
  }

  Widget _buildSignUpButton() {
    return ElevatedButton(
      onPressed: () {
        if (_formKey.currentState!.validate()) {
          _registerUser(); // 서버 연동 메서드 호출
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF12BC4C),
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: const Text(
        '회원 가입',
        style: TextStyle(
          fontSize: 18,
          color: Colors.white,
        ),
      ),
    );
  }
}
