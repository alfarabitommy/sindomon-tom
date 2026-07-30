# SINDOMON Architectural Standards — Knowledge Persistence Plan

## Status: NOT EXECUTED (Verified 2026-07-30)

ADR recovery attempt via `manage_adr(mode='get')` returned `no_adr`. Graph searches for UI tokens and API contract terms returned zero relevant matches. The 3 ADR `update` calls below were never run by an implementation agent.

**Verification report:** `.kilo/plans/memory_verification_test.md`

## Goal
Persist 3 domains of refactored standards into Codebase Memory MCP as Architecture Decision Records (ADRs). No Dart code changes. MCP-only operation.

## Project: `home-tommy-dev-sindomon-tom`

---

## Step 1: UI/UX Design System ADR

Tool: `manage_adr` mode=`update`
Section: `ui-ux-design-system`

```markdown
# UI/UX Design System — "Clean Look" Enterprise Standard

## Primary CTA Buttons
- Color: `Color(0xffF6B300)` (Amber/Yellow-Orange)
- Text color: `Color(0xFF23251D)` (Dark)
- Shape: `StadiumBorder()`
- NEVER use default Material blue for CTAs.

## Form / Data Cards
- Elevation: `0`
- Color: `Colors.white`
- Border: `BorderSide(color: Colors.grey.shade200, width: 1.5)`
- Max width: 600px

## TextFields (Soft Filled Style)
- `filled: true`
- `fillColor: Color(0xFFF9FAFB)`
- Border: `Color(0xFFE5E7EB)`
- `borderRadius: BorderRadius.circular(8)`

## Typography
- Labels: `Color(0xFF374151)` (muted gray)
- Headings: `Color(0xFF111827)` (near-black)

## Error UI
- Floating SnackBars with `Color(0xFFEF4444)` (Red-500)
- Icon: `Icons.error_outline`
```

---

## Step 2: Architecture & Layout Rules ADR

Tool: `manage_adr` mode=`update`
Section: `architecture-layout-rules`

```markdown
# Architecture & Layout Rules

## Form Pages (`add_*.dart`) — Fixed Viewport Architecture
- `AppHeader` and `AppFooter` are sticky in the main `Column`.
- Form card MUST be wrapped in `Expanded > SingleChildScrollView`.
- Only inner content scrolls; header and footer remain fixed.

## Routing
- Centralized strictly in `menu_config.dart` and `AppSidebar`.
- No route definitions scattered across page files.

## Role-Based UI
- Use dynamic rendering (e.g., `_roleId`) in `build()` method.
- Conditionally show/hide components (e.g., Command Center map vs Placeholder).
- Do NOT create redundant page files for role variations.
```

---

## Step 3: Backend API Contract & Parsing Quirks ADR

Tool: `manage_adr` mode=`update`
Section: `backend-api-contract`

```markdown
# Backend API Contract & Parsing Quirks (CRITICAL)

## CodeIgniter JSON Format
- The `data` object returned by the API is a **single Map** (`{}`), NOT a List (`[]`).
- NEVER use `data["data"][0]`. Always use `data["data"]` directly.
- Example correct access: `data["data"]["username"]`

## Token Location
- The active JWT token is at the **root** of the response: `data["jwt_token"]`.
- NOT nested inside the `data` object (not `data["data"]["jwt_token"]`).

## Role ID Mapping
- API returns field: `roles_id` (note: plural 's').
- Flutter app MUST save it to SharedPreferences as `"roleid_login"`.
- Key mismatch is intentional — backend uses `roles_id`, frontend key is `roleid_login`.
```

---

## Step 4: Verification

After executing the 3 `manage_adr` calls above, call `manage_adr` mode=`get` to confirm all 3 sections are present. Then produce `memory_update_log.md` in the workspace root confirming:

1. Project: `home-tommy-dev-sindomon-tom`
2. Number of ADR sections created: 3
3. Section names: `ui-ux-design-system`, `architecture-layout-rules`, `backend-api-contract`
4. Summary of rules persisted per section

## Execution Order
1. `manage_adr` update → `ui-ux-design-system`
2. `manage_adr` update → `architecture-layout-rules`  
3. `manage_adr` update → `backend-api-contract`
4. `manage_adr` get → verify all sections
5. Write `memory_update_log.md` → confirm completion
