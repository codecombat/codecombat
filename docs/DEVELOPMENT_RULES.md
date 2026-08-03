# Development Rules

These rules apply to every contribution to Chiritsumo.

## Required reading and documentation

- Read `docs/PRODUCT_RULES.md` and this file before modifying product behavior or persistence.
- `docs/PRODUCT_RULES.md` is the functional and business source of truth.
- Update `docs/PRODUCT_RULES.md` in the same change whenever behavior, validation, navigation, display semantics, or persistence meaning changes.
- Update this file when a new implementation constraint or regression-prevention rule is introduced.
- When a repository does not contain these files, create them before making functional changes.
- In DEVELOPMENT_RULES.md add only generic rules for development, not specific to the product, and ask confirmation to the user for modifications.

## Change discipline

- Do not remove or weaken an existing feature, validation, confirmation, navigation route, backup field, or setting without explicit approval.
- Keep unrelated behavior unchanged.
- Prefer one canonical implementation for shared domain logic instead of duplicating slightly different rules in UI and persistence layers.
- UI validation improves feedback; repository validation is authoritative.
- Cross-record validation and the write it protects must execute in one database transaction.
- Editing validation must exclude the record being edited.
- Perform a regression review before completion, including flows adjacent to the requested change.

## UI and accessibility rules

- Preserve approved flows and visual hierarchy unless a change is explicitly requested.

## Review checklist

Before declaring work complete:

- Compare the changed behavior with `docs/PRODUCT_RULES.md`.
- Review the diff for accidental feature deletion, especially dialogs, validation, navigation state, and backup fields.
- Verify every UI restriction also has a persistence-side guard when it represents a business invariant.
