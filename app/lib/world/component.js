// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS103: Rewrite code to no longer use __guard__, or convert again using --optional-chaining
 * DS205: Consider reworking code to avoid use of IIFEs
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let Component;
const utils = require('core/utils');

const componentKeywords = ['attach', 'constructor', 'validateArguments', 'toString', 'isComponent'];  // Array is faster than object

module.exports = (Component = (function() {
  Component = class Component {
    static initClass() {
      this.className = 'Component';
      this.prototype.isComponent = true;
  
      this.prototype.validateArguments =
        {additionalProperties: false};
    }
    constructor(config) {
      for (var key in config) {
        var value = config[key];
        this[key] = value;
      }  // Hmm, might want to _.cloneDeep here? What if the config has nested object values and the Thang modifies them, then we re-use the config for, say, missile spawning? Well, for now we'll clone in the missile.
    }

    attach(thang) {
      // Optimize; this is much of the World constructor time
      const keys = (Object.getOwnPropertyNames(this.__proto__) || []).concat(Object.getOwnPropertyNames(this));
      return (() => {
        const result = [];
        for (var key of Array.from(keys)) {
          if (!Array.from(componentKeywords).includes(key) && (key[0] !== '_')) {
            var oldValue = thang[key];
            var value = this[key];
            if (typeof oldValue === 'function') {
              result.push(thang.appendMethod(key, value));
            } else {
              result.push(thang[key] = value);
            }
          }
        }
        return result;
      })();
    }

    getCodeContext(className) {
      if (className == null) { ({
        className
      } = this.constructor); }
      if (!__guard__(this.world != null ? this.world.levelComponents : undefined, x => x.length)) { return; }
      const levelComponent = _.find(this.world.levelComponents, {name: className});
      if (!levelComponent) { return; }
      let context = (levelComponent != null ? levelComponent.context : undefined) || {};
      const language = this.world.language || 'en-US';

      const localizedContext = utils.i18n(levelComponent, 'context', language);
      if (localizedContext) {
        context = _.merge(context, localizedContext);
      }
      return context;
    }

    toString() {
      return `<Component: ${this.constructor.className}`;
    }
  };
  Component.initClass();
  return Component;
})());

function __guard__(value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined;
}