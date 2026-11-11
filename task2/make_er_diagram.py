#!/usr/bin/env python3
"""
Generates ER.png -- the E-R diagram for Task 2 of the TDA357/DIT621
Database Programming Assignment (Lab PM).

Drawn with matplotlib (no graphviz needed).  Chen-style notation:
rectangles = entities (double rectangle = weak entity, dashed =
extension entity), diamonds = relationships, triangle = ISA.
Attributes are listed inside the entity boxes, key attributes
underlined.  Cardinalities are written at the ends of the lines.

Author: Abel Haile Magicho
"""
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.patches import Rectangle, Polygon, FancyBboxPatch

fig = plt.figure(figsize=(18, 11.5), dpi=200)
ax = fig.add_axes([0, 0, 1, 1])
ax.set_xlim(0, 18)
ax.set_ylim(0, 11.5)
ax.axis("off")

KEY_TEXTS = []   # text artists of key attributes; underlined at the end


def entity(x, y, w, h, title, attrs, weak=False, dashed=False):
    ls = (0, (4, 2)) if dashed else "-"
    ax.add_patch(Rectangle((x - w / 2, y - h / 2), w, h, fill=True,
                           facecolor="#eaf1fb", edgecolor="black",
                           linewidth=1.4, linestyle=ls, zorder=2))
    if weak:  # double border for the weak entity
        ax.add_patch(Rectangle((x - w / 2 + 0.09, y - h / 2 + 0.09),
                               w - 0.18, h - 0.18, fill=False,
                               edgecolor="black", linewidth=1.0, zorder=2))
    ax.text(x, y + h / 2 - 0.28, title, ha="center", va="center",
            fontsize=11.5, fontweight="bold", zorder=3)
    ax.plot([x - w / 2, x + w / 2], [y + h / 2 - 0.52] * 2,
            color="black", lw=0.8, zorder=3)
    for i, (a, is_key) in enumerate(attrs):
        t = ax.text(x - w / 2 + 0.18, y + h / 2 - 0.88 - i * 0.31, a,
                    ha="left", va="center", fontsize=9.5, zorder=3)
        if is_key:
            KEY_TEXTS.append(t)


def diamond(x, y, w, h, label, double=False):
    pts = [(x, y + h / 2), (x + w / 2, y), (x, y - h / 2), (x - w / 2, y)]
    ax.add_patch(Polygon(pts, closed=True, fill=True, facecolor="#fdf3d8",
                         edgecolor="black", linewidth=1.3, zorder=2))
    if double:  # double diamond for the identifying relationship
        pts2 = [(x, y + h / 2 - 0.09), (x + w / 2 - 0.11, y),
                (x, y - h / 2 + 0.09), (x - w / 2 + 0.11, y)]
        ax.add_patch(Polygon(pts2, closed=True, fill=False,
                             edgecolor="black", linewidth=0.9, zorder=2))
    ax.text(x, y, label, ha="center", va="center", fontsize=8.6, zorder=3)


def line(x1, y1, x2, y2):
    ax.plot([x1, x2], [y1, y2], color="black", lw=1.1, zorder=1)


def card(x, y, text):
    ax.text(x, y, text, ha="center", va="center", fontsize=9,
            fontweight="bold", zorder=4)


def note(x, y, text, size=8.6, style="normal"):
    ax.text(x, y, text, ha="center", va="center", fontsize=size,
            style=style, zorder=4)

# ------------------------------- title -------------------------------
ax.text(9, 11.25, "E–R diagram: university students and courses",
        ha="center", fontsize=15, fontweight="bold")
ax.text(9, 10.9, "TDA357/DIT621 Lab PM -- Task 2.  Key attributes are "
        "underlined; cardinalities at line ends.",
        ha="center", fontsize=9.5, style="italic")

# ------------------------------- entities ------------------------------
entity(2.3, 9.55, 3.0, 1.50, "Department",
       [("name", 1), ("abbr  (unique)", 0)])
entity(6.6, 9.55, 3.0, 1.50, "Program",
       [("name", 1), ("abbr", 0)])
entity(11.7, 9.70, 3.3, 1.50, "Branch  (weak entity)",
       [("name  (discriminator)", 1)], weak=True)
entity(6.6, 6.1, 3.3, 2.10, "Student",
       [("idnr", 1), ("name", 0), ("login (unique)", 0), ("program →", 0)])
entity(13.2, 6.1, 3.3, 2.10, "Course",
       [("code", 1), ("name", 0), ("credits", 0), ("givenBy →", 0)])
entity(13.2, 3.5, 3.1, 1.50, "LimitedCourse",
       [("code  (ISA Course)", 1), ("seats", 0)])
entity(16.35, 3.55, 2.7, 1.05, "Classification",
       [("name", 1)])
entity(2.3, 3.60, 3.0, 1.75, "Employee (extension)",
       [("idnr", 1), ("name", 0), ("department →", 0)], dashed=True)

# ----------------------------- relationships ---------------------------
# HostedBy: Program M:N Department
diamond(4.45, 9.55, 1.25, 0.85, "HostedBy")
line(3.80, 9.55, 3.83, 9.55)   # Department -- diamond
line(5.07, 9.55, 5.10, 9.55)   # diamond -- Program
card(4.02, 9.92, "N"); card(4.90, 9.92, "M")

# BelongsTo (identifying, double diamond): Program 1:N Branch
diamond(9.15, 9.7, 1.35, 0.9, "BelongsTo", double=True)
line(8.1, 9.55, 8.48, 9.7)
line(9.82, 9.7, 10.05, 9.7)
card(8.35, 10.0, "1"); card(9.95, 10.05, "N")
note(9.15, 8.95, "identifying relationship\nof the weak entity", size=8)

