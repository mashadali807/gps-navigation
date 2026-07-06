import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:smart_route/models/search_result_model.dart' hide SearchResult;
import 'package:smart_route/services/map_services.dart';

import '../../providers/location_provider.dart';
import '../../providers/map_provider.dart';
import '../../providers/navigation_provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/widgets/glassmorphic_card.dart';
import '../../core/widgets/loading_widget.dart';
import '../../models/place_model.dart';
import '../../models/route_model.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  List<SearchResult> _searchResults = [];
  bool _isLoading = false;
  bool _isSearching = false;
  String? _error;
  bool _showRecentSearches = true;

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
  }

  Future<void> _searchLocation(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults.clear();
        _isSearching = false;
        _showRecentSearches = true;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _isLoading = true;
      _error = null;
      _showRecentSearches = false;
    });

    try {
      final results = await MapService.searchLocation(query);

      setState(() {
        _searchResults = results;
        _isLoading = false;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
        _isSearching = false;
      });
    }
  }

  void _selectSearchResult(SearchResult result) {
    final mapProvider = context.read<MapProvider>();
    final location = LatLng(result.latitude, result.longitude);

    // Move map to location
    mapProvider.moveTo(location, zoom: 15);

    // Add marker
    final marker = Marker(
      point: location,
      width: 40,
      height: 40,
      key: Key('search_${DateTime.now().millisecondsSinceEpoch}'),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.red,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.3),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ],
        ),
        child: const Icon(Icons.flag, color: Colors.white, size: 20),
      ),
    );
    mapProvider.addMarker(marker);

    _searchController.clear();
    setState(() {
      _searchResults.clear();
      _isSearching = false;
      _showRecentSearches = true;
    });

    // Navigate back to home using GoRouter
    context.go('/home');
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.grey[50],
      appBar: AppBar(
        title: const Text('Search Places'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? Colors.white : Colors.black87,
          ),
          onPressed: () => context.go('/home'),
        ),
        actions: [
          IconButton(
            onPressed: () {
              _searchController.clear();
              setState(() {
                _searchResults.clear();
                _isSearching = false;
                _showRecentSearches = true;
                _error = null;
              });
            },
            icon: Icon(
              Icons.close,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(theme, isDark),
          Expanded(child: _buildContent(theme, isDark)),
        ],
      ),
    );
  }

  Widget _buildSearchBar(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black54 : Colors.black12,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[800] : Colors.grey[100],
                borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
              ),
              child: TextField(
                controller: _searchController,
                focusNode: _focusNode,
                onChanged: _searchLocation,
                decoration: InputDecoration(
                  hintText: 'Search places...',
                  hintStyle: TextStyle(
                    color: isDark ? Colors.grey[500] : Colors.grey[400],
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: isDark ? Colors.grey[500] : Colors.grey[400],
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchResults.clear();
                              _isSearching = false;
                              _showRecentSearches = true;
                            });
                          },
                          icon: Icon(
                            Icons.clear,
                            color: isDark ? Colors.grey[500] : Colors.grey[400],
                            size: 18,
                          ),
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.paddingSmall,
                    vertical: AppConstants.paddingSmall,
                  ),
                ),
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(ThemeData theme, bool isDark) {
    if (_isSearching) {
      return _buildLoadingState(theme);
    }

    if (_error != null) {
      return _buildErrorState(theme);
    }

    if (_searchResults.isNotEmpty) {
      return _buildSearchResults(theme, isDark);
    }

    if (_showRecentSearches) {
      return _buildRecentAndFavorites(theme, isDark);
    }

    return _buildEmptyState(theme);
  }

  Widget _buildSearchResults(ThemeData theme, bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final result = _searchResults[index];
        return _buildResultItem(theme, isDark, result, index);
      },
    );
  }

  Widget _buildResultItem(
    ThemeData theme,
    bool isDark,
    SearchResult result,
    int index,
  ) {
    return GlassmorphicCard(
          padding: const EdgeInsets.all(AppConstants.paddingMedium),
          margin: const EdgeInsets.only(bottom: AppConstants.paddingSmall),
          onTap: () => _selectSearchResult(result),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.primaryColor.withOpacity(0.1),
                ),
                child: Icon(
                  _getResultIcon(result.type),
                  color: theme.primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppConstants.paddingMedium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.displayName,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      result.type ?? 'Location',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: isDark ? Colors.grey[500] : Colors.grey[400],
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(
          duration: AppConstants.durationMedium,
          delay: Duration(milliseconds: index * 50),
        )
        .slideX(
          begin: 0.2,
          end: 0,
          duration: AppConstants.durationMedium,
          delay: Duration(milliseconds: index * 50),
        );
  }

  Widget _buildRecentAndFavorites(ThemeData theme, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Recent Searches (for demonstration only - remove hardcoded data)
          if (_searchController.text.isEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppConstants.paddingSmall),
                Text(
                  'Search for places',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isDark ? Colors.grey[500] : Colors.grey[400],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const LoadingWidget(size: 40, style: LoadingStyle.dots),
          const SizedBox(height: AppConstants.paddingMedium),
          Text(
            'Searching...',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
          const SizedBox(height: AppConstants.paddingMedium),
          Text(
            _error!,
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.red),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppConstants.paddingMedium),
          ElevatedButton(
            onPressed: () => _searchLocation(_searchController.text),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 48,
            color: theme.textTheme.bodyMedium?.color?.withOpacity(0.3),
          ),
          const SizedBox(height: AppConstants.paddingMedium),
          Text(
            'No results found',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: AppConstants.paddingSmall),
          Text(
            'Try searching for a different place',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.textTheme.bodySmall?.color?.withOpacity(0.4),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getResultIcon(String? type) {
    switch (type?.toLowerCase()) {
      case 'city':
      case 'town':
      case 'village':
        return Icons.location_city;
      case 'street':
      case 'road':
        return Icons.streetview;
      case 'building':
        return Icons.business_center;
      case 'park':
        return Icons.park;
      case 'restaurant':
        return Icons.restaurant;
      case 'cafe':
        return Icons.local_cafe;
      case 'hotel':
        return Icons.hotel;
      case 'hospital':
        return Icons.local_hospital;
      case 'school':
        return Icons.school;
      case 'university':
        return Icons.school;
      case 'museum':
        return Icons.museum;
      case 'church':
        return Icons.church;
      case 'mosque':
        return Icons.mosque;
      case 'temple':
        return Icons.temple_buddhist;
      case 'landmark':
        return Icons.history;
      default:
        return Icons.place;
    }
  }
}

// ============ SEARCH RESULT EXTENSIONS ============

extension SearchResultExtension on SearchResult {
  PlaceModel toPlaceModel() {
    return PlaceModel.fromOSM({
      'display_name': displayName,
      'lat': latitude,
      'lon': longitude,
      'place_id': placeId,
      'type': type,
    });
  }
}
