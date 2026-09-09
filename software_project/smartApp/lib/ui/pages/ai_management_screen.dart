import 'package:flutter/material.dart';
import '../../core/di/app_di.dart';
import 'app_shell.dart';

class AiManagementScreen extends StatefulWidget {
  const AiManagementScreen({super.key});

  @override
  State<AiManagementScreen> createState() => _AiManagementScreenState();
}

class _AiManagementScreenState extends State<AiManagementScreen> {
  int tab = 1; // 0 students, 1 lessons, 2 analytics

  List<_MaterialItem> _materials = [];
  bool _loading = true;
  String? _error;

  bool _wide(BuildContext c) => MediaQuery.of(c).size.width >= 980;
  bool _mid(BuildContext c) => MediaQuery.of(c).size.width >= 680;

  @override
  void initState() {
    super.initState();
    _fetchMaterials();
  }

  Future<void> _fetchMaterials() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await apiClient.getAuthed('/api/materials');
      if (res is List) {
        setState(() {
          _materials = res.map((item) {
            if (item is Map) {
              return _MaterialItem(
                id: (item['id'] as num?)?.toInt() ?? 0,
                title: item['title']?.toString() ?? 'Untitled Lesson',
                contentUrl: item['contentUrl']?.toString() ?? '',
                teacherEmail: (item['teacher'] is Map ? item['teacher']['email'] : null)?.toString() ?? 'teacher@classroom.com',
                createdAt: item['createdAt']?.toString() ?? '',
              );
            }
            return _MaterialItem(id: 0, title: 'Unknown', contentUrl: '', teacherEmail: '', createdAt: '');
          }).toList();
          _loading = false;
        });
      } else {
        setState(() {
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load learning materials: $e'),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    }
  }

  Future<void> _showCreateDialog() async {
    final titleCtrl = TextEditingController();
    final urlCtrl = TextEditingController();
    String? dialogError;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: const Text('Add Learning Material / Lesson', style: TextStyle(fontWeight: FontWeight.w800)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (dialogError != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFFCA5A5)),
                      ),
                      child: Text(dialogError!, style: const TextStyle(color: Color(0xFF991B1B), fontSize: 12)),
                    ),
                  const Text('Lesson Title', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(hintText: 'e.g. Linear Algebra & Matrices'),
                  ),
                  const SizedBox(height: 14),
                  const Text('Content URL or PDF Path', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: urlCtrl,
                    decoration: const InputDecoration(hintText: 'e.g. https://classroom.internal/materials/algebra.pdf'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final title = titleCtrl.text.trim();
                  final url = urlCtrl.text.trim();

                  if (title.isEmpty) {
                    setDialogState(() => dialogError = 'Please enter a title for the lesson');
                    return;
                  }
                  if (url.isEmpty) {
                    setDialogState(() => dialogError = 'Please enter a content URL or document link');
                    return;
                  }

                  try {
                    await apiClient.postAuthed('/api/materials', {
                      'title': title,
                      'contentUrl': url,
                    });
                    if (ctx.mounted) Navigator.pop(ctx);
                    _fetchMaterials();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Material uploaded and indexed for AI Teacher!'),
                          backgroundColor: Color(0xFF16A34A),
                        ),
                      );
                    }
                  } catch (e) {
                    setDialogState(() => dialogError = e.toString());
                  }
                },
                child: const Text('Upload & Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showEditDialog(_MaterialItem item) async {
    final titleCtrl = TextEditingController(text: item.title);
    final urlCtrl = TextEditingController(text: item.contentUrl);
    String? dialogError;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: const Text('Edit Learning Material', style: TextStyle(fontWeight: FontWeight.w800)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (dialogError != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFFCA5A5)),
                      ),
                      child: Text(dialogError!, style: const TextStyle(color: Color(0xFF991B1B), fontSize: 12)),
                    ),
                  const Text('Lesson Title', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(hintText: 'Lesson Title'),
                  ),
                  const SizedBox(height: 14),
                  const Text('Content URL', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: urlCtrl,
                    decoration: const InputDecoration(hintText: 'Content URL'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final title = titleCtrl.text.trim();
                  final url = urlCtrl.text.trim();

                  if (title.isEmpty || url.isEmpty) {
                    setDialogState(() => dialogError = 'All fields are required');
                    return;
                  }

                  try {
                    await apiClient.putAuthed('/api/materials/${item.id}', {
                      'title': title,
                      'contentUrl': url,
                    });
                    if (ctx.mounted) Navigator.pop(ctx);
                    _fetchMaterials();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Material updated successfully!'),
                          backgroundColor: Color(0xFF16A34A),
                        ),
                      );
                    }
                  } catch (e) {
                    setDialogState(() => dialogError = e.toString());
                  }
                },
                child: const Text('Save Changes'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _deleteMaterial(_MaterialItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Material?'),
        content: Text('Are you sure you want to delete "${item.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await apiClient.deleteAuthed('/api/materials/${item.id}');
        _fetchMaterials();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Material deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete material: $e'),
              backgroundColor: const Color(0xFFDC2626),
            ),
          );
        }
      }
    }
  }

  void _previewMaterial(_MaterialItem item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.w800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Resource URL / Document:', style: TextStyle(fontSize: 12, color: Colors.black.withOpacity(0.55), fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            SelectableText(item.contentUrl, style: const TextStyle(fontSize: 13, color: Color(0xFF2563EB), fontWeight: FontWeight.w600)),
            const SizedBox(height: 14),
            Text('Instructor:', style: TextStyle(fontSize: 12, color: Colors.black.withOpacity(0.55), fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(item.teacherEmail, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ),
        actions: [
          ElevatedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTeacherOrAdmin = apiClient.currentRole != 'student';

    return AppShell(
      title: 'Teacher Management',
      subtitle: 'Monitor student progress and manage AI learning resources',
      selectedRoute: '/ai-management',
      actions: [
        if (isTeacherOrAdmin)
          SizedBox(
            height: 38,
            child: ElevatedButton.icon(
              onPressed: _showCreateDialog,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('New Lesson'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                textStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12.5),
              ),
            ),
          ),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Tabs(
            selected: tab,
            onChanged: (i) => setState(() => tab = i),
          ),
          const SizedBox(height: 14),
          _CardShell(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: tab == 0
                    ? const _StudentsTab(key: ValueKey('students'))
                    : tab == 1
                        ? _buildLessonsView()
                        : _AnalyticsTab(
                            key: const ValueKey('analytics'),
                            columns: _wide(context) ? 2 : 1,
                          ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLessonsView() {
    final columns = _wide(context) ? 3 : (_mid(context) ? 2 : 1);

    if (_loading) {
      return const SizedBox(
        height: 280,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 14),
              Text('Fetching materials from backend...', style: TextStyle(color: Color(0xFF64748B))),
            ],
          ),
        ),
      );
    }

    if (_error != null && _materials.isEmpty) {
      return SizedBox(
        height: 280,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 36),
              const SizedBox(height: 10),
              Text('Error loading materials:\n$_error', textAlign: TextAlign.center),
              const SizedBox(height: 14),
              ElevatedButton(onPressed: _fetchMaterials, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Course Materials (${_materials.length} active)',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.refresh, size: 20),
              tooltip: 'Refresh Materials',
              onPressed: _fetchMaterials,
            ),
          ],
        ),
        const SizedBox(height: 12),
        _WrapGrid(
          columns: columns,
          children: [
            ..._materials.map((m) => _LessonCard(
                  item: m,
                  onEdit: () => _showEditDialog(m),
                  onDelete: () => _deleteMaterial(m),
                  onPreview: () => _previewMaterial(m),
                )),
            _CreateLessonCard(onTap: _showCreateDialog),
          ],
        ),
      ],
    );
  }
}

