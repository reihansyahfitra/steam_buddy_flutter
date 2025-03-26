import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_html/flutter_html.dart';
import 'package:provider/provider.dart';
import 'package:steam_buddy/currency_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:steam_buddy/theme_provider.dart';

class GameDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> game;

  const GameDetailsScreen({super.key, required this.game});

  @override
  State<GameDetailsScreen> createState() => _GameDetailsScreenState();
}

class _GameDetailsScreenState extends State<GameDetailsScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  Map<String, dynamic> _gameDetails = {};
  List<String> _screenshots = [];
  List<Map<String, dynamic>> _videos = [];
  String _currencyCode = 'US';
  bool _isVideoPlaying = false;
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _fetchGameDetails();
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _chewieController?.dispose();
    _tabController?.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final currencyProvider = Provider.of<CurrencyProvider>(context);
    if (_currencyCode != currencyProvider.currencyCode) {
      _currencyCode = currencyProvider.currencyCode;
      _fetchGameDetails();
    }
  }

  void _playVideo(String url) {
    _videoController?.dispose();
    _chewieController?.dispose();

    setState(() {
      _isVideoPlaying = true;
    });

    _videoController = VideoPlayerController.networkUrl(Uri.parse(url));
    _videoController!
        .initialize()
        .then((_) {
          _chewieController = ChewieController(
            videoPlayerController: _videoController!,
            autoPlay: true,
            looping: false,
            aspectRatio: 16 / 9,
            errorBuilder: (context, errorMessage) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, color: Colors.red, size: 40),
                    const SizedBox(height: 10),
                    Text('Error: $errorMessage'),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () {
                        launchUrl(
                          Uri.parse(url),
                          mode: LaunchMode.externalApplication,
                        );
                      },
                      child: const Text('Watch in Browser'),
                    ),
                  ],
                ),
              );
            },
          );

          setState(() {});
        })
        .catchError((error) {
          setState(() {
            _isVideoPlaying = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error playing video: $error'),
              action: SnackBarAction(
                label: 'Watch in Browser',
                onPressed: () {
                  launchUrl(
                    Uri.parse(url),
                    mode: LaunchMode.externalApplication,
                  );
                },
              ),
            ),
          );
        });
  }

  Future<void> _fetchGameDetails() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse(
          'https://store.steampowered.com/api/appdetails?appids=${widget.game['id']}&cc=$_currencyCode',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['${widget.game['id']}']['success'] == true) {
          final gameData = data['${widget.game['id']}']['data'];

          List<String> screenshots = [];
          if (gameData.containsKey('screenshots')) {
            screenshots = List<String>.from(
              gameData['screenshots'].map((s) => s['path_full']),
            );
          }

          List<Map<String, dynamic>> videos = [];
          if (gameData.containsKey('moveis')) {
            videos = List<Map<String, dynamic>>.from(
              gameData['moveis'].map(
                (movie) => {
                  'name': movie['name'],
                  'thumbnail': movie['thumbnail'],
                  'url': movie['mp4']['max'],
                  'highlight': movie['highlight'],
                },
              ),
            );
          }

          setState(() {
            _gameDetails = gameData;
            _screenshots = screenshots;
            _videos = videos;
            _isLoading = false;
          });
        } else {
          throw Exception('Game details not available');
        }
      } else {
        throw Exception('Failed to load game details');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading game details: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatPrice(dynamic priceData) {
    if (priceData == null) return 'Free';

    if (priceData is Map) {
      if (priceData.containsKey('final') && priceData.containsKey('currency')) {
        final price = priceData['final'];
        final currencyCode = priceData['currency'];

        String symbol = _getCurrencySymbol(currencyCode);
        double formattedValue = price / 100;
        bool useDecimals =
            !['JPY', 'KRW', 'IDR', 'VND', 'CLP', 'COP'].contains(currencyCode);
        String formattedPrice =
            useDecimals
                ? formattedValue.toStringAsFixed(2)
                : formattedValue.toStringAsFixed(0);
        bool symbolAfter = ['kr', 'zł'].contains(symbol);

        return symbolAfter
            ? '$formattedPrice $symbol'
            : '$symbol$formattedPrice';
      }
    } else if (priceData is String) {
      return priceData;
    }

    return 'See price';
  }

  String _getCurrencySymbol(String currencyCode) {
    final Map<String, String> currencySymbols = {
      "USD": "\$",
      "ARS": "ARS\$",
      "AUD": "A\$",
      "BRL": "R\$",
      "CAD": "C\$",
      "CLP": "CLP\$",
      "CNY": "¥",
      "COP": "COL\$",
      "CRC": "₡",
      "EUR": "€",
      "GBP": "£",
      "HKD": "HK\$",
      "IDR": "Rp",
      "ILS": "₪",
      "INR": "₹",
      "JPY": "¥",
      "KRW": "₩",
      "KZT": "₸",
      "MXN": "Mex\$",
      "MYR": "RM",
      "NOK": "kr",
      "NZD": "NZ\$",
      "PEN": "S/.",
      "PHP": "₱",
      "PLN": "zł",
      "QAR": "QR",
      "RUB": "₽",
      "SAR": "SR",
      "SGD": "S\$",
      "THB": "฿",
      "TRY": "₺",
      "TWD": "NT\$",
      "UAH": "₴",
      "AED": "AED",
      "UYU": "\$U",
      "VND": "₫",
      "ZAR": "R",
    };

    return currencySymbols[currencyCode] ?? currencyCode;
  }

  bool _hasDiscount(dynamic priceData) {
    if (priceData is Map &&
        priceData.containsKey('initial') &&
        priceData.containsKey('final')) {
      return priceData['initial'] > priceData['final'];
    }
    return false;
  }

  String _formatOriginalPrice(dynamic priceData) {
    if (priceData is Map &&
        priceData.containsKey('initial') &&
        priceData.containsKey('currency')) {
      final initialPrice = priceData['initial'];
      final currencyCode = priceData['currency'];

      String symbol = _getCurrencySymbol(currencyCode);
      double formattedValue = initialPrice / 100;
      bool useDecimals =
          !['JPY', 'KRW', 'IDR', 'VND', 'CLP', 'COP'].contains(currencyCode);
      String formattedPrice =
          useDecimals
              ? formattedValue.toStringAsFixed(2)
              : formattedValue.toStringAsFixed(0);
      bool symbolAfter = ['kr', 'zł'].contains(symbol);

      return symbolAfter ? '$formattedPrice $symbol' : '$symbol$formattedPrice';
    }
    return '';
  }

  int _calculateDiscountPercent(dynamic priceData) {
    if (priceData is Map &&
        priceData.containsKey('initial') &&
        priceData.containsKey('final') &&
        priceData['initial'] > 0) {
      final initial = priceData['initial'];
      final finalPrice = priceData['final'];
      return ((initial - finalPrice) / initial * 100).round();
    }
    return 0;
  }

  void _showFullScreenImage(String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => Scaffold(
              appBar: AppBar(
                backgroundColor: Colors.black,
                iconTheme: const IconThemeData(color: Colors.white),
              ),
              backgroundColor: Colors.black,
              body: Center(
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value:
                              loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.game['name']),
        actions: [
          if (_gameDetails.containsKey('website') &&
              _gameDetails['website'].toString().isNotEmpty)
            IconButton(
              icon: const Icon(Icons.language),
              onPressed: () {
                launchUrl(
                  Uri.parse(_gameDetails['website']),
                  mode: LaunchMode.externalApplication,
                );
              },
              tooltip: 'Official Website',
            ),
          IconButton(
            icon: const Icon(Icons.open_in_browser),
            onPressed: () {
              final Uri url = Uri.parse(
                'https://store.steampowered.com/app/${widget.game['id']}',
              );
              launchUrl(url, mode: LaunchMode.externalApplication);
            },
            tooltip: 'Open in Steam Store',
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildGameDetails(themeProvider),
    );
  }

  Widget _buildGameDetails(ThemeProvider themeProvider) {
    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) {
        return [
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_gameDetails.containsKey('background'))
                  Stack(
                    alignment: Alignment.bottomLeft,
                    children: [
                      Image.network(
                        _gameDetails['background'],
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (ctx, error, _) =>
                                Container(height: 200, color: Colors.grey[800]),
                      ),
                      Container(
                        height: 200,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.3),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _gameDetails['name'],
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            if (_gameDetails.containsKey('developers'))
                              Text(
                                'By ${_gameDetails['developers'].join(', ')}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.white70,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),

                if (widget.game['price'] != null ||
                    _gameDetails.containsKey('is_free'))
                  Card(
                    margin: const EdgeInsets.all(16),
                    elevation: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Icon(Icons.shopping_cart),
                          const SizedBox(width: 16),
                          Expanded(
                            child:
                                _gameDetails.containsKey('is_free') &&
                                        _gameDetails['is_free'] == true
                                    ? const Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Free to Play',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green,
                                          ),
                                        ),
                                        Text(
                                          'This game is available to play for free',
                                          style: TextStyle(fontSize: 14),
                                        ),
                                      ],
                                    )
                                    : Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Price',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        _hasDiscount(widget.game['price'])
                                            ? Row(
                                              children: [
                                                Text(
                                                  _formatOriginalPrice(
                                                    widget.game['price'],
                                                  ),
                                                  style: const TextStyle(
                                                    decoration:
                                                        TextDecoration
                                                            .lineThrough,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  _formatPrice(
                                                    widget.game['price'],
                                                  ),
                                                  style: const TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.green,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 6,
                                                        vertical: 2,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.red,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          4,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    '-${_calculateDiscountPercent(widget.game['price'])}%',
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            )
                                            : Text(
                                              _formatPrice(
                                                widget.game['price'],
                                              ),
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.green,
                                              ),
                                            ),
                                      ],
                                    ),
                          ),

                          ElevatedButton(
                            onPressed: () {
                              final Uri url = Uri.parse(
                                'https://store.steampowered.com/app/${widget.game['id']}',
                              );
                              launchUrl(
                                url,
                                mode: LaunchMode.externalApplication,
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Theme.of(context).colorScheme.primary,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Visit Store'),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (_gameDetails.containsKey('metacritic'))
                  Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    elevation: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _getMetacriticColor(
                                _gameDetails['metacritic']['score'],
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${_gameDetails['metacritic']['score']}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Metacritic Score',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Based on critic reviews',
                                  style: TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.open_in_new),
                            onPressed: () {
                              launchUrl(
                                Uri.parse(_gameDetails['metacritic']['url']),
                                mode: LaunchMode.externalApplication,
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                TabBar(
                  controller: _tabController,
                  isScrollable: false,
                  tabs: const [
                    Tab(text: 'About'),
                    Tab(text: 'Media'),
                    Tab(text: 'Details'),
                    Tab(text: 'Spec'),
                  ],
                ),
              ],
            ),
          ),
        ];
      },
      body: TabBarView(
        controller: _tabController,
        children: [
          // About Tab
          _buildAboutTab(),

          // Media Tab (Screenshots & Videos)
          _buildMediaTab(),

          // Details Tab (Categories, Genres, Release Date, etc.)
          _buildDetailsTab(themeProvider),

          // System Requirements Tab
          _buildSystemReqTab(themeProvider),
        ],
      ),
    );
  }

  Widget _buildAboutTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_gameDetails.containsKey('short_description') &&
              _gameDetails['short_description'].toString().isNotEmpty)
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Short Description',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _gameDetails.containsKey('short_description') &&
                            _gameDetails['short_description']
                                .toString()
                                .isNotEmpty
                        ? Text(
                          _gameDetails['short_description'],
                          style: const TextStyle(fontSize: 16),
                        )
                        : const Text(
                          'No short description available for this game.',
                          style: TextStyle(
                            fontSize: 16,
                            fontStyle: FontStyle.italic,
                            color: Colors.grey,
                          ),
                        ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 16),

          if (_gameDetails.containsKey('about_the_game') &&
              _gameDetails['about_the_game'].toString().isNotEmpty)
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'About This Game',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _gameDetails.containsKey('about_the_game') &&
                            _gameDetails['about_the_game'].toString().isNotEmpty
                        ? Html(
                          data: _gameDetails['about_the_game'],
                          style: {
                            "body": Style(
                              fontSize: FontSize(16),
                              margin: Margins.zero,
                              padding: HtmlPaddings.zero,
                            ),
                            "li": Style(margin: Margins.only(bottom: 8)),
                          },
                          onLinkTap: (url, _, __) {
                            if (url != null) {
                              launchUrl(
                                Uri.parse(url),
                                mode: LaunchMode.externalApplication,
                              );
                            }
                          },
                        )
                        : const Text(
                          'No detailed description has been provided for this game.',
                          style: TextStyle(
                            fontSize: 16,
                            fontStyle: FontStyle.italic,
                            color: Colors.grey,
                          ),
                        ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 16),

          // If there's a highlighted video, show it here as well
          if (_videos.isNotEmpty &&
              _videos.any((video) => video['highlight'] == true))
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Featured Video',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _videos.any((video) => video['highlight'] == true)
                        ? InkWell(
                          onTap: () {
                            final highlightedVideo = _videos.firstWhere(
                              (video) => video['highlight'] == true,
                              orElse: () => _videos.first,
                            );
                            _playVideo(highlightedVideo['url']);
                          },
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  _videos.firstWhere(
                                    (video) => video['highlight'] == true,
                                    orElse: () => _videos.first,
                                  )['thumbnail'],
                                  width: double.infinity,
                                  height: 200,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: Colors.black45,
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: const Icon(
                                  Icons.play_arrow,
                                  color: Colors.white,
                                  size: 40,
                                ),
                              ),
                            ],
                          ),
                        )
                        : InkWell(
                          onTap: () => _playVideo(_videos.first['url']),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  _videos.first['thumbnail'],
                                  width: double.infinity,
                                  height: 200,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: Colors.black45,
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: const Icon(
                                  Icons.play_arrow,
                                  color: Colors.white,
                                  size: 40,
                                ),
                              ),
                            ],
                          ),
                        ),
                    const SizedBox(height: 8),
                    Text(
                      _videos.firstWhere(
                        (video) => video['highlight'] == true,
                        orElse: () => _videos.first,
                      )['name'],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMediaTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_isVideoPlaying && _chewieController != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Chewie(controller: _chewieController!),
                ),
                OverflowBar(
                  children: [
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _isVideoPlaying = false;
                          _videoController?.pause();
                        });
                      },
                      child: const Text('Close Video'),
                    ),
                  ],
                ),
              ],
            ),

          // Screenshots section
          if (_screenshots.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Screenshots',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _screenshots.isNotEmpty
                    ? SizedBox(
                      height: 200,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _screenshots.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: GestureDetector(
                              onTap:
                                  () =>
                                      _showFullScreenImage(_screenshots[index]),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  _screenshots[index],
                                  height: 200,
                                  width: 320,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    )
                    : Card(
                      child: Container(
                        width: double.infinity,
                        height: 150,
                        alignment: Alignment.center,
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.photo_library_outlined,
                              color: Colors.grey[400],
                              size: 48,
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'No screenshots available for this game',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
              ],
            ),

          const SizedBox(height: 16),

          // Videos section
          if (_videos.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Videos',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _videos.isNotEmpty
                    ? ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _videos.length,
                      itemBuilder: (context, index) {
                        final video = _videos[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: InkWell(
                            onTap: () => _playVideo(video['url']),
                            child: Row(
                              children: [
                                Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    ClipRRect(
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(4),
                                        bottomLeft: Radius.circular(4),
                                      ),
                                      child: Image.network(
                                        video['thumbnail'],
                                        height: 80,
                                        width: 120,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    Container(
                                      width: 30,
                                      height: 30,
                                      decoration: BoxDecoration(
                                        color: Colors.black45,
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                      child: const Icon(
                                        Icons.play_arrow,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                    ),
                                    child: Text(
                                      video['name'],
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                video['highlight']
                                    ? Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      margin: const EdgeInsets.only(right: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.blue,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'Featured',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    )
                                    : const SizedBox(width: 8),
                              ],
                            ),
                          ),
                        );
                      },
                    )
                    : Card(
                      child: Container(
                        width: double.infinity,
                        height: 150,
                        alignment: Alignment.center,
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.videocam_off,
                              color: Colors.grey[400],
                              size: 48,
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'No videos available for this game',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildDetailsTab(ThemeProvider themeProvider) {
    bool hasGameInfo =
        _gameDetails.containsKey('release_date') ||
        _gameDetails.containsKey('developers') ||
        _gameDetails.containsKey('publishers');

    bool hasCategories =
        _gameDetails.containsKey('genres') ||
        _gameDetails.containsKey('categories');

    bool hasLanguages =
        _gameDetails.containsKey('supported_languages') &&
        _gameDetails['supported_languages'].toString().isNotEmpty;

    bool hasAchievements =
        _gameDetails.containsKey('achievements') &&
        _gameDetails['achievements']['highlighted'].length > 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Game info - release date, developer, publisher
          if (_gameDetails.containsKey('release_date') ||
              _gameDetails.containsKey('developers') ||
              _gameDetails.containsKey('publishers'))
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Game Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (hasGameInfo) ...[
                      if (_gameDetails.containsKey('release_date'))
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(
                                width: 100,
                                child: Text(
                                  'Release Date:',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  _gameDetails['release_date']['date'] ??
                                      'Unknown',
                                ),
                              ),
                            ],
                          ),
                        ),

                      if (_gameDetails.containsKey('developers'))
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(
                                width: 100,
                                child: Text(
                                  'Developer:',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  _gameDetails['developers'].join(', '),
                                ),
                              ),
                            ],
                          ),
                        ),

                      if (_gameDetails.containsKey('publishers'))
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(
                                width: 100,
                                child: Text(
                                  'Publisher:',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  _gameDetails['publishers'].join(', '),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Add platform info
                      if (_gameDetails.containsKey('platforms'))
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(
                                width: 100,
                                child: Text(
                                  'Platforms:',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              Expanded(
                                child: Wrap(
                                  spacing: 8,
                                  children: [
                                    if (_gameDetails['platforms']['windows'] ==
                                        true)
                                      const Icon(Icons.computer),
                                    if (_gameDetails['platforms']['mac'] ==
                                        true)
                                      const Icon(Icons.apple),
                                    if (_gameDetails['platforms']['linux'] ==
                                        true)
                                      const Icon(Icons.android),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Add required age if available
                      if (_gameDetails.containsKey('required_age') &&
                          _gameDetails['required_age'] > 0)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(
                                width: 100,
                                child: Text(
                                  'Age Rating:',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '${_gameDetails['required_age']}+',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ] else ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16.0),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Colors.grey,
                                size: 36,
                              ),
                              SizedBox(height: 8),
                              Text(
                                'No basic game information available',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

          const SizedBox(height: 16),
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Categories & Genres',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  if (hasCategories) ...[
                    if (_gameDetails.containsKey('genres'))
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Genres:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (var genre in _gameDetails['genres'])
                                Chip(
                                  label: Text(genre['description']),
                                  backgroundColor: Theme.of(
                                    context,
                                  ).colorScheme.primary.withValues(alpha: 0.1),
                                ),
                            ],
                          ),
                        ],
                      ),

                    if (_gameDetails.containsKey('categories'))
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),
                          const Text(
                            'Features:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (var category in _gameDetails['categories'])
                                Chip(
                                  label: Text(category['description']),
                                  backgroundColor: Theme.of(context)
                                      .colorScheme
                                      .secondary
                                      .withValues(alpha: 0.1),
                                ),
                            ],
                          ),
                        ],
                      ),
                  ] else ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.category_outlined,
                              color: Colors.grey,
                              size: 36,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'No category or genre information available',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.grey,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Languages support
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Supported Languages',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  hasLanguages
                      ? Html(
                        data: _gameDetails['supported_languages'],
                        style: {
                          "body": Style(
                            fontSize: FontSize(14),
                            margin: Margins.zero,
                            padding: HtmlPaddings.zero,
                          ),
                        },
                      )
                      : const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          'Language support information is not available for this game.',
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Achievement showcase
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Achievements',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  hasAchievements
                      ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Highlighted Achievements',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                'Total: ${_gameDetails['achievements']['total']}',
                                style: const TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 5,
                                  crossAxisSpacing: 8,
                                  mainAxisSpacing: 8,
                                  childAspectRatio: 1,
                                ),
                            itemCount:
                                _gameDetails['achievements']['highlighted']
                                    .length,
                            itemBuilder: (context, index) {
                              final achievement =
                                  _gameDetails['achievements']['highlighted'][index];
                              return Tooltip(
                                message: achievement['name'],
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: Image.network(
                                    achievement['path'],
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            Container(
                                              color: Colors.grey[300],
                                              child: const Center(
                                                child: Icon(
                                                  Icons.emoji_events,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      )
                      : const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16.0),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.emoji_events_outlined,
                                color: Colors.grey,
                                size: 36,
                              ),
                              SizedBox(height: 8),
                              Text(
                                'This game does not have achievements',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSystemReqTab(ThemeProvider themeProvider) {
    bool hasPcRequirements =
        _gameDetails.containsKey('pc_requirements') &&
        _gameDetails['pc_requirements'] is Map &&
        (_gameDetails['pc_requirements'].containsKey('minimum') ||
            _gameDetails['pc_requirements'].containsKey('recommended'));

    bool hasMacRequirements =
        _gameDetails.containsKey('mac_requirements') &&
        _gameDetails['mac_requirements'] is Map &&
        (_gameDetails['mac_requirements'].containsKey('minimum') ||
            _gameDetails['mac_requirements'].containsKey('recommended'));

    bool hasLinuxRequirements =
        _gameDetails.containsKey('linux_requirements') &&
        _gameDetails['linux_requirements'] is Map &&
        (_gameDetails['linux_requirements'].containsKey('minimum') ||
            _gameDetails['linux_requirements'].containsKey('recommended'));

    bool hasNoRequirements =
        !hasPcRequirements && !hasMacRequirements && !hasLinuxRequirements;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasNoRequirements)
            Card(
              elevation: 2,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.computer_outlined,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'System requirements information is not available for this game',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Check the Steam store page for more details',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        final Uri url = Uri.parse(
                          'https://store.steampowered.com/app/${widget.game['id']}',
                        );
                        launchUrl(url, mode: LaunchMode.externalApplication);
                      },
                      child: const Text('Visit Steam Store'),
                    ),
                  ],
                ),
              ),
            ),

          // Windows Requirements
          if (hasPcRequirements)
            Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Windows Requirements',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_gameDetails['pc_requirements'].containsKey('minimum'))
                      Html(
                        data: _gameDetails['pc_requirements']['minimum'],
                        style: {
                          "body": Style(
                            fontSize: FontSize(14),
                            margin: Margins.zero,
                            padding: HtmlPaddings.zero,
                            color:
                                themeProvider.isDarkMode
                                    ? Colors.white
                                    : Colors.black87,
                          ),
                        },
                      ),
                    if (_gameDetails['pc_requirements'].containsKey(
                      'recommended',
                    ))
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Divider(),
                          Html(
                            data:
                                _gameDetails['pc_requirements']['recommended'],
                            style: {
                              "body": Style(
                                fontSize: FontSize(14),
                                margin: Margins.zero,
                                padding: HtmlPaddings.zero,
                                color:
                                    themeProvider.isDarkMode
                                        ? Colors.white
                                        : Colors.black87,
                              ),
                            },
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),

          // Mac Requirements
          if (hasMacRequirements)
            Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Mac Requirements',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_gameDetails['mac_requirements'].containsKey('minimum'))
                      Html(
                        data: _gameDetails['mac_requirements']['minimum'],
                        style: {
                          "body": Style(
                            fontSize: FontSize(14),
                            margin: Margins.zero,
                            padding: HtmlPaddings.zero,
                            color:
                                themeProvider.isDarkMode
                                    ? Colors.white
                                    : Colors.black87,
                          ),
                        },
                      ),
                    if (_gameDetails['mac_requirements'].containsKey(
                      'recommended',
                    ))
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Divider(),
                          Html(
                            data:
                                _gameDetails['mac_requirements']['recommended'],
                            style: {
                              "body": Style(
                                fontSize: FontSize(14),
                                margin: Margins.zero,
                                padding: HtmlPaddings.zero,
                                color:
                                    themeProvider.isDarkMode
                                        ? Colors.white
                                        : Colors.black87,
                              ),
                            },
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),

          // Linux Requirements
          if (hasLinuxRequirements)
            Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Linux Requirements',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_gameDetails['linux_requirements'].containsKey(
                      'minimum',
                    ))
                      Html(
                        data: _gameDetails['linux_requirements']['minimum'],
                        style: {
                          "body": Style(
                            fontSize: FontSize(14),
                            margin: Margins.zero,
                            padding: HtmlPaddings.zero,
                            color:
                                themeProvider.isDarkMode
                                    ? Colors.white
                                    : Colors.black87,
                          ),
                        },
                      ),
                    if (_gameDetails['linux_requirements'].containsKey(
                      'recommended',
                    ))
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Divider(),
                          Html(
                            data:
                                _gameDetails['linux_requirements']['recommended'],
                            style: {
                              "body": Style(
                                fontSize: FontSize(14),
                                margin: Margins.zero,
                                padding: HtmlPaddings.zero,
                                color:
                                    themeProvider.isDarkMode
                                        ? Colors.white
                                        : Colors.black87,
                              ),
                            },
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _getMetacriticColor(int score) {
    if (score >= 75) {
      return Colors.green;
    } else if (score >= 50) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }
}
