import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:http/http.dart' as http;
import 'package:web_query/js.dart';
import 'package:web_query/query.dart';
import 'package:web_query/ui.dart';

import 'log.dart';

void main() {
  logInit();
  configureJsExecutor(FlutterJsExecutor());
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DataQueryWidget Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      darkTheme: ThemeData.dark(useMaterial3: true),
      themeMode: ThemeMode.dark,
      home: const HomePage(),
    );
  }
}

class HomePage extends HookWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final pageData = useState<PageData?>(null);
    final isLoading = useState(false);
    final urlController = useTextEditingController(
      text: 'https://example.com',
    );

    Future<void> loadUrl(String url) async {
      if (url.isEmpty) return;

      isLoading.value = true;
      try {
        final response = await http.get(Uri.parse(url));
        pageData.value = PageData.auto(url, response.body);
        if (response.statusCode == 200) {
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to load: ${response.statusCode}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        isLoading.value = false;
      }
    }

    // Load sample data on startup
    useEffect(() {
      loadSampleData(pageData);
      return null;
    }, []);

    return Scaffold(
      appBar: AppBar(
        title: const Text('DataQueryWidget Example'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          // URL input section
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey.shade900,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: urlController,
                    decoration: const InputDecoration(
                      labelText: 'URL',
                      hintText: 'Enter URL to fetch',
                      border: OutlineInputBorder(),
                      filled: true,
                    ),
                    onSubmitted: loadUrl,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: isLoading.value
                      ? null
                      : () => loadUrl(urlController.text),
                  icon: isLoading.value
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.download),
                  label: const Text('Fetch'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => loadSampleData(pageData),
                  icon: const Icon(Icons.code),
                  label: const Text('Load Sample'),
                ),
              ],
            ),
          ),
          // DataQueryWidget
          Expanded(
            child: pageData.value == null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search,
                          size: 64,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Load a URL or sample data to start querying',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 32),
                        const _QueryExamplesCard(),
                      ],
                    ),
                  )
                : DataQueryWidget(
                    pageData: pageData.value,
                    title: 'Query Data',
                  ),
          ),
        ],
      ),
    );
  }

  void loadSampleData(ValueNotifier<PageData?> pageData) {
    const sampleHtml = r'''<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Tech Blog - Latest Articles</title>
    <meta name="description" content="A blog about web development and technology">
    <link rel="stylesheet" href="/css/main.css">
</head>
<body>
    <header class="site-header">
        <nav class="navbar">
            <div class="logo">TechBlog</div>
            <ul class="nav-menu">
                <li><a href="/">Home</a></li>
                <li><a href="/articles">Articles</a></li>
                <li><a href="/about">About</a></li>
                <li><a href="/contact">Contact</a></li>
            </ul>
        </nav>
    </header>
    
    <main class="container">
        <article class="post featured">
            <h1>Getting Started with Flutter Web Query</h1>
            <div class="post-meta">
                <span class="author">By Jane Doe</span>
                <span class="date">December 5, 2024</span>
                <span class="category">Tutorial</span>
            </div>
            <div class="post-content">
                <p>Learn how to query HTML and JSON data efficiently using the Web Query library.</p>
                <p>This powerful tool makes web scraping and data extraction simple and intuitive.</p>
            </div>
            <div class="tags">
                <span class="tag">flutter</span>
                <span class="tag">web-scraping</span>
                <span class="tag">dart</span>
            </div>
        </article>
        
        <section class="posts-grid">
            <article class="post-card">
                <h2>Understanding CSS Selectors</h2>
                <p class="excerpt">Master the art of selecting HTML elements with CSS selectors.</p>
                <a href="/articles/css-selectors" class="read-more">Read More</a>
            </article>
            
            <article class="post-card">
                <h2>JSON Path Navigation</h2>
                <p class="excerpt">Navigate complex JSON structures with ease using JSONPath.</p>
                <a href="/articles/json-path" class="read-more">Read More</a>
            </article>
            
            <article class="post-card">
                <h2>Data Transformation Techniques</h2>
                <p class="excerpt">Transform and manipulate extracted data using built-in transforms.</p>
                <a href="/articles/transforms" class="read-more">Read More</a>
            </article>
        </section>
    </main>
    
    <footer class="site-footer">
        <div class="footer-content">
            <p>&copy; 2024 TechBlog. All rights reserved.</p>
            <ul class="social-links">
                <li><a href="https://twitter.com/techblog">Twitter</a></li>
                <li><a href="https://github.com/techblog">GitHub</a></li>
            </ul>
        </div>
    </footer>
    
    <script>
        // Sample configuration data
        var siteConfig = {
            "name": "TechBlog",
            "version": "2.0",
            "features": ["articles", "comments", "search"],
            "analytics": {
                "enabled": true,
                "provider": "custom"
            }
        };
    </script>
</body>
</html>''';

    const sampleJson = r'''{
  "site": {
    "name": "TechBlog",
    "version": "2.0",
    "url": "https://techblog.example.com",
    "description": "A blog about web development and technology"
  },
  "articles": [
    {
      "id": 1,
      "title": "Getting Started with Flutter Web Query",
      "author": {
        "name": "Jane Doe",
        "email": "jane@techblog.com",
        "avatar": "/images/jane.jpg"
      },
      "publishedAt": "2024-12-05T10:30:00Z",
      "category": "Tutorial",
      "tags": ["flutter", "web-scraping", "dart"],
      "excerpt": "Learn how to query HTML and JSON data efficiently using the Web Query library.",
      "content": "This powerful tool makes web scraping and data extraction simple and intuitive.",
      "stats": {
        "views": 1250,
        "likes": 89,
        "comments": 12
      },
      "featured": true
    },
    {
      "id": 2,
      "title": "Understanding CSS Selectors",
      "author": {
        "name": "John Smith",
        "email": "john@techblog.com",
        "avatar": "/images/john.jpg"
      },
      "publishedAt": "2024-12-03T14:15:00Z",
      "category": "Guide",
      "tags": ["css", "selectors", "web-development"],
      "excerpt": "Master the art of selecting HTML elements with CSS selectors.",
      "stats": {
        "views": 890,
        "likes": 67,
        "comments": 8
      },
      "featured": false
    },
    {
      "id": 3,
      "title": "JSON Path Navigation",
      "author": {
        "name": "Alice Johnson",
        "email": "alice@techblog.com",
        "avatar": "/images/alice.jpg"
      },
      "publishedAt": "2024-12-01T09:45:00Z",
      "category": "Tutorial",
      "tags": ["json", "data-extraction", "api"],
      "excerpt": "Navigate complex JSON structures with ease using JSONPath.",
      "stats": {
        "views": 1100,
        "likes": 95,
        "comments": 15
      },
      "featured": false
    }
  ],
  "categories": [
    {"name": "Tutorial", "count": 15, "color": "#3498db"},
    {"name": "Guide", "count": 8, "color": "#2ecc71"},
    {"name": "News", "count": 5, "color": "#e74c3c"}
  ],
  "config": {
    "theme": "dark",
    "language": "en",
    "features": {
      "comments": true,
      "search": true,
      "analytics": true,
      "newsletter": true
    },
    "social": {
      "twitter": "@techblog",
      "github": "techblog",
      "linkedin": "techblog-official"
    },
    "analytics": {
      "provider": "custom",
      "trackingId": "TB-123456789",
      "enabled": true
    }
  },
  "metadata": {
    "totalArticles": 28,
    "totalAuthors": 5,
    "lastUpdated": "2024-12-05T15:30:00Z",
    "version": "2.0.1"
  }
}''';

    pageData.value = PageData(
      'https://example.com/sample',
      sampleHtml,
      jsonData: sampleJson,
    );
  }
}

