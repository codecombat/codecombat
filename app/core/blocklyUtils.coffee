utils = require 'core/utils'
Blockly = require 'blockly'

# Code generators. (Blockly does not have generators for CoffeeScript, C++, Java, or HTML.)
BlocklyPython = require 'blockly/python'
BlocklyJavaScript = require 'blockly/javascript'
BlocklyLua = require 'blockly/lua'

# Plugins
require '@blockly/block-plus-minus'
{ ContinuousToolbox, ContinuousFlyout, ContinuousMetrics } = require '@blockly/continuous-toolbox'
{ CrossTabCopyPaste } = require '@blockly/plugin-cross-tab-copy-paste'
#{ ZoomToFitControl } = require '@blockly/zoom-to-fit'  # Not that useful unless we increase zoom level range

module.exports.createBlocklyToolbox = ({ propertyEntryGroups, generator, codeLanguage, level }) ->
  codeLanguage ||= 'javascript'
  commentStart = utils.commentStarts[codeLanguage] or '//'
  generator = module.exports.getBlocklyGenerator codeLanguage
  #generator.STATEMENT_PREFIX = "#{commentStart} highlightBlock(%1)\n"  # TODO: can we highlight running blocks another way?
  generator.INDENT = '    '

  superBasicLevels = ['dungeons-of-kithgard', 'gems-in-the-deep', 'shadow-guard']
  if me.level() > 5
    superBasicLevels = []  # Coming back to them later should allow basic misc blocks

  userBlockCategories = []

  propNames = new Set()
  for owner of propertyEntryGroups
    #console.log "Adding #{owner}, which has", propertyEntryGroups[owner]
    propNames.add prop.name for prop in propertyEntryGroups[owner].props
    continue if /programmaticon/i.test owner
    userBlocks = (createBlock({ owner, prop, generator, codeLanguage, level, superBasicLevels }) for prop in propertyEntryGroups[owner].props)
    userBlockCategories.push { kind: 'category', name: "#{owner}", colour: "190", contents: userBlocks }

  commentBlock =
    type: 'comment'
    message0: '%1'
    args0: [{ type: 'field_input',  name: 'Comment', text: 'Comment' }]
    previousStatement: null
    nextStatement: null
    colour: 180
    tooltip: 'Comment'
  Blockly.Blocks.comment = init: -> @jsonInit commentBlock
  generator.comment = (block) ->
    text = block.getFieldValue('Comment')
    return "#{commentStart} #{text}\n"

  miscBlocks = [
    createBlock
      owner: 'hero'
      generator: generator
      codeLanguage: codeLanguage
      level: level
      superBasicLevels: superBasicLevels
      prop:
        name: 'say'
        owner: 'this'
        args: [{ name: 'what' } ]
        type: 'function'
      include: -> (level.get('slug') not in superBasicLevels) and (level.get('slug') is 'wakka-maul' or not level.isLadder())
    createBlock {owner: 'hero', generator, codeLanguage, level, superBasicLevels, prop: {type: 'ref'}, include: -> propNames.has('if/else') }  # TODO: better targeting of when we introduce this (hero used as a value)
  ]
  userBlockCategories.push { kind: 'category', name: 'Misc', colour: '190', contents: miscBlocks }

  builtInBlockCategories = [
    {
      kind: 'category'
      name: 'Logic'
      colour: '290'
      contents: [
        { kind: 'block', type: 'controls_if', include: -> propNames.has('if/else') }
        { kind: 'block', type: 'controls_if', extraState: { hasElse: true }, include: -> propNames.has('else') }
        { kind: 'block', type: 'controls_if', extraState: { elseIfCount: 1, hasElse: 1 }, include: -> propNames.has('else') }  # TODO: better if/elseif/else differentiation?
        { kind: 'block', type: 'logic_compare', include: -> propNames.has('else') }  # TODO: better targeting of when we introduce this logic?
        { kind: 'block', type: 'logic_operation', include: -> propNames.has('else') }  # TODO: better targeting of when we introduce this logic?
        { kind: 'block', type: 'logic_negate', include: -> propNames.has('else') }  # TODO: better targeting of when we introduce this logic?
        { kind: 'block', type: 'math_arithmetic', include: -> propNames.has('else') }  # TODO: better targeting of when we introduce this logic?
      ]
    }
    {
      kind: 'category'
      name: 'Loops'
      colour: '290'
      contents: [
        {
          kind: 'block'
          type: 'controls_whileUntil'
          fields:
            MODE: 'WHILE'
          inputs:
            BOOL:
              block: { type: 'logic_boolean', fields: { BOOL: 'true' } }
          include: -> propNames.has('while-true loop')
        }
        #{ kind: 'block', type: 'controls_whileUntil', include: -> propNames.has('while-loop') }  # Redundant, since while-true can just delete true
        { kind: 'block', type: 'controls_repeat_ext', include: -> propNames.has('for-loop') }
        #{ kind: 'block', type: 'controls_for', include: -> propNames.has('for-loop') }  # Too wide  # TODO: introduce this later than the simpler repeat_ext loop above? Or just use this one, but defaults start at 0 and increment by 1?
        { kind: 'block', type: 'controls_forEach', include: -> propNames.has('for-in-loop') }
        { kind: 'block', type: 'controls_flow_statements', include: -> propNames.has('break') or propNames.has('continue') }
      ]
    }
    {
      kind: 'category'
      name: 'Literals'
      colour: '10'
      contents: [
        { kind: 'block', type: 'text', include: -> level.get('slug') not in superBasicLevels }
        { kind: 'block', type: 'math_number', include: -> level.get('slug') not in superBasicLevels }
        { kind: 'block', type: 'logic_boolean', include: -> propNames.has('if/else') }  # TODO: better targeting of when we introduce this logic?
        { kind: 'block', type: 'logic_null', include: -> propNames.has('else') }  # TODO: better targeting of when we introduce this logic?
        { kind: 'block', type: 'comment', include: -> level.get('slug') not in superBasicLevels }
      ]
    }
    {
      kind: 'category'
      name: 'Lists'
      colour: '10'
      contents: [
        { kind: 'block', type: 'lists_create_empty', include: -> propNames.has('arrays') }
        { kind: 'block', type: 'lists_create_with', include: -> propNames.has('arrays') }
        { kind: 'block', type: 'lists_length', include: -> propNames.has('arrays') }
        { kind: 'block', type: 'lists_isEmpty', include: -> propNames.has('arrays') }
        # Removing wide blocks for now until we have a way to handle them in continuous flyout
        #{ kind: 'block', type: 'lists_repeat', inputs: { NUM: { block: { type: 'math_number', fields: { NUM: '5' } } } }, include: -> propNames.has('arrays') }
        #{ kind: 'block', type: 'lists_indexOf', include: -> propNames.has('arrays') }
        #{ kind: 'block', type: 'lists_getIndex', include: -> propNames.has('arrays') }
        #{ kind: 'block', type: 'lists_setIndex', include: -> propNames.has('arrays') }
        # Some of the extra list operations
        { kind: 'block', type: 'lists_getSublist', include: -> propNames.has('arrays') and false }  # TODO: better targeting of when we introduce this logic?
        { kind: 'block', type: 'lists_split', include: -> propNames.has('arrays') and false }  # TODO: better targeting of when we introduce this logic?
        { kind: 'block', type: 'lists_sort', include: -> propNames.has('arrays') and false }  # TODO: better targeting of when we introduce this logic?
      ]
    }
    {
      kind: 'category'
      name: 'Variables'
      colour: '50'
      custom: 'VARIABLE'
      include: -> propNames.has('while-true loop') or propNames.has('while-loop')  # TODO: better targeting of when we introduce this logic? It's after while-true loops, but doesn't have own 'variables' entry in Programmaticon
    }
    {
      kind: 'category'
      name: 'User Functions'
      colour: '50'
      custom: 'PROCEDURE'
      include: -> propNames.has('functions')
    }
  ]

  blockCategories = userBlockCategories.concat builtInBlockCategories

  for category in blockCategories when category.contents
    category.contents = category.contents.filter (block) -> block.include is undefined or block.include()
    numBlocks = category.contents.length
    if numBlocks and propNames.size > 12
      for i in [0...numBlocks] by 1
        # Add a separator block in between each actual block, to shrink space between them from default 24px
        category.contents.splice 2 * i, 0, { kind: 'sep', gap: 12 }
  blockCategories = blockCategories.filter (category) -> (category.include is undefined or category.include()) and (category.contents is undefined or category.contents.length > 0)

  toolbox =
    kind: 'categoryToolbox'
    contents: blockCategories

  toolbox

