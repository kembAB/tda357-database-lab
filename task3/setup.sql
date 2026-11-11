-- =====================================================================
-- TDA357 / DIT621 -- Database Programming Assignment (Lab PM), LP3 2019
-- Task 3: Triggers -- setup.sql
-- Author: Abel Haile Magicho
--
-- Sets up the database for testing the triggers.  This file is the
-- concatenation of the Task 2 deliverables tables.sql, inserts.sql
-- and views.sql (in that order), so that the trigger tests can be
-- run with:
--     psql -d <db> -f setup.sql -f triggers.sql -f tests.sql
-- on an empty database.
-- =====================================================================

-- ==================== task2/tables.sql ====================

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

-- ==================== task2/inserts.sql ====================

-- =====================================================================
-- TDA357 / DIT621 -- Database Programming Assignment (Lab PM), LP3 2019
-- Task 2: Database design -- test data for the FINAL schema
-- Author: Abel Haile Magicho
--
-- The Task 1 data, adapted to the final schema: Programs rows no
-- longer carry a host (hosting is in HostedBy instead, with CSEP
-- co-hosted by Computing Science and Computer Engineering, as the
-- domain describes), plus BranchRequirements, Employees and
-- AdminOverrides rows for the new relations.
--
-- Example data that exercises every corner case named in the
-- assignment (see the comments at each group of students):
--   * a student who fulfils the requirements for graduation (Anna)
--   * students who do not, for different reasons: a mandatory
--     course missing (Bjorn), too few mathematical credits
--     (Cecilia), no branch chosen (David)
--   * courses with classifications: mathematical, research,
--     seminar, one course with TWO classifications (MAT400),
--     and courses with no classification at all (TDA450, ...)
--   * two branches with the same name on different programmes
--     ("Interaction Design" in CSEP and in AT), each with at
--     least one registered student and one mandatory course
--   * at least three waiting students for two different full
--     courses (TDA381 and TDA550)
--   * a student who has not chosen a branch (David)
--   * a student who has not taken any courses (Erik)
--   * a student with only failing grades (Fatima)
--   * prerequisite chains: TDA450 -> TDA357 -> DAT400
--
-- (This file corresponds to the "inserts.sql" deliverable; the
-- assignment text also calls it insert.sql.  It differs from any
-- course-provided file in that it was reconstructed together with
-- the rest of this solution -- see README.md.)
-- =====================================================================

INSERT INTO Departments (name, abbr) VALUES
    ('Computing Science',    'CS'),
    ('Computer Engineering', 'CE'),
    ('Mathematics',          'MA');

INSERT INTO Programs (name, abbr) VALUES
    ('Computer Science and Engineering', 'CSEP'),
    ('Automation Technology',            'AT'),
    ('Information Technology',           'IT');

-- Hosting is many-to-many in the final schema: CSEP is co-hosted
-- by the CS and CE departments, as in the domain description.
INSERT INTO HostedBy (program, department) VALUES
    ('Computer Science and Engineering', 'Computing Science'),
    ('Computer Science and Engineering', 'Computer Engineering'),
    ('Automation Technology',            'Computer Engineering'),
    ('Information Technology',           'Computing Science');

-- Note the two branches called "Interaction Design", one in CSEP
-- and one in AT: branch names are only unique within a programme.
INSERT INTO Branches (name, program) VALUES
    ('Software Engineering', 'Computer Science and Engineering'),
    ('Algorithms',           'Computer Science and Engineering'),
    ('Computer Languages',   'Computer Science and Engineering'),
    ('Interaction Design',   'Computer Science and Engineering'),
    ('Interaction Design',   'Automation Technology'),
    ('Control Systems',      'Automation Technology'),
    ('Systems Development',  'Information Technology'),
    ('Networks',             'Information Technology');

-- Every branch requires 10 credits of its recommended courses.
INSERT INTO BranchRequirements (program, branch, recommendedCredits) VALUES
    ('Computer Science and Engineering', 'Software Engineering', 10),
    ('Computer Science and Engineering', 'Algorithms',           10),
    ('Computer Science and Engineering', 'Computer Languages',   10),
    ('Computer Science and Engineering', 'Interaction Design',   10),
    ('Automation Technology',            'Interaction Design',   10),
    ('Automation Technology',            'Control Systems',      10),
    ('Information Technology',           'Systems Development',  10),
    ('Information Technology',           'Networks',             10);

