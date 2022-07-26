import 'dart:io';

import 'package:flutter_app/src/infrastructure/proxies/custom_proxy_override.dart';

/// Following tutorial from: https://medium.com/hoursofoperation/use-charles-proxy-to-debug-network-requests-in-flutter-apps-2f2083275cad

/// Allows you to set and enable a proxy for your app
class CustomProxy {
  /// A string representing an IP address for the proxy server
  final String ipAddress;

  /// The port number for the proxy server
  /// Can be null if port is default.
  final int port;

  /// Set this to true
  /// - Warning: Setting this to true in production apps can be dangerous. Use with care!
  bool allowBadCertificates;

  /// Initializer
  CustomProxy(
      {required this.ipAddress, required this.port, this.allowBadCertificates = false});

  /// Initializer from string
  /// Note: Uses static method, rather than named init to allow final properties.
  static CustomProxy? fromString({required String proxy}) {
    // Check if valid
    if (proxy == null || proxy == "") {
      assert(false, "Proxy string passed to CustomProxy.fromString() is invalid.");
      return null;
    }

    // Build and return
    final proxyParts = proxy.split(":");
    final _ipAddress = proxyParts[0];
    final _port = proxyParts.length > 0 ? int.tryParse(proxyParts[1]) : null;
    return CustomProxy(
      ipAddress: _ipAddress,
      port: _port!,
    );
  }

  /// Enable the proxy
  void enable() {
    HttpOverrides.global = CustomProxyHttpOverride.withProxy(toString(), allowBadCertificates: true);
  }

  /// Disable the proxy
  void disable() {
    HttpOverrides.global = null;
  }

  @override
  String toString() {
    String proxy = ipAddress;
    if (port != null) {
      proxy += ":" + port.toString();
    }
    return proxy;
  }
}