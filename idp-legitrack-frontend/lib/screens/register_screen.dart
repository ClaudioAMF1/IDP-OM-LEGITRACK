import 'package:flutter/material.dart';
import '../widgets/custom_input.dart';
import '../widgets/custom_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. LOGO (O mesmo da tela de Login)
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4169E1),
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

              const Text(
                "Crie sua conta no LegiTrack", // Mudei levemente o texto para diferenciar
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),

              const SizedBox(height: 40),

              // 2. INPUTS (Agora são 3)
              CustomInput(
                label: "Nome Completo",
                controller: _nameController,
                icon: Icons.person_outline, // Ícone de pessoa
              ),

              const SizedBox(height: 20),

              CustomInput(
                label: "Email",
                controller: _emailController,
                icon: Icons.email_outlined,
              ),

              const SizedBox(height: 20),

              CustomInput(
                label: "Senha",
                isPassword: true,
                controller: _passwordController,
                icon: Icons.lock_outline,
              ),

              const SizedBox(height: 32),

              // 3. BOTÕES
              CustomButton(
                text: "Criar Conta",
                onPressed: () {
                  // Lógica de cadastro viria aqui
                  print("Cadastrar: ${_nameController.text}");
                },
              ),

              const SizedBox(height: 16),

              CustomButton(
                text: "Já tenho uma Conta",
                isPrimary: false, // Botão cinza
                onPressed: () {
                  // Volta para a tela anterior (Login)
                  Navigator.pop(context);
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