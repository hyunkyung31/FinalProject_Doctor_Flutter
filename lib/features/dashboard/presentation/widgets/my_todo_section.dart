import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import 'dashboard_section_card.dart';

// ============================================================
// STEP 1. MY TODO
// 의료진 개인 To-do 요약
// 내부 중첩 카드 없이 Flat Layout으로 구성
// 추후 /staff/todos API 연결
// ============================================================

class MyTodoSection extends StatefulWidget {
  const MyTodoSection({super.key});

  @override
  State<MyTodoSection> createState() => _MyTodoSectionState();
}

// ============================================================
// STEP 2. MY TODO State
// ============================================================

class _MyTodoSectionState extends State<MyTodoSection> {
  final List<_TodoData> _items = [
    const _TodoData(title: '김OO 검사 결과 확인', dueTime: '14:30', priority: 'HIGH'),
    const _TodoData(title: '이OO 보호자 연락', dueTime: '16:00', priority: 'NORMAL'),
    const _TodoData(title: '협진 의견 작성', dueTime: '오늘', priority: 'NORMAL'),
  ];

  final Set<int> _completedIndexes = {};

  @override
  Widget build(BuildContext context) {
    final textScaler = MediaQuery.textScalerOf(context);
    final textScale = textScaler.scale(16) / 16;

    final remainingCount = _items.length - _completedIndexes.length;

    return DashboardSectionCard(
      title: 'MY TODO',
      actionLabel: '전체보기',
      onAction: () {
        _showMessage(context, 'To-do 전체 화면으로 이동');
      },
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

  // ============================================================
  // STEP 3. Tablet Horizontal Layout
  // ============================================================

  Widget _buildHorizontalLayout(int remainingCount) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: _TodoSummary(count: remainingCount, onAdd: _addTodo),
          ),

          const SizedBox(width: 18),

          Expanded(
            child: _TodoList(
              items: _items,
              completedIndexes: _completedIndexes,
              onToggle: _toggleTodo,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STEP 4. Narrow / Large Text Layout
  // ============================================================

  Widget _buildVerticalLayout(int remainingCount) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TodoSummary(count: remainingCount, compact: true, onAdd: _addTodo),

          const SizedBox(height: 8),

          _TodoList(
            items: _items,
            completedIndexes: _completedIndexes,
            onToggle: _toggleTodo,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STEP 5. Todo 완료 / 완료 취소
  // 추후 PATCH /staff/todos/{id} 연결
  // ============================================================

  void _toggleTodo(int index) {
    setState(() {
      if (_completedIndexes.contains(index)) {
        _completedIndexes.remove(index);
      } else {
        _completedIndexes.add(index);
      }
    });
  }

  // ============================================================
  // STEP 6. Todo 추가
  // 추후 POST /staff/todos 연결
  // ============================================================

  Future<void> _addTodo() async {
    final newTodo = await showDialog<_TodoData>(
      context: context,
      builder: (context) {
        return const _AddTodoDialog();
      },
    );

    if (!mounted || newTodo == null) {
      return;
    }

    setState(() {
      _items.add(newTodo);
    });
  }
}

// ============================================================
// STEP 7. Todo 추가 Dialog
// Controller는 Dialog State가 직접 관리
// ============================================================

class _AddTodoDialog extends StatefulWidget {
  const _AddTodoDialog();

  @override
  State<_AddTodoDialog> createState() => _AddTodoDialogState();
}

class _AddTodoDialogState extends State<_AddTodoDialog> {
  final TextEditingController _titleController = TextEditingController();

  String _priority = 'NORMAL';
  TimeOfDay? _selectedTime;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  // ============================================================
  // STEP 7-1. 시간 선택
  // ============================================================

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );

    if (!mounted || picked == null) {
      return;
    }

    setState(() {
      _selectedTime = picked;
    });
  }

  // ============================================================
  // STEP 7-2. Todo 추가 완료
  // ============================================================

  void _submit() {
    final title = _titleController.text.trim();

    if (title.isEmpty) {
      return;
    }

    Navigator.of(
      context,
    ).pop(_TodoData(title: title, dueTime: _dueTimeText, priority: _priority));
  }

  // ============================================================
  // STEP 7-3. 시간 문자열
  // ============================================================

  String get _dueTimeText {
    if (_selectedTime == null) {
      return '오늘';
    }

    final hour = _selectedTime!.hour.toString().padLeft(2, '0');

    final minute = _selectedTime!.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      titlePadding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
      contentPadding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      actionsPadding: const EdgeInsets.fromLTRB(12, 4, 12, 12),

      title: const Text(
        'To-do 추가',
        style: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),

      // ========================================================
      // 작은 화면 / 글자 확대 시 Overflow 방지
      // ========================================================
      content: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ==================================================
              // 할 일 입력
              // ==================================================
              TextField(
                controller: _titleController,
                autofocus: true,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) {
                  _submit();
                },
                decoration: const InputDecoration(
                  labelText: '할 일',
                  hintText: '예: 김OO 검사 결과 확인',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 14),

              // ==================================================
              // 우선순위
              // ==================================================
              DropdownButtonFormField<String>(
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

              const SizedBox(height: 12),

              // ==================================================
              // 시간 선택
              // ==================================================
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _selectTime,
                  icon: const Icon(Icons.schedule_rounded, size: 17),
                  label: Text(
                    _selectedTime == null ? '시간 선택 · 오늘' : '시간 · $_dueTimeText',
                  ),
                ),
              ),
            ],
          ),
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
}

