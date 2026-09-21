import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/auth/auth_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/staff_todo.dart';
import '../../data/services/todo_service.dart';
import 'dashboard_section_card.dart';

class MyTodoSection extends StatefulWidget {
  final int refreshVersion;

  const MyTodoSection({super.key, this.refreshVersion = 0});

  @override
  State<MyTodoSection> createState() => _MyTodoSectionState();
}

class _MyTodoSectionState extends State<MyTodoSection> {
  List<StaffTodo> _items = [];

  bool _isLoading = true;
  bool _isMutating = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTodos();
    });
  }

  @override
  void didUpdateWidget(covariant MyTodoSection oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.refreshVersion != widget.refreshVersion) {
      _loadTodos();
    }
  }

  Future<void> _loadTodos() async {
    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final service = _todoService();

      final items = await service.fetchTodos();

      if (!mounted) {
        return;
      }

      setState(() {
        _items = items;
        _isLoading = false;
      });

      debugPrint('[TODO] 목록 조회 완료: ${items.length}건');
    } catch (error) {
      debugPrint('[TODO] 목록 조회 실패: $error');

      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });

      _showMessage('To-do 목록을 불러오지 못했습니다.');
    }
  }

  TodoService _todoService() {
    final auth = context.read<AuthProvider>();

    return TodoService(apiClient: auth.authService.apiClient);
  }

  @override
  Widget build(BuildContext context) {
    final textScaler = MediaQuery.textScalerOf(context);

    final textScale = textScaler.scale(16) / 16;

    final remainingCount = _items.where((item) => !item.isCompleted).length;

    return DashboardSectionCard(
      title: 'MY TODO',
      actionLabel: '새로고침',
      onAction: _isLoading ? null : _loadTodos,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final horizontal = constraints.maxWidth >= 760 && textScale < 1.25;

          if (horizontal) {
            return _buildHorizontalLayout(remainingCount);
          }

          return _buildVerticalLayout(remainingCount);
        },
      ),
    );
  }

  Widget _buildHorizontalLayout(int remainingCount) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: _TodoSummary(
              count: remainingCount,
              onAdd: _addTodo,
              disabled: _isMutating,
            ),
          ),

          const SizedBox(width: 18),

          Expanded(child: _buildTodoContent()),
        ],
      ),
    );
  }

  Widget _buildVerticalLayout(int remainingCount) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TodoSummary(
            count: remainingCount,
            compact: true,
            onAdd: _addTodo,
            disabled: _isMutating,
          ),

          const SizedBox(height: 8),

          _buildTodoContent(),
        ],
      ),
    );
  }

  Widget _buildTodoContent() {
    if (_isLoading) {
      return const SizedBox(
        height: 98,
        child: Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 1.8,
              color: AppColors.primaryBlue,
            ),
          ),
        ),
      );
    }

    if (_items.isEmpty) {
      return const SizedBox(
        height: 98,
        child: Center(
          child: Text(
            '등록된 To-do가 없습니다.',
            style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
          ),
        ),
      );
    }

    return _TodoList(
      items: _items,
      disabled: _isMutating,
      onToggle: _toggleTodo,
      onDelete: _deleteTodo,
    );
  }

  Future<void> _toggleTodo(StaffTodo todo) async {
    if (_isMutating) {
      return;
    }

    final nextStatus = todo.isCompleted ? 'PENDING' : 'COMPLETED';

    setState(() {
      _isMutating = true;
    });

    try {
      await _todoService().updateStatus(todoId: todo.id, status: nextStatus);

      await _loadTodos();
    } catch (error) {
      debugPrint('[TODO] 상태 변경 실패: $error');

      _showMessage('To-do 상태를 변경하지 못했습니다.');
    } finally {
      if (mounted) {
        setState(() {
          _isMutating = false;
        });
      }
    }
  }

  Future<void> _deleteTodo(StaffTodo todo) async {
    if (_isMutating) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('To-do 삭제'),
          content: Text('"${todo.title}"을 삭제하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
              child: const Text('삭제'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    setState(() {
      _isMutating = true;
    });

    try {
      await _todoService().deleteTodo(todo.id);

      await _loadTodos();
    } catch (error) {
      debugPrint('[TODO] 삭제 실패: $error');

      _showMessage('To-do를 삭제하지 못했습니다.');
    } finally {
      if (mounted) {
        setState(() {
          _isMutating = false;
        });
      }
    }
  }

  Future<void> _addTodo() async {
    if (_isMutating) {
      return;
    }

    final result = await showDialog<_TodoFormResult>(
      context: context,
      builder: (context) {
        return const _AddTodoDialog();
      },
    );

    if (result == null || !mounted) {
      return;
    }

    setState(() {
      _isMutating = true;
    });

    try {
      await _todoService().createTodo(
        title: result.title,
        priority: result.priority,
        dueAt: result.dueAt,
        description: result.description,
      );

      await _loadTodos();
    } catch (error) {
      debugPrint('[TODO] 등록 실패: $error');

      _showMessage('To-do를 등록하지 못했습니다.');
    } finally {
      if (mounted) {
        setState(() {
          _isMutating = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
      );
  }
}

class _TodoFormResult {
  final String title;
  final String priority;
  final DateTime dueAt;
  final String description;

  const _TodoFormResult({
    required this.title,
    required this.priority,
    required this.dueAt,
    required this.description,
  });
}

class _AddTodoDialog extends StatefulWidget {
  const _AddTodoDialog();

  @override
  State<_AddTodoDialog> createState() => _AddTodoDialogState();
}

class _AddTodoDialogState extends State<_AddTodoDialog> {
  final _titleController = TextEditingController();

  final _descriptionController = TextEditingController();

  String _priority = 'NORMAL';
  TimeOfDay? _selectedTime;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final displayTime = _selectedTime == null
        ? '오늘'
        : _formatTime(_selectedTime!);

    return AlertDialog(
      title: const Text(
        'To-do 추가',
        style: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: '할 일',
                hintText: '예: 검사 결과 확인',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: _descriptionController,
              minLines: 2,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: '설명',
                hintText: '선택 입력',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _priority,
                    decoration: const InputDecoration(
                      labelText: '우선순위',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'NORMAL', child: Text('일반')),
                      DropdownMenuItem(value: 'HIGH', child: Text('중요')),
                    ],
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }

                      setState(() {
                        _priority = value;
                      });
                    },
                  ),
                ),

                const SizedBox(width: 10),

                OutlinedButton.icon(
                  onPressed: _pickTime,
                  icon: const Icon(Icons.schedule_rounded, size: 17),
                  label: Text(displayTime),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('취소'),
        ),
        FilledButton(onPressed: _submit, child: const Text('추가')),
      ],
    );
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );

    if (picked == null || !mounted) {
      return;
    }

    setState(() {
      _selectedTime = picked;
    });
  }

  void _submit() {
    final title = _titleController.text.trim();

    if (title.isEmpty) {
      return;
    }

    final now = DateTime.now().toUtc().add(const Duration(hours: 9));

    final selectedTime = _selectedTime;

    final dueAt = selectedTime == null
        ? DateTime(now.year, now.month, now.day, 23, 59)
        : DateTime(
            now.year,
            now.month,
            now.day,
            selectedTime.hour,
            selectedTime.minute,
          );

    Navigator.of(context).pop(
      _TodoFormResult(
        title: title,
        priority: _priority,
        dueAt: dueAt,
        description: _descriptionController.text.trim(),
      ),
    );
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');

    final minute = time.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }
}

