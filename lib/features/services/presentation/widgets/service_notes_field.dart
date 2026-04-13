import 'package:flutter/material.dart';

import 'package:service_reminder/shared/widgets/app_text_field.dart';

class ServiceNotesField extends StatelessWidget {
  final TextEditingController controller;

  const ServiceNotesField({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      label: 'Notes (optional)',
      hint: 'e.g. Replaced carbon filter, pressure was low...',
      controller: controller,
      maxLines: 3,
      keyboardType: TextInputType.multiline,
      textInputAction: TextInputAction.newline,
    );
  }
}
