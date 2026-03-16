
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';

Future<void> main() async {
  final supabase = SupabaseClient(
    'https://zellqsyvjfgnlwredhtt.supabase.co',
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InplbGxxc3l2amZnbmx3cmVkaHR0Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3MDAwMTM4NiwiZXhwIjoyMDg1NTc3Mzg2fQ.Qt82caTI4YrAdQqC-p7OLLw734rNgFtlWyfpS2rLX9k'
  );

  try {
    final response = await supabase.from('auth').select('*').limit(1).maybeSingle();
    if (response != null) {
      print('Columns in auth table: ${response.keys.toList()}');
    } else {
      print('No data in auth table');
    }
  } catch (e) {
    print('Error: $e');
  }
  exit(0);
}
