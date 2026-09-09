import 'package:flutter/material.dart';
import '../../core/di/app_di.dart';
import '../../core/network/api_client.dart';
import 'app_shell.dart';

class NoticeBoardScreen extends StatefulWidget {
  const NoticeBoardScreen({super.key});

  @override
  State<NoticeBoardScreen> createState() => _NoticeBoardScreenState();
}

class _NoticeBoardScreenState extends State<NoticeBoardScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _notices = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchNotices();
  }

  Future<void> _fetchNotices() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await apiClient.getAuthed('/api/notices');
      List<dynamic> list = [];
      if (res is Map && res.containsKey('notices')) {
        list = (res['notices'] as List?) ?? [];
      } else if (res is List) {
        list = res;
      }

      if (mounted) {
        setState(() {
          _notices = list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  bool get _isTeacherOrAdmin {
    final role = apiClient.currentRole ?? '';
    return role == 'teacher' || role == 'admin';
  }

  void _showPostNoticeDialog() {
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    String? validationError;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Row(
                children: [
                  Icon(Icons.campaign_rounded, color: Color(0xFF2D66F6)),
                  SizedBox(width: 10),
                  Text(
                    'Post Announcement',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                  ),
                ],
              ),
              content: SizedBox(
                width: 500,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (validationError != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline, color: Colors.red, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  validationError!,
                                  style: const TextStyle(color: Colors.red, fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      const Text(
                        'Notice Title',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: titleCtrl,
                        decoration: InputDecoration(
                          hintText: 'e.g. Midterm Physics Exam Schedule',
                          prefixIcon: const Icon(Icons.title, color: Color(0xFF2D66F6), size: 18),
                          fillColor: const Color(0xFFF8FAFC),
                          filled: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.black.withOpacity(0.08)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Announcement Content',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: contentCtrl,
                        maxLines: 5,
                        decoration: InputDecoration(
                          hintText: 'Enter detailed notice description for students...',
                          fillColor: const Color(0xFFF8FAFC),
                          filled: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.black.withOpacity(0.08)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2D66F6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  ),
                  icon: const Icon(Icons.send_rounded, size: 16, color: Colors.white),
                  label: const Text('Publish Notice', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                  onPressed: () async {
                    final title = titleCtrl.text.trim();
                    final content = contentCtrl.text.trim();

                    if (title.isEmpty) {
                      setModalState(() {
                        validationError = 'Please enter a title for the notice.';
                      });
                      return;
                    }
                    if (content.isEmpty) {
                      setModalState(() {
                        validationError = 'Please enter content for the notice.';
                      });
                      return;
                    }

                    try {
                      Navigator.pop(ctx);
                      setState(() => _loading = true);
                      await apiClient.postAuthed('/api/notices', {
                        'title': title,
                        'content': content,
                      });
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Notice posted successfully!'),
                            backgroundColor: Color(0xFF10B981),
                          ),
                        );
                        _fetchNotices();
                      }
                    } catch (err) {
                      if (mounted) {
                        setState(() => _loading = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to post notice: $err'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _deleteNotice(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Notice'),
        content: const Text('Are you sure you want to delete this notice?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await apiClient.deleteAuthed('/api/notices/$id');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notice deleted')),
        );
        _fetchNotices();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Delete failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  String _formatDate(String? iso) {
    if (iso == null) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);

      if (diff.inMinutes < 60) {
        return '${diff.inMinutes}m ago';
      } else if (diff.inHours < 24) {
        return '${diff.inHours}h ago';
      } else {
        return '${dt.month}/${dt.day}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      }
    } catch (_) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _notices.where((n) {
      final title = (n['title'] ?? '').toString().toLowerCase();
      final content = (n['content'] ?? '').toString().toLowerCase();
      final q = _searchQuery.toLowerCase();
      return title.contains(q) || content.contains(q);
    }).toList();

    return AppShell(
      title: 'Notice Board',
      subtitle: 'Official announcements and classroom updates',
      selectedRoute: '/notice-board',
      actions: [
        if (_isTeacherOrAdmin)
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2D66F6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            icon: const Icon(Icons.add_rounded, size: 18, color: Colors.white),
            label: const Text('Post Notice', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
            onPressed: _showPostNoticeDialog,
          ),
        const SizedBox(width: 8),
        IconButton(
          tooltip: 'Refresh',
          icon: const Icon(Icons.refresh_rounded, color: Color(0xFF2D66F6)),
          onPressed: _fetchNotices,
        ),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header banner & Search bar
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2D66F6), Color(0xFF5B99FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2D66F6).withOpacity(0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.campaign_rounded, color: Colors.white, size: 30),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Classroom Bulletin',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _isTeacherOrAdmin
                            ? 'Post real-time announcements, test dates, and lab guidelines.'
                            : 'Stay updated with your teachers announcements and exam schedules.',
                        style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.85)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Search bar
          TextField(
            onChanged: (v) => setState(() => _searchQuery = v),
            decoration: InputDecoration(
              hintText: 'Search notices by keyword or subject...',
              prefixIcon: const Icon(Icons.search, color: Color(0xFF2D66F6)),
              fillColor: Colors.white,
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.black.withOpacity(0.06)),
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Content body
          if (_loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_error != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red),
                  const SizedBox(width: 12),
                  Expanded(child: Text(_error!, style: const TextStyle(color: Colors.red))),
                  TextButton(
                    onPressed: _fetchNotices,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          else if (filtered.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(48),
                child: Column(
                  children: [
                    Icon(Icons.inbox_outlined, size: 48, color: Colors.black.withOpacity(0.25)),
                    const SizedBox(height: 12),
                    Text(
                      _searchQuery.isNotEmpty ? 'No notices matching "$_searchQuery"' : 'No announcements posted yet.',
                      style: TextStyle(fontSize: 14, color: Colors.black.withOpacity(0.5)),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final item = filtered[i];
                final id = item['id'] as int? ?? 0;
                final title = (item['title'] ?? 'Notice').toString();
                final content = (item['content'] ?? '').toString();
                final createdAt = item['createdAt']?.toString();
                final author = item['author'] as Map<String, dynamic>?;
                final authorEmail = author?['email']?.toString() ?? 'Faculty';
                final authorRole = author?['role']?.toString().toUpperCase() ?? 'TEACHER';

                final isAuthorOrAdmin = _isTeacherOrAdmin;

                return Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.black.withOpacity(0.06)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEAF1FF),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.notifications_active_outlined, color: Color(0xFF2D66F6), size: 20),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: authorRole == 'ADMIN'
                                            ? Colors.purple.shade50
                                            : Colors.blue.shade50,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        authorRole,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          color: authorRole == 'ADMIN'
                                              ? Colors.purple.shade700
                                              : Colors.blue.shade700,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      authorEmail,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.black.withOpacity(0.5),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Icon(Icons.circle, size: 4, color: Colors.black.withOpacity(0.2)),
                                    const SizedBox(width: 8),
                                    Text(
                                      _formatDate(createdAt),
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.black.withOpacity(0.4),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          if (isAuthorOrAdmin)
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                              tooltip: 'Delete Notice',
                              onPressed: () => _deleteNotice(id),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(height: 1),
                      const SizedBox(height: 12),
                      Text(
                        content,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.5,
                          color: const Color(0xFF334155),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
