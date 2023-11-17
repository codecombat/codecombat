// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS103: Rewrite code to no longer use __guard__, or convert again using --optional-chaining
 * DS104: Avoid inline assignments
 * DS204: Change includes calls to have a more natural evaluation order
 * DS205: Consider reworking code to avoid use of IIFEs
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
const utils = require('core/utils');
const Blockly = require('blockly');

// Code generators. (Blockly does not have generators for CoffeeScript, C++, Java, or HTML.)
const BlocklyPython = require('blockly/python');
const BlocklyJavaScript = require('blockly/javascript');
const BlocklyLua = require('blockly/lua');

// Plugins
require('@blockly/block-plus-minus');
const { ContinuousToolbox, ContinuousFlyout, ContinuousMetrics } = require('@blockly/continuous-toolbox');
const { CrossTabCopyPaste } = require('@blockly/plugin-cross-tab-copy-paste');
//{ ZoomToFitControl } = require '@blockly/zoom-to-fit'  # Not that useful unless we increase zoom level range

module.exports.createBlocklyToolbox = function({ propertyEntryGroups, generator, codeLanguage, level }) {
  let owner;
  let prop;
  if (!codeLanguage) { codeLanguage = 'javascript'; }
  const commentStart = utils.commentStarts[codeLanguage] || '//';
  generator = module.exports.getBlocklyGenerator(codeLanguage);
  //generator.STATEMENT_PREFIX = "#{commentStart} highlightBlock(%1)\n"  # TODO: can we highlight running blocks another way?
  generator.INDENT = '    ';

  let superBasicLevels = ['dungeons-of-kithgard', 'gems-in-the-deep', 'shadow-guard'];
  if (me.level() > 5) {
    superBasicLevels = [];  // Coming back to them later should allow basic misc blocks
  }

  const userBlockCategories = [];

  const propNames = new Set();
  for (owner in propertyEntryGroups) {
    //console.log "Adding #{owner}, which has", propertyEntryGroups[owner]
    for (prop of Array.from(propertyEntryGroups[owner].props)) { propNames.add(prop.name); }
    if (/programmaticon/i.test(owner)) { continue; }
    var userBlocks = ((() => {
      const result = [];
      for (prop of Array.from(propertyEntryGroups[owner].props)) {         result.push(createBlock({ owner, prop, generator, codeLanguage, level, superBasicLevels }));
      }
      return result;
    })());
    userBlockCategories.push({ kind: 'category', name: `${owner}`, colour: "190", contents: userBlocks });
  }

  const commentBlock = {
    type: 'comment',
    message0: '%1',
    args0: [{ type: 'field_input',  name: 'Comment', text: 'Comment' }],
    previousStatement: null,
    nextStatement: null,
    colour: 180,
    tooltip: 'Comment'
  };
  Blockly.Blocks.comment = {init() { return this.jsonInit(commentBlock); }};
  generator.comment = function(block) {
    const text = block.getFieldValue('Comment');
    return `${commentStart} ${text}\n`;
  };

  const codeCommentBlock = {
    type: 'code_comment',
    message0: 'Commented %1',
    args0: [{ type: 'input_statement',  name: 'CodeComment' }],
    inputsInline: true,
    previousStatement: null,
    nextStatement: null,
    colour: 180,
    tooltip: 'Commented-out code will have no effect'
  };
  Blockly.Blocks.code_comment = {init() { return this.jsonInit(codeCommentBlock); }};
  generator.code_comment = function(block) {
    const text = generator.statementToCode(block, 'CodeComment');
    if (!text) { return ''; }
    return (Array.from(text.trim().split('\n')).map((line) => `${commentStart}${line.replace(/^    /g, '')}`)).join('\n') + '\n';
  };

  const miscBlocks = [
    createBlock({
      owner: 'hero',
      generator,
      codeLanguage,
      level,
      superBasicLevels,
      prop: {
        name: 'say',
        owner: 'this',
        args: [{ name: 'what' } ],
        type: 'function'
      },
      include() { let needle;
      return ((needle = level.get('slug'), !Array.from(superBasicLevels).includes(needle))) && ((level.get('slug') === 'wakka-maul') || !level.isLadder()); }
    }),
    createBlock({owner: 'hero', generator, codeLanguage, level, superBasicLevels, prop: {type: 'ref'}, include() { return propNames.has('if/else'); } })  // TODO: better targeting of when we introduce this (hero used as a value)
  ];
  userBlockCategories.push({ kind: 'category', name: 'Misc', colour: '190', contents: miscBlocks });

  const builtInBlockCategories = [
    {
      kind: 'category',
      name: 'Logic',
      colour: '290',
      contents: [
        { kind: 'block', type: 'controls_if', include() { return propNames.has('if/else'); } },
        { kind: 'block', type: 'controls_if', extraState: { hasElse: true }, include() { return propNames.has('else'); } },
        { kind: 'block', type: 'controls_if', extraState: { elseIfCount: 1, hasElse: 1 }, include() { return propNames.has('else'); } },  // TODO: better if/elseif/else differentiation?
        { kind: 'block', type: 'logic_compare', include() { return propNames.has('else'); } },  // TODO: better targeting of when we introduce this logic?
        { kind: 'block', type: 'logic_operation', include() { return propNames.has('else'); } },  // TODO: better targeting of when we introduce this logic?
        { kind: 'block', type: 'logic_negate', include() { return propNames.has('else'); } },  // TODO: better targeting of when we introduce this logic?
        { kind: 'block', type: 'math_arithmetic', include() { return propNames.has('else'); } }  // TODO: better targeting of when we introduce this logic?
      ]
    },
    {
      kind: 'category',
      name: 'Loops',
      colour: '290',
      contents: [
        {
          kind: 'block',
          type: 'controls_whileUntil',
          fields: {
            MODE: 'WHILE'
          },
          inputs: {
            BOOL: {
              block: { type: 'logic_boolean', fields: { BOOL: 'true' } }
            }
          },
          include() { return propNames.has('while-true loop'); }
        },
        //{ kind: 'block', type: 'controls_whileUntil', include: -> propNames.has('while-loop') }  # Redundant, since while-true can just delete true
        { kind: 'block', type: 'controls_repeat_ext', include() { return propNames.has('for-loop'); } },
        //{ kind: 'block', type: 'controls_for', include: -> propNames.has('for-loop') }  # Too wide  # TODO: introduce this later than the simpler repeat_ext loop above? Or just use this one, but defaults start at 0 and increment by 1?
        { kind: 'block', type: 'controls_forEach', include() { return propNames.has('for-in-loop'); } },
        { kind: 'block', type: 'controls_flow_statements', include() { return propNames.has('break') || propNames.has('continue'); } }
      ]
    },
    {
      kind: 'category',
      name: 'Literals',
      colour: '10',
      contents: [
        { kind: 'block', type: 'text', include() { let needle;
        return (needle = level.get('slug'), !Array.from(superBasicLevels).includes(needle)); } },
        { kind: 'block', type: 'math_number', include() { let needle;
        return (needle = level.get('slug'), !Array.from(superBasicLevels).includes(needle)); } },
        { kind: 'block', type: 'logic_boolean', include() { return propNames.has('if/else'); } },  // TODO: better targeting of when we introduce this logic?
        { kind: 'block', type: 'logic_null', include() { return propNames.has('else'); } },  // TODO: better targeting of when we introduce this logic?
        { kind: 'block', type: 'comment', include() { let needle;
        return (needle = level.get('slug'), !Array.from(superBasicLevels).includes(needle)); } },
        { kind: 'block', type: 'code_comment', include() { return propNames.has('if/else'); } }  // TODO: introduce this around when we start having commented-out code in sample code
      ]
    },
    {
      kind: 'category',
      name: 'Lists',
      colour: '10',
      contents: [
        { kind: 'block', type: 'lists_create_empty', include() { return propNames.has('arrays'); } },
        { kind: 'block', type: 'lists_create_with', include() { return propNames.has('arrays'); } },
        { kind: 'block', type: 'lists_length', include() { return propNames.has('arrays'); } },
        { kind: 'block', type: 'lists_isEmpty', include() { return propNames.has('arrays'); } },
        // Removing wide blocks for now until we have a way to handle them in continuous flyout
        //{ kind: 'block', type: 'lists_repeat', inputs: { NUM: { block: { type: 'math_number', fields: { NUM: '5' } } } }, include: -> propNames.has('arrays') }
        //{ kind: 'block', type: 'lists_indexOf', include: -> propNames.has('arrays') }
        //{ kind: 'block', type: 'lists_getIndex', include: -> propNames.has('arrays') }
        //{ kind: 'block', type: 'lists_setIndex', include: -> propNames.has('arrays') }
        // Some of the extra list operations
        { kind: 'block', type: 'lists_getSublist', include() { return propNames.has('arrays') && false; } },  // TODO: better targeting of when we introduce this logic?
        { kind: 'block', type: 'lists_split', include() { return propNames.has('arrays') && false; } },  // TODO: better targeting of when we introduce this logic?
        { kind: 'block', type: 'lists_sort', include() { return propNames.has('arrays') && false; } }  // TODO: better targeting of when we introduce this logic?
      ]
    },
    {
      kind: 'category',
      name: 'Variables',
      colour: '50',
      custom: 'VARIABLE',
      include() { return propNames.has('while-true loop') || propNames.has('while-loop'); }  // TODO: better targeting of when we introduce this logic? It's after while-true loops, but doesn't have own 'variables' entry in Programmaticon
    },
    {
      kind: 'category',
      name: 'User Functions',
      colour: '50',
      custom: 'PROCEDURE',
      include() { return propNames.has('functions'); }
    }
  ];

  let blockCategories = userBlockCategories.concat(builtInBlockCategories);

  for (var category of Array.from(blockCategories)) {
    if (category.contents) {
      category.contents = category.contents.filter(block => (block.include === undefined) || block.include());
      var numBlocks = category.contents.length;
      if (numBlocks && (propNames.size > 12)) {
        for (var i = 0, end = numBlocks; i < end; i++) {
          // Add a separator block in between each actual block, to shrink space between them from default 24px
          category.contents.splice(2 * i, 0, { kind: 'sep', gap: 12 });
        }
      }
    }
  }
  blockCategories = blockCategories.filter(category => ((category.include === undefined) || category.include()) && ((category.contents === undefined) || (category.contents.length > 0)));

  const toolbox = {
    kind: 'categoryToolbox',
    contents: blockCategories
  };

  return toolbox;
};

