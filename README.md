# Meine Apps

Tobis Übersicht über alle seine Apps: Für jede App zeigt sie, wer sie an
welchem der letzten 14 Tage benutzt hat. Wo jemand zugestimmt hat, stehen auch
Werte und Einträge da: bei Uwe (Mahlzeit) die Werte und, nach seinem „Ja“,
das Essen, bei Body Check das Tagebuch, das jemand dort ausdrücklich teilt.

**Adresse:** <https://finanzdienste.github.io/Apps/> – das Passwort ist
dasselbe wie für die Übersicht in der Workout-App.

Keine Abhängigkeiten zur Laufzeit, kein Bauschritt. Die Daten kommen aus Tobis
Supabase-Projekt, über Funktionen, die ein Passwort wollen. Der letzte Stand
liegt auf dem Gerät, ohne Netz steht er sofort da.

## Als App aufs Handy, ohne Startbildschirm (a6)

> Tobi, 26.11.2026: *„Ich will die Master Übersicht als App auf mein Handy
> downloaden aber nicht aufm startbildschirm haben“*

**Vorher (bis a5):** Die Seite lag unter `/Workout/apps/` im Repo Workout.
Android zählt aber alles unter der Adresse einer installierten App zu dieser
App. Die Workout-App ist auf Tobis Handy installiert, also hätte Chrome nur
„bereits installiert“ gemeldet. So war es schon bei Freizeit
(`/Workout/freizeit/`), die deshalb ein eigenes Repo bekam.

**Jetzt:**
- **Eigene Adresse:** Die Seite hat ein eigenes Repo und die Adresse `/Apps/`
  (Manifest-`id` `/Apps/`).
- **Weiterleitung:** `/Workout/apps/` leitet hierher weiter (samt `#…`) und
  meldet dabei den alten Service Worker ab.
- **Passwort und Stand gehen mit:** Sie liegen im `localStorage` von
  finanzdienste.github.io, und den teilen sich beide Adressen.

**Installieren ohne Symbol auf dem Startbildschirm** (Samsung, Chrome):
1. Startbildschirm lange drücken → **Einstellungen** → **Neue Apps zum
   Startbildschirm hinzufügen** aus.
2. Die Adresse in Chrome öffnen → **⋮** → **App installieren**.
3. Kommt trotzdem ein Symbol: lange drücken → **Entfernen** (nicht
   „Deinstallieren“).

Die App bleibt in der App-Übersicht (vom Startbildschirm nach oben wischen).

## Aufbau

| Datei | Aufgabe |
| --- | --- |
| `index.html`, `css/apps.css` | die Seite |
| `js/app.js` | Anmelden, Holen (`apps_uebersicht`, `bodycheck_lesen`, `mahlzeit_lesen`), Stand auf dem Gerät, Zeichnen |
| `js/modell.js` | aus den Zahlen je App: wer, wann, an welchen Tagen; `APPS` ist die Liste aller Apps |
| `js/tagebuch.js` | das geteilte Tagebuch aus Body Check, nach Tagen |
| `js/werte.js` | Uwes Werte und Essen aus Mahlzeit, nach Tagen |
| `js/bodycheck-woerter.js` | Namen zu den Kennungen von Body Check, erzeugt von `node tools/bodycheck-woerter.mjs <Klon von Bauchbuch>` |
| `sw.js` | offline: Hülle im Vorrat `meineapps-<VERSION>`, Symbole der anderen Apps in `meineapps-bilder` |
| `tools/apps-uebersicht.sql` | die Funktionen in Supabase (`apps_uebersicht`, `apps_tag` mit Triggern, `mahlzeit_lesen`) |
| `tools/apps-icons.mjs` | die PNG-Symbole aus `icon.svg` |
| `tests/test-apps.mjs` | der Test (Supabase gespielt, Server wirklich aus) |

**Eine neue Fassung:** `VERSION` in `sw.js` und `FASSUNG` in `js/app.js`
zusammen hochzählen. **Eine neue App oder Quelle** kommt in `APPS` in
`js/modell.js` und in die SQL-Funktion.

**Testen:**
- `npm ci`, dann `node tests/test-apps.mjs` und `npm run lint`.
- Playwright 1.56.1 braucht sein Chromium (`npx playwright install chromium`).

Die Tabellen und Funktionen der anderen Apps (`mahlzeit_essen` in Workout
`mahlzeit/supabase/essen.sql`, `bodycheck_*` im Repo Bauchbuch) gehören
diesen Apps; hier wird nur gelesen.

