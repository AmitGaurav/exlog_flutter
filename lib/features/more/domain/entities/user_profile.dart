import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum PremiumTier {
  free,
  monthly,
  yearly,
  lifetime,
  admin;

  static PremiumTier fromString(String? value) => PremiumTier.values.firstWhere(
        (e) => e.name == value,
        orElse: () => PremiumTier.free,
      );

  String get displayName {
    switch (this) {
      case PremiumTier.free:
        return 'Free Tier';
      case PremiumTier.monthly:
        return 'Premium Monthly';
      case PremiumTier.yearly:
        return 'Premium Yearly';
      case PremiumTier.lifetime:
        return 'Premium Lifetime';
      case PremiumTier.admin:
        return 'Admin Access';
    }
  }

  bool get isPremium => this != PremiumTier.free;
}

enum LLMProvider {
  openai,
  anthropic,
  gemini,
  groq,
  mistral;

  static LLMProvider fromString(String? value) => LLMProvider.values.firstWhere(
        (e) => e.name == value,
        orElse: () => LLMProvider.gemini,
      );

  String get displayName {
    switch (this) {
      case LLMProvider.openai:
        return 'OpenAI';
      case LLMProvider.anthropic:
        return 'Anthropic';
      case LLMProvider.gemini:
        return 'Google Gemini';
      case LLMProvider.groq:
        return 'Groq (Llama)';
      case LLMProvider.mistral:
        return 'Mistral AI';
    }
  }

  String get defaultModel {
    switch (this) {
      case LLMProvider.openai:
        return 'gpt-4o-mini';
      case LLMProvider.anthropic:
        return 'claude-sonnet-4-20250514';
      case LLMProvider.gemini:
        return 'gemini-2.5-flash';
      case LLMProvider.groq:
        return 'llama-3.3-70b-versatile';
      case LLMProvider.mistral:
        return 'mistral-small-latest';
    }
  }

  List<String> get availableModels {
    switch (this) {
      case LLMProvider.openai:
        return ['gpt-4o-mini', 'gpt-4o', 'gpt-4.1-mini', 'gpt-4.1-nano'];
      case LLMProvider.anthropic:
        return ['claude-sonnet-4-20250514', 'claude-3-5-haiku-20241022'];
      case LLMProvider.gemini:
        return ['gemini-2.5-flash', 'gemini-2.0-flash', 'gemini-2.5-pro'];
      case LLMProvider.groq:
        return ['llama-3.3-70b-versatile', 'llama-3.1-8b-instant', 'gemma2-9b-it'];
      case LLMProvider.mistral:
        return ['mistral-small-latest', 'mistral-medium-latest', 'mistral-large-latest'];
    }
  }

  String get apiKeyUrl {
    switch (this) {
      case LLMProvider.openai:
        return 'https://platform.openai.com/api-keys';
      case LLMProvider.anthropic:
        return 'https://console.anthropic.com/settings/keys';
      case LLMProvider.gemini:
        return 'https://aistudio.google.com/app/apikey';
      case LLMProvider.groq:
        return 'https://console.groq.com/keys';
      case LLMProvider.mistral:
        return 'https://console.mistral.ai/api-keys';
    }
  }

  String get pricingNote {
    switch (this) {
      case LLMProvider.openai:
        return '~\$0.15/1M input tokens';
      case LLMProvider.anthropic:
        return '~\$3/1M input tokens (Sonnet)';
      case LLMProvider.gemini:
        return 'Free tier: 15 RPM';
      case LLMProvider.groq:
        return 'Free tier: 30 RPM';
      case LLMProvider.mistral:
        return '~\$0.1/1M input tokens';
    }
  }
}

class AIParserConfig extends Equatable {
  final bool isEnabled;
  final LLMProvider provider;
  final String model;
  final String? apiKeyObfuscated;

  const AIParserConfig({
    this.isEnabled = false,
    this.provider = LLMProvider.gemini,
    this.model = '',
    this.apiKeyObfuscated,
  });

  factory AIParserConfig.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const AIParserConfig();
    final provider = LLMProvider.fromString(map['provider'] as String?);
    return AIParserConfig(
      isEnabled: map['isEnabled'] as bool? ?? false,
      provider: provider,
      model: (map['model'] as String?)?.isNotEmpty == true
          ? map['model'] as String
          : provider.defaultModel,
      apiKeyObfuscated: map['apiKeyObfuscated'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'isEnabled': isEnabled,
        'provider': provider.name,
        'model': model,
        'apiKeyObfuscated': apiKeyObfuscated,
      };

  AIParserConfig copyWith({
    bool? isEnabled,
    LLMProvider? provider,
    String? model,
    String? apiKeyObfuscated,
  }) =>
      AIParserConfig(
        isEnabled: isEnabled ?? this.isEnabled,
        provider: provider ?? this.provider,
        model: model ?? this.model,
        apiKeyObfuscated: apiKeyObfuscated ?? this.apiKeyObfuscated,
      );

  @override
  List<Object?> get props => [isEnabled, provider, model, apiKeyObfuscated];
}

class UserProfile extends Equatable {
  final String uid;
  final String email;
  final String displayName;
  final DateTime createdAt;
  final bool isActive;
  final PremiumTier premiumTier;
  final String preferredCurrency;
  final AIParserConfig aiParserConfig;
  final List<String> selfNames;

  const UserProfile({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.createdAt,
    this.isActive = true,
    this.premiumTier = PremiumTier.free,
    this.preferredCurrency = 'INR',
    this.aiParserConfig = const AIParserConfig(),
    this.selfNames = const [],
  });

  factory UserProfile.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return UserProfile(
      uid: doc.id,
      email: data['email'] as String? ?? '',
      displayName: data['displayName'] as String? ?? 'User',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: data['isActive'] as bool? ?? true,
      premiumTier: PremiumTier.fromString(data['premiumTier'] as String?),
      preferredCurrency: data['preferredCurrency'] as String? ?? 'INR',
      aiParserConfig: AIParserConfig.fromMap(data['aiParserConfig'] as Map<String, dynamic>?),
      selfNames: (data['selfNames'] as List<dynamic>?)?.map((e) => e as String).toList() ?? const [],
    );
  }

  String get initials {
    final parts = displayName.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty) {
      return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    return 'U';
  }

  UserProfile copyWith({
    String? email,
    String? displayName,
    DateTime? createdAt,
    bool? isActive,
    PremiumTier? premiumTier,
    String? preferredCurrency,
    AIParserConfig? aiParserConfig,
    List<String>? selfNames,
  }) =>
      UserProfile(
        uid: uid,
        email: email ?? this.email,
        displayName: displayName ?? this.displayName,
        createdAt: createdAt ?? this.createdAt,
        isActive: isActive ?? this.isActive,
        premiumTier: premiumTier ?? this.premiumTier,
        preferredCurrency: preferredCurrency ?? this.preferredCurrency,
        aiParserConfig: aiParserConfig ?? this.aiParserConfig,
        selfNames: selfNames ?? this.selfNames,
      );

  @override
  List<Object?> get props => [
        uid, email, displayName, createdAt, isActive, premiumTier,
        preferredCurrency, aiParserConfig, selfNames,
      ];
}
