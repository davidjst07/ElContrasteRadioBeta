import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:elcontrasteapp/core/di/service_locator.dart';
import 'package:elcontrasteapp/data/services/news_service.dart';
import 'package:elcontrasteapp/data/local/news_cache_store.dart';
import 'package:elcontrasteapp/presentation/blocs/news/news_cubit.dart';
import 'package:elcontrasteapp/presentation/widgets/news_list_tile.dart';

class NewsSearchPage extends StatefulWidget {
  const NewsSearchPage({super.key});

  @override
  State<NewsSearchPage> createState() => _NewsSearchPageState();
}

class _NewsSearchPageState extends State<NewsSearchPage> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;
  String _term = '';

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      setState(() => _term = value.trim());
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white, fontSize: 18),
          cursorColor: Colors.white,
          decoration: const InputDecoration(
            hintText: 'Buscar noticias...',
            hintStyle: TextStyle(color: Colors.white70),
            border: InputBorder.none,
          ),
          onChanged: _onChanged,
        ),
      ),
      body: _term.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Text(
                  'Escribe algo para buscar noticias.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : BlocProvider<NewsCubit>(
              key: ValueKey(_term),
              lazy: false,
              create: (_) => NewsCubit(
                newsService: getIt<NewsService>(),
                cacheStore: getIt<NewsCacheStore>(),
                categoryId: null,
                search: _term,
              )..fetchInitial(),
              child: const _SearchResultsList(),
            ),
    );
  }
}

class _SearchResultsList extends StatefulWidget {
  const _SearchResultsList();

  @override
  State<_SearchResultsList> createState() => _SearchResultsListState();
}

class _SearchResultsListState extends State<_SearchResultsList> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      context.read<NewsCubit>().loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NewsCubit, NewsState>(
      builder: (context, state) {
        if (state.status == NewsStatus.loading ||
            state.status == NewsStatus.initial) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.status == NewsStatus.error) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                'Error al buscar: ${state.errorMessage}',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        if (state.posts.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Text(
                'No se encontraron noticias para esa búsqueda.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        return ListView.builder(
          controller: _scrollController,
          itemCount: state.posts.length + (state.hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index >= state.posts.length) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            return NewsListTile(post: state.posts[index]);
          },
        );
      },
    );
  }
}
