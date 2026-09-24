---
title: "Coffee Diary – Release (Xcode Cloud + Fastlane)"
layout: default
---

# Release: Xcode Cloud + Fastlane

Ziel: **Xcode Cloud** baut das Archiv und lädt es nach App Store Connect / TestFlight. **Fastlane (`deliver`)** setzt Metadaten, hängt den Build an die Version und drückt **Zur Prüfung einreichen**.

```
Push → Xcode Cloud (Archive) → ASC / TestFlight
                              ↓
              Cursor: bundle exec fastlane release
                              ↓
                    App Review (automatische Freigabe)
```

---

## Einmalig einrichten

### 1. App Store Connect API Key

1. [App Store Connect](https://appstoreconnect.apple.com) → **Users and Access** → **Integrations** → **App Store Connect API**
2. Key mit Rolle **App Manager** oder **Admin** erstellen
3. `.p8`-Datei speichern, z. B. unter `~/.appstoreconnect/AuthKey_XXXXXXXXXX.p8`
4. Im Repo-Root:

```bash
cp .env.example .env
```

`.env` ausfüllen (`ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_KEY_PATH`).  
**.env und *.p8 niemals committen** (stehen in `.gitignore`).

### 2. Fastlane lokal

Ruby ist eingerichtet (Homebrew portable Ruby ≥ 3.2 in `~/.zshrc`). Im Repo:

```bash
cd /Users/yannik/Documents/Privat/Coding/CoffeeDiary
bundle install
```

### 3. Xcode Cloud Workflow (UI-Checkliste)

In Xcode (Scheme **CoffeeDiary**):

1. **Product → Xcode Cloud → Create Workflow…** (oder Workflow bearbeiten)
2. Repository mit GitHub verbinden (Branch `main` muss gepusht sein)
3. **Workflow-Einstellungen:**
   - **Name:** z. B. `Release` oder `TestFlight`
   - **Scheme:** `CoffeeDiary`
   - **Platform:** iOS
4. **Start Conditions (Trigger):**
   - [ ] Push auf Branch `main`, und/oder
   - [ ] Tag `v*` (z. B. `v1.2.0`)
5. **Actions:**
   - [ ] **Archive – iOS**
   - [ ] **Distribute App** → App Store Connect / TestFlight
6. **Build Number:**
   - [ ] „Increment build number“ / automatische Build-Erhöhung aktivieren (jeder Upload braucht eine höhere Build-Nummer als zuvor)
7. **TestFlight (optional):**
   - [ ] Interne Tester-Gruppe zuweisen
   - [ ] Externes Testing: „Start testing after Apple’s review“ nur wenn gewünscht
8. Workflow speichern und einen Test-Lauf starten (Push oder **Start Build**)

Hinweise:

- Bundle-ID: `YC.CoffeeDiary`
- Team: `7PAQG44S9V`
- CloudKit-Container `iCloud.YC.CoffeeDiary` muss in Production bereitstehen, bevor Nutzer syncen
- PLA / Signing-Fehler in Xcode Cloud: zuerst [developer.apple.com/account](https://developer.apple.com/account) Vereinbarung akzeptieren

---

## Release-Ablauf (jedes Update)

### Schritt 1 – Version setzen und pushen

In Xcode → Target **CoffeeDiary** → **General**:

| Feld | Beispiel |
|------|----------|
| Version (`MARKETING_VERSION`) | `1.2.0` |
| Build (`CURRENT_PROJECT_VERSION`) | wird oft von Xcode Cloud erhöht; lokal ggf. trotzdem anheben |

Committen und pushen:

```bash
git add -A && git commit -m "Bump version to 1.2.0" && git push origin main
```

### Schritt 2 – Auf Xcode Cloud warten

1. Xcode → **Report navigator** / App Store Connect → **Xcode Cloud**
2. Build muss **Succeeded** sein
3. In App Store Connect → App → **TestFlight** / **Build**: Status **Ready to Submit** / verarbeitet (oft 15–60 Min.)

### Schritt 3 – Optional: intern testen

TestFlight-Build auf iPhone/iPad installieren (Sync, Stats, Wetter, Export).

### Schritt 4 – Metadaten prüfen

Deutsche Texte liegen unter `fastlane/metadata/de-DE/` (Beschreibung, Keywords, **release_notes.txt** = „Neues in dieser Version“). Vor dem Submit anpassen, falls nötig.

### Schritt 5 – Einreichung aus Cursor / Terminal

Nur Metadaten (Dry-run, **kein** Review-Button):

```bash
bundle exec fastlane metadata
```

Vollständig inkl. **Zur Prüfung einreichen**:

```bash
bundle exec fastlane release
```

Fastlane lädt **kein** Binary hoch (`skip_binary_upload: true`) — der Build kommt von Xcode Cloud. Es werden Metadaten hochgeladen, der neueste passende Build der Version zugeordnet und die Version zur Prüfung eingereicht.

### Schritt 6 – Nach dem Review

`automatic_release: true` → nach Freigabe durch Apple geht die Version automatisch in den App Store. Phased Release bleibt aus.

---

## Befehle auf einen Blick

| Befehl | Wirkung |
|--------|---------|
| `bundle exec fastlane beta` | Kurzer Hinweis zum Ablauf |
| `bundle exec fastlane metadata` | Nur Store-Texte hochladen |
| `bundle exec fastlane release` | Texte + Build an Version + Submit for Review |
| `bundle exec fastlane screenshots` | iPhone + iPad Screenshots, frameit, Store-Größen |
| `bundle exec fastlane screenshots_iphone` | Nur iPhone-Screenshots |
| `bundle exec fastlane screenshots_ipad` | Nur iPad-Screenshots |
| `bundle exec fastlane screenshots_frame` | Vorhandene PNGs rahmen + auf Store-Größe bringen |
| `bundle exec fastlane screenshots_upload` | Screenshots in ASC ersetzen (ohne Review) |

### Screenshots (de-DE)

Voraussetzungen einmalig:

```bash
brew install imagemagick   # falls noch nicht vorhanden
bundle exec fastlane frameit download_frames
```

Simulator vorher öffnen hilft auf langsamen Macs. Dann nacheinander:

```bash
cd /Users/yannik/Documents/Privat/Coding/CoffeeDiary
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
export PATH="/usr/local/Homebrew/Library/Homebrew/vendor/portable-ruby/current/bin:$DEVELOPER_DIR/usr/bin:$PATH"
export SNAPSHOT_SIMULATOR_WAIT_FOR_BOOT_TIMEOUT=120
bundle exec fastlane screenshots
```

Nur ein Gerät (zum Debuggen):

```bash
bundle exec fastlane screenshots_iphone
bundle exec fastlane screenshots_ipad
```

In App Store Connect ersetzen (aktuelle Version, nur Screenshots):

```bash
bundle exec fastlane screenshots_upload
```

`release` und `metadata` laden Screenshots bewusst nicht hoch (`skip_screenshots`), damit ein normaler Submit bestehende Store-Bilder nicht überschreibt.

---

## Typische Probleme

| Problem | Lösung |
|---------|--------|
| Missing ENV `ASC_*` | `.env` aus `.env.example` anlegen |
| Key file not found | `ASC_KEY_PATH` prüfen, `~` wird expandiert |
| No build available | Xcode-Cloud-Build abwarten; Version in ASC muss zur Marketing-Version passen |
| PLA / membership | Developer-Agreement akzeptieren |
| Screenshots fehlen / veraltet | `bundle exec fastlane screenshots` dann `screenshots_upload` |
| SnapshotTests skipped | Lane setzt `SNAPSHOT_FORCE` + Cache-Marker; Simulator.app öffnen und Retry |
| Accessibility / AX Timeout | Simulator booten, nur `screenshots_iphone`, `SNAPSHOT_SIMULATOR_WAIT_FOR_BOOT_TIMEOUT=120` |
| ImageMagick / frameit | `brew install imagemagick` und `fastlane frameit download_frames` |
| Simulator nicht gefunden | Xcode.app als Developer Dir; Geräte in `Snapfile` / Fastfile an `xcrun simctl list` anpassen |

---

## Was dieses Setup bewusst nicht macht

- Release allein über GitHub Actions (CI bleibt Build/Test)
- Binary-Upload per Fastlane `gym` (übernimmt Xcode Cloud)
- Kleinere iPhone-Screenshot-Größen (Store skaliert vom 6,9"-Satz)
