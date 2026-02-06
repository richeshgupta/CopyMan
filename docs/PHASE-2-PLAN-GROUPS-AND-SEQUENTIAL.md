# Phase 2 Plan: Groups/Folders + Sequential Paste Mode

**Date:** 2026-02-05
**Status:** DRAFT — Awaiting Review
**Scope:** Features required for 1.0 release (P1 priority)

---

## Executive Summary

This document outlines the detailed implementation plan for two Phase 2 features:

1. **Groups / Folders** — Organize clipboard history into named, user-created groups
2. **Sequential Paste Mode** — Copy multiple items, then paste them one-by-one in order

Both features build on Phase 1's foundation (fuzzy search, app exclusions, pinning) and require:
- Database schema expansion (2 new tables)
- New service layer (groups management, sequence management)
- UI overhaul (sidebar with group selector, multi-select mode, sequential paste toolbar)
- Keyboard shortcuts (Ctrl+Click for multi-select, Ctrl+Shift+S to start sequence)

**Estimated effort:** ~2–3 weeks development + 1 week QA

---

## Part 1: Groups / Folders

### 1.1 Overview

**User Story:**
> As a developer, I want to organize my clipboard history into groups (e.g., "Code Snippets", "API Keys", "URLs") so I can quickly find items by context instead of scrolling through a flat history.

**Acceptance Criteria:**
- User can create a group via "New Group" button
- User can rename and delete groups
- User can drag-and-drop items into groups (or right-click → "Move to Group")
- Groups appear as collapsible sections in the main list or as a sidebar
- Ungrouped items appear in an "Uncategorized" group or at the top
- Pinned items can be pinned within their group
- Search filters across all groups (finds items in any group)
- Groups persist across app restarts
- Groups can be color-coded (optional, Phase 2.1)

---

### 1.2 Database Schema

#### New Table: `groups`

```sql
CREATE TABLE IF NOT EXISTS groups (
  id        INTEGER PRIMARY KEY AUTOINCREMENT,
  name      TEXT UNIQUE NOT NULL,
  color     TEXT DEFAULT '#4CAF50',  -- Hex color code (optional, Phase 2.1)
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
)
```

#### Modified Table: `clipboard_items`

Add new column:
```sql
ALTER TABLE clipboard_items ADD COLUMN group_id INTEGER REFERENCES groups(id) ON DELETE SET NULL;
```

**Migration Path (v2 → v3):**
- Create `groups` table
- Add `group_id` nullable column to `clipboard_items`
- Create default "Uncategorized" group (id=1)
- Set all existing items `group_id = 1`
- Create index on `group_id` for fast filtering

---

### 1.3 Model Layer

#### New Model: `Group`

**File:** `flutter_poc/lib/models/group.dart`

```dart
class Group {
  final int id;
  final String name;
  final String color;
  final int createdAt;
  final int updatedAt;

  Group({
    required this.id,
    required this.name,
    this.color = '#4CAF50',
    required this.createdAt,
    required this.updatedAt,
  });

  factory Group.fromMap(Map<String, dynamic> map) {
    return Group(
      id: map['id'] as int,
      name: map['name'] as String,
      color: map['color'] as String? ?? '#4CAF50',
      createdAt: map['created_at'] as int,
      updatedAt: map['updated_at'] as int,
    );
  }

  Color toFlutterColor() => Color(int.parse(color.replaceFirst('#', '0xff')));
}
```

#### Updated Model: `ClipboardItem`

**File:** `flutter_poc/lib/models/clipboard_item.dart`

Add field:
```dart
final int? groupId;  // null = uncategorized

// Update constructor, fromMap, and factory to handle groupId
```

---

### 1.4 Service Layer

#### New Service: `GroupService`

**File:** `flutter_poc/lib/services/group_service.dart`

