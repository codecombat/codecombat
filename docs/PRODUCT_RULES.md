# Japanese JavaScript Quest — Product Rules

This document is the functional and business source of truth for the local Japanese JavaScript learning campaign under `app/assets/japanese-js-quest`.

## Product scope

- The product is an original, local, browser-based CodeCombat-style campaign.
- It must not copy or depend on official or Premium CodeCombat level content.
- It must run from the static campaign directory with `py -m http.server 8000` or `python -m http.server 8000`.
- The primary learner is a Japanese elementary-school child. Explanations must be understandable without prior English reading ability.

## Campaign and persistence

- The campaign contains 21 missions numbered 00 through 20.
- Missions unlock linearly unless admin mode explicitly unlocks them.
- Completion state and edited code are stored in browser `localStorage`.
- Wizard level is never stored as a separate mutable value. It is derived deterministically from scripted mission rewards.
- Resetting progress removes completion and saved mission code after confirmation.
- Resetting one mission's code requires confirmation and restores that mission's current canonical starter code.
- A legacy saved starter may be migrated only when it exactly matches the replaced canonical starter; personally edited code must not be overwritten automatically.

## Controls and learner assistance

- The editor visibly reminds the learner of `Ctrl+C`, `Ctrl+V` and `Ctrl+Z`.
- `Ctrl+Enter` and `Command+Enter` execute the mission with the same behavior as clicking `実行する`.
- Mission code is saved automatically in the browser.
- Hints can be revealed progressively.
- The full reference solution remains disabled until the learner has attempted the mission three times.
- Showing the solution requires confirmation because it replaces the current editor content.
- The next-mission button appears only after the current mission succeeds on every field.

## Mission pedagogy

- Every genuinely new programming concept must be introduced in the mission's `新しい考え方` section before the learner is expected to use it.
- Mission 00 contains exactly one executable line: `hero.say('Hello Yuzu');`.
- Mission 00 explains object, method, dot access, parameters, string literals and the difference between program words and quoted text in the hero's world.
- Mission 01 introduces code comments. Text after `//` is explained as a human-readable note that is not executed.
- Mission 03 introduces `const`, assignment with `=`, return values, reuse of a named value, `if`, braces and comparison.
- Later missions introduce `else`, `else if`, logical operators, booleans, loops, mutable variables, remainder and nested loops when first used.
- Branch starter code from mission 03 onward contains Japanese `hero.say(...)` thinking prompts inside each branch. `else` prompts begin with `その他` rather than pretending to have a named condition.

## Japanese reading and technical vocabulary

- Difficult kanji above the expected reading level at the beginning of Japanese third grade receive full-word reading tooltips.
- Reading help in mission explanations uses a light-blue visual treatment.
- Reading help inside the glossary uses a quieter gray treatment and must not interfere with existing code-component tooltips.
- When Japanese programmers commonly use an English technical term, the concept introduction displays both names.
- The English term is written in Latin characters and exposes its katakana pronunciation on hover, keyboard focus and click.
- Examples include Object, Method, Parameter, String, Literal, Comment, Constant, Assignment, Return value, Conditional branch, Boolean, Variable, Operator and Loop.

## Reference panel

- `ことば・命令のヘルプ` is collapsed by default.
- Its content grows only with concepts and vocabulary introduced up to the current mission.
- It contains sections for methods, parameters/variables, grammar/operators and map vocabulary.
- English code components can be hovered, focused or clicked to display Japanese meaning and pronunciation.
- `gem` explains that gems give experience, increase wizard level and unlock powers.
- `transform`, `form` and `frog` are hidden before mission 02.

## Action execution

- Every click on `実行する`, including Ctrl/Command+Enter, starts the adventure from field 1 of the current mission.
- The complete field, hero position, hero form, collected items, statistics and active speech UI are reset before field 1 and before every later field.
- User code is simulated once per field and rendered from the engine trace.
- Movement, transformation, speech and failure speech are rendered in exact source order.
- Each visible action must finish before the next action begins.
- Speech pauses execution until the learner closes the bubble.
- Speech bubbles are attached visually to the hero's position at the corresponding trace frame.

