import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isPrimary;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isPrimary = true,
  });

  @override
  Widget build(BuildContext context) {
    // Definindo cores base
    final primaryColor = const Color(0xFF4169E1);
    final secondaryColor = Colors.white;
    final secondaryBorderColor = Colors.grey.shade300;

    return GestureDetector(
      onTap: onPressed,
      child: Opacity(
        opacity: onPressed == null ? 0.5 : 1.0,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18), // Botão mais alto e imponente
          decoration: BoxDecoration(
            color: isPrimary ? primaryColor : secondaryColor,
            borderRadius: BorderRadius.circular(16), // Mais arredondado
            // Borda apenas no secundário, e mais sutil
            border: isPrimary ? null : Border.all(color: secondaryBorderColor, width: 1.5),
            boxShadow: [
              BoxShadow(
                // Se for primário, a sombra tem um tom azulado, senão cinza
                color: isPrimary
                    ? primaryColor.withValues(alpha: 0.3)
                    : Colors.black.withValues(alpha: 0.05),
                blurRadius: 15,
                offset: const Offset(0, 8),
                spreadRadius: -2,
              ),
            ],
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5, // Espaçamento sutil entre letras
              color: isPrimary ? Colors.white : Colors.grey.shade800,
            ),
          ),
        ),
      ),
    );
  }
}