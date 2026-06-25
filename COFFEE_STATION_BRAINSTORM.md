# Coffee Station Feature - Brainstorming

## Vision
Add a "Coffee Station" section to the home screen that displays the user's current coffee machine and grinder, with a brand/model database for easier selection (similar to the inspiration images).

---

## Current State Analysis

### Existing Models
- **Machine**: `name`, `brand`, `model`, `notes`, `photoData`
- **Grinder**: `name`, `brand`, `burrType`, `defaultSetting`, `notes`, `photoData`
- Equipment is currently managed via `EquipmentManagementView` (accessed from overflow menu)
- Users manually type brand/model names
- No brand database or logos exist

### Home Screen (`BrewListView`)
- Currently shows list of brews
- Has navigation title "Coffee Diary"
- Empty state when no brews exist
- Filter controls at top

---

## Feature Components

### 1. Brand/Model Database

**Questions:**
- **Storage**: Where to store the database?
  - ✅ DECISION: Hybrid approach
    - JSON structure in bundle (brands/models metadata, ~50-100 KB)
    - Images loaded on-demand from remote CDN/server
    - User-uploaded images stored locally
  - Option A: Static JSON file in app bundle (simple, offline-first)
  - Option B: Remote API (updatable, but requires network)
  
- **Model Images**: 
  - ✅ DECISION: Include model images for visual appeal on home screen
  - ✅ DECISION: On-demand loading (remote CDN/server) - smaller app size, images load when needed
  - User can upload own images as fallback
  - Size impact: ~0 MB in bundle (images loaded on-demand)
  
- **Scope**: What should be in the database?
  - Brands only? (user still types model)
  - Brands + models? (more complete, but larger dataset)
  - Brands + models + specs? (e.g., pressure, boiler type)
  
- **Data Source**: How to populate?
  - Manual curation (you maintain a list)
  - Community contributions (users can suggest)
  - Import from existing sources (if any exist)
  
- **Logo Storage**: Where to store brand logos?
  - Option A: Bundle assets (SVG/PNG files)
  - Option B: Remote CDN (smaller app size, but needs network)
  - Option C: Hybrid (popular brands in bundle, others remote)

**Recommendation**: Start with Option A (static JSON + bundle assets) for v1, can evolve later.

---

### 2. Brand Selection UI

**From Inspiration:**
- Search bar at bottom
- Paginated brand list with logos
- "Load More" button
- Cancel navigation

**Design Questions:**
- **Layout**: Grid or list?
  - Inspiration shows list with logos on left
  - Could also do grid (2-3 columns) for better visual browsing
  
- **Search**: 
  - Real-time filtering as user types?
  - Search icon on right side of search bar?
  
- **Pagination**:
  - How many brands per page? (20-30 seems reasonable)
  - Infinite scroll vs "Load More" button?
  
- **Empty States**:
  - What if search returns no results?
  - "Add custom brand" option?

**Recommendation**: List layout (matches inspiration), real-time search, "Load More" button, allow custom entry.

---

### 3. Model Selection

**✅ DECISION: Brands + Models in database**

**Questions:**
- **UI Flow**:
  - ✅ DECISION: After selecting brand → show models for that brand
  
- **Fallback**:
  - ✅ DECISION: If brand exists but model doesn't → allow free text entry

---

### 4. "Active" Equipment Concept

**Questions:**
- How to mark equipment as "active"?
  - ✅ DECISION: Option A - Add `isActive` boolean to Machine/Grinder models (with validation: max 1 active machine, max 1 active grinder)
  - Option B: Separate "Coffee Station" entity that references Machine/Grinder
  - Option C: Most recently used equipment
  
- **Multiple Stations?**
  - ✅ DECISION: Single station (one active machine + one active grinder)
  - Can users have multiple "stations" (home, office)? (Future enhancement)
  
- **Default Behavior**:
  - What if user has no active equipment?
  - What if user has multiple machines/grinders?

**Recommendation**: Option A (`isActive` boolean), single station (one machine + one grinder), show empty state if none selected.

---

### 5. Home Screen Integration