INSERT INTO Classifications (name) VALUES
    ('Mathematical'),
    ('Research'),
    ('Seminar');

INSERT INTO Courses (code, name, credits, givenBy) VALUES
    ('MAT050', 'Set Theory',                          5.0, 'Mathematics'),
    ('MAT100', 'Linear Algebra',                     10.0, 'Mathematics'),
    ('MAT200', 'Discrete Mathematics',                7.5, 'Mathematics'),
    ('MAT300', 'Probability Theory',                  5.0, 'Mathematics'),
    ('MAT400', 'Mathematical Statistics',            10.0, 'Mathematics'),
    ('TDA450', 'Functional Programming',             10.0, 'Computing Science'),
    ('TDA357', 'Databases',                           7.5, 'Computing Science'),
    ('TIN090', 'Algorithms',                          7.5, 'Computing Science'),
    ('TDA590', 'Object-Oriented Systems Development', 10.0, 'Computing Science'),
    ('DAT400', 'Advanced Databases',                  7.5, 'Computing Science'),
    ('TDA500', 'Research Methods in Computer Science', 5.0, 'Computing Science'),
    ('SEM100', 'Seminar in Software Engineering',     5.0, 'Computing Science'),
    ('SEM200', 'Seminar in Automation and Interaction', 5.0, 'Computer Engineering'),
    ('TDA381', 'Concurrent Programming',              7.5, 'Computing Science'),
    ('TDA550', 'Computer Networks',                   7.5, 'Computer Engineering'),
    ('TDA600', 'Interaction Design',                  7.5, 'Computing Science'),
    ('AUT100', 'Control Theory',                     10.0, 'Computer Engineering'),
    ('AUT200', 'Signals and Systems',                 7.5, 'Computer Engineering'),
    ('AUT300', 'Robotics',                            7.5, 'Computer Engineering');

INSERT INTO LimitedCourses (code, seats) VALUES
    ('TDA381', 2),   -- full: 2 registered, 3 waiting (below)
    ('TDA550', 1),   -- full: 1 registered, 3 waiting (below)
    ('SEM200', 5);   -- limited but with free places

-- MAT400 is classified as BOTH Mathematical and Research;
-- TDA450, TIN090, TDA590, TDA381, TDA550, TDA600 and AUT200 have
-- no classification at all.
INSERT INTO ClassifiedAs (course, classification) VALUES
    ('MAT050', 'Mathematical'),
    ('MAT100', 'Mathematical'),
    ('MAT200', 'Mathematical'),
    ('MAT300', 'Mathematical'),
    ('MAT400', 'Mathematical'),
    ('MAT400', 'Research'),
    ('AUT100', 'Mathematical'),
    ('TDA357', 'Research'),
    ('DAT400', 'Research'),
    ('TDA500', 'Research'),
    ('AUT300', 'Research'),
    ('SEM100', 'Seminar'),
    ('SEM200', 'Seminar');

-- Prerequisite chain: TDA450 -> TDA357 -> DAT400.
INSERT INTO Prerequisites (course, prereq) VALUES
    ('TDA357', 'TDA450'),
    ('DAT400', 'TDA357'),
    ('TDA590', 'TDA450'),
    ('TIN090', 'TDA450'),
    ('AUT300', 'AUT100');

INSERT INTO MandatoryProgram (course, program) VALUES
    ('TDA357', 'Computer Science and Engineering'),
    ('TDA450', 'Computer Science and Engineering'),
    ('TIN090', 'Computer Science and Engineering'),
    ('AUT100', 'Automation Technology'),
    ('AUT200', 'Automation Technology'),
    ('TDA357', 'Information Technology'),
    ('TDA450', 'Information Technology');

