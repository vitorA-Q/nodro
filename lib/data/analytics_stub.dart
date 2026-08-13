/// Off-web build: analytics is a no-op.
///
/// Milestone 1 ships on the web only, and a native implementation would be
/// dead code with a maintenance cost.
void sendAnalyticsEvent(String event, Map<String, String> props) {}
