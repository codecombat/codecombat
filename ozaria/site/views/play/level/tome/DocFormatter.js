/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS103: Rewrite code to no longer use __guard__, or convert again using --optional-chaining
 * DS205: Consider reworking code to avoid use of IIFEs
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let DocFormatter;
const popoverTemplate = require('ozaria/site/templates/play/level/tome/spell_palette_entry_popover');
window.Vector = require('lib/world/vector');  // So we can document it
const utils = require('core/utils');

const safeJSONStringify = function(input, maxDepth) {
  let output;
  var recursion = function(input, path, depth) {
    const output = {};
    let pPath = undefined;
    let refIdx = undefined;
    path = path || '';
    depth = depth || 0;
    depth++;
    if (maxDepth && (depth > maxDepth)) { return '{depth over ' + maxDepth + '}'; }
    for (var p in input) {
      pPath = ((path ? (path + '.') : '')) + p;
      if (typeof input[p] === 'function') {
        output[p] = '{function}';
      } else if (typeof input[p] === 'object') {
        refIdx = refs.indexOf(input[p]);
        if (-1 !== refIdx) {
          output[p] = '{reference to ' + refsPaths[refIdx] + '}';
        } else {
          refs.push(input[p]);
          refsPaths.push(pPath);
          output[p] = recursion(input[p], pPath, depth);
        }
      } else {
        output[p] = input[p];
      }
    }
    return output;
  };
  var refs = [];
  var refsPaths = [];
  maxDepth = maxDepth || 5;
  if (typeof input === 'object') {
    output = recursion(input);
  } else {
    output = input;
  }
  return JSON.stringify(output, null, 1);
};

