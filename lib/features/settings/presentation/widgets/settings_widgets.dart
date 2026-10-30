import 'package:flutter/material.dart';

/// A section header of the settings list.
class SettingsSectionHeader extends StatelessWidget {
  /// Creates a header; [sectionKey] names the section for tests
  /// (`settings.section.<sectionKey>`).
  new({required String sectionKey, required this.title, super.key})
    : _sectionKey = Key('settings.section.$sectionKey');

  final Key _sectionKey;

  /// The section title.
  final String title;

  static const _padding = EdgeInsets.fromLTRB(16, 24, 16, 8);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      key: _sectionKey,
      padding: _padding,
      child: Semantics(
        header: true,
        // The default small-title color is too faint on the cream surface.
        child: Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}

/// A label with a dropdown choice; the items are keyed
/// `<keyPrefix>.<name>` and the dropdown `<keyPrefix>`.
class SettingsDropdown<T extends Enum> extends StatelessWidget {
  /// Creates a choice among [values], showing [labelOf] for each.
  const new({
    required this.keyPrefix,
    required this.label,
    required this.values,
    required this.value,
    required this.labelOf,
    required this.onChanged,
    super.key,
  });

  /// The key of the dropdown; its items add `.<name>`.
  final String keyPrefix;

  /// The row label.
  final String label;

  /// The options.
  final List<T> values;

  /// The current option.
  final T value;

  /// The text of an option.
  final String Function(T option) labelOf;

  /// Called with the option the adult picked.
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) => ListTile(
    title: Text(label),
    trailing: DropdownButton<T>(
      key: Key(keyPrefix),
      value: value,
      // The row already carries the label for screen readers.
      onChanged: (option) {
        if (option != null) onChanged(option);
      },
      items: [
        for (final option in values)
          DropdownMenuItem(
            key: Key('$keyPrefix.${option.name}'),
            value: option,
            child: Text(labelOf(option)),
          ),
      ],
    ),
  );
}
