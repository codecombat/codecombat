# Learning Reinforcement Plan

This branch extends `feature/japanese-js-quest-20-missions` with additional learning reinforcement features.

## Simplified pedagogical syntax coloring

- Show a simplified concept-based syntax preview when the JavaScript editor is not focused.
- Return to the normal uniform editor color while the learner edits.
- Rebuild the preview from the latest text when the editor loses focus.
- Keep the colors configurable through centralized CSS variables.
- Initial categories:
  - object and declared variable/constant names: blue;
  - methods: purple;
  - primitive literal values and string contents: red;
  - comments: gray;
  - keywords, operators, punctuation and string quotes: white.
- Display a compact Japanese legend below the editor.

## Concept-card validation quizzes

- New-concept cards start face down.
- Only one unvalidated card may be previewed at a time.
- A previewed card exposes a quiz action.
- Each card has one to three simple multiple-choice questions derived from the card content.
- Incorrect submissions reveal no correct answer and invite the learner to retry.
- A card is validated only after all of its questions are answered correctly in one submission.
- Validated cards retain their normal current appearance and display a success icon.
- The validated card IDs are persisted separately from mission progress.
- Mission execution remains unavailable until all concept cards for the selected mission are validated.

## Remaining feature

The third requested feature will be added after its detailed product specification is provided.