## Wie es anfing (Workout v274, 25.11.2026)

> Tobi, 25.11.2026: *„Können wir mir nicht mal ne masterübersicht aus allen
> meinen Apps bauen damit ich seh ob die genutzt werden?“*

**Vorher:** Jede App meldete etwas, aber jede an einer anderen Stelle – die
Workout-Übersicht unter *Mehr*, die Schilddrüse in `schilddruese/uebersicht.html`,
Mahlzeit nur auf Nachfrage per SQL, Freizeit nur dem Gastgeber in der App, das
Widget nur auf dem Startbildschirm. Ob eine App überhaupt benutzt wird, sah man
nirgends auf einen Blick.

**Damals:** <https://finanzdienste.github.io/Workout/apps/> (seit a6 unter /Apps/, siehe oben) – eine Seite für
den Startbildschirm, je App eine Karte: eine Ampel (grün bis 2 Tage, gelb bis 7,
rot länger, grau noch nie), 14 Kästchen für die letzten 14 Tage und darunter
wer: „Uwe · heute · an 7 von 14 Tagen · 29 Einträge“. Oben ein Satz: „In den
letzten 7 Tagen benutzt: 6 von 8 Apps. Still: Frag mal (seit 12.11.),
Schilddrüse (noch nie).“ Zuletzt benutzte Apps stehen oben. Das Passwort ist
dasselbe wie für die Workout-Übersicht; die Seite merkt es sich auf dem Gerät
(*Abmelden* nimmt es und den Stand wieder weg).

| App | Woher die Seite es weiß |
| --- | --- |
| Workout | Bildschirmzeit-Widget (Tobi, mit Minuten) und Rückkanal (`nutzung`, je Name, mit letztem Training) |
| Boxenstopp | Widget und KI-Anfragen (`fragmal_kosten`, app `boxenstopp`). **Blind** für Amy und Marielle: Boxenstopp meldet nichts, das steht auf der Karte. |
| Bewerbungszentrale | Widget |
| Freizeit | Widget, „zuletzt in der App“ und Haken der Eingeladenen (`freizeit_person`, `freizeit_bock`) – die Eingeladenen wissen das („Tobi sieht deine Haken und wann du zuletzt in der App warst.“) |
| Mahlzeit | Lebenszeichen (`mahlzeit_nutzung`): Uwe heißt Uwe, andere Geräte „Gerät 1a2b“; ein Gerät, das nur einen Tag kurz offen war, steht unter „Weitere“. Seit a4 dazu Uwes Werte (`mahlzeit_lesen`, siehe unten) |
| Schilddrüse | Lebenszeichen (`sd_geraete`) – am 25.11. hatte sich noch kein Gerät gemeldet |
| Frag mal | Anmeldung und Weiterlaufen der Sitzung (`auth.sessions`), Antworten aus `fragmal_kosten` (app `fragmal`); die Konten heißen „Konto 1/2“ nach Reihenfolge |
| Bildschirmzeit-Widget | wann es zuletzt Zahlen geholt hat (`bildschirmzeit_geraet`); ohne Streifen, weil es keinen Verlauf gibt |
| Body Check | bis a2 nichts (die App versprach, dass nichts das Handy verlässt). Seit a3 das Tagebuch, das jemand ausdrücklich teilt (`bodycheck_lesen`, siehe unten); ohne das „nicht geteilt“, und es zählt nicht mit. |

**Der Server** ([`tools/apps-uebersicht.sql`](tools/apps-uebersicht.sql),
am 25.11. eingespielt): `apps_uebersicht(pass)` prüft das Passwort über
`admin_liste()` und gibt alles der letzten 60 Tage in einem Aufruf zurück –
Zahlen und Tage, keine Werte, keine Einträge, keine Kennungen (Geräte heißen
„Gerät 1a2b“, Freizeit-Personen eine Prüfsumme). Drei Quellen kennen nur den
letzten Tag (`nutzung`, `sd_geraete`, Freizeit); für sie schreibt ein Trigger
ab jetzt jeden Tag nach `apps_tag`, rückwirkend stand dort, was die Tabellen
hergaben. Der Trigger fängt jeden eigenen Fehler ab: Die Übersicht darf nie die
Meldung einer App kaputt machen. Er hängt auch an den Tabellen der Freizeit-App
(Kommentar am Trigger nennt dieses Repo).

