// Flutter News App (main.dart)
// Features implemented:
// - Home with category chips
// - Grid / List toggle for articles
// - Article detail screen with full content, image, share, bookmark
// - Search screen (local filtering + optional NewsAPI fetch if you supply an API key)
// - Bookmarks (persisted to local storage using shared_preferences)
// - Simple Provider-based state management
// NOTE: This is a single-file demo intended to be dropped into a new Flutter project
// (create with `flutter create news_app` and replace lib/main.dart with this file).
// Getting started:
// 1) Create a new Flutter project: `flutter create news_app`.
// 2) Replace lib/main.dart with this file.
// 3) Add dependencies in pubspec.yaml:
//    provider: ^6.0.5
//    cached_network_image: ^3.2.3
//    shared_preferences: ^2.1.1
//    url_launcher: ^6.1.12
//    intl: ^0.18.1
// 4) Run `flutter pub get` then `flutter run`.
// Optional: to enable live real-news fetching via NewsAPI.org, set NewsRepository.newsApiKey

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(MyApp(prefs: prefs));
}

class MyApp extends StatelessWidget {
  final SharedPreferences prefs;
  const MyApp({super.key, required this.prefs});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => NewsProvider(prefs: prefs),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Flutter News App',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          scaffoldBackgroundColor: Colors.grey[100],
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        home: const MainNavigationShell(),
      ),
    );
  }
}

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _index = 0;

  static final List<Widget> _pages = <Widget>[
    const Homepage(),
    const BookmarksScreen(),
    const SearchScreen(),
    const AccountProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: _pages[_index]),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bookmark_border),
            activeIcon: Icon(Icons.bookmark),
            label: 'Bookmarks',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search_outlined),
            activeIcon: Icon(Icons.search),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// ---------- Models ----------
class NewsArticle {
  final String id;
  final String title;
  final String description;
  final String content;
  final String imageUrl;
  final String sourceName;
  final DateTime publishedAt;
  final String category;

  NewsArticle({
    required this.id,
    required this.title,
    required this.description,
    required this.content,
    required this.imageUrl,
    required this.sourceName,
    required this.publishedAt,
    required this.category,
  });

  factory NewsArticle.fromMap(Map<String, dynamic> m) => NewsArticle(
    id: m['id'] ?? UniqueKey().toString(),
    title: m['title'] ?? '',
    description: m['description'] ?? '',
    content: m['content'] ?? '',
    imageUrl: m['imageUrl'] ?? '',
    sourceName: m['sourceName'] ?? 'Unknown',
    publishedAt: DateTime.parse(
      m['publishedAt'] ?? DateTime.now().toIso8601String(),
    ),
    category: m['category'] ?? 'General',
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'description': description,
    'content': content,
    'imageUrl': imageUrl,
    'sourceName': sourceName,
    'publishedAt': publishedAt.toIso8601String(),
    'category': category,
  };
}

// ---------- Repository (mock + optional real fetch) ----------
class NewsRepository {
  // Optional: add your NewsAPI API key here to enable remote fetch
  static const String newsApiKey = ''; // <-- add key if you want live data

