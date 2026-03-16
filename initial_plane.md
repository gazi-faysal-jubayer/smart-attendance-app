# Plan: KUET Smart Attendance System — Full Flutter App

## TL;DR
Build "KUET Smart Attendance System" — a Flutter 3.22+ app with Supabase backend, offline-first architecture using Drift (SQLite), Riverpod state management, and GoRouter navigation. Feature-first clean architecture. Android-only target. Incremental 8-phase build, each phase independently testable.

**Supabase URL:** `https://dhlycmaykcvwhihyyulm.supabase.co`
**Target:** Android only
**Flutter:** Already installed

---

## Phase 1: Project Scaffolding & Core Infrastructure
> Goal: Runnable app with empty shell, all dependencies, database ready.

### Steps

1. **Create Flutter project** in the workspace root
   - `flutter create --org com.kuet --project-name smart_attendance .` (inside `smart-attendance-app/`)
   - Remove default counter app boilerplate

2. **Configure pubspec.yaml** with all dependencies from spec:
   - supabase_flutter, drift, sqlite3_flutter_libs, riverpod, flutter_riverpod, go_router, google_fonts, fl_chart, excel, connectivity_plus, mqtt_client, path_provider, share_plus, open_filex, flutter_secure_storage, flutter_dotenv, csv, file_picker, intl, uuid, another_flushbar
   - Dev: drift_dev, build_runner, riverpod_generator, flutter_lints

3. **Create directory structure** — full feature-first layout:
   ```
   lib/
   ├── main.dart
   ├── app.dart
   ├── core/
   │   ├── constants/ (app_constants.dart, supabase_tables.dart)
   │   ├── theme/ (app_theme.dart, app_colors.dart, app_text_styles.dart)
   │   ├── errors/ (app_exception.dart, failure.dart)
   │   ├── network/ (connectivity_service.dart, sync_queue_service.dart)
   │   └── utils/ (date_utils.dart, roll_generator.dart, excel_generator.dart)
   ├── features/
   │   ├── auth/ (data/ domain/ presentation/)
   │   ├── courses/ (data/ domain/ presentation/)
   │   ├── attendance/ (data/ domain/ presentation/)
   │   ├── reports/ (data/ domain/ presentation/)
   │   └── hardware/ (data/ domain/ presentation/)
   └── shared/
       ├── widgets/
       ├── models/
       └── providers/
   ```

4. **Create `.env` file** (gitignored) with credentials:
   - SUPABASE_URL, SUPABASE_ANON_KEY, MQTT defaults, CONFIDENCE_THRESHOLD
   - Add `.env` to `.gitignore`

