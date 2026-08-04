# Japanese JavaScript Quest — Product Rules

This document is the functional and business source of truth for the local Japanese JavaScript learning campaign under `app/assets/japanese-js-quest`.

## Product scope

- The product is an original, local, browser-based CodeCombat-style campaign.
- It must not copy or depend on official or Premium CodeCombat level content.
- It must run from the static campaign directory with `py -m http.server 8000` or `python -m http.server 8000`.
- The primary learner is a Japanese elementary-school child. Explanations must be understandable without prior English reading ability.

## Campaign and persistence

- The campaign contains 23 missions numbered 00 through 22.
- Missions unlock linearly unless admin mode explicitly unlocks them for the current loaded page.
- Completion state and edited code are stored in browser `localStorage`.
- Normal mission access is derived from the consecutive completed mission prefix: mission 00 is initially available, and each following mission becomes available only after every preceding mission has been completed.
- A persisted `unlocked` value is never authoritative by itself. Before the application starts, it is normalized from the completed mission prefix so a stale or admin-inflated value cannot expose later missions.
- Normalization preserves valid completed mission IDs, including later missions completed during admin verification, but those later completions do not unlock gaps in the normal linear path.
- Wizard level is never stored as a separate mutable value. It is derived deterministically from scripted mission rewards.
- Resetting progress removes completion and saved mission code after confirmation.
- Resetting one mission's code requires confirmation and restores that mission's current canonical starter code.
- A legacy saved starter may be migrated only when it exactly matches the replaced canonical starter; personally edited code must not be overwritten automatically.
- When missions are inserted and later missions are renumbered, saved code, completed mission identifiers and the unlocked position must be migrated so that existing learner work remains attached to the same lesson.

## Controls and learner assistance

- The editor visibly reminds the learner of `Ctrl+C`, `Ctrl+V`, `Ctrl+Z` and `Ctrl+F5`.
- `Ctrl+Enter` and `Command+Enter` execute the mission with the same behavior as clicking `実行する`.
- `Ctrl+F5` is identified as the full-page reload shortcut used by the intentional infinite-loop lesson.
- Mission code is saved automatically in the browser.
- Hints can be revealed progressively.
- The next-mission button appears only after the current mission succeeds on every field, except for the intentional infinite-loop demonstration described below.

## Final answers and learner partial help

- The final reference solution is available only in admin mode through a button labelled `答えを見る`.
- The admin final-answer button is enabled immediately for every selected mission; it does not require failed attempts.
- Displaying the final answer in admin mode requires no confirmation dialog and must not persist the final answer into the learner's saved mission code.
- A normal player must never be shown or receive the final reference solution through the interface.
- Normal-player help counts failed executions, not total executions. A successful execution does not increase the failure count.
- After three failed executions of the same mission, the player may open a near-complete partial solution through a button that is not labelled `答えを見る`.
- Showing the learner partial solution requires confirmation because it replaces the current editor content.
- The learner partial solution contains explanatory comments, important hints and a visible `TODO`, but omits at least one instruction required to solve the mission.
- Every generated learner partial solution must remain incomplete: it must differ from the final solution and fail at least one field of every finite mission.
- The learner partial solution may be saved as the learner's current code after confirmation.

## Mission pedagogy

