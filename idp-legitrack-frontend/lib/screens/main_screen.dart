import 'package:flutter/material.dart';
import '../models/process_model.dart';
import '../services/api_service.dart';
import 'home_screen.dart';
import 'favorites_screen.dart';
import 'interests_screen.dart';
import 'profile_screen.dart';

class MainScreen extends StatefulWidget {
  final Set<int> userInterests;

  const MainScreen({super.key, required this.userInterests});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final _apiService = ApiService();
  int _currentIndex = 0;

  // Estado local dos interesses que pode mudar e ser passado para a Home
  late Set<int> _currentInterests;

  // 1. DADOS CENTRALIZADOS
  // Essa é a "fonte da verdade" dos dados. Todos as telas leem daqui.
  List<ProcessModel> _processes = [];
  bool _isLoading = true;
  Set<int> _favoritesIds = {};

  @override
  void initState() {
    super.initState();
    _currentInterests = Set.from(widget.userInterests);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    await Future.wait([
      _loadProjetos(),
      _loadFavoritos(),
    ]);

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadProjetos() async {
    try {
      final result = await _apiService.listarProjetos(
        idsTemas: _currentInterests.toList(),
      );

      if (result['success']) {
        final projetosData = result['data'] as List;
        setState(() {
          _processes = projetosData.map((projeto) {
            return ProcessModel(
              id: projeto['id_projeto'].toString(),
              title: projeto['numero'] ?? 'Sem número',
              description: projeto['ementa'] ?? 'Sem descrição',
              status: projeto['ultima_situacao'] ?? 'Status não disponível',
              date: projeto['data_apresentacao'] ?? '',
              isFavorite: _favoritesIds.contains(projeto['id_projeto']),
            );
          }).toList();
        });
      }
    } catch (e) {
      // Handle error silently or show message
    }
  }

  Future<void> _loadFavoritos() async {
    try {
      final result = await _apiService.listarFavoritos();

      if (result['success']) {
        final favoritosData = result['data'] as List;
        setState(() {
          _favoritesIds = favoritosData
              .map((fav) => fav['id_projeto'] as int)
              .toSet();
        });
      }
    } catch (e) {
      // Handle error silently
    }
  }

  // 2. LÓGICA DE FAVORITAR E REORDENAR
  Future<void> _handleToggleFavorite(String id) async {
    final idProjeto = int.parse(id);

    try {
      final result = await _apiService.toggleFavorito(idProjeto);

      if (result['success']) {
        setState(() {
          final index = _processes.indexWhere((p) => p.id == id);
          if (index != -1) {
            _processes[index].isFavorite = !_processes[index].isFavorite;

            if (_processes[index].isFavorite) {
              _favoritesIds.add(idProjeto);
            } else {
              _favoritesIds.remove(idProjeto);
            }

            // ORDENAÇÃO: Favoritos sobem para o topo
            _processes.sort((a, b) {
              if (b.isFavorite && !a.isFavorite) return 1;
              if (!b.isFavorite && a.isFavorite) return -1;
              return 0;
            });
          }
        });
      }
    } catch (e) {
      // Handle error
    }
  }

  // 3. ATUALIZAÇÃO DE INTERESSES
  // Chamada quando o usuário muda algo na aba "Interesses"
  Future<void> _handleInterestsUpdate(Set<int> newInterests) async {
    setState(() {
      _currentInterests = newInterests;
    });

    try {
      await _apiService.atualizarInteresses(newInterests.toList());
      _loadProjetos(); // Recarrega projetos com os novos interesses
    } catch (e) {
      // Handle error
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

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
