// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS104: Avoid inline assignments
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let left, left1, Python;
const _ = (left = (left1 = (typeof window !== 'undefined' && window !== null ? window._ : undefined) != null ? (typeof window !== 'undefined' && window !== null ? window._ : undefined) : (typeof self !== 'undefined' && self !== null ? self._ : undefined)) != null ? left1 : (typeof global !== 'undefined' && global !== null ? global._ : undefined)) != null ? left : require('lodash');  // rely on lodash existing, since it busts CodeCombat to browserify it--TODO

import Language from './language';

export default Python = (function() {
  Python = class Python extends Language {
    static initClass() {
      this.prototype.name = 'Python';
      this.prototype.id = 'python';
      this.prototype.parserID = 'filbert';
      this.prototype.thisValue = 'self';
      this.prototype.thisValueAccess = 'self.';
      this.prototype.heroValueAccess = 'hero.';
      this.prototype.wrappedCodeIndentLen = 4;
    }

    constructor() {
      super(...arguments);
    }

    // Called to check if the ast has changed enough.
    // All of this code has been broken by the new esper changes.
    hasChangedASTs(a, b) { return true; }

    usesFunctionWrapping() { return false; }

    // Sets up middleware for the python execution context.
    setupInterpreter(esper) {
      const {
        realm
      } = esper;
      /*
        Register this function to be called whenever something from the outside world
        returns an array. We intercept the array and make it behave more like a Python
        list.
      */
      return realm.options.linkValueCallReturnValueWrapper = function(value) {
        const {
          ArrayPrototype
        } = realm;

        if (value.jsTypeName !== 'object') { return value; }

        if (value.clazz === 'Array') {
          const defineProperties = realm.Object.getImmediate('defineProperties');
          // listPropertyDescriptor has already been set up in the engine.
          // Reference: https://github.com/codecombat/skulpty/blob/master/lib/stdlib.js#L79
          const listPropertyDescriptor = realm.globalScope.get('__pythonRuntime').getImmediate('utils').getImmediate('listPropertyDescriptor');

          const gen = defineProperties.call(realm.Object, [value, listPropertyDescriptor], realm.globalScope);
          // All execution requests return a generator, thus we must consume the generator
          // to make execution happen.
          let it = gen.next();
          while (!it.done) {
            it = gen.next();
          }
        }

        return value;
      };
    }
  };
  Python.initClass();
  return Python;
})();
