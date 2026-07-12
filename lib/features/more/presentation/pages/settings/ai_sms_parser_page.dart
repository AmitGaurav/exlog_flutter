import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/utils/api_key_obfuscator.dart';
import '../../../domain/entities/user_profile.dart';
import '../../bloc/user_profile_bloc.dart';
import '../../bloc/user_profile_event.dart';
import '../../bloc/user_profile_state.dart';

String _obfuscate(String key) => obfuscateApiKey(key);
String _deobfuscate(String? encoded) => deobfuscateApiKey(encoded);

class AISmsParserPage extends StatefulWidget {
  const AISmsParserPage({super.key});

  @override
  State<AISmsParserPage> createState() => _AISmsParserPageState();
}

class _AISmsParserPageState extends State<AISmsParserPage> {
  bool _isEnabled = false;
  LLMProvider _provider = LLMProvider.gemini;
  String _model = '';
  String _apiKey = '';
  bool _isEditingKey = false;
  bool _showKeyText = false;
  bool _initialized = false;
  List<String> _selfNames = [];

  final _keyController = TextEditingController();
  final _selfNameController = TextEditingController();

  @override
  void dispose() {
    _keyController.dispose();
    _selfNameController.dispose();
    super.dispose();
  }

  void _initFromProfile(UserProfile profile) {
    if (_initialized) return;
    final config = profile.aiParserConfig;
    _isEnabled = config.isEnabled;
    _provider = config.provider;
    _model = config.model.isEmpty ? config.provider.defaultModel : config.model;
    _apiKey = _deobfuscate(config.apiKeyObfuscated);
    _selfNames = List.of(profile.selfNames);
    _initialized = true;
  }

  void _addSelfName(BuildContext context) {
    final name = _selfNameController.text.trim();
    if (name.isEmpty || _selfNames.contains(name)) return;
    setState(() {
      _selfNames = [..._selfNames, name];
      _selfNameController.clear();
    });
    context.read<UserProfileBloc>().add(UserProfileSelfNamesChanged(_selfNames));
  }

  void _removeSelfName(BuildContext context, String name) {
    setState(() => _selfNames = _selfNames.where((n) => n != name).toList());
    context.read<UserProfileBloc>().add(UserProfileSelfNamesChanged(_selfNames));
  }

  void _persist(BuildContext context) {
    context.read<UserProfileBloc>().add(UserProfileAIParserConfigChanged(AIParserConfig(
          isEnabled: _isEnabled,
          provider: _provider,
          model: _model,
          apiKeyObfuscated: _apiKey.isEmpty ? null : _obfuscate(_apiKey),
        )));
  }

