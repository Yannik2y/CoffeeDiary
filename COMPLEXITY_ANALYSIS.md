# Komplexitätsanalyse: Single vs. Multiple Coffee Stations

## Option A: Single Station (1 aktive Maschine + 1 aktive Mühle)

### Data Model
```swift
// Machine.swift
var isActive: Bool = false

// Grinder.swift  
var isActive: Bool = false
```
**Komplexität: ⭐ Sehr niedrig**
- Nur 2 Boolean-Felder hinzufügen
- Keine neuen Models nötig
- Keine Relationships zu ändern

### Business Logic
```swift
// Beim Setzen als aktiv:
func setActive(_ machine: Machine) {
    // Alle anderen deaktivieren
    machines.forEach { $0.isActive = false }
    machine.isActive = true
}
```
**Komplexität: ⭐ Sehr niedrig**
- Einfache Validierung: max 1 aktiv
- Ein Query: `machines.filter { $0.isActive }`
- Keine Station-Verwaltung nötig

### UI Components
```swift
// Coffee Station View
@Query(filter: #Predicate<Machine> { $0.isActive })
private var activeMachine: [Machine]

@Query(filter: #Predicate<Grinder> { $0.isActive })
private var activeGrinder: [Grinder]
```
**Komplexität: ⭐ Niedrig**
- Einfache Query mit Filter
- Direkte Anzeige: `activeMachine.first`
- Keine Auswahl-UI nötig

### User Flow
1. User tippt auf Coffee Station
2. Zeigt aktive Maschine + Mühle
3. Tippt auf Equipment → kann ändern
4. Beim Setzen als aktiv → andere automatisch deaktiviert

**Komplexität: ⭐ Sehr niedrig**
- Linearer Flow
- Keine Entscheidungen für User
- Keine Station-Auswahl nötig

### Code-Umfang (geschätzt)
- Data Model: ~5 Zeilen
- Business Logic: ~20 Zeilen
- UI Components: ~100 Zeilen
- **Gesamt: ~125 Zeilen**

---

## Option B: Multiple Stations

### Data Model
```swift
// Neues Model
@Model
final class CoffeeStation {
    var id: UUID = UUID()
    var name: String = ""  // "Home", "Office", etc.
    var createdAt: Date = Date()
    
    @Relationship var machine: Machine?
    @Relationship var grinder: Grinder?
    
    var isDefault: Bool = false  // Welche Station ist Standard?
}

// Machine/Grinder: Keine isActive mehr nötig
// Stattdessen: Relationship zu Station
```
**Komplexität: ⭐⭐⭐ Mittel-Hoch**
- Neues Model erstellen
- Relationships ändern
- Migration für bestehende Daten nötig
- `isDefault` Flag für Standard-Station

### Business Logic
```swift
// Station-Management
func createStation(name: String) -> CoffeeStation
func deleteStation(_ station: CoffeeStation)
func setDefaultStation(_ station: CoffeeStation)
func assignMachine(_ machine: Machine, to station: CoffeeStation)
func assignGrinder(_ grinder: Grinder, to station: CoffeeStation)

// Beim Erstellen eines Brews:
func getDefaultStation() -> CoffeeStation?
func getStationForBrew() -> CoffeeStation?  // User wählt Station
```
**Komplexität: ⭐⭐⭐⭐ Hoch**
- Mehrere neue Funktionen
- Station-Lifecycle-Management
- Default-Station-Logik
- Equipment-Zuweisung zu Stationen
- Validierung: Equipment kann nur einer Station zugeordnet sein?

### UI Components
```swift
// Station Selection View
struct StationPickerView: View {
    @Query private var stations: [CoffeeStation]
    @Binding var selectedStation: CoffeeStation?
}

// Station Management View
struct StationManagementView: View {
    // Liste aller Stationen
    // "Add Station" Button
    // Station bearbeiten/löschen
    // Equipment zu Station zuweisen
}

// Coffee Station View (Home Screen)
struct CoffeeStationView: View {
    @State private var selectedStation: CoffeeStation?
    // Zeigt Equipment der gewählten Station
    // Station-Picker oben
}
```
**Komplexität: ⭐⭐⭐⭐ Hoch**
- 3 neue Views nötig
- Station-Picker überall wo Equipment gewählt wird
- Station-Management-UI
- Navigation zwischen Views
- Empty States für "keine Station"

### User Flow
1. User tippt auf Coffee Station
2. **Station-Picker erscheint** (wenn mehrere existieren)
3. User wählt Station
4. Zeigt Equipment dieser Station
5. Tippt auf Equipment → kann ändern
6. Beim Zuweisen → muss Station wählen

**Komplexität: ⭐⭐⭐⭐ Hoch**
- Mehr Entscheidungspunkte
- Station-Auswahl bei jedem Brew?
- Station-Management nötig
- Komplexere Navigation

### Code-Umfang (geschätzt)
- Data Model: ~50 Zeilen (neues Model + Relationships)
- Business Logic: ~150 Zeilen
- UI Components: ~400 Zeilen (3 Views + Integration)
- Migration: ~50 Zeilen
- **Gesamt: ~650 Zeilen**

---

## Vergleich

| Aspekt | Option A (Single) | Option B (Multiple) | Unterschied |
|--------|------------------|---------------------|-------------|
| **Data Model** | 2 Booleans | Neues Model + Relationships | 10x komplexer |
| **Business Logic** | 1 Funktion | 5+ Funktionen | 5x komplexer |
| **UI Components** | 1 View | 3+ Views | 3x komplexer |
| **User Flow** | Linear | Mit Entscheidungen | 2x komplexer |
| **Code-Zeilen** | ~125 | ~650 | 5x mehr Code |
| **Test-Aufwand** | Niedrig | Hoch | 3x mehr Tests |
| **Wartbarkeit** | Sehr einfach | Mittel | Deutlich komplexer |

---

## Empfehlung

### Für v1: Option A (Single Station)
**Gründe:**
- ✅ 5x weniger Code
- ✅ Deutlich einfacher zu implementieren
- ✅ Schneller fertig
- ✅ Weniger Fehlerquellen
- ✅ Passt für 90% der Nutzer

### Später erweiterbar zu Option B
**Migration-Strategie:**
- Option A als Basis implementieren
- Später: `CoffeeStation` Model hinzufügen
- Migration: Aktive Equipment → "Default Station"
- Backward compatible

### Wann Option B sinnvoll?
- Wenn viele Nutzer mehrere Setups haben
- Wenn Community das Feature wünscht
- Wenn Zeit für komplexere Implementierung vorhanden

---

## Fazit

**Option A ist deutlich einfacher:**
- ~125 vs. ~650 Zeilen Code
- 1 vs. 3+ Views
- Linearer vs. komplexer User Flow
- Niedrige vs. hohe Wartbarkeit

**Empfehlung:** Start mit Option A, erweitere später zu Option B wenn Bedarf besteht.

