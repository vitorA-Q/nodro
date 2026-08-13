import 'dart:js_interop';

/// Web implementation: hands the event to a global `nodroTrack` hook.
///
/// Indirect on purpose. The app never talks to an analytics vendor directly, so
/// swapping Cloudflare Web Analytics for GoatCounter or removing tracking
/// entirely is an edit to one script tag in `web/index.html` — not a code
/// change, not a new dependency, and not a rebuild.
///
/// If no hook is installed the call is silently dropped, which is the correct
/// default: shipping without analytics must never break the game.
@JS('nodroTrack')
external JSFunction? get _nodroTrack;

void sendAnalyticsEvent(String event, Map<String, String> props) {
  final hook = _nodroTrack;
  if (hook == null) {
    return;
  }
  // Passed as a flat list of key/value strings rather than an object: it keeps
  // this file free of interop extension gymnastics, and the receiving hook in
  // index.html reassembles it in two lines.
  final flat = <JSString>[];
  props.forEach((key, value) {
    flat
      ..add(key.toJS)
      ..add(value.toJS);
  });
  hook.callAsFunction(null, event.toJS, flat.toJS);
}
