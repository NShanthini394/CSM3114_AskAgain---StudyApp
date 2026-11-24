"""Regenerate AskAgain v1.7.4 monochrome design documents.

Run from any directory: python tool/create_wireframes.py
All three deliverables are written to output/pdf/. Sketches are drawn directly
with ReportLab; no external illustration assets are required. The PNG is a
Poppler render of the full PDF's first page, rather than an independent layout.
Screen inventory: docs/CODE_GUIDE.md. Labels/routes checked against lib/ui/.
"""

from pathlib import Path
import shutil
import subprocess
import tempfile

from reportlab.lib import colors
from reportlab.lib.pagesizes import A4, landscape
from reportlab.pdfbase.pdfmetrics import stringWidth
from reportlab.pdfgen import canvas


ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "output" / "pdf" / "AskAgain_Wireframes_and_Navigation_Flow.pdf"
PROPOSAL_OUTPUT = ROOT / "output" / "pdf" / "AskAgain_Proposal_Wireframes_Selection.pdf"
NAVIGATION_OUTPUT = ROOT / "output" / "pdf" / "AskAgain_Navigation_Flow.png"
OUTPUT.parent.mkdir(parents=True, exist_ok=True)
PAGE_W, PAGE_H = landscape(A4)
INK = colors.HexColor("#20242b")
MID = colors.HexColor("#737983")
PALE = colors.HexColor("#f2f3f5")


def fit_lines(text, width, size=8, font="Helvetica", max_lines=3):
    words = text.split()
    lines = []
    line = ""
    for word in words:
        candidate = f"{line} {word}".strip()
        if stringWidth(candidate, font, size) <= width:
            line = candidate
        else:
            if line:
                lines.append(line)
            line = word
    if line:
        lines.append(line)
    if len(lines) > max_lines:
        lines = lines[:max_lines]
        while stringWidth(lines[-1] + "...", font, size) > width and lines[-1]:
            lines[-1] = lines[-1][:-1]
        lines[-1] += "..."
    return lines


def label(c, text, x, y, width, size=8, leading=11, max_lines=3, font="Helvetica"):
    c.setFont(font, size)
    c.setFillColor(INK)
    lines = fit_lines(text, width, size, font, max_lines)
    for line in lines:
        c.drawString(x, y, line)
        y -= leading
    return y


def box(c, x, y, width, height, title, fill=colors.white, size=8):
    c.setFillColor(fill)
    c.setStrokeColor(MID)
    c.roundRect(x, y - height, width, height, 5, stroke=1, fill=1)
    label(c, title, x + 8, y - 14, width - 16, size=size, max_lines=2)


def flow_node(c, x, y, w, h, title, subtitle=""):
    c.setFillColor(PALE)
    c.setStrokeColor(INK)
    c.roundRect(x, y, w, h, 6, stroke=1, fill=1)
    label(c, title, x + 10, y + h - 17, w - 20, 9, font="Helvetica-Bold", max_lines=2)
    if subtitle:
        label(c, subtitle, x + 10, y + 12, w - 20, 7, max_lines=2)


def arrow(c, x1, y1, x2, y2):
    c.setStrokeColor(MID)
    c.setFillColor(MID)
    c.line(x1, y1, x2, y2)
    if abs(x2 - x1) > abs(y2 - y1):
        direction = 1 if x2 > x1 else -1
        p = c.beginPath()
        p.moveTo(x2, y2)
        p.lineTo(x2 - 6 * direction, y2 + 3)
        p.lineTo(x2 - 6 * direction, y2 - 3)
    else:
        direction = 1 if y2 > y1 else -1
        p = c.beginPath()
        p.moveTo(x2, y2)
        p.lineTo(x2 - 3, y2 - 6 * direction)
        p.lineTo(x2 + 3, y2 - 6 * direction)
    p.close()
    c.drawPath(p, fill=1, stroke=0)