module.exports = (DocFormatter = class DocFormatter {
  constructor(options) {
    this.options = options;
    this.doc = _.cloneDeep(this.options.doc);
    this.fillOutDoc();
  }

  fillOutDoc() {
    // TODO: figure out better ways to format html/css/scripting docs for web-dev levels
    let arg, args;
    if (_.isString(this.doc)) {
      this.doc = {name: this.doc, type: typeof this.options.thang[this.doc]};
    }
    if (this.options.isSnippet) {
      this.doc.type = 'snippet';
      this.doc.owner = 'snippets';
      this.doc.shortName = (this.doc.shorterName = (this.doc.title = this.doc.name));
    } else if (['HTML', 'CSS', 'WebJavaScript', 'jQuery'].includes(this.doc.owner)) {
      this.doc.shortName = (this.doc.shorterName = (this.doc.title = this.doc.name));
    } else {
      let argNames, argString;
      if (this.doc.owner == null) { this.doc.owner = 'this'; }
      let ownerName = (() => {
        if (this.doc.owner !== 'this') { return this.doc.owner; } else { switch (this.options.language) {
        case 'python': case 'lua': if (this.options.useHero) { return 'hero'; } else { return 'self'; }
        case 'java': return 'hero';
        case 'coffeescript': return '@';
        default: if (this.options.useHero) { return 'hero'; } else { return 'this'; }
      }
    }
      })();
      if (this.options.level.isType('game-dev')) { ownerName = 'game'; }
      this.doc.ownerName = ownerName;
      if (this.doc.type === 'function') {
        let docName;
        [docName, args] = Array.from(this.getDocNameAndArguments());
        argNames = args.join(', ');
        argString = argNames ? '__ARGS__' : '';
        this.doc.shortName = (() => { switch (this.options.language) {
          case 'coffeescript': return `${ownerName}${ownerName === '@' ? '' : '.'}${docName}${argString ? ' ' + argString : '()'}`;
          case 'python': return `${ownerName}.${docName}(${argString})`;
          case 'lua': return `${ownerName}:${docName}(${argString})`;
          default: return `${ownerName}.${docName}(${argString});`;
        } })();
      } else {
        this.doc.shortName = this.doc.name;
      }
      this.doc.shorterName = this.doc.shortName;
      if ((this.doc.type === 'function') && argString) {
        this.doc.shortName = this.doc.shorterName.replace(argString, argNames);
        this.doc.shorterName = this.doc.shorterName.replace(argString, (!/cast[A-Z]/.test(this.doc.name) && (argNames.length > 6) ? '...' : argNames));
      }
      if (['event', 'handler'].includes(this.doc.type)) {
        this.doc.shortName = this.doc.name;
        this.doc.shorterName = this.doc.name;
      }
      if (this.doc.type === 'property') {
        this.doc.shortName = this.doc.name.split(".").pop() || this.doc.name;
        this.doc.shorterName = this.doc.shortName;
      }
      if (this.doc.owner === 'ui') {
        this.doc.shortName = this.doc.shortName.replace(/^game./, '');
        this.doc.shorterName = this.doc.shortName;
      }
      if (this.options.language === 'javascript') {
        this.doc.shorterName = this.doc.shortName.replace(';', '');
        if ((this.doc.owner === 'this') || this.options.tabbify || (ownerName === 'game')) {
          this.doc.shorterName = this.doc.shorterName.replace(/^(this|hero)\./, '');
        }
      } else if ((['python', 'lua'].includes(this.options.language)) && ((this.doc.owner === 'this') || this.options.tabbify || (ownerName === 'game'))) {
        this.doc.shorterName = this.doc.shortName.replace(/^(self|hero|game)[:.]/, '');
      }
      this.doc.title = this.options.shortenize ? this.doc.shorterName : this.doc.shortName;
      const translatedName = utils.i18n(this.doc, 'name');
      if (translatedName !== this.doc.name) {
        this.doc.translatedShortName = this.doc.shortName.replace(this.doc.name, translatedName);
      }
    }

    // Add section and sub-section for methods bank list on frontend
    this.doc.section = this.options.section;
    this.doc.subSection = this.options.subSection;


    // Grab the language-specific documentation for some sub-properties, if we have it.
    const toTranslate = [{obj: this.doc, prop: 'description'}, {obj: this.doc, prop: 'example'}, {obj: this.doc, prop: 'shortDescription'}];
    for (arg of Array.from((this.doc.args != null ? this.doc.args : []))) {
      toTranslate.push({obj: arg, prop: 'example'}, {obj: arg, prop: 'description'});
    }
    if (this.doc.returns) {
      toTranslate.push({obj: this.doc.returns, prop: 'example'}, {obj: this.doc.returns, prop: 'description'});
    }
    for (var {obj, prop} of Array.from(toTranslate)) {
      // Translate into chosen code language.
      var originalVal, val;
      if (val = obj[prop] != null ? obj[prop][this.options.language] : undefined) {
        obj[prop] = val;
      } else if (!_.isString(obj[prop])) {
        obj[prop] = null;
      }

      // Translate into chosen spoken language.
      if (val = (originalVal = obj[prop])) {
        var {
          context
        } = this.doc;
        obj[prop] = (val = utils.i18n(obj, prop));
        // For multiplexed-by-both-code-and-spoken-language objects, now also get code language again.
        if (_.isObject(val)) {
          var valByCodeLanguage;
          if ((valByCodeLanguage = obj[prop] != null ? obj[prop][this.options.language] : undefined)) {
            obj[prop] = (val = valByCodeLanguage);
          } else {
            obj[prop] = originalVal;  // Never mind, we don't have that code language for that spoken language.
          }
        }
        if (this.doc.i18n) {
          var spokenLanguage = me.get('preferredLanguage');
          while (spokenLanguage) {
            var spokenLanguageContext;
            if (fallingBack != null) { spokenLanguage = spokenLanguage.substr(0, spokenLanguage.lastIndexOf('-')); }
            if (spokenLanguageContext = this.doc.i18n[spokenLanguage] != null ? this.doc.i18n[spokenLanguage].context : undefined) {
              context = _.merge(context, spokenLanguageContext);
              break;
            }
            var fallingBack = true;
          }
        }
        if (context) {
          try {
            obj[prop] = _.template(val, context);
          } catch (e) {
            console.error("Couldn't create docs template of", val, "\nwith context", context, "\nError:", e);
          }
        }
        obj[prop] = this.replaceSpriteName(obj[prop]);  // Do this before using the template, otherwise marked might get us first.
      }
    }

    // Temporary hack to replace self|this with hero until we can update the docs
    if (this.options.useHero) {
      const thisToken = {
        'python': /self/g,
        'javascript': /this/g,
        'lua': /self/g
      };

      if (thisToken[this.options.language]) {
        if (this.doc.example) {
          this.doc.example = this.doc.example.replace(thisToken[this.options.language], 'hero');
        }
        if (__guard__(this.doc.snippets != null ? this.doc.snippets[this.options.language] : undefined, x => x.code)) {
          this.doc.snippets[this.options.language].code.replace(thisToken[this.options.language], 'hero');
        }
        if (this.doc.args) {
          for (arg of Array.from(this.doc.args)) { if (arg.example) { arg.example = arg.example.replace(thisToken[this.options.language], 'hero'); } }
        }
      }
    }

    if ((this.doc.shortName === 'loop') && this.options.level.isType('course', 'course-ladder')) {
      return this.replaceSimpleLoops();
    }
  }

  replaceSimpleLoops() {
    // Temporary hackery to make it look like we meant while True: in our loop: docs until we can update everything
    this.doc.shortName = (this.doc.shorterName = (this.doc.title = (this.doc.name = (() => { switch (this.options.language) {
      case 'coffeescript': return "loop";
      case 'python': return "while True:";
      case 'lua': return "while true do";
      default: return "while (true)";
    } })())));
    return (() => {
      const result = [];
      for (var field of ['example', 'description']) {
        var [simpleLoop, whileLoop] = Array.from((() => { switch (this.options.language) {
          case 'coffeescript': return [/loop/g, "loop"];
          case 'python': return [/loop:/g, "while True:"];
          case 'lua': return [/loop/g, "while true do"];
          default: return [/loop/g, "while (true)"];
        } })());
        result.push(this.doc[field] = this.doc[field].replace(simpleLoop, whileLoop));
      }
      return result;
    })();
  }

  formatPopover() {
    const [docName, args] = Array.from(this.getDocNameAndArguments());
    const argumentExamples = (Array.from(this.doc.args != null ? this.doc.args : []).map((arg) => arg.example || arg.default || arg.name));
    if (args.length > argumentExamples.length) { argumentExamples.unshift(args[0]); }
    let content = popoverTemplate({
      doc: this.doc,
      docName,
      language: this.options.language,
      value: this.formatValue(),
      marked,
      argumentExamples,
      writable: this.options.writable,
      selectedMethod: this.options.selectedMethod,
      cooldowns: this.inferCooldowns(),
      item: this.options.item,
      _
    });
    const owner = this.doc.owner === 'this' ? this.options.thang : window[this.doc.owner];
    content = this.replaceSpriteName(content);
    content = content.replace(/\#\{(.*?)\}/g, (s, properties) => this.formatValue(utils.downTheChain(owner, properties.split('.'))));
    return content = content.replace(/{([a-z]+)}([^]*?){\/\1}/g, (s, language, text) => {
      if (language === this.options.language) { return text; }
      return '';
    });
  }

  replaceSpriteName(s) {
    // Prefer type, and excluded the quotes we'd get with @formatValue
    let name = this.options.thang.type != null ? this.options.thang.type : this.options.thang.spriteName;
    if (/Hero Placeholder/.test(this.options.thang.id)) { name = 'hero'; }
    return s.replace(/#{spriteName}/g, name);
  }

  getDocNameAndArguments() {
    if (this.doc.type !== 'function') { return [this.doc.name, []]; }
    let docName = this.doc.name;
    const args = (Array.from(this.doc.args != null ? this.doc.args : []).map((arg) => arg.name));
    if (/cast[A-Z]/.test(docName)) {
      docName = 'cast';
      args.unshift('"' + _.string.dasherize(this.doc.name).replace('cast-', '') + '"');
    }
    return [docName, args];
  }

  formatValue(v) {
    if (this.options.level.isType('web-dev')) { return null; }
    if (this.doc.type === 'snippet') { return null; }
    if (this.doc.name === 'now') { return this.options.thang.now(); }
    if (!v && (this.doc.type === 'function')) { return '[Function]'; }
    if (v == null) {
      if (this.doc.owner === 'this') {
        v = this.options.thang[this.doc.name];
      } else {
        v = window[this.doc.owner][this.doc.name];  // grab Math or Vector
      }
    }
    if ((this.doc.type === 'number') && !_.isNaN(v)) {
      if (v === Math.round(v)) {
        return v;
      }
      if (_.isNumber(v)) {
        return v.toFixed(2);
      }
      if (!v) {
        return 'null';
      }
      return '' + v;
    }
    if (_.isString(v)) {
      return `\"${v}\"`;
    }
    if (v != null ? v.id : undefined) {
      return v.id;
    }
    if (v != null ? v.name : undefined) {
      return v.name;
    }
    if (_.isArray(v)) {
      return '[' + (Array.from(v).map((v2) => this.formatValue(v2))).join(', ') + ']';
    }
    if (_.isPlainObject(v)) {
      return safeJSONStringify(v, 2);
    }
    return v;
  }

  inferCooldowns() {
    let action, actionName, type;
    if ((this.doc.type !== 'function') || (this.doc.owner !== 'this')) { return null; }
    const owner = this.options.thang;
    let cooldowns = null;
    const spellName = this.doc.name.match(/^cast(.+)$/);
    if (spellName) {
      actionName = _.string.slugify(_.string.underscored(spellName[1]));
      action = owner.spells != null ? owner.spells[actionName] : undefined;
      type = 'spell';
    } else {
      actionName = _.string.slugify(_.string.underscored(this.doc.name));
      action = owner.actions != null ? owner.actions[actionName] : undefined;
      type = 'action';
    }
    if (!action) { return null; }
    cooldowns = {cooldown: action.cooldown, specificCooldown: action.specificCooldown, name: actionName, type};
    for (var prop of ['range', 'radius', 'duration', 'damage']) {
      var v = owner[_.string.camelize(actionName + _.string.capitalize(prop))];
      if ((prop === 'range') && (v <= 5)) { continue; }  // Don't confuse players by showing melee ranges, they will inappropriately use distanceTo(enemy) < 3.
      cooldowns[prop] = v;
      if (_.isNumber(v) && (v !== Math.round(v))) {
        cooldowns[prop] = v.toFixed(2);
      }
    }
    return cooldowns;
  }
});

function __guard__(value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined;
}