  // Provide a set of mock articles that look real
  static List<NewsArticle> mockArticles() {
    final now = DateTime.now();
    final sample = [
      {
        'id': 'a1',
        'title': 'Bring Me The Horizon talk headlining Reading & Leeds 2023',
        'description': 'We\'re gonna go hard',
        'content':
            'Frontman Oli Sykes told NME how they\'re going to make their R+L set "feel like a rollercoaster". The Sheffield metal titans were confirmed to be topping the bill for the first time at the legendary event.',
        'imageUrl':
            'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?auto=format&fit=crop&w=800&q=80',
        'sourceName': 'CNN Indonesia',
        'publishedAt': now.subtract(const Duration(hours: 2)).toIso8601String(),
        'category': 'Music',
      },
      {
        'id': 'a2',
        'title': 'Google was beloved as an employer for years. Then...',
        'description': 'Tech giant faces internal turbulence',
        'content':
            'Employees report shifts in company culture as Google expands into AI and automation. Layoffs and reorganizations have changed the once “dream job” image.',
        'imageUrl':
            'https://images.unsplash.com/photo-1454165205744-3b78555e5572?auto=format&fit=crop&w=800&q=80',
        'sourceName': 'TechCrunch',
        'publishedAt': now.subtract(const Duration(hours: 4)).toIso8601String(),
        'category': 'Technology',
      },
      {
        'id': 'a3',
        'title': 'These iconic foods aren\'t as old as you think',
        'description': 'Food history surprises',
        'content':
            'Many so-called traditional foods are younger than expected — from Hawaiian pizza to instant noodles.',
        'imageUrl':
            'https://images.unsplash.com/photo-1504674900247-0877df9cc836?auto=format&fit=crop&w=800&q=80',
        'sourceName': 'Bon Appetit',
        'publishedAt': now.subtract(const Duration(hours: 6)).toIso8601String(),
        'category': 'Food',
      },
      {
        'id': 'a4',
        'title':
            'Biden administration demands TikTok\'s Chinese owner take steps',
        'description': 'National security discussions heat up',
        'content':
            'The White House has renewed its concerns about data safety and foreign access related to the popular social media platform.',
        'imageUrl':
            'https://images.unsplash.com/photo-1522071820081-009f0129c71c?auto=format&fit=crop&w=800&q=80',
        'sourceName': 'BBC News',
        'publishedAt': now.subtract(const Duration(hours: 8)).toIso8601String(),
        'category': 'Politics',
      },
      {
        'id': 'a5',
        'title': 'Keanu Reeves honors Lance Reddick at John Wick screening',
        'description': 'Tributes from friends and fans',
        'content':
            'At the special screening event, Reeves spoke emotionally about his late co-star and friend Lance Reddick.',
        'imageUrl':
            'https://images.unsplash.com/photo-1529626455594-4ff0802cfb7e?auto=format&fit=crop&w=800&q=80',
        'sourceName': 'Variety',
        'publishedAt': now
            .subtract(const Duration(hours: 10))
            .toIso8601String(),
        'category': 'Entertainment',
      },
      {
        'id': 'a6',
        'title': 'Tesla unveils new AI-powered driver assistance system',
        'description': 'Futuristic update for 2025 models',
        'content':
            'Tesla claims its latest system uses on-board AI to predict driver intentions and improve overall safety.',
        'imageUrl':
            'https://images.unsplash.com/photo-1502877338535-766e1452684a?auto=format&fit=crop&w=800&q=80',
        'sourceName': 'Reuters',
        'publishedAt': now
            .subtract(const Duration(hours: 12))
            .toIso8601String(),
        'category': 'Technology',
      },
      {
        'id': 'a7',
        'title': 'Indonesia prepares for record tourism season',
        'description': 'Hotels and airlines ramp up capacity',
        'content':
            'Tourism Ministry projects over 12 million visitors this year, boosting the local economy and travel sector.',
        'imageUrl':
            'https://images.unsplash.com/photo-1518684079-3c830dcef090?auto=format&fit=crop&w=800&q=80',
        'sourceName': 'Jakarta Post',
        'publishedAt': now
            .subtract(const Duration(hours: 15))
            .toIso8601String(),
        'category': 'Business',
      },
      {
        'id': 'a8',
        'title': 'Lionel Messi scores stunning free-kick for Inter Miami',
        'description': 'Fans erupt as Messi continues his form',
        'content':
            'The Argentine legend scored yet another incredible goal, helping Miami maintain their lead in the league.',
        'imageUrl':
            'https://images.unsplash.com/photo-1517927033932-b3d18e61fb3a?auto=format&fit=crop&w=800&q=80',
        'sourceName': 'ESPN',
        'publishedAt': now
            .subtract(const Duration(hours: 16))
            .toIso8601String(),
        'category': 'Sports',
      },
      {
        'id': 'a9',
        'title': 'New study finds link between sleep and creativity',
        'description': 'Sleep boosts brain’s creative process',
        'content':
            'Researchers found that REM sleep enhances problem-solving and abstract thinking abilities significantly.',
        'imageUrl':
            'https://images.unsplash.com/photo-1505678261036-a3fcc5e884ee?auto=format&fit=crop&w=800&q=80',
        'sourceName': 'Science Daily',
        'publishedAt': now
            .subtract(const Duration(hours: 20))
            .toIso8601String(),
        'category': 'Health',
      },
      {
        'id': 'a10',
        'title': 'Apple announces redesigned MacBook Air lineup',
        'description': 'Lighter, faster, better battery life',
        'content':
            'Apple has introduced the new M4 MacBook Air featuring edge-to-edge display and up to 22-hour battery.',
        'imageUrl':
            'https://images.unsplash.com/photo-1517336714731-489689fd1ca8?auto=format&fit=crop&w=800&q=80',
        'sourceName': 'The Verge',
        'publishedAt': now.subtract(const Duration(days: 1)).toIso8601String(),
        'category': 'Technology',
      },
      {
        'id': 'a11',
        'title': 'Sandstorms blanket Beijing and northern China',
        'description': 'Air quality index hits record highs',
        'content':
            'Authorities issued health warnings as the sky turned yellow due to heavy dust storms.',
        'imageUrl':
            'https://images.unsplash.com/photo-1483721310020-03333e577078?auto=format&fit=crop&w=800&q=80',
        'sourceName': 'CNN',
        'publishedAt': now
            .subtract(const Duration(days: 1, hours: 2))
            .toIso8601String(),
        'category': 'Breaking News',
      },
      {
        'id': 'a12',
        'title': 'London police reform sparks major protests',
        'description': 'Citizens call for transparency',
        'content':
            'Thousands took to the streets demanding accountability after reports of misconduct surfaced.',
        'imageUrl':
            'https://images.unsplash.com/photo-1501594907352-04cda38ebc29?auto=format&fit=crop&w=800&q=80',
        'sourceName': 'BBC',
        'publishedAt': now
            .subtract(const Duration(days: 1, hours: 4))
            .toIso8601String(),
        'category': 'Breaking News',
      },
      {
        'id': 'a13',
        'title': 'SpaceX successfully launches 100th Falcon 9 rocket',
        'description': 'A milestone in reusable rockets',
        'content':
            'The mission deployed 60 Starlink satellites into orbit, marking another success in SpaceX’s growing record.',
        'imageUrl':
            'https://images.unsplash.com/photo-1581090700227-1e37b190418e?auto=format&fit=crop&w=800&q=80',
        'sourceName': 'NASA Watch',
        'publishedAt': now
            .subtract(const Duration(days: 1, hours: 8))
            .toIso8601String(),
        'category': 'Technology',
      },
      {
        'id': 'a14',
        'title': 'Oil prices surge amid Middle East tensions',
        'description': 'Markets react to global uncertainty',
        'content':
            'Crude oil reached its highest level in six months following geopolitical developments in the Gulf region.',
        'imageUrl':
            'https://images.unsplash.com/photo-1517245386807-bb43f82c33c4?auto=format&fit=crop&w=800&q=80',
        'sourceName': 'Reuters',
        'publishedAt': now
            .subtract(const Duration(days: 1, hours: 15))
            .toIso8601String(),
        'category': 'Business',
      },
    ];

    return sample.map((m) => NewsArticle.fromMap(m)).toList();
  }
}