**Questions:**
- **Layout**: Where to place Coffee Station?
  - ✅ DECISION: Option A Variante 2 - Top of screen, sticky/pinned (always visible, brew list scrolls below)
  - Option B: Replace empty state (if no brews)
  - Option C: Dedicated tab (separate from brews)
  
- **Visual Design**:
  - ✅ DECISION: Hybrid - App theme with prominent elements (larger cards, more padding for prominence)
  - Match inspiration (gradient header, equipment cards)?
  - Or integrate with existing app theme?
  
- **Interaction**:
  - ✅ DECISION: Tap to view equipment details (then can edit from there)
  - Tap to edit/change equipment?
  - Swipe actions?
  
- **Empty State**:
  - ✅ DECISION: Show "Set up your coffee station" prompt with button (clear call-to-action)
  - Or show placeholder cards?

**Recommendation**: Option A (top of screen), match app theme but with prominent display, tap to change equipment.

---

### 6. Data Model Changes

**Potential Additions:**
```swift
// Machine model additions
var brandId: String?  // Reference to brand database
var modelId: String?   // Reference to model database (if implemented)
var isActive: Bool = false

// Grinder model additions  
var brandId: String?
var isActive: Bool = false
```

**Brand Database Structure:**
```swift
struct Brand: Codable, Identifiable {
    let id: String  // e.g., "aeropress", "ascaso"
    let name: String
    let logoAssetName: String?  // e.g., "brand_aeropress"
    let category: BrandCategory  // .machine, .grinder, .both
}

enum BrandCategory: String, Codable {
    case machine
    case grinder
    case both
}
```

---

### 7. Migration Strategy

**Questions:**
- How to handle existing equipment?
  - Try to match existing brand names to database?
  - Or leave as-is and only use database for new entries?
  
- **Backward Compatibility**:
  - Existing brews reference old Machine/Grinder models
  - Need to ensure relationships still work

**Recommendation**: Leave existing equipment as-is, only use database for new entries. Can add "match to brand" feature later.

---

### 8. Implementation Phases

**Phase 1: Foundation**
- Create brand database JSON structure
- Add brand logos to bundle assets
- Create `Brand` model/struct
- Add brand selection view (list + search)

**Phase 2: Integration**
- Add `isActive` to Machine/Grinder models
- Create Coffee Station view component
- Integrate into home screen
- Add "Set Active" action in equipment management

**Phase 3: Enhancement**
- Model database (optional)
- Brand matching for existing equipment
- Multiple stations (if desired)
- Remote updates for brand database

---

### 9. Open Questions for You

1. **Brand Database Scope**: How many brands should we include initially?
   - ✅ DECISION: Top 20-30 most popular brands (expandable later)
   - Comprehensive list (100+)?
   - Start small and grow?

2. **Logo Sources**: Where will brand logos come from?
   - ✅ DECISION: Bundle Assets (PNG, optimized, ~1.4-1.8 MB for 30 brands)
   - Do you have access to logos?
   - Should we use placeholder/system icons initially?
   - Need to check licensing for brand logos?

3. **Active Equipment**: Should users be able to have multiple active machines/grinders?
   - Or strictly one machine + one grinder?

4. **Model Database**: Do you want to include models in the database from the start?
   - Or start with brands only?

5. **Home Screen Priority**: Should Coffee Station be the primary focus?
   - Or secondary to brew list?

6. **Custom Brands**: Should users be able to add brands not in the database?
   - ✅ DECISION: Yes - Allow "Add Custom Brand" with manual logo upload option
   - Or only select from curated list?

---

## Next Steps

1. **Decide on scope** (brands only vs brands + models)
2. **Create brand database structure** (JSON format)
3. **Design Coffee Station UI component**
4. **Plan home screen layout changes**
5. **Implement brand selection flow**
6. **Add active equipment management**

---

## Technical Considerations

- **Performance**: Brand database should be lightweight (JSON parsing)
- **Localization**: Brand names might need translation (or keep English?)
- **Accessibility**: Ensure brand selection is accessible
- **Testing**: Need test data for various scenarios (no equipment, one equipment, multiple)

