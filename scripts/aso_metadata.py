"""App Store metadata for every locale, written to fastlane/metadata and checked against Apple's limits.

Usage: python3 scripts/aso_metadata.py
Source: the market research brief (§8–§10, §15). Names, subtitles, keywords and promotional texts are
verbatim. Descriptions follow the brief with factual corrections: v1 has no iCloud sync (books are in the
iCloud backup), flashcards are added with one tap rather than automatically, text size replaces line
spacing, and the subscription terms required by App Review are added.
"""
import os

PRIVACY_URL = "https://sahinrasit.github.io/biliteral/privacy"
SUPPORT_URL = "https://sahinrasit.github.io/biliteral/"
EMAIL = "mrrasitsahin@icloud.com"
TERMS_URL = "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/"

LIMITS = {"name": 30, "subtitle": 30, "keywords": 100, "promotional_text": 170, "description": 4000}

EN_DESCRIPTION = f"""Biliteral turns any book, article or pasted text into a bilingual reader. The original stays on the left page, the translation appears on the right, sentence by sentence, aligned and scrolling together. Translation runs entirely on your device, so it works on a plane, in the metro, anywhere.

YOUR CONTENT, NOT A LIBRARY
• Import EPUB and PDF files, web articles or any pasted text
• No curated library, no "premium stories": read what you actually want to read
• Books stay on your device and in your iCloud backup

READ IN TWO LANGUAGES
• Two-page layout: original and translation side by side
• Tap a sentence to highlight its match on the other page
• Single-column mode on smaller screens: translation under each paragraph or on tap
• Adjustable font, text size and themes (Paper, Night)

LEARN WHILE YOU READ
• Tap any word for its meaning and the built-in dictionary
• Save unknown words as spaced-repetition flashcards with one tap
• Daily review queue with sentence context from your own book
• Listen to any passage with natural text-to-speech
• Ask on-device AI to explain a sentence (Pro, on supported devices)

OFFLINE AND PRIVATE
• On-device translation: no text ever leaves your device
• Download a language pair once, read offline forever
• No account, no tracking, no ads

SUPPORTED LANGUAGES
English, Spanish, French, German, Italian, Dutch, Portuguese, Turkish, Polish, Russian, Ukrainian, Arabic, Chinese, Japanese, Korean, Hindi, Indonesian, Thai, Vietnamese and more, in any direction supported by your device's translation models.

ONE PURCHASE
Try it free: a public-domain classic is included, and you can read one book of your own up to chapter 3. Biliteral Lifetime unlocks everything with a single payment. A monthly plan is available if you prefer; it renews automatically unless cancelled at least 24 hours before the end of the period, and you manage it in your App Store account settings. No trial traps.

Designed first for foldable and large screens, Biliteral works fully on every iPhone and iPad running iOS 18 or later.

Notes: Books protected by DRM (for example purchased from major ebook stores) cannot be opened. Translation quality depends on the system translation models for each language pair.

Support: {EMAIL}
Privacy: {PRIVACY_URL}
Terms of Use: {TERMS_URL}"""

