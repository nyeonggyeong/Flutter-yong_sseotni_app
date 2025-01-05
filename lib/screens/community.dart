import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CommunityPage extends StatefulWidget {
  final int userIdx; // 로그인된 유저 ID

  const CommunityPage({super.key, required this.userIdx});

  @override
  _CommunityPageState createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  List<Map<String, dynamic>> _posts = []; // 게시글 목록
  bool _isLoading = false;

  final String apiUrl =
      'http://3.36.22.27:8080/Spring-yong_sseotni/api/board'; // API URL

  @override
  void initState() {
    super.initState();
    _fetchPosts(); // 게시물 목록 로드
  }

  // 게시글 목록 가져오기
  Future<void> _fetchPosts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(Uri.parse('$apiUrl/findByBoardPage'));
      if (response.statusCode == 200) {
        final List<dynamic> data =
            json.decode(utf8.decode(response.bodyBytes)); // UTF-8 디코딩
        setState(() {
          _posts = data.map((item) => item as Map<String, dynamic>).toList();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('게시글 로드 실패: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('오류 발생: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 게시글 작성
  Future<void> _submitPost() async {
    if (_titleController.text.isEmpty || _contentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('제목과 내용을 입력하세요.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('$apiUrl/save'),
        body: {
          'user_idx': widget.userIdx.toString(),
          'board_title': _titleController.text,
          'board_content': _contentController.text,
        },
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('게시물이 성공적으로 작성되었습니다.')),
        );
        _fetchPosts(); // 작성 후 목록 갱신
        _titleController.clear();
        _contentController.clear();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('작성 실패: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('오류 발생: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 게시글 삭제
  Future<void> _deletePost(int boardIdx) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('$apiUrl/deleteBoard'),
        body: {
          'board_idx': boardIdx.toString(),
          'user_idx': widget.userIdx.toString(),
        },
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('게시물이 성공적으로 삭제되었습니다.')),
        );
        _fetchPosts(); // 삭제 후 목록 갱신
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('삭제 실패: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('오류 발생: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 게시글 수정
  Future<void> _updatePost(
      int boardIdx, String initialTitle, String initialContent) async {
    final TextEditingController titleController =
        TextEditingController(text: initialTitle);
    final TextEditingController contentController =
        TextEditingController(text: initialContent);

    // 다이얼로그로 수정 입력 받기
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('게시물 수정'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: '제목'),
              ),
              TextField(
                controller: contentController,
                decoration: const InputDecoration(labelText: '내용'),
                maxLines: 5,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context); // 다이얼로그 닫기
                if (titleController.text.isEmpty ||
                    contentController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('제목과 내용을 입력하세요.')),
                  );
                  return;
                }

                setState(() {
                  _isLoading = true;
                });

                try {
                  // 서버로 수정 요청 보내기
                  final response = await http.post(
                    Uri.parse('$apiUrl/updateBoard'),
                    body: {
                      'board_idx': boardIdx.toString(),
                      'board_title': titleController.text,
                      'board_content': contentController.text,
                      'user_idx': widget.userIdx.toString(),
                    },
                  );

                  if (response.statusCode == 200) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('게시물이 성공적으로 수정되었습니다.')),
                    );
                    _fetchPosts(); // 목록 갱신
                  } else if (response.statusCode == 403) {
                    // 권한 없음
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('수정할 권한이 없습니다.')),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('수정 실패: ${response.body}')),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('오류 발생: $e')),
                  );
                } finally {
                  setState(() {
                    _isLoading = false;
                  });
                }
              },
              child: const Text('저장'),
            ),
          ],
        );
      },
    );
  }

  // 게시글 작성 다이얼로그
  void _showPostDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('게시물 작성'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: '제목'),
              ),
              TextField(
                controller: _contentController,
                decoration: const InputDecoration(labelText: '내용'),
                maxLines: 5,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _submitPost();
              },
              child: const Text('작성'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('커뮤니티'),
        backgroundColor: const Color(0xFF7CF5A5),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchPosts,
              child: ListView.builder(
                itemCount: _posts.length,
                itemBuilder: (context, index) {
                  final post = _posts[index];
                  return Card(
                    margin: const EdgeInsets.all(8.0),
                    child: ListTile(
                      title: Text(post['board_title'] ?? '제목 없음'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(post['board_content'] ?? '내용 없음'),
                          Text(
                            post['author_name'] != null
                                ? '작성자: ${post['author_name']}'
                                : '작성자 정보 없음',
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _updatePost(
                              post['board_idx'],
                              post['board_title'] ?? '',
                              post['board_content'] ?? '',
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deletePost(post['board_idx']),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showPostDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
