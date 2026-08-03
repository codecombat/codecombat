# Japanese JavaScript Quest — Product Rules

This document is the functional and business source of truth for the local Japanese JavaScript learning campaign under `app/assets/japanese-js-quest`.

## Product scope

- The product is an original, local, browser-based CodeCombat-style campaign.
- It must not copy or depend on official or Premium CodeCombat level content.
- It must run from the static campaign directory with `py -m http.server 8000` or `python -m http.server 8000`.
- The primary learner is a Japanese elementary-school child. Explanations must be understandable without prior English reading ability.

## Campaign and persistence

- The campaign contains 23 missions numbered 00 through 22.
- Missions unlock linearly unless admin mode explicitly unlocks them.
- Completion state and edited code are stored in browser `localStorage`.
- Wizard level is never stored as a separate mutable value. It is derived deterministically from scripted mission rewards.
- Resetting progress removes completion and saved mission code after confirmation.
- Resetting one mission's code requires confirmation and restores that mission's current canonical starter code.
- A legacy saved starter may be migrated only when it exactly matches the replaced canonical starter; personally edited code must not be overwritten automatically.
- When missions are inserted and later missions are renumbered, saved code, completed mission identifiers and the unlocked position must be migrated so that existing learner work remains attached to the same lesson.

## Controls and learner assistance

- The editor visibly reminds the learner of `Ctrl+C`, `Ctrl+V` and `Ctrl+Z`.
- `Ctrl+Enter` and `Command+Enter` execute the mission with the same behavior as clicking `実行する`.
- Mission code is saved automatically in the browser.
- Hints can be revealed progressively.
- The full reference solution remains disabled until the learner has attempted the mission three times.
- Showing the solution requires confirmation because it replaces the current editor content.
- The next-mission button appears only after the current mission succeeds on every field, except for the intentional infinite-loop demonstration described below.

## Mission pedagogy

- Every genuinely new programming concept must be introduced in the mission's `新しい考え方` section before the learner is expected to use it.
- Mission 00 contains exactly one executable line: `hero.say('Hello Yuzu');`.
- Mission 00 explains object, method, dot access, parameters, string literals and the difference between program words and quoted text in the hero's world.
- Mission 01 introduces code comments. Text after `//` is explained as a human-readable note that is not executed.
- Mission 03 introduces booleans, `true`, `false`, `const`, assignment with `=`, reuse of a named value, the English word `always`, and `hero.isTrue(boolean)`.
- Mission 03 has completed starter code. The learner validates it by executing it without needing to edit it.
- Mission 04 is the first `if` mission. It introduces `hero.readSign()`, return values, `if`, braces and comparison, while referring back to constants and assignment learned in mission 03.
- Mission 04 must not repeat dedicated concept cards for `const`, constants or assignment. Its learning guide contains one card for the `hero.readSign()` return value, one card for `if`, and one card for comparison with `===`.
- Mission 14 is an intentional infinite-loop demonstration using `while (true)`.
- Mission 15 is the first later mission using `while (!hero.isAtGoal())`.
- Later missions introduce `else`, `else if`, logical operators, loops, mutable variables, remainder and nested loops when first used.
- Branch starter code from mission 04 onward contains Japanese `hero.say(...)` thinking prompts inside each branch. `else` prompts begin with `その他` rather than pretending to have a named condition.

## Concept card reference base

- Every genuinely new concept is introduced through a dedicated card displayed in the mission's `新しい考え方` section.
- Each concept card is stored exactly once in the canonical concept-card reference base and has a stable, unique ID.
- A mission guide stores its title and the ordered IDs of the cards it displays; it must not duplicate the card title or explanation outside the reference base.
- The adventure renders the visible card title, explanatory HTML, code styling and explanatory tooltips by resolving those IDs from the reference base.
- Every rendered card exposes its source ID through `data-concept-card-id` so later learning tools can connect visible content to the same canonical record.
- Concept-card IDs must never be reassigned to a different meaning or silently reused after publication.
- Future flashcards, quizzes and review activities must reuse the same reference records rather than copying card content into a second data source.
- Refactoring storage or rendering must preserve the approved visual appearance, code markup, tooltip behavior and mission card order.

## Boolean lesson and `hero.isTrue`

- A boolean is a value that can only be `true` or `false`.
- `hero.isTrue(boolean)` accepts exactly one JavaScript boolean value.
- Passing `true` makes the hero say `正しいです。`.
- Passing `false` makes the hero say `違いますよ。`.
- A missing, extra or non-boolean parameter produces a blocking Japanese hero explanation that only `true` or `false` is accepted.
- Mission 03 defines `const alwaysTrue = true` and `const alwaysFalse = false`, calls `hero.isTrue(...)` for both values, and then collects its required gem.
- Mission 03 validates only after the existing program has been executed and both boolean cases have been checked.

## Standalone loading and stable curriculum rendering

