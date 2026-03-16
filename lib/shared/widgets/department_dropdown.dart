import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';

class DepartmentDropdown extends StatelessWidget {
  final String? value;
  final ValueChanged<String?> onChanged;
  final FormFieldValidator<String>? validator;

  const DepartmentDropdown({
    super.key,
    required this.value,
    required this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: const InputDecoration(
        labelText: 'Department',
        prefixIcon: Icon(Icons.business_outlined),
      ),
      items: AppConstants.departments
          .map((dept) => DropdownMenuItem(
                value: dept,
                child: Text(dept),
              ))
          .toList(),
      onChanged: onChanged,
      validator: validator,
    );
  }
}
