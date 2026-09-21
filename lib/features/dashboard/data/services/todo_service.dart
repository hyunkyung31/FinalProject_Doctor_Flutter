import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/staff_todo.dart';

class TodoService {
  final ApiClient apiClient;

  TodoService({required this.apiClient});

  Future<List<StaffTodo>> fetchTodos({String? status, String? priority}) async {
    final response = await apiClient.dio.get(
      ApiEndpoints.todos,
      queryParameters: {'status': ?status, 'priority': ?priority},
    );

    final data = response.data;

    List<dynamic> items;

    if (data is List) {
      items = data;
    } else if (data is Map && data['results'] is List) {
      items = data['results'] as List;
    } else {
      throw const FormatException('To-do 목록 응답 형식이 올바르지 않습니다.');
    }

    final todos = items
        .whereType<Map>()
        .map((item) => StaffTodo.fromJson(Map<String, dynamic>.from(item)))
        .toList();

    todos.sort(_compareTodo);

    return todos;
  }

  Future<void> createTodo({
    required String title,
    required String priority,
    required DateTime dueAt,
    required String description,
  }) async {
    await apiClient.dio.post(
      ApiEndpoints.todos,
      data: {
        'title': title,
        'priority': priority,
        'due_at': _toServerDateTime(dueAt),
        'description': description,
      },
    );
  }

  Future<void> updateStatus({
    required int todoId,
    required String status,
  }) async {
    await apiClient.dio.patch(
      '${ApiEndpoints.todos}$todoId/',
      data: {'status': status},
    );
  }

  Future<void> deleteTodo(int todoId) async {
    await apiClient.dio.delete('${ApiEndpoints.todos}$todoId/');
  }

  int _compareTodo(StaffTodo a, StaffTodo b) {
    if (a.isCompleted != b.isCompleted) {
      return a.isCompleted ? 1 : -1;
    }

    if (a.isHighPriority != b.isHighPriority) {
      return a.isHighPriority ? -1 : 1;
    }

    final aDue = a.dueAt;
    final bDue = b.dueAt;

    if (aDue == null && bDue == null) {
      return 0;
    }

    if (aDue == null) {
      return 1;
    }

    if (bDue == null) {
      return -1;
    }

    return aDue.compareTo(bDue);
  }

  String _toServerDateTime(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    final second = date.second.toString().padLeft(2, '0');

    return '$year-$month-${day}T'
        '$hour:$minute:$second+09:00';
  }
}
