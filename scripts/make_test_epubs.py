"""Builds the EPUB fixtures used by BiliteralCoreTests.

Usage: python3 scripts/make_test_epubs.py
"""
import os
import zipfile

OUT = os.path.join(os.path.dirname(__file__), "..", "Packages/BiliteralCore/Tests/BiliteralCoreTests/Fixtures")
CONTAINER = """<?xml version="1.0"?>
<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
  <rootfiles><rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/></rootfiles>
</container>"""


def opf(title, items, spine, lang="en"):
    manifest = "\n".join(f'<item id="{i}" href="{h}" media-type="application/xhtml+xml"{p}/>' for i, h, p in items)
    refs = "\n".join(f'<itemref idref="{i}"/>' for i in spine)
    return f"""<?xml version="1.0" encoding="utf-8"?>
<package xmlns="http://www.idpf.org/2007/opf" version="3.0" unique-identifier="id">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
    <dc:title>{title}</dc:title><dc:creator>Test Author</dc:creator><dc:language>{lang}</dc:language>
  </metadata>
  <manifest>{manifest}</manifest>
  <spine>{refs}</spine>
</package>"""


def xhtml(body, title="Doc"):
    return f"""<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml"><head><title>{title}</title><style>p {{ margin: 0 }}</style></head>
<body>{body}</body></html>"""


def write(name, files, extra=None):
    path = os.path.join(OUT, name)
    with zipfile.ZipFile(path, "w") as z:
        z.writestr("mimetype", "application/epub+zip", compress_type=zipfile.ZIP_STORED)
        z.writestr("META-INF/container.xml", CONTAINER, compress_type=zipfile.ZIP_DEFLATED)
        for p, data in {**files, **(extra or {})}.items():
            z.writestr(p, data, compress_type=zipfile.ZIP_DEFLATED)


os.makedirs(OUT, exist_ok=True)
long_p = "<p>It was a bright cold day in April, and the clocks were striking thirteen. Mr. Smith walked home slowly.</p>"

write("simple.epub", {
    "OEBPS/content.opf": opf("Simple Book", [("cover", "cover.xhtml", ""), ("nav", "nav.xhtml", ' properties="nav"'),
                                             ("c1", "text/ch%201.xhtml", ""), ("c2", "text/ch2.xhtml", "")],
                             ["cover", "nav", "c1", "c2"]),
    "OEBPS/cover.xhtml": xhtml('<div><img src="cover.jpg" alt="Cover"/></div>'),
    "OEBPS/nav.xhtml": xhtml('<nav><ol><li><a href="text/ch1.xhtml">One</a></li></ol></nav>'),
    "OEBPS/text/ch 1.xhtml": xhtml("<h1>Chapter One</h1>" + long_p * 2 + "<p>Caf&eacute; &amp; cr&egrave;me&nbsp;br&ucirc;l&eacute;e &#8212; done.</p>"),
    "OEBPS/text/ch2.xhtml": xhtml("<h2>CHAPTER II.</h2><h3>The Pool of Tears</h3>" + long_p * 3 + "<script>var x = '<p>no</p>';</script>"),
})

gutenberg = ("<p>The Project Gutenberg eBook of Test</p><p>*** START OF THE PROJECT GUTENBERG EBOOK TEST ***</p>"
             + "".join(f"<h2>CHAPTER {n}.</h2>" + long_p * 2 for n in ["I", "II", "III"])
             + "<p>*** END OF THE PROJECT GUTENBERG EBOOK TEST ***</p><p>Licence text that must be dropped.</p>")
write("gutenberg.epub", {
    "OEBPS/content.opf": opf("Gutenberg Book", [("all", "all.xhtml", "")], ["all"]),
    "OEBPS/all.xhtml": xhtml(gutenberg),
})

write("drm.epub", {
    "OEBPS/content.opf": opf("Locked", [("c1", "c1.xhtml", "")], ["c1"]),
    "OEBPS/c1.xhtml": "binary-garbage",
}, extra={"META-INF/encryption.xml": """<encryption xmlns="urn:oasis:names:tc:opendocument:xmlns:container"
  xmlns:enc="http://www.w3.org/2001/04/xmlenc#"><enc:EncryptedData><enc:EncryptionMethod
  Algorithm="http://www.w3.org/2001/04/xmlenc#aes128-cbc"/></enc:EncryptedData></encryption>"""})
print("fixtures written to", os.path.normpath(OUT))