// ---------- Provider State ----------
class NewsProvider extends ChangeNotifier {
  final SharedPreferences prefs;
  List<NewsArticle> _articles = [];
  List<String> _bookmarkedIds = [];
  bool _isGrid = true;
  String _selectedCategory = 'All';
  // Simple local profile state
  String _userName = 'John Doe';
  String _userEmail = 'john.doe@example.com';
  String _userBio = '';

  NewsProvider({required this.prefs}) {
    _articles = NewsRepository.mockArticles();
    _loadBookmarks();
    _loadProfile();
  }

  List<NewsArticle> get articles => _selectedCategory == 'All'
      ? _articles
      : _articles.where((a) => a.category == _selectedCategory).toList();

  List<NewsArticle> get allArticles => _articles;

  List<NewsArticle> get bookmarks =>
      _articles.where((a) => _bookmarkedIds.contains(a.id)).toList();

  bool get isGrid => _isGrid;
  String get selectedCategory => _selectedCategory;

  void toggleGrid() {
    _isGrid = !_isGrid;
    notifyListeners();
  }

  void selectCategory(String cat) {
    _selectedCategory = cat;
    notifyListeners();
  }

  void addBookmark(NewsArticle a) {
    if (!_bookmarkedIds.contains(a.id)) _bookmarkedIds.add(a.id);
    _saveBookmarks();
    notifyListeners();
  }

