-- =====================================================================
-- TDA357 / DIT621 -- Database Programming Assignment (Lab PM), LP3 2019
-- Task 1: Constructing the database -- table definitions
-- Author: Abel Haile Magicho
--
-- Implements the (reconstructed) abstract schema for Task 1 in
-- PostgreSQL.  Exactly the given table and attribute names are used,
-- with the same primary key and foreign key constraints, sensible
-- types, basic CHECKs against invalid data, and no nullable columns.
--
-- Note: CHAR(10) is used for the student identification number
-- (exactly 10 digits) and CHAR(6) for the six-character course codes.
-- =====================================================================

-- Departments of the university.  Both the name and the abbreviation
-- of a department are unique.
CREATE TABLE Departments (
    name VARCHAR(64) NOT NULL,
    abbr VARCHAR(16) NOT NULL,
    PRIMARY KEY (name),
    UNIQUE (abbr)
);

-- Study programmes.  Programme names are unique, abbreviations are
-- not necessarily unique.  'host' is the (main) hosting department.
-- NOTE: the domain also allows several departments to *collaborate*
-- on a programme; the single host attribute of this Task 1 schema
-- cannot express that.  This known incompleteness of the given
-- schema is fixed in Task 2 (relation HostedBy).
CREATE TABLE Programs (
    name VARCHAR(64) NOT NULL,
    abbr VARCHAR(16) NOT NULL,
    host VARCHAR(64) NOT NULL REFERENCES Departments(name),
    PRIMARY KEY (name)
);

-- Branches belong to a programme.  A branch name is unique within
-- its programme but not across programmes, hence the composite key.
-- (In E-R terms of Task 2, Branch is a weak entity of Program.)
CREATE TABLE Branches (
    name    VARCHAR(64) NOT NULL,
    program VARCHAR(64) NOT NULL REFERENCES Programs(name),
    PRIMARY KEY (name, program)
);

-- Students.  Every student belongs to exactly one programme.
-- The login is unique, and the id number consists of 10 digits.
-- UNIQUE (idnr, program) is needed so that StudentBranches can
-- reference the pair (student, programme) with a foreign key, which
-- is what guarantees that a student can only choose a branch that
-- belongs to his/her own programme.
CREATE TABLE Students (
    idnr    CHAR(10)    NOT NULL,
    name    VARCHAR(64) NOT NULL,
    login   VARCHAR(32) NOT NULL,
    program VARCHAR(64) NOT NULL REFERENCES Programs(name),
    PRIMARY KEY (idnr),
    UNIQUE (login),
    UNIQUE (idnr, program),
    CHECK (idnr ~ '^[0-9]{10}$')
);

-- The branch (if any) chosen by a student.  A student chooses at
-- most one branch, hence student alone is the key.  The composite
-- foreign key (student, program) -> Students(idnr, program),
-- together with (branch, program) -> Branches(name, program),
-- makes it impossible to store a branch from another programme.
CREATE TABLE StudentBranches (
    student CHAR(10)    NOT NULL,
    branch  VARCHAR(64) NOT NULL,
    program VARCHAR(64) NOT NULL,
    PRIMARY KEY (student),
    FOREIGN KEY (student, program) REFERENCES Students(idnr, program),
    FOREIGN KEY (branch, program)  REFERENCES Branches(name, program)
);

-- Courses.  The course code is a unique six-character string.
-- Every course is given by a department and gives a fixed number
-- of credits (the same for all students reading the course).
CREATE TABLE Courses (
    code    CHAR(6)       NOT NULL,
    name    VARCHAR(64)   NOT NULL,
    credits NUMERIC(4, 1) NOT NULL,
    givenBy VARCHAR(64)   NOT NULL REFERENCES Departments(name),
    PRIMARY KEY (code),
    CHECK (credits > 0)
);

