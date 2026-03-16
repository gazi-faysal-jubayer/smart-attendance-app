-- KUET Smart Attendance System — Supabase Migration
-- Run this in Supabase SQL Editor before using the app

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Profiles table (linked to auth.users)
CREATE TABLE profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name TEXT NOT NULL,
  employee_id TEXT UNIQUE NOT NULL,
  department TEXT NOT NULL,
  role TEXT DEFAULT 'teacher',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Courses table
CREATE TABLE courses (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  teacher_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  course_code TEXT NOT NULL,
  course_name TEXT NOT NULL,
  department TEXT NOT NULL,
  semester INT NOT NULL CHECK (semester BETWEEN 1 AND 8),
  type TEXT NOT NULL CHECK (type IN ('theory','lab')),
  student_count INT NOT NULL CHECK (student_count > 0),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Students table
CREATE TABLE students (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  course_id UUID NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
  roll_number INT NOT NULL,
  student_id TEXT,
  name TEXT,
  UNIQUE(course_id, roll_number)
);

-- Attendance sessions table
CREATE TABLE attendance_sessions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  course_id UUID NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
  teacher_id UUID NOT NULL REFERENCES profiles(id),
  date DATE NOT NULL,
  class_number INT NOT NULL,
  topic TEXT,
  status TEXT DEFAULT 'draft' CHECK (status IN ('draft','submitted')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(course_id, class_number)
);

-- Attendance records table
CREATE TABLE attendance_records (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  session_id UUID NOT NULL REFERENCES attendance_sessions(id) ON DELETE CASCADE,
  student_id UUID NOT NULL REFERENCES students(id),
  roll_number INT NOT NULL,
  status TEXT NOT NULL DEFAULT 'P' CHECK (status IN ('P','A','LA','E')),
  comment TEXT,
  marked_by TEXT DEFAULT 'manual' CHECK (marked_by IN ('manual','fingerprint','face')),
  timestamp TIMESTAMPTZ DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE courses ENABLE ROW LEVEL SECURITY;
ALTER TABLE students ENABLE ROW LEVEL SECURITY;
ALTER TABLE attendance_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE attendance_records ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY teachers_own_profile ON profiles FOR ALL USING (id = auth.uid());
CREATE POLICY teachers_insert_profile ON profiles
  FOR INSERT WITH CHECK (id = auth.uid());
CREATE POLICY teachers_own_courses ON courses FOR ALL USING (teacher_id = auth.uid());
CREATE POLICY teachers_own_students ON students FOR ALL USING (
  EXISTS (SELECT 1 FROM courses WHERE courses.id = students.course_id AND courses.teacher_id = auth.uid())
);
CREATE POLICY teachers_own_sessions ON attendance_sessions FOR ALL USING (teacher_id = auth.uid());
CREATE POLICY teachers_own_records ON attendance_records FOR ALL USING (
  EXISTS (SELECT 1 FROM attendance_sessions WHERE attendance_sessions.id = attendance_records.session_id AND attendance_sessions.teacher_id = auth.uid())
);