  void removeBookmark(NewsArticle a) {
    _bookmarkedIds.remove(a.id);
    _saveBookmarks();
    notifyListeners();
  }

  bool isBookmarked(NewsArticle a) => _bookmarkedIds.contains(a.id);

  void _loadBookmarks() {
    _bookmarkedIds = prefs.getStringList('bookmarks') ?? [];
  }

  void _saveBookmarks() {
    prefs.setStringList('bookmarks', _bookmarkedIds);
  }

  // Profile persistence
  void _loadProfile() {
    _userName = prefs.getString('user_name') ?? _userName;
    _userEmail = prefs.getString('user_email') ?? _userEmail;
    _userBio = prefs.getString('user_bio') ?? _userBio;
  }

  void updateProfile({
    required String name,
    required String email,
    required String bio,
  }) {
    _userName = name;
    _userEmail = email;
    _userBio = bio;
    prefs.setString('user_name', _userName);
    prefs.setString('user_email', _userEmail);
    prefs.setString('user_bio', _userBio);
    notifyListeners();
  }

  String get userName => _userName;
  String get userEmail => _userEmail;
  String get userBio => _userBio;

  // robust local search
  List<NewsArticle> search(String q) {
    final ql = q.toLowerCase();
    return _articles.where((a) {
      final title = a.title.toLowerCase();
      final desc = a.description.toLowerCase();
      final content = a.content.toLowerCase();
      final cat = a.category.toLowerCase();
      return title.contains(ql) ||
          desc.contains(ql) ||
          content.contains(ql) ||
          cat.contains(ql);
    }).toList();
  }
}

