import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Opens the settings (Ctrl/Cmd + ,).
class OpenSettingsIntent extends Intent {
  /// Creates the intent.
  const new();
}

/// Shows the list of keyboard shortcuts (?).
class ShowShortcutsIntent extends Intent {
  /// Creates the intent.
  const new();
}

/// App-wide keyboard shortcuts (contracts/ui/00 §7); the screens that own
/// each feature register the matching actions.
///
/// Space (start/pause) is bound by the home and countdown screens rather
/// than here, because an app-wide Space would stop activating the focused
/// button. Holding Esc to unlock belongs to the child lock.
const appShortcuts = <ShortcutActivator, Intent>{
  SingleActivator(LogicalKeyboardKey.comma, control: true):
      OpenSettingsIntent(),
  SingleActivator(LogicalKeyboardKey.comma, meta: true): OpenSettingsIntent(),
  CharacterActivator('?'): ShowShortcutsIntent(),
};
