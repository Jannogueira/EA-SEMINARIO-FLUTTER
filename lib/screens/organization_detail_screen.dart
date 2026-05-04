import 'package:flutter/material.dart';
import '../models/organization.dart';
import '../models/task.dart';
import '../services/organization_service.dart';
import 'create_task_screen.dart';

class OrganizationDetailScreen extends StatefulWidget {
  final Organization organization;

  const OrganizationDetailScreen({super.key, required this.organization});

  @override
  State<OrganizationDetailScreen> createState() =>
      _OrganizationDetailScreenState();
}

class _OrganizationDetailScreenState extends State<OrganizationDetailScreen> {
  final OrganizationService _organizationService = OrganizationService();
  late Future<List<Task>> _tasksFuture;
  
  // Mapa para persistir estados localmente durante la sesión en esta pantalla
  final Map<String, String> _localTaskStates = {};

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  void _loadTasks() {
    setState(() {
      _tasksFuture = _organizationService.fetchTasksByOrganization(
        widget.organization.id,
      );
    });
  }

  String _formatDate(DateTime date) {
    final String day = date.day.toString().padLeft(2, '0');
    final String month = date.month.toString().padLeft(2, '0');
    final String year = date.year.toString();
    return '$day/$month/$year';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(widget.organization.name),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildOrgHeader(),
          const SizedBox(height: 20),
          Expanded(
            child: FutureBuilder<List<Task>>(
              future: _tasksFuture,
              builder: (BuildContext context, AsyncSnapshot<List<Task>> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return _buildErrorView(snapshot.error.toString());
                }

                final List<Task> allTasks = snapshot.data ?? [];
                
                // Actualizamos estados locales si hay tareas nuevas
                for (var task in allTasks) {
                  _localTaskStates.putIfAbsent(task.id, () => task.estado);
                }

                // Filtramos por estado local
                final todoTasks = allTasks.where((t) => _localTaskStates[t.id] == 'To do').toList();
                final inProgressTasks = allTasks.where((t) => _localTaskStates[t.id] == 'In progress').toList();
                final doneTasks = allTasks.where((t) => _localTaskStates[t.id] == 'Done').toList();

                return DefaultTabController(
                  length: 3,
                  child: Column(
                    children: [
                      TabBar(
                        labelColor: Colors.blueAccent,
                        unselectedLabelColor: Colors.grey,
                        indicatorColor: Colors.blueAccent,
                        tabs: [
                          Tab(text: 'To do (${todoTasks.length})'),
                          Tab(text: 'In progress (${inProgressTasks.length})'),
                          Tab(text: 'Done (${doneTasks.length})'),
                        ],
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            _buildTaskList(todoTasks),
                            _buildTaskList(inProgressTasks),
                            _buildTaskList(doneTasks),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          _buildCreateButton(context),
        ],
      ),
    );
  }

  Widget _buildOrgHeader() {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5)),
        ],
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 30,
            backgroundColor: Colors.blueAccent,
            child: Icon(Icons.business, size: 30, color: Colors.white),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.organization.name,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                Text(
                  'ID: ${widget.organization.id}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskList(List<Task> tasks) {
    if (tasks.isEmpty) {
      return const Center(child: Text('No hay tareas en este estado'));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 10),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            onTap: () => _openTaskDetail(task),
            leading: _getStatusIcon(_localTaskStates[task.id]!),
            title: Text(task.titulo, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Fin: ${_formatDate(task.fechaFin)}'),
            trailing: const Icon(Icons.chevron_right),
          ),
        );
      },
    );
  }

  void _openTaskDetail(Task task) async {
    // Diálogo rápido para cambiar el estado localmente
    final String? newState = await showDialog<String>(
      context: context,
      builder: (context) => _StatusChangeDialog(
        currentStatus: _localTaskStates[task.id]!,
        taskTitle: task.titulo,
      ),
    );

    if (newState != null && newState != _localTaskStates[task.id]) {
      setState(() {
        _localTaskStates[task.id] = newState;
      });
    }
  }

  Widget _getStatusIcon(String estado) {
    switch (estado) {
      case 'To do': return const Icon(Icons.list, color: Colors.grey);
      case 'In progress': return const Icon(Icons.sync, color: Colors.blue);
      case 'Done': return const Icon(Icons.check_circle, color: Colors.green);
      default: return const Icon(Icons.help_outline);
    }
  }

  Widget _buildErrorView(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Text('Error: $error', textAlign: TextAlign.center),
      ),
    );
  }

  Widget _buildCreateButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: ElevatedButton(
        onPressed: () async {
          final bool? created = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (context) => CreateTaskScreen(
                organizacionId: widget.organization.id,
                usuarios: widget.organization.usuarios,
              ),
            ),
          );
          if (created == true) _loadTasks();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blueAccent,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 60),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
        child: const Text('Crear tarea', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class _StatusChangeDialog extends StatefulWidget {
  final String currentStatus;
  final String taskTitle;

  const _StatusChangeDialog({required this.currentStatus, required this.taskTitle});

  @override
  State<_StatusChangeDialog> createState() => _StatusChangeDialogState();
}

class _StatusChangeDialogState extends State<_StatusChangeDialog> {
  late String _selectedStatus;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.currentStatus;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Cambiar estado: ${widget.taskTitle}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: ['To do', 'In progress', 'Done'].map((status) {
          return RadioListTile<String>(
            title: Text(status),
            value: status,
            groupValue: _selectedStatus,
            onChanged: (val) {
              if (val != null) {
                setState(() => _selectedStatus = val);
                Navigator.pop(context, val);
              }
            },
          );
        }).toList(),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
      ],
    );
  }
}
