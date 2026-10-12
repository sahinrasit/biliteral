"""Builds Biliteral/Resources/SampleBook.epub from Project Gutenberg's plain text of
"Alice's Adventures in Wonderland" (eBook #11, public domain in the USA).

Usage: python3 scripts/make_sample_book.py path/to/pg11.txt
"""
import html
import os
import re
import sys
import zipfile

ROMAN = ["I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X", "XI", "XII"]
OUT = os.path.join(os.path.dirname(__file__), "..", "Biliteral/Resources/SampleBook.epub")

text = open(sys.argv[1], encoding="utf-8").read().replace("\r\n", "\n")
body = text.split("*** END OF THE PROJECT GUTENBERG EBOOK")[0]
body = body[body.index("\nCHAPTER I.\n"):]
parts = re.split(r"\nCHAPTER ([IVX]+)\.\n", body)[1:]

chapters = []
for numeral, content in zip(parts[0::2], parts[1::2]):
    lines = content.strip("\n").split("\n")
    title, rest = lines[0].strip(), "\n".join(lines[1:])
    paragraphs = []
    for block in re.split(r"\n\s*\n", rest):
        line = " ".join(l.strip() for l in block.split("\n") if l.strip())
        if not line or line == "THE END" or set(line) <= set("* "):
            continue
        escaped = html.escape(line, quote=False)
        paragraphs.append(re.sub(r"_([^_]+)_", r"<em>\1</em>", escaped))
    chapters.append((numeral, title, paragraphs))

def xhtml(numeral, title, paragraphs):
    ps = "\n".join(f"<p>{p}</p>" for p in paragraphs)
    return f"""<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml" lang="en"><head><title>{html.escape(title)}</title></head>
<body><h1>Chapter {numeral}: {html.escape(title)}</h1>
{ps}
</body></html>"""

items = "\n".join(f'<item id="c{i}" href="c{i}.xhtml" media-type="application/xhtml+xml"/>' for i in range(len(chapters)))
spine = "\n".join(f'<itemref idref="c{i}"/>' for i in range(len(chapters)))
opf = f"""<?xml version="1.0" encoding="utf-8"?>
<package xmlns="http://www.idpf.org/2007/opf" version="3.0" unique-identifier="id">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
    <dc:identifier id="id">biliteral-sample-alice</dc:identifier>
    <dc:title>Alice’s Adventures in Wonderland</dc:title>
    <dc:creator>Lewis Carroll</dc:creator>
    <dc:language>en</dc:language>
    <dc:source>https://www.gutenberg.org/ebooks/11</dc:source>
  </metadata>
  <manifest>{items}</manifest>
  <spine>{spine}</spine>
</package>"""
container = """<?xml version="1.0"?>
<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
  <rootfiles><rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/></rootfiles>
</container>"""

os.makedirs(os.path.dirname(OUT), exist_ok=True)
with zipfile.ZipFile(OUT, "w") as z:
    z.writestr("mimetype", "application/epub+zip", compress_type=zipfile.ZIP_STORED)
    z.writestr("META-INF/container.xml", container, compress_type=zipfile.ZIP_DEFLATED)
    z.writestr("OEBPS/content.opf", opf, compress_type=zipfile.ZIP_DEFLATED)
    for i, chapter in enumerate(chapters):
        z.writestr(f"OEBPS/c{i}.xhtml", xhtml(*chapter), compress_type=zipfile.ZIP_DEFLATED)
print(f"{len(chapters)} chapters, {sum(len(c[2]) for c in chapters)} paragraphs ->", os.path.normpath(OUT))
