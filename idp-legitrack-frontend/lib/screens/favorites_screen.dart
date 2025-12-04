import 'package:flutter/material.dart';
import '../models/process_model.dart';
import '../widgets/process_card.dart';
import 'process_detail_screen.dart'; // Importante para navegar

class FavoritesScreen extends StatelessWidget {
  final List<ProcessModel> favoriteProcesses;
  final Function(String) onToggleFavorite;

  const FavoritesScreen({
    super.key,
    required this.favoriteProcesses,
    required this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Favoritos",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey.shade200, height: 1),
        ),
      ),
      body: favoriteProcesses.isEmpty
          // ESTADO VAZIO
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.star_border_rounded,
                    size: 80,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Nenhum favorito ainda",
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Marque processos com a estrela\npara vê-los aqui.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                  ),
                ],
              ),
            )
          // LISTA DE FAVORITOS
          : ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: favoriteProcesses.length,
              itemBuilder: (context, index) {
                final process = favoriteProcesses[index];
                return ProcessCard(
                  id: process.id,
                  title: process.title,
                  description: process.description,
                  status: process.status,
                  date: process.date,
                  isFavorite: true,
                  onFavoriteToggle: () => onToggleFavorite(process.id),
                  // NAVEGAÇÃO PARA DETALHES TAMBÉM AQUI
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProcessDetailScreen(
                          process: process,
                          onToggleFavorite:
                              onToggleFavorite, // Aqui a variável chama só onToggleFavorite
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
