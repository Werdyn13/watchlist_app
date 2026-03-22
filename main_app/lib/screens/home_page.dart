import 'package:flutter/material.dart';
import 'package:main_app/services/supabase_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final service = SupabaseService();
  static const int pageSize = 5;

  List<Map<String, dynamic>> movies = [];
  String filter = "all";
  String search = "";
  int pageIndex = 0;
  bool hasNextPage = false;
  bool loading = false;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() => loading = true);

    final offset = pageIndex * pageSize;
    final pageData = await service.getMoviesPage(
      offset: offset,
      limit: pageSize + 1,
      filter: filter,
      search: search,
    );

    setState(() {
      movies = pageData.take(pageSize).toList();
      hasNextPage = pageData.length > pageSize;
      loading = false;
    });
  }

  Future<void> changePage(int delta) async {
    if (loading) return;

    final newIndex = pageIndex + delta;
    if (newIndex < 0 || (delta > 0 && !hasNextPage)) return;

    pageIndex = newIndex;
    await load();
  }

  Future<void> reloadAfterMutation() async {
    await load();
    if (movies.isEmpty && pageIndex > 0) {
      pageIndex--;
      await load();
    }
  }

  Future<void> showMovieDialog({Map<String, dynamic>? movie}) async {
    final title = TextEditingController(text: movie?['title'] ?? '');
    final desc = TextEditingController(text: movie?['description'] ?? '');
    String type = movie?['type'] ?? 'Film';
    int rating = movie?['rating'] ?? 3;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: Text(movie == null ? "Přidat" : "Upravit"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTextField("Název", title),
              _buildTextField("Popis", desc),
              DropdownButton<String>(
                value: type,
                items: ["Film", "Serial"]
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setStateDialog(() => type = v!),
              ),
              const SizedBox(height: 10),
              Row(
                children: List.generate(5, (i) {
                  return IconButton(
                    icon: Icon(i < rating ? Icons.star : Icons.star_border),
                    onPressed: () => setStateDialog(() => rating = i + 1),
                  );
                }),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Zrušit")),
            ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text("Uložit"))
          ],
        ),
      ),
    );

    if (ok == true) {
      if (movie == null) {
        await service.addMovie({
          "title": title.text,
          "description": desc.text,
          "type": type,
          "watched": false,
          "rating": rating,
        });
      } else {
        await service.updateMovie(movie['id'], {
          "title": title.text,
          "description": desc.text,
          "type": type,
          "rating": rating,
        });
      }
      await reloadAfterMutation();
    }
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
    );
  }

  Future<void> deleteMovie(Map<String, dynamic> movie) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Smazat film'),
        content: Text('Opravdu smazat "${movie['title']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Ne'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ano'),
          ),
        ],
      ),
    );

    if (ok == true) {
      await service.deleteMovie(movie['id']);
      await reloadAfterMutation();
    }
  }

  void showDetail(Map movie) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(movie['title']),
        content: Text(movie['description'] ?? "Bez popisu"),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          decoration: const InputDecoration(
            hintText: "Hledat...",
            border: InputBorder.none,
          ),
          onChanged: (v) async {
            search = v.toLowerCase();
            pageIndex = 0;
            await load();
          },
        ),
        actions: [
          DropdownButton(
            value: filter,
            items: const [
              DropdownMenuItem(value: "all", child: Text("Vše")),
              DropdownMenuItem(value: "film", child: Text("Filmy")),
              DropdownMenuItem(value: "serial", child: Text("Seriály")),
              DropdownMenuItem(value: "watched", child: Text("Zhlédnuté")),
            ],
            onChanged: (v) async {
              filter = v!;
              pageIndex = 0;
              await load();
            },
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showMovieDialog(),
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: load,
        child: Column(
          children: [
            Expanded(
              child: loading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      padding: EdgeInsets.only(bottom: 130 + bottomInset),
                      itemCount: movies.length,
                      itemBuilder: (context, i) {
                        final m = movies[i];

                        return Card(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          child: ListTile(
                            title: Text(
                              m['title'],
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  m['type'], // 👈 Film / Serial
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.grey),
                                ),
                                Row(
                                  children: List.generate(
                                    m['rating'] ?? 0,
                                    (i) => const Icon(
                                      Icons.star,
                                      size: 16,
                                      color: Colors.amber,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            leading: Icon(
                              m['watched'] == true
                                  ? Icons.check_circle
                                  : Icons.radio_button_unchecked,
                              color: m['watched'] == true
                                  ? Colors.green
                                  : null,
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () =>
                                      showMovieDialog(movie: m),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () => deleteMovie(m),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.visibility),
                                  onPressed: () async {
                                    await service.toggleWatched(
                                        m['id'], m['watched']);
                                    await load();
                                  },
                                ),
                              ],
                            ),
                            onTap: () => showDetail(m),
                          ),
                        );
                      },
                    ),
            ),
            Padding(
              padding:
                  EdgeInsets.fromLTRB(12, 8, 12, 92 + bottomInset),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  OutlinedButton(
                    onPressed: (pageIndex == 0 || loading)
                        ? null
                        : () => changePage(-1),
                    child: const Text('Předchozí'),
                  ),
                  Text('Strana ${pageIndex + 1}'),
                  OutlinedButton(
                    onPressed: (!hasNextPage || loading)
                        ? null
                        : () => changePage(1),
                    child: const Text('Další'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}