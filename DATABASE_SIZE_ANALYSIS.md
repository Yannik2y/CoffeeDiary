# Datenbank-Größen-Analyse (Brands + Models + Bilder)

## Annahmen

- **Brands**: 30 Brands
- **Models pro Brand**: Durchschnittlich 5-10 Models (variiert stark)
  - Kleine Brands: 1-3 Models
  - Große Brands (z.B. La Marzocco): 20+ Models
  - **Durchschnitt**: ~7 Models pro Brand
- **Gesamt Models**: 30 × 7 = **~210 Models**

## Option 1: Nur Brand-Logos (wie bisher geplant)

- **Brand Logos**: 30 × ~60 KB = **~1.8 MB**
- **Models**: Nur Text (Name, Specs) = **~50-100 KB** (JSON)
- **Gesamt**: **~1.9 MB**

## Option 2: Brand-Logos + Model-Bilder

### Model-Bild-Größen
- **Thumbnail**: 60x60pt → 180x180px (@3x) = ~20-30 KB
- **Detail**: 120x120pt → 360x360px (@3x) = ~50-80 KB
- **Gesamt pro Model**: ~70-110 KB (alle Auflösungen)

**Für 210 Models:**
- Minimum: 210 × 70 KB = **~14.7 MB**
- Maximum: 210 × 110 KB = **~23.1 MB**
- **Durchschnitt: ~18.9 MB**

**Plus Brand Logos**: +1.8 MB = **~20.7 MB total**

### Mit Optimierung
- Nur @2x und @3x (kein @1x): -33% = **~13.8 MB**
- Aggressive Kompression: -20% = **~11 MB**
- **Plus Brand Logos**: **~12.8 MB total**

## Vergleich

| Option | Datenbank-Größe | App-Größe Impact |
|--------|----------------|------------------|
| **Nur Brand-Logos** | ~1.9 MB | Minimal |
| **Brands + Model-Bilder** | ~12-21 MB | Signifikant |
| **Brands + Model-Bilder (optimiert)** | ~12.8 MB | Mittel |

## Alternative Ansätze

### Option A: Model-Bilder nur bei Bedarf laden
- **Initial**: Nur Brand-Logos (~1.9 MB)
- **On-Demand**: Model-Bilder werden geladen wenn gebraucht
- **Vorteil**: Kleine initiale App-Größe
- **Nachteil**: Ladezeiten, Netzwerk nötig

### Option B: Model-Bilder optional (User kann hochladen)
- **Datenbank**: Nur Brand-Logos + Text (~1.9 MB)
- **User-Upload**: Nutzer kann eigene Bilder für Models hochladen
- **Vorteil**: Flexibel, kleinere App-Größe
- **Nachteil**: Keine Standard-Bilder

### Option C: Nur Top-Models mit Bildern
- **Top 50 Models**: Mit Bildern (~3-5 MB)
- **Rest**: Nur Text
- **Vorteil**: Balance zwischen Größe und Coverage
- **Nachteil**: Inkonsistenz

### Option D: Model-Bilder in separatem Asset-Pack
- **Core App**: Nur Brand-Logos (~1.9 MB)
- **Optional Download**: Model-Bilder-Pack (~12 MB)
- **Vorteil**: User wählt ob er Bilder will
- **Nachteil**: Zusätzliche Komplexität

## Empfehlung

### Für v1: **Option B (Model-Bilder optional/User-Upload)**
- **Datenbank**: Brand-Logos + Model-Text (~1.9 MB)
- **User kann**: Eigene Bilder für Models hochladen
- **Vorteile**:
  - ✅ Kleine App-Größe
  - ✅ Flexibel (User hat sein eigenes Equipment)
  - ✅ Keine Lizenzen für Model-Bilder nötig
  - ✅ Später erweiterbar

### Später erweiterbar zu:
- Option A (On-Demand Loading)
- Option C (Top-Models mit Bildern)
- Option D (Separates Asset-Pack)

## Fazit

**Mit Model-Bildern: ~12-21 MB zusätzlich**
- Das ist **signifikant** (10-20% der App-Größe)
- Download: +10-30 Sekunden
- Speicher: ~0.02-0.03% (immer noch minimal)

**Empfehlung**: Start ohne Model-Bilder in der Datenbank, User kann eigene hochladen. Später optional erweiterbar.

