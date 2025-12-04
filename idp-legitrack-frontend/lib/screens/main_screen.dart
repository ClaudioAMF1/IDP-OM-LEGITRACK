import 'package:flutter/material.dart';
import '../models/process_model.dart';
import 'home_screen.dart';
import 'favorites_screen.dart';
import 'interests_screen.dart';
import 'profile_screen.dart';

class MainScreen extends StatefulWidget {
  final Set<String> userInterests;

  const MainScreen({super.key, required this.userInterests});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  // Estado local dos interesses que pode mudar e ser passado para a Home
  late Set<String> _currentInterests;

  // 1. DADOS CENTRALIZADOS
  // Essa é a "fonte da verdade" dos dados. Todos as telas leem daqui.
  final List<ProcessModel> _processes = [
    ProcessModel(
      id: "PL 2024/001",
      title: "Marco Regulatório da IA",
      description:
          "Estabelece diretrizes para o desenvolvimento e uso ético de sistemas de IA no Brasil.",
      status: "Em tramitação na Câmara",
      date: "14 de jan. de 2024",
      isFavorite: false,
    ),
    ProcessModel(
      id: "PL 2024/002",
      title: "Programa Nacional de Telemedicina",
      description:
          "Regulamenta e expande o acesso aos serviços de telemedicina em todo território nacional.",
      status: "Aprovado na Câmara",
      date: "19 de jan. de 2024",
      isFavorite: false,
    ),
    ProcessModel(
      id: "PL 2024/004",
      title: "Lei de Proteção de Dados Educacionais",
      description:
          "Estabelece regras para coleta e uso de dados pessoais de estudantes.",
      status: "Pronto para votação",
      date: "4 de fev. de 2024",
      isFavorite: false,
    ),
    ProcessModel(
      id: "PL 2024/008",
      title: "Incentivo à Energia Solar",
      description:
          "Cria subsídios para instalação de painéis solares residenciais.",
      status: "Em análise no Senado",
      date: "10 de fev. de 2024",
      isFavorite: false,
    ),
  ];

  @override
  void initState() {
    super.initState();
    // Copia o que veio do login para nossa variável local editável
    _currentInterests = Set.from(widget.userInterests);
  }

  // 2. LÓGICA DE FAVORITAR E REORDENAR
  void _handleToggleFavorite(String id) {
    setState(() {
      // Encontra o index pelo ID para garantir que alteramos o item certo
      final index = _processes.indexWhere((p) => p.id == id);
      if (index != -1) {
        // Inverte o status
        _processes[index].isFavorite = !_processes[index].isFavorite;

        // ORDENAÇÃO: Favoritos sobem para o topo
        _processes.sort((a, b) {
          if (b.isFavorite && !a.isFavorite) return 1;
          if (!b.isFavorite && a.isFavorite) return -1;
          return 0; // Mantém a ordem original se ambos forem iguais
        });
      }
    });
  }

  // 3. ATUALIZAÇÃO DE INTERESSES
  // Chamada quando o usuário muda algo na aba "Interesses"
  void _handleInterestsUpdate(Set<String> newInterests) {
    setState(() {
      _currentInterests = newInterests;
      // O setState vai reconstruir a tela e passar os novos filtros pra HomeScreen automaticamente
    });
  }

  @override
  Widget build(BuildContext context) {
    // Cria a lista filtrada apenas para a tela de Favoritos
    final favoriteList = _processes.where((p) => p.isFavorite).toList();

    // Lista de Telas (Recriada no build para garantir que pegue o estado atualizado)
    final List<Widget> screens = [
      // ABA 0: HOME
      HomeScreen(
        initialFilters: _currentInterests, // Passa os filtros atualizados
        processes: _processes, // Passa a lista completa
        onToggleFavorite: _handleToggleFavorite,
      ),

      // ABA 1: FAVORITOS
      FavoritesScreen(
        favoriteProcesses: favoriteList, // Passa apenas os favoritos
        onToggleFavorite: _handleToggleFavorite,
      ),

      // ABA 2: INTERESSES
      InterestsScreen(
        initialSelection:
            _currentInterests, // Mostra o que está selecionado atualmente
        isTab:
            true, // Avisa que é modo aba (esconde botão continuar e cabeçalho)
        onSelectionChanged:
            _handleInterestsUpdate, // Conecta a função de atualização
      ),

      // ABA 3: PERFIL (Placeholder)
      const ProfileScreen(),
    ];

    return Scaffold(
      body:
          screens[_currentIndex], // Mostra a tela correspondente à aba selecionada

      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.grey.shade200)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF4169E1),
          unselectedItemColor: Colors.grey.shade600,
          showSelectedLabels: false,
          showUnselectedLabels: false,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined, size: 28),
              activeIcon: Icon(Icons.home, size: 28),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.favorite_border, size: 28),
              activeIcon: Icon(Icons.favorite, size: 28),
              label: 'Favoritos',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.book_outlined, size: 28),
              activeIcon: Icon(Icons.book, size: 28),
              label: 'Interesses',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline, size: 28),
              activeIcon: Icon(Icons.person, size: 28),
              label: 'Perfil',
            ),
          ],
        ),
      ),
    );
  }
}
