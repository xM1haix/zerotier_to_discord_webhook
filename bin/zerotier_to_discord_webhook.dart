import "dart:async";
import "dart:convert";
import "dart:io";

Future<void> main() async {
  final discord = Discord();
  await discord.report("Starting the HTTP Server");
  final server = await HttpServer.bind(InternetAddress.anyIPv4, 8081);
  await discord.report("Server started.\nWaiting for requests");
  await for (final HttpRequest req in server) {
    if (req.method != "POST") {
      await discord.report("Request is not POST: ${req.method}");
      continue;
    }
    await discord.report("Request retrived");
    try {
      final body = await utf8.decoder.bind(req).join();
      unawaited(discord.report(body));
      final x = const JsonEncoder.withIndent(
        "  ",
      ).convert(jsonDecode(body) as Map<String, dynamic>);
      await discord.sendMSG("```json\n$x\n```");
      req.response
        ..statusCode = HttpStatus.ok
        ..write("ok");
      await req.response.close();
    } catch (e, stack) {
      await discord.report("```\n$e\n$stack\n```");
      print(e);
    }
  }
}

class Discord {
  factory Discord() => _instance ??= Discord._internal();

  Discord._internal();
  static Discord? _instance;
  static final _client = HttpClient();
  static final _msgUri = Uri.parse("PUT FIRST TOKEN HERE");
  static final _reportUri = Uri.parse("PUT SECOND TOKEN HERE");
  static Discord get instance => Discord();
  void dispose() => _client.close(force: true);
  Future<void> report(String msg) => _send(msg, false);
  Future<void> sendMSG(String msg) => _send(msg);
  Future<void> _send(String msg, [bool isOk = true]) async {
    try {
      final request = await _client.postUrl(isOk ? _msgUri : _reportUri);
      request
        ..headers.contentType = ContentType.json
        ..headers.set(
          "User-Agent",
          "ZeroTierToDiscord/1.0 (+https://github.com/xM1haix/zerotier_to_discord_webhook)",
        )
        ..write(jsonEncode({"content": msg}));
      final response = await request.close().timeout(
        const Duration(seconds: 5),
      );

      if (response.statusCode != 204) {
        final body = await utf8.decoder.bind(response).join();
        throw DiscordWebhookException(response.statusCode, body);
      }
    } on TimeoutException {
      throw DiscordWebhookException(-1, "Request timed out");
    }
  }
}

class DiscordWebhookException implements Exception {
  DiscordWebhookException(this.statusCode, this.body);
  final int statusCode;
  final String body;
  @override
  String toString() =>
      "DiscordWebhookException(statusCode: $statusCode, body: $body)";
}
