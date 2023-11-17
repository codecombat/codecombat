/*
 * decaffeinate suggestions:
 * DS002: Fix invalid constructor
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS103: Rewrite code to no longer use __guard__, or convert again using --optional-chaining
 * DS202: Simplify dynamic range loops
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let SpellDebugView;
const CocoView = require('views/core/CocoView');
const template = require('app/templates/play/level/tome/spell_debug');
const ace = require('lib/aceContainer');
const {
  Range
} = ace.require('ace/range');
const {
  TokenIterator
} = ace.require('ace/token_iterator');
const serializedClasses = {
  Thang: require('lib/world/thang'),
  Vector: require('lib/world/vector'),
  Rectangle: require('lib/world/rectangle'),
  Ellipse: require('lib/world/ellipse'),
  LineSegment: require('lib/world/line_segment')
};

module.exports = (SpellDebugView = (function() {
  SpellDebugView = class SpellDebugView extends CocoView {
    static initClass() {
      this.prototype.className = 'spell-debug-view';
      this.prototype.template = template;

      this.prototype.subscriptions = {
        'god:new-world-created': 'onNewWorld',
        'god:debug-value-return': 'handleDebugValue',
        'god:debug-world-load-progress-changed': 'handleWorldLoadProgressChanged',
        'tome:cast-spells': 'onTomeCast',
        'surface:frame-changed': 'onFrameChanged',
        'tome:spell-has-changed-significantly-calculation': 'onSpellChangedCalculation'
      };

      this.prototype.events = {};
    }

    constructor(options) {
      super(options);
      this.calculateCurrentTimeString = this.calculateCurrentTimeString.bind(this);
      this.setTooltipKeyAndValue = this.setTooltipKeyAndValue.bind(this);
      this.setTooltipText = this.setTooltipText.bind(this);
      this.setTooltipProgress = this.setTooltipProgress.bind(this);
      this.onMouseMove = this.onMouseMove.bind(this);
      this.updateTooltipProgress = this.updateTooltipProgress.bind(this);
      this.notifyPropertyHovered = this.notifyPropertyHovered.bind(this);
      this.ace = options.ace;
      this.thang = options.thang;
      this.spell = options.spell;
      this.progress = 0;
      this.variableStates = {};
      this.globals = {Math, _, String, Number, Array, Object};  // ... add more as documented
      for (var className in serializedClasses) {
        var serializedClass = serializedClasses[className];
        this.globals[className] = serializedClass;
      }

      this.onMouseMove = _.throttle(this.onMouseMove, 25);
      this.cache = {};
      this.lastFrameRequested = -1;
      this.workerIsSimulating = false;
      this.spellHasChanged = false;
      this.currentFrame = 0;
      this.frameRate = 10; //only time it won't be set is at very beginning
      this.debouncedTooltipUpdate = _.debounce(this.updateTooltipProgress, 100);
    }

    pad2(num) {
      if ((num == null) || (num === 0)) { return '00'; } else { return ((num < 10 ? '0' : '') + num); }
    }

    calculateCurrentTimeString() {
      const time = this.currentFrame / this.frameRate;
      const mins = Math.floor(time / 60);
      const secs = (time - (mins * 60)).toFixed(1);
      return `${mins}:${this.pad2(secs)}`;
    }

    setTooltipKeyAndValue(key, value) {
      this.hideProgressBarAndShowText();
      const message = `Time: ${this.calculateCurrentTimeString()}\n${key}: ${value}`;
      this.$el.find('code').text(message);
      return this.$el.show().css(this.pos);
    }

    setTooltipText(text) {
      //perhaps changing styling here in the future
      this.hideProgressBarAndShowText();
      this.$el.find('code').text(text);
      return this.$el.show().css(this.pos);
    }

    setTooltipProgress(progress) {
      this.showProgressBarAndHideText();
      this.$el.find('.progress-bar').css('width', progress + '%').attr('aria-valuenow', progress);
      return this.$el.show().css(this.pos);
    }

    showProgressBarAndHideText() {
      this.$el.find('pre').css('display', 'none');
      return this.$el.find('.progress').css('display', 'block');
    }

    hideProgressBarAndShowText() {
      this.$el.find('pre').css('display', 'block');
      return this.$el.find('.progress').css('display', 'none');
    }

    onTomeCast() {
      return this.invalidateCache();
    }

    invalidateCache() { return this.cache = {}; }

    retrieveValueFromCache(thangID, spellID, variableChain, frame) {
      const joinedVariableChain = variableChain.join();
      const value = __guard__(__guard__(this.cache[frame] != null ? this.cache[frame][thangID] : undefined, x1 => x1[spellID]), x => x[joinedVariableChain]);
      return value != null ? value : undefined;
    }

    updateCache(thangID, spellID, variableChain, frame, value) {
      let currentObject = this.cache;
      const keys = [frame, thangID, spellID, variableChain.join()];
      for (let keyIndex = 0, end = keys.length - 1, asc = 0 <= end; asc ? keyIndex < end : keyIndex > end; asc ? keyIndex++ : keyIndex--) {
        var key = keys[keyIndex];
        if (!(key in currentObject)) {
          currentObject[key] = {};
        }
        currentObject = currentObject[key];
      }
      return currentObject[keys[keys.length - 1]] = value;
    }

    handleDebugValue(e) {
      const {key, value} = e;
      this.workerIsSimulating = false;
      this.updateCache(this.thang.id, this.spell.name, key.split('.'), this.lastFrameRequested, value);
      if (this.variableChain && (!key === this.variableChain.join('.'))) { return; }
      return this.setTooltipKeyAndValue(key, value);
    }

    handleWorldLoadProgressChanged(e) {
      return this.progress = e.progress;
    }

    afterRender() {
      super.afterRender();
      return this.ace.on('mousemove', this.onMouseMove);
    }

    setVariableStates(variableStates) {
      this.variableStates = variableStates;
      return this.update();
    }

    isIdentifier(t) {
      return t && ((t.type === 'identifier') || (t.value === 'this') || this.globals[t.value]);
    }

    onMouseMove(e) {
      let chain, end, start, token;
      if (this.destroyed) { return; }
      const pos = e.getDocumentPosition();
      const it = new TokenIterator(e.editor.session, pos.row, pos.column);
      const endOfLine = __guard__(it.getCurrentToken(), x => x.index) === (it.$rowTokens.length - 1);
      while ((it.getCurrentTokenRow() === pos.row) && !this.isIdentifier(token = it.getCurrentToken())) {
        if (endOfLine || !token) { break; }  // Don't iterate beyond end or beginning of line
        it.stepBackward();
      }
      if (this.isIdentifier(token)) {
        // This could be a property access, like 'enemy.target.pos' or 'this.spawnedRectangles'.
        // We have to realize this and dig into the nesting of the objects.
        start = it.getCurrentTokenColumn();
        [chain, start, end] = Array.from([[token.value], start, start + token.value.length]);
        while (it.getCurrentTokenRow() === pos.row) {
          var prev;
          it.stepBackward();
          if (__guard__(it.getCurrentToken(), x1 => x1.value) !== '.') { break; }
          it.stepBackward();
          token = null;  // If we're doing a complex access like this.getEnemies().length, then length isn't a valid var.
          if (!this.isIdentifier(prev = it.getCurrentToken())) { break; }
          token = prev;
          start = it.getCurrentTokenColumn();
          chain.unshift(token.value);
        }
      }
      //Highlight all tokens, so true overrides all other conditions TODO: Refactor this later
      if (token && (true || token.value in this.variableStates || (token.value === 'this') || this.globals[token.value])) {
        this.variableChain = chain;
        let offsetX = e.domEvent.offsetX != null ? e.domEvent.offsetX : e.clientX - $(e.domEvent.target).offset().left;
        const offsetY = e.domEvent.offsetY != null ? e.domEvent.offsetY : e.clientY - $(e.domEvent.target).offset().top;
        const w = $(document).width();
        if ((e.clientX + 300) > w) { offsetX = w - $(e.domEvent.target).offset().left - 300; }
        this.pos = {left: offsetX + 50, top: offsetY + 20};
        this.markerRange = new Range(pos.row, start, pos.row, end);
      } else {
        this.variableChain = (this.markerRange = null);
      }
      return this.update();
    }

    onMouseOut(e) {
      this.variableChain = (this.markerRange = null);
      return this.update();
    }

    updateTooltipProgress() {
      if (this.variableChain && (this.progress < 1)) {
        this.setTooltipProgress(this.progress * 100);
        return _.delay(this.updateTooltipProgress, 100);
      }
    }

    onNewWorld(e) {
      if (this.thang) { this.thang = (this.options.thang = e.world.thangMap[this.thang.id]); }
      return this.frameRate = e.world.frameRate;
    }

    onFrameChanged(data) {
      this.currentFrame = Math.round(data.frame);
      return this.frameRate = data.world.frameRate;
    }

    onSpellChangedCalculation(data) {
      return this.spellHasChanged = data.hasChangedSignificantly;
    }

    update() {
      if (this.variableChain) {
        let cacheValue;
        if (this.spellHasChanged) {
          this.setTooltipText('You\'ve changed this spell! \nPlease recast to use the hover debugger.');
        } else if ((this.variableChain.length === 2) && (this.variableChain[0] === 'this')) {
          this.setTooltipKeyAndValue(this.variableChain.join('.'), this.stringifyValue(this.thang[this.variableChain[1]], 0));
        } else if ((this.variableChain.length === 1) && Aether.globals[this.variableChain[0]]) {
          this.setTooltipKeyAndValue(this.variableChain.join('.'), this.stringifyValue(Aether.globals[this.variableChain[0]], 0));
        } else if (this.workerIsSimulating && (this.progress < 1)) {
          this.debouncedTooltipUpdate();
        } else if ((this.currentFrame === this.lastFrameRequested) && (cacheValue = this.retrieveValueFromCache(this.thang.id, this.spell.name, this.variableChain, this.currentFrame))) {
          this.setTooltipKeyAndValue(this.variableChain.join('.'), cacheValue);
        } else {
          Backbone.Mediator.publish('tome:spell-debug-value-request', {
            thangID: this.thang.id,
            spellID: this.spell.name,
            variableChain: this.variableChain,
            frame: this.currentFrame
          }
          );
          if (this.currentFrame !== this.lastFrameRequested) { this.workerIsSimulating = true; }
          this.lastFrameRequested = this.currentFrame;
          this.progress = 0;
          this.debouncedTooltipUpdate();
        }
      } else {
        this.$el.hide();
      }
      if ((this.variableChain != null ? this.variableChain.length : undefined) === 2) {
        if (this.hoveredPropertyTimeout) { clearTimeout(this.hoveredPropertyTimeout); }
        this.hoveredPropertyTimeout = _.delay(this.notifyPropertyHovered, 500);
      } else {
        this.notifyPropertyHovered();
      }
      return this.updateMarker();
    }

    stringifyValue(value, depth) {
      let s;
      if (!value || _.isString(value)) { return value; }
      if (_.isFunction(value)) {
        if (depth === 2) { return undefined; } else { return '<Function>'; }
      }
      if ((value === this.thang) && depth) { return `<this ${value.id}>`; }
      if (depth === 2) {
        if ((value.constructor != null ? value.constructor.className : undefined) === 'Thang') {
          value = `<${value.type || value.spriteName} - ${value.id}, ${value.pos ? value.pos.toString() : 'non-physical'}>`;
        } else {
          value = value.toString();
        }
        return value;
      }

      const isArray = _.isArray(value);
      const isObject = _.isObject(value);
      if (!isArray && !isObject) { return value.toString(); }
      const brackets = isArray ? ['[', ']'] : ['{', '}'];
      const size = _.size(value);
      if (!size) { return brackets.join(''); }
      const values = [];
      if (isArray) {
        for (var v of Array.from(value)) {
          s = this.stringifyValue(v, depth + 1);
          if (s !== undefined) { values.push('' + s); }
        }
      } else {
        for (var key of Array.from(value.apiProperties != null ? value.apiProperties : _.keys(value))) {
          s = this.stringifyValue(value[key], depth + 1);
          if (s !== undefined) { values.push(key + ': ' + s); }
        }
      }
      const sep = '\n' + (__range__(0, depth, false).map((i) => '  ')).join('');
      let prefix = value.constructor != null ? value.constructor.className : undefined;
      if (isArray) { if (prefix == null) { prefix = 'Array'; } }
      if (isObject) { if (prefix == null) { prefix = 'Object'; } }
      prefix = prefix ? prefix + ' ' : '';
      return `${prefix}${brackets[0]}${sep}  ${values.join(sep + '  ')}${sep}${brackets[1]}`;
    }
    notifyPropertyHovered() {
      if (this.hoveredPropertyTimeout) { clearTimeout(this.hoveredPropertyTimeout); }
      this.hoveredPropertyTimeout = null;
      const oldHoveredProperty = this.hoveredProperty;
      this.hoveredProperty = (this.variableChain != null ? this.variableChain.length : undefined) === 2 ? {owner: this.variableChain[0], property: this.variableChain[1]} : {};
      if (!_.isEqual(oldHoveredProperty, this.hoveredProperty)) {
        return Backbone.Mediator.publish('tome:spell-debug-property-hovered', this.hoveredProperty);
      }
    }

    updateMarker() {
      if (this.marker) {
        this.ace.getSession().removeMarker(this.marker);
        this.marker = null;
      }
      if (this.markerRange) {
        return this.marker = this.ace.getSession().addMarker(this.markerRange, 'ace_bracket', 'text');
      }
    }


    destroy() {
      if (this.ace != null) {
        this.ace.removeEventListener('mousemove', this.onMouseMove);
      }
      return super.destroy();
    }
  };
  SpellDebugView.initClass();
  return SpellDebugView;
})());

function __guard__(value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined;
}
function __range__(left, right, inclusive) {
  let range = [];
  let ascending = left < right;
  let end = !inclusive ? right : ascending ? right + 1 : right - 1;
  for (let i = left; ascending ? i < end : i > end; ascending ? i++ : i--) {
    range.push(i);
  }
  return range;
}