import 'package:flutter/material.dart';
import '../models/process_model.dart';

class ProcessDetailScreen extends StatefulWidget {
  final ProcessModel process;
  final Function(String) onToggleFavorite; // Recebe a função do pai

  const ProcessDetailScreen({
    super.key,
    required this.process,
    required this.onToggleFavorite,
  });

  @override
  State<ProcessDetailScreen> createState() => _ProcessDetailScreenState();
}

class _ProcessDetailScreenState extends State<ProcessDetailScreen> {
  // Estado local para controlar a estrela visualmente enquanto estamos nesta tela
  late bool _isFavorite;

  @override
  void initState() {
    super.initState();
    // Inicializa com o valor que veio da Home
    _isFavorite = widget.process.isFavorite;
  }

  void _handleFavoriteClick() {
    setState(() {
      _isFavorite = !_isFavorite; // Inverte visualmente agora
    });
    // Avisa o "banco de dados" na tela principal para atualizar
    widget.onToggleFavorite(widget.process.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Detalhes",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  offset: const Offset(0, 2),
                  blurRadius: 4,
                )
              ]
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // 1. CARD PRINCIPAL (Agora com estrela funcional)
            _buildMainCard(),

            const SizedBox(height: 24),

            // 2. TRAMITAÇÃO
            _buildExpandableCard(
              title: "Tramitação",
              isExpanded: false,
              children: [
                _buildTimelineItem(
                  date: "14 de jan. de 2024",
                  title: "Apresentado",
                  subtitle: "Câmara dos Deputados",
                  isFirst: true,
                ),
                _buildTimelineItem(
                  date: "9 de fev. de 2024",
                  title: "Em análise na Comissão",
                  subtitle: "Comissão de Ciência e Tecnologia",
                ),
                _buildTimelineItem(
                  date: "4 de mar. de 2024",
                  title: "Audiência Pública",
                  subtitle: "Plenário",
                  isLast: true,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // 3. RESUMO
            _buildExpandableCard(
              title: "Resumo do Projeto",
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Text(
                    "O processo é um Projeto de Lei (${widget.process.id}) que propõe o ${widget.process.title}. "
                    "Seu objetivo principal é estabelecer diretrizes, princípios e regras para o desenvolvimento e uso ético, "
                    "seguro e responsável de sistemas de IA no país.",
                    style: TextStyle(fontSize: 15, height: 1.6, color: Colors.grey.shade700),
                    textAlign: TextAlign.justify,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // 4. BOTÕES DE AÇÃO
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.ios_share, color: Colors.white),
                label: const Text("Compartilhar Projeto", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4169E1),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 4,
                  shadowColor: const Color(0xFF4169E1).withValues(alpha: 0.4),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.notifications_active_outlined, color: Colors.white),
                label: const Text("Ativar Notificações", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF5350),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 4,
                  shadowColor: const Color(0xFFEF5350).withValues(alpha: 0.4),
                ),
              ),
            ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildMainCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  widget.process.id,
                  style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
              // AQUI ESTÁ A ESTRELA FUNCIONAL
              GestureDetector(
                onTap: _handleFavoriteClick,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                  child: Icon(
                    _isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
                    key: ValueKey(_isFavorite),
                    size: 32,
                    color: _isFavorite ? const Color(0xFFFFC107) : Colors.grey.shade400,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            widget.process.title,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.grey.shade900, height: 1.2),
          ),
          const SizedBox(height: 12),
          Text(
            widget.process.description,
            style: TextStyle(fontSize: 15, color: Colors.grey.shade600, height: 1.4),
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 20),
          Divider(color: Colors.grey.shade200),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 8, height: 8,
                      decoration: const BoxDecoration(color: Color(0xFF4169E1), shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.process.status,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF4169E1)),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                widget.process.date,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // WIDGET HELPERS (Mantidos iguais, apenas ajuste de estilo sutil)
  Widget _buildExpandableCard({required String title, required List<Widget> children, bool isExpanded = false}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Theme(
        data: ThemeData().copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade900)),
          initiallyExpanded: isExpanded,
          childrenPadding: EdgeInsets.zero,
          tilePadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          children: children,
        ),
      ),
    );
  }

  Widget _buildTimelineItem({required String date, required String title, required String subtitle, bool isFirst = false, bool isLast = false}) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 70, // Largura fixa para alinhar
            child: Column(
              children: [
                Expanded(child: Container(width: 2, color: isFirst ? Colors.transparent : Colors.grey.shade200)),
                Container(
                  width: 16, height: 16,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF4169E1), width: 4),
                  ),
                ),
                Expanded(child: Container(width: 2, color: isLast ? Colors.transparent : Colors.grey.shade200)),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 16, 24, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(date, style: TextStyle(fontSize: 13, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey.shade900)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}