{
  localAnnounceEnabled = true;
  urAccepted = -1;
  # Disable QUIC to work around quic-go v0.56.0 TLS bug
  # that causes "crypto/tls bug: where's my session ticket?" panics
  connectionPriorityQuicLan = 0;
  connectionPriorityQuicWan = 0;
  # Force TCP-only mode to completely avoid QUIC
  listenAddresses = [ "tcp://:22000" ];
  # Disable crash reporting to avoid startup delays
  crashReportingEnabled = false;
}
