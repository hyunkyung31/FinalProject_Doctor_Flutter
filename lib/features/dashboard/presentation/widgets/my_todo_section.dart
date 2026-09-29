import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/auth/auth_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_theme_context.dart';
import '../../data/models/staff_todo.dart';
import '../../data/services/todo_service.dart';
import 'dashboard_section_card.dart';

// ============================================================
// 오늘 To-do
// - DashboardPage에서 전달받은 실제 To-do 데이터 사용
// - 홈에서는 오늘 기준 To-do만 표시
// - + 버튼을 누르면 Dialog 대신 카드 내부 Inline Composer 표시
// ============================================================

class MyTodoSection extends StatefulWidget {
  final List<StaffTodo> items;
  final bool loadFailed;

  const MyTodoSection({
    super.key,
    required this.items,
    required this.loadFailed,
  });

  @override
  State<MyTodoSection> createState() => _MyTodoSectionState();
}

class _MyTodoSectionState extends State<MyTodoSection> {
  late List<StaffTodo> _items;
  late bool _loadFailed;

  bool _isLoading = false;
  bool _isMutating = false;

  // ============================================================
  // Inline To-do Composer State
  // ============================================================

  final _quickTodoController = TextEditingController();
  final _quickTodoFocusNode = FocusNode();

  bool _isComposing = false;
  String _composerPriority = 'NORMAL';
  late DateTime _composerDate;

  @override
  void initState() {
    super.initState();

    _items = List<StaffTodo>.of(widget.items);
    _loadFailed = widget.loadFailed;
    _composerDate = _nowKst();
  }

