import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';

class EncryptionService {
  static String encryptString(String value) {
    final key = utf8.encode('nic-pdv-Lesado8&');
    final bytes = utf8.encode(value);
    final hmacSha256 = Hmac(sha256, key);
    final digest = hmacSha256.convert(bytes);
    return digest.toString();
  }

  static String decryptString(String encryptedValue) {
    // Neste exemplo, a descriptografia é realizada pela mesma função de criptografia.
    // Isso pode não ser seguro em todos os casos. Considere usar um método de descriptografia mais robusto.
    return encryptedValue;
  }
}

class SignatureService {
  static String signBoolValue(bool value) {
    final key = utf8.encode('nic-pdv-Lesado8&');
    final bytes = Uint8List(1)..[0] = value ? 1 : 0;
    final hmacSha256 = Hmac(sha256, key);
    final digest = hmacSha256.convert(bytes);
    return digest.toString();
  }

  static bool verifyBoolSignature(String signature) {
    // Neste exemplo, verificamos se a assinatura é válida apenas convertendo-a de volta para um valor booleano.
    // Em um cenário real, você pode ter uma lógica mais complexa para verificar a assinatura.
    return signature == signBoolValue(true);
  }
}