```dart
class GroupService {
  static final GroupService instance = GroupService();

  Database get db => StorageService.instance.db;

  // ── CRUD ──────────────────────────────────────────────────────

  Future<List<Group>> fetchAllGroups() async {
    // SELECT * FROM groups ORDER BY name
  }

  Future<int> createGroup(String name, {String color = '#4CAF50'}) async {
    // INSERT INTO groups (name, color, created_at, updated_at)
    // Returns group id
  }

  Future<void> updateGroup(int id, {String? name, String? color}) async {
    // UPDATE groups SET name=?, color=?, updated_at=? WHERE id=?
  }

  Future<void> deleteGroup(int id, {int? moveToGroupId}) async {
    // Option 1: Move all items in this group to moveToGroupId (or null = uncategorized)
    // Option 2: Delete items in this group along with the group
    // Default: Move to null (uncategorized)
    // DELETE FROM groups WHERE id=?
  }

  Future<void> moveItemToGroup(int itemId, int? groupId) async {
    // UPDATE clipboard_items SET group_id=? WHERE id=?
  }

  // ── convenience ──────────────────────────────────────────────

  Future<List<ClipboardItem>> fetchItemsInGroup(int groupId) async {
    // SELECT * FROM clipboard_items WHERE group_id=? ORDER BY pinned DESC, updated_at DESC
  }

  Future<int> getGroupItemCount(int groupId) async {
    // SELECT COUNT(*) FROM clipboard_items WHERE group_id=?
  }
}
```

#### Updated Service: `StorageService`

**File:** `flutter_poc/lib/services/storage_service.dart`

Add method:
```dart
Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
  // ... existing v1 → v2 code ...

  if (oldVersion < 3) {
    // v2 → v3: Add groups table and groupId column
    await db.execute('''
      CREATE TABLE IF NOT EXISTS groups (
        id        INTEGER PRIMARY KEY AUTOINCREMENT,
        name      TEXT UNIQUE NOT NULL,
        color     TEXT DEFAULT '#4CAF50',
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    // Add default "Uncategorized" group
    await db.insert('groups', {
      'id': 1,
      'name': 'Uncategorized',
      'color': '#9E9E9E',
      'created_at': DateTime.now().millisecondsSinceEpoch,
      'updated_at': DateTime.now().millisecondsSinceEpoch,
    });

    // Add group_id column to existing table
    await db.execute('ALTER TABLE clipboard_items ADD COLUMN group_id INTEGER DEFAULT 1');

    // Create index for fast group filtering
    await db.execute('CREATE INDEX IF NOT EXISTS idx_group_id ON clipboard_items(group_id)');
  }
}
```

Update database version from `2` to `3`.

---

### 1.5 UI Layer

#### New Screen: `GroupsPanel` (Sidebar)

**File:** `flutter_poc/lib/widgets/groups_panel.dart`

```dart
class GroupsPanel extends StatefulWidget {
  final List<Group> groups;
  final int? selectedGroupId;
  final ValueChanged<int?> onGroupSelected;
  final VoidCallback onNewGroup;
  final Function(int, String) onGroupRenamed;
  final Function(int) onGroupDeleted;

  const GroupsPanel({
    required this.groups,
    required this.selectedGroupId,
    required this.onGroupSelected,
    required this.onNewGroup,
    required this.onGroupRenamed,
    required this.onGroupDeleted,
  });

  @override
  State<GroupsPanel> createState() => _GroupsPanelState();
}
```

**Layout:**
```
┌─────────────────────────────┐
│ Groups         [+ New]      │  ← Header with "New Group" button
├─────────────────────────────┤
│ ☐ Uncategorized (42 items)  │  ← All items not in a group
│ ☐ Code Snippets (15 items)  │  ← Each group shows item count
│ ☑ API Keys (8 items)        │  ← Checkmark = selected group
│ ☐ URLs (23 items)           │
│ ☐ Notes (5 items)           │
├─────────────────────────────┤
│ All Items       [X delete]  │  ← Option: delete selected group
└─────────────────────────────┘
```

**Behavior:**
- Click group → filter main list to show only that group's items
- Right-click group → context menu: "Rename", "Delete", "Change Color"
- "New Group" → dialog to enter group name
- Uncategorized group is always present, cannot be deleted

#### Updated Screen: `HomeScreen`

**File:** `flutter_poc/lib/screens/home_screen.dart`

**New state:**
```dart
List<Group> _groups = [];
int? _selectedGroupId;  // null = "All Items" (no filter)
List<bool> _itemSelected = [];  // Track multi-select
bool _sequenceMode = false;  // Are we in sequential paste mode?
List<int> _sequenceIndices = [];  // Items selected for sequence
```

**Layout changes:**
```
┌──────────────────────────────────────────────────────────┐
│ [Groups Panel (collapsed by default)]  🔍 search...     │
├──────────────────────────────────────────────────────────┤
│ Filter: All Items  ↓   [4 selected]  [Start Sequence]   │
├──────────────────────────────────────────────────────────┤
│ ☐ git clone https://...                                 │
│ ☑ export default App {                                  │
│ ☐ const x = useState(0)                                 │
│ ☑ import React from ...                                 │
├──────────────────────────────────────────────────────────┤
│ Preview: ...                                             │
├──────────────────────────────────────────────────────────┤
│ Enter copy · Ctrl+Shift+Enter plain · Esc close         │
└──────────────────────────────────────────────────────────┘
```