class _TodoSummary extends StatelessWidget {
  final int count;
  final bool compact;
  final VoidCallback onAdd;
  final bool disabled;

  const _TodoSummary({
    required this.count,
    required this.onAdd,
    required this.disabled,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Row(
        children: [
          const _TodoIcon(),

          const SizedBox(width: 8),

          Text(
            '$count',
            style: const TextStyle(
              color: AppColors.navy,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(width: 6),

          const Text(
            'To-do',
            style: TextStyle(
              color: AppColors.primaryBlue,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),

          const Spacer(),

          _TodoAddButton(onTap: onAdd, disabled: disabled),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const _TodoIcon(),

            const SizedBox(width: 6),

            _TodoAddButton(onTap: onAdd, disabled: disabled),
          ],
        ),

        const SizedBox(height: 7),

        Text(
          '$count',
          style: const TextStyle(
            color: AppColors.navy,
            fontSize: 24,
            height: 1,
            fontWeight: FontWeight.w800,
          ),
        ),

        const SizedBox(height: 3),

        const Text(
          'To-do',
          style: TextStyle(
            color: AppColors.primaryBlue,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _TodoIcon extends StatelessWidget {
  const _TodoIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 23,
      height: 23,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: AppColors.surfaceSoft,
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.push_pin_outlined,
        size: 12,
        color: AppColors.primaryBlue,
      ),
    );
  }
}

class _TodoAddButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool disabled;

  const _TodoAddButton({required this.onTap, required this.disabled});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'To-do 추가',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: disabled ? null : onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: 23,
            height: 23,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.surfaceSoft,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(
              Icons.add_rounded,
              size: 15,
              color: AppColors.primaryBlue,
            ),
          ),
        ),
      ),
    );
  }
}