def navigation_page(c):
    c.setFillColor(INK)
    c.setFont("Helvetica-Bold", 20)
    c.drawString(30, PAGE_H - 38, "AskAgain - Navigation Flow")
    c.setFont("Helvetica", 9)
    c.drawString(30, PAGE_H - 55, "Arrows show the principal routes; the four tab destinations share one Bottom Navigation Bar.")
    c.drawString(30, PAGE_H - 70, "Principal routes only; the 25 screen widgets are numbered in the reference sketches. Dialogs are additional UI states.")

    # Direct returning-user bypass, above the onboarding row.
    c.saveState()
    c.setDash(4, 3)
    c.setStrokeColor(MID)
    c.lines([(90, 497, 90, 510), (90, 510, 707, 510)])
    arrow(c, 707, 510, 707, 497)
    c.restoreState()
    label(c, "returning signed-in user", 301, 514, 200, 7, max_lines=1)

    flow_node(c, 34, 450, 112, 47, "Splash", "load app")
    flow_node(c, 181, 450, 112, 47, "Authentication", "sign in / guest")
    flow_node(c, 328, 450, 112, 47, "Profile Setup", "first account")
    flow_node(c, 475, 450, 112, 47, "Tutorial", "Next / Skip")
    flow_node(c, 622, 450, 170, 47, "App Shell", "Home + Bottom Navigation Bar")
    for x in (146, 293, 440, 587):
        arrow(c, x, 473, x + 35, 473)

    tabs = [
        (34, "Home", "due, subjects, exams"),
        (233, "Subjects", "folders and chapters"),
        (432, "Revision", "queue and practice"),
        (631, "Progress", "mastery and sessions"),
    ]
    for x, title, subtitle in tabs:
        flow_node(c, x, 359, 174, 49, title, subtitle)
    arrow(c, 707, 450, 707, 421)
    c.setStrokeColor(MID)
    c.line(121, 421, 718, 421)
    for x, _, _ in tabs:
        arrow(c, x + 87, 421, x + 87, 408)

    flow_node(c, 34, 279, 174, 53, "Create from Notes", "PDF / paste -> AI draft")
    flow_node(c, 233, 279, 174, 53, "Subject Detail", "chapters, bank, create")
    flow_node(c, 432, 279, 174, 53, "Choose Practice", "3 answer modes")
    flow_node(c, 631, 279, 174, 53, "Revision History", "open session details")
    for x in (121, 320, 519, 718):
        arrow(c, x, 359, x, 332)

    flow_node(c, 34, 201, 174, 53, "Review Question Set", "edit -> finalise -> bank")
    flow_node(c, 233, 201, 174, 53, "Chapter / Question Bank", "Question Editor / Read & Learn")
    flow_node(c, 432, 201, 174, 53, "Practice Session", "rate answer -> progress")
    flow_node(c, 631, 201, 174, 53, "Session Details", "review results")
    for x in (121, 320, 519, 718):
        arrow(c, x, 279, x, 254)

    flow_node(c, 432, 130, 174, 43, "Needs Attention", "filtered weak questions")
    # Side route avoids the practice nodes, making this a direct Revision link.
    c.setStrokeColor(MID)
    c.lines([(606, 383, 618, 383), (618, 383, 618, 151)])
    arrow(c, 618, 151, 606, 151)
    label(c, "weak areas", 548, 346, 65, 7, max_lines=1)
    arrow(c, 519, 173, 519, 201)
    label(c, "practise", 526, 184, 70, 7, max_lines=1)

    # Header routes share one explicitly connected, subtle container.
    c.saveState()
    c.setStrokeColor(MID)
    c.setDash(4, 3)
    c.roundRect(27, 28, 785, 80, 6, stroke=1, fill=0)
    c.lines([(792, 473, 823, 473), (823, 473, 823, 115), (823, 115, 790, 115)])
    arrow(c, 790, 115, 790, 108)
    c.restoreState()
    label(c, "App Bar / Header Actions (accessible from main tabs)", 40, 94, 650, 9, font="Helvetica-Bold", max_lines=1)
    flow_node(c, 40, 38, 222, 44, "Exams", "-> Exam Editor")
    flow_node(c, 284, 38, 242, 44, "Profile & Settings", "-> Tutorial / About")
    flow_node(c, 548, 38, 251, 44, "Generation Status (Dialog)", "retry / review; Close / Cancel")
    c.setFont("Helvetica", 8)
    c.setFillColor(MID)
    c.drawRightString(PAGE_W - 30, 19, "Navigation flow | 1")
    c.showPage()