DE_DESCRIPTION = f"""Biliteral macht aus jedem Buch, Artikel oder eingefügten Text einen zweisprachigen Reader. Das Original steht auf der linken Seite, die Übersetzung erscheint rechts, Satz für Satz, aneinander ausgerichtet und gemeinsam scrollend. Die Übersetzung läuft komplett auf deinem Gerät, im Flugzeug, in der U-Bahn, überall.

DEINE INHALTE, KEINE BIBLIOTHEK
• EPUB- und PDF-Dateien, Webartikel oder beliebigen Text importieren
• Keine kuratierte Bibliothek, keine „Premium-Geschichten“: Lies, was du wirklich lesen willst
• Deine Bücher bleiben auf deinem Gerät und in deinem iCloud-Backup

IN ZWEI SPRACHEN LESEN
• Zwei-Seiten-Layout: Original und Übersetzung nebeneinander
• Tippe auf einen Satz, und sein Gegenstück auf der anderen Seite wird markiert
• Einspaltig auf kleineren Bildschirmen: Übersetzung unter jedem Absatz oder per Tippen
• Schrift, Textgröße und Themen (Papier, Nacht) einstellbar

BEIM LESEN LERNEN
• Tippe auf ein Wort für seine Bedeutung und das integrierte Wörterbuch
• Unbekannte Wörter mit einem Tippen als Karteikarten mit verteilter Wiederholung speichern
• Tägliche Wiederholung mit dem Satzkontext aus deinem eigenen Buch
• Jede Passage mit natürlicher Sprachausgabe anhören
• Lass dir einen Satz von KI auf dem Gerät erklären (Pro, auf unterstützten Geräten)

OFFLINE UND PRIVAT
• Übersetzung auf dem Gerät: Kein Text verlässt dein Gerät
• Ein Sprachpaar einmal laden und für immer offline lesen
• Kein Konto, kein Tracking, keine Werbung

UNTERSTÜTZTE SPRACHEN
Englisch, Spanisch, Französisch, Deutsch, Italienisch, Niederländisch, Portugiesisch, Türkisch, Polnisch, Russisch, Ukrainisch, Arabisch, Chinesisch, Japanisch, Koreanisch, Hindi, Indonesisch, Thai, Vietnamesisch und mehr, in jeder Richtung, die die Übersetzungsmodelle deines Geräts unterstützen.

EIN KAUF
Kostenlos ausprobieren: Ein gemeinfreier Klassiker ist dabei, und ein eigenes Buch kannst du bis Kapitel 3 lesen. Biliteral Lifetime schaltet alles mit einer einzigen Zahlung frei. Wenn du möchtest, gibt es auch ein Monatsabo; es verlängert sich automatisch, wenn es nicht mindestens 24 Stunden vor Ende des Zeitraums gekündigt wird, und wird in deinen App-Store-Einstellungen verwaltet. Keine Probeabo-Fallen.

Zuerst für faltbare und große Bildschirme entworfen, funktioniert Biliteral vollständig auf jedem iPhone und iPad mit iOS 18 oder neuer.

Hinweise: Durch DRM geschützte Bücher (zum Beispiel aus großen E-Book-Shops) können nicht geöffnet werden. Die Übersetzungsqualität hängt von den Übersetzungsmodellen des Systems für das jeweilige Sprachpaar ab.

Support: {EMAIL}
Datenschutz: {PRIVACY_URL}
Nutzungsbedingungen: {TERMS_URL}"""

FR_DESCRIPTION = f"""Biliteral transforme n'importe quel livre, article ou texte collé en lecteur bilingue. L'original reste sur la page de gauche, la traduction apparaît à droite, phrase par phrase, alignée et défilant en même temps. La traduction se fait entièrement sur votre appareil : en avion, dans le métro, partout.

VOS CONTENUS, PAS UNE BIBLIOTHÈQUE
• Importez des fichiers EPUB et PDF, des articles web ou n'importe quel texte collé
• Pas de bibliothèque imposée, pas d'« histoires premium » : lisez ce que vous voulez vraiment lire
• Vos livres restent sur votre appareil et dans votre sauvegarde iCloud

LIRE EN DEUX LANGUES
• Mise en page sur deux pages : original et traduction côte à côte
• Touchez une phrase pour surligner sa correspondance sur l'autre page
• Une seule colonne sur les petits écrans : traduction sous chaque paragraphe ou au toucher
• Police, taille du texte et thèmes (Papier, Nuit) réglables

APPRENDRE EN LISANT
• Touchez un mot pour son sens et le dictionnaire intégré
• Enregistrez les mots inconnus en cartes mémoire à répétition espacée d'un seul toucher
• Révision quotidienne avec le contexte de la phrase tirée de votre propre livre
• Écoutez n'importe quel passage avec une synthèse vocale naturelle
• Demandez à l'IA sur l'appareil d'expliquer une phrase (Pro, sur les appareils compatibles)

HORS LIGNE ET PRIVÉ
• Traduction sur l'appareil : aucun texte ne quitte votre appareil
• Téléchargez une paire de langues une fois, lisez hors ligne pour toujours
• Pas de compte, pas de pistage, pas de publicité

LANGUES PRISES EN CHARGE
Anglais, espagnol, français, allemand, italien, néerlandais, portugais, turc, polonais, russe, ukrainien, arabe, chinois, japonais, coréen, hindi, indonésien, thaï, vietnamien et plus, dans tous les sens pris en charge par les modèles de traduction de votre appareil.

UN SEUL ACHAT
Essayez gratuitement : un classique du domaine public est inclus, et vous pouvez lire un de vos livres jusqu'au chapitre 3. Biliteral à vie débloque tout en un seul paiement. Un abonnement mensuel est aussi proposé ; il se renouvelle automatiquement sauf résiliation au moins 24 heures avant la fin de la période et se gère dans les réglages de votre compte App Store. Aucun piège d'essai.

Conçu d'abord pour les écrans pliables et grands, Biliteral fonctionne pleinement sur tout iPhone et iPad sous iOS 18 ou version ultérieure.

Remarques : les livres protégés par DRM (par exemple achetés dans les grandes librairies numériques) ne peuvent pas être ouverts. La qualité de traduction dépend des modèles de traduction du système pour chaque paire de langues.

Assistance : {EMAIL}
Confidentialité : {PRIVACY_URL}
Conditions d'utilisation : {TERMS_URL}"""

