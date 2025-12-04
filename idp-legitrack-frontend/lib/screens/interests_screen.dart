import 'package:flutter/material.dart';
import 'main_screen.dart'; // Mantenha este import se ainda usar o botão Continuar no fluxo de login

class InterestsScreen extends StatefulWidget {
  // Novos parâmetros opcionais
  final Set<String>? initialSelection;
  final bool isTab; // Saber se é aba ou tela de setup
  final Function(Set<String>)? onSelectionChanged;

  const InterestsScreen({
    super.key,
    this.initialSelection,
    this.isTab = false, // Por padrão é falso (modo setup inicial)
    this.onSelectionChanged,
  });

  @override
  State<InterestsScreen> createState() => _InterestsScreenState();
}

class _InterestsScreenState extends State<InterestsScreen> {
  // Inicializamos vazio, mas vamos preencher no initState
  final Set<String> _selectedInterests = {};

  final List<Map<String, dynamic>> _categories = [
    {'label': 'Tecnologia', 'icon': Icons.monitor},
    {'label': 'Segurança', 'icon': Icons.shield_outlined},
    {'label': 'Economia', 'icon': Icons.attach_money},
    {'label': 'Meio Ambiente', 'icon': Icons.eco_outlined},
    {'label': 'Educação', 'icon': Icons.menu_book_outlined},
    {'label': 'Saúde', 'icon': Icons.vaccines_outlined},
  ];

  @override
  void initState() {
    super.initState();
    // SE recebermos interesses do pai, carregamos eles aqui
    if (widget.initialSelection != null) {
      _selectedInterests.addAll(widget.initialSelection!);
    }
  }

  void _toggleSelection(String label) {
    setState(() {
      if (_selectedInterests.contains(label)) {
        _selectedInterests.remove(label);
      } else {
        _selectedInterests.add(label);
      }
    });
    // Se for aba, aqui você poderia chamar uma função para salvar no pai/backend
    if (widget.onSelectionChanged != null) {
      widget.onSelectionChanged!(_selectedInterests);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // Se for Aba, removemos o AppBar padrão ou ajustamos o padding
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cabeçalho (Sino) - Só mostramos se NÃO for aba (ou mantemos, depende do seu design)
              if (!widget.isTab)
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    icon: const Icon(
                      Icons.notifications_none_rounded,
                      size: 28,
                    ),
                    onPressed: () {},
                  ),
                ),

              SizedBox(height: widget.isTab ? 0 : 16),

              const Center(
                child: Text(
                  "Interesses",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),

              const SizedBox(height: 40),

              Expanded(
                child: GridView.builder(
                  itemCount: _categories.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.0,
                  ),
                  itemBuilder: (context, index) {
                    final category = _categories[index];
                    final label = category['label'] as String;
                    final icon = category['icon'] as IconData;
                    final isSelected = _selectedInterests.contains(label);

                    return GestureDetector(
                      onTap: () => _toggleSelection(label),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFFCceeff)
                              : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(16),
                          border: isSelected
                              ? Border.all(
                                  color: const Color(0xFF4169E1),
                                  width: 2,
                                )
                              : Border.all(color: Colors.transparent, width: 2),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(icon, size: 48, color: Colors.black87),
                            const SizedBox(height: 12),
                            Text(
                              label,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // O Botão Continuar só aparece no fluxo inicial (NÃO TAB)
              if (!widget.isTab) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _selectedInterests.isNotEmpty
                        ? () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MainScreen(
                                  userInterests: _selectedInterests,
                                ),
                              ),
                            );
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4169E1),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "Continuar",
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