# Each tuple is a screen name, its app-bar title, a list of sketch blocks, and
# whether the four-tab navigation appears on that screen.
SCREENS = [
    ("Splash", "AskAgain", [("hero", "App logo"), ("heading", "AskAgain"), ("progress", "Loading notebook")], False),
    ("Sign In / Register", "AskAgain", [("hero", "App logo"), ("heading", "Welcome to AskAgain"), ("button", "Continue with Google"), ("field", "Email"), ("field", "Password"), ("button", "Sign In / Create Account"), ("link", "Try as Guest")], False),
    ("Profile Setup", "Set up Your Profile", [("heading", "How Should We Address You?"), ("field", "Display Name"), ("field", "Education Level"), ("button", "Start Learning")], False),
    ("Tutorial", "Getting Started       Skip", [("progress", "Step 1 of 4"), ("hero", "Feature illustration"), ("heading", "Organise Your Subjects"), ("text", "Short explanation + tip"), ("button", "Back              Next")], False),
    ("Home", "AskAgain        AI   Exam   Profile", [("card", "Today's Revision - questions due"), ("button", "Start Revision"), ("button", "Create Questions from Notes"), ("heading", "Your Subjects"), ("grid", "Subject folder cards"), ("heading", "Upcoming Exams"), ("list", "Exam goal list")], True),
    ("Subjects", "Subjects       AI   Exam   Profile", [("button", "+ Add Subject"), ("grid", "Subject folder cards")], True),
    ("Subject Detail", "Subject Name", [("button", "Read & Learn"), ("button", "Practice"), ("heading", "Chapters"), ("link", "Add chapter"), ("list", "Chapter / Unassigned chapter"), ("button", "View Questions"), ("button", "Add Question"), ("link", "Note Reviews in top bar")], False),
    ("Chapter Detail", "Chapter Name", [("heading", "Chapter Name"), ("button", "Read & Learn"), ("button", "Practice"), ("text", "Question count"), ("button", "Manage Questions"), ("button", "Add Question")], False),
    ("Add Question Choice", "Add Question", [("heading", "How Would You Like to Create Questions?"), ("list", "Write Q&A Manually"), ("list", "Upload PDF Notes with AI"), ("list", "Paste Notes with AI")], False),
    ("Question Editor", "New / Edit Question", [("field", "Question"), ("field", "Answer"), ("field", "Chapter"), ("button", "Save Question")], False),
    ("Create from Notes", "Create from Notes", [("field", "Subject"), ("field", "Chapter / Add chapter"), ("button", "Choose PDF / Paste Notes"), ("field", "Content mode"), ("field", "Pages / focus topic (optional)"), ("field", "Question count / difficulty"), ("field", "Q&A language (answer language)"), ("text", "Estimated AI requests"), ("button", "Generate Questions")], False),
    ("Generation Status (Dialog)", "AskAgain        AI   Exam   Profile", [("card", "Current main tab behind dialog"), ("modal", "Creating Questions\nProgress bar + batches\nClose / Cancel (running)\nRetry / Dismiss (paused)\nReview Questions (ready)")], True),
    ("Review Question Set", "Review Question Set", [("heading", "Document title - draft"), ("button", "Add a Question"), ("card", "Question + source page"), ("card", "Question + source page"), ("button", "Finalise for Revision")], False),
    ("Question Bank", "Questions / subject filter", [("button", "Read & Learn / Move to Chapter"), ("field", "Search questions"), ("field", "Topic / Difficulty or progress"), ("list", "Questions - select / edit / delete"), ("list", "Questions - select / edit / delete")], False),
    ("Read & Learn", "Learn & Recall", [("progress", "Reviewed count"), ("card", "Flashcard question / reveal answer"), ("text", "Source page"), ("button", "Show Answer / Rate Recall")], False),
    ("Revision Tab", "Revision       AI   Exam   Profile", [("heading", "Revision Queue"), ("text", "Questions due today"), ("button", "Open Revision"), ("heading", "Needs Attention"), ("list", "Forgot / Confused Concepts"), ("heading", "Revise by Subject"), ("grid", "Subject folder cards")], True),
    ("Practice", "Choose Practice", [("text", "Due-only title: Choose Revision Mode"), ("heading", "Questions Due (due-only)"), ("text", "Choose how to practise"), ("button", "Written / Problem Solving"), ("button", "Fill in the Blanks"), ("button", "Matching")], False),
    ("Revision Session", "Revision", [("progress", "Question 1 of N"), ("heading", "Question prompt"), ("field", "Answer / blank / matching"), ("button", "Submit / Show Answer"), ("card", "Expected Answer + Source"), ("button", "Recall Rating")], False),
    ("Needs Attention", "Forgot / Confused Concepts", [("heading", "Filtered question count"), ("button", "Learn these questions"), ("button", "Practise these questions"), ("list", "Question - subject / chapter"), ("list", "Question - subject / chapter")], False),
    ("Progress", "Progress       AI   Exam   Profile", [("text", "Question / due / study-day totals"), ("heading", "Subject Progress"), ("card", "Mastery by subject"), ("heading", "Recent Sessions"), ("list", "Session list"), ("button", "View History")], True),
    ("Revision History", "Revision History", [("heading", "Completed Sessions"), ("list", "Date - subject - reviewed"), ("list", "Date - subject - reviewed"), ("list", "Date - subject - reviewed")], False),
    ("Session Details", "Session Details", [("heading", "Subject - date"), ("text", "Reviewed / need practice"), ("list", "Question results"), ("list", "Question results")], False),
    ("Exam Goals", "Exam Goals", [("button", "Add exam"), ("list", "Exam - subject - date"), ("button", "Revise Subject / Edit / Delete")], False),
    ("Exam Editor", "Add Exam / Edit Exam", [("field", "Exam Name"), ("field", "Subject"), ("field", "Date"), ("button", "Save exam")], False),
    ("Profile & Settings", "Profile and Settings", [("field", "Name / Education Level"), ("field", "Appearance / Font / Text Size"), ("card", "Reading Preview"), ("field", "Daily Reminder / Quiet Hours"), ("button", "Replay Tutorial"), ("button", "About AskAgain"), ("link", "Sign In / Log Out / Delete")], False),
    ("About AskAgain", "About AskAgain", [("hero", "App logo + version"), ("heading", "Purpose and SDG 4"), ("text", "Study features"), ("text", "Developer / academic credits"), ("button", "Third-Party Packages & Licenses"), ("text", "Study accuracy note")], False),
    ("Note Reviews", "Note Reviews", [("heading", "Documents / Question Sets"), ("list", "Draft / completed set - tap to open"), ("list", "Draft / completed set - tap to open")], False),
]


