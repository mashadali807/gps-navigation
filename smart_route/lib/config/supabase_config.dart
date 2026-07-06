import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  // Your Supabase project URL from the dashboard
  static const String url = 'https://hoxjzfwcxzcmryfedafg.supabase.co';

  // Your publishable key from the dashboard (use the publishable key, not anon key)
  // Supabase now uses publishable keys for client-side authentication
  static const String publishableKey =
      'sb_publishable_3qA_SftLL3a96hRnZsHojw_2B02kJnQ';

  // Keep anonKey for backward compatibility but use publishableKey
  static const String anonKey = publishableKey;

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
      debug: true, // Uncomment for debugging
    );
  }

  static SupabaseClient get client => Supabase.instance.client;

  // Helper method to check if Supabase is initialized
  static bool get isInitialized => Supabase.instance.client != null;

  // Helper method to get the current user
  static User? get currentUser => Supabase.instance.client.auth.currentUser;

  // Helper method to get the current session
  static Session? get currentSession =>
      Supabase.instance.client.auth.currentSession;
}

// ============ USAGE EXAMPLE ============
/*
  // In main.dart
  import 'package:gps_navigation_app/config/supabase_config.dart';
  
  void main() async {
    WidgetsFlutterBinding.ensureInitialized();
    await SupabaseConfig.initialize();
    runApp(const MyApp());
  }
  
  // Access Supabase anywhere
  final supabase = SupabaseConfig.client;
  
  // Example: Fetch data
  final response = await supabase
      .from('users')
      .select()
      .eq('id', userId);
  
  // Example: Insert data
  final response = await supabase
      .from('users')
      .insert({
        'name': 'John Doe',
        'email': 'john@example.com',
      });
      
  // Example: Update data
  final response = await supabase
      .from('users')
      .update({'status': 'active'})
      .eq('id', userId);
      
  // Example: Delete data
  final response = await supabase
      .from('users')
      .delete()
      .eq('id', userId);
*/
