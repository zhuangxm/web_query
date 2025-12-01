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
    const sampleHtml = '''
<!DOCTYPE html>
<html>
<head>
  <title>Sample Page</title>
</head>
<body>
  <div class="container">
    <h1>Welcome to Web Query</h1>
    <div class="content">
      <p class="intro">This is a sample HTML page for testing QueryString.</p>
      <ul class="features">
        <li>HTML querying with CSS selectors</li>
        <li>JSON path navigation</li>
        <li>Transform and filter data</li>
        <li>URL manipulation</li>
      </ul>
      <div class="links">
        <a href="https://github.com/example/repo">GitHub</a>
        <a href="https://example.com/docs">Documentation</a>
      </div>
    </div>
    <div class="metadata">
      <span class="author">John Doe</span>
      <span class="date">2024-01-01</span>
    </div>
  </div>
  <script id="json-data" type="application/json">
  {
    "title": "Sample Data",
    "items": [
      {"id": 1, "name": "Item 1", "price": 10.99},
      {"id": 2, "name": "Item 2", "price": 20.99},
      {"id": 3, "name": "Item 3", "price": 30.99}
    ],
    "metadata": {
      "version": "1.0",
      "author": "John Doe"
    },
    "comments": [
        "<div class='user'>Alice</div>",
        "<div class='user'>Bob</div>"
    ]
  }
  </script>
  <script>
        window.__INITIAL_STATE__ = {"user": {"id": 123, "name": "Bob"}};
  </script>
</body>
</html>
''';

    pageData.value = PageData(
      'https://example.com/sample',
      sampleHtml,
      defaultJsonId: 'json-data',
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