def block(c, kind, text, x, top, width):
    heights = {"hero": 70, "heading": 38, "text": 34, "field": 37,
               "button": 34, "card": 56, "grid": 74, "list": 37,
               "progress": 27, "link": 23, "modal": 146}
    height = heights[kind]
    if kind == "heading":
        label(c, text, x, top - 17, width, 9, font="Helvetica-Bold", max_lines=2)
        c.setStrokeColor(MID)
        c.line(x, top - 36, x + width, top - 36)
    elif kind == "text":
        label(c, text, x + 2, top - 12, width - 4, 8, max_lines=3)
    elif kind == "link":
        label(c, text, x + 2, top - 12, width - 4, 8, max_lines=2)
    elif kind == "progress":
        label(c, text, x, top - 9, width, 7, max_lines=1)
        c.setFillColor(PALE)
        c.rect(x, top - 22, width, 5, fill=1, stroke=0)
        c.setFillColor(MID)
        c.rect(x, top - 22, width * 0.4, 5, fill=1, stroke=0)
    elif kind == "hero":
        box(c, x + width * 0.27, top - 2, width * 0.46, height - 7, text, PALE, 7)
    elif kind == "grid":
        box(c, x, top - 1, (width - 8) / 2, height - 7, text, PALE, 7)
        box(c, x + (width + 8) / 2, top - 1, (width - 8) / 2, height - 7, text, PALE, 7)
    elif kind == "modal":
        lines = text.split("\n")
        box(c, x + 8, top, width - 16, height, lines[0], PALE, 9)
        for j, line in enumerate(lines[1:]):
            label(c, line, x + 20, top - 48 - j * 26, width - 40, 8)
    else:
        fill = PALE if kind in ("button", "card", "list") else colors.white
        box(c, x, top - 1, width, height - 6, text, fill, 8)
    return top - height - 6