ES_DESCRIPTION = f"""Biliteral convierte cualquier libro, artículo o texto pegado en un lector bilingüe. El original queda en la página izquierda y la traducción aparece a la derecha, frase por frase, alineadas y desplazándose juntas. La traducción se hace por completo en tu dispositivo: en un avión, en el metro, en cualquier sitio.

TU CONTENIDO, NO UNA BIBLIOTECA
• Importa archivos EPUB y PDF, artículos web o cualquier texto pegado
• Sin biblioteca impuesta ni «historias premium»: lee lo que de verdad quieres leer
• Tus libros se quedan en tu dispositivo y en tu copia de seguridad de iCloud

LEE EN DOS IDIOMAS
• Diseño a dos páginas: original y traducción lado a lado
• Toca una frase para resaltar su equivalente en la otra página
• Una columna en pantallas pequeñas: traducción bajo cada párrafo o al tocar
• Tipo de letra, tamaño del texto y temas (Papel, Noche) ajustables

APRENDE MIENTRAS LEES
• Toca cualquier palabra para ver su significado y el diccionario integrado
• Guarda las palabras desconocidas como tarjetas de repetición espaciada con un toque
• Repaso diario con el contexto de la frase de tu propio libro
• Escucha cualquier pasaje con voz natural
• Pide a la IA del dispositivo que te explique una frase (Pro, en dispositivos compatibles)

SIN CONEXIÓN Y PRIVADO
• Traducción en el dispositivo: ningún texto sale de tu dispositivo
• Descarga un par de idiomas una vez y lee sin conexión para siempre
• Sin cuenta, sin rastreo, sin anuncios

IDIOMAS COMPATIBLES
Inglés, español, francés, alemán, italiano, neerlandés, portugués, turco, polaco, ruso, ucraniano, árabe, chino, japonés, coreano, hindi, indonesio, tailandés, vietnamita y más, en cualquier dirección que admitan los modelos de traducción de tu dispositivo.

UN SOLO PAGO
Pruébalo gratis: incluye un clásico de dominio público y puedes leer un libro tuyo hasta el capítulo 3. Biliteral de por vida lo desbloquea todo con un único pago. Si lo prefieres, hay un plan mensual; se renueva automáticamente salvo que lo canceles al menos 24 horas antes del final del periodo, y se gestiona en los ajustes de tu cuenta del App Store. Sin trampas de prueba.

Diseñado primero para pantallas plegables y grandes, Biliteral funciona por completo en cualquier iPhone y iPad con iOS 18 o posterior.

Notas: los libros protegidos con DRM (por ejemplo, comprados en las grandes tiendas de libros electrónicos) no se pueden abrir. La calidad de la traducción depende de los modelos de traducción del sistema para cada par de idiomas.

Soporte: {EMAIL}
Privacidad: {PRIVACY_URL}
Condiciones de uso: {TERMS_URL}"""

