// lib/data/sources/local/password_hash_service.dart
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

class PasswordHashService {
  // Generate a random salt
  static String generateSalt() {
    final random = Random.secure();
    final saltBytes = List<int>.generate(32, (_) => random.nextInt(256));
    return base64.encode(saltBytes);
  }
  
  // Hash password with salt
  static String hashPassword(String password, String salt) {
    final combined = password + salt;
    final bytes = utf8.encode(combined);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
  
  // Verify password
  static bool verifyPassword(String password, String salt, String hashedPassword) {
    final computedHash = hashPassword(password, salt);
    return computedHash == hashedPassword;
  }
  
  // Create new password hash with salt
  static ({String hash, String salt}) createPasswordHash(String password) {
    final salt = generateSalt();
    final hash = hashPassword(password, salt);
    return (hash: hash, salt: salt);
  }
}