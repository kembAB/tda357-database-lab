/* =====================================================================
 * TDA357 / DIT621 -- Database Programming Assignment (Lab PM), LP3 2019
 * Task 4: Front end application -- StudentPortal (Java + JDBC)
 * Author: Abel Haile Magicho
 *
 * A command line portal through which a student can inspect
 * his/her own information and register/unregister for courses.
 *
 * Usage:
 *     java StudentPortal <idnr>
 * Modes (typed at the "? >" prompt):
 *     i            show all information for the student
 *     r <code>     register for course <code>
 *     u <code>     unregister from course <code>
 *     quit         exit
 *
 * Compilation (the PostgreSQL JDBC driver must be on the class
 * path; download it from https://jdbc.postgresql.org or use the
 * system package, e.g. Debian's libpostgresql-jdbc-java):
 *     javac -cp postgresql.jar StudentPortal.java
 *     java  -cp .:postgresql.jar StudentPortal 1234567890
 *
 * Connection settings are taken from the environment, with local
 * defaults:
 *     DB_URL   default jdbc:postgresql://localhost:5432/tda357
 *     DB_USER  default postgres
 *     DB_PASS  default (empty)
 *     DB_SOCKET  optional; if set to the path of PostgreSQL's Unix
 *              socket file (e.g. /var/run/postgresql/.s.PGSQL.5432),
 *              the connection is made over that socket instead of
 *              TCP, using the junixsocket factory
 *              (https://kohlschutter.github.io/junixsocket/) -- put
 *              junixsocket-common and junixsocket-native-common on
 *              the class path in that case.  Useful on hosts where
 *              TCP connections to the server are unavailable.
 *
 * Privileges: the program behaves as if it only had the
 * privileges listed in the assignment.  It runs SELECTs on the
 * tables Courses and Students and on the views BasicInformation,
 * FinishedCourses, Registrations, CourseQueuePositions and
 * PathToGraduation, and it INSERTs/DELETEs only on the view
 * Registrations (the triggers of Task 3 do the real work on the
 * underlying tables).  Note on names: the assignment's privilege
 * list calls the base tables "Course" and "Student"; in this
 * project's schema they are named Courses and Students (the
 * table names of the Task 1 abstract schema).  Of these two the
 * portal actually only reads Courses (to print course names next
 * to the codes in the views); all student data comes from the
 * views.
 * ===================================================================== */

import java.math.BigDecimal;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.Scanner;

import org.postgresql.util.PSQLException;

public class StudentPortal {

    private final Connection conn;
    private final String idnr;          // the "logged on" student

    public StudentPortal(Connection conn, String idnr) {
        this.conn = conn;
        this.idnr = idnr;
    }

    /* ------------------------- modes ------------------------- */

