import 'package:flutter/material.dart';
import '../core/utils/date_helpers.dart';

class DatePickerField extends StatefulWidget {
  final DateTime? initialDate;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final String label;
  final ValueChanged<DateTime>? onDateSelected;
  final String? Function(DateTime?)? validator;

  const DatePickerField({
    super.key,
    this.initialDate,
    this.firstDate,
    this.lastDate,
    required this.label,
    this.onDateSelected,
    this.validator,
  });

  @override
  State<DatePickerField> createState() => _DatePickerFieldState();
}

class _DatePickerFieldState extends State<DatePickerField> {
  late DateTime? _selectedDate;
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _updateController();
  }

  @override
  void didUpdateWidget(DatePickerField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialDate != oldWidget.initialDate) {
      _selectedDate = widget.initialDate;
      _updateController();
    }
  }

  void _updateController() {
    _controller.text = _selectedDate != null 
        ? DateHelpers.formatDate(_selectedDate!)
        : '';
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: widget.firstDate ?? DateTime(2000),
      lastDate: widget.lastDate ?? now,
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _updateController();
      });
      widget.onDateSelected?.call(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _controller,
      readOnly: true,
      decoration: InputDecoration(
        labelText: widget.label,
        suffixIcon: IconButton(
          icon: const Icon(Icons.calendar_today),
          onPressed: _selectDate,
        ),
      ),
      onTap: _selectDate,
      validator: widget.validator != null 
          ? (_) => widget.validator!(_selectedDate)
          : null,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
