---
phase: 14-checkbox-mode-polish
plan: 01
subsystem: interactive-ui
tags: [zcurses, resize, TRAPWINCH, help-overlay, keybindings]
dependency_graph:
  requires:
    - phase: 13-01
      provides: zcurses interactive engine with navigation and actions
  provides:
    - TRAPWINCH resize handler with window recreation
    - Help overlay window toggled with ? key
  affects: [lib/_td_interactive]
tech_stack:
  added: []
  patterns: [TRAPWINCH-function-form, redraw-flag-polling, zcurses-overlay-window]
key_files:
  created: []
  modified:
    - lib/_td_interactive
key_decisions:
  - "TRAPWINCH function form (not trap command) for zcurses signal compatibility"
  - "200ms timeout polling for resize flag -- avoids zcurses signal race"
  - "Help overlay as separate zcurses window centered on screen with border"
  - "Any key dismisses help (except ? which toggles) -- simple UX"
  - "Help visibility reset on resize (helpwin destroyed with cleanup_windows)"
  - "list_name promoted to global _TD_UI_LIST_NAME for resize handler access"
patterns-established:
  - "TRAPWINCH sets flag, timeout branch checks flag -- never redraw in signal handler"
  - "Overlay windows: create with addwin, add to _TD_UI_WINDOWS, border+content, delwin on dismiss"
requirements-completed: [UX-07, UX-08]
duration: 2min
completed: 2026-04-03
---

# Phase 14 Plan 01: Resize Handling & Help Overlay Summary

**TRAPWINCH resize handler with window recreation and zcurses help overlay (? key) for interactive board**

## Performance

- **Duration:** 2 min
- **Started:** 2026-04-03T22:43:48Z
- **Completed:** 2026-04-03T22:45:57Z
- **Tasks:** 2
- **Files modified:** 1

## Accomplishments
- Terminal resize during `td ui` redraws board correctly via TRAPWINCH flag + timeout polling
- `?` key shows centered help overlay with all keybindings (Navigation, Actions, General)
- Any key dismisses help overlay; resize also clears it cleanly
- Status bar updated with `?:help` hint for discoverability

## Task Commits

Each task was committed atomically:

1. **Task 1: TRAPWINCH resize handler with window recreation** - `f08bc77` (feat)
2. **Task 2: Help overlay window with ? key** - `6d71bcf` (feat)

## Files Created/Modified
- `lib/_td_interactive` - Added resize globals, TRAPWINCH handler, handle_resize function, help overlay show/hide functions, ? key dispatch, status bar hint

## Decisions Made
- TRAPWINCH function form (not `trap 'code' WINCH`) for reliable zcurses signal handling
- Redraw flag pattern: TRAPWINCH only sets `_TD_UI_NEED_REDRAW=1`, actual redraw happens in timeout branch of input loop (avoids zcurses calls inside signal handler)
- Promoted `list_name` to global `_TD_UI_LIST_NAME` so resize handler can pass it to render
- Help overlay is a separate zcurses window (helpwin) that gets added to `_TD_UI_WINDOWS` array for proper cleanup
- Help visibility reset to 0 on resize -- helpwin is destroyed with all windows, user can press ? again after resize
- Dismiss-on-any-key: when help visible, any key except ? closes help and continues (next keypress does the action)

## Deviations from Plan

None -- plan executed exactly as written.

## Known Stubs

None.

## Issues Encountered
None.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Resize handling and help overlay complete
- Ready for Plan 02 (checkbox mode)

---
## Self-Check: PASSED

*Phase: 14-checkbox-mode-polish*
*Completed: 2026-04-03*
