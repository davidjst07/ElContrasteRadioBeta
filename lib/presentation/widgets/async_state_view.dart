import 'package:flutter/material.dart';

/// Centraliza las ramas waiting/error/empty/data que se repetían en cada
/// `FutureBuilder`. `loadingBuilder` es opcional para poder seguir usando
/// skeletons de shimmer en vez de un spinner genérico.
class AsyncStateView<T> extends StatelessWidget {
  final AsyncSnapshot<T> snapshot;
  final Widget Function(BuildContext context, T data) builder;
  final bool Function(T data)? isEmpty;
  final String emptyMessage;
  final WidgetBuilder? loadingBuilder;
  final String Function(Object error)? errorMessage;

  const AsyncStateView({
    super.key,
    required this.snapshot,
    required this.builder,
    this.isEmpty,
    this.emptyMessage = 'No hay datos disponibles.',
    this.loadingBuilder,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return loadingBuilder?.call(context) ??
          const Center(child: CircularProgressIndicator());
    }

    if (snapshot.hasError) {
      final error = snapshot.error!;
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            errorMessage?.call(error) ?? 'Ocurrió un error: $error',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final data = snapshot.data;
    if (data == null || (isEmpty?.call(data) ?? false)) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Text(emptyMessage, textAlign: TextAlign.center),
        ),
      );
    }

    return builder(context, data);
  }
}
