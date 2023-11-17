// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS002: Fix invalid constructor
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS103: Rewrite code to no longer use __guard__, or convert again using --optional-chaining
 * DS205: Consider reworking code to avoid use of IIFEs
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let SuperModel;
module.exports = (SuperModel = class SuperModel extends Backbone.Model {
  constructor() {
    super()
    this.updateProgress = this.updateProgress.bind(this);
    this.num = 0;
    this.denom = 0;
    this.progress = 0;
    this.resources = {};
    this.rid = 0;
    this.maxProgress = 1;

    this.models = {};
    this.collections = {};
  }

  // Since the supermodel has undergone some changes into being a loader and a cache interface,
  // it's a bit wonky to use. The next couple functions are meant to cover the majority of
  // use cases across the site. If they are used, the view will automatically handle errors,
  // retries, progress, and filling the cache. Note that the resource it passes back will not
  // necessarily have the same model or collection that was passed in, if it was fetched from
  // the cache.

  report() {
    // Useful for debugging why a SuperModel never finishes loading.
    console.info('SuperModel report ------------------------');
    console.info(`${_.values(this.resources).length} resources.`);
    const unfinished = [];
    for (var resource of Array.from(_.values(this.resources))) {
      if (resource) {
        console.info("\t", resource.name, 'loaded', resource.isLoaded, resource.model);
        if (!resource.isLoaded) { unfinished.push(resource); }
      }
    }
    return unfinished;
  }

  numDuplicates() {
    // For debugging. TODO: Prevent duplicates from happening!
    const ids = (Array.from(_.values(this.models)).map((m) => m.get('_id')));
    return _.size(ids) - _.size(_.unique(ids));
  }

  loadModel(model, name, fetchOptions, value) {
    // Deprecating name. Handle if name is not included
    let cachedModel, res;
    if (value == null) { value = 1; }
    if (_.isNumber(fetchOptions)) { value = fetchOptions; }
    if (_.isObject(name)) { fetchOptions = name; }

    // hero-ladder levels need remote opponent_session for latest session data (e.g. code)
    // Can't apply to everything since other features rely on cached models being more recent (E.g. level_session)
    // E.g.#2 heroConfig isn't necessarily saved to db in world map inventory modal, so we need to load the cached session on level start
    if (((fetchOptions != null ? fetchOptions.cache : undefined) !== false) || (name !== 'opponent_session')) { cachedModel = this.getModelByURL(model.getURL()); }
    if (cachedModel) {
      if (cachedModel.loaded) {
        res = this.addModelResource(cachedModel, name, fetchOptions, 0);
        res.markLoaded();
        return res;
      } else {
        res = this.addModelResource(cachedModel, name, fetchOptions, value);
        res.markLoading();
        return res;
      }
    } else {
      this.registerModel(model);
      res = this.addModelResource(model, name, fetchOptions, value);
      if (model.loaded) { res.markLoaded(); } else { res.load(); }
      return res;
    }
  }

  loadCollection(collection, name, fetchOptions, value) {
    // Deprecating name. Handle if name is not included
    let cachedCollection, res;
    if (value == null) { value = 1; }
    if (_.isNumber(fetchOptions)) { value = fetchOptions; }
    if (_.isObject(name)) { fetchOptions = name; }

    const url = collection.getURL();
    if (cachedCollection = this.collections[url]) {
      console.debug('Collection cache hit', url, 'already loaded', cachedCollection.loaded);
      if (cachedCollection.loaded) {
        res = this.addModelResource(cachedCollection, name, fetchOptions, 0);
        res.markLoaded();
        return res;
      } else {
        res = this.addModelResource(cachedCollection, name, fetchOptions, value);
        res.markLoading();
        return res;
      }
    } else {
      this.addCollection(collection);
      var onCollectionSynced = function(c) {
        if (collection.url === c.url) {
          return this.registerCollection(c);
        } else {
          console.warn('Sync triggered for collection', c);
          console.warn('Yet got other object', c);
          return this.listenToOnce(collection, 'sync', onCollectionSynced);
        }
      };
      this.listenToOnce(collection, 'sync', onCollectionSynced);
      res = this.addModelResource(collection, name, fetchOptions, value);
      if (!(res.isLoading || res.isLoaded)) { res.load(); }
      return res;
    }
  }

  // Eventually should use only these functions. Use SuperModel just to track progress.
  trackModel(model, value) {
    const res = this.addModelResource(model, '', {}, value);
    return res.listen();
  }

  trackCollection(collection, value) {
    const res = this.addModelResource(collection, '', {}, value);
    return res.listen();
  }

  trackPromise(promise, value) {
    if (value == null) { value = 1; }
    const res = new Resource('', value);
    promise.then(() => res.markLoaded());
    promise.catch(function(err) {
      res.error = err;
      return res.markFailed();
    });
    this.storeResource(res, value);
    return promise;
  }

  trackRequest(jqxhr, value) {
    if (value == null) { value = 1; }
    const res = new Resource('', value);
    res.jqxhr = jqxhr;
    jqxhr.done(() => res.markLoaded());
    jqxhr.fail(() => res.markFailed());
    this.storeResource(res, value);
    return jqxhr;
  }

  trackRequests(jqxhrs, value) { if (value == null) { value = 1; } return Array.from(jqxhrs).map((jqxhr) => this.trackRequest(jqxhr, value)); }

  // replace or overwrite
  shouldSaveBackups(model) { return false; }

  // Caching logic

  getModel(ModelClass_or_url, id) {
    if (_.isString(ModelClass_or_url)) { return this.getModelByURL(ModelClass_or_url); }
    const m = new ModelClass_or_url({_id: id});
    return this.getModelByURL(m.getURL());
  }

  getModelByURL(modelURL) {
    if (_.isFunction(modelURL)) { modelURL = modelURL(); }
    return this.models[modelURL] || null;
  }

  getModelByOriginal(ModelClass, original, filter=null) {
    return _.find(this.models, m => (m.get('original') === original) && (m.constructor.className === ModelClass.className) && (!filter || filter(m)));
  }

  getModelByOriginalAndMajorVersion(ModelClass, original, majorVersion) {
    if (majorVersion == null) { majorVersion = 0; }
    return _.find(this.models, function(m) {
      let v;
      if (!(v = m.get('version'))) { return; }
      return (m.get('original') === original) && (v.major === majorVersion) && (m.constructor.className === ModelClass.className);
    });
  }

  getModels(ModelClass) {
    // can't use instanceof. SuperModel gets passed between windows, and one window
    // will have different class objects than another window.
    // So compare className instead.
    if (!ModelClass) {
      return _.values(this.models);
    }
    // Allow checking by string name to reduce module dependencies
    const className = _.isString(ModelClass) ? ModelClass : ModelClass.className;
    return (() => {
      const result = [];
      for (var key in this.models) {
        var m = this.models[key];
        if (m.constructor.className === className) {
          result.push(m);
        }
      }
      return result;
    })();
  }

  registerModel(model) {
    return this.models[model.getURL()] = model;
  }

  getCollection(collection) {
    return this.collections[collection.getURL()] || collection;
  }

  addCollection(collection) {
    // TODO: remove, instead just use registerCollection?
    const url = collection.getURL();
    if ((this.collections[url] != null) && (this.collections[url] !== collection)) {
      return console.warn(`Tried to add Collection '${url}' to SuperModel when we already had it.`);
    }
    return this.registerCollection(collection);
  }

  registerCollection(collection) {
    if (collection.isCachable) { this.collections[collection.getURL()] = collection; }
    // consolidate models
    for (let i = 0; i < collection.models.length; i++) {
      var model = collection.models[i];
      var cachedModel = this.getModelByURL(model.getURL());
      if (cachedModel) {
        var clone = $.extend(true, {}, model.attributes);
        cachedModel.set(clone, {silent: true, fromMerge: true});
        //console.debug "Updated cached model <#{cachedModel.get('name') or cachedModel.getURL()}> with new data"
      } else {
        this.registerModel(model);
      }
    }
    return collection;
  }

  // Tracking resources being loaded for this supermodel

  finished() {
    return (this.progress === 1.0) || (!this.denom) || this.failed;
  }

  addModelResource(modelOrCollection, name, fetchOptions, value) {
    // Deprecating name. Handle if name is not included
    if (value == null) { value = 1; }
    if (_.isNumber(fetchOptions)) { value = fetchOptions; }
    if (_.isObject(name)) { fetchOptions = name; }

    modelOrCollection.saveBackups = modelOrCollection.saveBackups || this.shouldSaveBackups(modelOrCollection);
    this.checkName(name);
    const res = new ModelResource(modelOrCollection, name, fetchOptions, value);
    this.storeResource(res, value);
    return res;
  }

  removeModelResource(modelOrCollection) {
    return this.removeResource(_.find(this.resources, resource => (resource != null ? resource.model : undefined) === modelOrCollection));
  }

  addRequestResource(name, jqxhrOptions, value) {
    // Deprecating name. Handle if name is not included
    if (value == null) { value = 1; }
    if (_.isNumber(jqxhrOptions)) { value = jqxhrOptions; }
    if (_.isObject(name)) { jqxhrOptions = name; }

    this.checkName(name);
    const res = new RequestResource(name, jqxhrOptions, value);
    this.storeResource(res, value);
    return res;
  }

  addSomethingResource(name, value) {
    if (value == null) { value = 1; }
    if (_.isNumber(name)) { value = name; }
    this.checkName(name);
    const res = new SomethingResource(name, value);
    this.storeResource(res, value);
    return res;
  }

  addPromiseResource(promise, value) {
    if (value == null) { value = 1; }
    const somethingResource = this.addSomethingResource('some promise', value);
    promise.then(() => somethingResource.markLoaded());
    return promise.catch(() => somethingResource.markFailed());
  }

  checkName(name) {}
    //if _.isString(name)
    //  console.warn("SuperModel name property deprecated. Remove '#{name}' from code.")

  storeResource(resource, value) {
    this.rid++;
    resource.rid = this.rid;
    this.resources[this.rid] = resource;
    this.listenToOnce(resource, 'loaded', this.onResourceLoaded);
    this.listenTo(resource, 'failed', this.onResourceFailed);
    this.denom += value;
    if (this.denom) { return _.defer(this.updateProgress); }
  }

  removeResource(resource) {
    if (!this.resources[resource.rid]) { return; }
    this.resources[resource.rid] = null;
    if (resource.isLoaded) { --this.num; }
    --this.denom;
    return _.defer(this.updateProgress);
  }

  onResourceLoaded(r) {
    if (!this.resources[r.rid]) { return; }
    this.num += r.value;
    _.defer(this.updateProgress);
    r.clean();
    this.stopListening(r, 'failed', this.onResourceFailed);
    return this.trigger('resource-loaded', r);
  }

  onResourceFailed(r) {
    if (!this.resources[r.rid]) { return; }
    this.failed = true;
    this.trigger('failed', {resource: r});
    return r.clean();
  }

  updateProgress() {
    // Because this is _.defer'd, this might end up getting called after
    // a bunch of things load all at once.
    // So make sure we only emit events if @progress has changed.
    let newProg = this.denom ? this.num / this.denom : 1;
    newProg = Math.min(this.maxProgress, newProg);
    if (this.progress >= newProg) { return; }
    this.progress = newProg;
    this.trigger('update-progress', this.progress);
    if (this.finished()) { return this.trigger('loaded-all'); }
  }

  setMaxProgress(maxProgress) {
    this.maxProgress = maxProgress;
  }
  resetProgress() { return this.progress = 0; }
  clearMaxProgress() {
    this.maxProgress = 1;
    return _.defer(this.updateProgress);
  }

  getProgress() { return this.progress; }

  getResource(rid) {
    return this.resources[rid];
  }

  // Promises
  finishLoading() {
    return new Promise((resolve, reject) => {
      if (this.finished()) { return resolve(this); }
      this.once('failed', function({resource}) {
        const {
          jqxhr
        } = resource;
        return reject({message: __guard__(jqxhr != null ? jqxhr.responseJSON : undefined, x => x.message) || (jqxhr != null ? jqxhr.responseText : undefined) || resource.error || 'Unknown Error'});
      });
      return this.once('loaded-all', () => resolve(this));
    });
  }
});