## Speech bubble accessibility

- Speech bubbles are mounted outside the field clipping context.
- They appear above all panels and remain aligned with the hero during scrolling or resizing.
- The close button must always remain reachable. If the viewport would crop the bubble, it is clamped into the visible viewport.
- It is acceptable for a speech bubble to cover surrounding instructions temporarily.

## Methods and understandable errors

- Invalid method parameters must produce a blocking Japanese hero speech bubble before the run is reported as failed.
- Direction-taking methods accept exactly one value: `right`, `left`, `up` or `down`.
- A missing, extra or invalid direction produces a dedicated Japanese explanation that repeats all four accepted values.
- Methods that accept no parameters reject supplied parameters with a Japanese hero explanation.
- `hero.say(message)` requires exactly one string value. Invalid input produces a Japanese hero explanation.
- Unknown or misspelled `hero` methods produce a Japanese hero explanation asking the learner to check the command spelling.
- An invalid transformation name produces a Japanese hero explanation that the requested form is not understood.

## Transformations and levels

- `hero.transform('hero')` and `hero.transform('frog')` require wizard level 1.
- `hero.transform('dragon')` is a recognized future power requiring wizard level 99.
- A recognized transformation used below its required level makes the hero say `この技はまだ使えないよ。` and leaves the current form unchanged.
- Unknown transformation values are different from locked recognized powers and use the invalid-transformation explanation.
- Frog and dragon use original local sprites.
- Dragon must not be exposed in normal mission instructions, glossary or legend before its future story introduction.

## Gems, experience and level progression

- Mission 00 has no required gem and wizard level 0.
- Every mission after mission 00 displays and requires at least one gem.
- A mission cannot validate unless its required gem count is collected in every field.
- Maps without a gem receive one on the reference solution path.
- Level thresholds are 1 gem for level 1, 5 for level 2, 12 for level 3, then 22, 35, 51 and subsequent scripted thresholds.
- Missions 00 and 01 use level 0. Missions 02 through 05 use level 1.
- The mission interface displays current wizard level and an experience progress bar.
- Crossing a threshold displays a blocking level-up modal distinct from hero speech.

## Multiple fields

- A mission may contain one or more fields represented by its variants.
- The interface displays the current field number and total field count with a progress bar.
- One click on `実行する` runs the same unchanged code through all fields in order, starting with field 1.
- A successful field advances automatically to the next field.
- If a field fails, execution stops on that field and the mission remains incomplete.
- Re-running always restarts at field 1, not at the failed or previously displayed field.
- A mission completes only after the same code passes all fields.

## Legend disclosure

- The legend reveals objects progressively and contains no duplicate entries.
- The hero is visible from mission 00.
- Gem and goal are visible from mission 01.
- Frog is hidden before mission 02 and appears exactly once from mission 02 onward.
- Trap appears from mission 06.
- Key and door appear from mission 08.
- Enemy appears from mission 13.
- Future forms such as dragon stay hidden until their story introduction.

## Admin mode

- Admin mode is enabled by adding `?admin=1` to the local URL, for example `http://localhost:8000/?admin=1`.
- Admin mode is intentionally not protected.
- Admin mode adds a visible button that unlocks all missions for manual verification.
- Unlocking all missions does not automatically mark missions complete or grant persisted wizard level.

## Speech and branch prompts

- `hero.say(...)` displays a comic-style bubble and pauses execution until closed.
- Locked powers and understandable runtime errors reuse the same trace-based blocking speech mechanism.
- Multiple speech calls appear at their true execution positions and never get pre-collected before movement.

## Validation and regression protection

- The focused validator must execute every reference solution on every field.
- It verifies mission count, unique identifiers, required gems, scripted levels, transformation gates and ordered action traces.
- It verifies invalid direction, invalid parameter, unknown method, invalid transformation and locked dragon behavior.
- It verifies multi-field ordering, field-progress source rules, admin URL behavior and progressive legend thresholds.
- It verifies required documentation exists and remains consistent with the implementation.
- ESLint must pass for changed JavaScript files.
