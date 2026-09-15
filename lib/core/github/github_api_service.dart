import 'dart:convert';
import 'package:http/http.dart' as http;

class GitHubApiService {
  final String token;
  final String owner = 'phakphoum38-stack';
  final String repo = 'EqualizerPro';

  GitHubApiService({required this.token});

  Map<String, String> get headers => {
    'Authorization': 'Bearer $token',
    'Accept': 'application/vnd.github.v3+json',
    'Content-Type': 'application/json',
  };

  Future<String?> getFileSha(String path, String branch) async {
    final url = Uri.parse('https://api.github.com/repos/$owner/$repo/contents/$path?ref=$branch');
    final res = await http.get(url, headers: headers);
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return data['sha'] as String?;
    }
    return null;
  }

  Future<bool> pushFile({
    required String path,
    required String content,
    required String branch,
    required String message,
  }) async {
    try {
      final sha = await getFileSha(path, branch);
      final url = Uri.parse('https://api.github.com/repos/$owner/$repo/contents/$path');
      final body = jsonEncode({
        'message': message,
        'content': base64Encode(utf8.encode(content)),
        'branch': branch,
        if (sha != null) 'sha': sha,
      });
      final res = await http.put(url, headers: headers, body: body);
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  Future<bool> pushMultipleFiles({
    required Map<String, String> files,
    required String branch,
    required String message,
  }) async {
    for (final entry in files.entries) {
      final ok = await pushFile(
        path: entry.key,
        content: entry.value,
        branch: branch,
        message: message,
      );
      if (!ok) return false;
    }
    return true;
  }
}
