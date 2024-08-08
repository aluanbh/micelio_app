import 'package:flutter/material.dart';

class MultiSelectFormField extends FormField<List<String>> {
  final List<Map<String, dynamic>> items;
  final String title;

  MultiSelectFormField({
    required this.items,
    required this.title,
    FormFieldSetter<List<String>>? onSaved,
    FormFieldValidator<List<String>>? validator,
    List<String>? initialValue,
    bool autovalidate = false,
  }) : super(
          onSaved: onSaved,
          validator: validator,
          initialValue: initialValue ?? [],
          autovalidateMode: autovalidate
              ? AutovalidateMode.always
              : AutovalidateMode.disabled,
          builder: (FormFieldState<List<String>> state) {
            return InputDecorator(
              decoration: InputDecoration(
                labelText: title,
                errorText: state.hasError ? state.errorText : null,
              ),
              isEmpty: state.value == null || state.value!.isEmpty,
              child: Column(
                children: items.map((item) {
                  return CheckboxListTile(
                    title: Text(item['display']),
                    value: state.value!.contains(item['value']),
                    onChanged: (bool? checked) {
                      if (checked == true) {
                        if (!state.value!.contains(item['value'])) {
                          state.value!.add(item['value']);
                        }
                      } else {
                        state.value!.remove(item['value']);
                      }
                      state.didChange(state.value);
                    },
                  );
                }).toList(),
              ),
            );
          },
        );
}
