/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
const CocoModel = require('models/CocoModel');
const utils = require('core/utils');

class BlandClass extends CocoModel {
  static initClass() {
    this.className = 'Bland';
    this.schema = {
      type: 'object',
      additionalProperties: false,
      properties: {
        number: {type: 'number'},
        object: {type: 'object'},
        string: {type: 'string'},
        _id: {type: 'string'}
      }
    };
    this.prototype.urlRoot = '/db/bland';
  }
}
BlandClass.initClass();

describe('CocoModel', function() {
  describe('setProjection', function() {
    it('takes an array of properties to project and adds them as a query parameter', function() {
      const b = new BlandClass({});
      b.setProjection(['number', 'object']);
      b.fetch();
      const request = jasmine.Ajax.requests.mostRecent();
      return expect(decodeURIComponent(request.url).indexOf('project=number,object')).toBeGreaterThan(-1);
    });

    return it('can update its projection', function() {
      const baseURL = '/db/bland/test?filter-creator=Mojambo&project=number,object&ignore-evil=false';
      const unprojectedURL = baseURL.replace(/&project=number,object/, '');
      const b = new BlandClass({});
      b.setURL(baseURL);
      expect(b.getURL()).toBe(baseURL);
      b.setProjection(['number', 'object']);
      expect(b.getURL()).toBe(baseURL);
      b.setProjection(['number']);
      expect(b.getURL()).toBe(baseURL.replace(/,object/, ''));
      b.setProjection([]);
      expect(b.getURL()).toBe(unprojectedURL);
      b.setProjection(null);
      expect(b.getURL()).toBe(unprojectedURL);
      b.setProjection(['object', 'number']);
      return expect(b.getURL()).toBe(unprojectedURL + '&project=object,number');
    });
  });

  describe('save', function() {
    it('saves to db/<urlRoot>', function() {
      const b = new BlandClass({});
      const res = b.save();
      const request = jasmine.Ajax.requests.mostRecent();
      expect(res).toBeDefined();
      expect(request.url).toBe(b.urlRoot);
      return expect(request.method).toBe('POST');
    });

    it('does not save if the data is invalid based on the schema', function() {
      const b = new BlandClass({number: 'NaN'});
      const res = b.save();
      expect(res).toBe(false);
      const request = jasmine.Ajax.requests.mostRecent();
      return expect(request).toBeUndefined();
    });

    return it('uses PUT when _id is included', function() {
      const b = new BlandClass({_id: 'test'});
      b.save();
      const request = jasmine.Ajax.requests.mostRecent();
      return expect(request.method).toBe('PUT');
    });
  });

  describe('patch', function() {
    it('PATCHes only properties that have changed', function() {
      const b = new BlandClass({_id: 'test', number: 1});
      b.loaded = true;
      b.set('string', 'string');
      b.patch();
      const request = jasmine.Ajax.requests.mostRecent();
      const params = JSON.parse(request.params);
      expect(params.string).toBeDefined();
      return expect(params.number).toBeUndefined();
    });

    it('collates all changes made over several sets', function() {
      const b = new BlandClass({_id: 'test', number: 1});
      b.loaded = true;
      b.set('string', 'string');
      b.set('object', {4: 5});
      b.patch();
      const request = jasmine.Ajax.requests.mostRecent();
      const params = JSON.parse(request.params);
      expect(params.string).toBeDefined();
      expect(params.object).toBeDefined();
      return expect(params.number).toBeUndefined();
    });

    it('does not include data from previous patches', function() {
      const b = new BlandClass({_id: 'test', number: 1});
      b.loaded = true;
      b.set('object', {1: 2});
      b.patch();
      let request = jasmine.Ajax.requests.mostRecent();
      const attrs = JSON.stringify(b.attributes); // server responds with all
      request.respondWith({status: 200, responseText: attrs});

      b.set('number', 3);
      b.patch();
      request = jasmine.Ajax.requests.mostRecent();
      const params = JSON.parse(request.params);
      return expect(params.object).toBeUndefined();
    });

    return it('does nothing when there\'s nothing to patch', function() {
      const b = new BlandClass({_id: 'test', number: 1});
      b.loaded = true;
      b.set('number', 1);
      b.patch();
      const request = jasmine.Ajax.requests.mostRecent();
      return expect(request).toBeUndefined();
    });
  });

  xdescribe('Achievement polling', () => // TODO: Figure out how to do debounce in tests so that this test doesn't need to use keepDoingUntil

  it('achievements are polled upon saving a model', function(done) {
    //spyOn(CocoModel, 'pollAchievements')
    Backbone.Mediator.subscribe('achievements:new', function(collection) {
      Backbone.Mediator.unsubscribe('achievements:new');
      expect(collection.constructor.name).toBe('NewAchievementCollection');
      return done();
    });

    const b = new BlandClass({});
    const res = b.save();
    let request = jasmine.Ajax.requests.mostRecent();
    request.respondWith({status: 200, responseText: '{}'});

    const collection = [];
    const model = {
      _id: "5390f7637b4d6f2a074a7bb4",
      achievement: "537ce4855c91b8d1dda7fda8"
    };
    collection.push(model);

    return utils.keepDoingUntil(function(ready) {
      request = jasmine.Ajax.requests.mostRecent();
      const achievementURLMatch = (/.*achievements\?notified=false$/).exec(request.url);
      if (achievementURLMatch) {
        ready(true);
      } else { return ready(false); }

      request.respondWith({status: 200, responseText: JSON.stringify(collection)});

      return utils.keepDoingUntil(function(ready) {
        request = jasmine.Ajax.requests.mostRecent();
        const userURLMatch = (/^\/db\/user\/[a-zA-Z0-9]*$/).exec(request.url);
        if (userURLMatch) {
          ready(true);
        } else { return ready(false); }

        return request.respondWith({status:200, responseText: JSON.stringify(me)});});});
}));

  return describe('updateI18NCoverage', function() {
    class FlexibleClass extends CocoModel {
      static initClass() {
        this.className = 'Flexible';
        this.schema = {
          type: 'object',
          properties: {
            name: { type: 'string' },
            description: { type: 'string' },
            innerObject: {
              type: 'object',
              properties: {
                name: { type: 'string' },
                i18n: { type: 'object', format: 'i18n', props: ['name']}
              }
            },
            i18n: { type: 'object', format: 'i18n', props: ['description', 'name', 'prop1']}
          }
        };
      }
    }
    FlexibleClass.initClass();

    it('only includes languages for which all objects include a translation', function() {
      const m = new FlexibleClass({
        i18n: { es: { name: '+', description: '+' }, fr: { name: '+', description: '+' } },
        name: 'Name',
        description: 'Description',
        innerObject: {
          i18n: { es: { name: '+' }, de: { name: '+' }, fr: {} },
          name: 'Name'
        }
      });

      m.updateI18NCoverage();
      return expect(_.isEqual(m.get('i18nCoverage'), ['es'])).toBe(true);
    });

    return it('ignores objects for which there is nothing to translate', function() {
      const m = new FlexibleClass();
      m.set({
        name: 'Name',
        i18n: {
          '-': {'-':'-'},
          'es': {name: 'Name in Spanish'}
        },
        innerObject: {
          i18n: { '-': {'-':'-'} }
        }
      });
      m.updateI18NCoverage();
      return expect(_.isEqual(m.get('i18nCoverage'), ['es'])).toBe(true);
    });
  });
});
