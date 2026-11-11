# Testing — what was actually run, and what came out

All results below are from real runs in this environment — nothing
here is a claim about a test that did not execute.

## Environment

- PostgreSQL **16.15** (Ubuntu 16.15-0ubuntu0.24.04.1), run as a
  small scratch cluster (port 5433, Unix socket in a scratch
  directory, trust authentication) because the VM has no system
  PostgreSQL service.
- OpenJDK **17.0.21**; PostgreSQL JDBC driver **42.7.2**
  (`/usr/share/java/postgresql.jar`, Debian package
  libpostgresql-jdbc-java).
- One environment quirk worth recording: in this VM, JVM processes
  are placed in a separate network namespace by the sandbox, so
  Java could not reach the server over TCP — verified down to the
  wire level (a raw protocol probe from Python gets a perfect
  PostgreSQL reply on the same port; a raw Java socket never
  arrives, and reports a local address in the sandbox's own
  `fd8b:…` range). Filesystem Unix sockets *are* shared between
  the namespaces, so the Task 4 demo connects through
  PostgreSQL's Unix socket file using junixsocket 2.10.1, via the
  portal's documented `DB_SOCKET` option. The portal code path is
  identical otherwise; on a normal machine the default TCP URL
  works as-is.

## Task 1 — tables.sql, inserts.sql, views.sql on an empty database

Runs clean with `ON_ERROR_STOP=1`. `PathToGraduation` afterwards:

```
  student   | totalcredits | mandatoryleft | mathcredits | researchcredits | seminarcourses | qualified
------------+--------------+---------------+-------------+-----------------+---------------
 1234567890 |         25.0 |             1 |         5.0 |               0 |              0 | f
 1990010111 |         75.0 |             0 |        22.5 |            20.0 |              1 | t
 1991020222 |         72.5 |             1 |        22.5 |            20.0 |              1 | f
 1992030333 |         60.0 |             0 |        17.5 |            30.0 |              1 | f
 1993040444 |         57.5 |             0 |        22.5 |            12.5 |              1 | f
 1994050555 |            0 |             3 |           0 |               0 |              0 | f
 ... (11 more students, all qualified = f)
(17 rows)
```

Exactly **one** student qualifies — Anna Andersson (1990010111) —
as designed. The near-misses fail for the intended single reason
each: Bjorn Berg only on `mandatoryLeft = 1` (TDA590 missing),
Cecilia Ceder only on math credits (17.5 < 20), David Dahl has
`mandatoryLeft = 0` but no branch. Also verified:
`BasicInformation` has exactly 6 students with NULL branch, and
the `Registrations` view shows the designed 12 rows.

## Task 2 — final schema on an empty database

`task2/tables.sql`, `inserts.sql`, `views.sql` run clean.
`PathToGraduation` again yields exactly one qualified student
(1990010111), `HostedBy` holds 4 rows (CSEP hosted by two
departments), `BranchRequirements` holds 8 rows.

## Task 3 — setup.sql + triggers.sql + tests.sql

Setup and triggers load clean. `tests.sql` (13 tests) produces
**exactly 4 errors** — the four intended failure modes, each at the
line its comment predicts:

```
psql:task3/tests.sql:52: ERROR:  Registration failed: student 1990010111 has already passed course TDA357
psql:task3/tests.sql:57: ERROR:  Registration failed: student 1234567890 is already registered or waiting for course TDA357
psql:task3/tests.sql:62: ERROR:  Registration failed: student 1234567890 is already registered or waiting for course TDA381
psql:task3/tests.sql:69: ERROR:  Registration failed: student 1994050555 does not meet the prerequisites for course TDA357
```

State checks inside the same run, all as expected:

- Register to unlimited course: Erik Ek → TDA450 `registered`;
  register to limited-but-not-full SEM200: Gustav Gran registered.
- Waiting for a full course: Lars Larsson joins TDA381's queue as
  place 4, behind Johan (1), Karin (2), Emilia (3).
- Unregister from limited course **with** queue (TDA550, 1 seat):
  Maja leaves → Nils is promoted to `registered`; queue becomes
  Olga 1, Per 2.
- Unregister from **over-full** course (TDA550 with 3 registered —
  two inserted directly into `Registered`, as an administrator
  could — against 1 seat): Karin leaves → **nobody is promoted**;
  Olga remains waiting at place 1.
- Unregister when not registered: `DELETE 0`, no state change, no
  promotion.
