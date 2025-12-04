import 'package:flutter/material.dart';

class ProcessCard extends StatelessWidget {
  final String id;
  final String title;
  final String description;
  final String status;
  final String date;
  final bool isFavorite;
  final VoidCallback onFavoriteToggle;
  final VoidCallback? onTap;

  const ProcessCard({
    super.key,
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.date,
    this.isFavorite = false,
    required this.onFavoriteToggle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 24), // Mais espaço entre cards
        padding: const EdgeInsets.all(24), // Mais respiro interno
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24), // Bem arredondado
          // REMOVIDO: Border.all(...)
          boxShadow: [
            // Técnica de Sombra Dupla para efeito premium:
            // 1. Sombra menor e mais escura para definição próxima
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
            // 2. Sombra grande e difusa para elevação ambiente
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 30,
              offset: const Offset(0, 10),
              spreadRadius: -5,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Cabeçalho: ID e Estrela
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    id,
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: onFavoriteToggle,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Icon(
                      isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
                      key: ValueKey(isFavorite), // Para animação funcionar
                      color: isFavorite ? const Color(0xFFFFC107) : Colors.grey.shade400, // Dourado mais rico
                      size: 30, // Ícone maior
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),

            // 2. Título
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800, // Mais negrito
                color: Colors.grey.shade900,
                height: 1.2,
              ),
            ),

            const SizedBox(height: 12),

            // 3. Descrição
            Text(
              description,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 24),

            // 4. Rodapé: Status e Data com divisor
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Row(
                children: [
                  // Status com indicador visual (bolinha)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF4169E1),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      status,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF4169E1),
                      ),
                    ),
                  ),
                  Text(
                    date,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}