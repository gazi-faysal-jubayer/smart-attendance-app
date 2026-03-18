import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/widgets/department_dropdown.dart';
import '../../../shared/widgets/app_toast.dart';
import '../domain/course_model.dart';
import '../domain/course_notifier.dart';

class CreateCourseScreen extends ConsumerStatefulWidget {
  const CreateCourseScreen({super.key});

  @override
  ConsumerState<CreateCourseScreen> createState() =>
      _CreateCourseScreenState();
}

class _CreateCourseScreenState extends ConsumerState<CreateCourseScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _nameController = TextEditingController();
  final _countController = TextEditingController();

  String? _department;
  int _semester = 1;
  String _type = 'theory';
  bool _isLoading = false;
  bool _countOverridden = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();

    _codeController.addListener(() => setState(() {}));
    _nameController.addListener(() => setState(() {}));
    _countController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _animController.dispose();
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
        AppToast.show(context, 'Course created successfully!', isSuccess: true);
        context.go('/dashboard');
      }
    } catch (e) {
      if (mounted) {
        AppToast.show(context, 'Error: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool get _hasPreviewData =>
      _codeController.text.isNotEmpty || _nameController.text.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ─── Hero Header ────────────────────────────────
          SliverAppBar(
            expandedHeight: size.height * 0.18,
            pinned: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: () => context.pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF0F2448),
                      AppColors.primary,
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 48, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          'New Course',
                          style: Theme.of(context)
                              .textTheme
                              .headlineLarge
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Set up a new course and auto-generate students',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.7),
                                  ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ─── Form Content ───────────────────────────────
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Section: Department & Type
                      _SectionHeader(
                          title: 'Course Setup', icon: Icons.tune_rounded),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: _cardDecoration(context),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
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
                            Text('Semester',
                                style:
                                    Theme.of(context).textTheme.labelLarge),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: List.generate(8, (i) {
                                final sem = i + 1;
                                final isSelected = _semester == sem;
                                return ChoiceChip(
                                  label: Text('$sem'),
                                  selected: isSelected,
                                  selectedColor: AppColors.primary,
                                  backgroundColor:
                                      AppColors.primary.withValues(alpha: 0.06),
                                  labelStyle: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  onSelected: (_) {
                                    setState(() => _semester = sem);
                                  },
                                  side: BorderSide(
                                    color: isSelected
                                        ? AppColors.primary
                                        : AppColors.primary
                                            .withValues(alpha: 0.2),
                                  ),
                                );
                              }),
                            ),
                            const SizedBox(height: 20),
                            Text('Course Type',
                                style:
                                    Theme.of(context).textTheme.labelLarge),
                            const SizedBox(height: 10),
                            SegmentedButton<String>(
                              segments: const [
                                ButtonSegment(
                                  value: 'theory',
                                  label: Text('Theory'),
                                  icon: Icon(Icons.menu_book_rounded,
                                      size: 18),
                                ),
                                ButtonSegment(
                                  value: 'lab',
                                  label: Text('Lab'),
                                  icon: Icon(Icons.science_rounded,
                                      size: 18),
                                ),
                              ],
                              selected: {_type},
                              onSelectionChanged: (val) {
                                setState(() {
                                  _type = val.first;
                                  _updateStudentCount();
                                });
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Section: Course Info
                      _SectionHeader(
                          title: 'Course Information',
                          icon: Icons.info_outline_rounded),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: _cardDecoration(context),
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _codeController,
                              textCapitalization:
                                  TextCapitalization.characters,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: 'Course Code',
                                hintText: 'e.g. CSE 2101',
                                prefixIcon:
                                    Icon(Icons.code_rounded),
                              ),
                              validator: (v) => v == null || v.isEmpty
                                  ? 'Course code is required'
                                  : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _nameController,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: 'Course Name',
                                hintText: 'e.g. Data Structures',
                                prefixIcon:
                                    Icon(Icons.book_outlined),
                              ),
                              validator: (v) => v == null || v.isEmpty
                                  ? 'Course name is required'
                                  : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _countController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Student Count',
                                prefixIcon:
                                    const Icon(Icons.people_outline_rounded),
                                helperText:
                                    'Auto-filled from department. Tap to override.',
                                suffixIcon: _countOverridden
                                    ? IconButton(
                                        icon: const Icon(Icons.refresh_rounded),
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
                          ],
                        ),
                      ),

                      // ─── Live Preview ───────────────────
                      if (_hasPreviewData) ...[
                        const SizedBox(height: 24),
                        _SectionHeader(
                            title: 'Preview',
                            icon: Icons.preview_rounded),
                        const SizedBox(height: 12),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: _type == 'lab'
                                  ? [
                                      AppColors.labGradientStart,
                                      AppColors.labGradientEnd,
                                    ]
                                  : [
                                      AppColors.primary,
                                      AppColors.theoryGradientEnd,
                                    ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.25),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _codeController.text.isEmpty
                                    ? 'COURSE CODE'
                                    : _codeController.text.toUpperCase(),
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _nameController.text.isEmpty
                                    ? 'Course Name'
                                    : _nameController.text,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color:
                                          Colors.white.withValues(alpha: 0.8),
                                    ),
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                children: [
                                  if (_department != null)
                                    _PreviewChip(_department!),
                                  _PreviewChip('Sem $_semester'),
                                  _PreviewChip(
                                      _type == 'lab' ? 'Lab' : 'Theory'),
                                  if (_countController.text.isNotEmpty)
                                    _PreviewChip(
                                        '${_countController.text} students'),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 32),

                      // Submit
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _submit,
                          icon: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.check_rounded),
                          label: Text(_isLoading
                              ? 'Creating...'
                              : 'Create Course'),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration(BuildContext context) {
    return BoxDecoration(
      color: Theme.of(context).cardTheme.color ?? Colors.white,
      borderRadius: BorderRadius.circular(18),
      border:
          Border.all(color: AppColors.cardBorder.withValues(alpha: 0.3)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}

class _PreviewChip extends StatelessWidget {
  final String label;
  const _PreviewChip(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
