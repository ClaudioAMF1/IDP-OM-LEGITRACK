import 'package:flutter/material.dart';
import 'login_screen.dart'; // Para o botão de sair funcionar
import 'notification_screen.dart'; // Para o sino funcionar

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Estado dos Switches
  bool _notificationsEnabled = true;
  bool _dailySummaryEnabled = true;
  bool _weeklySummaryEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // 1. CABEÇALHO (Sino)
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: const Icon(Icons.notifications_none_rounded, size: 28),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const NotificationsScreen(),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 10),

              // 2. TÍTULO
              const Text(
                "Usuário",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),

              const SizedBox(height: 24),

              // 3. AVATAR E DADOS
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.grey.shade200,
                    width: 4,
                  ), // Borda branca/cinza
                ),
                child: const CircleAvatar(
                  radius: 60,
                  backgroundImage: NetworkImage(
                    'https://i.pravatar.cc/300?img=11',
                  ), // Imagem placeholder
                  backgroundColor: Colors.grey,
                ),
              ),

              const SizedBox(height: 16),

              const Text(
                "Carlos Ferreira",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),

              const Text(
                "carlos@email.com",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87, // Um pouco mais escuro que cinza
                ),
              ),

              const SizedBox(height: 32),

              // 4. CARD DE CONFIGURAÇÕES (Cinza)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 32,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0E0E0), // Cinza do design
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    // Opção 1: Notificações
                    _buildSwitchRow(
                      label: "Notificações",
                      value: _notificationsEnabled,
                      onChanged: (val) =>
                          setState(() => _notificationsEnabled = val),
                    ),

                    const Divider(
                      color: Colors.black26,
                      height: 32,
                    ), // Linha divisória
                    // Opção 2: Resumo Diário
                    _buildSwitchRow(
                      label: "Resumo Diário",
                      value: _dailySummaryEnabled,
                      onChanged: (val) =>
                          setState(() => _dailySummaryEnabled = val),
                    ),

                    const Divider(color: Colors.black26, height: 32),

                    // Opção 3: Resumo Semanal
                    _buildSwitchRow(
                      label: "Resumo Semanal",
                      value: _weeklySummaryEnabled,
                      onChanged: (val) =>
                          setState(() => _weeklySummaryEnabled = val),
                    ),

                    const SizedBox(height: 40),

                    // BOTÃO SAIR
                    SizedBox(
                      width: 150, // Largura fixa menor
                      height: 45,
                      child: ElevatedButton(
                        onPressed: () {
                          // Remove todo o histórico de navegação e volta pro Login
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LoginScreen(),
                            ),
                            (route) => false,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(
                            0xFFEF5350,
                          ), // Vermelho suave
                          foregroundColor: Colors.white,
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              25,
                            ), // Bem arredondado
                            side: const BorderSide(
                              color: Colors.black12,
                            ), // Borda sutil
                          ),
                        ),
                        child: const Text(
                          "SAIR",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30), // Espaço extra no final
            ],
          ),
        ),
      ),
    );
  }

  // Widget auxiliar para criar as linhas com Switch
  Widget _buildSwitchRow({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        // Switch com cor verde personalizada
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: Colors.white,
          activeTrackColor: const Color(0xFF4CAF50), // Verde
          inactiveThumbColor: Colors.white,
          inactiveTrackColor: Colors.grey.shade400,
        ),
      ],
    );
  }
}