/* ---------------- Models ---------------- */

class _MaterialItem {
  final int id;
  final String title;
  final String contentUrl;
  final String teacherEmail;
  final String createdAt;

  _MaterialItem({
    required this.id,
    required this.title,
    required this.contentUrl,
    required this.teacherEmail,
    required this.createdAt,
  });
}

/* ---------------- Tabs ---------------- */

class _Tabs extends StatelessWidget {
  const _Tabs({required this.selected, required this.onChanged});

  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: 6),
        _TabItem(
          icon: Icons.people_outline,
          label: 'Students',
          selected: selected == 0,
          onTap: () => onChanged(0),
        ),
        const SizedBox(width: 18),
        _TabItem(
          icon: Icons.menu_book_outlined,
          label: 'Lessons & Materials',
          selected: selected == 1,
          onTap: () => onChanged(1),
        ),
        const SizedBox(width: 18),
        _TabItem(
          icon: Icons.bar_chart_rounded,
          label: 'Analytics',
          selected: selected == 2,
          onTap: () => onChanged(2),
        ),
      ],
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? const Color(0xFF2563EB) : Colors.black.withOpacity(0.55);

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: fg),
              const SizedBox(width: 8),
              Text(label, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12.5, color: fg)),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 2.2,
            width: 92,
            decoration: BoxDecoration(
              color: selected ? const Color(0xFF2563EB) : Colors.transparent,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
        ],
      ),
    );
  }
}