    /* Info: print everything the specification asks for. */
    public void info() throws SQLException {
        String name = null, login = null, program = null, branch = null;

        try (PreparedStatement ps = conn.prepareStatement(
                "SELECT name, login, program, branch "
              + "FROM BasicInformation WHERE idnr = ?")) {
            ps.setString(1, idnr);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    name    = rs.getString(1);
                    login   = rs.getString(2);
                    program = rs.getString(3);
                    branch  = rs.getString(4);
                }
            }
        }
        if (name == null) {
            System.out.println("No student with identification number " + idnr);
            return;
        }

        System.out.println("Information for student " + idnr);
        System.out.println("-------------------------------------");
        System.out.println("Name: " + name);
        System.out.println("Student ID: " + login);
        System.out.println("Line: " + program);
        System.out.println("Branch: " + (branch == null ? "-" : branch));
        System.out.println();

        // Read (finished) courses, with grades.
        System.out.println("Read courses (name (code), credits: grade):");
        try (PreparedStatement ps = conn.prepareStatement(
                "SELECT C.name, F.course, F.credits, F.grade "
              + "FROM FinishedCourses F JOIN Courses C ON C.code = F.course "
              + "WHERE F.student = ? ORDER BY F.course")) {
            ps.setString(1, idnr);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    System.out.println(" " + rs.getString(1)
                        + " (" + rs.getString(2).trim() + "), "
                        + fmt(rs.getBigDecimal(3)) + "p: " + rs.getString(4));
                }
            }
        }
        System.out.println();

        // Registered and waiting courses, with queue positions.
        System.out.println("Registered courses (name (code): status):");
        try (PreparedStatement ps = conn.prepareStatement(
                "SELECT C.name, R.course, R.status, Q.place "
              + "FROM Registrations R JOIN Courses C ON C.code = R.course "
              + "LEFT JOIN CourseQueuePositions Q "
              + "  ON Q.course = R.course AND Q.student = R.student "
              + "WHERE R.student = ? ORDER BY R.course")) {
            ps.setString(1, idnr);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    StringBuilder line = new StringBuilder(" ")
                        .append(rs.getString(1))
                        .append(" (").append(rs.getString(2).trim())
                        .append("): ").append(rs.getString(3));
                    if ("waiting".equals(rs.getString(3))) {
                        line.append(" as nr ").append(rs.getInt(4));
                    }
                    System.out.println(line);
                }
            }
        }
        System.out.println();

        // The path-to-graduation summary.
        try (PreparedStatement ps = conn.prepareStatement(
                "SELECT totalCredits, mathCredits, researchCredits, "
              + "       seminarCourses, qualified "
              + "FROM PathToGraduation WHERE student = ?")) {
            ps.setString(1, idnr);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    System.out.println("Seminar courses taken: " + rs.getInt(4));
                    System.out.println("Math credits taken: " + fmt(rs.getBigDecimal(2)));
                    System.out.println("Research credits taken: " + fmt(rs.getBigDecimal(3)));
                    System.out.println("Total credits taken: " + fmt(rs.getBigDecimal(1)));
                    System.out.println("Fulfills the requirements for graduation: "
                                       + (rs.getBoolean(5) ? "yes" : "no"));
                }
            }
        }
        System.out.println("-------------------------------------");
    }

    /* Register: insert into the Registrations view; the Task 3
     * trigger checks the rules and either registers the student,
     * puts him/her on the waiting list, or raises an exception
     * whose message is the reason the registration failed. */
    public void register(String course) {
        try (PreparedStatement ps = conn.prepareStatement(
                "INSERT INTO Registrations (student, course, status) "
              + "VALUES (?, ?, 'registered')")) {
            ps.setString(1, idnr);
            ps.setString(2, course);
            ps.executeUpdate();
        } catch (SQLException e) {
            System.out.println(errorText(e));
            return;
        }

        // Find out what actually happened: registered or waiting?
        try (PreparedStatement ps = conn.prepareStatement(
                "SELECT status FROM Registrations "
              + "WHERE student = ? AND course = ?")) {
            ps.setString(1, idnr);
            ps.setString(2, course);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next() && "waiting".equals(rs.getString(1))) {
                    System.out.println("Course " + course + " " + courseName(course)
                        + " is full, you are put in the waiting list.");
                    return;
                }
            }
        } catch (SQLException e) {
            System.out.println(errorText(e));
            return;
        }
        System.out.println("You are now successfully registered to course "
                           + course + " " + courseName(course) + "!");
    }

    /* Unregister: delete from the Registrations view; the Task 3
     * trigger removes the registration and, if a place was freed
     * on a course with a queue, promotes the longest-waiting
     * student (unless the course is still over-full). */
    public void unregister(String course) {
        String statusBefore = null;
        try (PreparedStatement ps = conn.prepareStatement(
                "SELECT status FROM Registrations "
              + "WHERE student = ? AND course = ?")) {
            ps.setString(1, idnr);
            ps.setString(2, course);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    statusBefore = rs.getString(1);
                }
            }
        } catch (SQLException e) {
            System.out.println(errorText(e));
            return;
        }

        if (statusBefore == null) {
            System.out.println("You are not registered or waiting for course "
                               + course + ".");
            return;
        }

        try (PreparedStatement ps = conn.prepareStatement(
                "DELETE FROM Registrations WHERE student = ? AND course = ?")) {
            ps.setString(1, idnr);
            ps.setString(2, course);
            ps.executeUpdate();
        } catch (SQLException e) {
            System.out.println(errorText(e));
            return;
        }
        if ("waiting".equals(statusBefore)) {
            System.out.println("You are now removed from the waiting list for course "
                               + course + " " + courseName(course) + ".");
        } else {
            System.out.println("You are now unregistered from course "
                               + course + " " + courseName(course) + ".");
        }
    }

    /* ------------------------- helpers ------------------------- */

    private String courseName(String course) {
        try (PreparedStatement ps = conn.prepareStatement(
                "SELECT name FROM Courses WHERE code = ?")) {
            ps.setString(1, course);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return rs.getString(1);
                }
            }
        } catch (SQLException e) {
            /* fall through: name is decorative only */
        }
        return "";
    }

    /* The message of the error as the server phrased it (for the
     * triggers this is exactly the RAISE EXCEPTION text). */
    private static String errorText(SQLException e) {
        if (e instanceof PSQLException) {
            PSQLException pe = (PSQLException) e;
            if (pe.getServerErrorMessage() != null) {
                return pe.getServerErrorMessage().getMessage();
            }
        }
        return e.getMessage();
    }

    /* Credits without unnecessary decimals: 5.0 -> "5", 7.5 -> "7.5". */
    private static String fmt(BigDecimal x) {
        return x == null ? "0" : x.stripTrailingZeros().toPlainString();
    }

    /* ------------------------- main ------------------------- */

    public static void main(String[] args) throws Exception {
        if (args.length < 1) {
            System.out.println("Usage: java StudentPortal <student id number>");
            return;
        }
        String idnr = args[0];

        String url  = System.getenv().getOrDefault(
                          "DB_URL", "jdbc:postgresql://localhost:5432/tda357");
        String user = System.getenv().getOrDefault("DB_USER", "postgres");
        String pass = System.getenv().getOrDefault("DB_PASS", "");

        // Optional: connect over PostgreSQL's Unix socket file
        // instead of TCP (via junixsocket), when DB_SOCKET is set.
        String socket = System.getenv("DB_SOCKET");
        if (socket != null && !socket.isEmpty()) {
            String sep = url.contains("?") ? "&" : "?";
            url += sep + "socketFactory=org.newsclub.net.unix.AFUNIXSocketFactory$FactoryArg"
                       + "&socketFactoryArg=" + socket;
        }

        Class.forName("org.postgresql.Driver");
        try (Connection conn = DriverManager.getConnection(url, user, pass)) {
            StudentPortal portal = new StudentPortal(conn, idnr);

            System.out.println("Welcome!");
            Scanner in = new Scanner(System.in);
            while (true) {
                System.out.println("Please choose a mode of operation:");
                System.out.print("? > ");
                System.out.flush();
                if (!in.hasNextLine()) {
                    break;                       // EOF: scripted run
                }
                String line = in.nextLine().trim();
                if (line.equals("quit")) {
                    break;
                } else if (line.equals("i")) {
                    portal.info();
                } else if (line.startsWith("r ") && line.length() > 2) {
                    portal.register(line.substring(2).trim().toUpperCase());
                } else if (line.startsWith("u ") && line.length() > 2) {
                    portal.unregister(line.substring(2).trim().toUpperCase());
                } else if (!line.isEmpty()) {
                    System.out.println("Unknown command. Use: i, r <code>, "
                                       + "u <code>, quit");
                }
                System.out.println();
            }
            System.out.println("Goodbye!");
        }
    }
}