**Offline zuerst:** Der letzte Stand liegt im `localStorage` und steht beim
Öffnen sofort da; ohne Netz „Ohne Netz – Stand von heute 14:05. Lädt von selbst,
sobald Netz da ist.“ Nachgeholt wird beim Ereignis `online`, beim Zurückkommen
in die App (älter als 2 Minuten) und mit *Neu laden*. Zum ersten Öffnen ohne Netz:
„Zum ersten Öffnen braucht die Übersicht Netz.“ Die Seite schickt nichts, also
gibt es nichts vorzumerken. `sw.js` hat einen eigenen Vorrat (bis a5 `apps-…`,
seit a6 `meineapps-…`, Symbole der anderen Apps in `meineapps-bilder`).

**Gefunden dabei:** Die Worker von Frag mal (`Amy/sw.js`) und Body Check
(`Bauchbuch/sw.js`) löschen beim Aktivieren *alle* Vorräte außer dem eigenen –
auf finanzdienste.github.io also auch die von Workout, Mahlzeit, Schilddrüse,
Boxenstopp und den anderen Apps. `sw.js` füllt seinen Vorrat deshalb nach
einem Seitenaufruf mit Netz neu, falls er fehlt. Behoben ist es erst, wenn die
beiden nur noch ihre eigenen Vorräte wegräumen (offen, 25.11.).

### Uwes Essen (Meine Apps a5)

> Tobi, 26.11.2026: *„Ja ich will das essen auch sehen. In meiner Master
> übersicht“*

**Vorher (a4):** Hier stand „Was Uwe isst, steht hier nicht: Mahlzeit schickt
es nicht.“ In der App stand Uwe gegenüber „Was du isst, geht nicht mit“.

**Jetzt:**
- **Uwe wird gefragt:** Seit Mahlzeit v14 fragt die App ihn einmal „Darf
  Tobi auch sehen, was du isst?“. Erst nach „Ja, darf er“ schickt sie die
  Einträge der letzten 60 Tage (`mahlzeit/README.md` v14).
- **Hier, unter „Werte von Uwe“:** je Tag „1.250 kcal gegessen“ und die
  Einträge nach Tageszeit, etwa „morgens Haferbrei (75 g × 2) · 550 kcal 🌾“.
  Oben steht dazu „Essen am 26.11.: 1.250 kcal, 2 Einträge“.
- **Solange nichts geteilt ist,** steht dort: „Sein Essen ist noch nicht
  geteilt: Mahlzeit fragt Uwe einmal, ob du es sehen darfst. Erst nach „Ja,
  darf er“ steht es hier.“
- **Bewertet wird nichts:** keine Farbe, kein Ziel.

Die Daten kommen aus `mahlzeit_lesen(pass)`, die jetzt zusätzlich `essen` aus
`mahlzeit_essen` liefert (eingespielt am 26.11.). Gelesen wird in
`js/werte.js` (`essenText()`).

Geprüft in `tests/test-apps.mjs`:
- Essen nach Tageszeit, Portion, Menge, Kalorien, Hafer
- ein Tag nur mit Essen
- ein Name als Text statt HTML
- ob geteilt ist

Gegen a4 rot.

### Uwes Werte aus Mahlzeit (Meine Apps a4)

> Tobi, 26.11.2026: *„Dachte wir haben bei Uwe jetzt eingestellt dass wir
> seine Sachen tiefgehend sehen können“*

**Vorher:** Seine Werte kamen seit Mahlzeit v13 bei Supabase an, aber die
Übersicht zeigte nur, *ob* Uwe die App benutzt. Nachsehen ging nur per SQL.
Uwe ist einverstanden: *„Uwe meinte ich kann all seine gesundheitsdaten haben“*
(21.11., `mahlzeit/README.md` v10/v13).

**Jetzt:** Die Karte Mahlzeit hat „▸ Werte von Uwe“, zugeklappt wie das
Tagebuch bei Body Check.
- **Oben** steht der letzte Wert je Art: „Gewicht am 26.11.: 126,2 kg (seit
  21.11.: +0,8 kg)“, Blutzucker mit Uhrzeit und „nüchtern/vor/nach dem
  Essen“, HbA1c, Schlaf, Schritte.
- **Darunter die Tage**, neuester zuerst, je Tag die Werte und die Zahlen des
  Lebenszeichens („9 Einträge · 1 × Sport · 3 × Hafer“).
- **Ältere Tage** (über 14 Tage, bis 60) stehen zugeklappt darunter.
- **Von der Uhr** (⌚, `mahlzeit_uhr`) zählt ein Wert nur, wenn die App für den
  Tag nicht schon einen derselben Art hat.