createBlock = ({ owner, prop, generator, codeLanguage, include, level, superBasicLevels }) ->
  propName = prop.name.replace /"/g, '' if prop.name
  returnsValue = prop.returns? or prop.userShouldCaptureReturn? or (prop.type not in ['function', 'snippet'])
  name = "#{owner}_#{propName}"
  args = prop.args or []
  if (level?.get('slug') in superBasicLevels) and (propName in ['moveDown', 'moveLeft', 'moveRight', 'moveUp'])
    args = []

  generator[name] = (block) ->
    parts = []
    if propName? and (prop.owner in ['this', 'self', 'hero'])
      parts.push "hero.#{propName}"
    else if prop.type is 'function' or (prop.type is 'snippet' and args.length)
      parts.push propName.replace(/\(.*/, '')
    else if propName?
      parts.push propName
    else
      parts.push owner

    if prop.type is 'function' or (prop.type is 'snippet' and args.length)
      parts.push '('
      for idx, arg of args
        parts.push ', ' if idx > 0
        code = generator.valueToCode(block, arg.name, generator.ORDER_NONE)
        switch codeLanguage
          when 'javascript'
            parts.push code ? arg.default ? "undefined /* #{arg.name} */"
          when 'python'
            parts.push code ? arg.default ? 'None'
          when 'lua'
            parts.push code ? arg.default ? 'nil'
      parts.push ')'

    switch codeLanguage
      when 'javascript'
        parts.push ';\n' unless returnsValue
      when 'python', 'lua'
        parts.push '\n' unless returnsValue

    if returnsValue
      return [parts.join(''), generator.ORDER_NONE]
    else
      return parts.join('')

  setup =
    message0: "#{(propName or owner).replace(/\(.*/, '')} " + args.map((a, v) => "#{a.name}: %#{v+1}").join(" ")
    args0: args.map (a) ->
      type: "input_value"
      name: a.name
    colour: if returnsValue then 350 else 240
    tooltip: prop.description or ''
    docFormatter: prop.docFormatter

  if returnsValue
    setup.output = null
  else
    setup.previousStatement =  null
    setup.nextStatement = null

  #console.log 'Defining new block', name, setup
  Blockly.Blocks[name] = init: ->
    @jsonInit setup
    @docFormatter = setup.docFormatter
    @tooltipImg = setup.tooltipImg
  blockDefinition =
    kind: 'block'
    type: "#{name.replace(/\"/g, '\'')}"
  blockDefinition.include = include if include?
  for arg in args when arg.default?
    blockDefinition.inputs ?= {}
    type = { string: 'text', number: 'math_number', int: 'math_number', boolean: 'logic_boolean' }[arg.type] or 'text'  # TODO: more types
    field = { string: 'TEXT', number: 'NUM', int: 'NUM', boolean: 'BOOL' }[arg.type]
    continue unless type and field
    blockDefinition.inputs[arg.name] = { shadow: { type: type, fields: { "#{field}": arg.default } } }
  return blockDefinition

customTooltip = (div, element) ->
  container = document.createElement('div')
  if element.docFormatter
    tip = element.docFormatter.formatPopover()
    container.innerHTML = tip
  else 
    tip = Blockly.Tooltip.getTooltipOfObject(element)
    container.textContent = tip
  div.appendChild(container)

initializedTooltips = false
module.exports.initializeBlocklyTooltips = ->
  return if initializedTooltips
  initializedTooltips = true
  Blockly.Tooltip.setCustomTooltip(customTooltip)

registeredTheme = false
module.exports.registerBlocklyTheme = ->
  return if registeredTheme
  registeredTheme = true
  Blockly.Theme.defineTheme 'coco-dark',
    base: Blockly.Themes.Classic,
    componentStyles:
      #workspaceBackgroundColour: '#1e1e1e'
      toolboxBackgroundColour: 'blackBackground'
      toolboxForegroundColour: '#fff'
      flyoutBackgroundColour: '#252526'
      flyoutForegroundColour: '#ccc'
      flyoutOpacity: 1
      scrollbarColour: '#797979'
      insertionMarkerColour: '#fff'
      insertionMarkerOpacity: 0.3
      scrollbarOpacity: 0.4
      cursorColour: '#d0d0d0'
      blackBackground: '#333'

initializedLanguage = false
module.exports.initializeBlocklyLanguage = ->
  return if initializedLanguage
  return  # TODO: need to fix webpack loading first
  initializedLanguage = true
  language = me.get('preferredLanguage', true).toLowerCase()
  languageParts = language.split('-')
  while languageParts.length
    try
      localePath = "blockly/msg/#{languageParts.join('-')}"
      console.log 'trying to load', localePath
      # TODO: fix this up with proper webpackery, maybe like https://github.com/codecombat/codecombat/blob/master/app/locale/locale.coffee#L78-L102
      #blocklyLocale = require(localePath)  # doesn't work
      #blocklyLocale = require("blockly/msg/#{languageParts.join('-')}")  # works but throws a ton of errors
      Blockly.setLocale(blocklyLocale)
      break 
    catch e
      console.log e
      languageParts.pop()

module.exports.createBlocklyOptions = ({ toolbox }) ->
  module.exports.initializeBlocklyLanguage()
  toolbox: toolbox
  zoom:
    controls: true
    wheel: true
    startScale: 0.8
    maxScale: 1
    minScale: 0.6
    scaleSpeed: 1.2
  toolboxPosition: 'end'
  theme: 'coco-dark'
  plugins:
    toolbox: ContinuousToolbox
    flyoutsVerticalToolbox: ContinuousFlyout
    metricsManager: ContinuousMetrics
  sounds: me.get('volume') > 0

module.exports.getBlocklyGenerator = (codeLanguage) ->
  switch codeLanguage
    when 'python' then (require 'blockly/python').pythonGenerator
    when 'lua' then (require 'blockly/lua').luaGenerator
    when 'javascript' then (require 'blockly/javascript').javascriptGenerator
    else (require 'blockly/javascript').javascriptGenerator

initializedCopyPastePlugin = false
module.exports.initializeBlocklyPlugins = (blockly) ->
  unless initializedCopyPastePlugin
    initializedCopyPastePlugin = true
    # https://google.github.io/blockly-samples/plugins/cross-tab-copy-paste/README
    crossTabCopyPastePlugin = new CrossTabCopyPaste()
    crossTabCopyPastePlugin.init { contextMenu: true, shortcut: true }, (err) ->
      console.log 'CrossTabCopyPastePlugin paste error', err
    # optional: Remove the duplication command from Blockly's context menu
    #Blockly.ContextMenuRegistry.registry.unregister('blockDuplicate')
    # optional: Change the position of the items added to the context menu
    Blockly.ContextMenuRegistry.registry.getItem('blockCopyToStorage').weight = 0
    Blockly.ContextMenuRegistry.registry.getItem('blockPasteFromStorage').weight = 0

  #zoomToFit = new ZoomToFitControl blockly
  #zoomToFit.init()

module.exports.getBlocklySource = (blockly, codeLanguage) ->
  return unless blockly
  blocklyState = Blockly.serialization.workspaces.save blockly
  generator = module.exports.getBlocklyGenerator codeLanguage
  blocklySource = generator.workspaceToCode blockly
  blocklySource = rewriteBlocklySource blocklySource
  commentStart = utils.commentStarts[codeLanguage] or '//'
  #console.log "Blockly state", blocklyState
  #console.log "Blockly source", blocklySource
  combined = "#{commentStart}BLOCKLY| #{JSON.stringify(blocklyState)}\n\n#{blocklySource}"
  { blocklyState, blocklySource, combined }

rewriteBlocklySource = (source) ->
  # Fix any weird code generation coming from Blockly (currently none)
  source

module.exports.loadBlocklyState = (blocklyState, blockly, tries=0) ->
  return false if tries > 10
  return false unless blocklyState?.blocks
  try
    Blockly.serialization.workspaces.load blocklyState, blockly
    return true
  catch err
    # Example error: Invalid block definition for type: Esper.str_undefined
    # TODO: For some reason, this requires a page reload after filtering before Blockly code starts editing again. Not sure where problem is.
    blockType = err.message.match(/Invalid block definition for type: (.*)/)?[1]
    if blockType
      blocklyState = filterBlocklyState blocklyState, blockType
      return module.exports.loadBlocklyState blocklyState, blockly, tries + 1
    else
      console.error 'Error loading Blockly state', err
      return false
    
filterBlocklyState = (blocklyState, blockType) ->
  # Stubs out all blocks of the given type from the blockly state. Useful for not throwing away all code just because a block definition is missing.
  console.log 'Trying to remove', blockType, 'from blockly state', blocklyState, 'with', blocklyState.blocks?.blocks?.length, 'blocks'
  #console.log 'Trying to remove', blockType, 'from blockly state', _.cloneDeep(blocklyState), 'with', blocklyState.blocks?.blocks?.length, 'blocks'  # debugging
  # Recursively walk through all properties of the blockly state, and transform the ones with type: blockType to be comment blocks
  transformBlock = (parent, key, value) ->
    if value?.type is blockType
      #console.log 'Found block of type', blockType, 'at', key, 'in', _.cloneDeep parent
      #console.log 'Replacing with comment block'
      #console.log 'Parent before', _.cloneDeep parent
      parent[key] = { type: 'text', x: value.x, y: value.y, id: value.id, fields: { TEXT: "Missing block #{blockType}" } }
      #console.log 'Parent after', _.cloneDeep parent
    else if _.isObject(value)
      _.each value, (v, k) -> transformBlock value, k, v
  transformBlock null, 'blocks', blocklyState.blocks.blocks
  blocklyState
