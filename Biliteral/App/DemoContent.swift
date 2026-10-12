import BiliteralCore
import Foundation
import SwiftData

/// Screenshot and UI-test content (`-SeedDemo`). The simulator has no system translator, so the
/// opening of chapter VII of the sample book ("A Mad Tea-Party") comes with ready translations
/// into the App Store languages. Translations are original to this project.
enum DemoContent {
    static let chapterIndex = 6
    /// “Your hair wants cutting,” said the Hatter.
    static let selectedSentence = 12
    static let lookupTerm = "cutting"

    /// es for English devices, otherwise the device language.
    static var target: String {
        let code = Locale.preferredLanguages.first.map { BookImporter.baseCode($0) } ?? "en"
        return translations[code] == nil ? "es" : code
    }

    @MainActor
    static func seed(_ sample: Book, into context: ModelContext) {
        let target = target
        sample.targetLanguage = target
        sample.currentChapter = chapterIndex
        sample.lastOpenedAt = .now
        if let chapter = sample.sortedChapters.first(where: { $0.index == chapterIndex }), let lines = translations[target] {
            var content = chapter.content
            content.clearTranslations()
            content.apply(lines.enumerated().map { ($0.offset, $0.element) })
            chapter.content = content
            chapter.translatedLanguage = target
            seedCards(target: target, content: content, book: sample.title, into: context)
        }
        try? context.save()
    }

    @MainActor
    private static func seedCards(target: String, content: ChapterContent, book: String, into context: ModelContext) {
        for (offset, card) in cards.enumerated() {
            guard let meaning = card.meanings[target], content.sentences.indices.contains(card.sentence) else { continue }
            let sentence = content.sentences[card.sentence]
            let vocab = VocabCard(term: card.term, lemma: card.term, meaning: meaning, context: sentence.text,
                                  contextTranslation: sentence.translation, sourceLanguage: "en", targetLanguage: target, bookTitle: book)
            vocab.due = offset < 5 ? Date.now.addingTimeInterval(-3_600) : Date.now.addingTimeInterval(86_400 * Double(offset))
            vocab.repetitions = offset < 5 ? 1 : 3
            vocab.interval = offset < 5 ? 1 : 6
            context.insert(vocab)
        }
    }

    static func lookupWord(in sentence: String) -> String? {
        sentence.contains(lookupTerm) ? lookupTerm : nil
    }

    static func meaning(of word: String, in language: String) -> String? {
        cards.first { $0.term == word.lowercased() }?.meanings[language]
    }

    private struct Card {
        var term: String
        var sentence: Int
        var meanings: [String: String]
    }

    private static let cards: [Card] = [
        Card(term: "cutting", sentence: 12, meanings: ["es": "corte (de pelo)", "de": "Schneiden", "fr": "coupe", "it": "taglio",
                                                       "nl": "knippen", "tr": "kesilme, kesim"]),
        Card(term: "indignantly", sentence: 4, meanings: ["es": "con indignación", "de": "empört", "fr": "avec indignation",
                                                          "it": "con indignazione", "nl": "verontwaardigd", "tr": "öfkeyle"]),
        Card(term: "civil", sentence: 9, meanings: ["es": "educado, cortés", "de": "höflich", "fr": "poli", "it": "educato",
                                                    "nl": "beleefd", "tr": "kibar"]),
        Card(term: "curiosity", sentence: 13, meanings: ["es": "curiosidad", "de": "Neugier", "fr": "curiosité", "it": "curiosità",
                                                         "nl": "nieuwsgierigheid", "tr": "merak"]),
        Card(term: "severity", sentence: 14, meanings: ["es": "severidad", "de": "Strenge", "fr": "sévérité", "it": "severità",
                                                        "nl": "strengheid", "tr": "sertlik"]),
        Card(term: "riddles", sentence: 17, meanings: ["es": "adivinanzas", "de": "Rätsel", "fr": "devinettes", "it": "indovinelli",
                                                       "nl": "raadsels", "tr": "bilmeceler"]),
        Card(term: "encouraging", sentence: 5, meanings: ["es": "alentador", "de": "aufmunternd", "fr": "encourageant",
                                                          "it": "incoraggiante", "nl": "bemoedigend", "tr": "cesaret verici"])
    ]