- **Wie in Mahlzeit selbst** wird nichts bewertet: keine Farbe, kein „zu hoch“.
  Beim Gewicht steht nur der Unterschied als Zahl.

**Der Server:** `mahlzeit_lesen(pass)` in
[`tools/apps-uebersicht.sql`](tools/apps-uebersicht.sql), eingespielt am
26.11., mit demselben Passwort über `admin_liste()`. Die Funktion gibt je Gerät
die Werte der letzten 60 Tage aus `mahlzeit_werte` und `mahlzeit_uhr` zurück.
Uwe steht zuerst, `testclaude01` fehlt. Ein Gerät, das nur Uhr-Zeilen hat und
nicht Uwe ist, war ein Test und erscheint nicht.

**Was Uwe isst, stand hier bis a4 nicht:** Mahlzeit schickte es nicht. In v13
wählte Tobi „Variante 2“, also nur die Werte. Seit a5 siehe „Uwes Essen“.

**Offline und Fehler** wie beim Tagebuch:
- Die Werte liegen mit im Stand auf dem Gerät.
- Lassen sie sich nicht holen, bleibt der letzte Stand, mit „Die Werte ließen
  sich gerade nicht holen – hier steht der Stand von …“.
- Gelesen wird in `js/werte.js`.

Geprüft in `tests/test-apps.mjs`:
- **In Node:** Überblick, Tage, zwei Blutzucker an einem Tag, Uhr nur als
  Lücke, das Testgerät, kaputte Werte.
- **Im Browser:** zugeklappt, aufgeklappt, nichts bewertet, ohne Netz, ein
  Server, der hakt.

Gegen a3 rot.

### Body Check: das geteilte Tagebuch (Meine Apps a3)

> Tobi, 25.11.2026: *„Body Check schickt jetzt Amys Tagebuch nach Supabase,
> sobald sie in der App zugestimmt hat. Lies es mit der Funktion
> bodycheck_lesen(pass). […] Zeig das in der Master-Übersicht bei Body Check
> an, statt „zählt bewusst nichts“: wann zuletzt aktualisiert, und Amys
> Einträge übersichtlich nach Tagen.“*

**Vorher:** Die Karte sagte „misst nichts“. Body Check versprach bis Fassung
30, dass nichts das Handy verlässt.

**Woher es kommt:** Seit Body Check Fassung 31/32 fragt die App
„Dein Tagebuch mit … teilen?“ und sagt dazu, dass dann *das ganze Tagebuch*
geht („alle Einträge, Mittel, Werte und Notizen“). Vor „Ja, teilen“ geht nichts
weg. „Teilen beenden“ unter *Mehr* bittet den Server, den Stand zu löschen
(`bodycheck_beenden`). Geschrieben wird nur mit einem Kopplungsschlüssel
(`bodycheck_kopplung`). Gelesen wird über `bodycheck_lesen(pass)` mit dem
Passwort der Übersichten: je Gerät `name`, `geraet` („Gerät 1a2b“),
`aktualisiert`, `fassung` und `stand`. Gebaut hat das eine andere Sitzung im
Repo Bauchbuch, nicht dieses Repo. Am 25.11. war noch nichts geteilt (0
Zeilen).

**Jetzt:** *Meine Apps* holt beim Laden zusätzlich `bodycheck_lesen`.
- **Ist etwas geteilt:** Body Check zählt wie jede App. Benutzt ist ein Tag
  mit Einträgen oder Tageswerten, dazu der Tag der letzten Aktualisierung.
  Unter dem Namen steht zum Beispiel „Amy · heute · an 3 von 14 Tagen ·
  7 Einträge in 14 Tagen · aktualisiert heute um 14:05“.
- **Das Tagebuch selbst** ist zugeklappt („▸ Tagebuch von Amy“), damit es nicht
  gleich offen dasteht, wenn jemand mit aufs Handy schaut. Aufgeklappt stehen
  die Tage der letzten 14 Tage, neuester zuerst („Mi 25.11.“): die Tageswerte
  („Stimmung: gut · Schlaf: ok · Wasser: 5 Gläser“), die Tagesnotiz und die
  Einträge nach Uhrzeit („08:10 Essen Haferflocken · Milchprodukte · Kaffee
  (Getränk)“). Ältere Tage stehen zugeklappt darunter, die regelmäßigen Mittel
  oben. Was aufgeklappt war, bleibt es auch nach dem Nachladen.
- **Ist nichts geteilt:** „nicht geteilt“, dazu ein Satz, dass Body Check erst
  nach „Ja, teilen“ schickt. In „6 von 8 Apps“ zählt es dann nicht mit.