INSERT INTO MandatoryBranch (course, branch, program) VALUES
    ('TDA590', 'Software Engineering', 'Computer Science and Engineering'),
    ('SEM100', 'Software Engineering', 'Computer Science and Engineering'),
    ('MAT200', 'Algorithms',           'Computer Science and Engineering'),
    ('DAT400', 'Algorithms',           'Computer Science and Engineering'),
    ('TDA450', 'Computer Languages',   'Computer Science and Engineering'),
    ('TDA600', 'Interaction Design',   'Computer Science and Engineering'),
    ('TDA600', 'Interaction Design',   'Automation Technology'),
    ('AUT300', 'Control Systems',      'Automation Technology'),
    ('TDA590', 'Systems Development',  'Information Technology'),
    ('TDA550', 'Networks',             'Information Technology');

INSERT INTO RecommendedBranch (course, branch, program) VALUES
    ('DAT400', 'Software Engineering', 'Computer Science and Engineering'),
    ('TDA500', 'Software Engineering', 'Computer Science and Engineering'),
    ('TDA381', 'Software Engineering', 'Computer Science and Engineering'),
    ('MAT400', 'Software Engineering', 'Computer Science and Engineering'),
    ('MAT400', 'Algorithms',           'Computer Science and Engineering'),
    ('TDA500', 'Algorithms',           'Computer Science and Engineering'),
    ('MAT300', 'Algorithms',           'Computer Science and Engineering'),
    ('TDA500', 'Computer Languages',   'Computer Science and Engineering'),
    ('DAT400', 'Computer Languages',   'Computer Science and Engineering'),
    ('SEM200', 'Interaction Design',   'Computer Science and Engineering'),
    ('TDA500', 'Interaction Design',   'Computer Science and Engineering'),
    ('SEM200', 'Interaction Design',   'Automation Technology'),
    ('TDA500', 'Interaction Design',   'Automation Technology'),
    ('AUT200', 'Control Systems',      'Automation Technology'),
    ('MAT300', 'Control Systems',      'Automation Technology'),
    ('TDA500', 'Systems Development',  'Information Technology'),
    ('DAT400', 'Systems Development',  'Information Technology'),
    ('TDA381', 'Networks',             'Information Technology'),
    ('SEM200', 'Networks',             'Information Technology');

INSERT INTO Students (idnr, name, login, program) VALUES
    ('1234567890', 'Emilia Emilsson', 'emem',   'Information Technology'),
    ('1990010111', 'Anna Andersson',  'annaa',  'Computer Science and Engineering'),
    ('1991020222', 'Bjorn Berg',      'bjornb', 'Computer Science and Engineering'),
    ('1992030333', 'Cecilia Ceder',   'cecilc', 'Computer Science and Engineering'),
    ('1993040444', 'David Dahl',      'davidd', 'Computer Science and Engineering'),
    ('1994050555', 'Erik Ek',         'erike',  'Automation Technology'),
    ('1995060666', 'Fatima Falk',     'fatimf', 'Automation Technology'),
    ('1996070777', 'Gustav Gran',     'gustag', 'Computer Science and Engineering'),
    ('1997080888', 'Hanna Holm',      'hannah', 'Computer Science and Engineering'),
    ('1998090999', 'Ibrahim Issa',    'ibrahi', 'Information Technology'),
    ('1999101000', 'Johan Jansson',   'johanj', 'Information Technology'),
    ('2000011111', 'Karin Karlsson',  'karink', 'Computer Science and Engineering'),
    ('2001021222', 'Lars Larsson',    'larsl',  'Automation Technology'),
    ('2002031333', 'Maja Malm',       'majam',  'Computer Science and Engineering'),
    ('2003041444', 'Nils Nilsson',    'nilsn',  'Information Technology'),
    ('2004051555', 'Olga Olsson',     'olgao',  'Automation Technology'),
    ('2005061666', 'Per Persson',     'perp',   'Computer Science and Engineering');

-- David (and Johan, Karin, Nils, Olga, Per) have not chosen a
-- branch: they simply have no row here.
INSERT INTO StudentBranches (student, branch, program) VALUES
    ('1234567890', 'Systems Development',  'Information Technology'),
    ('1990010111', 'Software Engineering', 'Computer Science and Engineering'),
    ('1991020222', 'Software Engineering', 'Computer Science and Engineering'),
    ('1992030333', 'Algorithms',           'Computer Science and Engineering'),
    ('1994050555', 'Control Systems',      'Automation Technology'),
    ('1995060666', 'Interaction Design',   'Automation Technology'),
    ('1996070777', 'Interaction Design',   'Computer Science and Engineering'),
    ('1997080888', 'Software Engineering', 'Computer Science and Engineering'),
    ('1998090999', 'Systems Development',  'Information Technology'),
    ('2001021222', 'Control Systems',      'Automation Technology'),
    ('2002031333', 'Algorithms',           'Computer Science and Engineering');

