-- =====================================================================
-- TDA357 / DIT621 -- Database Programming Assignment (Lab PM), LP3 2019
-- Task 2: Database design -- SQL for the FINAL schema
-- Author: Abel Haile Magicho
--
-- Implements final-schema.txt.  Changes relative to Task 1:
--   * Programs no longer has a 'host' attribute; hosting is the
--     many-to-many relation HostedBy (several departments may
--     collaborate on a programme).
--   * New relations HostedBy, BranchRequirements, Employees and
--     AdminOverrides.
--   * New UNIQUE constraints found by the FD analysis:
--     Departments(abbr), Students(login), WaitingList(course,
--     position), and the technical Students(idnr, program) that
--     enables the composite reference from StudentBranches.
-- No column accepts NULL values.
-- =====================================================================

CREATE TABLE Departments (
    name VARCHAR(64) NOT NULL,
    abbr VARCHAR(16) NOT NULL,
    PRIMARY KEY (name),
    UNIQUE (abbr)
);

CREATE TABLE Programs (
    name VARCHAR(64) NOT NULL,
    abbr VARCHAR(16) NOT NULL,
    PRIMARY KEY (name)
);

-- Programmes are hosted by departments; several departments may
-- collaborate on one programme (e.g. CSEP is co-hosted by CS+CE).
CREATE TABLE HostedBy (
    program    VARCHAR(64) NOT NULL REFERENCES Programs(name),
    department VARCHAR(64) NOT NULL REFERENCES Departments(name),
    PRIMARY KEY (program, department)
);

CREATE TABLE Branches (
    name    VARCHAR(64) NOT NULL,
    program VARCHAR(64) NOT NULL REFERENCES Programs(name),
    PRIMARY KEY (name, program)
);

-- How many credits of its recommended courses a branch requires
-- its students to pass ("a certain amount"; 10 in this system).
CREATE TABLE BranchRequirements (
    program            VARCHAR(64)   NOT NULL,
    branch             VARCHAR(64)   NOT NULL,
    recommendedCredits NUMERIC(4, 1) NOT NULL DEFAULT 10,
    PRIMARY KEY (program, branch),
    FOREIGN KEY (branch, program) REFERENCES Branches(name, program),
    CHECK (recommendedCredits > 0)
);

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

CREATE TABLE StudentBranches (
    student CHAR(10)    NOT NULL,
    branch  VARCHAR(64) NOT NULL,
    program VARCHAR(64) NOT NULL,
    PRIMARY KEY (student),
    FOREIGN KEY (student, program) REFERENCES Students(idnr, program),
    FOREIGN KEY (branch, program)  REFERENCES Branches(name, program)
);

CREATE TABLE Courses (
    code    CHAR(6)       NOT NULL,
    name    VARCHAR(64)   NOT NULL,
    credits NUMERIC(4, 1) NOT NULL,
    givenBy VARCHAR(64)   NOT NULL REFERENCES Departments(name),
    PRIMARY KEY (code),
    CHECK (credits > 0)
);

CREATE TABLE LimitedCourses (
    code  CHAR(6) NOT NULL REFERENCES Courses(code),
    seats INTEGER NOT NULL,
    PRIMARY KEY (code),
    CHECK (seats > 0)
);

CREATE TABLE Classifications (
    name VARCHAR(32) NOT NULL,
    PRIMARY KEY (name)
);

CREATE TABLE ClassifiedAs (
    course         CHAR(6)     NOT NULL REFERENCES Courses(code),
    classification VARCHAR(32) NOT NULL REFERENCES Classifications(name),
    PRIMARY KEY (course, classification)
);

CREATE TABLE Prerequisites (
    course CHAR(6) NOT NULL REFERENCES Courses(code),
    prereq CHAR(6) NOT NULL REFERENCES Courses(code),
    PRIMARY KEY (course, prereq),
    CHECK (course <> prereq)
);

CREATE TABLE MandatoryProgram (
    course  CHAR(6)     NOT NULL REFERENCES Courses(code),
    program VARCHAR(64) NOT NULL REFERENCES Programs(name),
    PRIMARY KEY (course, program)
);

CREATE TABLE MandatoryBranch (
    course  CHAR(6)     NOT NULL REFERENCES Courses(code),
    branch  VARCHAR(64) NOT NULL,
    program VARCHAR(64) NOT NULL,
    PRIMARY KEY (course, branch, program),
    FOREIGN KEY (branch, program) REFERENCES Branches(name, program)
);

CREATE TABLE RecommendedBranch (
    course  CHAR(6)     NOT NULL REFERENCES Courses(code),
    branch  VARCHAR(64) NOT NULL,
    program VARCHAR(64) NOT NULL,
    PRIMARY KEY (course, branch, program),
    FOREIGN KEY (branch, program) REFERENCES Branches(name, program)
);

CREATE TABLE TakenCourse (
    student CHAR(10) NOT NULL REFERENCES Students(idnr),
    course  CHAR(6)  NOT NULL REFERENCES Courses(code),
    grade   CHAR(1)  NOT NULL,
    PRIMARY KEY (student, course),
    CHECK (grade IN ('U', '3', '4', '5'))
);

CREATE TABLE Registered (
    student CHAR(10) NOT NULL REFERENCES Students(idnr),
    course  CHAR(6)  NOT NULL REFERENCES Courses(code),
    PRIMARY KEY (student, course)
);

-- 'position' is an absolute, ever-increasing number per course
-- (see task1/tables.sql for the justification).  The FD
-- (course, position) -> student gives the extra UNIQUE key.
CREATE TABLE WaitingList (
    student  CHAR(10) NOT NULL REFERENCES Students(idnr),
    course   CHAR(6)  NOT NULL REFERENCES Courses(code),
    position INTEGER  NOT NULL,
    PRIMARY KEY (student, course),
    UNIQUE (course, position),
    CHECK (position > 0)
);

-- The university is organised into departments for employees.
-- (Extension relation: completes the E-R model; not used by the
-- views or the student portal.)
CREATE TABLE Employees (
    idnr       CHAR(10)    NOT NULL,
    name       VARCHAR(64) NOT NULL,
    department VARCHAR(64) NOT NULL REFERENCES Departments(name),
    PRIMARY KEY (idnr),
    CHECK (idnr ~ '^[0-9]{10}$')
);

-- Bookkeeping of registrations created directly by a study
-- administrator, overriding prerequisite and size restrictions
-- (allowed by the domain).  Such a registration is a normal row
-- of Registered; this table records that it was an override.
CREATE TABLE AdminOverrides (
    student CHAR(10) NOT NULL REFERENCES Students(idnr),
    course  CHAR(6)  NOT NULL REFERENCES Courses(code),
    PRIMARY KEY (student, course)
);