class _QueryExamplesCard extends StatelessWidget {
  const _QueryExamplesCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(32),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Query Examples',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildExample('HTML Queries', [
              'h1@text - Get h1 text content',
              '.intro@text - Get intro paragraph',
              '*li@text - Get all list items',
              'a@href - Get first link href',
              '.metadata/*span@text - Get all spans in metadata',
            ]),
            const SizedBox(height: 16),
            _buildExample('JSON Queries', [
              'json:title - Get title',
              'json:items/* - Get all items',
              'json:items/0/name - Get first item name',
              'json:metadata/author - Get author',
            ]),
            const SizedBox(height: 16),
            _buildExample('With Transforms', [
              'h1@text?transform=upper - Uppercase title',
              'a@href?regexp=/https:\\/\\/([^\\/]+).*\$/\$1/ - Extract domain',
              '*li@text?filter=JSON - Filter items containing "JSON"',
            ]),
            const SizedBox(height: 16),
            _buildExample('URL Queries', [
              'url: - Get full URL',
              'url:host - Get hostname',
              'url:?page=2 - Modify query param',
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildExample(String title, List<String> examples) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.blue,
          ),
        ),
        const SizedBox(height: 8),
        ...examples.map((example) => Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 4),
              child: Text(
                '• $example',
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13,
                ),
              ),
            )),
      ],
    );
  }
}