class _TodoList extends StatelessWidget {
  final List<StaffTodo> items;
  final bool disabled;

  final ValueChanged<StaffTodo> onToggle;

  final ValueChanged<StaffTodo> onDelete;

  const _TodoList({
    required this.items,
    required this.disabled,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final item in items.take(5))
          _TodoRow(
            data: item,
            disabled: disabled,
            onTap: () {
              onToggle(item);
            },
            onDelete: () {
              onDelete(item);
            },
          ),
      ],
    );
  }
}

class _TodoRow extends StatelessWidget {
  final StaffTodo data;
  final bool disabled;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _TodoRow({
    required this.data,
    required this.disabled,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final completed = data.isCompleted;

    final isHigh = data.isHighPriority;

    return InkWell(
      onTap: disabled ? null : onTap,
      borderRadius: BorderRadius.circular(AppRadius.small),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 17,
              height: 17,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: completed ? AppColors.primaryBlue : Colors.transparent,
                border: Border.all(
                  color: completed
                      ? AppColors.primaryBlue
                      : isHigh
                      ? AppColors.warning
                      : AppColors.textDisabled,
                  width: 1.5,
                ),
              ),
              child: completed
                  ? const Icon(
                      Icons.check_rounded,
                      size: 11,
                      color: Colors.white,
                    )
                  : null,
            ),

            const SizedBox(width: 9),

            Expanded(
              child: Text(
                data.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: completed
                      ? AppColors.textDisabled
                      : AppColors.textPrimary,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  decoration: completed ? TextDecoration.lineThrough : null,
                ),
              ),
            ),

            const SizedBox(width: 8),

            Text(
              _formatDueAt(data.dueAt),
              style: TextStyle(
                color: completed
                    ? AppColors.textDisabled
                    : isHigh
                    ? AppColors.warning
                    : AppColors.textSecondary,
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(width: 3),

            PopupMenuButton<String>(
              tooltip: 'To-do 메뉴',
              padding: EdgeInsets.zero,
              iconSize: 17,
              icon: const Icon(
                Icons.more_vert_rounded,
                color: AppColors.textSecondary,
              ),
              onSelected: (value) {
                if (value == 'delete') {
                  onDelete();
                }
              },
              itemBuilder: (context) {
                return const [
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_outline,
                          size: 17,
                          color: AppColors.danger,
                        ),
                        SizedBox(width: 7),
                        Text('삭제'),
                      ],
                    ),
                  ),
                ];
              },
            ),
          ],
        ),
      ),
    );
  }
}

String _formatDueAt(DateTime? date) {
  if (date == null) {
    return '-';
  }

  final now = DateTime.now().toUtc().add(const Duration(hours: 9));

  final isToday =
      date.year == now.year && date.month == now.month && date.day == now.day;

  final hour = date.hour.toString().padLeft(2, '0');

  final minute = date.minute.toString().padLeft(2, '0');

  if (isToday) {
    if (date.hour == 23 && date.minute == 59) {
      return '오늘';
    }

    return '$hour:$minute';
  }

  final month = date.month.toString().padLeft(2, '0');

  final day = date.day.toString().padLeft(2, '0');

  return '$month.$day';
}