-- Emilia: the student from the assignment's example session.
-- 25 credits, no seminar course -- does not qualify.
INSERT INTO TakenCourse (student, course, grade) VALUES
    ('1234567890', 'MAT050', '5'),
    ('1234567890', 'TDA450', '5'),
    ('1234567890', 'TDA590', '4');

-- Anna: fulfils EVERY graduation requirement.
--   mandatory: TDA450, TDA357, TIN090 (programme) + TDA590, SEM100
--              (branch) all passed
--   recommended (branch): DAT400 7.5 + TDA500 5 = 12.5 >= 10
--   mathematical: MAT100 10 + MAT200 7.5 + MAT050 5 = 22.5 >= 20
--   research: TDA357 7.5 + DAT400 7.5 + TDA500 5 = 20 >= 10
--   seminar: SEM100
INSERT INTO TakenCourse (student, course, grade) VALUES
    ('1990010111', 'TDA450', '4'),
    ('1990010111', 'TDA357', '5'),
    ('1990010111', 'TIN090', '4'),
    ('1990010111', 'TDA590', '5'),
    ('1990010111', 'SEM100', '4'),
    ('1990010111', 'DAT400', '4'),
    ('1990010111', 'TDA500', '5'),
    ('1990010111', 'MAT100', '3'),
    ('1990010111', 'MAT200', '4'),
    ('1990010111', 'MAT050', '5');

-- Bjorn: like Anna but has NOT passed TDA590, a mandatory course
-- of his branch -- the only requirement he fails (mandatoryLeft 1).
INSERT INTO TakenCourse (student, course, grade) VALUES
    ('1991020222', 'TDA450', '3'),
    ('1991020222', 'TDA357', '4'),
    ('1991020222', 'TIN090', '3'),
    ('1991020222', 'SEM100', '3'),
    ('1991020222', 'DAT400', '3'),
    ('1991020222', 'TDA500', '4'),
    ('1991020222', 'MAT100', '4'),
    ('1991020222', 'MAT200', '3'),
    ('1991020222', 'MAT050', '4'),
    ('1991020222', 'TDA381', '4');

-- Cecilia: all mandatory and recommended requirements fulfilled,
-- research 30 credits, a seminar course -- but only
-- MAT200 7.5 + MAT400 10 = 17.5 mathematical credits (< 20),
-- so she does not qualify, for that reason alone.
INSERT INTO TakenCourse (student, course, grade) VALUES
    ('1992030333', 'TDA450', '4'),
    ('1992030333', 'TDA357', '3'),
    ('1992030333', 'TIN090', '4'),
    ('1992030333', 'MAT200', '3'),
    ('1992030333', 'DAT400', '4'),
    ('1992030333', 'MAT400', '3'),
    ('1992030333', 'TDA500', '4'),
    ('1992030333', 'SEM100', '5');

-- David: has passed all programme-mandatory courses and enough
-- classified credits, but has NOT chosen a branch, so he cannot
-- graduate.
INSERT INTO TakenCourse (student, course, grade) VALUES
    ('1993040444', 'TDA450', '3'),
    ('1993040444', 'TDA357', '3'),
    ('1993040444', 'TIN090', '5'),
    ('1993040444', 'MAT100', '4'),
    ('1993040444', 'MAT200', '4'),
    ('1993040444', 'MAT050', '3'),
    ('1993040444', 'TDA500', '3'),
    ('1993040444', 'SEM100', '4');

-- Fatima: only failing grades ('U').
INSERT INTO TakenCourse (student, course, grade) VALUES
    ('1995060666', 'AUT100', 'U'),
    ('1995060666', 'TDA600', 'U');

-- Gustav: a couple of passed courses; registered below for the
-- mandatory course of "Interaction Design" (CSEP).
INSERT INTO TakenCourse (student, course, grade) VALUES
    ('1996070777', 'TDA450', '3'),
    ('1996070777', 'MAT050', '4');

