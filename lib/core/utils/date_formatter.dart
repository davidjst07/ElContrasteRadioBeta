String formatRelativeDate(DateTime date, {DateTime? now}) {
  final reference = now ?? DateTime.now();
  final difference = reference.difference(date);

  if (difference.inDays == 0) {
    return 'Hoy';
  } else if (difference.inDays == 1) {
    return 'Ayer';
  } else if (difference.inDays < 7) {
    return 'Hace ${difference.inDays} días';
  } else {
    return '${date.day}/${date.month}/${date.year}';
  }
}
