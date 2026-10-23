{{flutter_js}}
{{flutter_build_config}}

// Fallback fonts (glyphs missing from the bundled fonts) are requested from the
// app's own origin; the engine default is fonts.gstatic.com, which would break
// the no-network rule (Constitution I, research R20). A missing glyph renders
// as a box instead of triggering an external request.
_flutter.loader.load({
  config: {
    fontFallbackBaseUrl: 'fallback-fonts/',
  },
});
