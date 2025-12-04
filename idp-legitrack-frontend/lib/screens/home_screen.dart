import 'package:flutter/material.dart';
import '../widgets/process_card.dart';
import '../models/process_model.dart';
import 'notification_screen.dart';
import 'process_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  final Set<String> initialFilters;
  final List<ProcessModel> processes;
  final Function(String) onToggleFavorite;

  const HomeScreen({
    super.key,
    required this.initialFilters,
    required this.processes,
    required this.onToggleFavorite,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedFilter = 'Todos';
  late List<String> _filters;

  @override
  void initState() {
    super.initState();
    _updateFilters();
  }

  @override
  void didUpdateWidget(HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialFilters != oldWidget.initialFilters) {
      _updateFilters();
    }
  }

  void _updateFilters() {
    List<String> sortedInterests = widget.initialFilters.toList()..sort();
    setState(() {
      _filters = ['Todos', ...sortedInterests];
      if (!_filters.contains(_selectedFilter)) {
        _selectedFilter = 'Todos';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF4169E1);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD), // Fundo ligeiramente mais azulado/frio
      body: SafeArea(
        child: Column(
          children: [
            // === CABEÇALHO (Visually improved) ===
            Container(
              padding: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                // Em vez de borda, uma sombra sutil para separar
                boxShadow: [
                   BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    offset: const Offset(0, 4),
                    blurRadius: 10,
                   )
                ]
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                    child: Column(
                      children: [
                        // Topo: Saudação e Sino
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                             Column(
                               crossAxisAlignment: CrossAxisAlignment.start,
                               children: [
                                 Text("Olá, Carlos", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.grey.shade900)),
                                 Text("Acompanhe seus processos", style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
                               ],
                             ),
                            IconButton(
                              // Ícone com um fundo circular sutil
                              icon: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  shape: BoxShape.circle
                                ),
                                child: Icon(Icons.notifications_none_rounded, size: 24, color: Colors.grey.shade800)
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const NotificationsScreen()),
                                );
                              },
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 24),

                        // Barra de Busca (Visualmente mais limpa)
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F5F9), // Cinza muito claro, sem borda
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const TextField(
                            decoration: InputDecoration(
                              hintText: "Pesquisar por título, palavra-chave...",
                              hintStyle: TextStyle(color: Colors.grey),
                              prefixIcon: Icon(Icons.search_rounded, color: primaryBlue),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Filtros Horizontais (Pills mais modernos)
                  SizedBox(
                    height: 40,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      scrollDirection: Axis.horizontal,
                      itemCount: _filters.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final filter = _filters[index];
                        final isSelected = filter == _selectedFilter;
                        
                        return GestureDetector(
                          onTap: () => setState(() => _selectedFilter = filter),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isSelected ? primaryBlue : Colors.white,
                              borderRadius: BorderRadius.circular(30),
                              // Sombra suave apenas no selecionado
                              boxShadow: isSelected ? [
                                BoxShadow(color: primaryBlue.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))
                              ] : null,
                              border: Border.all(
                                color: isSelected ? Colors.transparent : Colors.grey.shade200,
                                width: 1.5
                              ),
                            ),
                            child: Text(
                              filter,
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.grey.shade700,
                                fontWeight: FontWeight.w600,
                                fontSize: 14
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            
            // === LISTA DE PROCESSOS ===
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 24), // Mais padding no topo da lista
                itemCount: widget.processes.length,
                itemBuilder: (context, index) {
                  final process = widget.processes[index];
                  // (Lógica de filtro omitida para brevidade)
                   if (_selectedFilter != 'Todos' && 
                      !process.title.contains(_selectedFilter) && 
                      !process.description.contains(_selectedFilter)) {
                     // return const SizedBox.shrink(); 
                  }
                  return ProcessCard(
                    id: process.id,
                    title: process.title,
                    description: process.description,
                    status: process.status,
                    date: process.date,
                    isFavorite: process.isFavorite,
                    onFavoriteToggle: () => widget.onToggleFavorite(process.id),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProcessDetailScreen(
                          process: process,
                          onToggleFavorite: widget.onToggleFavorite,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}