/* ---------------- Card Shell ---------------- */

class _CardShell extends StatelessWidget {
  const _CardShell({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            blurRadius: 26,
            offset: const Offset(0, 16),
            color: Colors.black.withOpacity(0.08),
          ),
        ],
      ),
      child: child,
    );
  }
}

/* ---------------- Students Tab ---------------- */

class _StudentsTab extends StatelessWidget {
  const _StudentsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final students = [
      ('STU1001', 'Alex Johnson', 'Mathematics', '92% Average', 'Active'),
      ('STU1002', 'Sophia Martinez', 'Computer Science', '88% Average', 'Active'),
      ('STU1003', 'Liam Chen', 'Physics & Science', '95% Average', 'Active'),
      ('STU1004', 'Emma Davis', 'Languages', '81% Average', 'Active'),
      ('STU1005', 'Noah Wilson', 'Mathematics', '79% Average', 'Active'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Enrolled Students & Performance', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
        const SizedBox(height: 12),
        ...students.map((s) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black.withOpacity(0.05)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: const Color(0xFFDCEBFF),
                    child: Text(s.$1.substring(3), style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF2563EB))),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.$2, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                        Text('${s.$1} • ${s.$3}', style: TextStyle(fontSize: 11.5, color: Colors.black.withOpacity(0.55))),
                      ],
                    ),
                  ),
                  Text(s.$4, style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF16A34A), fontSize: 12)),
                ],
              ),
            )),
      ],
    );
  }
}

/* ---------------- Lesson Card ---------------- */

class _LessonCard extends StatelessWidget {
  const _LessonCard({
    required this.item,
    required this.onEdit,
    required this.onDelete,
    required this.onPreview,
  });

  final _MaterialItem item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onPreview;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 270),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFDCEBFF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.book_outlined, color: Color(0xFF2563EB), size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444), size: 20),
                tooltip: 'Delete Material',
                onPressed: onDelete,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Instructor: ${item.teacherEmail}',
            style: TextStyle(
              fontSize: 11,
              color: Colors.black.withOpacity(0.55),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.black.withOpacity(0.05)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Source Document:', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
                const SizedBox(height: 2),
                Text(
                  item.contentUrl,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF2563EB),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              SizedBox(
                height: 34,
                child: ElevatedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit, size: 14),
                  label: const Text('Edit'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    textStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11.5),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: onPreview,
                icon: const Icon(Icons.visibility_outlined, size: 14),
                label: const Text('Preview', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11.5)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CreateLessonCard extends StatelessWidget {
  const _CreateLessonCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 270),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF2563EB).withOpacity(0.35), style: BorderStyle.solid),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: const BoxDecoration(
                  color: Color(0xFFEAF1FF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add, color: Color(0xFF2563EB), size: 28),
              ),
              const SizedBox(height: 12),
              const Text('Add New Material', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13.5)),
              const SizedBox(height: 6),
              Text(
                'Upload notes, PDFs & index\nfor the AI Teacher',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11.5, color: Colors.black.withOpacity(0.55), fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/* ---------------- Analytics Tab ---------------- */

class _AnalyticsTab extends StatelessWidget {
  const _AnalyticsTab({super.key, required this.columns});
  final int columns;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Learning Resources Analytics', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w900)),
        const SizedBox(height: 14),
        _WrapGrid(
          columns: columns,
          children: const [
            _ChartBox(title: 'AI Query Volume', subtitle: '142 queries answered this week'),
            _ChartBox(title: 'Material Coverage', subtitle: '98% of queries resolved with context'),
          ],
        ),
      ],
    );
  }
}

class _ChartBox extends StatelessWidget {
  const _ChartBox({required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 130,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
            const SizedBox(height: 6),
            Text(subtitle, style: TextStyle(fontSize: 11.5, color: Colors.black.withOpacity(0.55), fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

/* ---------------- Layout Utilities ---------------- */

class _WrapGrid extends StatelessWidget {
  const _WrapGrid({required this.columns, required this.children});
  final int columns;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (_, c) {
      const spacing = 14.0;
      final w = c.maxWidth;
      final itemW = (w - (columns - 1) * spacing) / columns;

      return Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: children.map((e) => SizedBox(width: itemW, child: e)).toList(),
      );
    });
  }
}
