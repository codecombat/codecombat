// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS002: Fix invalid constructor
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS103: Rewrite code to no longer use __guard__, or convert again using --optional-chaining
 * DS104: Avoid inline assignments
 * DS204: Change includes calls to have a more natural evaluation order
 * DS205: Consider reworking code to avoid use of IIFEs
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
const storage = require('core/storage');
const locale = require('locale/locale');
const utils = require('core/utils');
const globalVar = require('core/globalVar');

class CocoModel extends Backbone.Model {
  static initClass() {
    this.prototype.idAttribute = '_id';
    this.prototype.loaded = false;
    this.prototype.loading = false;
    this.prototype.saveBackups = false;
    this.prototype.notyErrors = true;
    this.schema = null;

    this.prototype.attributesWithDefaults = undefined;

    this.backedUp = {};

    CocoModel.pollAchievements = _.debounce(CocoModel.pollAchievements, 3000);
  }

  constructor(attributes, options)  {
    super(...arguments)
    if (_.isObject(attributes) && ('undefined' in attributes)) {
      console.error(`Unsetting \`undefined\` property key during construction of ${this.constructor.className} model with value ${attributes['undefined']}`);
      delete attributes['undefined'];
    }
  }

  initialize(attributes, options) {
    super.initialize(...arguments);
    if (options == null) { options = {}; }
    this.setProjection(options.project);
    if (!this.constructor.className) {
      console.error(`${this} needs a className set.`);
    }
    this.on('sync', this.onLoaded, this);
    this.on('error', this.onError, this);
    this.on('add', this.onLoaded, this);
    this.saveBackup = _.debounce(this.saveBackup, 500);
    this.usesVersions = (__guard__(__guard__(this.schema(), x1 => x1.properties), x => x.version) != null);
    if (globalVar.application != null ? globalVar.application.testing : undefined) {
      this.fakeRequests = [];
      return this.on('request', function() { return this.fakeRequests.push(jasmine.Ajax.requests.mostRecent()); });
    }
  }

  created() { return new Date(parseInt(this.id.substring(0, 8), 16) * 1000); }

  backupKey() {
    if (this.usesVersions) { return this.id; } else { return this.id; }  // + ':' + @attributes.__v  # TODO: doesn't work because __v doesn't actually increment. #2061
  }
    // if fixed, RevertModal will also need the fix

  setProjection(project) {
    // TODO: ends up getting done twice, since the URL is modified and the @project is modified. So don't do this, just set project directly... (?)
    if (project === this.project) { return; }
    let url = this.getURL();
    if (!/project=/.test(url)) { url += '&project='; }
    if (!/\?/.test(url)) { url = url.replace('&', '?'); }
    url = url.replace(/project=[^&]*/, `project=${(project != null ? project.join(',') : undefined) || ''}`);
    if (!(project != null ? project.length : undefined)) { url = url.replace(/[&?]project=&/, '&'); }
    if (!(project != null ? project.length : undefined)) { url = url.replace(/[&?]project=$/, ''); }
    this.setURL(url);
    return this.project = project;
  }

  type() {
    return this.constructor.className;
  }

  clone(withChanges) {
    // Backbone does not support nested documents
    if (withChanges == null) { withChanges = true; }
    const clone = super.clone();
    clone.set($.extend(true, {}, withChanges || !this._revertAttributes ? this.attributes : this._revertAttributes));
    if (this._revertAttributes && !withChanges) {
      // remove any keys that are in the current attributes not in the snapshot
      for (var key of Array.from(_.difference(_.keys(clone.attributes), _.keys(this._revertAttributes)))) {
        clone.unset(key);
      }
    }
    return clone;
  }

  onError(level, jqxhr) {
    this.loading = false;
    this.jqxhr = null;
    if (jqxhr.status === 402) {
      if (_.contains(jqxhr.responseText, 'must be enrolled')) {
        return Backbone.Mediator.publish('level:license-required', {});
      } else if (_.contains(jqxhr.responseText, 'be in a course')) {
        return Backbone.Mediator.publish('level:course-membership-required', {});
      } else {
        return Backbone.Mediator.publish('level:subscription-required', {});
      }
    }
  }

  onLoaded() {
    this.loaded = true;
    this.loading = false;
    this.jqxhr = null;
    return this.loadFromBackup();
  }

