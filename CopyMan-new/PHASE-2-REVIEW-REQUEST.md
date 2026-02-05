# Phase 2 Implementation Plan: Groups & Sequential Paste

**Status:** 📋 READY FOR REVIEW
**Date:** 2026-02-05
**Documents:** 3 (main plan + mockups + this summary)

---

## What's Being Proposed

Two complementary Phase 2 features to enable better clipboard organization and workflow efficiency:

### Feature 1: Groups / Folders
- Organize clipboard history into user-created groups (e.g., "Code Snippets", "API Keys", "URLs")
- Sidebar shows all groups with item counts
- Click group to filter list; search works across all groups
- Right-click item → "Move to Group" (cascading context menu)
- New items added while filtered go to selected group
- All existing items automatically go to "Uncategorized" group on upgrade

### Feature 2: Sequential Paste Mode
- Select 2+ items (Ctrl+Click to multi-select; Ctrl+A for all)
- Click "Start Sequence" button or press Ctrl+Shift+S
- UI shows "Sequence Mode: Item 1 of N" indicator
- User presses Ctrl+V to paste first item
- Pressing Ctrl+V again automatically advances to item 2, 3, etc.
- Useful for filling form fields, pasting code blocks in order
- Sequence is session-only (not persisted; lost if popup closes)

---

## Key Design Decisions (Need Your Approval)

### Groups: Sidebar vs. Dropdown
**Chosen: Collapsible Sidebar**
- Left panel shows all groups (Uncategorized, Code Snippets, API Keys, etc.)
- Toggle with [≡] icon to reclaim space on small screens
- Groups always visible when expanded (primary UI feature)

**Alternative rejected:** Dropdown (hides groups when not actively filtering; less discoverable)

**Why:** Groups are a first-class feature, not a secondary filter. Sidebar makes them permanent, discoverable, always accessible.

**Trade-off:** Narrows item list on small screens (420px popup becomes 280px items + 140px sidebar). Mitigated by collapsibility.

---

### Sequential Paste: Ctrl+V to Advance
**Chosen: Reuse Ctrl+V (normal paste key)**
- User already pressing Ctrl+V to paste; natural muscle memory
- While in sequence mode, Ctrl+V advances to next item + pastes
- Requires clear "Sequence Mode" banner to avoid confusion

**Alternative rejected:** Dedicated key like Ctrl+Shift+V (adds new shortcut to learn)

**Why:** Most natural UX; users expect Ctrl+V to do something; sequence mode is expected behavior in context.

**Risk:** Could confuse users if not clearly labeled. Mitigation: prominent indicator "Sequence Mode: Item 1/3" at top of screen.

---

### Sequence State Persistence
**Chosen: Session-only (lost on app close)**
- Simpler implementation; no DB state to manage
- Sequence clears if popup closes, locked, or hotkey triggered from different window

**Alternative rejected:** Persistent (save/restore sequence state)

**Why:** Sequences are typically used once per task, then discarded. Persisting adds complexity for unclear benefit.

**Future:** Can be revisited if users request it; schema doesn't prevent adding persistence later.

---

## Database Changes

### Schema Expansion: v2 → v3

**New table: `groups`**
```sql
id (PK), name (unique), color, created_at, updated_at
```

**Modified table: `clipboard_items`**
```sql
ADD COLUMN group_id INTEGER REFERENCES groups(id) ON DELETE SET NULL
```

**Migration on upgrade:**
1. Create `groups` table
2. Insert default "Uncategorized" group (id=1, gray color)
3. Add `group_id` column to clipboard_items (defaults to 1)
4. All existing items automatically belong to "Uncategorized"
5. Zero data loss; backward compatible

---

## File Structure (New & Modified)

### New Files (6)
```
flutter_poc/lib/
├── models/
│   ├── group.dart                (Group model: id, name, color)
│   └── sequence_session.dart     (SequenceSession: items, currentIndex)
├── services/
│   ├── group_service.dart        (GroupService: CRUD operations)
│   └── sequence_service.dart     (SequenceService: session management)
└── widgets/
    └── groups_panel.dart         (GroupsPanel: sidebar widget)
```