def phone(c, left, top, name, appbar, blocks, tabs, number=None):
    width, height = 220, 455
    x, y = left + 8, top - height
    c.setStrokeColor(INK)
    c.setFillColor(colors.white)
    c.setLineWidth(1.3)
    c.roundRect(x, y, width, height, 12, stroke=1, fill=1)
    c.setLineWidth(1)
    c.setFillColor(PALE)
    c.roundRect(x + 1, top - 53, width - 2, 52, 10, stroke=0, fill=1)
    c.setFont("Helvetica", 6)
    c.setFillColor(INK)
    c.drawString(x + 12, top - 12, "9:41")
    c.drawRightString(x + width - 12, top - 12, "signal  battery")
    label(c, appbar, x + 12, top - 35, width - 24, 8, max_lines=1, font="Helvetica-Bold")
    c.setStrokeColor(MID)
    c.line(x + 1, top - 54, x + width - 1, top - 54)
    body_top = top - 64
    body_bottom = y + (43 if tabs else 17)
    available = body_top - body_bottom
    total = sum({"hero": 76, "heading": 44, "text": 40, "field": 43,
                 "button": 40, "card": 62, "grid": 80, "list": 43,
                 "progress": 33, "link": 29, "modal": 152}[kind] for kind, _ in blocks)
    scale = min(1.0, available / total) if total else 1
    c.saveState()
    if scale < 1:
        c.translate(x + 12, body_top)
        c.scale(1, scale)
        c.translate(-(x + 12), -body_top)
    current = body_top
    for kind, text in blocks:
        current = block(c, kind, text, x + 12, current, width - 24)
    c.restoreState()
    if tabs:
        c.setFillColor(PALE)
        c.rect(x + 1, y + 1, width - 2, 39, stroke=0, fill=1)
        c.setFont("Helvetica", 7)
        c.setFillColor(INK)
        for i, title in enumerate(("Home", "Subjects", "Revision", "Progress")):
            c.drawCentredString(x + 28 + i * 55, y + 15, title)
    c.setFillColor(INK)
    c.setFont("Helvetica-Bold", 11)
    title = f"{number:02d}  {name}" if number is not None else name
    c.drawCentredString(x + width / 2, top + 20, title)


# Number only the 25 screen widgets from docs/CODE_GUIDE.md. The Revision
# tab is embedded in HomePage; the generation modal is not a screen widget.
BY_NAME = {screen[0]: screen for screen in SCREENS}
INVENTORY = [
    "Splash", "Sign In / Register", "Profile Setup", "Tutorial", "Home",
    "Subjects", "Subject Detail", "Chapter Detail", "Add Question Choice",
    "Question Editor", "Question Bank", "Create from Notes", "Review Question Set",
    "Note Reviews", "Read & Learn", "Practice", "Revision Session", "Needs Attention",
    "Progress", "Revision History", "Session Details", "Exam Goals", "Exam Editor",
    "Profile & Settings", "About AskAgain",
]
SUPPLEMENTARY = ["Revision Tab", "Generation Status (Dialog)"]
PROPOSAL = [
    "Sign In / Register", "Home", "Subject Detail", "Question Editor",
    "Create from Notes", "Review Question Set", "Revision Session",
    "Needs Attention", "Progress", "Profile & Settings",
]


