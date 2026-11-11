-- =====================================================================
-- TDA357 / DIT621 -- Database Programming Assignment (Lab PM), LP3 2019
-- Task 3: Triggers
-- Author: Abel Haile Magicho
--
-- The CourseQueuePositions view and the two INSTEAD OF triggers on
-- the Registrations view that implement course registration and
-- unregistration:
--
--   * INSERT on Registrations: checks that the student may
--     register (not already passed, not already registered or
--     waiting, prerequisites passed), then either registers the
--     student or -- if the course is limited and full -- puts
--     him/her last on the waiting list.  Violations RAISE an
--     exception, whose message is the reason for the failure.
--   * DELETE on Registrations: removes the registration; if the
--     student was registered (not only waiting) and there is now
--     room on the course, the student who has waited the longest
--     is registered instead.  If the course is still full or
--     over-full (possible after administrator overrides), nobody
--     is promoted.
--
-- The triggers are defined on the VIEW (not on the tables) because
-- the application of Task 4 only has INSERT/DELETE privileges on
-- the view; the trigger functions do the privileged work on the
-- underlying tables.  Defining them on the tables instead would
-- also fire for direct table writes (e.g. administrator overrides,
-- which must be allowed to bypass the checks) and could not
-- distinguish "register via the portal" from other inserts.
--
-- Run setup.sql first, then this file.
-- =====================================================================

-- CourseQueuePositions(course, student, place)
-- For all students in a queue: the course, the student, and the
-- student's dense place in the queue (first in line has place 1).
-- (The stored WaitingList.position is an absolute ever-increasing
-- number; ROW_NUMBER turns it into the dense place.)
CREATE VIEW CourseQueuePositions AS
SELECT course  AS course,
       student AS student,
       ROW_NUMBER() OVER (PARTITION BY course ORDER BY position) AS place
FROM WaitingList;

-- ---------------------------------------------------------------------
-- Registration trigger
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION register_student() RETURNS trigger AS $$
BEGIN
    -- A student cannot register for a course already passed.
    IF EXISTS (SELECT 1 FROM PassedCourses
               WHERE student = NEW.student AND course = NEW.course) THEN
        RAISE EXCEPTION 'Registration failed: student % has already passed course %',
              NEW.student, NEW.course;
    END IF;

    -- A student cannot register twice, nor register while waiting.
    IF EXISTS (SELECT 1 FROM Registered
               WHERE student = NEW.student AND course = NEW.course)
       OR EXISTS (SELECT 1 FROM WaitingList
               WHERE student = NEW.student AND course = NEW.course) THEN
        RAISE EXCEPTION 'Registration failed: student % is already registered or waiting for course %',
              NEW.student, NEW.course;
    END IF;

    -- All prerequisites of the course must be passed.
    IF EXISTS (SELECT 1 FROM Prerequisites P
               WHERE P.course = NEW.course
                 AND NOT EXISTS (SELECT 1 FROM PassedCourses PC
                                 WHERE PC.student = NEW.student
                                   AND PC.course = P.prereq)) THEN
        RAISE EXCEPTION 'Registration failed: student % does not meet the prerequisites for course %',
              NEW.student, NEW.course;
    END IF;

    -- If the course is limited and full, join the waiting list
    -- (with the next absolute position); otherwise register.
    -- "Full" means: number of registered students >= seats.
    -- (A course made over-full by an administrator override is
    -- also "full" here, and new students simply wait.)
    IF EXISTS (SELECT 1 FROM LimitedCourses L
               WHERE L.code = NEW.course
                 AND (SELECT COUNT(*) FROM Registered R
                      WHERE R.course = NEW.course) >= L.seats) THEN
        INSERT INTO WaitingList (student, course, position)
        VALUES (NEW.student, NEW.course,
                (SELECT COALESCE(MAX(position), 0) + 1
                 FROM WaitingList WHERE course = NEW.course));
    ELSE
        INSERT INTO Registered (student, course)
        VALUES (NEW.student, NEW.course);
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER registration_trigger
INSTEAD OF INSERT ON Registrations
FOR EACH ROW EXECUTE FUNCTION register_student();

-- ---------------------------------------------------------------------
-- Unregistration trigger
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION unregister_student() RETURNS trigger AS $$
DECLARE
    v_seats  INTEGER;
    v_count  INTEGER;
    v_next   CHAR(10);
BEGIN
    IF EXISTS (SELECT 1 FROM Registered
               WHERE student = OLD.student AND course = OLD.course) THEN
        -- The student was registered: remove the registration.
        DELETE FROM Registered
        WHERE student = OLD.student AND course = OLD.course;

        -- Promote the longest-waiting student, but only if there
        -- is actually room now: for a limited course the number
        -- of registered students must be strictly below the seat
        -- count (an over-full course promotes nobody); unlimited
        -- courses always have room.
        SELECT seats INTO v_seats FROM LimitedCourses WHERE code = OLD.course;
        SELECT COUNT(*) INTO v_count FROM Registered WHERE course = OLD.course;
        IF v_seats IS NULL OR v_count < v_seats THEN
            SELECT student INTO v_next
            FROM WaitingList
            WHERE course = OLD.course
            ORDER BY position
            LIMIT 1;
            IF v_next IS NOT NULL THEN
                DELETE FROM WaitingList
                WHERE student = v_next AND course = OLD.course;
                INSERT INTO Registered (student, course)
                VALUES (v_next, OLD.course);
            END IF;
        END IF;

    ELSIF EXISTS (SELECT 1 FROM WaitingList
                  WHERE student = OLD.student AND course = OLD.course) THEN
        -- The student was only waiting: remove from the waiting
        -- list.  No slot on the course was freed, so NOBODY is
        -- promoted.
        DELETE FROM WaitingList
        WHERE student = OLD.student AND course = OLD.course;
    END IF;

    -- If the student was neither registered nor waiting, nothing
    -- happens (and in particular nobody is promoted).
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER unregistration_trigger
INSTEAD OF DELETE ON Registrations
FOR EACH ROW EXECUTE FUNCTION unregister_student();
