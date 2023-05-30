/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS205: Consider reworking code to avoid use of IIFEs
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let CocoCollection;
const CocoModel = require('models/CocoModel');
const globalVar = require('core/globalVar');

module.exports = (CocoCollection = (function() {
  CocoCollection = class CocoCollection extends Backbone.Collection {
    static initClass() {
      this.prototype.loaded = false;
      this.prototype.model = null;
    }

    initialize(models, options) {
      if (options == null) { options = {}; }
      if (this.model == null) { this.model = options.model; }
      if (!this.model) {
        console.error(this.constructor.name, 'does not have a model defined. This will not do!');
      }
      super.initialize(models, options);
      this.setProjection(options.project);
      if (options.url) { this.url = options.url; }
      this.once('sync', () => {
        this.loaded = true;
        return Array.from(this.models).map((model) => (model.loaded = true));
      });
      if (globalVar.application != null ? globalVar.application.testing : undefined) {
        this.fakeRequests = [];
        this.on('request', function() { return this.fakeRequests.push(jasmine.Ajax.requests.mostRecent()); });
      }
      if (options.saveBackups) {
        return this.on('sync', function() {
          return (() => {
            const result = [];
            for (var model of Array.from(this.models)) {
              model.saveBackups = true;
              result.push(model.loadFromBackup());
            }
            return result;
          })();
        });
      }
    }

    getURL() {
      if (_.isString(this.url)) { return this.url; } else { return this.url(); }
    }

    fetch(options) {
      if (options == null) { options = {}; }
      if (this.project) {
        if (options.data == null) { options.data = {}; }
        options.data.project = this.project.join(',');
      }
      this.jqxhr = super.fetch(options);
      this.loading = true;
      return this.jqxhr;
    }

    setProjection(project) {
      this.project = project;
    }

    stringify() { return JSON.stringify(this.toJSON()); }
  
    wait(event) { return new Promise(resolve => this.once(event, resolve)); }
  };
  CocoCollection.initClass();
  return CocoCollection;
})());
