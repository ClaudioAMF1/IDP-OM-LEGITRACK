import 'package:flutter/material.dart';
import '../services/api_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _apiService = ApiService();
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotificacoes();
  }

  Future<void> _loadNotificacoes() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _apiService.listarNotificacoes();

      if (result['success']) {
        final notificacoesData = result['data'] as List;
        setState(() {
          _notifications = notificacoesData.map((notif) {
            return {
              'id': notif['id_notificacao'],
              'title': notif['titulo'] ?? 'Notificação',
              'description': notif['mensagem'] ?? '',
              'date': notif['data_criacao'] ?? '',
              'isUnread': !(notif['lida'] ?? false),
            };
          }).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _marcarComoLida(int idNotificacao, int index) async {
    try {
      final result = await _apiService.marcarNotificacaoLida(idNotificacao);

      if (result['success']) {
        setState(() {
          _notifications[index]['isUnread'] = false;
        });
      }
    } catch (e) {
      // Handle error silently
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

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
      body: _notifications.isEmpty
          ? const Center(
              child: Text(
                'Nenhuma notificação',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: _notifications.length,
              itemBuilder: (context, index) {
                final item = _notifications[index];
                return GestureDetector(
                  onTap: () {
                    if (item['isUnread'] as bool) {
                      _marcarComoLida(item['id'] as int, index);
                    }
                  },
                  child: _NotificationCard(
                    title: item['title'] as String,
                    description: item['description'] as String,
                    date: item['date'] as String,
                    isUnread: item['isUnread'] as bool,
                  ),
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