### Modified Files (3)
```
flutter_poc/lib/
├── models/clipboard_item.dart    (add groupId field)
├── services/storage_service.dart (add v3 migration)
└── screens/home_screen.dart      (major UI overhaul: ~500 lines added)
```

### Documentation Files (2)
```
docs/
├── PHASE-2-PLAN-GROUPS-AND-SEQUENTIAL.md  (detailed spec, 400+ lines)
└── PHASE-2-MOCKUPS.md                     (UI mockups, state diagrams)
```

---

## Implementation Timeline

| Phase | Duration | Deliverables |
|-------|----------|--------------|
| **DB & Models** | Day 1 | Group model, v3 migration, groupId field |
| **Services** | Day 1–2 | GroupService, SequenceService |
| **Groups UI** | Day 2–3 | GroupsPanel, context menus, filtering |
| **Sequence** | Day 3–4 | Multi-select, sequence indicator, keyboard shortcuts |
| **Testing** | Day 4–5 | Manual QA, edge cases, database migration test |
| **Total** | **~10 days** | Complete Phase 2 implementation |

---

## Critical Questions Needing Your Input

1. **Sidebar Collapsibility:** Should sidebar be visible by default on large screens (600px+), or always hidden until user clicks [≡]?
   - **Option A (recommended):** Visible by default on large screens; hidden by default on small screens (responsive)
   - **Option B:** Always hidden; click [≡] to toggle open/close

2. **Default Group for New Items:** When user has "Code Snippets" group selected and copies text, should it go to Code Snippets or Uncategorized?
   - **Option A (recommended):** Goes to selected group (follows user intent)
   - **Option B:** Always goes to Uncategorized (simple; user manually moves if needed)

3. **Multi-Select Visibility:** Should checkboxes be visible always, or only appear when user activates multi-select mode (Ctrl+Click)?
   - **Option A (recommended):** Hidden by default; checkboxes appear after first Ctrl+Click
   - **Option B:** Always visible (clutter, but discoverable)

4. **Sequence Keyboard Shortcut:** Is Ctrl+V the right choice for advancing, or prefer a different key?
   - **Current:** Ctrl+V advances (reuses paste muscle memory)
   - **Alternative:** Ctrl+Shift+V (more explicit, but new shortcut)
   - **Alternative:** Function key (F1–F12) to avoid clipboard conflicts

5. **Group Color Coding:** Should Phase 2.0 support colors, or defer to Phase 2.1?
   - **Current plan (2.0):** Monochrome (all groups same gray color)
   - **Alternative:** Support color picker in Phase 2.0 (adds ~4 hours of work)

6. **Database Version Bump:** Ready to go from v2 → v3, with v2→v3 migration handling?
   - **Confirmation needed:** This is a forward-only change (no rollback plan)

---

## Acceptance Criteria Summary

### Groups Feature
- ✓ Create/rename/delete groups
- ✓ Move items between groups
- ✓ Filter by group; search works across groups
- ✓ Persistence across app restarts
- ✓ v2→v3 migration with zero data loss
- ✓ All existing items in "Uncategorized" on upgrade

### Sequential Paste Feature
- ✓ Multi-select 2+ items (Ctrl+Click, Ctrl+A)
- ✓ Start sequence (button or Ctrl+Shift+S)
- ✓ Indicator shows "Item 1/N" progress
- ✓ Ctrl+V advances to next item (clipboard updated)
- ✓ Last item → Ctrl+V → exits with "Sequence complete" toast
- ✓ Esc cancels sequence
- ✓ Session-only (not persisted)

---

## Testing Strategy

### Pre-Implementation Testing (Stakeholder Signoff)
- [ ] Review database schema changes (§3 in detailed plan)
- [ ] Review UI mockups (PHASE-2-MOCKUPS.md)
- [ ] Confirm keyboard shortcuts (no OS collisions)
- [ ] Answer critical questions above

