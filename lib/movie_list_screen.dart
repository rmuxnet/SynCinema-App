import 'package:flutter/material.dart';
import 'api_service.dart';
import 'video_screen/video_screen.dart';

class MovieListScreen extends StatefulWidget {
  const MovieListScreen({super.key});

  @override
  State<MovieListScreen> createState() => _MovieListScreenState();
}

class _MovieListScreenState extends State<MovieListScreen> {
  List<String> movies = [];
  bool isLoading = true;

  final Color bgBlack = Colors.black;
  final Color cardBg = const Color(0xFF1F2937);
  final Color accentStart = const Color(0xFF2563EB);
  final Color accentEnd = const Color(0xFF4F46E5);

  @override
  void initState() {
    super.initState();
    _loadMovies();
  }

  Future<void> _loadMovies() async {
    final list = await ApiService.getMovies();
    if (mounted) {
      setState(() {
        movies = list;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgBlack,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            // Mini Logo
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: accentEnd.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Image.asset(
                'assets/logo.png',
                width: 24,
                height: 24,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Library',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, letterSpacing: 1.0),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.grey),
            onPressed: () {
              setState(() => isLoading = true);
              _loadMovies();
            },
          )
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: accentStart))
          : movies.isEmpty
              ? const Center(child: Text("No movies found", style: TextStyle(color: Colors.grey)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: movies.length,
                  itemBuilder: (context, index) {
                    final movie = movies[index];
                    return _buildMovieCard(movie);
                  },
                ),
    );
  }

  Widget _buildMovieCard(String filename) {
    // Clean up filename for display (remove dots, extensions)
    String displayName = filename.replaceAll('.', ' ').replaceAll('mp4', '').replaceAll('mkv', '').trim();
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => VideoScreen(movieFilename: filename)),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Icon / Thumbnail Placeholder
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [accentStart, accentEnd], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(color: accentEnd.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 30),
                ),
                const SizedBox(width: 16),
                
                // Text Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Tap to watch together",
                        style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                
                // Arrow
                Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey.shade600, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}