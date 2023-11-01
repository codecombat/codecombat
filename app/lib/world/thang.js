/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS103: Rewrite code to no longer use __guard__, or convert again using --optional-chaining
 * DS104: Avoid inline assignments
 * DS205: Consider reworking code to avoid use of IIFEs
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let Thang;
const ThangState = require('./thang_state');
const {thangNames} = require('./names');
const {ArgumentError} = require('./errors');
const Rand = require('./rand');
const utils = require('core/utils');

module.exports = (Thang = (function() {
  Thang = class Thang {
    static initClass() {
      this.className = 'Thang';
      this.remainingThangNames = {};
      this.prototype.isThang = true;
      this.prototype.apiProperties = ['id', 'spriteName', 'health', 'pos', 'team'];
    }

    static nextID(spriteName, world) {
      let name;
      const originals = thangNames[spriteName] || [spriteName];
      let remaining = Thang.remainingThangNames[spriteName];
      if (!(remaining != null ? remaining.length : undefined)) { remaining = (Thang.remainingThangNames[spriteName] = originals.slice()); }

      const baseName = remaining.splice(world.rand.rand(remaining.length), 1)[0];
      let i = 0;
      while (true) {
        name = i ? `${baseName} ${i}` : baseName;
        var extantThang = world.thangMap[name];
        if (!extantThang) { break; }
        i++;
      }
      return name;
    }

    static resetThangIDs() { return Thang.remainingThangNames = {}; }

    constructor(world, spriteName, id) {
      this.world = world;
      this.spriteName = spriteName;
      this.id = id;
      if (this.spriteName == null) { this.spriteName = this.constructor.className; }
      if (this.id == null) { this.id = this.constructor.nextID(this.spriteName, this.world); }
      this.addTrackedProperties(['exists', 'boolean']);  // TODO: move into Systems/Components, too?
    }
      //console.log "Generated #{@toString()}."

    destroy() {
      // Just trying to destroy __aetherAPIClone, but might as well nuke everything just in case
      for (var key in this) { this[key] = undefined; }
      this.destroyed = true;
      return this.destroy = function() {};
    }

    updateRegistration() {
      return Array.from(this.world.systems).map((system) => system.register(this));
    }

    publishNote(channel, event) {
      event.thang = this;
      return this.world.publishNote(channel, event);
    }

    getGoalState(goalID) {
      return this.world.getGoalState(goalID);
    }

    setGoalState(goalID, status) {
      return this.world.setGoalState(goalID, status);
    }

    getThangByID(id) {
      return this.world.getThangByID(id);
    }

    addComponents(...components) {
      // We don't need to keep the components around after attaching them, but we will keep their initial config for recreating Thangs
      if (this.components == null) { this.components = []; }
      return (() => {
        const result = [];
        for (var [componentClass, componentConfig] of Array.from(components)) {
          this.components.push([componentClass, componentConfig]);
          if (_.isString(componentClass)) {  // We had already turned it into a string, so re-classify it momentarily
            componentClass = this.world.classMap[componentClass];
          } else {
            if (this.world != null) {
              this.world.classMap[componentClass.className] != null ? this.world.classMap[componentClass.className] : (this.world.classMap[componentClass.className] = componentClass);
            }
          }
          var c = new componentClass(componentConfig != null ? componentConfig : {});
          c.world = this.world;
          result.push(c.attach(this));
        }
        return result;
      })();
    }

    // [prop, type]s of properties which have values tracked across WorldFrames. Also call keepTrackedProperty some non-expensive time when you change it or it will be skipped.
    addTrackedProperties(...props) {
      if (this.trackedPropertiesKeys == null) { this.trackedPropertiesKeys = []; }
      if (this.trackedPropertiesTypes == null) { this.trackedPropertiesTypes = []; }
      if (this.trackedPropertiesUsed == null) { this.trackedPropertiesUsed = []; }
      return (() => {
        const result = [];
        for (var [prop, type] of Array.from(props)) {
          if (!Array.from(ThangState.trackedPropertyTypes).includes(type)) {
            // How should errors for busted Components work? We can't recover from this and run the world.
            throw new Error(`Type ${type} for property ${prop} is not a trackable property type: ${ThangState.trackedPropertyTypes}`);
          }
          var oldPropIndex = this.trackedPropertiesKeys.indexOf(prop);
          if (oldPropIndex === -1) {
            this.trackedPropertiesKeys.push(prop);
            this.trackedPropertiesTypes.push(type);
            result.push(this.trackedPropertiesUsed.push(false));
          } else {
            var oldType = this.trackedPropertiesTypes[oldPropIndex];
            if (type !== oldType) {
              throw new Error(`Two types were specified for trackable property ${prop}: ${oldType} and ${type}.`);
            } else {
              result.push(undefined);
            }
          }
        }
        return result;
      })();
    }

    keepTrackedProperty(prop) {
      // Wish we could do this faster, but I can't think of how.
      const propIndex = this.trackedPropertiesKeys.indexOf(prop);
      if (propIndex !== -1) {
        return this.trackedPropertiesUsed[propIndex] = true;
      }
    }

    // @trackedFinalProperties: names of properties which need to be tracked once at the end of the World; don't worry about types
    addTrackedFinalProperties(...props) {
      if (this.trackedFinalProperties == null) { this.trackedFinalProperties = []; }
      return this.trackedFinalProperties = this.trackedFinalProperties.concat(((() => {
        const result = [];
        for (var k of Array.from(props)) {           if (!(Array.from(this.trackedFinalProperties).includes(k))) {
            result.push(k);
          }
        }
        return result;
      })()));
    }

    getState() {
      return this._state = new ThangState(this);
    }
    setState(state) {
      return this._state = state.restore();
    }

    toString() { return this.id; }

    createMethodChain(methodName) {
      if (this.methodChains == null) { this.methodChains = {}; }
      let chain = this.methodChains[methodName];
      if (chain) { return chain; }
      chain = (this.methodChains[methodName] = {original: this[methodName], user: null, components: []});
      this[methodName] = _.partial(this.callChainedMethod, methodName);  // Optimize! _.partial is fastest I've found
      return chain;
    }

    appendMethod(methodName, newMethod) {
      // Components add methods that come after the original method
      return this.createMethodChain(methodName).components.push(newMethod);
    }

    callChainedMethod(methodName, ...args) {
      // Optimize this like crazy--but how?
      const chain = this.methodChains[methodName];
      const primaryMethod = chain.user || chain.original;
      let ret = primaryMethod != null ? primaryMethod.apply(this, args) : undefined;
      for (var componentMethod of Array.from(chain.components)) {
        var ret2 = componentMethod.apply(this, args);
        ret = ret2 != null ? ret2 : ret;
      }  // override return value only if not null
      return ret;
    }

    getMethodSource(methodName) {
      const source = {};
      if ((this.methodChains != null) && methodName in this.methodChains) {
        const chain = this.methodChains[methodName];
        source.original = chain.original.toString();
        source.user = chain.user != null ? chain.user.toString() : undefined;
      } else {
        let left;
        source.original = (left = (this[methodName] != null ? this[methodName].toString() : undefined)) != null ? left : '';
      }
      source.original = Aether.getFunctionBody(source.original);
      return source;
    }

    serialize() {
      const o = {spriteName: this.spriteName, id: this.id, components: [], finalState: {}};
      const iterable = this.components != null ? this.components : [];
      for (let i = 0; i < iterable.length; i++) {
        var componentClassName;
        var [componentClass, componentConfig] = iterable[i];
        if (_.isString(componentClass)) {
          componentClassName = componentClass;
        } else {
          componentClassName = componentClass.className;
          if (this.world.classMap[componentClass.className] == null) { this.world.classMap[componentClass.className] = componentClass; }
        }
        o.components.push([componentClassName, componentConfig]);
      }
      for (var trackedFinalProperty of Array.from(this.trackedFinalProperties != null ? this.trackedFinalProperties : [])) {
        // TODO: take some (but not all) of serialize logic from ThangState to handle other types
        o.finalState[trackedFinalProperty] = this[trackedFinalProperty];
      }
      // Since we might keep tracked properties later during streaming, we need to know which we think are unused.
      o.unusedTrackedPropertyKeys = ((() => {
        const result = [];
        for (let propIndex = 0; propIndex < this.trackedPropertiesUsed.length; propIndex++) {
          var used = this.trackedPropertiesUsed[propIndex];
          if (!used) {
            result.push(this.trackedPropertiesKeys[propIndex]);
          }
        }
        return result;
      })());
      return o;
    }

    static deserialize(o, world, classMap, levelComponents) {
      let prop;
      const t = new Thang(world, o.spriteName, o.id);
      for (var [componentClassName, componentConfig] of Array.from(o.components)) {
        var componentClass;
        if (!(componentClass = classMap[componentClassName])) {
          console.debug('Compiling new Component while deserializing:', componentClassName);
          var componentModel = _.find(levelComponents, {name: componentClassName});
          componentClass = world.loadClassFromCode(componentModel.js, componentClassName, 'component');
          world.classMap[componentClassName] = componentClass;
        }
        t.addComponents([componentClass, componentConfig]);
      }
      t.unusedTrackedPropertyKeys = o.unusedTrackedPropertyKeys;
      t.unusedTrackedPropertyValues = ((() => {
        const result = [];
        for (prop of Array.from(o.unusedTrackedPropertyKeys)) {           result.push(t[prop]);
        }
        return result;
      })());
      for (prop in o.finalState) {
        // TODO: take some (but not all) of deserialize logic from ThangState to handle other types
        var val = o.finalState[prop];
        t[prop] = val;
      }
      return t;
    }

    serializeForAether() {
      return {CN: this.constructor.className, id: this.id};
    }

    getLankOptions() {
      let color, teamColor;
      const colorConfigs = this.teamColors || (this.world != null ? this.world.getTeamColors() : undefined) || {};
      const options = {colorConfig: {}};
      if ((this.id === 'Hero Placeholder') && !this.world.getThangByID('Hero Placeholder 1')) {
        if (utils.isOzaria) {
          // Single player color customization options
          const player_tints = __guard__(me.get('ozariaUserOptions'), x => x.tints) || [];
          player_tints.forEach(tint => {
            return (() => {
              const result = [];
              const object = tint.colorGroups || {};
              for (var key in object) {
                var value = object[key];
                result.push(options.colorConfig[key] = _.clone(value));
              }
              return result;
            })();
          });
        }
        return options;
      }
      if (this.team && (teamColor = colorConfigs[this.team])) {
        options.colorConfig.team = teamColor;
      }
      if (this.color && (color = this.grabColorConfig(this.color))) {
        options.colorConfig.color = color;
      }
      if (this.colors) {
        for (var colorType in this.colors) { var colorValue = this.colors[colorType]; options.colorConfig[colorType] = colorValue; }
      }
      return options;
    }

    grabColorConfig(color) {
      return {
        green: {hue: 0.33, saturation: 0.5, lightness: 0.5},
        black: {hue: 0, saturation: 0, lightness: 0.25},
        violet: {hue: 0.83, saturation: 0.5, lightness: 0.5}
      }[color];
    }
  };
  Thang.initClass();
  return Thang;
})());

function __guard__(value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined;
}