**Keyboard shortcuts (multi-select mode):**
- **Ctrl+Click** or **Ctrl+A** → select/deselect items
- **Ctrl+Shift+S** → start sequence with selected items
- **Escape** → cancel multi-select
- **Shift+Delete** → delete selected items

---

### 1.6 Feature: Move Items to Groups

#### Context Menu Update

**File:** `flutter_poc/lib/widgets/clipboard_item_tile.dart`

Add menu item:
```dart
PopupMenuItem<String>(
  value: 'move_to_group',
  child: const Row(
    children: [
      Icon(Icons.folder_open_outlined, size: 16),
      SizedBox(width: 10),
      Text('Move to Group'),
    ],
  ),
),
```

#### Submenu: Select Group

When user clicks "Move to Group", show a submenu listing all groups:
```dart
case 'move_to_group':
  _showGroupSubmenu(context, item);
  break;
```

**Implementation:**
- Cascade context menu showing all groups
- Click group → `moveItemToGroup(itemId, groupId)`
- Toast: "Moved to Group X"

---

### 1.7 Migration Strategy

**Step-by-step:**

1. **Phase 1 state:** Database v2 (no groups)
2. **User launches Phase 2:** `onUpgrade` handler runs
   - Creates `groups` table
   - Inserts "Uncategorized" group (id=1)
   - Adds `group_id` column to clipboard_items (defaults to 1)
   - All existing items now belong to "Uncategorized"
3. **Phase 2 active:** User can create new groups, move items

**No data loss.** All existing items remain accessible in "Uncategorized" group.

---

## Part 2: Sequential Paste Mode

### 2.1 Overview

**User Story:**
> As a developer, I want to copy multiple items and paste them one-by-one in sequence, so I can fill form fields or paste code blocks without manually switching clipboard items.

**Example workflow:**
1. Copy snippet 1, copy snippet 2, copy snippet 3
2. Open CopyMan, select all three (Ctrl+Click each)
3. Click "Start Sequence" or press Ctrl+Shift+S
4. CopyMan sets clipboard to snippet 1
5. User presses Ctrl+V → pastes snippet 1
6. User presses Ctrl+V again → CopyMan automatically advances to snippet 2
7. And so on for snippet 3

**Acceptance Criteria:**
- User selects 2+ items (multi-select mode)
- Click "Start Sequence" button or Ctrl+Shift+S
- Sequence mode activates: UI shows "Sequence Mode: Item 1/3" indicator
- User presses Ctrl+V (or a dedicated "Next" key) to advance to the next item
- Each advance sets clipboard to the next item in the sequence
- Last item → pressing Ctrl+V → exit sequence mode
- Escape cancels sequence mode without pasting anything
- Sequence state is NOT persisted (session-only)

---

### 2.2 Data Model

#### New Model: `SequenceSession`

**File:** `flutter_poc/lib/models/sequence_session.dart`

```dart
class SequenceSession {
  final List<ClipboardItem> items;
  int currentIndex;  // Current item index (0 = first)

  SequenceSession({required this.items, this.currentIndex = 0});

  ClipboardItem get currentItem => items[currentIndex];
  bool get isComplete => currentIndex >= items.length;
  bool get hasNext => currentIndex < items.length - 1;

  void advance() {
    if (hasNext) currentIndex++;
  }

  String get progress => '${currentIndex + 1}/${items.length}';
}
```

---

### 2.3 Service Layer

#### New Service: `SequenceService`

**File:** `flutter_poc/lib/services/sequence_service.dart`

```dart
class SequenceService {
  SequenceSession? _currentSession;

  bool get isActive => _currentSession != null;
  SequenceSession? get session => _currentSession;

  void startSequence(List<ClipboardItem> items) {
    if (items.length < 2) throw ArgumentError('Need at least 2 items');
    _currentSession = SequenceSession(items: items);
  }

  void advance() {
    if (_currentSession != null) {
      _currentSession!.advance();
    }
  }

  void cancel() {
    _currentSession = null;
  }

  ClipboardItem? getCurrentItem() => _currentSession?.currentItem;
}
```

---

### 2.4 UI Integration

#### HomeScreen State Updates

**File:** `flutter_poc/lib/screens/home_screen.dart`