IT_DESCRIPTION = f"""Biliteral trasforma qualsiasi libro, articolo o testo incollato in un lettore bilingue. L'originale resta sulla pagina di sinistra, la traduzione compare a destra, frase per frase, allineate e con scorrimento sincronizzato. La traduzione avviene interamente sul tuo dispositivo: in aereo, in metro, ovunque.

I TUOI CONTENUTI, NON UNA BIBLIOTECA
• Importa file EPUB e PDF, articoli web o qualsiasi testo incollato
• Nessuna biblioteca imposta, nessuna «storia premium»: leggi ciò che vuoi davvero leggere
• I tuoi libri restano sul dispositivo e nel tuo backup iCloud

LEGGI IN DUE LINGUE
• Layout a due pagine: originale e traduzione affiancati
• Tocca una frase per evidenziare la corrispondente sull'altra pagina
• Una colonna sugli schermi più piccoli: traduzione sotto ogni paragrafo o al tocco
• Carattere, dimensione del testo e temi (Carta, Notte) regolabili

IMPARA MENTRE LEGGI
• Tocca una parola per il significato e il dizionario integrato
• Salva le parole sconosciute come flashcard a ripetizione dilazionata con un tocco
• Ripasso quotidiano con il contesto della frase tratta dal tuo libro
• Ascolta qualsiasi passaggio con una voce naturale
• Chiedi all'IA sul dispositivo di spiegarti una frase (Pro, sui dispositivi compatibili)

OFFLINE E PRIVATO
• Traduzione sul dispositivo: nessun testo lascia il tuo dispositivo
• Scarica una coppia di lingue una volta e leggi offline per sempre
• Nessun account, nessun tracciamento, nessuna pubblicità

LINGUE SUPPORTATE
Inglese, spagnolo, francese, tedesco, italiano, olandese, portoghese, turco, polacco, russo, ucraino, arabo, cinese, giapponese, coreano, hindi, indonesiano, thailandese, vietnamita e altre, in ogni direzione supportata dai modelli di traduzione del tuo dispositivo.

UN SOLO ACQUISTO
Provalo gratis: è incluso un classico di pubblico dominio e puoi leggere un tuo libro fino al capitolo 3. Biliteral a vita sblocca tutto con un unico pagamento. Se preferisci c'è un piano mensile; si rinnova automaticamente se non viene annullato almeno 24 ore prima della fine del periodo e si gestisce nelle impostazioni del tuo account App Store. Nessuna trappola di prova.

Pensato prima per schermi pieghevoli e grandi, Biliteral funziona pienamente su ogni iPhone e iPad con iOS 18 o successivo.

Note: i libri protetti da DRM (ad esempio acquistati nei grandi store di ebook) non possono essere aperti. La qualità della traduzione dipende dai modelli di traduzione del sistema per ogni coppia di lingue.

Assistenza: {EMAIL}
Privacy: {PRIVACY_URL}
Condizioni d'uso: {TERMS_URL}"""