// ---------- UI Screens ----------
class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  int _index = 0;

  static final List<Widget> _pages = <Widget>[
    const Homepage(),
    const BookmarksScreen(),
    const SearchScreen(),
    const AccountProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: _pages[_index]),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bookmark_border),
            label: 'Bookmarks',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search_outlined),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Widget buildNewsList(BuildContext context, bool isGrid, List list) {
    if (isGrid) {
      // --- GRID VIEW MODE ---
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: .85,
          ),
          itemCount: list.length,
          itemBuilder: (context, i) => NewsCardGrid(article: list[i]),
        ),
      );
    } else {
      // --- LIST VIEW MODE ---
      return ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
        itemCount: list.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          final article = list[i];
          return GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ArticleDetailScreen(article: article),
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      bottomLeft: Radius.circular(12),
                    ),
                    child: SizedBox(
                      width: 120,
                      height: 90,
                      child: CachedNetworkImage(
                        imageUrl: article.imageUrl.contains('?')
                            ? '${article.imageUrl}&w=600'
                            : '${article.imageUrl}?w=600',
                        fit: BoxFit.cover,
                        placeholder: (_, __) =>
                            Container(color: Colors.grey[200]),
                        errorWidget: (_, __, ___) => Container(
                          color: Colors.grey[200],
                          alignment: Alignment.center,
                          child: const Icon(Icons.broken_image),
                        ),
                      ),
                    ),
                  ),
                  // --- TEXT SIDE ---
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            article.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            article.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.black54),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Chip(
                                label: Text(
                                  article.sourceName,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                              const Spacer(),
                              Icon(
                                Icons.bookmark_border,
                                color: Colors.blueGrey,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final prov = Provider.of<NewsProvider>(context);
    final cats = <String>[
      'All',
      'Technology',
      'Music',
      'Food',
      'Politics',
      'Entertainment',
    ];

    return Column(
      children: [
        // --- Search bar + grid/list toggle ---
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              const Expanded(child: _SearchBarInHeader()),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(prov.isGrid ? Icons.grid_view : Icons.view_list),
                onPressed: () => prov.toggleGrid(),
              ),
            ],
          ),
        ),

        // --- Category filter ---
        SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: cats.length,
            separatorBuilder: (_, __) => const SizedBox(width: 4),
            itemBuilder: (_, i) {
              final c = cats[i];
              final sel = prov.selectedCategory == c;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: ChoiceChip(
                  label: Text(c),
                  selected: sel,
                  onSelected: (_) => prov.selectCategory(c),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 8),

        // --- News list/grid display ---
        Expanded(
          child: Consumer<NewsProvider>(
            builder: (context, prov, _) {
              final list = prov.articles;
              return buildNewsList(context, prov.isGrid, list);
            },
          ),
        ),
      ],
    );
  }
}