  String get _maskedKey {
    if (_apiKey.length <= 12) return '*' * _apiKey.length;
    return '${_apiKey.substring(0, 8)}...${_apiKey.substring(_apiKey.length - 4)}';
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UserProfileBloc, UserProfileState>(
      builder: (context, state) {
        final profile = state.profile;
        if (profile != null) _initFromProfile(profile);

        return Scaffold(
          backgroundColor: AppColors.backgroundGray,
          appBar: AppBar(
            backgroundColor: AppColors.backgroundGray,
            title: const Text('AI SMS Parser', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              _StatusBanner(isEnabled: _isEnabled, hasKey: _apiKey.isNotEmpty, provider: _provider, model: _model),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12)),
                child: SwitchListTile(
                  title: const Text('Enable AI Parser'),
                  value: _isEnabled,
                  onChanged: (v) {
                    setState(() => _isEnabled = v);
                    _persist(context);
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 4),
                child: Text(
                  _isEnabled
                      ? 'AI parser will be tried first. Falls back to regex if AI fails.'
                      : 'Only regex-based parsing will be used.',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ),
              if (_isEnabled) ...[
                const SizedBox(height: 20),
                const Text('AI PROVIDER', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    children: [
                      for (var i = 0; i < LLMProvider.values.length; i++) ...[
                        _ProviderRow(
                          provider: LLMProvider.values[i],
                          isSelected: _provider == LLMProvider.values[i],
                          onTap: () {
                            if (_provider == LLMProvider.values[i]) return;
                            setState(() {
                              _provider = LLMProvider.values[i];
                              _model = _provider.defaultModel;
                              _apiKey = '';
                              _keyController.clear();
                              _isEditingKey = false;
                            });
                            _persist(context);
                          },
                        ),
                        if (i < LLMProvider.values.length - 1) const Divider(height: 1, color: AppColors.divider),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Text('MODEL', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    children: [
                      for (final m in _provider.availableModels)
                        ListTile(
                          title: Text(m),
                          trailing: _model == m ? const Icon(Icons.check_circle, color: AppColors.primary) : null,
                          onTap: () {
                            setState(() => _model = m);
                            _persist(context);
                          },
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text('${_provider.displayName.toUpperCase()} API KEY',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12)),
                  child: _isEditingKey ? _buildKeyEditView(context) : _buildKeyDisplayView(context),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8, left: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Get your API key from:', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      GestureDetector(
                        onTap: () => launchUrl(Uri.parse(_provider.apiKeyUrl), mode: LaunchMode.externalApplication),
                        child: Text(_provider.apiKeyUrl,
                            style: const TextStyle(fontSize: 12, color: AppColors.primary)),
                      ),
                      const SizedBox(height: 2),
                      const Text('Keys are stored encrypted in your Firebase account.',
                          style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              const Text('SELF-TRANSFER NAMES', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Add name variants your own accounts appear as in bank SMS (e.g. your name, nickname) '
                      'so transfers between your own accounts are detected as "Self Transfer" instead of an expense.',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 10),
                    if (_selfNames.isNotEmpty)
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final name in _selfNames)
                            Chip(
                              label: Text(name),
                              onDeleted: () => _removeSelfName(context, name),
                            ),
                        ],
                      ),
                    if (_selfNames.isNotEmpty) const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _selfNameController,
                            decoration: const InputDecoration(hintText: 'e.g. Rayaan Jha', isDense: true),
                            onSubmitted: (_) => _addSelfName(context),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.add_circle, color: AppColors.primary),
                          onPressed: () => _addSelfName(context),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12)),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.lock_outline, color: AppColors.primary),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Privacy & Security', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                          SizedBox(height: 4),
                          Text(
                            'Your API key is stored encrypted in Firebase (Base64). SMS content is sent to the '
                            'selected provider for processing. No data is stored on LLM servers.',
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildKeyEditView(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _keyController,
          obscureText: true,
          decoration: InputDecoration(hintText: '${_provider.apiKeyPlaceholderPrefix}...', isDense: true),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            TextButton(
              onPressed: () {
                setState(() {
                  _isEditingKey = false;
                  _keyController.text = _apiKey;
                });
              },
              child: const Text('Cancel'),
            ),
            const Spacer(),
            TextButton(
              onPressed: _keyController.text.trim().isEmpty
                  ? null
                  : () {
                      setState(() {
                        _apiKey = _keyController.text.trim();
                        _isEditingKey = false;
                      });
                      _persist(context);
                    },
              child: const Text('Save Key'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildKeyDisplayView(BuildContext context) {
    if (_apiKey.isEmpty) {
      return TextButton.icon(
        onPressed: () => setState(() => _isEditingKey = true),
        icon: const Icon(Icons.key),
        label: const Text('Set API Key'),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(_showKeyText ? _apiKey : _maskedKey, style: const TextStyle(fontFamily: 'monospace', fontSize: 13)),
            ),
            IconButton(
              icon: Icon(_showKeyText ? Icons.visibility_off : Icons.visibility, size: 18),
              onPressed: () => setState(() => _showKeyText = !_showKeyText),
            ),
          ],
        ),
        Row(
          children: [
            TextButton(
              onPressed: () {
                _keyController.text = _apiKey;
                setState(() => _isEditingKey = true);
              },
              child: const Text('Change Key'),
            ),
            const Spacer(),
            TextButton(
              onPressed: () {
                setState(() => _apiKey = '');
                _persist(context);
              },
              style: TextButton.styleFrom(foregroundColor: AppColors.expense),
              child: const Text('Remove Key'),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatusBanner extends StatelessWidget {
  final bool isEnabled;
  final bool hasKey;
  final LLMProvider provider;
  final String model;

  const _StatusBanner({required this.isEnabled, required this.hasKey, required this.provider, required this.model});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;
    String title;
    String subtitle;

    if (!isEnabled) {
      icon = Icons.bedtime_outlined;
      color = AppColors.textSecondary;
      title = 'Disabled';
      subtitle = 'Only regex parsing is used';
    } else if (!hasKey) {
      icon = Icons.warning_amber_rounded;
      color = const Color(0xFFFF9500);
      title = 'API Key Required';
      subtitle = 'Configure an API key to enable AI parsing';
    } else {
      icon = Icons.check_circle;
      color = AppColors.income;
      title = 'Active — ${provider.displayName}';
      subtitle = 'Model: $model';
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProviderRow extends StatelessWidget {
  final LLMProvider provider;
  final bool isSelected;
  final VoidCallback onTap;

  const _ProviderRow({required this.provider, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      title: Text(provider.displayName, style: TextStyle(fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal)),
      subtitle: Text(provider.pricingNote, style: const TextStyle(fontSize: 11)),
      trailing: isSelected ? const Icon(Icons.check_circle, color: AppColors.primary) : null,
    );
  }
}

extension on LLMProvider {
  String get apiKeyPlaceholderPrefix {
    switch (this) {
      case LLMProvider.openai:
        return 'sk-';
      case LLMProvider.anthropic:
        return 'sk-ant-';
      case LLMProvider.gemini:
        return 'AIza';
      case LLMProvider.groq:
        return 'gsk_';
      case LLMProvider.mistral:
        return '';
    }
  }
}