- Unregistering a *waiting* student removes only that entry and
  promotes nobody.

## Task 4 — StudentPortal demo sessions

`StudentPortal.java` compiles clean (`javac`, JDBC jar on the
class path). The demo ran against a pristine database
(setup + triggers), driven by scripted stdin. Student
1234567890 is Emilia Emilsson, the student whose data mirrors
the example session in the assignment text.

### Session A — info, register, re-register, unregister ×2, missing prerequisite

```
Welcome!
? > Information for student 1234567890
-------------------------------------
Name: Emilia Emilsson
Student ID: emem
Line: Information Technology
Branch: Systems Development

Read courses (name (code), credits: grade):
 Set Theory (MAT050), 5p: 5
 Functional Programming (TDA450), 10p: 5
 Object-Oriented Systems Development (TDA590), 10p: 4

Registered courses (name (code): status):
 Databases (TDA357): registered
 Concurrent Programming (TDA381): waiting as nr 3

Seminar courses taken: 0
Math credits taken: 5
Research credits taken: 0
Total credits taken: 25
Fulfills the requirements for graduation: no
-------------------------------------

? > You are now successfully registered to course TDA600 Interaction Design!
? > Registration failed: student 1234567890 is already registered or waiting for course TDA600
? > You are now unregistered from course TDA600 Interaction Design.
? > You are not registered or waiting for course TDA600.
? > Registration failed: student 1234567890 does not meet the prerequisites for course DAT400
? > Goodbye!
```

(The error lines are the Task 3 triggers' `RAISE EXCEPTION` texts,
printed verbatim by the portal.) The commands behind the prompts,
in order: `i`, `r TDA600`, `r TDA600`, `u TDA600`, `u TDA600`,
`r DAT400`, `quit`. DAT400 requires TDA357 passed; Emilia is only
*registered* for TDA357, so the prerequisite error is correct.

### Session B — restricted course with a queue: promotion, then last place, twice

Maja Malm (2002031333) holds the single TDA550 seat; Nils, Olga
and Per wait at places 1–3. Commands: `i`, `u TDA550`, `r TDA550`,
`u TDA550`, `r TDA550`, `quit`.

```
? > You are now unregistered from course TDA550 Computer Networks.
? > Course TDA550 Computer Networks is full, you are put in the waiting list.
? > You are now removed from the waiting list for course TDA550 Computer Networks.
? > Course TDA550 Computer Networks is full, you are put in the waiting list.
? > Goodbye!
```

Verified in the database afterwards: Nils (2003041444) was
promoted to `registered` when Maja unregistered; the queue is
Olga place 1, Per place 2, Maja place 3 — i.e. re-registering put
Maja **last**, and after leaving the queue and re-registering
again she is last again at the same place 3.

### Session C — over-full course: unregistering promotes nobody

Setup (direct SQL, as an administrator): Karin Karlsson
(2000011111) and Johan Jansson (1999101000) were inserted straight
into `Registered` for TDA550, giving 3 registered against 1 seat,
with Olga, Per and Maja waiting. Portal run as Karin, command
`u TDA550`:

```
? > You are now unregistered from course TDA550 Computer Networks.
? > Goodbye!
```

Verified afterwards: 2 students remain registered (still ≥ the
1 seat), and the queue is unchanged — Olga still waiting at
place 1, Per 2, Maja 3. **No promotion**, as specified.

### Demo coverage vs the assignment's demo list

| Assignment demo item | Where covered |
|---|---|
| Print all information for a student | Session A (`i`) and B (`i`) |
| Register to an unrestricted course | Session A (`r TDA600`) |
| Register again → error | Session A (trigger message printed) |
| Unregister, then unregister again | Session A |
| Register without prerequisites → error | Session A (`r DAT400`) |
| Unregister from restricted course with ≥ 2 in queue | Session B (Nils promoted) |
| Register again → last place in queue | Session B (place 3) |
| Unregister and register again → same last place | Session B (place 3 again) |
| Unregister from over-full course → no promotion | Session C |

## Not verified / reconstructed

- The course-provided files (`task1.txt`, the provided
  `inserts.sql`, `runtests.sql` / `output.txt`, the
  `StudentPortal.java` stub) were not available; see the
  reconstruction note in README.md. Behaviour was checked against
  the assignment text, not against the course's expected-output
  files.
- TCP JDBC from Java could not be exercised in this VM for the
  sandbox reason documented above; the portal's TCP defaults are
  the standard pgjdbc URL form and are unchanged.
