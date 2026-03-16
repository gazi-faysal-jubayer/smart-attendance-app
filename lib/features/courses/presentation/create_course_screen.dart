import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/widgets/department_dropdown.dart';
import '../domain/course_model.dart';
import '../domain/course_notifier.dart';

class CreateCourseScreen extends ConsumerStatefulWidget {
  const CreateCourseScreen({super.key});

  @override
  ConsumerState<CreateCourseScreen> createState() =>
      _CreateCourseScreenState();
}

class _CreateCourseScreenState extends ConsumerState<CreateCourseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _nameController = TextEditingController();
  final _countController = TextEditingController();

  String? _department;
  int _semester = 1;
  String _type = 'theory';
  bool _isLoading = false;
  bool _countOverridden = false;

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _countController.dispose();
    super.dispose();
  }

  void _updateStudentCount() {
    if (_countOverridden) return;
    if (_department != null) {
      final count = AppConstants.getStudentCount(_department!, _type);
      _countController.text = count.toString();
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final user = ref.read(currentUserProvider);
      if (user == null) throw Exception('Not authenticated');

      final course = CourseModel(
        id: const Uuid().v4(),
        teacherId: user.id,
        courseCode: _codeController.text.trim().toUpperCase(),
        courseName: _nameController.text.trim(),
        department: _department!,
        semester: _semester,
        type: _type,
        studentCount: int.parse(_countController.text),
        createdAt: DateTime.now(),
      );

      await ref.read(courseListProvider.notifier).createCourse(course);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Course created successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        context.go('/dashboard');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Course')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Department
              DepartmentDropdown(
                value: _department,
                onChanged: (v) {
                  setState(() {
                    _department = v;
                    _updateStudentCount();
                  });
                },
                validator: (v) =>
                    v == null ? 'Department is required' : null,
              ),
              const SizedBox(height: 20),

              // Semester
              Text('Semester',
                  style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: List.generate(8, (i) {
                  final sem = i + 1;
                  final isSelected = _semester == sem;
                  return ChoiceChip(
                    label: Text('$sem'),
                    selected: isSelected,
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : null,
                      fontWeight: FontWeight.w600,
                    ),
                    onSelected: (_) {
                      setState(() => _semester = sem);
                    },
                  );
                }),
              ),
              const SizedBox(height: 20),

              // Type toggle
              Text('Course Type',
                  style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'theory', label: Text('Theory')),
                  ButtonSegment(value: 'lab', label: Text('Lab')),
                ],
                selected: {_type},
                onSelectionChanged: (val) {
                  setState(() {
                    _type = val.first;
                    _updateStudentCount();
                  });
                },
              ),
              const SizedBox(height: 20),

              // Course Code
              TextFormField(
                controller: _codeController,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'Course Code',
                  hintText: 'e.g. CSE 2101',
                  prefixIcon: Icon(Icons.code),
                ),
                validator: (v) => v == null || v.isEmpty
                    ? 'Course code is required'
                    : null,
              ),
              const SizedBox(height: 16),

              // Course Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Course Name',
                  hintText: 'e.g. Data Structures',
                  prefixIcon: Icon(Icons.book_outlined),
                ),
                validator: (v) => v == null || v.isEmpty
                    ? 'Course name is required'
                    : null,
              ),
              const SizedBox(height: 16),

              // Student Count
              TextFormField(
                controller: _countController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Student Count',
                  prefixIcon: const Icon(Icons.people_outline),
                  helperText:
                      'Auto-determined from department. Tap to override.',
                  suffixIcon: _countOverridden
                      ? IconButton(
                          icon: const Icon(Icons.refresh),
                          onPressed: () {
                            setState(() {
                              _countOverridden = false;
                              _updateStudentCount();
                            });
                          },
                        )
                      : null,
                ),
                onChanged: (_) => _countOverridden = true,
                validator: (v) {
                  if (v == null || v.isEmpty) {
                    return 'Student count is required';
                  }
                  final n = int.tryParse(v);
                  if (n == null || n <= 0) {
                    return 'Enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Preview card
              if (_codeController.text.isNotEmpty ||
                  _nameController.text.isNotEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Preview',
                            style:
                                Theme.of(context).textTheme.labelLarge),
                        const SizedBox(height: 8),
                        Text(
                          _codeController.text.isEmpty
                              ? 'Course Code'
                              : _codeController.text.toUpperCase(),
                          style:
                              Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(
                          _nameController.text.isEmpty
                              ? 'Course Name'
                              : _nameController.text,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: [
                            if (_department != null)
                              Chip(label: Text(_department!)),
                            Chip(label: Text('Sem $_semester')),
                            Chip(
                                label: Text(_type == 'lab'
                                    ? 'Lab'
                                    : 'Theory')),
                            if (_countController.text.isNotEmpty)
                              Chip(
                                  label: Text(
                                      '${_countController.text} students')),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Create Course'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