### During Implementation
- [ ] Database migration test (v2 → v3 keeps all data)
- [ ] CRUD operations for groups
- [ ] Fuzzy search works across groups
- [ ] Multi-select + sequence flow

### Post-Implementation QA
- [ ] Manual testing checklist (25 test cases in detailed plan)
- [ ] Edge cases (delete group with items, exit sequence mid-way, etc.)
- [ ] Performance (100+ groups, 50+ selected items)
- [ ] Keyboard shortcuts on all platforms (Linux/Windows/macOS)

---

## Risk Assessment

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|-----------|
| Groups UI clutters screen | High | Medium | Collapsible sidebar; responsive design |
| Ctrl+V confusion in sequence | Medium | Medium | Clear "Sequence Mode" indicator |
| DB migration loses data | Critical | Low | Thorough testing; backup existing DB |
| Keyboard shortcut collision | Medium | Low | Cross-platform testing |
| Performance (100+ groups) | Medium | Low | Indexed database queries; lazy-load groups |

---

## Success Criteria

### Phase 2 is successful if:
1. User can organize 500 clipboard items into 10+ named groups
2. Fuzzy search works across all groups (finds items in any group)
3. User can select 5+ items and sequence-paste them without errors
4. All Phase 1 features (pinning, app exclusions, paste-as-plain) work with groups
5. v2 database upgrades to v3 without data loss
6. No performance degradation vs. Phase 1 (search still <50ms on 10k items)
7. Keyboard shortcuts don't conflict with OS/browser defaults

---

## Next Steps (Contingent on Your Approval)

1. **Get sign-off** on 6 critical questions above
2. **Confirm architectural decisions** (sidebar, Ctrl+V, etc.)
3. **Create GitHub issues** for each component (DB, models, services, UI)
4. **Begin implementation** starting with database layer
5. **Daily progress updates** in PHASE-2-PROGRESS.md

---

## Documents Provided

1. **PHASE-2-PLAN-GROUPS-AND-SEQUENTIAL.md** (detailed, 500+ lines)
   - Database schema (§1.2)
   - Model layer (§1.3)
   - Service layer (§1.4)
   - UI components (§1.5–1.7)
   - Sequential paste (§2)
   - Implementation order (§3.2)
   - Architectural decisions & trade-offs (§4)
   - Acceptance criteria (§5)
   - Testing plan (§5)

2. **PHASE-2-MOCKUPS.md** (visual reference)
   - Groups sidebar (expanded/collapsed)
   - Context menu (move to group)
   - Dialogs (create/rename/delete group)
   - Multi-select UI
   - Sequence mode active/complete
   - Keyboard shortcuts reference card
   - State transitions diagram
   - Responsive design notes

3. **PHASE-2-REVIEW-REQUEST.md** (this document)
   - Executive summary
   - Key decisions
   - Critical questions
   - Risk assessment
   - Success criteria

---

## Feedback Needed

Please review and provide feedback on:

### Must-Have Decisions
- [ ] Sidebar collapsibility (default visible vs. hidden)?
- [ ] Default group for new items?
- [ ] Multi-select checkbox visibility?
- [ ] Sequence advancement key (Ctrl+V vs. alternative)?
- [ ] Group colors in 2.0 or defer to 2.1?
- [ ] Database v2→v3 migration approved?

### Design Questions
- [ ] Any UI concerns with mockups?
- [ ] Any accessibility concerns?
- [ ] Any keyboard shortcut conflicts on your system?

### Scope Questions
- [ ] Are there any features NOT included that should be?
- [ ] Any features that should be removed or deferred?
- [ ] Any integration points I'm missing with Phase 1?

### Timeline Questions
- [ ] Is 10 days realistic, or should we adjust?
- [ ] Any blockers or dependencies I'm missing?

---

**Waiting for your review and approval to proceed with implementation.**