    /// Sentences 0–23 of chapter VII, in the order `SentenceSplitter` produces them.
    static let translations: [String: [String]] = [
        "es": [
            "Había una mesa puesta bajo un árbol delante de la casa, y la Liebre de Marzo y el Sombrerero estaban tomando el té en ella: un Lirón estaba sentado entre ellos, profundamente dormido, y los otros dos lo usaban como cojín, apoyando los codos sobre él y hablando por encima de su cabeza.",
            "«Muy incómodo para el Lirón», pensó Alicia; «aunque, como está dormido, supongo que no le importa».",
            "La mesa era grande, pero los tres estaban apretujados en una esquina: «¡No hay sitio!",
            "¡No hay sitio!», gritaron al ver que Alicia se acercaba.",
            "«¡Hay sitio de sobra!», dijo Alicia indignada, y se sentó en un gran sillón en un extremo de la mesa.",
            "«Toma un poco de vino», dijo la Liebre de Marzo en tono alentador.",
            "Alicia miró por toda la mesa, pero no había nada más que té.",
            "«No veo ningún vino», observó.",
            "«Es que no hay», dijo la Liebre de Marzo.",
            "«Entonces no ha sido muy educado ofrecerlo», dijo Alicia enfadada.",
            "«Tampoco ha sido muy educado sentarse sin que te inviten», dijo la Liebre de Marzo.",
            "«No sabía que la mesa era vuestra», dijo Alicia; «está puesta para muchos más de tres».",
            "«Te hace falta un corte de pelo», dijo el Sombrerero.",
            "Llevaba un rato mirando a Alicia con gran curiosidad, y estas fueron sus primeras palabras.",
            "«Deberías aprender a no hacer comentarios personales», dijo Alicia con cierta severidad; «es de muy mala educación».",
            "Al oír esto, el Sombrerero abrió mucho los ojos, pero lo único que dijo fue: «¿En qué se parece un cuervo a un escritorio?».",
            "«¡Vaya, ahora nos vamos a divertir!», pensó Alicia.",
            "«Me alegra que hayan empezado con adivinanzas. Creo que esa la puedo adivinar», añadió en voz alta.",
            "«¿Quieres decir que crees que puedes encontrar la respuesta?», dijo la Liebre de Marzo.",
            "«Exactamente», dijo Alicia.",
            "«Entonces deberías decir lo que piensas», continuó la Liebre de Marzo.",
            "«Eso hago», respondió Alicia apresuradamente; «al menos… al menos pienso lo que digo, que viene a ser lo mismo, ¿sabes?».",
            "«¡No es lo mismo en absoluto!», dijo el Sombrerero.",
            "«¡Es como si dijeras que “veo lo que como” es lo mismo que “como lo que veo”!»."
        ],
        "de": [
            "Unter einem Baum vor dem Haus stand ein gedeckter Tisch, an dem der Märzhase und der Hutmacher Tee tranken: Zwischen ihnen saß eine Haselmaus und schlief fest, und die beiden anderen benutzten sie als Kissen, stützten die Ellbogen auf sie und unterhielten sich über ihren Kopf hinweg.",
            "„Sehr unbequem für die Haselmaus“, dachte Alice, „aber da sie schläft, macht es ihr wohl nichts aus.“",
            "Der Tisch war groß, doch die drei drängten sich alle an einer Ecke zusammen: „Kein Platz!",
            "Kein Platz!“, riefen sie, als sie Alice kommen sahen.",
            "„Es ist reichlich Platz!“, sagte Alice empört und setzte sich in einen großen Lehnstuhl am Ende des Tisches.",
            "„Nimm etwas Wein“, sagte der Märzhase aufmunternd.",
            "Alice sah sich auf dem ganzen Tisch um, aber es stand nichts darauf außer Tee.",
            "„Ich sehe keinen Wein“, bemerkte sie.",
            "„Es gibt auch keinen“, sagte der Märzhase.",
            "„Dann war es nicht sehr höflich von dir, welchen anzubieten“, sagte Alice ärgerlich.",
            "„Es war nicht sehr höflich von dir, dich ungebeten hinzusetzen“, sagte der Märzhase.",
            "„Ich wusste nicht, dass es euer Tisch ist“, sagte Alice, „er ist für viel mehr als drei gedeckt.“",
            "„Deine Haare müssten geschnitten werden“, sagte der Hutmacher.",
            "Er hatte Alice schon eine Weile mit großer Neugier betrachtet, und das waren seine ersten Worte.",
            "„Du solltest lernen, keine persönlichen Bemerkungen zu machen“, sagte Alice ziemlich streng, „das ist sehr unhöflich.“",
            "Der Hutmacher riss bei diesen Worten die Augen weit auf, sagte aber nur: „Warum ist ein Rabe wie ein Schreibtisch?“",
            "„Schön, jetzt wird es lustig!“, dachte Alice.",
            "„Wie gut, dass sie mit Rätseln anfangen. Das kann ich bestimmt erraten“, fügte sie laut hinzu.",
            "„Meinst du, dass du die Antwort darauf herausfinden kannst?“, fragte der Märzhase.",
            "„Genau“, sagte Alice.",
            "„Dann solltest du sagen, was du meinst“, fuhr der Märzhase fort.",
            "„Das tue ich doch“, antwortete Alice hastig, „jedenfalls … jedenfalls meine ich, was ich sage, und das ist doch dasselbe.“",
            "„Ganz und gar nicht dasselbe!“, sagte der Hutmacher.",
            "„Dann könntest du ja gleich sagen, ‚Ich sehe, was ich esse‘ sei dasselbe wie ‚Ich esse, was ich sehe‘!“"
        ],
        "fr": [
            "Une table était dressée sous un arbre devant la maison, et le Lièvre de Mars et le Chapelier y prenaient le thé : un Loir était assis entre eux, profondément endormi, et les deux autres s’en servaient comme d’un coussin, les coudes posés sur lui, en parlant par-dessus sa tête.",
            "« Bien inconfortable pour le Loir, pensa Alice ; mais comme il dort, je suppose que ça lui est égal. »",
            "La table était grande, mais tous trois étaient serrés dans un coin : « Pas de place !",
            "Pas de place ! » s’écrièrent-ils en voyant arriver Alice.",
            "« Il y a plein de place ! » dit Alice, indignée, et elle s’assit dans un grand fauteuil au bout de la table.",
            "« Prends donc du vin », dit le Lièvre de Mars d’un ton encourageant.",
            "Alice fit le tour de la table du regard, mais il n’y avait rien d’autre que du thé.",
            "« Je ne vois pas de vin », remarqua-t-elle.",
            "« Il n’y en a pas », dit le Lièvre de Mars.",
            "« Alors ce n’était pas très poli de m’en offrir », dit Alice avec colère.",
            "« Ce n’était pas très poli de t’asseoir sans y être invitée », dit le Lièvre de Mars.",
            "« Je ne savais pas que c’était votre table, dit Alice ; elle est mise pour bien plus de trois personnes. »",
            "« Tu as besoin d’une coupe de cheveux », dit le Chapelier.",
            "Il regardait Alice depuis un moment avec une grande curiosité, et c’étaient ses premiers mots.",
            "« Tu devrais apprendre à ne pas faire de remarques personnelles, dit Alice avec une certaine sévérité ; c’est très impoli. »",
            "À ces mots, le Chapelier ouvrit de grands yeux, mais il se contenta de dire : « Pourquoi un corbeau ressemble-t-il à un bureau ? »",
            "« Bon, on va enfin s’amuser ! » pensa Alice.",
            "« Je suis contente qu’ils commencent les devinettes. Je crois que je peux trouver celle-là », ajouta-t-elle à voix haute.",
            "« Tu veux dire que tu penses pouvoir en trouver la réponse ? » demanda le Lièvre de Mars.",
            "« Exactement », dit Alice.",
            "« Alors tu devrais dire ce que tu penses », poursuivit le Lièvre de Mars.",
            "« C’est ce que je fais, répondit vivement Alice ; du moins… du moins je pense ce que je dis, c’est la même chose, tu sais. »",
            "« Pas du tout la même chose ! » dit le Chapelier.",
            "« Autant dire que “je vois ce que je mange” est la même chose que “je mange ce que je vois” ! »"
        ],
        "it": [
            "C’era una tavola apparecchiata sotto un albero davanti alla casa, e la Lepre Marzolina e il Cappellaio vi prendevano il tè: un Ghiro sedeva in mezzo a loro, profondamente addormentato, e gli altri due lo usavano come cuscino, appoggiandovi i gomiti e parlandosi sopra la sua testa.",
            "«Molto scomodo per il Ghiro», pensò Alice; «però, visto che dorme, immagino che non gli importi.»",
            "La tavola era grande, ma i tre stavano tutti stretti in un angolo: «Non c’è posto!",
            "Non c’è posto!» gridarono quando videro arrivare Alice.",
            "«C’è posto in abbondanza!» disse Alice indignata, e si sedette in una grande poltrona a un capo della tavola.",
            "«Prendi un po’ di vino», disse la Lepre Marzolina in tono incoraggiante.",
            "Alice guardò tutta la tavola, ma non c’era nient’altro che tè.",
            "«Non vedo nessun vino», osservò.",
            "«Non ce n’è», disse la Lepre Marzolina.",
            "«Allora non è stato molto educato offrirlo», disse Alice arrabbiata.",
            "«Non è stato molto educato sederti senza essere invitata», disse la Lepre Marzolina.",
            "«Non sapevo che fosse la vostra tavola», disse Alice; «è apparecchiata per molti più di tre.»",
            "«I tuoi capelli hanno bisogno di un taglio», disse il Cappellaio.",
            "Guardava Alice da un po’ con grande curiosità, e queste furono le sue prime parole.",
            "«Dovresti imparare a non fare osservazioni personali», disse Alice con una certa severità; «è molto scortese.»",
            "A queste parole il Cappellaio spalancò gli occhi, ma disse soltanto: «Perché un corvo somiglia a una scrivania?»",
            "«Bene, adesso ci divertiremo!» pensò Alice.",
            "«Sono contenta che abbiano cominciato con gli indovinelli. Credo di poterlo indovinare», aggiunse ad alta voce.",
            "«Vuoi dire che pensi di poter trovare la risposta?» disse la Lepre Marzolina.",
            "«Esattamente», disse Alice.",
            "«Allora dovresti dire quello che pensi», continuò la Lepre Marzolina.",
            "«Lo faccio», rispose Alice in fretta; «almeno… almeno penso quello che dico, che è la stessa cosa, sai.»",
            "«Non è affatto la stessa cosa!» disse il Cappellaio.",
            "«Sarebbe come dire che “vedo quello che mangio” è la stessa cosa di “mangio quello che vedo”!»"
        ],
        "nl": [
            "Onder een boom voor het huis stond een gedekte tafel, waaraan de Maartse Haas en de Hoedenmaker thee zaten te drinken: tussen hen in zat een Relmuis, diep in slaap, en de andere twee gebruikten hem als kussen, met hun ellebogen op hem geleund, en praatten over zijn hoofd heen.",
            "‘Erg ongemakkelijk voor de Relmuis,’ dacht Alice, ‘maar omdat hij slaapt, vindt hij het vast niet erg.’",
            "De tafel was groot, maar de drie zaten dicht opeengepakt aan één hoek: ‘Geen plaats!",
            "Geen plaats!’ riepen ze toen ze Alice zagen aankomen.",
            "‘Er is plaats genoeg!’ zei Alice verontwaardigd, en ze ging in een grote leunstoel aan het eind van de tafel zitten.",
            "‘Neem wat wijn,’ zei de Maartse Haas bemoedigend.",
            "Alice keek de hele tafel rond, maar er stond niets op behalve thee.",
            "‘Ik zie geen wijn,’ merkte ze op.",
            "‘Die is er ook niet,’ zei de Maartse Haas.",
            "‘Dan was het niet erg beleefd om die aan te bieden,’ zei Alice boos.",
            "‘Het was ook niet erg beleefd om te gaan zitten zonder uitgenodigd te zijn,’ zei de Maartse Haas.",
            "‘Ik wist niet dat het jullie tafel was,’ zei Alice, ‘hij is gedekt voor veel meer dan drie.’",
            "‘Je haar moet geknipt worden,’ zei de Hoedenmaker.",
            "Hij had Alice al een tijdje met grote nieuwsgierigheid aangekeken, en dit waren zijn eerste woorden.",
            "‘Je moet leren geen persoonlijke opmerkingen te maken,’ zei Alice nogal streng, ‘dat is erg onbeleefd.’",
            "De Hoedenmaker zette grote ogen op toen hij dit hoorde, maar hij zei alleen: ‘Waarom lijkt een raaf op een schrijfbureau?’",
            "‘Fijn, nu wordt het leuk!’ dacht Alice.",
            "‘Ik ben blij dat ze met raadsels beginnen. Ik denk dat ik dat kan raden,’ voegde ze er hardop aan toe.",
            "‘Bedoel je dat je denkt dat je het antwoord kunt vinden?’ vroeg de Maartse Haas.",
            "‘Precies,’ zei Alice.",
            "‘Dan moet je zeggen wat je bedoelt,’ ging de Maartse Haas verder.",
            "‘Dat doe ik,’ antwoordde Alice haastig, ‘tenminste… tenminste bedoel ik wat ik zeg, en dat is hetzelfde, weet je.’",
            "‘Helemaal niet hetzelfde!’ zei de Hoedenmaker.",
            "‘Dan kun je net zo goed zeggen dat “ik zie wat ik eet” hetzelfde is als “ik eet wat ik zie”!’"
        ],
        "tr": [
            "Evin önündeki bir ağacın altına bir masa kurulmuştu; Mart Tavşanı ile Şapkacı orada çay içiyordu: aralarında mışıl mışıl uyuyan bir Fındık Faresi oturuyordu, öteki ikisi onu yastık gibi kullanıyor, dirseklerini üstüne dayayıp başının üzerinden konuşuyordu.",
            "“Fındık Faresi için çok rahatsız,” diye düşündü Alice, “ama uyuduğuna göre herhalde aldırmıyordur.”",
            "Masa büyüktü, ama üçü de bir köşesine sıkışmıştı: “Yer yok!",
            "Yer yok!” diye bağırdılar Alice’in geldiğini görünce.",
            "“Bol bol yer var!” dedi Alice öfkeyle ve masanın bir ucundaki büyük bir koltuğa oturdu.",
            "“Biraz şarap al,” dedi Mart Tavşanı cesaret verici bir sesle.",
            "Alice masanın her yanına baktı, ama üzerinde çaydan başka bir şey yoktu.",
            "“Hiç şarap göremiyorum,” dedi.",
            "“Yok zaten,” dedi Mart Tavşanı.",
            "“O zaman ikram etmen pek kibarca değildi,” dedi Alice kızgınlıkla.",
            "“Davet edilmeden oturman da pek kibarca değildi,” dedi Mart Tavşanı.",
            "“Masanın sizin olduğunu bilmiyordum,” dedi Alice, “üç kişiden çok daha fazlası için kurulmuş.”",
            "“Saçlarının kesilmesi lazım,” dedi Şapkacı.",
            "Bir süredir Alice’e büyük bir merakla bakıyordu ve bu onun ilk sözüydü.",
            "“Kişisel yorumlar yapmamayı öğrenmelisin,” dedi Alice biraz sert bir şekilde, “bu çok kaba.”",
            "Şapkacı bunu duyunca gözlerini kocaman açtı, ama tek söylediği şu oldu: “Kuzgun neden yazı masasına benzer?”",
            "“Hah, şimdi eğlenceli olacak!” diye düşündü Alice.",
            "“Bilmece sormaya başlamalarına sevindim. Sanırım bunu bilebilirim,” diye ekledi yüksek sesle.",
            "“Yani cevabını bulabileceğini mi düşünüyorsun?” dedi Mart Tavşanı.",
            "“Aynen öyle,” dedi Alice.",
            "“O zaman ne demek istiyorsan onu söylemelisin,” diye devam etti Mart Tavşanı.",
            "“Öyle yapıyorum,” diye cevap verdi Alice aceleyle, “en azından… en azından söylediğimi kastediyorum, bu da aynı şey, biliyorsun.”",
            "“Hiç de aynı şey değil!” dedi Şapkacı.",
            "“O zaman ‘Yediğimi görürüm’ ile ‘Gördüğümü yerim’ aynı şeydir de diyebilirsin!”"
        ]
    ]
}