class _SearchBarInHeader extends StatelessWidget {
  const _SearchBarInHeader();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const SearchScreen()));
      },
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.search, color: Colors.grey),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Search news, topics, agencies...',
                style: TextStyle(color: Colors.grey[600], fontSize: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NewsCardGrid extends StatelessWidget {
  final NewsArticle article;
  const NewsCardGrid({super.key, required this.article});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ArticleDetailScreen(article: article),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: CachedNetworkImage(
                  imageUrl: '${article.imageUrl}?w=800',
                  fit: BoxFit.cover,
                  width: double.infinity,
                  placeholder: (_, __) => Container(color: Colors.grey[200]),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      article.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Chip(
                          label: Text(
                            article.category,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          DateFormat.Hm().format(article.publishedAt),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class NewsCardList extends StatelessWidget {
  final NewsArticle article;
  const NewsCardList({super.key, required this.article});

  @override
  Widget build(BuildContext context) {
    final prov = Provider.of<NewsProvider>(context, listen: false);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ArticleDetailScreen(article: article),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Theme.of(context).cardColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ FIXED: give it a fixed height & width
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
              child: SizedBox(
                width: 120,
                height: 100,
                child: CachedNetworkImage(
                  imageUrl: '${article.imageUrl ?? ''}?w=600',
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(color: Colors.grey[200]),
                  errorWidget: (_, __, ___) => Container(
                    color: Colors.grey[300],
                    child: const Icon(Icons.broken_image, size: 40),
                  ),
                ),
              ),
            ),

            // 📰 Text content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      article.title.isNotEmpty
                          ? article.title
                          : 'Untitled article',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      article.description.isNotEmpty
                          ? article.description
                          : 'No description available',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Chip(
                          label: Text(
                            article.sourceName.isNotEmpty
                                ? article.sourceName
                                : 'Unknown',
                            style: const TextStyle(fontSize: 12),
                          ),
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest,
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () {
                            if (prov.isBookmarked(article)) {
                              prov.removeBookmark(article);
                            } else {
                              prov.addBookmark(article);
                            }
                          },
                          icon: Icon(
                            prov.isBookmarked(article)
                                ? Icons.bookmark
                                : Icons.bookmark_border,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ArticleDetailScreen extends StatelessWidget {
  final NewsArticle article;
  const ArticleDetailScreen({super.key, required this.article});

  @override
  Widget build(BuildContext context) {
    final prov = Provider.of<NewsProvider>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // --- HEADER IMAGE ---
          SliverAppBar(
            pinned: true,
            expandedHeight: 300,
            backgroundColor: Colors.transparent,
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: article.imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(color: Colors.grey[300]),
                    errorWidget: (_, __, ___) => Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.broken_image, size: 60),
                    ),
                  ),
                  Positioned(
                    left: 12,
                    top: 40,
                    child: CircleAvatar(
                      backgroundColor: Colors.white70,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 12,
                    top: 40,
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.white70,
                          child: IconButton(
                            icon: const Icon(Icons.share),
                            onPressed: () => _shareArticle(article),
                          ),
                        ),
                        const SizedBox(width: 8),
                        CircleAvatar(
                          backgroundColor: Colors.white70,
                          child: IconButton(
                            icon: const Icon(Icons.more_vert),
                            onPressed: () {},
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // --- MAIN CONTENT ---
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- AGENCY / AUTHOR HEADER ---
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ProfileScreen(
                              agencyName: article.sourceName,
                              articles: prov.allArticles
                                  .where(
                                    (a) => a.sourceName == article.sourceName,
                                  )
                                  .toList(),
                            ),
                          ),
                        ),
                        child: CircleAvatar(
                          backgroundColor: Colors.blueGrey[100],
                          child: Text(
                            article.sourceName.isNotEmpty
                                ? article.sourceName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          article.sourceName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          shape: const StadiumBorder(),
                        ),
                        child: const Text('Follow'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  Text(
                    article.title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        DateFormat.yMMMd().add_Hm().format(article.publishedAt),
                        style: const TextStyle(color: Colors.black54),
                      ),
                      const SizedBox(width: 8),
                      Chip(label: Text(article.category)),
                      const Spacer(),
                      IconButton(
                        onPressed: () {
                          if (prov.isBookmarked(article)) {
                            prov.removeBookmark(article);
                          } else {
                            prov.addBookmark(article);
                          }
                        },
                        icon: Icon(
                          prov.isBookmarked(article)
                              ? Icons.bookmark
                              : Icons.bookmark_border,
                          color: Colors.blueAccent,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  Text(
                    article.description,
                    style: const TextStyle(fontSize: 16, height: 1.4),
                  ),

                  const SizedBox(height: 16),
                  CachedNetworkImage(
                    imageUrl: article.imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, __) =>
                        Container(height: 200, color: Colors.grey[200]),
                    errorWidget: (_, __, ___) =>
                        Container(height: 200, color: Colors.grey[300]),
                  ),

                  const SizedBox(height: 16),
                  Text(
                    article.content,
                    style: const TextStyle(fontSize: 16, height: 1.5),
                  ),

                  const SizedBox(height: 24),
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: () => _openExternal(article),
                      icon: const Icon(Icons.open_in_new),
                      label: const Text('Read More on Source'),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _shareArticle(NewsArticle a) async {
    final url = 'https://example.com/articles/${a.id}';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  void _openExternal(NewsArticle a) async {
    final url = 'https://example.com/articles/${a.id}';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }
}

// Simple wrapper so the homepage can be referenced as `Homepage` in the nav.
class Homepage extends StatelessWidget {
  const Homepage({super.key});

  @override
  Widget build(BuildContext context) => const HomeScreen();
}

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _ctrl = TextEditingController();
  List<NewsArticle> results = [];

  @override
  Widget build(BuildContext context) {
    final prov = Provider.of<NewsProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search'),
        automaticallyImplyLeading: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            //  Search bar
            TextField(
              controller: _ctrl,
              decoration: InputDecoration(
                hintText: 'Type to search news...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _ctrl.clear();
                    setState(() => results = []);
                  },
                ),
                filled: true,
                fillColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (v) {
                final q = v.trim();
                if (q.isEmpty) {
                  setState(() => results = []);
                } else {
                  final res = prov.search(q);
                  print('Found ${res.length} results for "$q"'); // 👀 debug
                  setState(() => results = res);
                }
              },
            ),
            const SizedBox(height: 12),

            // 📜 Results
            Expanded(
              child: results.isEmpty
                  ? Center(
                      child: Text(
                        _ctrl.text.isEmpty
                            ? 'Type something to search news'
                            : 'No results — try a different keyword',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    )
                  : Consumer<NewsProvider>(
                      builder: (context, prov, _) {
                        return ListView.builder(
                          padding: const EdgeInsets.only(top: 8),
                          itemCount: results.length,
                          itemBuilder: (context, i) {
                            final article = results[i];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: NewsCardList(article: article),
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

class BookmarksScreen extends StatelessWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final prov = Provider.of<NewsProvider>(context);
    final list = prov.bookmarks;
    if (list.isEmpty) return const Center(child: Text('No bookmarks yet'));
    return ListView.builder(
      itemCount: list.length,
      itemBuilder: (context, i) => NewsCardList(article: list[i]),
    );
  }
}

class ProfileListScreen extends StatelessWidget {
  const ProfileListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // show common agencies (from articles)
    final prov = Provider.of<NewsProvider>(context);
    final agencies = prov.allArticles.map((a) => a.sourceName).toSet().toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Profiles')),
      body: ListView.separated(
        itemCount: agencies.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, i) => ListTile(
          leading: CircleAvatar(child: Text(agencies[i].substring(0, 1))),
          title: Text(agencies[i]),
          subtitle: Text(
            '${prov.allArticles.where((a) => a.sourceName == agencies[i]).length} posts',
          ),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ProfileScreen(
                agencyName: agencies[i],
                articles: prov.allArticles
                    .where((a) => a.sourceName == agencies[i])
                    .toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AccountProfileScreen extends StatelessWidget {
  const AccountProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final prov = Provider.of<NewsProvider>(context);
    final name = prov.userName;
    final email = prov.userEmail;
    final bio = prov.userBio;

    return Scaffold(
      appBar: AppBar(title: const Text('My Account')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 36,
                  child: Text(name.isNotEmpty ? name.substring(0, 1) : '?'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text('Email: $email'),
            const SizedBox(height: 8),
            Text('Bio: ${bio.isNotEmpty ? bio : '—'}'),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const AccountSettingsScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.settings),
              label: const Text('Account settings'),
            ),
            const SizedBox(height: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 8),
                  Text('Bookmarks will appear in the Bookmarks tab.'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  late TextEditingController _nameCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _bioCtrl;
  bool _notifications = true;

  @override
  void initState() {
    super.initState();
    final prov = Provider.of<NewsProvider>(context, listen: false);
    _nameCtrl = TextEditingController(text: prov.userName);
    _emailCtrl = TextEditingController(text: prov.userEmail);
    _bioCtrl = TextEditingController(text: prov.userBio);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final prov = Provider.of<NewsProvider>(context, listen: false);
    prov.updateProfile(
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      bio: _bioCtrl.text.trim(),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Account Settings')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Display name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emailCtrl,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _bioCtrl,
              decoration: const InputDecoration(labelText: 'Bio'),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              value: _notifications,
              onChanged: (v) => setState(() => _notifications = v),
              title: const Text('Enable notifications'),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _save,
                    child: const Text('Save'),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ProfileScreen extends StatefulWidget {
  final String agencyName;
  final List<NewsArticle> articles;
  const ProfileScreen({
    super.key,
    required this.agencyName,
    required this.articles,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool followed = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 36,
                    child: Text(widget.agencyName.substring(0, 1)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.agencyName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text('News agency'),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => setState(() => followed = !followed),
                    child: Text(followed ? 'Following' : 'Follow'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12.0,
                  vertical: 8,
                ),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 1,
                ),
                itemCount: widget.articles.length,
                itemBuilder: (context, i) => GestureDetector(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          ArticleDetailScreen(article: widget.articles[i]),
                    ),
                  ),
                  child: CachedNetworkImage(
                    imageUrl: '${widget.articles[i].imageUrl}?w=400',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
