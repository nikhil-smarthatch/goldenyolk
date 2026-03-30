import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/providers/settings_provider.dart';

class AmountInput extends ConsumerStatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? Function(String?)? validator;
  final void Function(double)? onChanged;

  const AmountInput({
    super.key,
    required this.controller,
    required this.label,
    this.validator,
    this.onChanged,
  });

  @override
  ConsumerState<AmountInput> createState() => _AmountInputState();
}

class _AmountInputState extends ConsumerState<AmountInput> {
  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    
    return TextFormField(
      controller: widget.controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: widget.label,
        prefixText: '${settings.currencySymbol} ',
      ),
      validator: widget.validator,
      onChanged: (value) {
        final amount = double.tryParse(value) ?? 0;
        widget.onChanged?.call(amount);
      },
    );
  }
}

class QuantityInput extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? suffix;
  final String? Function(String?)? validator;
  final void Function(int)? onChanged;

  const QuantityInput({
    super.key,
    required this.controller,
    required this.label,
    this.suffix,
    this.validator,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix,
      ),
      validator: validator,
      onChanged: (value) {
        final quantity = int.tryParse(value) ?? 0;
        onChanged?.call(quantity);
      },
    );
  }
}