  getCreationDate() { return new Date(parseInt(this.id.slice(0,8), 16)*1000); }

  getNormalizedURL() { return `${this.urlRoot}/${this.id}`; }

  getTranslatedName() {
    return utils.i18n(this.attributes, 'displayName') || utils.i18n(this.attributes, 'name');
  }

  get(attribute, withDefault) {
    if (withDefault == null) { withDefault = false; }
    if (withDefault) {
      if (this.attributesWithDefaults === undefined) { this.buildAttributesWithDefaults(); }
      return this.attributesWithDefaults[attribute];
    } else {
      return super.get(attribute);
    }
  }

  set(attributes, options) {
    if (attributes !== 'thangs') { delete this.attributesWithDefaults; }  // unless attributes is 'thangs': performance optimization for Levels keeping their cache.
    const inFlux = this.loading || !this.loaded;
    if (!inFlux && !this._revertAttributes && !this.project && !(options != null ? options.fromMerge : undefined)) { this.markToRevert(); }
    if (_.isString(attributes) && ((attributes === 'undefined') || (attributes === undefined))) {
      console.error(`Blocking setting of ${attributes} property to ${this.constructor.className} model with value ${options}`);
      return;
    } else if (_.isObject(attributes) && ('undefined' in attributes)) {
      console.error(`Blocking setting of \`undefined\` property key to ${this.constructor.className} model with value ${attributes['undefined']}`);
      delete attributes['undefined'];
    }
    const res = super.set(attributes, options);
    if (this.saveBackups && (!inFlux)) { this.saveBackup(); }
    return res;
  }

  buildAttributesWithDefaults() {
    const t0 = new Date();
    const clone = $.extend(true, {}, this.attributes);
    const thisTV4 = tv4.freshApi();
    thisTV4.addSchema('#', this.schema());
    thisTV4.addSchema('metaschema', require('schemas/metaschema'));
    TreemaUtils.populateDefaults(clone, this.schema(), thisTV4);
    this.attributesWithDefaults = clone;
    const duration = new Date() - t0;
    if (duration > 10) { return console.debug(`Populated defaults for ${this.type()}${this.attributes.name ? ' ' + this.attributes.name : ''} in ${duration}ms`); }
  }

  loadFromBackup() {
    if (!this.saveBackups) { return; }
    const existing = storage.load(this.backupKey());
    if (existing) {
      this.set(existing, {silent: true});
      return CocoModel.backedUp[this.backupKey()] = this;
    }
  }

  saveBackup() { return this.saveBackupNow(); }

  saveBackupNow() {
    storage.save(this.backupKey(), this.attributes);
    return CocoModel.backedUp[this.backupKey()] = this;
  }
  schema() { return this.constructor.schema; }

  getValidationErrors() {
    // Since Backbone unset only sets things to undefined instead of deleting them, we ignore undefined properties.
    const definedAttributes = _.pick(this.attributes, v => v !== undefined);
    const {
      errors
    } = tv4.validateMultiple(definedAttributes, this.constructor.schema || {});
    if (errors != null ? errors.length : undefined) { return errors; }
  }

  validate() {
    const errors = this.getValidationErrors();
    if (errors != null ? errors.length : undefined) {
      if (!(typeof application !== 'undefined' && application !== null ? application.testing : undefined)) {
        console.debug(`Validation failed for ${this.constructor.className}: '${this.get('name') || this}'.`);
        for (var error of Array.from(errors)) {
          console.debug("\t", error.dataPath, ':', error.message);
        }
        if (typeof console.trace === 'function') {
          console.trace();
        }
      }
      return errors;
    }
  }