- **Teilen beendet:** Der Server gibt nichts mehr zurück, und beim nächsten
  Laden ist das Tagebuch auch aus dem Speicher dieses Geräts weg.
- **Lässt sich nur das Tagebuch nicht holen** (Fehler beim Server): Der Rest
  ist frisch, das Tagebuch bleibt auf seinem letzten Stand, mit „Das Tagebuch
  ließ sich gerade nicht holen – hier steht der Stand von …“.
- **Ohne Netz:** Das Tagebuch liegt mit im Stand auf dem Gerät und steht wie
  alles andere da.

**Die Namen** zu den Kennungen (Beschwerden, Zutaten, Stuhlformen,
Tagesfragen …) kommen aus Body Check selbst: `node tools/bodycheck-woerter.mjs
<Klon von Bauchbuch>` schreibt `js/bodycheck-woerter.js`. Eigene Auslöser
und Aktivitäten bringt der Stand mit. Eine Kennung, die erst später dazukommt,
steht bis zum nächsten Lauf so da, wie sie ist. Gelesen wird der Stand in
`js/tagebuch.js`, alles als Text, nie als HTML.

Geprüft in `tests/test-apps.mjs`:
- **In Node:** Tage, Einträge, Tageswerte, Mittel, eigene Auslöser,
  unbekannte Kennungen, ein Tag in der Zukunft, ein kaputter Stand, zwei
  Geräte.
- **Im Browser:** zugeklappt, dann aufgeklappt, Notiz als Text, aufgeklappt
  nach dem Nachladen, ohne Netz, ein Server, der hakt, „Teilen beenden“ (auch
  aus dem Speicher weg), dasselbe Passwort für beide Aufrufe.

Gegen a2 rot.

### Passwort vergessen (Meine Apps a2)

> Tobi, 25.11.2026: *„Ich kenn mein Passwort zur Workout app nicht mehr“*

Ein Passwort gilt für alle drei Übersichten: *Mehr → Übersicht* in der
Workout-App, `schilddruese/uebersicht.html` und *Meine Apps*. Es steckt in
`admin_liste()`; die beiden anderen fragen diese Funktion. Bis zum 25.11. stand
es dort im Klartext. Seitdem steht dort nur die SHA-256-Prüfsumme, und ein
falsches Passwort kostet eine Sekunde. Das alte wurde nicht ausgelesen, sondern
durch ein zufälliges ersetzt (drei Vierergruppen, ohne verwechselbare Zeichen).

Neu setzen: ein Passwort ausdenken oder würfeln, die Prüfsumme bilden
(`printf %s 'NEUES-PASSWORT' | sha256sum`) und in Supabase → SQL Editor:

```sql
create or replace function public.admin_liste(pass text)
returns setof nutzung
language plpgsql security definer set search_path = public, pg_temp as $$
begin
  if pass is null
     or encode(sha256(convert_to(pass, 'UTF8')), 'hex') is distinct from 'PRÜFSUMME' then
    perform pg_sleep(1);
    raise exception 'nope' using errcode = '42501';
  end if;
  return query select * from nutzung order by einheiten desc;
end $$;
```

Rechte und Aufrufer bleiben dabei, wie sie sind. Das Passwort selbst gehört in
kein Repo, keine Notiz und keine Datei. Unter dem Passwortfeld von *Meine Apps*
steht deshalb: „Vergessen? Sag Claude Bescheid – es setzt ein neues.“

Eine neue Fassung der Seite: `VERSION` in `sw.js` und `FASSUNG` in
`js/app.js` zusammen hochzählen; die Symbole kommen aus
`node tools/apps-icons.mjs`.

Geprüft in `tests/test-apps.mjs` (Supabase gespielt, Server wirklich aus):
das Rechnen in Node (wer, wann, an wie vielen Tagen, Minuten nur aus den 14
Tagen, Tobi aus Widget und Rückkanal ist eine Person, Tag in Berlin, Ampel,
Reihenfolge, leere Antwort); im Browser falsches und richtiges Passwort, je App
eine Karte, Namen als Text statt HTML, kein Wischen zur Seite, neu geöffnet
sofort der letzte Stand, ohne Netz mit Stand und Hinweis, `online` holt nach,
Abmelden und erstes Öffnen ohne Netz. (Dass der Workout-Worker unter `/Workout/apps/`
nicht die Workout-App ausliefert, prüft seit a6 das Repo Workout.) Gegen v273 rot.