- Every genuinely new programming concept must be introduced in the mission's `新しい考え方` section before the learner is expected to use it.
- Mission 00 contains exactly one executable line: `hero.say('Hello Yuzu');`.
- Mission 00 explains object, method, dot access, parameters, string literals and the difference between program words and quoted text in the hero's world.
- Mission 01 introduces code comments. Text after `//` is explained as a human-readable note that is not executed.
- Mission 01 displays a dedicated canonical card titled `// はコメント（Comment）` before its `hero.move(direction)` card.
- Mission 03 introduces booleans, `true`, `false`, `const`, assignment with `=`, reuse of a named value, constant naming in romaji, the common use of meaningful English names, and `hero.isTrue(boolean)`.
- Mission 03 has completed starter code. The learner validates it by executing it without needing to edit it.
- Mission 03 includes a Japanese explanatory comment directly above `const alwaysTrue = true;` and another directly above `const alwaysFalse = false;`.
- Mission 03 collects its gem and then continues to the flag. Successful execution must finish on the goal tile rather than on the gem tile.
- Mission 04 is the first `if` mission. It introduces `hero.readSign()`, return values, `if`, braces and comparison, while referring back to constants and assignment learned in mission 03.
- Mission 04 must not repeat dedicated concept cards for `const`, constants or assignment. Its learning guide contains one card for the `hero.readSign()` return value, one card for `if`, and one card for comparison with `===`.
- Mission 11 is titled `初めてのループ`, using the standard kanji spelling rather than `はじめてのループ`.
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
- The mission 03 naming card explains that constants can receive meaningful romaji names without spaces, that English names are commonly used, and that `alwaysTrue` means “always true”.
- A new-concept card must never be implemented only as ad-hoc mission HTML or an interface-only exception. It must be a record in the canonical concept-card database and be referenced by stable ID from its mission guide.
- Every canonical concept card must be referenced by exactly one mission guide, and every mission-guide card ID must resolve to a card whose `missionId` matches that mission.
- No terminology enhancer or other post-render script may append a second visual concept block outside the canonical card database and card-memory lifecycle.

## Concept-card validation and memory

- Every concept card starts face down until that card has been validated by the learner.
- This face-down default applies to every card without exception, including `// はコメント（Comment）` and cards introduced by future missions.
- The learner may reveal the unvalidated cards in any order.
- Only one unvalidated card may remain previewed at a time. Revealing another card or clicking outside the cards hides the previous preview again.
- A previewed card displays its complete canonical title, HTML explanation, code formatting and tooltips, plus a visible mini-quiz action.
- A previewed unvalidated card uses a background that is only slightly different from the normal card background.
- Every card has canonical quiz data associated with the same stable card ID.
- A card quiz contains between one and three very simple multiple-choice questions, using three or four choices per question.
- The questions must be answerable directly from the card and primarily verify that the explanation was read and understood.
- Wrong choices may include one plausible trap, while the remaining wrong choices should be clearly incorrect for a child learner.
- A quiz submission validates the card only when every question is answered correctly.
- An incorrect or incomplete submission does not reveal the correct answer. It reports only that at least one answer is wrong and invites the learner to read the card and retry.
- Closing a quiz without validating the card leaves that card unvalidated and returns it to the face-down state.
- A validated card remains face up with the previously approved normal card background and displays a success icon.
- Validated card IDs are persisted separately from mission completion and saved code, under a dedicated concept-memory storage key.
- The concept-memory record stores stable card IDs rather than mission positions or duplicated card content.
- The mission shows the number of validated cards and the total number of cards.
- The learner cannot open the editable code view or execute the mission until every concept card assigned to the current mission has been validated.
- Clicking the colored code preview, the run button, or the execution keyboard shortcut before all cards are validated redirects attention to the concept cards and explains the requirement in Japanese.
- The execution restriction applies equally to the normal run path and the special mission-14 preparation path.
- In admin mode, every quiz provides a review-only control that selects all correct choices automatically.
- The admin quiz-review control must not submit the quiz or validate the card by itself; the administrator can inspect the selected choices and submit normally.
- Admin mode also displays an admin-only control at the end of the section that validates every canonical card assigned to the current mission in one action.
- The admin validate-all control is absent outside `?admin=1`, persists through the same stable-card-ID memory store, and does not complete the mission or alter mission progression.
- Whenever a mission or concept card is added or changed, the same change must verify the canonical card record, stable mission-to-card mapping, face-down default, quiz data, card-memory validation, and the edit/execution gate for all cards in that mission.

## Boolean lesson and `hero.isTrue`