  save(attrs, options) {
    if (options == null) { options = {}; }
    const originalOptions = _.cloneDeep(options);
    if (options.headers == null) { options.headers = {}; }
    options.headers['X-Current-Path'] = (document.location != null ? document.location.pathname : undefined) != null ? (document.location != null ? document.location.pathname : undefined) : 'unknown';
    const {
      success
    } = options;
    const {
      error
    } = options;
    options.success = (model, res) => {
      this.retries = 0;
      this.trigger('save:success', this);
      if (success) { success(this, res); }
      if (this._revertAttributes) { this.markToRevert(); }
      this.clearBackup();
      CocoModel.pollAchievements();
      return options.success = (options.error = null);  // So the callbacks can be garbage-collected.
    };
    options.error = (model, res) => {
      let left, notyError;
      if (res.status === 0) {
        let msg;
        if (this.retries == null) { this.retries = 0; }
        this.retries += 1;
        if (this.retries > 20) {
          msg = 'Your computer or our servers appear to be offline. Please try refreshing.';
          noty({text: msg, layout: 'center', type: 'error', killer: true});
          return;
        } else {
          let f;
          msg = $.i18n.t('loading_error.connection_failure', {defaultValue: 'Connection failed.'});
          try {
            noty({text: msg, layout: 'center', type: 'error', killer: true, timeout: 3000});
          } catch (error1) {
            notyError = error1;
            console.warn("Couldn't even show noty error for", error, "because", notyError);
          }
          return _.delay((f = () => this.save(attrs, originalOptions)), 3000);
        }
      }
      if (error) { error(this, res); }
      if (!this.notyErrors) { return; }
      const errorMessage = `Error saving ${(left = this.get('name')) != null ? left : this.type()}`;
      console.log('going to log an error message');
      console.warn(errorMessage, res.responseJSON);
      if (!(typeof webkit !== 'undefined' && webkit !== null ? webkit.messageHandlers : undefined)) {  // Don't show these notys on iPad
        try {
          noty({text: `${errorMessage}: ${res.status} ${res.statusText}\n${res.responseText}`, layout: 'topCenter', type: 'error', killer: false, timeout: 10000});
        } catch (error2) {
          notyError = error2;
          console.warn("Couldn't even show noty error for", error, "because", notyError);
        }
      }
      return options.success = (options.error = null);  // So the callbacks can be garbage-collected.
    };
    this.trigger('save', this);
    return super.save(attrs, options);
  }

  patch(options) {
    if (!this._revertAttributes) { return false; }
    if (options == null) { options = {}; }
    options.patch = true;
    options.type = 'PUT';

    const attrs = {_id: this.id};
    const keys = [];
    for (var key of Array.from(_.keys(this.attributes))) {
      if (!_.isEqual(this.attributes[key], this._revertAttributes[key])) {
        attrs[key] = this.attributes[key];
        keys.push(key);
      }
    }

    if (!keys.length) { return; }
    return this.save(attrs, options);
  }

  fetch(options) {
    if (!options) { options = {} }
    if (options.data == null) { options.data = {}; }
    if (this.project) { options.data.project = this.project.join(','); }
    //console.error @constructor.className, @, "fetching with cache?", options.cache, "options", options  # Useful for debugging cached IE fetches
    if (options.callOz) {
      const url = options.url || this.getURL();
      options.url = utils.getProductUrl('OZ', url);
    }
    this.jqxhr = super.fetch(options);
    this.loading = true;
    return this.jqxhr;
  }

  markToRevert() {
    if (this.type() === 'ThangType') {
      // Don't deep clone the raw vector data, but do deep clone everything else.
      this._revertAttributes = _.clone(this.attributes);
      return (() => {
        const result = [];
        for (var smallProp in this.attributes) {
          var value = this.attributes[smallProp];
          if (value && (smallProp !== 'raw')) {
            result.push(this._revertAttributes[smallProp] = _.cloneDeep(value));
          }
        }
        return result;
      })();
    } else {
      return this._revertAttributes = $.extend(true, {}, this.attributes);
    }
  }

  revert() {
    this.clear({silent: true});
    if (this._revertAttributes) { this.set(this._revertAttributes, {silent: true}); }
    return this.clearBackup();
  }

  clearBackup() {
    return storage.remove(this.backupKey());
  }

  hasLocalChanges() {
    return this._revertAttributes && !_.isEqual(this.attributes, this._revertAttributes);
  }

  cloneNewMinorVersion() {
    const newData = _.clone(this.attributes);
    const clone = new this.constructor(newData);
    return clone;
  }

  cloneNewMajorVersion() {
    const clone = this.cloneNewMinorVersion();
    clone.unset('version');
    return clone;
  }

  isPublished() {
    let left;
    for (var permission of Array.from(((left = this.get('permissions', true)) != null ? left : []))) {
      if ((permission.target === 'public') && (permission.access === 'read')) { return true; }
    }
    return false;
  }

