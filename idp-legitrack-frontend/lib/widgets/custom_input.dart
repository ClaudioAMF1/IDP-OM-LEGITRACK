import 'package:flutter/material.dart';

class CustomInput extends StatelessWidget {
  final String label;
  final String? placeholder;
  final bool isPassword;
  final TextEditingController? controller;
  final IconData? icon;

  const CustomInput({
    super.key,
    required this.label,
    this.placeholder,
    this.isPassword = false,
    this.controller,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 10), // Mais espaçamento no label
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800, // Cor ligeiramente mais suave
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16), // Bordas mais arredondadas
            // REMOVIDO: border: Border.all(...) - A sombra agora faz o trabalho
            boxShadow: [
              // Sombra mais moderna e difusa
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.07),
                blurRadius: 20,
                offset: const Offset(0, 5),
                spreadRadius: 0,
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            obscureText: isPassword,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              hintText: placeholder,
              hintStyle: TextStyle(color: Colors.grey.shade400),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 18, // Um pouco mais alto para dar respiro
              ),
              prefixIcon: icon != null
                  ? Padding(
                      padding: const EdgeInsets.only(left: 16, right: 12),
                      child: Icon(icon, color: const Color(0xFF4169E1), size: 24), // Ícone azul para combinar
                    )
                  : null,
            ),
          ),
        ),
      ],
    );
  }
}