# Follows: Program 1 -- N Student (many-to-at-most-one)
diamond(6.6, 8.15, 1.3, 0.85, "Follows")
line(6.6, 8.80, 6.6, 8.58)
line(6.6, 7.72, 6.6, 7.15)
card(6.95, 8.75, "1"); card(6.95, 7.35, "N")

# Chooses: Student N -- at most one Branch (many-to-at-most-one)
diamond(9.75, 7.75, 1.35, 0.85, "Chooses")
line(8.05, 6.95, 9.08, 7.6)
line(10.42, 7.9, 10.9, 8.95)
card(8.35, 7.45, "N"); card(10.80, 8.40, "≤1")
note(11.45, 7.80, "many-to-at-most-one", size=8.4, style="italic")

# GivenBy: Course N -- 1 Department (many-to-at-most-one)
diamond(4.35, 4.95, 1.35, 0.85, "GivenBy")
line(3.1, 8.80, 4.1, 5.37)
line(5.02, 4.95, 11.55, 5.45)
card(3.35, 7.4, "1"); card(11.15, 5.10, "N")
note(4.90, 4.30, "many-to-at-most-one", size=8.4, style="italic")

# WorksIn: Employee N -- 1 Department
diamond(1.45, 6.55, 1.25, 0.8, "WorksIn")
line(1.95, 8.80, 1.55, 6.95)
line(1.35, 6.15, 2.1, 4.48)
card(1.15, 7.9, "1"); card(1.05, 5.2, "N")

# Student--Course relationships
diamond(10.05, 6.75, 1.45, 0.72, "RegisteredTo")
line(8.25, 6.75, 9.32, 6.75); line(10.78, 6.75, 11.55, 6.75)
note(11.16, 6.98, "M:N", size=8.4)
diamond(10.05, 6.05, 1.45, 0.72, "HasTaken")
line(8.25, 6.05, 9.32, 6.05); line(10.78, 6.05, 11.55, 6.05)
note(10.05, 5.52, "M:N -- attribute: grade", size=8)
diamond(10.05, 4.62, 1.45, 0.72, "WaitingFor")
line(8.25, 5.35, 9.32, 4.75); line(10.78, 4.5, 11.55, 5.3)
note(10.05, 4.02, "M:N -- attribute: position", size=8)

# ClassifiedAs: Course M:N Classification
diamond(15.65, 6.15, 1.3, 0.8, "ClassifiedAs")
line(14.85, 6.15, 15.0, 6.15)
line(15.9, 5.75, 16.2, 4.08)
card(15.65, 6.68, "M:N")

# Prerequisite: Course M:N itself (roles course / prereq)
diamond(16.55, 8.75, 1.35, 0.85, "Prerequisite")
line(14.3, 7.15, 15.9, 8.5)
line(16.9, 8.32, 14.85, 6.6)
card(15.3, 7.9, "course"); card(16.15, 7.35, "prereq")
note(16.55, 8.05, "M:N", size=8.6, style="italic")

# ISA: Course --ISA--> LimitedCourse
tri = Polygon([(13.2, 5.05), (12.55, 4.38), (13.85, 4.38)], closed=True,
              fill=True, facecolor="#fde8e8", edgecolor="black",
              linewidth=1.3, zorder=2)
ax.add_patch(tri)
ax.text(13.2, 4.56, "ISA", ha="center", va="center", fontsize=8.6, zorder=3)
line(13.2, 4.38, 13.2, 4.25)

# ------------------------------- note box ------------------------------
ax.add_patch(FancyBboxPatch((0.35, 0.35), 9.3, 2.0,
                            boxstyle="round,pad=0.08", fill=True,
                            facecolor="#f4f4f4", edgecolor="black",
                            linewidth=0.9, zorder=1))
note(5.0, 2.12, "Further many-to-many relationships (translated in "
     "ER-schema.txt, diamonds omitted for readability):", size=8.8)
note(5.0, 1.78, "MandatoryForProgram and MandatoryForBranch: Course -- "
     "Program / Branch;   RecommendedForBranch: Course -- Branch", size=8.8)
note(5.0, 1.44, "BranchRequirements: the recommended-credit amount is an "
     "attribute of Branch.   AdminOverrides: bookkeeping for", size=8.8)
note(5.0, 1.10, "administrator-created registrations (Student -- Course).",
     size=8.8)
note(5.0, 0.72, "Weak entity: Branch (double box, identifying relationship "
     "BelongsTo).   ISA: LimitedCourse is a subclass of Course.",
     size=8.8)

# Underline the key attributes: matplotlib mathtext has no
# \underline, so measure the rendered text and draw the line.
fig.canvas.draw()
renderer = fig.canvas.get_renderer()
inv = ax.transData.inverted()
for t in KEY_TEXTS:
    bb = t.get_window_extent(renderer=renderer)
    # underline just the attribute word itself (strip any " (...)" tail)
    txt = t.get_text()
    word = txt.split(" ")[0]
    frac = len(word) / max(len(txt), 1)
    x0, y0 = inv.transform((bb.x0, bb.y0))
    x1, _ = inv.transform((bb.x0 + bb.width * frac, bb.y0))
    ax.plot([x0, x1], [y0 + 0.015, y0 + 0.015], color="black", lw=1.0,
            zorder=4)

plt.savefig("ER.png")
print("ER.png written")