NL_DESCRIPTION = f"""Biliteral maakt van elk boek, artikel of geplakte tekst een tweetalige lezer. Het origineel staat op de linkerpagina, de vertaling verschijnt rechts, zin voor zin, op één lijn en samen scrollend. De vertaling gebeurt volledig op je toestel: in het vliegtuig, in de metro, overal.

JOUW INHOUD, GEEN BIBLIOTHEEK
• Importeer EPUB- en PDF-bestanden, webartikelen of geplakte tekst
• Geen opgelegde bibliotheek, geen 'premiumverhalen': lees wat je echt wilt lezen
• Je boeken blijven op je toestel en in je iCloud-reservekopie

LEZEN IN TWEE TALEN
• Indeling met twee pagina's: origineel en vertaling naast elkaar
• Tik op een zin om de tegenhanger op de andere pagina te markeren
• Eén kolom op kleinere schermen: vertaling onder elke alinea of na een tik
• Lettertype, tekstgrootte en thema's (Papier, Nacht) instelbaar

LEREN TERWIJL JE LEEST
• Tik op een woord voor de betekenis en het ingebouwde woordenboek
• Bewaar onbekende woorden met één tik als flashcards met gespreide herhaling
• Dagelijkse herhaling met de zin uit je eigen boek als context
• Luister naar elke passage met natuurlijke spraak
• Laat AI op je toestel een zin uitleggen (Pro, op ondersteunde toestellen)

OFFLINE EN PRIVÉ
• Vertaling op het toestel: geen tekst verlaat je toestel
• Download een taalpaar één keer en lees voor altijd offline
• Geen account, geen tracking, geen advertenties

ONDERSTEUNDE TALEN
Engels, Spaans, Frans, Duits, Italiaans, Nederlands, Portugees, Turks, Pools, Russisch, Oekraïens, Arabisch, Chinees, Japans, Koreaans, Hindi, Indonesisch, Thai, Vietnamees en meer, in elke richting die de vertaalmodellen van je toestel ondersteunen.

ÉÉN AANKOOP
Probeer het gratis: er zit een klassieker uit het publieke domein bij en je kunt één eigen boek lezen tot en met hoofdstuk 3. Biliteral Levenslang ontgrendelt alles met één betaling. Wil je liever een maandabonnement, dan kan dat ook; het wordt automatisch verlengd tenzij je het minstens 24 uur voor het einde van de periode opzegt, en je beheert het in de instellingen van je App Store-account. Geen proefvallen.

Eerst ontworpen voor opvouwbare en grote schermen, werkt Biliteral volledig op elke iPhone en iPad met iOS 18 of later.

Opmerkingen: met DRM beveiligde boeken (bijvoorbeeld gekocht in grote e-bookwinkels) kunnen niet worden geopend. De vertaalkwaliteit hangt af van de vertaalmodellen van het systeem voor elk taalpaar.

Ondersteuning: {EMAIL}
Privacy: {PRIVACY_URL}
Gebruiksvoorwaarden: {TERMS_URL}"""

TR_DESCRIPTION = f"""Biliteral, elindeki her kitabı, makaleyi veya yapıştırdığın metni iki dilli bir okuma deneyimine dönüştürür. Solda orijinal, sağda çeviri; cümleler birebir hizalı ve birlikte kayar. Çeviri tamamen cihazında yapılır: uçakta, metroda, internet olmayan her yerde çalışır.

KENDİ İÇERİĞİN, HAZIR KÜTÜPHANE DEĞİL
• EPUB ve PDF dosyaları, web makaleleri veya yapıştırılan metinleri içe aktar
• "Premium hikâye" yok: gerçekten okumak istediğini oku
• Kitapların cihazında ve iCloud yedeğinde kalır

İKİ DİLDE OKU
• İki sayfa düzeni: orijinal ve çeviri yan yana
• Bir cümleye dokun, karşı sayfadaki karşılığı vurgulansın
• Küçük ekranda tek sütun: paragraf altı çeviri veya dokununca çeviri
• Yazı tipi, yazı boyutu ve tema (Kâğıt, Gece) ayarlanabilir

OKURKEN ÖĞREN
• Herhangi bir kelimeye dokun, anlamı ve yerleşik sözlük açılsın
• Bilmediğin kelimeleri tek dokunuşla aralıklı tekrar kartına dönüştür
• Günlük tekrar kuyruğu, kendi kitabından cümle bağlamıyla
• İstediğin bölümü doğal sesle dinle
• Cihaz üstü yapay zekâya bir cümleyi açıklat (Pro, desteklenen cihazlarda)

ÇEVRİMDIŞI VE GİZLİ
• Cihaz üstü çeviri: metnin cihazından asla çıkmaz
• Dil paketini bir kez indir, sonsuza kadar çevrimdışı oku
• Hesap yok, takip yok, reklam yok

YDS, YÖKDİL, IELTS, TOEFL hazırlığında İngilizce okuma hızını kendi seçtiğin metinlerle artır. İngilizce, Almanca, Fransızca, İspanyolca, İtalyanca, Hollandaca, Rusça, Arapça, Japonca, Korece, Çince ve cihazının çeviri modellerinin desteklediği diğer diller.

TEK ÖDEME
Ücretsiz dene: kamu malı bir klasik hazır gelir, kendi kitabından birini 3. bölüme kadar okuyabilirsin. Biliteral Ömür Boyu tek ödemeyle her şeyi açar. İstersen aylık plan da var; dönem bitmeden en az 24 saat önce iptal edilmezse otomatik yenilenir ve App Store hesap ayarlarından yönetilir. Deneme tuzağı yok.

Önce katlanabilir ve büyük ekranlar için tasarlandı; iOS 18 ve üzeri her iPhone ve iPad'de eksiksiz çalışır.

Notlar: DRM korumalı kitaplar (büyük e-kitap mağazalarından satın alınanlar) açılamaz. Çeviri kalitesi her dil çifti için sistem çeviri modellerine bağlıdır.

Destek: {EMAIL}
Gizlilik: {PRIVACY_URL}
Kullanım Koşulları: {TERMS_URL}"""

