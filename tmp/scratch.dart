import 'package:supabase/supabase.dart';
import 'dart:convert';
import 'dart:io';

void main() async {
  final supabaseUrl = Platform.environment['SUPABASE_URL'] ?? 'https://kphizkgjcawfameowpmw.supabase.co';
  final supabaseKey = Platform.environment['SUPABASE_KEY'] ?? '...'; // Not needed since anon is enough usually, but wait, I can just read the keys from main.dart
}