// ============================================================
// STEP 8. Todo Summary
// 아이폰 미리알림 느낌의 아이콘 + 미완료 개수
// ============================================================

class _TodoSummary extends StatelessWidget {
  final int count;
  final bool compact;
  final VoidCallback onAdd;

  const _TodoSummary({
    required this.count,
    required this.onAdd,
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

          _TodoAddButton(onTap: onAdd),
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

            _TodoAddButton(onTap: onAdd),
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

// ============================================================
// STEP 9. Todo Icon
// ============================================================

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

// ============================================================
// STEP 10. Todo Add Button
// ============================================================

class _TodoAddButton extends StatelessWidget {
  final VoidCallback onTap;

  const _TodoAddButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'To-do 추가',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
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

// ============================================================
// STEP 11. Todo List
// ============================================================

class _TodoList extends StatelessWidget {
  final List<_TodoData> items;
  final Set<int> completedIndexes;
  final ValueChanged<int> onToggle;

  const _TodoList({
    required this.items,
    required this.completedIndexes,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (int index = 0; index < items.length; index++)
          _TodoRow(
            data: items[index],
            completed: completedIndexes.contains(index),
            onTap: () {
              onToggle(index);
            },
          ),
      ],
    );
  }
}

// ============================================================
// STEP 12. Todo Row
// ============================================================

class _TodoRow extends StatelessWidget {
  final _TodoData data;
  final bool completed;
  final VoidCallback onTap;

  const _TodoRow({
    required this.data,
    required this.completed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isHigh = data.priority == 'HIGH';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.small),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
        child: Row(
          children: [
            // ==================================================
            // 원형 완료 체크
            // ==================================================
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

            // ==================================================
            // 제목
            // ==================================================
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

            const SizedBox(width: 12),

            // ==================================================
            // 마감 시간
            // ==================================================
            Text(
              data.dueTime,
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
          ],
        ),
      ),
    );
  }
}

// ============================================================
// STEP 13. Todo Data
// 추후 API Model로 교체
// ============================================================

class _TodoData {
  final String title;
  final String dueTime;
  final String priority;

  const _TodoData({
    required this.title,
    required this.dueTime,
    required this.priority,
  });
}

// ============================================================
// STEP 14. Temporary Message
// ============================================================

void _showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(milliseconds: 900),
      ),
    );
}