EN_PROMO = ("Open any EPUB, PDF or article and read it side by side with an on-device translation. "
            "Tap a word for the dictionary, save it as a flashcard. Works offline.")

LOCALES = {
    "en-US": dict(name="Biliteral: Bilingual Reader", subtitle="Read Books in Two Languages",
                  keywords="learn,language,epub,translate,parallel,text,vocabulary,flashcards,spanish,french,german,offline,pdf",
                  promotional_text=EN_PROMO, description=EN_DESCRIPTION),
    "en-GB": dict(name="Biliteral: Bilingual Reader", subtitle="Read Books in Two Languages",
                  keywords="learn,language,epub,translate,parallel,text,vocabulary,flashcards,spanish,french,german,offline,book",
                  promotional_text=EN_PROMO, description=EN_DESCRIPTION),
    "de-DE": dict(name="Biliteral: Zweisprachig lesen", subtitle="Bücher in zwei Sprachen lesen",
                  keywords="sprachen,lernen,englisch,epub,übersetzen,übersetzer,vokabeln,karteikarten,paralleltext,offline,pdf",
                  promotional_text="Öffne ein EPUB, PDF oder einen Artikel und lies ihn neben einer Übersetzung direkt auf dem Gerät. Tippe auf ein Wort: Wörterbuch und Karteikarte. Offline.",
                  description=DE_DESCRIPTION),
    "fr-FR": dict(name="Biliteral : Lecture bilingue", subtitle="Lisez des livres en 2 langues",
                  keywords="apprendre,langue,anglais,epub,traduire,traduction,vocabulaire,cartes,texte,parallèle,hors,ligne,pdf",
                  promotional_text="Ouvrez un EPUB, un PDF ou un article et lisez-le à côté d'une traduction faite sur l'appareil. Touchez un mot : dictionnaire et carte mémoire. Hors ligne.",
                  description=FR_DESCRIPTION),
    "es-ES": dict(name="Biliteral: Lectura bilingüe", subtitle="Lee libros en dos idiomas",
                  keywords="aprender,idiomas,inglés,epub,traducir,traductor,vocabulario,tarjetas,texto,paralelo,sin,conexión,pdf",
                  promotional_text="Abre un EPUB, PDF o artículo y léelo junto a una traducción hecha en tu dispositivo. Toca una palabra: diccionario y tarjeta de memoria. Funciona sin conexión.",
                  description=ES_DESCRIPTION),
    "it": dict(name="Biliteral: Lettura bilingue", subtitle="Leggi libri in due lingue",
               keywords="imparare,lingue,inglese,epub,tradurre,traduttore,vocabolario,flashcard,testo,parallelo,offline,pdf",
               promotional_text="Apri un EPUB, un PDF o un articolo e leggilo accanto a una traduzione fatta sul dispositivo. Tocca una parola: dizionario e flashcard. Funziona offline.",
               description=IT_DESCRIPTION),
    "nl-NL": dict(name="Biliteral: Tweetalig lezen", subtitle="Lees boeken in twee talen",
                  keywords="taal,leren,engels,epub,vertalen,vertaler,woordenschat,flashcards,parallel,tekst,offline,pdf,boek",
                  promotional_text="Open een EPUB, PDF of artikel en lees het naast een vertaling die op je toestel wordt gemaakt. Tik op een woord: woordenboek en flashcard. Werkt offline.",
                  description=NL_DESCRIPTION),
    "tr": dict(name="Biliteral: İki Dilli Okuma", subtitle="Kitapları çeviriyle oku",
               keywords="ingilizce,öğrenme,kitap,çeviri,hikaye,kelime,ezber,epub,pdf,paralel,metin,sözlük,çevrimdışı,almanca",
               promotional_text="EPUB, PDF veya makaleyi aç; cihaz içi çeviri yanında cümle cümle oku. Kelimeye dokun: sözlük açılır, kart olur. İnternet gerekmez, abonelik şart değil.",
               description=TR_DESCRIPTION),
}

