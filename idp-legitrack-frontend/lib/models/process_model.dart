class ProcessModel {
  final String id;
  final String title;
  final String description;
  final String status;
  final String date;
  bool isFavorite; // Não é 'final' porque pode mudar

  ProcessModel({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.date,
    this.isFavorite = false,
  });
}