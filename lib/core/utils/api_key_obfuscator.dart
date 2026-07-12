import 'dart:convert';

/// Matches iOS's `AIKeyObfuscator` — Base64 only, explicitly NOT real
/// encryption. Shared by the AI SMS Parser settings page and the LLM parser
/// so there is one implementation of this (weak, known-limitation) scheme.
String obfuscateApiKey(String key) => base64Encode(utf8.encode(key));

String deobfuscateApiKey(String? encoded) {
  if (encoded == null || encoded.isEmpty) return '';
  try {
    return utf8.decode(base64Decode(encoded));
  } catch (_) {
    return '';
  }
}