var createBlock = function({ owner, prop, generator, codeLanguage, include, level, superBasicLevels }) {
  let needle, propName;
  if (prop.name) { propName = prop.name.replace(/"/g, ''); }
  const returnsValue = (prop.returns != null) || (prop.userShouldCaptureReturn != null) || (!['function', 'snippet'].includes(prop.type));
  const name = `${owner}_${propName}`;
  let args = prop.args || [];
  if (((needle = level != null ? level.get('slug') : undefined, Array.from(superBasicLevels).includes(needle))) && (['moveDown', 'moveLeft', 'moveRight', 'moveUp'].includes(propName))) {
    args = [];
  }

  generator[name] = function(block) {
    const parts = [];
    if ((propName != null) && (['this', 'self', 'hero'].includes(prop.owner))) {
      parts.push(`hero.${propName}`);
    } else if ((prop.type === 'function') || ((prop.type === 'snippet') && args.length)) {
      parts.push(propName.replace(/\(.*/, ''));
    } else if (propName != null) {
      parts.push(propName);
    } else {
      parts.push(owner);
    }

    if ((prop.type === 'function') || ((prop.type === 'snippet') && args.length)) {
      parts.push('(');
      for (var idx in args) {
        var left, left1, left2;
        var arg = args[idx];
        if (idx > 0) { parts.push(', '); }
        var code = generator.valueToCode(block, arg.name, generator.ORDER_NONE);
        switch (codeLanguage) {
          case 'javascript':
            parts.push((left = code != null ? code : arg.default) != null ? left : `undefined /* ${arg.name} */`);
            break;
          case 'python':
            parts.push((left1 = code != null ? code : arg.default) != null ? left1 : 'None');
            break;
          case 'lua':
            parts.push((left2 = code != null ? code : arg.default) != null ? left2 : 'nil');
            break;
        }
      }
      parts.push(')');
    }

    switch (codeLanguage) {
      case 'javascript':
        if (!returnsValue) { parts.push(';\n'); }
        break;
      case 'python': case 'lua':
        if (!returnsValue) { parts.push('\n'); }
        break;
    }

    if (returnsValue) {
      return [parts.join(''), generator.ORDER_NONE];
    } else {
      return parts.join('');
    }
  };

  const setup = {
    message0: `${(propName || owner).replace(/\(.*/, '')} ` + args.map((a, v) => `${a.name}: %${v+1}`).join(" "),
    args0: args.map(a => ({
      type: "input_value",
      name: a.name
    })),
    colour: returnsValue ? 350 : 240,
    tooltip: prop.description || '',
    docFormatter: prop.docFormatter
  };

  if (returnsValue) {
    setup.output = null;
  } else {
    setup.previousStatement =  null;
    setup.nextStatement = null;
  }

  //console.log 'Defining new block', name, setup
  Blockly.Blocks[name] = { init() {
    this.jsonInit(setup);
    this.docFormatter = setup.docFormatter;
    return this.tooltipImg = setup.tooltipImg;
  }
};
  const blockDefinition = {
    kind: 'block',
    type: `${name.replace(/\"/g, '\'')}`
  };
  if (include != null) { blockDefinition.include = include; }
  for (var arg of Array.from(args)) {
    if (arg.default != null) {
      if (blockDefinition.inputs == null) { blockDefinition.inputs = {}; }
      var type = { string: 'text', number: 'math_number', int: 'math_number', boolean: 'logic_boolean' }[arg.type] || 'text';  // TODO: more types
      var field = { string: 'TEXT', number: 'NUM', int: 'NUM', boolean: 'BOOL' }[arg.type];
      if (!type || !field) { continue; }
      blockDefinition.inputs[arg.name] = { shadow: { type, fields: { [field]: arg.default } } };
    }
  }
  return blockDefinition;
};

const customTooltip = function(div, element) {
  let tip;
  const container = document.createElement('div');
  if (element.docFormatter) {
    tip = element.docFormatter.formatPopover();
    container.innerHTML = tip;
  } else {
    tip = Blockly.Tooltip.getTooltipOfObject(element);
    container.textContent = tip;
  }
  return div.appendChild(container);
};

let initializedTooltips = false;
module.exports.initializeBlocklyTooltips = function() {
  if (initializedTooltips) { return; }
  initializedTooltips = true;
  return Blockly.Tooltip.setCustomTooltip(customTooltip);
};

let registeredTheme = false;
module.exports.registerBlocklyTheme = function() {
  if (registeredTheme) { return; }
  registeredTheme = true;
  return Blockly.Theme.defineTheme('coco-dark', {
    base: Blockly.Themes.Classic,
    componentStyles: {
      //workspaceBackgroundColour: '#1e1e1e'
      toolboxBackgroundColour: 'blackBackground',
      toolboxForegroundColour: '#fff',
      flyoutBackgroundColour: '#252526',
      flyoutForegroundColour: '#ccc',
      flyoutOpacity: 1,
      scrollbarColour: '#797979',
      insertionMarkerColour: '#fff',
      insertionMarkerOpacity: 0.3,
      scrollbarOpacity: 0.4,
      cursorColour: '#d0d0d0',
      blackBackground: '#333'
    }
  }
  );
};

let initializedLanguage = false;
module.exports.initializeBlocklyLanguage = function() {
  if (initializedLanguage) { return; }
  return;  // TODO: need to fix webpack loading first
  initializedLanguage = true;
  const language = me.get('preferredLanguage', true).toLowerCase();
  const languageParts = language.split('-');
  return (() => {
    const result = [];
    while (languageParts.length) {
      try {
        var localePath = `blockly/msg/${languageParts.join('-')}`;
        console.log('trying to load', localePath);
        // TODO: fix this up with proper webpackery, maybe like https://github.com/codecombat/codecombat/blob/master/app/locale/locale.coffee#L78-L102
        //blocklyLocale = require(localePath)  # doesn't work
        //blocklyLocale = require("blockly/msg/#{languageParts.join('-')}")  # works but throws a ton of errors
        Blockly.setLocale(blocklyLocale);
        break;
      } catch (e) {
        console.log(e);
        result.push(languageParts.pop());
      }
    }
    return result;
  })();
};

module.exports.createBlocklyOptions = function({ toolbox }) {
  module.exports.initializeBlocklyLanguage();
  return {
    toolbox,
    zoom: {
      controls: true,
      wheel: true,
      startScale: 0.8,
      maxScale: 1,
      minScale: 0.6,
      scaleSpeed: 1.2
    },
    toolboxPosition: 'end',
    theme: 'coco-dark',
    plugins: {
      toolbox: ContinuousToolbox,
      flyoutsVerticalToolbox: ContinuousFlyout,
      metricsManager: ContinuousMetrics
    },
    sounds: me.get('volume') > 0
  };
};

module.exports.getBlocklyGenerator = function(codeLanguage) {
  switch (codeLanguage) {
    case 'python': return (require('blockly/python')).pythonGenerator;
    case 'lua': return (require('blockly/lua')).luaGenerator;
    case 'javascript': return (require('blockly/javascript')).javascriptGenerator;
    default: return (require('blockly/javascript')).javascriptGenerator;
  }
};

let initializedCopyPastePlugin = false;
module.exports.initializeBlocklyPlugins = function(blockly) {
  if (!initializedCopyPastePlugin) {
    initializedCopyPastePlugin = true;
    // https://google.github.io/blockly-samples/plugins/cross-tab-copy-paste/README
    const crossTabCopyPastePlugin = new CrossTabCopyPaste();
    crossTabCopyPastePlugin.init({ contextMenu: true, shortcut: true }, err => console.log('CrossTabCopyPastePlugin paste error', err));
    // optional: Remove the duplication command from Blockly's context menu
    //Blockly.ContextMenuRegistry.registry.unregister('blockDuplicate')
    // optional: Change the position of the items added to the context menu
    Blockly.ContextMenuRegistry.registry.getItem('blockCopyToStorage').weight = 0;
    return Blockly.ContextMenuRegistry.registry.getItem('blockPasteFromStorage').weight = 0;
  }
};

  //zoomToFit = new ZoomToFitControl blockly
  //zoomToFit.init()

module.exports.getBlocklySource = function(blockly, codeLanguage) {
  if (!blockly) { return; }
  const blocklyState = Blockly.serialization.workspaces.save(blockly);
  const generator = module.exports.getBlocklyGenerator(codeLanguage);
  let blocklySource = generator.workspaceToCode(blockly);
  blocklySource = rewriteBlocklySource(blocklySource);
  const commentStart = utils.commentStarts[codeLanguage] || '//';
  //console.log "Blockly state", blocklyState
  //console.log "Blockly source", blocklySource
  const combined = `${commentStart}BLOCKLY| ${JSON.stringify(blocklyState)}\n\n${blocklySource}`;
  return { blocklyState, blocklySource, combined };
};

var rewriteBlocklySource = source => // Fix any weird code generation coming from Blockly (currently none)
source;

module.exports.loadBlocklyState = function(blocklyState, blockly, tries) {
  if (tries == null) { tries = 0; }
  if (tries > 10) { return false; }
  if (!(blocklyState != null ? blocklyState.blocks : undefined)) { return false; }
  try {
    Blockly.serialization.workspaces.load(blocklyState, blockly);
    return true;
  } catch (err) {
    // Example error: Invalid block definition for type: Esper.str_undefined
    // TODO: For some reason, this requires a page reload after filtering before Blockly code starts editing again. Not sure where problem is.
    const blockType = __guard__(err.message.match(/Invalid block definition for type: (.*)/), x => x[1]);
    if (blockType) {
      blocklyState = filterBlocklyState(blocklyState, blockType);
      return module.exports.loadBlocklyState(blocklyState, blockly, tries + 1);
    } else {
      console.error('Error loading Blockly state', err);
      return false;
    }
  }
};

var filterBlocklyState = function(blocklyState, blockType) {
  // Stubs out all blocks of the given type from the blockly state. Useful for not throwing away all code just because a block definition is missing.
  console.log('Trying to remove', blockType, 'from blockly state', blocklyState, 'with', __guard__(blocklyState.blocks != null ? blocklyState.blocks.blocks : undefined, x => x.length), 'blocks');
  //console.log 'Trying to remove', blockType, 'from blockly state', _.cloneDeep(blocklyState), 'with', blocklyState.blocks?.blocks?.length, 'blocks'  # debugging
  // Recursively walk through all properties of the blockly state, and transform the ones with type: blockType to be comment blocks
  var transformBlock = function(parent, key, value) {
    if ((value != null ? value.type : undefined) === blockType) {
      //console.log 'Found block of type', blockType, 'at', key, 'in', _.cloneDeep parent
      //console.log 'Replacing with comment block'
      //console.log 'Parent before', _.cloneDeep parent
      return parent[key] = { type: 'text', x: value.x, y: value.y, id: value.id, fields: { TEXT: `Missing block ${blockType}` } };
      //console.log 'Parent after', _.cloneDeep parent
    } else if (_.isObject(value)) {
      return _.each(value, (v, k) => transformBlock(value, k, v));
    }
  };
  transformBlock(null, 'blocks', blocklyState.blocks.blocks);
  return blocklyState;
};

function __guard__(value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined;
}