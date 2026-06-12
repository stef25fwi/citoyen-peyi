import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../services/commune_lookup_service.dart';

/// Champ "Commune" avec autocompletion predictive (referentiel officiel).
///
/// A la selection d'une suggestion, le nom est normalise dans [controller] et
/// [onSelected] est appele avec la commune complete (nom + code INSEE + CP) afin
/// que le parent remplisse les champs lies (code postal, INSEE).
class CommuneAutocompleteField extends StatefulWidget {
  const CommuneAutocompleteField({
    super.key,
    required this.controller,
    required this.onSelected,
    this.enabled = true,
    this.labelText = 'Commune *',
    this.hintText = 'Tapez le nom ou le code postal…',
    this.validator,
    this.autofocus = false,
    this.lookupService,
  });

  final TextEditingController controller;
  final ValueChanged<CommuneSuggestion> onSelected;
  final bool enabled;
  final String labelText;
  final String hintText;
  final String? Function(String?)? validator;
  final bool autofocus;
  final CommuneLookupService? lookupService;

  @override
  State<CommuneAutocompleteField> createState() =>
      _CommuneAutocompleteFieldState();
}

class _CommuneAutocompleteFieldState extends State<CommuneAutocompleteField> {
  Timer? _debounce;
  List<CommuneSuggestion> _suggestions = const [];
  bool _searching = false;

  CommuneLookupService get _service =>
      widget.lookupService ?? CommuneLookupService.instance;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    if (value.trim().length < 2) {
      setState(() {
        _suggestions = const [];
        _searching = false;
      });
      return;
    }
    setState(() => _searching = true);
    _debounce = Timer(const Duration(milliseconds: 280), () async {
      List<CommuneSuggestion> results = const [];
      try {
        results = await _service.search(value);
      } catch (error) {
        if (kDebugMode) {
          debugPrint('[CommuneAutocompleteField] recherche echouee: $error');
        }
      }
      if (mounted) {
        setState(() {
          _suggestions = results;
          _searching = false;
        });
      }
    });
  }

  void _select(CommuneSuggestion commune) {
    setState(() {
      widget.controller.text = commune.nom;
      _suggestions = const [];
      _searching = false;
    });
    widget.onSelected(commune);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: widget.controller,
          enabled: widget.enabled,
          autofocus: widget.autofocus,
          decoration: InputDecoration(
            labelText: widget.labelText,
            hintText: widget.hintText,
            suffixIcon: _searching
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : const Icon(Icons.location_on_outlined),
          ),
          onChanged: _onChanged,
          validator: widget.validator,
        ),
        if (_suggestions.isNotEmpty)
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFD7E0EA)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: _suggestions.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final c = _suggestions[i];
                return ListTile(
                  dense: true,
                  leading: const Icon(Icons.location_city_rounded,
                      size: 18, color: Color(0xFF0F6D8F)),
                  title: Text(c.nom,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(
                    '${c.codesPostaux.join(', ')}  •  INSEE ${c.code}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  onTap: () => _select(c),
                );
              },
            ),
          ),
      ],
    );
  }
}