```dart
class _HomeScreenState extends State<HomeScreen> with WindowListener {
  // ── existing state ──
  List<ClipboardItem> _allItems = [];
  List<FuzzyMatch> _matches = [];
  // ── NEW for groups ──
  List<Group> _groups = [];
  int? _selectedGroupId;
  List<bool> _itemSelected = [];
  // ── NEW for sequence ──
  final SequenceService _sequenceService = SequenceService();
}
```

#### Multi-Select Mode UI

```dart
// In ListView.builder, replace single-select with checkbox + multi-select toggle

if (_itemSelected[i]) {
  // Show checkbox, tint background
  ClipboardItemTile(
    item: match.item,
    isSelected: _itemSelected[i],
    isMultiSelectMode: _itemSelected.any((x) => x),
    onCheckboxChanged: (checked) {
      setState(() => _itemSelected[i] = checked);
    },
    // ... other callbacks
  );
}
```

#### Sequence Mode Indicator

```dart
if (_sequenceService.isActive)
  Container(
    color: theme.colorScheme.primary.withValues(alpha: 0.15),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Sequence Mode: ${_sequenceService.session!.progress}',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close, size: 16),
          onPressed: () {
            setState(() => _sequenceService.cancel());
          },
        ),
      ],
    ),
  ),
```

#### Start Sequence Button

```dart
if (_itemSelected.any((x) => x) && !_sequenceService.isActive)
  ElevatedButton.icon(
    onPressed: _startSequence,
    icon: const Icon(Icons.repeat),
    label: const Text('Start Sequence'),
  ),
```

#### Keyboard Handler (Updated)

**File:** `flutter_poc/lib/screens/home_screen.dart`

```dart
bool _onKey(KeyEvent event) {
  if (event is! KeyDownEvent) return false;

  // Ctrl+A: Toggle multi-select all
  if (event.logicalKey == LogicalKeyboardKey.keyA &&
      HardwareKeyboard.instance.isControlPressed) {
    setState(() {
      final allSelected = _itemSelected.every((x) => x);
      for (int i = 0; i < _itemSelected.length; i++) {
        _itemSelected[i] = !allSelected;
      }
    });
    return true;
  }

  // Ctrl+Shift+S: Start sequence
  if (event.logicalKey == LogicalKeyboardKey.keyS &&
      HardwareKeyboard.instance.isControlPressed &&
      HardwareKeyboard.instance.isShiftPressed) {
    _startSequence();
    return true;
  }

  // Ctrl+V while in sequence mode: Advance to next item
  if (event.logicalKey == LogicalKeyboardKey.keyV &&
      HardwareKeyboard.instance.isControlPressed &&
      _sequenceService.isActive) {
    _advanceSequence();
    return true;
  }

  // ... existing keyboard logic ...
}
```

---

### 2.5 Implementation Details

#### Method: `_startSequence()`

```dart
Future<void> _startSequence() async {
  final selectedItems = <ClipboardItem>[];
  for (int i = 0; i < _matches.length; i++) {
    if (_itemSelected[i]) {
      selectedItems.add(_matches[i].item);
    }
  }

  if (selectedItems.length < 2) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Select at least 2 items to start sequence')),
    );
    return;
  }

  setState(() {
    _sequenceService.startSequence(selectedItems);
    _itemSelected = List.filled(_matches.length, false);  // Clear selection
    // Set clipboard to first item
    _clipService.setLastContent(selectedItems[0].content);
    Clipboard.setData(ClipboardData(text: selectedItems[0].content));
  });
}
```

#### Method: `_advanceSequence()`

```dart
Future<void> _advanceSequence() async {
  _sequenceService.advance();

  final item = _sequenceService.getCurrentItem();
  if (item != null) {
    _clipService.setLastContent(item.content);
    await Clipboard.setData(ClipboardData(text: item.content));
    setState(() {}); // Refresh UI to show new progress
  } else {
    // Sequence complete
    setState(() => _sequenceService.cancel());
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sequence complete')),
    );
  }
}
```

---

## Part 3: Implementation Timeline & Files

### 3.1 File Structure (New & Modified)

**New Files:**
```
flutter_poc/lib/
├── models/
│   └── group.dart                    (new)
│   └── sequence_session.dart         (new)
├── services/
│   ├── group_service.dart            (new)
│   └── sequence_service.dart         (new)
├── widgets/
│   ├── groups_panel.dart             (new)
│   └── clipboard_item_tile.dart      (MODIFIED — add checkbox, move menu)
├── screens/
│   └── home_screen.dart              (MODIFIED — major UI overhaul)
└── app.dart                          (MODIFIED — database version 3)
```

