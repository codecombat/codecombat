# ENG-2644 Algebra/Cyber shared-component refactor

## Extracted shared components

- `HackstackHero.vue`: shared title, Powered By logo, description, optional alignment badges, optional hero media, and an `actions` slot. `algebra` and `cyber` variants retain each page's existing layout and responsive styling.
- `HackstackFeaturesSection.vue`: shared feature-strip rendering. Each page passes its own translated titles, descriptions, alt text, and image paths.
- `HackstackPathwaySection.vue` and `HackstackPathwayCard.vue`: shared card/grid system for Algebra lesson flow, Algebra module structure, and Cyber pathways. Items provide labels, translated copy, images, icons, and Algebra tag variants.
- `HackstackInfoCard.vue`: shared standards/safety card. Each page passes its own icon, copy, document link, and visual variant.
- `HackstackFaq.vue` and `hackstackFaqItems.js`: shared FAQ rendering and shared construction of the existing HackStack FAQ content.
- Each shared Vue component has a colocated Storybook story covering its relevant variants.

Both `PageHackstackAlgebra.vue` and `PageHackstackCyber.vue` now compose these files from `app/views/landing-pages/hackstack/shared/`.

## Behavior kept page-owned

- Algebra's Get Solution CTA still opens the in-page `ModalGetLicenses`.
- Algebra's anonymous Explore CTA and curriculum CTA still open the teacher signup modal; signed-in Explore remains a direct Algebra guide link.
- Cyber still fetches teacher prepaids in `created()` and uses the async `me/isPaidTeacher` getter.
- Cyber anonymous users still see Get My Solution plus modal-based Explore.
- Cyber signed-in users without a teacher license, including non-teacher accounts, still see both CTAs and get a direct Cyber guide link.
- Cyber paid teachers still see only the direct-link Explore CTA.
- Cyber pathways still show Free Teacher Account for anonymous users and direct-link Try it now for signed-in users.

## Browser validation focus

- Check both hero layouts at desktop, tablet, and mobile widths, especially Cyber background cropping, badges, media alignment, and two-button wrapping.
- Exercise all three Cyber account states after the prepaid request settles.
- Confirm Algebra's two modal entry points, Cyber's signup modal, and Cyber's new-tab Get My Solution behavior.
- Compare Algebra lesson/module card heights and arrows, Cyber's five-card desktop grid and chevrons, and both standards/safety cards.
- Expand FAQ items on both pages and verify the shared open/close state and link styling.

## Deliberately not shared

- Algebra's testimonial/carousel remains page-specific because Cyber has no corresponding section.
- Algebra's curriculum-path diagram remains in `algebra/CurriculumPathSection.vue`; Cyber's pathway is a card grid with different CTA rules and no equivalent diagram.
- CTA account decisions and modal state remain in each page. Shared components only render passed content/actions, preventing one page's gating behavior from leaking into the other.

## Verification

- HackStack ESLint command passes.
- All changed Vue templates compile with `vue-template-compiler`.
- Full webpack reached asset emission but failed because this worktree has no `bower_components` dependencies (including `modernizr-mixin`, `treema`, and `fetch`). No successful full build is claimed.
