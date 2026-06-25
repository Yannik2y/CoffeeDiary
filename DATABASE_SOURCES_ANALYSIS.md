# Analyse: Verfügbare Datenbanken/APIs für Coffee Equipment

## Recherche-Ergebnisse

### ❌ Keine direkten APIs gefunden
Es gibt **keine öffentlich verfügbaren REST-APIs oder JSON-Datenbanken** für Coffee Equipment (Brands/Models), die direkt programmatisch genutzt werden können.

### 📚 Verfügbare Ressourcen (aber nicht als API)

1. **KaffeeWiki** (kaffeewiki.de)
   - Umfangreiche Wiki-Datenbank
   - Detaillierte Informationen zu Maschinen und Mühlen
   - **Problem**: Keine API, nur Web-Scraping möglich (rechtlich fragwürdig)

2. **Kaffee-Netz Forum** (kaffee-netz.de)
   - Community-Forum mit Erfahrungen
   - **Problem**: Keine strukturierten Daten, nur Diskussionen

3. **Old-Coffee-Grinders.com**
   - Sammlung alter Mühlen
   - **Problem**: Fokus auf alte Modelle, keine API

4. **Kaffeemuehlen.net**
   - Ratgeberportal
   - **Problem**: Keine strukturierten Daten

## Optionen für die Datenbank

### Option 1: Manuelle Erstellung (empfohlen)
- **Vorgehen**: Du erstellst eine JSON-Datei mit Brands/Models
- **Vorteile**: 
  - ✅ Vollständige Kontrolle
  - ✅ Qualität gesichert
  - ✅ Keine rechtlichen Probleme
  - ✅ Strukturiert nach deinen Bedürfnissen
- **Nachteile**:
  - ⚠️ Zeitaufwand für Initial-Setup
  - ⚠️ Manuelle Wartung

### Option 2: Web-Scraping (nicht empfohlen)
- **Vorgehen**: Daten von KaffeeWiki/anderen Seiten scrapen
- **Vorteile**: 
  - ✅ Schneller Start
- **Nachteile**:
  - ❌ Rechtlich fragwürdig (Terms of Service)
  - ❌ Unstrukturierte Daten
  - ❌ Wartung schwierig
  - ❌ Keine Bilder/Logos

### Option 3: Community-basierte Sammlung
- **Vorgehen**: User können Brands/Models vorschlagen
- **Vorteile**:
  - ✅ Crowdsourcing
  - ✅ Wächst organisch
- **Nachteile**:
  - ⚠️ Qualitätskontrolle nötig
  - ⚠️ Moderation erforderlich
  - ⚠️ Später implementierbar

### Option 4: Hybrid (Start manuell, später Community)
- **Vorgehen**: Start mit manueller Liste (20-30 Brands), später Community-Features
- **Vorteile**:
  - ✅ Schneller Start
  - ✅ Qualität gesichert
  - ✅ Später erweiterbar
- **Nachteile**:
  - ⚠️ Initial-Aufwand

## Empfehlung

### Für v1: **Option 1 (Manuelle Erstellung)**
1. **Start**: Du erstellst eine JSON-Datei mit Top 20-30 Brands
2. **Struktur**: Brands → Models → Specs (optional)
3. **Bilder**: Logos und Model-Bilder manuell sammeln/erstellen
4. **Erweiterung**: Später Community-Features für Vorschläge

### JSON-Struktur Beispiel
```json
{
  "brands": [
    {
      "id": "la-marzocco",
      "name": "La Marzocco",
      "logoAssetName": "brand_la_marzocco",
      "category": "machine",
      "models": [
        {
          "id": "linea-mini",
          "name": "Linea Mini",
          "imageAssetName": "model_la_marzocco_linea_mini",
          "specs": {
            "boilerType": "dual",
            "pressure": "9 bar"
          }
        }
      ]
    }
  ]
}
```

## Fazit

**Keine fertige API verfügbar** → Manuelle Erstellung ist der beste Weg:
- ✅ Kontrolle über Qualität und Struktur
- ✅ Rechtlich sicher
- ✅ Passt zu deinen Bedürfnissen
- ✅ Später erweiterbar mit Community-Features

**Aufwand**: ~2-4 Stunden für Initial-Setup (30 Brands, ~210 Models, Bilder sammeln)