-- Courses with a restriction on the number of students that may
-- take the course at the same time (subclass of Courses).
CREATE TABLE LimitedCourses (
    code  CHAR(6) NOT NULL REFERENCES Courses(code),
    seats INTEGER NOT NULL,
    PRIMARY KEY (code),
    CHECK (seats > 0)
);

-- The classifications a course may have (mathematical, research,
-- seminar, ...).  New classifications can be introduced by simply
-- inserting new rows here.
CREATE TABLE Classifications (
    name VARCHAR(32) NOT NULL,
    PRIMARY KEY (name)
);

-- Which courses have which classifications.  A course need not be
-- classified at all, and may have several classifications.
CREATE TABLE ClassifiedAs (
    course         CHAR(6)     NOT NULL REFERENCES Courses(code),
    classification VARCHAR(32) NOT NULL REFERENCES Classifications(name),
    PRIMARY KEY (course, classification)
);

-- Prerequisites: 'prereq' must be passed before a student may
-- register for 'course'.  A course cannot be its own prerequisite.
CREATE TABLE Prerequisites (
    course CHAR(6) NOT NULL REFERENCES Courses(code),
    prereq CHAR(6) NOT NULL REFERENCES Courses(code),
    PRIMARY KEY (course, prereq),
    CHECK (course <> prereq)
);

-- Courses that are mandatory for a whole programme.
CREATE TABLE MandatoryProgram (
    course  CHAR(6)     NOT NULL REFERENCES Courses(code),
    program VARCHAR(64) NOT NULL REFERENCES Programs(name),
    PRIMARY KEY (course, program)
);

-- Courses that are mandatory for a branch of a programme.
CREATE TABLE MandatoryBranch (
    course  CHAR(6)     NOT NULL REFERENCES Courses(code),
    branch  VARCHAR(64) NOT NULL,
    program VARCHAR(64) NOT NULL,
    PRIMARY KEY (course, branch, program),
    FOREIGN KEY (branch, program) REFERENCES Branches(name, program)
);

-- Courses recommended for a branch: students of the branch must
-- pass at least 10 credits worth of these to graduate.
CREATE TABLE RecommendedBranch (
    course  CHAR(6)     NOT NULL REFERENCES Courses(code),
    branch  VARCHAR(64) NOT NULL,
    program VARCHAR(64) NOT NULL,
    PRIMARY KEY (course, branch, program),
    FOREIGN KEY (branch, program) REFERENCES Branches(name, program)
);

-- Courses a student has finished, with the grade obtained
-- ('U' = not passed, '3', '4', '5' = passed with increasing merit).
CREATE TABLE TakenCourse (
    student CHAR(10) NOT NULL REFERENCES Students(idnr),
    course  CHAR(6)  NOT NULL REFERENCES Courses(code),
    grade   CHAR(1)  NOT NULL,
    PRIMARY KEY (student, course),
    CHECK (grade IN ('U', '3', '4', '5'))
);

-- Students currently registered for a course.
CREATE TABLE Registered (
    student CHAR(10) NOT NULL REFERENCES Students(idnr),
    course  CHAR(6)  NOT NULL REFERENCES Courses(code),
    PRIMARY KEY (student, course)
);

-- Students on the waiting list for a (full) course.
-- 'position' is stored as an absolute, ever-increasing number per
-- course (new entries get MAX(position)+1 within the course): the
-- smallest position has waited the longest.  Absolute positions are
-- used (rather than timestamps, whose resolution could tie, or
-- dense 1..n positions, which would need renumbering on every
-- change); the dense place in the queue (1, 2, 3, ...) is computed
-- by the CourseQueuePositions view in Task 3, so gaps left by
-- removed entries are harmless.
CREATE TABLE WaitingList (
    student  CHAR(10) NOT NULL REFERENCES Students(idnr),
    course   CHAR(6)  NOT NULL REFERENCES Courses(code),
    position INTEGER  NOT NULL,
    PRIMARY KEY (student, course),
    CHECK (position > 0)
);
