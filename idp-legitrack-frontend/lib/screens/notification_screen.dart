import 'package:flutter/material.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Dados Mockados (Simulando o que viria do backend)
    final notifications = [
      {
        'title': 'Novo projeto sobre aposentadoria',
        'description': 'PL 2024/003 foi apresentado no Senado',
        'date': '31 de jan. de 2024',
        'isUnread': true, // Esse tem bolinha vermelha
      },
      {
        'title': 'Atualização no Marco da IA',
        'description': 'O relator apresentou novo texto substitutivo na comissão.',
        'date': '28 de jan. de 2024',
        'isUnread': false,
      },
      {
        'title': 'Votação Urgente',
        'description': 'A PL da Telemedicina entrou em regime de urgência.',
        'date': '20 de jan. de 2024',
        'isUnread': false,
      },
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context), // Voltar
        ),
        title: const Text(
          "Notificações",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final item = notifications[index];
          return _NotificationCard(
            title: item['title'] as String,
            description: item['description'] as String,
            date: item['date'] as String,
            isUnread: item['isUnread'] as bool,
          );
        },
      ),
    );
  }
}

// COMPONENTE LOCAL (Privado ao arquivo)
class _NotificationCard extends StatelessWidget {
  final String title;
  final String description;
  final String date;
  final bool isUnread;

  const _NotificationCard({
    required this.title,
    required this.description,
    required this.date,
    required this.isUnread,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        // Fundo cinza claro como no design (ex: Colors.grey.shade300 ou shade200)
        color: const Color(0xFFE0E0E0), 
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12), // Borda bem sutil
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Linha do Título + Bolinha Vermelha
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Se não lido, mostra a bolinha
              if (isUnread)
                Padding(
                  padding: const EdgeInsets.only(top: 4, right: 8),
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Colors.red, // Vermelho de alerta
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              
              // Título expandido para quebrar linha se precisar
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),

          // Descrição
          Text(
            description,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade800,
              height: 1.3,
            ),
          ),

          const SizedBox(height: 16),

          // Data (Texto pequeno)
          Text(
            date,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}