- A boolean is a value that can only be `true` or `false`.
- `hero.isTrue(boolean)` accepts exactly one JavaScript boolean value.
- Passing `true` makes the hero say `正しいです。`.
- Passing `false` makes the hero say `違いますよ。`.
- A missing, extra or non-boolean parameter produces a blocking Japanese hero explanation that only `true` or `false` is accepted.
- Mission 03 defines `const alwaysTrue = true` and `const alwaysFalse = false`, calls `hero.isTrue(...)` for both values, collects its required gem, and reaches the goal flag with two rightward moves.
- Mission 03 validates only after the existing program has been executed, both boolean cases have been checked, the gem has been collected and the goal has been reached.

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
- Progress access normalization runs synchronously before `app-v3.js`, so the first rendered mission list already reflects normal linear access rather than briefly exposing stale admin access.

## Japanese reading and technical vocabulary

- Difficult kanji above the expected reading level at the beginning of Japanese third grade receive full-word reading tooltips.
- Difficult kanji and advanced words in mission explanations, concept cards and mini-quizzes must use the same shared reading-help system and expose full-word pronunciation tooltips.
- Adding or changing an explanation, concept card, quiz question or quiz choice requires reviewing and updating difficult-word readings in the same change.
- Reading help in mission explanations, cards and mini-quizzes uses a light-blue visual treatment.
- Reading help inside the glossary uses a quieter gray treatment and must not interfere with existing code-component tooltips.
- `無限` receives the reading `むげん` in the mission title, concept cards, explanations and the duplicated mission heading inside the field panel.
- `値` uses `あたい`, `魔法` uses `まほう`, and `実行` uses `じっこう` wherever those words are annotated.
- `初めて` receives the reading `はじめて` when used in the first loop mission title or explanatory text.
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

## Field and editor presentation

- Immediately before the field-progress block, the field panel displays `MISSION XX - mission title`.
- `MISSION XX` uses the same yellow eyebrow style as the main mission card.
- The separator and mission title are white and use normal font weight.
- The `Ctrl / ⌘ + Enter で実行` reminder is supporting text, uses a clearly smaller `0.62rem` font, and remains on one line.
- The interface uses the same detailed blue scrollbar theme throughout the game, including the page, mission list, editor, syntax preview, reference panels and mini-quiz dialogs.
- Scrollbar track, thumb, hover color and size are centralized through shared CSS custom properties.
- In Chromium/WebKit, the detailed track, rounded thumb, inset border and hover styling must remain authoritative; standardized scrollbar properties must not override them with a native gray scrollbar.
- Browsers without WebKit scrollbar pseudo-elements use the centralized standard scrollbar colors as a fallback.
- Loop victory conditions appear inside the field-progress block before the progress track.

## Simplified pedagogical syntax preview

- The code area displays a simplified concept-based syntax preview by default whenever the editor is not focused.
- The syntax preview is presentational only and must never modify the learner's stored or executed source code.
- Focusing or activating the editable code area removes the concept colors and returns to the approved uniform editor text color.
- When the editor loses focus, the preview is rebuilt from the latest version of the code and the simplified coloring returns.
- When the learner clicks a specific character or word in the colored preview, the editable editor opens with its cursor placed at the corresponding source-code offset.
- Cursor placement from the preview must work with the standalone textarea editor and remain compatible with Ace.
- The syntax colors are centralized in easy-to-change CSS custom properties rather than repeated as literal colors throughout the implementation.
- Object names and declared constant or variable names use the object/variable color, initially blue.
- `hero` is treated as an object name.
- Names declared with `const`, `let` or `var` use the object/variable color both at declaration and later use.
- Method names following dot access and used as calls use the method color, initially purple.
- Primitive literal values use the literal color, initially red. This includes numbers, `true`, `false`, `null`, `undefined`, `NaN`, `Infinity` and string contents.
- String quote characters remain in the default syntax color while only the contents between the quotes use the literal color.
- Line and block comments use the comment color, initially a gray that remains reasonably close to the normal white text.
- Keywords, operators, punctuation, parentheses, braces, brackets, dots, semicolons, assignment and comparison symbols, logical operators and string quote characters retain the default white syntax color.
- For `const alwaysTrue = true;`, `const`, `=`, and `;` are white, `alwaysTrue` is blue and `true` is red.
- A compact Japanese legend below the code area explains the five categories: object/variable, method, value, comment and grammar/symbol.
- The preview and legend support the standalone textarea editor and remain compatible with Ace if it is available later.