def page_header(c, title, subtitle):
    c.setFillColor(INK)
    c.setFont("Helvetica-Bold", 16)
    c.drawString(30, PAGE_H - 32, title)
    c.setFont("Helvetica", 8)
    c.setFillColor(MID)
    c.drawString(30, PAGE_H - 47, subtitle)


def wireframe_pages(c):
    entries = [(name, i + 1) for i, name in enumerate(INVENTORY)]
    entries += [(name, None) for name in SUPPLEMENTARY]
    for start in range(0, len(entries), 3):
        page_header(c, "AskAgain - Mobile Wireframes | v1.7.4",
                    "25 numbered screen widgets; Revision Tab is embedded; Generation Status is a modal dialog (unnumbered).")
        for column, (name, number) in enumerate(entries[start:start + 3]):
            phone(c, 26 + column * 274, PAGE_H - 94,
                  *BY_NAME[name], number)
        c.setFont("Helvetica", 7)
        c.setFillColor(MID)
        c.drawString(30, 19, "Schematic regions; long forms scroll. Read & Learn retains its actual Learn & Recall app-bar title.")
        c.drawRightString(PAGE_W - 30, 19, f"Full reference | {start // 3 + 2}")
        c.showPage()


def proposal_pages():
    c = canvas.Canvas(str(PROPOSAL_OUTPUT), pagesize=(PAGE_W, PAGE_H))
    c.setTitle("AskAgain v1.7.4 - Proposal Wireframes Selection")
    c.setAuthor("AskAgain project")
    # Ten selected screens in the requested order, with 2-3 per page.
    groups = [PROPOSAL[:3], PROPOSAL[3:6], PROPOSAL[6:8], PROPOSAL[8:]]
    number = 0
    for page, screens in enumerate(groups):
        page_header(c, "AskAgain - Proposal Wireframes",
                    "10 core screens selected from the 25-screen AskAgain v1.7.4 inventory")
        start_left = 26 if len(screens) == 3 else 163
        for column, name in enumerate(screens):
            number += 1
            left = start_left + column * 274
            phone(c, left, PAGE_H - 94, *BY_NAME[name], number)
            c.setFont("Helvetica", 7)
            c.setFillColor(MID)
            c.drawCentredString(left + 118, PAGE_H - 84,
                               f"Full reference ID {INVENTORY.index(name) + 1:02d}")
        c.setFont("Helvetica", 7)
        c.setFillColor(MID)
        c.drawString(30, 19, "Selection numbering 01-10; navigation flow supplied separately. Long forms scroll.")
        c.drawRightString(PAGE_W - 30, 19, f"Proposal design | {page + 1}/4")
        c.showPage()
    c.save()


def main():
    assert len(INVENTORY) == 25 and len(PROPOSAL) == 10
    c = canvas.Canvas(str(OUTPUT), pagesize=(PAGE_W, PAGE_H))
    c.setTitle("AskAgain v1.7.4 - Wireframes and Navigation Flow")
    c.setAuthor("AskAgain project")
    navigation_page(c)
    wireframe_pages(c)
    c.save()
    proposal_pages()
    # Render page 1 from the same PDF to ensure PNG and PDF stay identical.
    renderer = shutil.which("pdftoppm")
    if renderer is None:
        raise RuntimeError("Install Poppler/pdftoppm to regenerate navigation PNG")
    with tempfile.TemporaryDirectory() as directory:
        prefix = Path(directory) / "navigation"
        subprocess.run([renderer, "-f", "1", "-l", "1", "-singlefile",
                        "-scale-to", "2400", "-png", str(OUTPUT), str(prefix)], check=True)
        shutil.copyfile(prefix.with_suffix(".png"), NAVIGATION_OUTPUT)
    for path in (OUTPUT, PROPOSAL_OUTPUT, NAVIGATION_OUTPUT):
        print(path)
    print("25 numbered screens + 2 supplementary states; proposal: 4 landscape pages (3, 3, 2, 2 screens)")


if __name__ == "__main__":
    main()