  publish() {
    if (this.isPublished()) { throw new Error('Can\'t publish what\'s already-published. Can\'t kill what\'s already dead.'); }
    return this.set('permissions', this.get('permissions', true).concat({access: 'read', target: 'public'}));
  }

  static isObjectID(s) {
    return (s.length === 24) && (__guard__(s.match(/[a-f0-9]/gi), x => x.length) === 24);
  }

  hasReadAccess(actor) {
    // actor is a User object
    let left;
    if (actor == null) { actor = me; }
    if (actor.isAdmin()) { return true; }
    if (actor.isArtisan() && this.editableByArtisans) { return true; }
    for (var permission of Array.from(((left = this.get('permissions', true)) != null ? left : []))) {
      if ((permission.target === 'public') || (actor.get('_id') === permission.target)) {
        if (['owner', 'read'].includes(permission.access)) { return true; }
      }
    }

    return false;
  }

  hasWriteAccess(actor) {
    // actor is a User object
    let left;
    if (actor == null) { actor = me; }
    if (actor.isAdmin()) { return true; }
    if (actor.isArtisan() && this.editableByArtisans) { return true; }
    for (var permission of Array.from(((left = this.get('permissions', true)) != null ? left : []))) {
      if ((permission.target === 'public') || (actor.get('_id') === permission.target)) {
        if (['owner', 'write'].includes(permission.access)) { return true; }
      }
    }

    return false;
  }

  getOwner() {
    const ownerPermission = _.find(this.get('permissions', true), {access: 'owner'});
    return (ownerPermission != null ? ownerPermission.target : undefined);
  }

  watch(doWatch) {
    if (doWatch == null) { doWatch = true; }
    $.ajax(`${this.urlRoot}/${this.id}/watch`, {type: 'PUT', data: {on: doWatch}});
    return this.watching = () => doWatch;
  }

  watching() {
    let needle;
    return (needle = me.id, Array.from((this.get('watchers') || [])).includes(needle));
  }

  populateI18N(data, schema, path) {
    // TODO: Better schema/json walking
    let value;
    if (path == null) { path = ''; }
    let sum = 0;
    if (data == null) { data = $.extend(true, {}, this.attributes); }
    if (schema == null) { schema = this.schema() || {}; }
    if (schema.oneOf) { // get populating the Programmable component config to work
      schema = _.find(schema.oneOf, {type: 'object'}) || schema;
    }
    let addedI18N = false;
    if ((schema.properties != null ? schema.properties.i18n : undefined) && _.isPlainObject(data) && (data.i18n == null)) {
      data.i18n = {'-':{'-':'-'}}; // mongoose doesn't work with empty objects
      sum += 1;
      addedI18N = true;
    }

    if (_.isPlainObject(data)) {
      for (var key in data) {
        value = data[key];
        var numChanged = 0;
        var childSchema = schema.properties != null ? schema.properties[key] : undefined;
        if (!childSchema && _.isObject(schema.additionalProperties)) {
          childSchema = schema.additionalProperties;
        }
        if (childSchema) {
          numChanged = this.populateI18N(value, childSchema, path+'/'+key);
        }
        if (numChanged && !path) { // should only do this for the root object
          this.set(key, value);
        }
        sum += numChanged;
      }
    }

    if (schema.items && _.isArray(data)) {
      for (let index = 0; index < data.length; index++) { value = data[index]; sum += this.populateI18N(value, schema.items, path+'/'+index); }
    }

    if (addedI18N && !path) { this.set('i18n', data.i18n); } // need special case for root i18n
    if (!path) { this.updateI18NCoverage(); }  // only need to do this at the highest level
    return sum;
  }

  setURL(url) {
    const makeURLFunc = u => () => u;
    this.url = makeURLFunc(url);
    return this;
  }

  getURL() {
    if (_.isString(this.url)) { return this.url; } else { return this.url(); }
  }