5. **Implement core/constants/**:
   - `app_constants.dart`: DEPT_STUDENT_COUNTS map, STATUS_LABELS, env-loaded values
   - `supabase_tables.dart`: all table/column name constants

6. **Implement core/theme/**:
   - `app_colors.dart`: KUET Navy (#1A3A6B), Gold (#C8960C), surface, error, success, warning + per-status colors
   - `app_text_styles.dart`: Poppins headings, Inter body styles
   - `app_theme.dart`: Light + dark ThemeData using Material Design 3, ColorScheme, InputDecorationTheme, CardTheme with spec'd border radius/elevation

7. **Implement core/errors/**:
   - `app_exception.dart`: Sealed class hierarchy (NetworkException, AuthException, SyncException, ValidationException)
   - `failure.dart`: `Result<T>` type = `Success<T>` | `Failure` with AppException

8. **Implement Drift database** (`lib/core/database/`):
   - `app_database.dart`: Define all 5 tables (CoursesTable, StudentsTable, AttendanceSessionsTable, AttendanceRecordsTable, PendingSyncTable) per drift_local_schema spec
   - Run `dart run build_runner build` to generate `.g.dart` files
   - DAOs created as empty stubs initially

9. **Implement shared/providers/**:
   - `supabase_provider.dart`, `drift_db_provider.dart`, `connectivity_provider.dart` — basic Riverpod providers
   - `auth_provider.dart`, `sync_provider.dart` — stubs

10. **Implement main.dart**:
    - Load .env via flutter_dotenv
    - Initialize Supabase
    - Initialize Drift AppDatabase
    - Wrap with ProviderScope + MaterialApp.router

11. **Implement app.dart**:
    - MaterialApp.router with theme, darkTheme, GoRouter instance (stub routes initially)

**Verification (Phase 1):**
- `flutter pub get` succeeds
- `dart run build_runner build` generates Drift code without errors
- App launches to blank screen on Android emulator
- Supabase initializes without error (check debug console)

---

## Phase 2: Authentication
> Goal: Full auth flow — login, register, forgot password, session persistence, route guards.
> *Depends on Phase 1*

### Steps

12. **Run Supabase SQL migrations** — execute all CREATE TABLE + RLS policies from spec in Supabase SQL editor

13. **Implement auth domain layer**:
    - `auth_repository.dart`: Abstract class with signIn, signUp, signOut, getCurrentUser, watchAuthState
    - `shared/models/app_user.dart`: id, email, fullName, employeeId, department, role

14. **Implement auth data layer**:
    - `auth_repository_impl.dart`: Uses supabase.auth for signIn/signUp/signOut. On register: inserts into profiles table.

15. **Implement auth notifier**:
    - `auth_notifier.dart`: AsyncNotifier<AppUser?> watching supabase.auth.onAuthStateChange
    - Wire up `authNotifierProvider` and `currentUserProvider`

16. **Implement GoRouter with auth guard**:
    - Define all routes from navigation spec
    - Redirect: unauthenticated users to /login (except /register, /forgot-password)
    - Redirect: authenticated users away from /login to /dashboard

17. **Implement Splash Screen**:
    - Full navy background, KUET logo placeholder, app name, 2s delay
    - Check session → navigate to dashboard or login

18. **Implement Login Screen**:
    - Curved navy header with logo, white card form
    - Email + password fields with validation
    - Loading state on button, SnackBar errors

19. **Implement Register Screen**:
    - Full Name, Employee ID, Department dropdown, Email, Password, Confirm Password
    - Department options from spec
    - On submit: signUp → insert profile → navigate to dashboard

20. **Implement Forgot Password Screen**:
    - Email field → supabase.auth.resetPasswordForEmail()

21. **Implement shared/widgets/department_dropdown.dart**:
    - Reusable DropdownButtonFormField with KUET departments

**Verification (Phase 2):**
- Register a new user → profile appears in Supabase profiles table
- Login with that user → lands on dashboard (empty)
- Logout → redirected to login
- Kill app → reopen → auto-logged in (session persistence)
- Wrong password shows error SnackBar
- Forgot password sends reset email

---

## Phase 3: Course Management + Auto-Student Generation
> Goal: Create courses, auto-generate students, view course list and details.
> *Depends on Phase 2*

### Steps

22. **Implement course domain**:
    - `course_model.dart`: id, teacherId, courseCode, courseName, department, semester, type, studentCount, createdAt
    - `course_repository.dart`: Abstract — watchCourses(), createCourse(dto), deleteCourse(id), getCourseById(id)

23. **Implement course data layer**:
    - `local/course_dao.dart`: Drift DAO — watchAllCourses(), insertCourse(), deleteCourse()
    - `remote/course_remote_ds.dart`: Supabase CRUD for courses table
    - `course_repository_impl.dart`: Writes to Drift first, queues sync, triggers student generation

24. **Implement roll_generator utility**:
    - `core/utils/roll_generator.dart`: generateStudents(courseId, count) using DEPT_STUDENT_COUNTS map
    - Generate UUIDs for each student, roll numbers 1..N

25. **Implement course notifier**:
    - `course_notifier.dart`: AsyncNotifier<List<Course>> watching Drift stream, triggering remote sync on mount

26. **Implement Dashboard Screen**:
    - AppBar with greeting ("Good morning, {name}") + SyncStatusChip placeholder
    - Horizontal scroll of CourseCard widgets
    - Recent sessions ListView (stub — populated in Phase 4)
    - FAB → navigate to create course
    - Empty state widget when no courses

27. **Implement shared/widgets/empty_state_widget.dart**:
    - Illustration + message + optional CTA button

28. **Implement Create Course Screen**:
    - Form with: Department dropdown, Semester ChoiceChips (1-8), Type SegmentedButton (Theory/Lab), Course Code, Course Name, Student Count (auto-filled, overridable)
    - Live preview card at bottom
    - On submit: createCourse → generateStudents → navigate back with SnackBar

29. **Implement Course Detail Screen**:
    - NestedScrollView with SliverAppBar (course info, gradient header)
    - TabBar: Sessions | Students | Reports
    - Tab Students: ListView of StudentTile (roll number, optional name/ID), edit icon per student
    - CSV import action (AppBar action → FilePicker → parse → bulk update)
    - Sessions and Reports tabs — stubs populated in Phases 4 & 6

30. **Implement CourseCard widget** (used in dashboard):
    - 200x140dp, gradient background, course code, name, dept badge, type chip, student count

**Verification (Phase 3):**
- Create a CSE Theory course → 120 students auto-generated (check Drift DB + Supabase students table)
- Create a BME Lab course → 30 students
- Course appears in dashboard grid
- Tap course → detail screen shows 3 tabs
- Students tab lists all generated students with roll numbers
- Delete course → removed from list

---

## Phase 4: Attendance System (Core Feature)
> Goal: Take attendance, view history, view session details. The primary workflow.
> *Depends on Phase 3*

### Steps

31. **Implement attendance domain**:
    - `attendance_session_model.dart`: id, courseId, teacherId, date, classNumber, topic, status, synced, createdAt
    - `attendance_record_model.dart`: id, sessionId, studentId, rollNumber, status(P/A/LA/E), comment, markedBy, timestamp
    - `attendance_repository.dart`: Abstract — createSession, saveRecords, submitSession, watchSessions, watchRecords, getPendingSync

32. **Implement attendance data layer**:
    - `local/attendance_dao.dart`: Drift DAO — all CRUD + watch streams + getPendingSessions
    - `remote/attendance_remote_ds.dart`: Supabase upsert for sessions and records
    - `attendance_repository_impl.dart`: Local-first writes, queue sync

33. **Implement attendance notifier**:
    - `attendance_notifier.dart`: StateNotifier<Map<int, AttendanceRecordDraft>>
    - Methods: markStatus(roll, status), addComment(roll, comment), markAllPresent(), markAllAbsent(), resetAll(), submit()
    - Auto-increment classNumber from last session

34. **Implement shared/widgets/roll_card.dart** (critical widget):
    - Card: Row[RollBadge (44x44 circle), StudentInfo column, Spacer, StatusToggle (P/A/LA/E buttons)]
    - Status button colors: P=#2E7D32, A=#D32F2F, LA=#F9A825, E=#1565C0
    - AnimatedContainer for background color change (200ms, easeInOut)
    - Card backgrounds: P=white, A=#FFEBEE, LA=#FFFDE7, E=#E3F2FD
    - Long press → bottom sheet with comment TextField
    - Deselect same status → revert to P

35. **Implement shared/widgets/status_badge.dart**:
    - Colored chip for P/A/LA/E with short labels

36. **Implement Take Attendance Screen**:
    - Custom AppBar: course code + date, hardware toggle icon, bulk action menu (Mark All P / A / Reset)
    - SessionInfoBar: Date chip, Class #{N} chip (auto-incremented), editable Topic chip
    - ListView.builder of RollCard widgets (BouncingScrollPhysics)
    - BottomActionBar: absent/present/late count chips + Submit button
    - Submit → confirmation dialog → save → navigate back

37. **Implement Session History Screen** (embedded in CourseDetail Sessions tab):
    - ListView of past sessions: date, class number, sync badge, present/absent count
    - FAB to take new attendance

38. **Implement Session Detail Screen**:
    - AppBar: date + class number
    - FilterChipRow: All | P | A | LA | E
    - Header stats: 4 StatCard widgets (total, present, absent, late with %)
    - Filtered ListView of read-only RollCards
    - AppBar share action (stub for Phase 6)

39. **Wire up CourseDetail Sessions tab** with sessionHistoryProvider

**Verification (Phase 4):**
- Navigate to course → Sessions tab → FAB → Take Attendance screen loads with all students
- Class number auto-increments from last session
- Tap P/A/LA/E on roll cards → background animates
- Mark All Present → all cards green
- Long press → comment sheet works
- Bottom bar shows live counts
- Submit → confirmation → returns to sessions list
- Session appears in history with correct counts
- Tap session → detail view with filter chips working
- Take 3 sessions → class numbers are 1, 2, 3

---

## Phase 5: Offline Sync Engine
> Goal: Full offline-first capability. All writes work offline, sync when online.
> *Depends on Phase 4* (but connectivity_service stub from Phase 1)

### Steps

40. **Implement core/network/connectivity_service.dart**:
    - Wraps connectivity_plus
    - Exposes `Stream<bool> isOnline` and `Future<bool> checkConnectivity()`

41. **Implement core/network/sync_queue_service.dart**:
    - Reads PendingSyncTable rows ordered by createdAt ASC
    - Batch size: 50
    - For each: call appropriate Supabase upsert/delete
    - On success: delete from PendingSyncTable + set isSynced=true on parent
    - On failure: increment retryCount, skip if > 5
    - Exponential backoff: 2^retryCount seconds

42. **Update all repositories** (course, attendance) to:
    - Insert PendingSyncTable row on every local write
    - Set isSynced=false on create/update

43. **Implement shared/widgets/sync_status_chip.dart**:
    - Green: "All synced ✓"
    - Amber: "{N} unsynced"
    - Red: "Offline"
    - Blue + spinner: "Syncing..."
    - Tap → manual sync trigger

44. **Wire syncStatusProvider**:
    - StreamProvider derived from PendingSyncTable count + connectivity state
    - Add SyncStatusChip to Dashboard AppBar

45. **Trigger sync on connectivity change**:
    - ConnectivityService emits online → SyncQueueService.processPendingQueue()

**Verification (Phase 5):**
- Turn off network → create course → take attendance → all works locally
- Turn on network → sync chip changes to "Syncing..." → then "All synced ✓"
- Check Supabase → data appears
- Kill app offline → reopen online → pending items sync
- Retry logic: corrupt a sync item → retryCount increments, stops at 5

---

## Phase 6: Reports & Excel Export
> Goal: View attendance summaries, charts, export to Excel.
> *Depends on Phase 4*. *Parallel with Phase 5*.

### Steps

46. **Implement report domain**:
    - `report_model.dart`: StudentAttendanceSummary (rollNumber, studentId, name, totalClasses, attended, late, absent, percentage)
    - `report_repository.dart`: Abstract — generateSummary(courseId, dateRange?), exportToExcel(courseId)

47. **Implement report data layer**:
    - `report_repository_impl.dart`: Aggregates attendance records from Drift, computes per-student totals

48. **Implement core/utils/excel_generator.dart**:
    - Sheet 1 "Attendance Summary": headers (bold, navy fill), per-student rows with colored status cells, alternating row colors, conditional % formatting
    - Sheet 2 "Session Log": per-session summary
    - File naming: KUET_{courseCode}_{semester}Sem_{date}.xlsx

49. **Implement Report Screen**:
    - fl_chart PieChart (Present/Absent/Late sections, center %)
    - DateRangeFilter
    - DataTable: sortable columns, row coloring by % (red <60, amber 60-75, green >75)
    - Export FAB

50. **Implement export_options_sheet.dart**:
    - Bottom sheet: Download to device | Share via apps | date range picker

51. **Wire CourseDetail Reports tab** with reportProvider

52. **Wire Session Detail export action** (per-session Excel export)

**Verification (Phase 6):**
- Take 3+ attendance sessions → Reports tab shows accurate pie chart
- DataTable shows correct per-student percentages
- Sort by different columns works
- Export → Excel file generated → opens/shares correctly
- Sheet 1 has colored status cells, Sheet 2 has session log
- Date range filter changes the data

---

## Phase 7: Hardware Integration (Scaffold)
> Goal: MQTT scaffold, settings screen, connection test. No actual ESP32 needed.
> *Parallel with Phase 5 & 6*

### Steps

53. **Implement hardware domain**:
    - `mqtt_payload_model.dart`: deviceId, courseId, rollNumber, method, confidence, timestamp
    - `hardware_repository.dart`: Abstract — connect, listenForAttendance, disconnect, testConnection

54. **Implement hardware data layer**:
    - `mqtt_service.dart`: Wraps mqtt_client — connect, subscribe, publishMessage, disconnect, messageStream
    - `hardware_repository_impl.dart`: Parse MQTT payload → call attendanceNotifier.markStatus()

55. **Implement Hardware Settings Screen**:
    - MQTT Broker URL, Port, Topic Pattern, Client ID (read-only UUID)
    - Test Connection button with spinner + result
    - Connection status indicator
    - Info banner about ESP32 firmware

56. **Implement hardware_mode_banner.dart**:
    - Widget for take_attendance_screen when hardware mode is active
    - Shows device name + connection quality

57. **Wire hardwareConnectionProvider** (StateNotifier with sealed states)

**Verification (Phase 7):**
- Settings screen renders with all fields
- Test connection to broker.emqx.io succeeds (shows latency)
- Toggle hardware mode on take_attendance_screen shows banner
- Invalid broker URL → connection error state

---

## Phase 8: Polish, Error Handling & Testing
> Goal: Production-ready quality. All error paths handled. Tests pass.
> *Depends on all previous phases*

### Steps

58. **Implement global error handling**:
    - Repository layer: catch SocketException, PostgrestException, AuthException → return typed failures
    - Map Supabase error codes to user-friendly messages
    - Global ProviderScope error boundary

59. **Implement shared/widgets/loading_overlay.dart**:
    - Semi-transparent overlay with spinner + message

60. **Add date_utils.dart**: formatDate(), getAcademicWeek(), isSameDay()

61. **Write unit tests**:
    - roll_generator_test.dart: verify count per dept/type
    - sync_queue_service_test.dart: ordering, retry logic
    - excel_generator_test.dart: valid XLSX output
    - attendance_notifier_test.dart: markStatus, markAllPresent, submit

62. **Write widget tests**:
    - roll_card_test.dart: tap statuses, background colors, long press comment
    - sync_status_chip_test.dart: render all states

63. **Write integration tests**:
    - create_course_flow_test.dart: form fill → students generated
    - offline_attendance_test.dart: offline take → online sync

64. **Final polish**: edge cases, loading states, empty states, keyboard handling

---

## Relevant Files (key files to create)

- `lib/main.dart` — Entry point: init Supabase, Drift, dotenv, ProviderScope
- `lib/app.dart` — MaterialApp.router with theme + GoRouter
- `lib/core/constants/app_constants.dart` — DEPT_STUDENT_COUNTS, labels, env vars
- `lib/core/constants/supabase_tables.dart` — table/column name constants
- `lib/core/theme/app_theme.dart` — MD3 ThemeData (light+dark)
- `lib/core/theme/app_colors.dart` — KUET brand palette
- `lib/core/theme/app_text_styles.dart` — Poppins + Inter named styles
- `lib/core/errors/app_exception.dart` — Sealed exception hierarchy
- `lib/core/errors/failure.dart` — Result<T> type
- `lib/core/database/app_database.dart` — Drift DB with 5 tables
- `lib/core/network/connectivity_service.dart` — Online/offline stream
- `lib/core/network/sync_queue_service.dart` — Batch sync engine
- `lib/core/utils/roll_generator.dart` — Student auto-generation
- `lib/core/utils/excel_generator.dart` — Excel file builder
- `lib/core/utils/date_utils.dart` — Date formatting helpers
- `lib/features/auth/data/auth_repository_impl.dart` — Supabase auth
- `lib/features/auth/domain/auth_repository.dart` — Abstract auth
- `lib/features/auth/domain/auth_notifier.dart` — AsyncNotifier<AppUser?>
- `lib/features/auth/presentation/login_screen.dart`
- `lib/features/auth/presentation/register_screen.dart`
- `lib/features/auth/presentation/forgot_password_screen.dart`
- `lib/features/courses/data/course_repository_impl.dart`
- `lib/features/courses/data/local/course_dao.dart`
- `lib/features/courses/data/remote/course_remote_ds.dart`
- `lib/features/courses/domain/course_model.dart`
- `lib/features/courses/domain/course_repository.dart`
- `lib/features/courses/domain/course_notifier.dart`
- `lib/features/courses/presentation/course_list_screen.dart`
- `lib/features/courses/presentation/create_course_screen.dart`
- `lib/features/courses/presentation/course_detail_screen.dart`
- `lib/features/attendance/data/attendance_repository_impl.dart`
- `lib/features/attendance/data/local/attendance_dao.dart`
- `lib/features/attendance/data/remote/attendance_remote_ds.dart`
- `lib/features/attendance/domain/attendance_session_model.dart`
- `lib/features/attendance/domain/attendance_record_model.dart`
- `lib/features/attendance/domain/attendance_repository.dart`
- `lib/features/attendance/domain/attendance_notifier.dart`
- `lib/features/attendance/presentation/take_attendance_screen.dart`
- `lib/features/attendance/presentation/session_history_screen.dart`
- `lib/features/attendance/presentation/session_detail_screen.dart`
- `lib/features/reports/data/report_repository_impl.dart`
- `lib/features/reports/domain/report_model.dart`
- `lib/features/reports/domain/report_repository.dart`
- `lib/features/reports/presentation/report_screen.dart`
- `lib/features/reports/presentation/export_options_sheet.dart`
- `lib/features/hardware/data/mqtt_service.dart`
- `lib/features/hardware/data/hardware_repository_impl.dart`
- `lib/features/hardware/domain/mqtt_payload_model.dart`
- `lib/features/hardware/domain/hardware_repository.dart`
- `lib/features/hardware/presentation/hardware_settings_screen.dart`
- `lib/features/hardware/presentation/hardware_mode_banner.dart`
- `lib/shared/widgets/roll_card.dart`
- `lib/shared/widgets/sync_status_chip.dart`
- `lib/shared/widgets/empty_state_widget.dart`
- `lib/shared/widgets/loading_overlay.dart`
- `lib/shared/widgets/department_dropdown.dart`
- `lib/shared/widgets/status_badge.dart`
- `lib/shared/models/app_user.dart`
- `lib/shared/models/sync_item.dart`
- `lib/shared/providers/supabase_provider.dart`
- `lib/shared/providers/drift_db_provider.dart`
- `lib/shared/providers/auth_provider.dart`
- `lib/shared/providers/connectivity_provider.dart`
- `lib/shared/providers/sync_provider.dart`
- `.env` — Supabase URL, anon key, MQTT defaults
- `assets/` — KUET logo placeholder

## Verification (Overall)

1. **Phase 1**: `flutter pub get` + `build_runner build` + app launches
2. **Phase 2**: Register → Login → Session persistence → Logout → Route guard
3. **Phase 3**: Create course → students generated → course detail with tabs
4. **Phase 4**: Take attendance → RollCard interactions → submit → history → detail view
5. **Phase 5**: Offline create/attend → online sync → SyncStatusChip updates
6. **Phase 6**: Reports with pie chart + DataTable → Excel export + share
7. **Phase 7**: Hardware settings → MQTT test connection → hardware mode banner
8. **Phase 8**: All unit/widget/integration tests pass, error handling complete

## Decisions

- **Android only** — no iOS/web platform config needed
- **Incremental milestones** — each phase is independently testable
- **Supabase credentials provided** — will go in .env file (gitignored)
- **Phase 5 and 6 can run in parallel** since reports depend on Phase 4 (attendance data) and sync depends on Phase 4 (repositories exist)
- **Phase 7 is independent** of 5/6, only needs Phase 4's attendance notifier for markStatus
- **Hardware is scaffold only** in v1 — no actual ESP32 firmware
- **No riverpod_generator code-gen** — despite being in dev deps, the spec uses manual AsyncNotifier/StateNotifier patterns. Will use @riverpod annotations only where needed for simple providers.
- **Drift code generation** — requires `build_runner build` after defining tables

## Further Considerations

1. **KUET Logo Asset**: The spec references a KUET logo. Use a placeholder icon initially (e.g., school icon from Material Icons) — replace with actual asset when available.
2. **Supabase SQL Migrations**: Must be run manually in Supabase SQL editor before Phase 2 auth testing. Consider providing a single migration.sql file in the repo.
3. **Dark Theme**: Spec mentions light + dark ThemeData. Implement light theme first, dark theme can follow as polish in Phase 8.
