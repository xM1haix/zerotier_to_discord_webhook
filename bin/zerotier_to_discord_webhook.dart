import 'dart:convert';
import 'dart:io';

Future<void> main() async {
  final server = await HttpServer.bind(InternetAddress.anyIPv4, 8081);
  final client = HttpClient();
  final uri = Uri.parse('MY DISCORD WEBHOOK LINK HERE');
  await for (final HttpRequest req in server) {
    if (req.method != 'POST') continue;
    try {
      final body = await utf8.decoder.bind(req).join();
      final p = jsonDecode(body) as Map<String, dynamic>;
      final h = p['hook_type'] as String?;
      final message = switch (h) {
        'NETWORK_JOIN' =>
          '🔔 **NETWORK_JOIN**\nNetwork: `${p['network_id']}`\nNew Member: `${p['member_id']}`',
        'NETWORK_AUTH' =>
          '✅ **NETWORK_AUTH**\nNetwork: `${p['network_id']}`\nMember: `${p['member_id']}`\nBy: `${p['user_email']}`',
        'NETWORK_DEAUTH' =>
          '🚫 **NETWORK_DEAUTH**\nNetwork: `${p['network_id']}`\nMember: `${p['member_id']}`\nBy: `${p['user_email']}`',
        'NETWORK_SSO_LOGIN' =>
          '🔑 **SSO LOGIN**\nNetwork: `${p['network_id']}`\nMember: `${p['member_id']}`\nUser: `${p['sso_user_email']}`',
        'NETWORK_SSO_LOGIN_ERROR' =>
          '⚠️ **SSO LOGIN ERROR**\nNetwork: `${p['network_id']}`\nUser: `${p['sso_user_email']}`\nError: `${p['error']}`',
        'NETWORK_CREATED' =>
          '🆕 **NETWORK_CREATED**\nNetwork ID: `${p['network_id']}`\nBy: `${p['user_email']}`',
        'NETWORK_CONFIG_CHANGED' =>
          '📝 **NETWORK_CONFIG_CHANGED**\nNetwork: `${p['network_id']}`\nBy: `${p['user_email']}`',
        'NETWORK_DELETED' =>
          '💀 **NETWORK_DELETED**\nNetwork ID: `${p['network_id']}`\nBy: `${p['user_email']}`',
        'MEMBER_CONFIG_CHANGED' =>
          '🛠️ **MEMBER_CONFIG_CHANGED**\nNetwork: `${p['network_id']}`\nMember: `${p['member_id']}`\nBy: `${p['user_email']}`',
        'MEMBER_DELETED' =>
          '🗑️ **MEMBER_DELETED**\nNetwork: `${p['network_id']}`\nMember: `${p['member_id']}`\nBy: `${p['user_email']}`',
        'ORG_INVITE_SENT' =>
          '✉️ **ORG_INVITE_SENT**\nTo: `${p['invitee_email']}`\nBy: `${p['user_id']}`',
        'ORG_INVITE_ACCEPTED' =>
          '🙋 **ORG_INVITE_ACCEPTED**\nUser: `${p['user_email']}`',
        'ORG_INVITE_REJECTED' =>
          '🙅 **ORG_INVITE_REJECTED**\nUser: `${p['user_email']}`',
        'ORG_MEMBER_REMOVED' =>
          '🚷 **ORG_MEMBER_REMOVED**\nUser: `${p['removed_user_email']}`\nBy: `${p['user_id']}`',
        _ => '❓ Unknown hook_type: `$h`',
      };
      final request = await client.postUrl(uri);
      request.headers.contentType = ContentType.json;
      final payload = jsonEncode({'content': message});
      request.write(payload);
      final response = await request.close();
      if (response.statusCode != 204) {
        final responseBody = await utf8.decoder.bind(response).join();
        throw '⚠️ Discord webhook error: ${response.statusCode} $responseBody';
      }
      req.response
        ..statusCode = HttpStatus.ok
        ..write('ok')
        ..close();
    } catch (e) {
      print(e);
    }
  }
}