  @override
  void didUpdateWidget(covariant MyTodoSection oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!identical(oldWidget.items, widget.items) ||
        oldWidget.loadFailed != widget.loadFailed) {
      setState(() {
        _items = List<StaffTodo>.of(widget.items);
        _loadFailed = widget.loadFailed;
      });
    }
  }

  @override
  void dispose() {
    _quickTodoController.dispose();
    _quickTodoFocusNode.dispose();

    super.dispose();
  }

  // ============================================================
  // Service
  // ============================================================

  TodoService _todoService() {
    final auth = context.read<AuthProvider>();

    return TodoService(apiClient: auth.authService.apiClient);
  }

  Future<void> _loadTodos() async {
    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = true;
      _loadFailed = false;
    });

    try {
      final items = await _todoService().fetchTodos();

      if (!mounted) {
        return;
      }

      setState(() {
        _items = items;
        _isLoading = false;
        _loadFailed = false;
      });

      debugPrint('[TODO] 목록 조회 완료: ${items.length}건');
    } catch (error) {
      debugPrint('[TODO] 목록 조회 실패: $error');

      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _loadFailed = true;
      });

      _showMessage('To-do 목록을 불러오지 못했습니다.');
    }
  }

  // ============================================================
  // 오늘 표시 대상
  // React 홈과 같은 날짜 기준
  // ============================================================

  List<StaffTodo> _todayItems() {
    final today = _nowKst();

    final items = _items.where((item) {
      final dueAt = item.dueAt;

      // 기한이 있으면 오늘 기한인 항목만 홈에 표시
      if (dueAt != null) {
        return _isSameDay(dueAt, today);
      }

      // 기한이 없는 미완료 항목은 계속 표시
      if (!item.isCompleted) {
        return true;
      }

      // 기한이 없는 완료 항목은 오늘 완료한 경우만 표시
      final completedAt = item.completedAt;

      return completedAt != null && _isSameDay(completedAt, today);
    }).toList();

    // 미완료를 먼저 표시
    items.sort((a, b) {
      if (a.isCompleted == b.isCompleted) {
        return 0;
      }

      return a.isCompleted ? 1 : -1;
    });

    return items;
  }

  @override
  Widget build(BuildContext context) {
    final textScaler = MediaQuery.textScalerOf(context);

    final textScale = textScaler.scale(16) / 16;

    final todayItems = _todayItems();

    final remainingCount = todayItems.where((item) => !item.isCompleted).length;

    return DashboardSectionCard(
      title: '오늘 To-do',
      actionLabel: '새로고침',
      onAction: _isLoading ? null : _loadTodos,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final horizontal = constraints.maxWidth >= 760 && textScale < 1.25;

          if (horizontal) {
            return _buildHorizontalLayout(remainingCount, todayItems);
          }

          return _buildVerticalLayout(remainingCount, todayItems);
        },
      ),
    );
  }

  // ============================================================
  // Layout
  // ============================================================

  Widget _buildHorizontalLayout(
    int remainingCount,
    List<StaffTodo> todayItems,
  ) {
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

          Expanded(child: _buildTodoArea(todayItems)),
        ],
      ),
    );
  }

  Widget _buildVerticalLayout(int remainingCount, List<StaffTodo> todayItems) {
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

          const SizedBox(height: 5),

          _buildTodoArea(todayItems),
        ],
      ),
    );
  }

  // ============================================================
  // Inline Composer + 오늘 목록
  // ============================================================

  Widget _buildTodoArea(List<StaffTodo> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_isComposing) ...[
          _InlineTodoComposer(
            controller: _quickTodoController,
            focusNode: _quickTodoFocusNode,
            selectedDate: _composerDate,
            priority: _composerPriority,
            disabled: _isMutating,
            onPickDate: _pickTodoDate,
            onPriorityChanged: (value) {
              setState(() {
                _composerPriority = value;
              });
            },
            onSubmit: _submitInlineTodo,
            onCancel: _cancelTodoComposer,
          ),

          if (items.isNotEmpty)
            const Divider(height: 1, thickness: 1, color: AppColors.border),
        ],

        if (!_isComposing || items.isNotEmpty) _buildTodoContent(items),
      ],
    );
  }

  Widget _buildTodoContent(List<StaffTodo> items) {
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

    if (_loadFailed) {
      return const SizedBox(
        height: 98,
        child: Center(
          child: Text(
            'To-do 목록을 불러오지 못했습니다.',
            style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
          ),
        ),
      );
    }

    if (items.isEmpty) {
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
      items: items,
      disabled: _isMutating,
      onToggle: _toggleTodo,
      onDelete: _deleteTodo,
    );
  }

  // ============================================================
  // To-do 상태 변경
  // ============================================================

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

  // ============================================================
  // To-do 삭제
  // ============================================================

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

  // ============================================================
  // Inline To-do 추가 열기 / 취소
  // ============================================================

  void _addTodo() {
    if (_isMutating) {
      return;
    }

    if (_isComposing) {
      _quickTodoFocusNode.requestFocus();

      return;
    }

    _quickTodoController.clear();

    setState(() {
      _isComposing = true;

      _composerPriority = 'NORMAL';

      _composerDate = _nowKst();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _quickTodoFocusNode.requestFocus();
      }
    });
  }

  void _cancelTodoComposer() {
    _quickTodoController.clear();

    _quickTodoFocusNode.unfocus();

    setState(() {
      _isComposing = false;

      _composerPriority = 'NORMAL';

      _composerDate = _nowKst();
    });
  }

  // ============================================================
  // 날짜 선택
  // ============================================================

  Future<void> _pickTodoDate() async {
    final now = _nowKst();

    final picked = await showDatePicker(
      context: context,
      initialDate: _composerDate,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );

    if (picked == null || !mounted) {
      return;
    }

    setState(() {
      _composerDate = DateTime(picked.year, picked.month, picked.day);
    });
  }

  // ============================================================
  // 실제 API To-do 생성
  // ============================================================

  Future<void> _submitInlineTodo() async {
    if (_isMutating) {
      return;
    }

    final title = _quickTodoController.text.trim();

    if (title.isEmpty) {
      _showMessage('할 일을 입력해주세요.');

      _quickTodoFocusNode.requestFocus();

      return;
    }

    final dueAt = DateTime(
      _composerDate.year,
      _composerDate.month,
      _composerDate.day,
      23,
      59,
    );

    setState(() {
      _isMutating = true;
    });

    try {
      await _todoService().createTodo(
        title: title,
        priority: _composerPriority,
        dueAt: dueAt,
        description: '',
      );

      if (!mounted) {
        return;
      }

      _quickTodoController.clear();

      _quickTodoFocusNode.unfocus();

      setState(() {
        _isComposing = false;

        _composerPriority = 'NORMAL';

        _composerDate = _nowKst();
      });

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

// ============================================================
// Inline To-do Composer
// iOS Reminders 스타일의 빠른 입력 영역
// ============================================================

class _InlineTodoComposer extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;

  final DateTime selectedDate;
  final String priority;
  final bool disabled;

  final VoidCallback onPickDate;
  final ValueChanged<String> onPriorityChanged;
  final VoidCallback onSubmit;
  final VoidCallback onCancel;

  const _InlineTodoComposer({
    required this.controller,
    required this.focusNode,
    required this.selectedDate,
    required this.priority,
    required this.disabled,
    required this.onPickDate,
    required this.onPriorityChanged,
    required this.onSubmit,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final isHighPriority = priority == 'HIGH';

    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 1, 2, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ====================================================
          // STEP 1. 할 일 입력
          // ============================================================
          Row(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isHighPriority
                        ? AppColors.warning
                        : AppColors.textDisabled,
                    width: 1.4,
                  ),
                ),
              ),

              const SizedBox(width: 8),

              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  enabled: !disabled,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) {
                    if (!disabled) {
                      onSubmit();
                    }
                  },
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  decoration: const InputDecoration(
                    hintText: '할 일을 입력하세요',
                    hintStyle: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textSecondary,
                    ),
                    isDense: true,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 5),
                  ),
                ),
              ),

              const SizedBox(width: 4),

              Tooltip(
                message: '추가',
                child: InkWell(
                  onTap: disabled ? null : onSubmit,
                  borderRadius: BorderRadius.circular(20),
                  child: const Padding(
                    padding: EdgeInsets.all(3),
                    child: Icon(
                      Icons.check_circle_rounded,
                      size: 19,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 2),

          // ====================================================
          // STEP 2. 날짜 / 우선순위 / 취소
          // ============================================================
          Padding(
            padding: const EdgeInsets.only(left: 24),
            child: Row(
              children: [
                // 날짜
                _TodoComposerChip(
                  icon: Icons.calendar_today_outlined,
                  label: _formatComposerDate(selectedDate),
                  highlighted: false,
                  onTap: disabled ? null : onPickDate,
                ),

                const SizedBox(width: 5),

                // 우선순위
                PopupMenuButton<String>(
                  tooltip: '우선순위',
                  enabled: !disabled,
                  initialValue: priority,
                  onSelected: onPriorityChanged,
                  itemBuilder: (context) {
                    return const [
                      PopupMenuItem(value: 'NORMAL', child: Text('일반')),
                      PopupMenuItem(value: 'HIGH', child: Text('중요')),
                    ];
                  },
                  child: _TodoComposerChip(
                    icon: Icons.flag_outlined,
                    label: isHighPriority ? '중요' : '일반',
                    highlighted: isHighPriority,
                  ),
                ),

                const Spacer(),

                Tooltip(
                  message: '취소',
                  child: InkWell(
                    onTap: disabled ? null : onCancel,
                    borderRadius: BorderRadius.circular(20),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(
                        Icons.close_rounded,
                        size: 15,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// Inline Composer 작은 옵션 버튼
// ============================================================

class _TodoComposerChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool highlighted;
  final VoidCallback? onTap;

  const _TodoComposerChip({
    required this.icon,
    required this.label,
    required this.highlighted,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final content = Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 7),
      decoration: BoxDecoration(
        color: highlighted
            ? AppColors.warningBackground
            : AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: highlighted ? AppColors.warning : AppColors.border,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 11,
            color: highlighted ? AppColors.warning : AppColors.textSecondary,
          ),

          const SizedBox(width: 4),

          Text(
            label,
            style: TextStyle(
              fontSize: 8.5,
              fontWeight: FontWeight.w600,
              color: highlighted ? AppColors.warning : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );

    if (onTap == null) {
      return content;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: content,
    );
  }
}

// ============================================================
// To-do Summary
// ============================================================

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
            style: TextStyle(
              color: context.appTextPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'To-do',
            style: TextStyle(
              color: context.appBrand,
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
          style: TextStyle(
            color: context.appTextPrimary,
            fontSize: 24,
            height: 1,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          'To-do',
          style: TextStyle(
            color: context.appBrand,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

// ============================================================
// To-do Icon
// ============================================================

class _TodoIcon extends StatelessWidget {
  const _TodoIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 23,
      height: 23,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: context.appBackground,
        shape: BoxShape.circle,
        border: Border.all(color: context.appBorder),
      ),
      child: Icon(Icons.push_pin_outlined, size: 12, color: context.appBrand),
    );
  }
}

// ============================================================
// To-do Add Button
// ============================================================

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
              color: context.appBackground,
              shape: BoxShape.circle,
              border: Border.all(color: context.appBorder),
            ),
            child: Icon(Icons.add_rounded, size: 15, color: context.appBrand),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// To-do Row
// ============================================================

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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 3),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 17,
              height: 17,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: completed ? context.appBrand : Colors.transparent,
                border: Border.all(
                  color: completed
                      ? context.appBrand
                      : isHigh
                      ? AppColors.warning
                      : context.appTextSecondary,
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
                      ? context.appTextSecondary
                      : context.appTextPrimary,
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
                    ? context.appTextSecondary
                    : isHigh
                    ? AppColors.warning
                    : context.appTextSecondary,
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(width: 3),

            SizedBox(
              width: 28,
              height: 28,
              child: PopupMenuButton<String>(
                tooltip: 'To-do 메뉴',
                padding: EdgeInsets.zero,
                iconSize: 17,
                icon: Icon(
                  Icons.more_vert_rounded,
                  color: context.appTextSecondary,
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
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// To-do List
// ============================================================

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
    final visibleItems = items.take(5).toList();

    return Column(
      children: [
        for (int index = 0; index < visibleItems.length; index++) ...[
          _TodoRow(
            data: visibleItems[index],
            disabled: disabled,
            onTap: () {
              onToggle(visibleItems[index]);
            },
            onDelete: () {
              onDelete(visibleItems[index]);
            },
          ),

          if (index < visibleItems.length - 1)
            Divider(height: 1, thickness: 1, color: context.appBorder),
        ],
      ],
    );
  }
}

// ============================================================
// Format Helpers
// ============================================================

String _formatComposerDate(DateTime date) {
  final today = _nowKst();

  if (_isSameDay(date, today)) {
    return '오늘';
  }

  final month = date.month.toString().padLeft(2, '0');

  final day = date.day.toString().padLeft(2, '0');

  return '$month.$day';
}

String _formatDueAt(DateTime? date) {
  if (date == null) {
    return '-';
  }

  final now = _nowKst();

  final isToday = _isSameDay(date, now);

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

DateTime _nowKst() {
  final kst = DateTime.now().toUtc().add(const Duration(hours: 9));

  return DateTime(
    kst.year,
    kst.month,
    kst.day,
    kst.hour,
    kst.minute,
    kst.second,
  );
}

bool _isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}
