"""Build a small, text-based source PDF for a real AskAgain AI demonstration."""
from pathlib import Path
from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer
from pypdf import PdfReader
import pypdfium2 as pdfium

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'output' / 'pdf'
OUT.mkdir(parents=True, exist_ok=True)
PDF = OUT / 'AskAgain_Simple_Computer_Basics_Notes.pdf'
SECTIONS = [
    ('1. The processor (CPU)',
     'The central processing unit, or CPU, executes program instructions. '
     'It performs calculations and coordinates many activities inside a computer. '
     'For example, the CPU follows instructions when a calculator program adds two numbers. '
     'The CPU processes information; it is not the main place where personal files are stored.'),
    ('2. Working memory (RAM)',
     'Random access memory, or RAM, temporarily holds data and programs that are currently in use. '
     'RAM is volatile: its contents are lost when power is switched off. '
     'Opening a program normally places some of its instructions and data into RAM so the CPU can use them.'),
    ('3. Long-term storage',
     'Storage keeps files and programs for later use. A solid-state drive (SSD) is one example of a storage device. '
     'Unlike RAM, an SSD retains saved data when power is switched off. '
     'Saving a document writes its contents to storage. Unsaved changes held only in RAM can be lost if power fails.'),
    ('4. Input devices',
     'An input device sends data or commands into a computer. A keyboard is used to enter text. '
     'A mouse is used to point, select, and click. A microphone captures sound as input. '
     'These devices allow a user to provide information for the computer to process.'),
    ('5. Output devices',
     'An output device presents information from a computer to a user. A monitor displays text and images. '
     'Speakers produce sound, and a printer produces a paper copy. '
     'Input devices send information into the computer, while output devices present the results.'),
]
styles = {
    'title': ParagraphStyle('title', fontName='Helvetica-Bold', fontSize=25,
                            leading=29, textColor=colors.HexColor('#1f2937'), spaceAfter=8),
    'sub': ParagraphStyle('sub', fontName='Helvetica', fontSize=10, leading=15,
                          textColor=colors.HexColor('#526171'), spaceAfter=23),
    'heading': ParagraphStyle('heading', fontName='Helvetica-Bold', fontSize=12,
                              leading=16, textColor=colors.HexColor('#253b55'), spaceAfter=6),
    'body': ParagraphStyle('body', fontName='Helvetica', fontSize=11, leading=16),
}
story = [Paragraph('Computer Basics', styles['title']),
         Paragraph('Study notes | Five essential computer components', styles['sub'])]
for heading, body in SECTIONS:
    story += [Paragraph(heading, styles['heading']), Paragraph(body, styles['body']), Spacer(1, 16)]

def footer(canvas, doc):
    canvas.setStrokeColor(colors.HexColor('#d8dfe6'))
    canvas.line(48, 45, A4[0] - 48, 45)
    canvas.setFont('Helvetica', 9)
    canvas.setFillColor(colors.HexColor('#526171'))
    canvas.drawString(48, 29, 'AskAgain | Sample study material')
    canvas.drawRightString(A4[0] - 48, 29, f'Page {doc.page}')

SimpleDocTemplate(str(PDF), pagesize=A4, leftMargin=48, rightMargin=48,
                  topMargin=45, bottomMargin=58).build(story, onFirstPage=footer, onLaterPages=footer)
reader = PdfReader(PDF)
assert len(reader.pages) == 1, 'Keep the demonstration to one readable page.'
text = reader.pages[0].extract_text()
assert 900 < len(text) < 4000
assert all(heading in text for heading, _ in SECTIONS)
(OUT / 'AskAgain_Simple_Computer_Basics_Notes.txt').write_text(text, encoding='utf-8')
preview = ROOT / 'tmp' / 'pdf_preview'
preview.mkdir(parents=True, exist_ok=True)
with pdfium.PdfDocument(str(PDF)) as pdf:
    pdf[0].render(scale=1.5).to_pil().save(preview / 'computer_basics.png')
print(f'{PDF}\n1 page; {len(text)} extractable characters; {PDF.stat().st_size} bytes')