## Action execution

- Every click on `実行する`, including Ctrl/Command+Enter, starts the adventure from field 1 of the current mission.
- The complete field, hero position, hero form, collected items, statistics and active speech UI are reset before field 1 and before every later field.
- User code is simulated once per field and rendered from the engine trace.
- Movement, transformation, speech and failure speech are rendered in exact source order.
- Each visible action must finish before the next action begins.
- Speech pauses execution until the learner closes the bubble.
- Speech bubbles are attached visually to the hero's position at the corresponding trace frame.

## Loop victory conditions

- Every mission whose intended solution teaches a loop has canonical loop victory metadata.
- The field panel displays the execution limit as `移動：最大 N 回` when the mission has a maximum movement count.
- The field panel displays each source-code call limit in Japanese, for example `コードに hero.move(...)：最大 1 回`.
- A source-code call limit counts how many times the learner writes a named `hero` method in source code, not how many times the loop executes it.
- Exceeding a source-code call limit fails the field and produces a Japanese result-console message showing the maximum, the current count and the instruction to place the command inside a loop.
- Loop syntax requirements are evaluated after comments are removed. A commented-out loop keyword does not satisfy a loop requirement.
- Commented-out method calls do not count toward source-code call limits.
- A learner cannot complete a loop mission by writing the repeated movement commands one by one while leaving a loop only in comments or as an unused dummy structure.
- The canonical source-code call limits are stored once in `loop-rules.js` and are used by both display and validation.

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
- Mission 14 uses a two-step reload preparation before the actual infinite-loop execution.
- On the first normal display of an incomplete mission 14, the editor is read-only and visually grayed out.
- On that first display, the normal yellow `▶ 実行する` button is replaced by a harmonious green preparation button.
- Clicking the preparation button does not start the learner code and does not complete the mission. It makes the hero explain in Japanese that the learner must reload with `Ctrl+F5` so the hero can enter the infinite loop.
- Preparation is recorded for the browser tab, but it becomes executable only after a real page reload. Navigating away and back on the same loaded page must not bypass the reload step.
- After the prepared page is reloaded, the editor becomes editable and the normal yellow `▶ 実行する` button returns.
- Clicking the normal run button after preparation persists mission completion and the next-mission unlock before the infinite demonstration starts.
- During the demonstration, closing the speech bubble starts the next loop iteration and shows the same speech again.
- Adventure controls remain unavailable during the demonstration. Reloading the page is the intended exit.
- After the post-execution reload, the persisted completion allows the learner to continue to mission 15 when missions 00 through 13 were completed normally.
- Completing mission 14 through temporary admin access does not bypass unfinished earlier missions after reload.
- Automated validation must not execute the truly infinite canonical solution directly; it validates the staged preparation and runtime mechanism instead.

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
- Merely opening an admin URL must not unlock missions before the admin button is activated.
- Admin mode adds a visible button that unlocks all missions for manual verification.
- The admin unlock is temporary to the current loaded page. Reloading the page, removing the admin URL or opening a normal page restores access derived from normal consecutive completion.
- Activating the admin unlock must not write `unlocked = missionCount` into normal persisted progress.
- Unlocking all missions does not automatically mark missions complete or grant persisted wizard level.
- Missions completed during admin verification may remain recorded as completed, but they must not unlock unfinished gaps in the normal mission sequence.
- Once the admin unlock button is activated, the same admin-unlocked state must be used both when rendering mission buttons and when checking whether a selected mission may open.
- Admin mode shows `答えを見る` for the selected mission even before three failed attempts. This final-answer control is independent of the temporary unlock-all button.
- Admin mode provides a quiz-review control on every concept-card quiz that selects the correct choices without submitting the form or validating the card automatically.
- Admin mode provides the validate-all control only at the end of the current mission's `新しい考え方` section; it validates those cards through normal concept memory and does not complete the mission.

