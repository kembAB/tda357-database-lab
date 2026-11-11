# TDA357 / DIT621 — Database Programming Assignment (Lab PM, LP3 2019)

A complete, working implementation of the Chalmers / University of
Gothenburg database lab: schema design, views for graduation
checking, queue-handling triggers, and a Java/JDBC student portal.

**Author:** Abel Haile Magicho (Chalmers M.Sc. alumnus — portfolio /
learning project)

## Repository layout

```
tda357-database-lab/
├── README.md               this file
├── TESTING.md              what was actually run, with real outputs
├── task1/                  Task 1 — the given abstract schema, in SQL
│   ├── tables.sql            16 relations, keys, FKs, CHECKs
│   ├── inserts.sql           test data covering every corner case
│   └── views.sql             BasicInformation … PathToGraduation
├── task2/                  Task 2 — design: E-R, FDs, the perfect schema
│   ├── ER.png                E-R diagram (weak entity, ISA, many-to-at-most-one)
│   ├── make_er_diagram.py    generator script for ER.png (matplotlib)
│   ├── ER-schema.txt         schema derived from the E-R diagram
│   ├── FD.txt                Domain(...), functional dependencies, BCNF analysis
│   ├── FD-schema.txt         BCNF decomposition
│   ├── final-schema.txt      the "perfect schema" (ER + FD driven)
│   ├── tables.sql            final schema implemented
│   ├── inserts.sql           same test data, adapted (+ new relations)
│   └── views.sql             same views (unchanged definitions)
├── task3/                  Task 3 — registration triggers
│   ├── setup.sql             task2 tables+inserts+views, concatenated
│   ├── triggers.sql          CourseQueuePositions + INSTEAD OF triggers
│   └── tests.sql             13 commented tests, incl. all hint-list cases
└── task4/                  Task 4 — the student portal (Java + JDBC)
    └── StudentPortal.java
```

## A note on sources (reconstruction)

The assignment text references course files that were not available
when this project was built — the abstract schema `task1.txt`, a
provided `inserts.sql`, `runtests.sql`/`output.txt`, and the
`StudentPortal.java` stub. They were **reconstructed faithfully from
the assignment text itself**: the domain description, the exact view
specifications (names and column names), the deliverable lists, and
the demo test list in the portal section. Where the assignment left
a choice open, the choice made is documented under *Design notes*.

## How to run

You need PostgreSQL (developed and tested against PostgreSQL 16)
and, for Task 4, a JDK plus the PostgreSQL JDBC driver.

```bash
createdb tda357
```

Task 1:

```bash
psql -d tda357 -f task1/tables.sql -f task1/inserts.sql -f task1/views.sql
psql -d tda357 -c 'SELECT * FROM PathToGraduation;'
```

Task 2 (final schema, on a fresh database):

```bash
createdb tda357_v2
psql -d tda357_v2 -f task2/tables.sql -f task2/inserts.sql -f task2/views.sql
```

Task 3 (setup loads the Task 2 schema and data; then the triggers;
then the tests — exactly 4 errors are *expected*, one per failure
mode, each explained by a comment in tests.sql):

```bash
psql -d tda357_v2 -f task3/setup.sql -f task3/triggers.sql
psql -d tda357_v2 -f task3/tests.sql
```

Task 4 (the portal; run it against the Task 3 database):

```bash
cd task4
javac -cp postgresql.jar StudentPortal.java
java  -cp .:postgresql.jar StudentPortal 1234567890
```

At the `? >` prompt: `i` = info, `r <code>` = register,
`u <code>` = unregister, `quit` = exit. Connection settings come
from the environment: `DB_URL` (default
`jdbc:postgresql://localhost:5432/tda357`), `DB_USER` (default
`postgres`), `DB_PASS` (default empty), and the optional `DB_SOCKET`
(path of PostgreSQL's Unix socket file; connects via junixsocket
instead of TCP — see TESTING.md for why that mattered here).

## Design notes

**Hosting (Task 1 vs Task 2).** In Task 1, `Programs` carries a
single `host` attribute, as the abstract schema prescribes. The
domain description says several departments may *collaborate* on a
programme, so the Task 2 final schema replaces the attribute with
the many-to-many relation `HostedBy(program, department)` (4 rows
in the test data: CSEP is hosted by both CS and CE).

**The final schema (Task 2)** adds four relations over Task 1 —
`HostedBy`, `BranchRequirements` (the recommended-credit
requirement per branch, instead of a magic constant in the views),
`Employees` and `AdminOverrides` — and several UNIQUE constraints,
among them `Departments.abbr`, `Students.login`,
`Students(idnr, program)` and `WaitingList(course, position)`.

**A student can only choose a branch of their own programme.**
`Students` has `UNIQUE(idnr, program)` precisely so that
`StudentBranches(student, program)` can reference it, while
`StudentBranches(branch, program)` references
`Branches(name, program)`. The shared `program` column makes a
wrong-programme branch impossible to insert — no trigger needed.

**Waiting-list positions.** `WaitingList.position` is an *absolute*
integer: when a student joins a queue they get
`MAX(position) + 1` for that course, and positions are never
renumbered when somebody leaves. The relative place (1st, 2nd, …)
is derived in the `CourseQueuePositions` view with
`ROW_NUMBER() OVER (PARTITION BY course ORDER BY position)`.
Absolute positions keep a student's place stable and avoid
rewriting the whole queue on every departure; the view is also
what guarantees `UNIQUE(course, position)` is meaningful.

**"Full" and over-full courses (Task 3).** A limited course is full
when `count(Registered) >= seats`; unlimited courses are never
full. The unregister trigger promotes the longest-waiting student
only when the course *after* the deletion has room
(`count < seats`), so an administrator-created over-full course
(registered > seats) promotes nobody — exactly as the assignment's
hint list demands. Deleting a *waiting* entry never promotes
anybody.

**Task 4 names.** The assignment's privilege list speaks of tables
"Course" and "Student"; this schema names them `Courses` and
`Students`, following the Task 1 abstract schema. The portal only
ever SELECTs from `Courses` (for course names) and from the views
`BasicInformation`, `FinishedCourses`, `Registrations`,
`CourseQueuePositions` and `PathToGraduation`, and it INSERTs /
DELETEs only on the `Registrations` view, letting the Task 3
triggers enforce the rules. Trigger `RAISE EXCEPTION` texts are
printed verbatim as the failure reason (read from the server error
message, not the generic JDBC wrapper text).

## Testing

Everything was executed against a real PostgreSQL 16.15 in this
environment: all SQL files on empty databases, the trigger test
suite, and scripted portal demo sessions covering the assignment's
own demo list (including the over-full no-promotion case). See
**TESTING.md** for the actual outputs and transcripts.
