# Hinweise für Claude

## Ultracode-Empfehlung
Bevor du mit einer Aufgabe anfängst: Wenn sie sich für einen Workflow eignet
(dieselbe Arbeit über viele Dateien, eine Prüfung über das ganze Projekt oder
eine Aufgabe, die zu groß für einen einzelnen Agenten ist), schlag mir in einem
Satz vor, sie mit „ultracode“ laufen zu lassen, und warte auf meine Antwort.
Bei normalen Aufgaben erwähnst du Ultracode nicht.

## Modell und Aufwand
Bevor du mit einer Aufgabe anfängst: Passt sie deutlich besser zu einem anderen
Modell oder Aufwand als dem laufenden, schlag mir das in einem Satz vor – mit
Grund und dem Befehl, den ich als Nachricht schicke (`/model fable|opus|sonnet`,
`/effort low|medium|high|xhigh|max`). Was gerade läuft, zeigt `get_session`
(`model`, `effort_level`); am 11.11.2026 war es Opus 5.5 mit Aufwand max.
- **Nur melden, wenn etwas zu ändern ist** (Tobi, 26.11.2026: „Dass Opus okay
  ist brauch ich nicht zu wissen, ich brauch nur zu wissen wenn was geändert
  werden muss“): Kein Schlusssatz mehr wie „passt – nichts umstellen“. Sollte
  etwas umgestellt werden (Modell, Aufwand, neuer Chat), am Ende ein Satz mit
  Grund und dem genauen Befehl.
- **Neuer Chat** (Tobi, 26.11.2026: „in allen Chats bescheid geben wenn ein
  neuer Chat nötig ist“): von selbst in einem Satz sagen, sobald einer nötig
  ist – wenn `get_session` mehr als etwa 80 % von `context_usage.max_tokens`
  belegt zeigt, wenn du merkst, dass du mit veraltetem oder widersprüchlichem
  Stand arbeitest, oder bei einem anderen Projekt. Ein neues Thema im selben
  Projekt und ein schon zusammengefasster Verlauf allein sind kein Grund
  (Tobi, 26.11.2026: „dass hier Infos zusammengefasst wurden ist schlechter
  als bei nem neuen chat komplett von 0 zu beginnen?“ – nein). Vorher alles Offene in die Dateien schreiben und einen kurzen
  Starttext zum Einfügen mitgeben.
- **Mehr** – vorschlagen und auf meine Antwort warten: `/model fable`, dazu
  `/effort high`, wenn die Ursache nach dem ersten Durchgang unklar ist, ein
  Fehler nach einer Korrektur wiederkommt oder viel ineinandergreift (Service
  Worker, Pausen-Uhr, Kalender-Sync, Sicherung, Planberechnung). Fable kostet kein Nutzungsguthaben (Tobi, 26.11.2026; Guthaben kostet nur
  die Claude-API). Ist der Aufwand gerade gesenkt, zuerst zurück auf
  `/effort max`.
- **Weniger** – nicht warten, erledigen und am Ende in einem Satz sagen, dass
  für Aufgaben dieser Art `/effort high` (oder `medium`) reicht: Texte und
  Zahlen in `tools/exercise-meta.json`, Formulierungen im README. Für eine
  einzelne schwere Frage genügt dann „ultrathink“ in meiner Nachricht.
- Lieber den Aufwand senken als zu Sonnet wechseln, und nicht hin und her: Nach
  einem Modellwechsel wird der ganze Verlauf ohne Zwischenspeicher neu gelesen.
- `/fast` (dasselbe Modell schneller, kostet Guthaben extra) nur, wenn ich auf
  etwas warte, das eilt.

## Offline zuerst
Tobi, 22.11.2026: „Generell sollen all meine Apps auch so weit wie möglich
offline funktionieren.“ Das gilt für jede Änderung und jede neue Funktion:
- Was ohne Netz gehen kann, geht ohne Netz: App-Hülle und zuletzt geladene
  Daten liegen im Vorrat von `sw.js`, ebenso Bilder und Kartenkacheln, die
  man schon gesehen hat.
- Änderungen ohne Netz werden lokal gemerkt und von selbst nachgeschickt –
  beim Ereignis `online`, beim nächsten Abgleich und beim nächsten Start.
  Nichts geht verloren, nichts kommt doppelt an, und was sich inzwischen
  anderswo geändert hat, wird zusammengeführt statt überschrieben.
- Was nur mit Netz geht, wird ohne Netz vorgemerkt und läuft von selbst,
  sobald Netz da ist – Tobi, 22.11.2026: „sowas wie mails senden könnte er sich
  doch vormerken und dann machen sobald er internet hat“. Also Mails senden,
  KI-Aufträge und Ähnliches: sichtbar „wartet auf Netz“ (mit „Nicht senden“),
  vor dem Ausführen gegen den neuesten Stand geprüft, nie doppelt. Braucht es
  eine Anmeldung, die nur nach einem Tipp aufgeht (Google), reicht dann ein Tipp.
  Nur was sich nicht vormerken lässt (neue Angebote, eine Suche, Push), sagt
  ohne Netz in einem Satz, dass es Netz braucht; der Rest bleibt benutzbar.
- Neue Funktionen bekommen einen Test ohne Netz (Server aus oder Anfragen
  abbrechen – Playwrights `setOffline()` schneidet die Anfragen des Service
  Workers nicht ab).

## Das Repository
- **Meine Apps**: Tobis Übersicht, wer welche seiner Apps wann benutzt –
  live unter https://finanzdienste.github.io/Apps/ (GitHub Pages von `main`).
  Bis a5 lag sie im Repo Workout unter `apps/`; seit a6 hier, weil Android
  unter `/Workout/` nicht als eigene App installiert (README „Als App aufs
  Handy“). `/Workout/apps/` leitet nur noch weiter.
- **`README.md` ist das Gedächtnis**: jede Entscheidung mit Tobis Zitat, was
  vorher war, was jetzt gilt, warum, und wo es geprüft wird.

## Mit Tobi arbeiten
- Deutsch. Er schreibt kurz, meist vom Handy (Samsung, Chrome). Antworten
  knapp und direkt.
- Jede Rückmeldung wird eine Änderung an der App, nicht bloß eine Erklärung.
- Nachfragen nur, wenn die Antwort etwas ändert. Was er selbst tun muss, als
  genaue Klickfolge.

## Regeln
- Nach jeder Änderung an einer Datei aus `SHELL` (sw.js): `VERSION` in
  `sw.js` und `FASSUNG` in `js/app.js` zusammen hochzählen (a6, a7, …);
  neue Module in `SHELL`. `tests/test-apps.mjs` prüft beides.
- Test erweitern, der gegen die alte Fassung rot ist; dazu `npm run lint`.
- Supabase-Projekt vjyohppohmvhhxgwouti: SQL steht in
  `tools/apps-uebersicht.sql` und wird über den Supabase-Connector als
  Migration eingespielt. Alle Lesefunktionen prüfen das Passwort über
  `admin_liste()` (nur eine Prüfsumme, README „Passwort vergessen“). **Das
  Passwort nie ins Repo, in Notizen oder in Commits.**
- Werte und Einträge Dritter (Uwe, Amy) nur, wo sie zugestimmt haben, und nur
  zeigen, nicht bewerten. Alles als Text, nie als HTML (`esc()`).
- Ausgeliefert wird von `main`. Push auf `main`, dann live prüfen: `sw.js`
  von https://finanzdienste.github.io/Apps/ laden und `VERSION` vergleichen.
