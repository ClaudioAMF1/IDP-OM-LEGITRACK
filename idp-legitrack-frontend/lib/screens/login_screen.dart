import 'package:flutter/material.dart';
import '../widgets/custom_input.dart';
import '../widgets/custom_button.dart';
import 'register_screen.dart';
import 'interests_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Controladores para capturar o texto (como o 'ref' ou 'state' do React)
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Garante fundo branco como no design
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. O LOGO (Quadrado Azul com L)
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(
                      0xFF4169E1,
                    ), // Azul "Royal Blue" aproximado
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Text(
                      "L",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // 2. O TÍTULO
              const Text(
                "Bem-vindo ao LegiTrack",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),

              const SizedBox(height: 40),

              // 3. OS INPUTS MELHORADOS
              CustomInput(
                label: "Email",
                //placeholder: "exemplo@email.com", // Opcional
                controller: _emailController,
                icon: Icons.email_outlined, // Ícone de carta
              ),

              const SizedBox(height: 20), // Mais respiro entre os campos

              CustomInput(
                label: "Senha",
                isPassword: true,
                controller: _passwordController,
                icon: Icons.lock_outline, // Ícone de cadeado
              ),

              const SizedBox(height: 12),

              // 4. Link "Esqueci a Senha" (Alinhado à direita e mais bonito)
              Align(
                alignment:
                    Alignment.centerRight, // Fica mais moderno na direita
                child: TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero, // Remove padding padrão do botão
                    minimumSize: const Size(0, 0), // Remove área de toque extra
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    "Esqueci a Senha",
                    style: TextStyle(
                      color: Color(0xFF4169E1),
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Botão Entrar
              CustomButton(
                text: "Entrar",
                onPressed: () {
                  // Navegação com "Replacement" para o usuário não voltar pro Login ao dar "voltar"
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const InterestsScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 16),

              // Botão Criar Conta (Secundário) dentro de login_screen.dart
              CustomButton(
                text: "Criar Conta",
                isPrimary: false,
                onPressed: () {
                  // Navega para a tela de Cadastro empilhando-a
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RegisterScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
