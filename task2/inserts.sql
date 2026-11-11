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