INSERT INTO TakenCourse (student, course, grade) VALUES
    ('1997080888', 'TDA450', '4'),
    ('1998090999', 'TDA450', '3');

-- Erik has taken no courses at all: no rows for him anywhere.

INSERT INTO Registered (student, course) VALUES
    ('1234567890', 'TDA357'),   -- Emilia reads Databases
    ('1995060666', 'AUT200'),   -- Fatima: registered student of "Interaction Design" (AT)
    ('1996070777', 'TDA600'),   -- Gustav: registered student of "Interaction Design" (CSEP)
    ('1997080888', 'TDA381'),   -- Hanna  -- TDA381 full (2/2)
    ('1998090999', 'TDA381'),   -- Ibrahim
    ('2002031333', 'TDA550');   -- Maja   -- TDA550 full (1/1)

-- Three waiting students on each of the two full courses.
INSERT INTO WaitingList (student, course, position) VALUES
    ('1999101000', 'TDA381', 1),   -- Johan
    ('2000011111', 'TDA381', 2),   -- Karin
    ('1234567890', 'TDA381', 3),   -- Emilia waits as number 3
    ('2003041444', 'TDA550', 1),   -- Nils
    ('2004051555', 'TDA550', 2),   -- Olga
    ('2005061666', 'TDA550', 3);   -- Per

-- Rows for the two relations that are new in the final schema.
INSERT INTO Employees (idnr, name, department) VALUES
    ('1970010111', 'Sara Lindqvist', 'Computing Science'),
    ('1971020222', 'Omar Haddad',    'Computer Engineering'),
    ('1972030333', 'Ingrid Nyberg',  'Mathematics');

-- Maja's registration for the one-seat course TDA550 was created
-- directly by a study administrator (an override), which this
-- bookkeeping row records.
INSERT INTO AdminOverrides (student, course) VALUES
    ('2002031333', 'TDA550');

-- ==================== task2/views.sql ====================

-- =====================================================================
-- TDA357 / DIT621 -- Database Programming Assignment (Lab PM), LP3 2019
-- Task 2: Database design -- views for the FINAL schema
-- Author: Abel Haile Magicho
--
-- The views required by the system specification, unchanged from
-- Task 1: none of the Task 2 design changes (HostedBy,
-- BranchRequirements, extra UNIQUEs) affects any view definition,
-- which confirms the final design did not break the Task 1 work.
-- =====================================================================

-- BasicInformation(idnr, name, login, program, branch)
-- For all students: their national identification number, name,
-- login, programme and branch (if any).  'branch' is the only
-- column in any of the views that may contain NULL (students who
-- have not chosen a branch yet), hence the LEFT JOIN.
CREATE VIEW BasicInformation AS
SELECT S.idnr    AS idnr,
       S.name    AS name,
       S.login   AS login,
       S.program AS program,
       SB.branch AS branch
FROM Students S
LEFT JOIN StudentBranches SB ON SB.student = S.idnr;

-- FinishedCourses(student, course, grade, credits)
-- For all students, all finished courses, with their codes, grades
-- and number of credits.
CREATE VIEW FinishedCourses AS
SELECT T.student AS student,
       T.course  AS course,
       T.grade   AS grade,
       C.credits AS credits
FROM TakenCourse T
JOIN Courses C ON C.code = T.course;

-- PassedCourses(student, course, credits)
-- For all students, all passed courses (grade other than 'U') and
-- the number of credits for those courses.  Helper view.
CREATE VIEW PassedCourses AS
SELECT student, course, credits
FROM FinishedCourses
WHERE grade <> 'U';

-- Registrations(student, course, status)
-- All registered and waiting students for all courses, along with
-- their status ('registered' or 'waiting').
CREATE VIEW Registrations AS
SELECT student, course, 'registered' AS status FROM Registered
UNION ALL
SELECT student, course, 'waiting'    AS status FROM WaitingList;

-- UnreadMandatory(student, course)
-- For all students, the mandatory courses (of their programme and
-- of their branch, if they have chosen one) that they have not yet
-- passed.  Helper view for PathToGraduation.
CREATE VIEW UnreadMandatory AS
SELECT S.idnr AS student, MP.course AS course
FROM Students S
JOIN MandatoryProgram MP ON MP.program = S.program
WHERE NOT EXISTS (SELECT 1
                  FROM PassedCourses P
                  WHERE P.student = S.idnr AND P.course = MP.course)
