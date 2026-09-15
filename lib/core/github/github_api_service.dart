import 'dart:convert';
import 'package:http/http.dart' as http;
class GitHubApiService {
  final String token; final String owner='phakphoum38-stack'; final String repo='EqualizerPro';
  GitHubApiService({required this.token});
  Map<String,String> get headers => {'Authorization':'Bearer \','Accept':'application/vnd.github.v3+json'};
  Future<bool> pushFile({required String path, required String content, required String branch, required String msg}) async {
    final shaUrl = Uri.parse('https://api.github.com/repos/\/\/contents/\=\');
    final shaRes = await http.get(shaUrl, headers: headers);
    String? sha; if (shaRes.statusCode==200) sha = jsonDecode(shaRes.body)['sha'];
    final url = Uri.parse('https://api.github.com/repos/\/\/contents/\');
    final body = jsonEncode({'message':msg,'content':base64Encode(utf8.encode(content)),'branch':branch, if(sha!=null) 'sha':sha});
    final res = await http.put(url, headers: headers, body: body);
    return res.statusCode==200||res.statusCode==201;
  }
}