class Resource extends Backbone.Model {
  constructor(name, value) {
    super(...arguments)
    if (value == null) { value = 1; }
    this.name = name;
    this.value = value;
    this.rid = -1; // Used for checking state and reloading
    this.isLoading = false;
    this.isLoaded = false;
    this.model = null;
    this.jqxhr = null;
  }

  markLoaded() {
    if (this.isLoaded) { return; }
    this.trigger('loaded', this);
    this.isLoaded = true;
    return this.isLoading = false;
  }

  markFailed() {
    if (this.isLoaded) { return; }
    this.trigger('failed', this);
    this.isLoaded = (this.isLoading = false);
    return this.isFailed = true;
  }

  markLoading() {
    this.isLoaded = (this.isFailed = false);
    return this.isLoading = true;
  }

  clean() {
    // request objects get rather large. Clean them up after the request is finished.
    return this.jqxhr = null;
  }

  load() { return this; }
}

class ModelResource extends Resource {
  constructor(modelOrCollection, name, fetchOptions, value){
    super(name, value);
    this.model = modelOrCollection;
    this.fetchOptions = fetchOptions;
    this.jqxhr = this.model.jqxhr;
    this.loadsAttempted = 0;
  }

  load() {
    this.markLoading();
    this.fetchModel();
    return this;
  }

//    # TODO: Track progress on requests and don't retry if progress was made recently.
//    # Probably use _.debounce and attach event listeners to xhr objects.
//
//    # This logic is for handling failed responses for level loading.
//    timeToWait = 5000
//    tryLoad = =>
//      return if this.isLoaded
//      if @loadsAttempted > 4
//        @markFailed()
//        return @
//      @markLoading()
//      @model.loading = false # So fetchModel can run again
//      if @loadsAttempted > 0
//        console.log "Didn't load model in #{timeToWait}ms (attempt ##{@loadsAttempted}), trying again: ", _.result(@model, 'url')
//      @fetchModel()
//      @listenTo @model, 'error', (levelComponent, request) ->
//        if request.status not in [408, 504, 522, 524]
//          clearTimeout(@timeoutID)
//      clearTimeout(@timeoutID) if @timeoutID
//      @timeoutID = setTimeout(tryLoad, timeToWait)
//      if application.testing
//        application.timeoutsToClear?.push(@timeoutID)
//      @loadsAttempted += 1
//      timeToWait *= 1.5
//    tryLoad()
//    @

  fetchModel() {
    if (!this.model.loading) { this.jqxhr = this.model.fetch(this.fetchOptions); }
    return this.listen();
  }

  listen() {
    this.listenToOnce(this.model, 'sync', function() { return this.markLoaded(); });
    return this.listenToOnce(this.model, 'error', function() { return this.markFailed(); });
  }

  clean() {
    this.jqxhr = null;
    return this.model.jqxhr = null;
  }
}

class RequestResource extends Resource {
  constructor(name, jqxhrOptions, value) {
    super(name, value);
    this.jqxhrOptions = jqxhrOptions;
  }

  load() {
    this.markLoading();
    this.jqxhr = $.ajax(this.jqxhrOptions);
    // make sure any other success/fail callbacks happen before resource loaded callbacks
    this.jqxhr.done(() => _.defer(() => this.markLoaded()));
    this.jqxhr.fail(() => _.defer(() => this.markFailed()));
    return this;
  }
}

class SomethingResource extends Resource {}

function __guard__(value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined;
}