REVIEW_NOTES = f"""Biliteral is a bilingual reader. Translation is performed on-device by Apple's Translation framework; no server and no account are used.

How to test:
1. Finish the three onboarding pages. The bundled public-domain sample book (Alice's Adventures in Wonderland, Project Gutenberg) opens, set to English -> Spanish (or the device language).
2. iOS asks once to download the language pair; allow it. Read in two-page mode (iPad, or iPhone in landscape) or single column (iPhone portrait).
3. Tap a sentence to highlight its translation, then tap a word inside the highlighted sentence for its meaning. Choose "I don't know this word" to create a flashcard (Flashcards tab).

Free tier: one imported book, its first three chapters and 20 reviews a day; the sample book is always free. The paywall appears when importing a second book, opening chapter 4 of an imported book, or from Settings > Unlock Biliteral Pro.
In-app purchases: Lifetime (non-consumable) and Monthly (auto-renewable), StoreKit 2 via RevenueCat. Sandbox works without an account in the app.
DRM-protected books cannot be opened by design.
Contact: {EMAIL}"""


def write():
    root = os.path.join(os.path.dirname(__file__), "..", "fastlane", "metadata")
    problems = []
    for locale, fields in LOCALES.items():
        folder = os.path.join(root, locale)
        os.makedirs(folder, exist_ok=True)
        for field, value in fields.items():
            if len(value) > LIMITS[field]:
                problems.append(f"{locale}/{field}: {len(value)} > {LIMITS[field]}")
            if field == "keywords" and any(len(k) == 0 for k in value.split(",")):
                problems.append(f"{locale}/keywords has an empty entry")
            open(os.path.join(folder, f"{field}.txt"), "w").write(value + "\n")
        open(os.path.join(folder, "privacy_url.txt"), "w").write(PRIVACY_URL + "\n")
        open(os.path.join(folder, "support_url.txt"), "w").write(SUPPORT_URL + "\n")
        open(os.path.join(folder, "marketing_url.txt"), "w").write(SUPPORT_URL + "\n")
        print(f"{locale:6} " + "  ".join(f"{k}={len(v)}" for k, v in fields.items()))
    for name, value in {"copyright.txt": "2026 Raşit Şahin",
                        "primary_category.txt": "EDUCATION",
                        "secondary_category.txt": "BOOKS"}.items():
        open(os.path.join(root, name), "w").write(value + "\n")
    review = os.path.join(root, "review_information")
    os.makedirs(review, exist_ok=True)
    open(os.path.join(review, "notes.txt"), "w").write(REVIEW_NOTES + "\n")
    open(os.path.join(review, "demo_required.txt"), "w").write("false\n")
    if problems:
        raise SystemExit("Limit problems:\n" + "\n".join(problems))
    print("All fields within limits.")


if __name__ == "__main__":
    write()