UNION
SELECT S.idnr AS student, MB.course AS course
FROM Students S
JOIN StudentBranches SB ON SB.student = S.idnr
JOIN MandatoryBranch MB ON MB.branch = SB.branch AND MB.program = SB.program
WHERE NOT EXISTS (SELECT 1
                  FROM PassedCourses P
                  WHERE P.student = S.idnr AND P.course = MB.course);

-- PathToGraduation(student, totalCredits, mandatoryLeft, mathCredits,
--                  researchCredits, seminarCourses, qualified)
-- For all students, their path to graduation:
--   totalCredits    credits taken (passed courses only)
--   mandatoryLeft   number of mandatory courses not yet passed
--   mathCredits     passed credits in mathematical courses
--   researchCredits passed credits in research courses
--   seminarCourses  number of passed seminar courses
--   qualified       TRUE iff the student has chosen a branch, has
--                   passed all mandatory courses, has at least 10
--                   credits among the recommended courses of the
--                   branch, at least 20 mathematical credits, at
--                   least 10 research credits, and has passed at
--                   least one seminar course.
-- One subquery per component is built in the WITH clause and the
-- parts are combined with a chain of LEFT JOINs; COALESCE turns
-- missing (NULL) components into 0.
CREATE VIEW PathToGraduation AS
WITH Total AS (
    SELECT student, SUM(credits) AS totalCredits
    FROM PassedCourses
    GROUP BY student
),
Mand AS (
    SELECT student, COUNT(*) AS mandatoryLeft
    FROM UnreadMandatory
    GROUP BY student
),
MathC AS (
    SELECT P.student, SUM(P.credits) AS mathCredits
    FROM PassedCourses P
    JOIN ClassifiedAs CA ON CA.course = P.course
                        AND CA.classification = 'Mathematical'
    GROUP BY P.student
),
ResC AS (
    SELECT P.student, SUM(P.credits) AS researchCredits
    FROM PassedCourses P
    JOIN ClassifiedAs CA ON CA.course = P.course
                        AND CA.classification = 'Research'
    GROUP BY P.student
),
SemC AS (
    SELECT P.student, COUNT(*) AS seminarCourses
    FROM PassedCourses P
    JOIN ClassifiedAs CA ON CA.course = P.course
                        AND CA.classification = 'Seminar'
    GROUP BY P.student
),
RecC AS (
    SELECT SB.student, SUM(P.credits) AS recCredits
    FROM StudentBranches SB
    JOIN RecommendedBranch RB ON RB.branch = SB.branch
                             AND RB.program = SB.program
    JOIN PassedCourses P ON P.student = SB.student
                        AND P.course = RB.course
    GROUP BY SB.student
)
SELECT S.idnr                        AS student,
       COALESCE(T.totalCredits, 0)   AS totalCredits,
       COALESCE(M.mandatoryLeft, 0)  AS mandatoryLeft,
       COALESCE(MA.mathCredits, 0)   AS mathCredits,
       COALESCE(R.researchCredits, 0) AS researchCredits,
       COALESCE(SE.seminarCourses, 0) AS seminarCourses,
       (SB.student IS NOT NULL
        AND COALESCE(M.mandatoryLeft, 0) = 0
        AND COALESCE(RC.recCredits, 0) >= 10
        AND COALESCE(MA.mathCredits, 0) >= 20
        AND COALESCE(R.researchCredits, 0) >= 10
        AND COALESCE(SE.seminarCourses, 0) >= 1) AS qualified
FROM Students S
LEFT JOIN Total T  ON T.student = S.idnr
LEFT JOIN Mand M   ON M.student = S.idnr
LEFT JOIN MathC MA ON MA.student = S.idnr
LEFT JOIN ResC R   ON R.student = S.idnr
LEFT JOIN SemC SE  ON SE.student = S.idnr
LEFT JOIN RecC RC  ON RC.student = S.idnr
LEFT JOIN StudentBranches SB ON SB.student = S.idnr;
