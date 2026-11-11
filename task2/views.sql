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