- The documented launch from `app/assets/japanese-js-quest` is a standalone static-server mode.
- Standalone mode uses the built-in textarea editor fallback and must not request CodeCombat's absent `/javascripts/ace/ace.js` asset.
- An optional enhanced editor may be used only when its assets are explicitly available; failure to load an optional editor must never block the game or produce a required 404 request.
- Selecting or displaying a mission must not start unbounded work. In particular, selecting mission 03 must remain responsive before the learner presses `実行する`.
- The displayed mission number is authoritative UI state and must never be changed temporarily to render legacy guides.
- A `jsquest:missionloaded` handler must not dispatch another `jsquest:missionloaded` event while handling the current event.
- Renumbered legacy guides, glossary thresholds and technical terms use a pure final-ID-to-legacy-ID conversion without changing the DOM.
- Mission execution uses the static `quest-worker.js` worker, which explicitly loads both `engine.js` and `curriculum-engine.js`.
- The application must not globally replace or monkey-patch the browser's native `Worker` constructor.
- The execution worker must report initialization and execution errors back to the page instead of silently waiting until timeout.
- Concept and reading annotations run a bounded number of times after mission rendering. They must not use a permanent subtree observer that mutates the same observed content.

## Japanese reading and technical vocabulary

- Difficult kanji above the expected reading level at the beginning of Japanese third grade receive full-word reading tooltips.
- Reading help in mission explanations uses a light-blue visual treatment.
- Reading help inside the glossary uses a quieter gray treatment and must not interfere with existing code-component tooltips.
- When Japanese programmers commonly use an English technical term, the concept introduction displays both names.
- The English term is written in Latin characters and exposes its katakana pronunciation on hover, keyboard focus and click.
- Examples include Object, Method, Parameter, String, Literal, Comment, Constant, Assignment, Return value, Conditional branch, Boolean, Variable, Operator, Loop and Infinite loop.

## Reference panel

- `ことば・命令のヘルプ` is collapsed by default.
- Its content grows only with concepts and vocabulary introduced up to the current mission.
- It contains sections for methods, parameters/variables, grammar/operators and map vocabulary.
- English code components can be hovered, focused or clicked to display Japanese meaning and pronunciation.
- `gem` explains that gems give experience, increase wizard level and unlock powers.
- `transform`, `form` and `frog` are hidden before mission 02.
- `boolean`, `true`, `false`, `always`, constants, assignment and `hero.isTrue(boolean)` appear from mission 03.
- `while (true)` and the infinite-loop warning appear from mission 14.

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
- `hero.isTrue(boolean)` requires exactly one boolean value. Invalid input produces a Japanese hero explanation.
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

## Intentional infinite-loop mission

- Mission 14 teaches conditional loops and the danger of a condition that stays `true` forever.
- Its canonical code collects the required gem and then runs `while (true)` with a Japanese `hero.say(...)` inside every iteration.
- The explanation clearly states that an always-true loop cannot reach later instructions and may continuously consume computer resources.
- The explanation clearly instructs the learner to reload the browser with the circular reload icon or `Ctrl+F5`.
- On the first click on `実行する`, mission completion and the next mission unlock are persisted before the infinite demonstration starts.
- During the demonstration, closing the speech bubble starts the next loop iteration and shows the same speech again.
- Adventure controls remain unavailable during the demonstration. Reloading the page is the intended exit.
- After reload, the persisted completion allows the learner to continue to mission 15.
- Automated validation must not execute the truly infinite canonical solution directly; it validates the special mission metadata and runtime mechanism instead.

## Legend disclosure

- The legend reveals objects progressively and contains no duplicate entries.
- The hero is visible from mission 00.
- Gem and goal are visible from mission 01.
- Frog is hidden before mission 02 and appears exactly once from mission 02 onward.
- Trap appears from mission 07.
- Key and door appear from mission 09.
- Enemy appears from mission 15.
- Future forms such as dragon stay hidden until their story introduction.

## Admin mode

- Admin mode is enabled by adding `?admin=1` to the local URL, for example `http://localhost:8000/?admin=1`.
- Admin mode is intentionally not protected.
- Admin mode adds a visible button that unlocks all missions for manual verification.
- Unlocking all missions does not automatically mark missions complete or grant persisted wizard level.
- Once the admin unlock button is activated, the same admin-unlocked state must be used both when rendering mission buttons and when checking whether a selected mission may open.

## Speech and branch prompts

- `hero.say(...)` displays a comic-style bubble and pauses execution until closed.
- Locked powers and understandable runtime errors reuse the same trace-based blocking speech mechanism.
- Multiple speech calls appear at their true execution positions and never get pre-collected before movement.

## Validation and regression protection

- The focused validator must execute every finite reference solution on every field.
- It verifies mission count, consecutive identifiers, unique identifiers, required gems, scripted levels, transformation gates and ordered action traces.
- It verifies invalid direction, invalid parameter, invalid boolean, unknown method, invalid transformation and locked dragon behavior.
- It verifies the boolean mission checks both `true` and `false`.
- It verifies the infinite-loop mission is prevalidated before execution and requires page reload rather than being run directly in the test process.
- It verifies multi-field ordering, field-progress source rules, admin URL behavior and progressive legend thresholds.
- It verifies saved curriculum migration preserves existing code and progress semantics.
- It verifies every mission guide resolves its ordered concept-card IDs from the canonical reference base, all IDs are unique and every rendered card exposes its ID.
- It verifies standalone mode does not request the absent Ace asset and that curriculum rendering does not recursively redispatch mission loading.
- It verifies the static execution worker loads the complete engine, the app does not create Blob workers, and admin navigation uses the canonical unlock predicate.
- It verifies concept annotation does not install a self-mutating permanent subtree observer.
- It verifies required documentation exists and remains consistent with the implementation.
- ESLint must pass for changed JavaScript files.
