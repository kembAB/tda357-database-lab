-- =====================================================================
-- TDA357 / DIT621 -- Database Programming Assignment (Lab PM), LP3 2019
-- Task 3: Triggers -- tests
-- Author: Abel Haile Magicho
--
-- Run AFTER setup.sql and triggers.sql:
--     psql -d <db> -f setup.sql -f triggers.sql -f tests.sql
-- Do NOT use --single-transaction or ON_ERROR_STOP: several tests
-- are EXPECTED to fail with an exception (that is the point of the
-- test); in plain autocommit mode psql prints the error and
-- continues with the next statement.
--
-- Students used (from the setup data):
--   Erik Ek        1994050555  has passed nothing, registered nowhere
--   Gustav Gran    1996070777  passed TDA450 and MAT050
--   Anna Andersson 1990010111  has PASSED TDA357
--   Emilia Emilsson 1234567890 is REGISTERED for TDA357 and WAITING
--                              (position 3) for TDA381
--   Maja Malm      2002031333  is REGISTERED for TDA550 (1 seat)
--   Nils Nilsson   2003041444  WAITING position 1 for TDA550
--   Olga Olsson    2004051555  WAITING position 2 for TDA550
--   Per Persson    2005061666  WAITING position 3 for TDA550
--   Lars Larsson   2001021222  no registrations
-- Courses: TDA450 unlimited; SEM200 limited (5 seats, empty);
--   TDA381 limited and FULL (2 seats, 2 registered, 3 waiting);
--   TDA550 limited and FULL (1 seat, 1 registered, 3 waiting);
--   TDA357 has prerequisite TDA450.
-- =====================================================================

-- TEST 1: register to an UNLIMITED course.
-- Expected: Erik becomes registered for TDA450.
INSERT INTO Registrations (student, course, status)
VALUES ('1994050555', 'TDA450', 'registered');
SELECT * FROM Registrations WHERE student = '1994050555';

-- TEST 2: register to a LIMITED course that still has free places.
-- Expected: Gustav becomes registered for SEM200 (not waiting).
INSERT INTO Registrations (student, course, status)
VALUES ('1996070777', 'SEM200', 'registered');
SELECT * FROM Registrations WHERE student = '1996070777';

-- TEST 3: register to a LIMITED course that is FULL.
-- Expected: Lars is put on the waiting list for TDA381, last in
-- the queue (place 4, after Johan, Karin and Emilia).
INSERT INTO Registrations (student, course, status)
VALUES ('2001021222', 'TDA381', 'registered');
SELECT * FROM CourseQueuePositions WHERE course = 'TDA381' ORDER BY place;

-- TEST 4: registration FAILURE -- course already passed.
-- Expected: ERROR, "... has already passed course TDA357 ...".
INSERT INTO Registrations (student, course, status)
VALUES ('1990010111', 'TDA357', 'registered');

-- TEST 5: registration FAILURE -- already registered.
-- Expected: ERROR, "... is already registered or waiting ...".
INSERT INTO Registrations (student, course, status)
VALUES ('1234567890', 'TDA357', 'registered');

-- TEST 6: registration FAILURE -- already on the waiting list.
-- Expected: ERROR, "... is already registered or waiting ...".
INSERT INTO Registrations (student, course, status)
VALUES ('1234567890', 'TDA381', 'registered');

-- TEST 7: registration FAILURE -- prerequisite not passed.
-- Erik is registered for TDA450 (test 1) but has not PASSED it,
-- and TDA450 is a prerequisite of TDA357.
-- Expected: ERROR, "... does not meet the prerequisites ...".
INSERT INTO Registrations (student, course, status)
VALUES ('1994050555', 'TDA357', 'registered');

-- TEST 8: unregister from an UNLIMITED course.
-- Expected: Erik's registration for TDA450 is removed.
DELETE FROM Registrations
WHERE student = '1994050555' AND course = 'TDA450';
SELECT * FROM Registrations WHERE student = '1994050555';

-- TEST 9: unregister from a LIMITED course WITHOUT a waiting list.
-- Expected: Gustav's registration for SEM200 is removed and
-- nothing else changes (there is no queue to promote from).
DELETE FROM Registrations
WHERE student = '1996070777' AND course = 'SEM200';
SELECT * FROM Registrations WHERE course = 'SEM200';

-- TEST 10: unregister from a LIMITED course WITH a waiting list.
-- Expected: Maja is unregistered from TDA550 and Nils (first in
-- the queue) is registered instead; the queue for TDA550 becomes
-- Olga (place 1), Per (place 2).
DELETE FROM Registrations
WHERE student = '2002031333' AND course = 'TDA550';
SELECT * FROM Registrations WHERE course = 'TDA550' ORDER BY status, student;
SELECT * FROM CourseQueuePositions WHERE course = 'TDA550' ORDER BY place;

-- TEST 11: unregister from an OVERFULL course WITH a waiting list.
-- Setup: an administrator directly registers Karin and Johan for
-- TDA550 (direct table inserts, bypassing the triggers, as an
-- administrator override may).  TDA550 now has 3 registered
-- students but only 1 seat: it is over-full.
INSERT INTO Registered (student, course) VALUES ('2000011111', 'TDA550');
INSERT INTO Registered (student, course) VALUES ('1999101000', 'TDA550');
SELECT * FROM Registrations WHERE course = 'TDA550' ORDER BY status, student;
-- Test: Karin unregisters.
-- Expected: Karin is removed, but since 2 students remain
-- registered for 1 seat, the course is still full and Olga is
-- NOT promoted -- she stays at place 1 of the queue.
DELETE FROM Registrations
WHERE student = '2000011111' AND course = 'TDA550';
SELECT * FROM Registrations WHERE course = 'TDA550' ORDER BY status, student;
SELECT * FROM CourseQueuePositions WHERE course = 'TDA550' ORDER BY place;

-- TEST 12: unregister a student who is NOT registered or waiting.
-- Erik has no connection with TDA381.
-- Expected: no error, no change at all; in particular nobody is
-- promoted on TDA381 (its queue keeps Johan, Karin, Emilia, Lars
-- at places 1-4, two students stay registered).
DELETE FROM Registrations
WHERE student = '1994050555' AND course = 'TDA381';
SELECT * FROM Registrations WHERE course = 'TDA381' ORDER BY status, student;
SELECT * FROM CourseQueuePositions WHERE course = 'TDA381' ORDER BY place;

-- TEST 13: unregister a student who is only WAITING.
-- Expected: Lars is removed from the TDA381 waiting list; the
-- registered students (Hanna, Ibrahim) are untouched and nobody
-- is promoted (no seat was freed).  Queue becomes Johan (1),
-- Karin (2), Emilia (3).
DELETE FROM Registrations
WHERE student = '2001021222' AND course = 'TDA381';
SELECT * FROM Registrations WHERE course = 'TDA381' ORDER BY status, student;
SELECT * FROM CourseQueuePositions WHERE course = 'TDA381' ORDER BY place;
