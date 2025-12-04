import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'main_screen.dart';

class InterestsScreen extends StatefulWidget {
  // Novos parâmetros opcionais
  final Set<int>? initialSelection;
  final bool isTab; // Saber se é aba ou tela de setup
  final Function(Set<int>)? onSelectionChanged;

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
  final _apiService = ApiService();
  final Set<int> _selectedInterests = {};
  List<Map<String, dynamic>> _temas = [];
  bool _isLoading = true;
  bool _isSaving = false;

  // Mapeamento de ícones para temas
  final Map<String, IconData> _iconMapping = {
    'Tecnologia': Icons.monitor,
    'Segurança': Icons.shield_outlined,
    'Economia': Icons.attach_money,
    'Meio Ambiente': Icons.eco_outlined,
    'Educação': Icons.menu_book_outlined,
    'Saúde': Icons.vaccines_outlined,
  };

  @override
  void initState() {
    super.initState();
    _loadTemas();
    if (widget.initialSelection != null) {
      _selectedInterests.addAll(widget.initialSelection!);
    }
  }

  Future<void> _loadTemas() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _apiService.listarTemas();

      if (result['success']) {
        final temasData = result['data'] as List;
        setState(() {
          _temas = temasData
              .map((tema) => {
                    'id': tema['id_tema'],
                    'label': tema['tema'],
                    'icon': _iconMapping[tema['tema']] ?? Icons.category,
                  })
              .toList();
          _isLoading = false;
        });

        // Se for aba, carregar interesses do usuário
        if (widget.isTab && widget.initialSelection == null) {
          _loadUserInteresses();
        }
      } else {
        setState(() {
          _isLoading = false;
        });
        _showError('Erro ao carregar temas');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showError('Erro ao conectar com o servidor');
    }
  }

  Future<void> _loadUserInteresses() async {
    try {
      final result = await _apiService.obterInteressesUsuario();

      if (result['success']) {
        final interessesData = result['data'] as List;
        setState(() {
          _selectedInterests.clear();
          for (var interesse in interessesData) {
            _selectedInterests.add(interesse['id_tema']);
          }
        });
      }
    } catch (e) {
      // Silencioso - não é crítico
    }
  }

  void _toggleSelection(int id) {
    setState(() {
      if (_selectedInterests.contains(id)) {
        _selectedInterests.remove(id);
      } else {
        _selectedInterests.add(id);
      }
    });

    if (widget.onSelectionChanged != null) {
      widget.onSelectionChanged!(_selectedInterests);
    }
  }

  Future<void> _saveInteresses() async {
    if (_selectedInterests.isEmpty) {
      _showError('Selecione pelo menos um interesse');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final result = await _apiService.atualizarInteresses(_selectedInterests.toList());

      if (!mounted) return;

      if (result['success']) {
        // Navega para a tela principal
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MainScreen(
              userInterests: _selectedInterests,
            ),
          ),
        );
      } else {
        _showError(result['message'] ?? 'Erro ao salvar interesses');
      }
    } catch (e) {
      if (!mounted) return;
      _showError('Erro ao conectar com o servidor');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
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

              if (_isLoading)
                const Expanded(
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                )
              else
                Expanded(
                  child: GridView.builder(
                    itemCount: _temas.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.0,
                    ),
                    itemBuilder: (context, index) {
                      final tema = _temas[index];
                      final id = tema['id'] as int;
                      final label = tema['label'] as String;
                      final icon = tema['icon'] as IconData;
                      final isSelected = _selectedInterests.contains(id);

                      return GestureDetector(
                        onTap: () => _toggleSelection(id),
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
                    onPressed: (_selectedInterests.isNotEmpty && !_isSaving)
                        ? _saveInteresses
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4169E1),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      _isSaving ? "Salvando..." : "Continuar",
                      style: const TextStyle(fontSize: 18),
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