**Modified Files:**
```
flutter_poc/
├── lib/
│   ├── models/clipboard_item.dart    (add groupId field)
│   ├── services/storage_service.dart (add v3 migration)
│   └── pubspec.yaml                  (no changes)
├── PHASE-2-PLAN.md                   (this document)
└── PHASE-2-PROGRESS.md               (tracking doc, created during implementation)
```

---

### 3.2 Recommended Implementation Order

1. **Database & Models (Day 1)**
   - [ ] Add `Group` model
   - [ ] Add `group_id` to `ClipboardItem` model
   - [ ] Add v3 migration to `StorageService`
   - [ ] Bump database version to 3

2. **Services (Day 1–2)**
   - [ ] Implement `GroupService` (CRUD)
   - [ ] Implement `SequenceService` (session management)
   - [ ] Add helper methods to `StorageService`

3. **Groups UI (Day 2–3)**
   - [ ] Create `GroupsPanel` widget
   - [ ] Update `ClipboardItemTile` with "Move to Group" menu
   - [ ] Integrate `GroupsPanel` into `HomeScreen`
   - [ ] Implement group filtering logic

4. **Multi-Select & Sequence (Day 3–4)**
   - [ ] Add multi-select mode to `HomeScreen`
   - [ ] Update `ClipboardItemTile` to show checkbox in multi-select mode
   - [ ] Implement `_startSequence()` and `_advanceSequence()`
   - [ ] Add sequence indicator UI
   - [ ] Update keyboard handlers

5. **Testing & Refinement (Day 4–5)**
   - [ ] Manual testing of all group operations
   - [ ] Test migration from v2 → v3
   - [ ] Test multi-select with search filters
   - [ ] Test sequence mode with keyboard shortcuts
   - [ ] Edge cases: delete group with items, exit sequence mode, etc.

---

### 3.3 Database Migration Example

**From v2 to v3:**

```sql
-- Create groups table
CREATE TABLE groups (
  id        INTEGER PRIMARY KEY AUTOINCREMENT,
  name      TEXT UNIQUE NOT NULL,
  color     TEXT DEFAULT '#4CAF50',
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
);

-- Insert default "Uncategorized" group
INSERT INTO groups (id, name, color, created_at, updated_at)
VALUES (1, 'Uncategorized', '#9E9E9E', <now>, <now>);

-- Add group_id column to clipboard_items
ALTER TABLE clipboard_items ADD COLUMN group_id INTEGER DEFAULT 1;

-- Create index for fast filtering
CREATE INDEX idx_group_id ON clipboard_items(group_id);
```

---

## Part 4: Architectural Decisions & Trade-Offs

### 4.1 Groups: Sidebar vs. Inline

**Option A: Sidebar (chosen)**
- Groups listed in left panel; click to filter
- Pros: More screen real estate for items; groups always visible
- Cons: Narrower item list on small screens (420px popup)
- Recommendation: **Use collapsible sidebar** (toggle with icon)

**Option B: Dropdown**
- Groups in a dropdown filter above the list
- Pros: More space for items
- Cons: Groups hidden when not actively filtering
- Recommendation: Not chosen; groups are a primary feature

### 4.2 Sequential Paste: Ctrl+V Advance vs. Dedicated Key

**Option A: Ctrl+V (chosen)**
- User already pressing Ctrl+V to paste; reuses same muscle memory
- Pros: Natural; fewer new shortcuts to learn
- Cons: Requires detecting if we're in sequence mode; could be confusing if user expects normal paste
- Mitigation: Show clear "Sequence Mode" indicator in UI

**Option B: Dedicated key (e.g., Ctrl+Shift+V)**
- Explicit advancement key
- Pros: No ambiguity
- Cons: Additional shortcut; breaks expectation of Ctrl+V being "paste"

### 4.3 Sequence State Persistence

**Option A: Session-only (chosen)**
- Sequence state lost if app is closed or hotkey triggers
- Pros: Simpler; no persistent state to manage
- Cons: User cannot pause and resume

**Option B: Persistent**
- Save sequence state to DB; restore on app reopen
- Pros: Can pause/resume later
- Cons: More complex; when to auto-start? DB bloat

### 4.4 Group Color Coding

**Phase 2.0: No colors (monochrome)**
- All groups same color; keep it simple
- Recommendation: Defer color coding to Phase 2.1 (after user feedback)