## Speech and branch prompts

- `hero.say(...)` displays a comic-style bubble and pauses execution until closed.
- Locked powers and understandable runtime errors reuse the same trace-based blocking speech mechanism.
- Multiple speech calls appear at their true execution positions and never get pre-collected before movement.

## Validation and regression protection

- The focused validator must execute every finite reference solution on every field.
- It verifies mission count, consecutive identifiers, unique identifiers, required gems, scripted levels, transformation gates and ordered action traces.
- It verifies invalid direction, invalid parameter, invalid boolean, unknown method, invalid transformation and locked dragon behavior.
- It verifies the boolean mission checks both `true` and `false`, collects its gem and ends on the goal tile after two moves.
- It verifies the infinite-loop mission uses the two-step reload preparation, persists completion before the actual infinite execution and requires a second page reload to leave it.
- It verifies each canonical loop solution still passes all fields.
- It verifies commented-out loop keywords do not satisfy loop syntax requirements.
- It verifies manually unrolled commands exceeding a source-code call limit fail with a Japanese result message.
- It verifies multi-field ordering, field-progress source rules, admin URL behavior and progressive legend thresholds.
- It verifies saved curriculum migration preserves existing code and progress semantics.
- It verifies the first loop mission uses the exact title `初めてのループ`.
- It verifies every mission guide resolves its ordered concept-card IDs from the canonical reference base, all IDs are unique and every rendered card exposes its ID.
- It verifies that the set of IDs referenced by mission guides is exactly the set of records in the canonical concept-card database and that no card is referenced twice.
- It verifies that no legacy or ad-hoc HTML injector can append a second comment-concept card outside the canonical database and memory system.
- It verifies every canonical concept card has between one and three quiz questions and every question has three or four unique choices containing its correct answer.
- It verifies concept-card validation uses stable card IDs and a dedicated memory storage key rather than mission-number persistence.
- It verifies every unprepared concept card is visually hidden before the memory layer applies its face-down state.
- It verifies the learner cannot edit or execute through the colored preview, run button, keyboard shortcut, or mission-14 preparation before the current mission's cards are validated.
- It verifies admin quiz review can select the correct choices but does not submit or validate automatically.
- It verifies the admin-only validate-all control is rendered at the end of the guide, persists all current mission card IDs, and is absent from normal mode.
- It verifies difficult-word reading help is applied to mini-quiz prompts and choices through the shared reading dictionary, including `値`, `魔法` and `実行`.
- It verifies clicking the colored code preview maps the click position to the corresponding textarea or Ace cursor offset.
- It verifies simplified syntax coloring keeps keywords and punctuation in the default color while distinguishing objects/variables, methods, literal values and comments.
- It verifies string quote characters remain in the default color while string contents receive the literal color.
- It verifies the five syntax colors are centralized through CSS custom properties.
- It verifies the same detailed blue scrollbar theme is used throughout the game, that Chromium does not fall back to native gray scrollbars, and that the execution reminder uses its reduced supporting-text size.
- It verifies standalone mode does not request the absent Ace asset and that curriculum rendering does not recursively redispatch mission loading.
- It verifies the static execution worker loads the complete engine, the app does not create Blob workers, and admin navigation uses the canonical unlock predicate.
- It verifies normal access repairs stale or admin-inflated persisted unlock values before `app-v3.js` renders the mission list.
- It verifies an admin URL alone leaves later missions locked and that temporary admin access does not survive page initialization.
- It verifies every finite mission's learner partial solution differs from the final solution, contains comments and a `TODO`, and must remain incomplete on at least one field.
- It verifies the final answer is restricted to admin mode, is immediately available there without confirmation, and is not persisted as learner code.
- It verifies concept annotation does not install a self-mutating permanent subtree observer.
- It verifies required documentation exists and remains consistent with the implementation.
- ESLint must pass for changed JavaScript files.