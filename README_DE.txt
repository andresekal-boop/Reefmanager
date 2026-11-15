MEERWASSER-LOGBUCH – iOS-PROJEKT (UNSIGNIERTE IPA)
==================================================

Dieses Projekt verpackt deine HTML-Datei als native iOS-App (WKWebView)
inklusive Unterstützung für iOS-Dialoge (alert, confirm, prompt),
externe Safari-Links sowie JSON-/CSV-Dateiexport über das iOS-Teilen-Menü.

SO ERSTELLST DU DIE UNSIGNIERTE IPA OHNE EIGENEN MAC (ÜBER GITHUB ACTIONS)
-------------------------------------------------------------------------
1. Entpacke diese ZIP-Datei vollständig.
2. Erstelle auf GitHub ein neues Repository (z. B. "MeerwasserLogbuch-iOS")
   oder lade den Inhalt des Ordners "MeerwasserLogbuch-iOS" in ein Repository hoch
   (wichtig: der versteckte Ordner ".github/workflows/ios.yml" muss im
   Hauptverzeichnis des Repositories liegen!).
3. Öffne auf GitHub den Reiter "Actions".
4. Wähle links den Workflow "iOS Unsigned IPA" aus und klicke rechts auf
   "Run workflow" (oder warte, falls er durch den Push automatisch gestartet ist).
5. Nach ca. 2–3 Minuten ist der Build fertig. Scrolle ganz nach unten zu
   "Artifacts" und lade "Meerwasser-Logbuch-IPA" herunter.
6. Darin befindet sich deine fertige "MeerwasserLogbuch-unsigned.ipa".

SO INSTALLIERST DU DIE UNSIGNIERTE IPA AUF DEM IPHONE
-----------------------------------------------------
- Mit Sideloadly (Windows / macOS):
  IPA in Sideloadly ziehen, eigene kostenlose Apple-ID eintragen und auf
  "Start" klicken. Sideloadly signiert die Datei automatisch für 7 Tage und
  installiert sie auf dem iPhone.
- Mit AltStore / SideStore:
  IPA direkt auf dem iPhone in AltStore/SideStore öffnen und installieren.
- Mit TrollStore (falls unterstützt):
  IPA direkt dauerhaft installieren.

ALTERNATIV: LOKAL AUF EINEM MAC MIT XCODE BAUEN
-----------------------------------------------
1. Homebrew & XcodeGen installieren: `brew install xcodegen`
2. Im Terminal in den Ordner `MeerwasserLogbuch-iOS` wechseln und
   `xcodegen generate` ausführen.
3. Die erzeugte Datei `MeerwasserLogbuch.xcodeproj` in Xcode öffnen.
4. Entweder direkt auf das verbundene iPhone installieren oder über
   Product > Archive exportieren.

Wichtige Hinweise
-----------------
- App-ID: de.andresekal.meerwasserlogbuch
- Mindestversion: iOS 15.0
- Alle Daten werden lokal im WebView-Speicher gesichert. Nutze regelmäßig
  die Export-Funktion unter Mehr > Daten, um Backups in "Dateien" oder
  iCloud zu sichern.
