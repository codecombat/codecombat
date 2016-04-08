c = require 'schemas/schemas'

module.exports =
  'tome:cast-spell': c.object {title: 'Cast Spell', description: 'Published when a spell is cast', required: []},
    spell: {type: 'object'}
    thang: {type: 'object'}
    preload: {type: 'boolean'}
    realTime: {type: 'boolean'}

  'tome:cast-spells': c.object {title: 'Cast Spells', description: 'Published when spells are cast', required: ['spells', 'preload', 'realTime', 'submissionCount', 'flagHistory', 'difficulty', 'god']},
    spells: {type: 'object'}
    preload: {type: 'boolean'}
    realTime: {type: 'boolean'}
    submissionCount: {type: 'integer'}
    fixedSeed: {type: ['integer', 'undefined']}
    flagHistory: {type: 'array'}
    difficulty: {type: 'integer'}
    god: {type: 'object'}

  'tome:manual-cast': c.object {title: 'Manually Cast Spells', description: 'Published when you wish to manually recast all spells', required: []},
    realTime: {type: 'boolean'}

  'tome:manual-cast-denied': c.object {title: 'Manual Cast Denied', description: 'Published when player attempts to submit for real-time playback, but must wait after a replayable level failure.', required: ['timeUntilResubmit']},
    timeUntilResubmit: {type: 'number'}

  'tome:spell-created': c.object {title: 'Spell Created', description: 'Published after a new spell has been created', required: ['spell']},
    spell: {type: 'object'}

  'tome:spell-has-changed-significantly-calculation': c.object {title: 'Has Changed Significantly Calculation', description: 'Let anyone know that the spell has changed significantly.', required: ['hasChangedSignificantly']},
    hasChangedSignificantly: {type: 'boolean'}

  'tome:spell-debug-property-hovered': c.object {title: 'Spell Debug Property Hovered', description: 'Published when you hover over a spell property', required: []},
    property: {type: 'string'}
    owner: {type: 'string'}

  'tome:spell-debug-value-request': c.object {title: 'Spell Debug Value Request', description: 'Published when the SpellDebugView wants to retrieve a debug value.', required: ['thangID', 'spellID', 'variableChain', 'frame']},
    thangID: {type: 'string'}
    spellID: {type: 'string'}
    variableChain: c.array {}, {type: 'string'}
    frame: {type: 'integer', minimum: 0}

  'tome:toggle-spell-list': c.object {title: 'Toggle Spell List', description: 'Published when you toggle the dropdown for a thang\'s spells'}

  'tome:reload-code': c.object {title: 'Reload Code', description: 'Published when you reset a spell to its original source', required: []},
    spell: {type: 'object'}

  'tome:palette-cleared': c.object {title: 'Palette Cleared', description: 'Published when the spell palette is about to be cleared and recreated.'},
    thangID: {type: 'string'}

  'tome:palette-updated': c.object {title: 'Palette Updated', description: 'Published when the spell palette has just been updated.'},
    thangID: {type: 'string'}
    entryGroups: {type: 'string'}

  'tome:palette-hovered': c.object {title: 'Palette Hovered', description: 'Published when you hover over a Thang in the spell palette', required: ['thang', 'prop', 'entry']},
    thang: {type: 'object'}
    prop: {type: 'string'}
    entry: {type: 'object'}

  'tome:palette-pin-toggled': c.object {title: 'Palette Pin Toggled', description: 'Published when you pin or unpin the spell palette', required: ['entry', 'pinned']},
    entry: {type: 'object'}
    pinned: {type: 'boolean'}

  'tome:palette-clicked': c.object {title: 'Palette Clicked', description: 'Published when you click on the spell palette', required: ['thang', 'prop', 'entry']},
    thang: {type: 'object'}
    prop: {type: 'string'}
    entry: {type: 'object'}

  'tome:spell-statement-index-updated': c.object {title: 'Spell Statement Index Updated', description: 'Published when the spell index is updated', required: ['statementIndex', 'ace']},
    statementIndex: {type: 'integer'}
    ace: {type: 'object'}

  'tome:spell-beautify': c.object {title: 'Beautify', description: 'Published when you click the \'beautify\' button', required: []},
    spell: {type: 'object'}

  'tome:spell-step-forward': c.object {title: 'Step Forward', description: 'Published when you step forward in time'}

  'tome:spell-step-backward': c.object {title: 'Step Backward', description: 'Published when you step backward in time'}

  'tome:spell-loaded': c.object {title: 'Spell Loaded', description: 'Published when a spell is loaded', required: ['spell']},
    spell: {type: 'object'}

  'tome:spell-changed': c.object {title: 'Spell Changed', description: 'Published when a spell is changed', required: ['spell']},
    spell: {type: 'object'}

  'tome:editing-began': c.object {title: 'Editing Began', description: 'Published when you have begun changing code'}

  'tome:editing-ended': c.object {title: 'Editing Ended', description: 'Published when you have stopped changing code'}

  'tome:problems-updated': c.object {title: 'Problems Updated', description: 'Published when problems have been updated', required: ['spell', 'problems', 'isCast']},
    spell: {type: 'object'}
    problems: {type: 'array'}
    isCast: {type: 'boolean'}

  'tome:spell-shown': c.object {title: 'Spell Shown', description: 'Published when we show a spell', required: ['thang', 'spell']},
    thang: {type: 'object'}
    spell: {type: 'object'}

  'tome:change-language': c.object {title: 'Tome Change Language', description: 'Published when the Tome should update its programming language', required: ['language']},
    language: {type: 'string'}
    reload: {type: 'boolean', description: 'Whether player code should reload to the default when the language changes.'}

  'tome:spell-changed-language': c.object {title: 'Spell Changed Language', description: 'Published when an individual spell has updated its code language', required: ['spell']},
    spell: {type: 'object'}
    language: {type: 'string'}

  'tome:comment-my-code': c.object {title: 'Comment My Code', description: 'Published when we comment out a chunk of your code'}

  'tome:change-config': c.object {title: 'Change Config', description: 'Published when you change your tome settings'}

  'tome:update-snippets': c.object {title: 'Update Snippets', description: 'Published when we need to add Zatanna snippets', required: ['propGroups', 'allDocs']},
    propGroups: {type: 'object'}
    allDocs: {type: 'object'}
    language: {type: 'string'}

  'tome:insert-snippet': c.object {title: 'Insert Snippet', description: 'Published when we need to insert a Zatanna snippet', required: ['doc', 'language', 'formatted']},
    doc: {type: 'object'}
    language: {type: 'string'}
    formatted: {type: 'object'}

  'tome:focus-editor': c.object {title: 'Focus Editor', description: 'Published whenever we want to give focus back to the editor'}

  'tome:toggle-maximize': c.object {title: 'Toggle Maximize', description: 'Published when we want to make the Tome take up most of the screen'}

  'tome:maximize-toggled': c.object {title: 'Maximize Toggled', description: 'Published when the Tome has changed maximize/minimize state.'}

  'tome:select-primary-sprite': c.object {title: 'Select Primary Sprite', description: 'Published to get the most important sprite\'s code selected.'}

  'tome:required-code-fragment-deleted': c.object {title: 'Required Code Fragment Deleted', description: 'Published when a required code fragment is deleted from the sample code.', required: ['codeFragment']},
    codeFragment: {type: 'string'}

  'tome:suspect-code-fragment-added': c.object {title: 'Suspect Code Fragment Added', description: 'Published when a suspect code fragment is added to the sample code.', required: ['codeFragment']},
    codeFragment: {type: 'string'}
    codeLanguage: {type: 'string'}

  'tome:suspect-code-fragment-deleted': c.object {title: 'Suspect Code Fragment Deleted', description: 'Published when a suspect code fragment is deleted from the sample code.', required: ['codeFragment']},
    codeFragment: {type: 'string'}
    codeLanguage: {type: 'string'}

  'tome:winnability-updated': c.object {title: 'Winnability Updated', description: 'When we think we can now win (or can no longer win), we may want to emphasize the submit button versus the run button (or vice versa), so this fires when we get new goal states (even preloaded goal states) suggesting success or failure change.', required: ['winnable']},
    winnable: {type: 'boolean'}
    level: {type: 'object'}

  # Problem Alert
  'tome:show-problem-alert': c.object {title: 'Show Problem Alert', description: 'A problem alert needs to be shown.', required: ['problem']},
    problem: {type: 'object'}
    lineOffsetPx: {type: ['number', 'undefined']}
  'tome:hide-problem-alert': c.object {title: 'Hide Problem Alert'}
  'tome:jiggle-problem-alert': c.object {title: 'Jiggle Problem Alert'}