  static pollAchievements() {
    if (utils.isOzaria) { return; }  // Not needed until/unlesss we start using achievements in Ozaria
    if (typeof application !== 'undefined' && application !== null ? application.testing : undefined) { return; }

    const CocoCollection = require('collections/CocoCollection');
    const EarnedAchievement = require('models/EarnedAchievement');

    class NewAchievementCollection extends CocoCollection {
      static initClass() {
        this.prototype.model = EarnedAchievement;
      }
      initialize(me) {
        if (me == null) { ({
          me
        } = require('core/auth')); }
        return this.url = `/db/user/${me.id}/achievements?notified=false`;
      }
    }
    NewAchievementCollection.initClass();

    const achievements = new NewAchievementCollection;
    return achievements.fetch({
      success(collection) {
        if (!_.isEmpty(collection.models)) { return me.fetch(({cache: false, success() { return Backbone.Mediator.publish('achievements:new', {earnedAchievements: collection}); }})); }
      },
      error() {
        return console.error('Miserably failed to fetch unnotified achievements', arguments);
      },
      cache: false
    });
  }


  //- Internationalization

  updateI18NCoverage(attributes) {
    const langCodeArrays = [];
    const pathToData = {};
    if (attributes == null) { ({
      attributes
    } = this); }

    // TODO: Share this code between server and client
    // NOTE: If you edit this, edit the server side version as well!
    TreemaUtils.walk(attributes, this.schema(), null, function(path, data, workingSchema) {
      // Store parent data for the next block...
      let prop;
      if (data != null ? data.i18n : undefined) {
        pathToData[path] = data;
      }

      if (_.string.endsWith(path, 'i18n')) {
        const i18n = data;

        // grab the parent data
        const parentPath = path.slice(0, -5);
        const parentData = pathToData[parentPath];

        // use it to determine what properties actually need to be translated
        let props = workingSchema.props || [];
        props = ((() => {
          const result = [];
          for (prop of Array.from(props)) {             if (parentData[prop] && !['sound', 'soundTriggers'].includes(prop)) {
              result.push(prop);
            }
          }
          return result;
        })());
        if (!props.length) { return; }
        if ('additionalProperties' in i18n) { return; }  // Workaround for #2630: Programmable is weird

        // get a list of lang codes where its object has keys for every prop to be translated
        const coverage = _.filter(_.keys(i18n), function(langCode) {
          const translations = i18n[langCode];
          return translations && _.all(((() => {
            const result1 = [];
            for (prop of Array.from(props)) {               result1.push(translations[prop]);
            }
            return result1;
          })()));
        });
        //console.log 'got coverage', coverage, 'for', path, props, workingSchema, parentData
        return langCodeArrays.push(coverage);
      }
    });

    if (!langCodeArrays.length) { return; }
    // language codes that are covered for every i18n object are fully covered
    const overallCoverage = _.intersection(...Array.from(langCodeArrays || []));
    return this.set('i18nCoverage', overallCoverage);
  }

  deleteI18NCoverage(options) {
    if (options == null) { options = {}; }
    options.url = this.url() + '/i18n-coverage';
    options.type = 'DELETE';
    return $.ajax(options);
  }

  saveNewMinorVersion(attrs, options) {
    if (options == null) { options = {}; }
    options.url = this.url() + '/new-version';
    options.type = 'POST';
    return this.save(attrs, options);
  }

  saveNewMajorVersion(attrs, options) {
    if (options == null) { options = {}; }
    attrs = attrs || _.omit(this.attributes, 'version');
    options.url = this.url() + '/new-version';
    options.type = 'POST';
    options.patch = true; // do not let version get sent along
    return this.save(attrs, options);
  }

  fetchPatchesWithStatus(status, options) {
    if (status == null) { status = 'pending'; }
    if (options == null) { options = {}; }
    const Patches = require('../collections/Patches');
    const patches = new Patches();
    if (options.data == null) { options.data = {}; }
    options.data.status = status;
    options.url = this.urlRoot + '/' + (this.get('original') || this.id) + '/patches';
    patches.fetch(options);
    return patches;
  }

  stringify() { return JSON.stringify(this.toJSON()); }

  wait(event) { return new Promise(resolve => this.once(event, resolve)); }

  fetchLatestVersion(original, options) {
    if (options == null) { options = {}; }
    options.url = _.result(this, 'urlRoot') + '/' + original + '/version';
    return this.fetch(options);
  }
}
CocoModel.initClass();

module.exports = CocoModel;

function __guard__(value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined;
}