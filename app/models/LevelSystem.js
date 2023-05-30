/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let LevelSystem;
const CocoModel = require('./CocoModel');
const SystemNameLoader = require('core/SystemNameLoader');

module.exports = (LevelSystem = (function() {
  LevelSystem = class LevelSystem extends CocoModel {
    static initClass() {
      this.className = 'LevelSystem';
      this.schema = require('schemas/models/level_system');
      this.prototype.urlRoot = '/db/level.system';
      this.prototype.editableByArtisans = true;
    }

    set(key, val, options) {
      let attrs;
      if (_.isObject(key)) {
        [attrs, options] = Array.from([key, val]);
      } else {
        (attrs = {})[key] = val;
      }
      if ('code' in attrs && !('js' in attrs)) {
        attrs.js = this.compile(attrs.code);
      }
      return super.set(attrs, options);
    }

    onLoaded() {
      super.onLoaded();
      if (!this.get('js')) { this.set('js', this.compile(this.get('code'))); }
      return SystemNameLoader.setName(this);
    }

    compile(code) {
      let js;
      if (this.get('codeLanguage') && (this.get('codeLanguage') === 'javascript')) { return code; }
      if (this.get('codeLanguage') && (this.get('codeLanguage') !== 'coffeescript')) {
        return console.error('Can\'t compile', this.get('codeLanguage'), '-- only CoffeeScript/JavaScript.', this);
      }
      try {
        js = CoffeeScript.compile(code, {bare: true});
      } catch (e) {
        //console.log 'couldn\'t compile', code, 'for', @get('name'), 'because', e
        js = this.get('js');
      }
      return js;
    }

    getDependencies(allSystems) {
      const results = [];
      for (var dep of Array.from(this.get('dependencies') || [])) {
        var system = _.find(allSystems, sys => (sys.get('original') === dep.original) && (sys.get('version').major === dep.majorVersion));
        for (var result of Array.from(system.getDependencies(allSystems).concat([system]))) {
          if (!Array.from(results).includes(result)) { results.push(result); }
        }
      }
      return results;
    }
  };
  LevelSystem.initClass();
  return LevelSystem;
})());