**Phase 2.1: Optional colors**
- User can pick color for each group via settings
- Pros: Visual organization
- Cons: Added complexity; color picker UI

---

## Part 5: Acceptance Criteria & Testing Plan

### 5.1 Groups Feature Testing

#### Functional Tests
- [ ] Create group with unique name → succeeds, appears in sidebar
- [ ] Create group with duplicate name → fails with error message
- [ ] Rename group → name updates in sidebar and filtered list title
- [ ] Delete group (no items) → group removed; no orphaned items
- [ ] Delete group (with items) → items moved to "Uncategorized"
- [ ] Move item to group → item appears in group; removed from old group
- [ ] Filter by group → only items in that group shown; search still works
- [ ] "All Items" filter → shows all items regardless of group
- [ ] Add item while group filtered → item goes to selected group
- [ ] Ungrouped items (group_id=null) → fallback to Uncategorized

#### Edge Cases
- [ ] Rename group while filtered by it → list updates; filter still applies
- [ ] Collapse/expand sidebar → groups list hidden/shown
- [ ] Very long group name → truncated in sidebar with tooltip
- [ ] 100+ groups → sidebar scrollable; performance acceptable

#### Database Tests
- [ ] v2 → v3 migration → all existing items in "Uncategorized"
- [ ] v3 backward compat → deleting app + reinstalling maintains history

---

### 5.2 Sequential Paste Feature Testing

#### Functional Tests
- [ ] Select 1 item → "Start Sequence" button disabled
- [ ] Select 2+ items → "Start Sequence" button enabled
- [ ] Click "Start Sequence" → sequence mode activates; first item in clipboard
- [ ] Sequence indicator shows "Item 1/N" → correct progress
- [ ] Press Ctrl+V while in sequence → advances to item 2; clipboard updated
- [ ] Continue advancing → reaches last item
- [ ] Press Ctrl+V on last item → sequence completes; indicator disappears
- [ ] Press Escape → cancels sequence without pasting
- [ ] Ctrl+Shift+S → keyboard shortcut equivalent to button

#### Edge Cases
- [ ] Start sequence with 2 items → advances through both → exits cleanly
- [ ] Search while in sequence → items still pasteable; progress maintained
- [ ] Filter group while in sequence → sequence persists (or exits gracefully)
- [ ] Pin/delete item while in sequence → sequence unaffected (no cross-talk)

#### Performance
- [ ] Select 50 items → "Start Sequence" UI responsive
- [ ] Advance through 100-item sequence → no stuttering

---

## Part 6: Open Questions for Review

1. **Group Sidebar Layout:** Should it be a fixed left panel (narrower items list), or a collapsible drawer (toggle icon)? Which feels better?

2. **Default Group for New Items:** When user captures clipboard, should it go to the currently-filtered group, or always to "Uncategorized"?

3. **Sequence Pausing:** Should sequence persist if user opens a different app and comes back? Or always session-only?

4. **Group Deletion:** When deleting a group, should we show a confirmation dialog listing affected items?

5. **Multi-Select Feedback:** Should checkboxes be visible always, or only in "multi-select mode" (toggled by Ctrl+A)?

6. **Keyboard Shortcut Collision:** Is Ctrl+V for advancing sequence a problem on any platform? (It's paste-as-plain in some apps.)

7. **Visual Hierarchy:** In the sidebar, should "Uncategorized" be special (e.g., pinned at top, grayed out color)?

---

## Summary

| Feature | Component | Complexity | Est. Effort |
|---------|-----------|-----------|------------|
| **Groups** | DB migration + models | Medium | 3 days |
| | GroupService CRUD | Low | 1 day |
| | GroupsPanel widget | Medium | 2 days |
| | Integration into HomeScreen | High | 2 days |
| **Sequential Paste** | SequenceService | Low | 1 day |
| | Multi-select UI | Medium | 1 day |
| | Keyboard handling | Low | 1 day |
| | Sequence indicator | Low | 0.5 days |
| **Testing & Polish** | | | 2 days |
| **TOTAL** | | | ~10 days |

---

## Next Steps After Approval

1. Get sign-off on architectural decisions (§4)
2. Answer open questions (§6)
3. Create GitHub issues for each component (with this plan as reference)
4. Begin implementation starting with database layer
5. Update `PHASE-2-PROGRESS.md` as work progresses

---

**Awaiting your review and feedback. Please comment on:**
- Overall approach and file structure
- UI/UX decisions (sidebar vs. dropdown, etc.)
- Any additional features or constraints
- Estimated timeline feasibility
