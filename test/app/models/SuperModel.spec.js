/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
const SuperModel = require('models/SuperModel');
const User = require('models/User');
const LevelComponents = require('collections/LevelComponents');
const factories = require('test/app/factories');

describe('SuperModel', function() {
  
  describe('.trackRequest(jqxhr, value)', () => it('takes a jqxhr and tracks its progress', function(done) {
    const s = new SuperModel();
    const jqxhrA = $.get('/db/a');
    const reqA = jasmine.Ajax.requests.mostRecent();
    const jqxhrB = $.get('/db/b');
    const reqB = jasmine.Ajax.requests.mostRecent();
    s.trackRequest(jqxhrA, 1);
    s.trackRequest(jqxhrB, 3);
    expect(s.progress).toBe(0);
    reqA.respondWith({status: 200, responseText: '[]'});
    return _.defer(function() {
      expect(s.progress).toBe(0.25);
      reqB.respondWith({status: 200, responseText: '[]'});
      return _.defer(function() {
        expect(s.progress).toBe(1);
        return done();
      });
    });
  }));
  
  describe('progress (property)', function() {
    it('is finished by default', function() {
      const s = new SuperModel();
      return expect(s.finished()).toBeTruthy();
    });

    return it('is based on resource completion and value', function(done) {
      const s = new SuperModel();
      const r1 = s.addSomethingResource('???', 2);
      const r2 = s.addSomethingResource('???', 3);
      expect(s.progress).toBe(0);
      r1.markLoaded();

      // progress updates are deferred so defer more
      return _.defer(function() {
        expect(s.progress).toBe(0.4);
        r2.markLoaded();
        return _.defer(function() {
          expect(s.progress).toBe(1);
          return done();
        });
      });
    });
  });

  describe('loadModel (function)', function() {
    it('starts loading the model if it isn\'t already loading', function() {
      const s = new SuperModel();
      const m = new User({_id: '12345'});
      s.loadModel(m);
      const request = jasmine.Ajax.requests.mostRecent();
      return expect(request).toBeDefined();
    });

    it('also loads collections', function() {
      const s = new SuperModel();
      const c = new LevelComponents();
      s.loadModel(c);
      const request = jasmine.Ajax.requests.mostRecent();
      return expect(request).toBeDefined();
    });

    return xdescribe('timeout handling', function() {
      beforeEach(() => jasmine.clock().install());
      afterEach(() => jasmine.clock().uninstall());

      it('automatically retries stalled requests', function() {
        const s = new SuperModel();
        const m = new User({_id: '12345'});
        s.loadModel(m);
        let timeUntilRetry = 5000;

        // Retry request 5 times
        for (let timesTried = 1; timesTried <= 5; timesTried++) {
          expect(s.failed).toBeFalsy();
          expect(s.resources[1].loadsAttempted).toBe(timesTried);
          expect(jasmine.Ajax.requests.all().length).toBe(timesTried);
          jasmine.clock().tick(timeUntilRetry);
          timeUntilRetry *= 1.5;
        }

        // And then stop retrying
        expect(s.resources[1].loadsAttempted).toBe(5);
        expect(jasmine.Ajax.requests.all().length).toBe(5);
        return expect(s.failed).toBe(true);
      });

      return it('stops retrying once the model loads', function(done) {
        const s = new SuperModel();
        const m = new User({_id: '12345'});
        s.loadModel(m);
        let timeUntilRetry = 5000;
        // Retry request 2 times
        for (let timesTried = 1; timesTried <= 2; timesTried++) {
          expect(s.failed).toBeFalsy();
          expect(s.resources[1].loadsAttempted).toBe(timesTried);
          expect(jasmine.Ajax.requests.all().length).toBe(timesTried);
          jasmine.clock().tick(timeUntilRetry);
          timeUntilRetry *= 1.5;
        }

        // Respond to the third reqest
        expect(s.finished()).toBeFalsy();
        expect(s.failed).toBeFalsy();
        const request = jasmine.Ajax.requests.mostRecent();
        request.respondWith({status: 200, responseText: JSON.stringify(factories.makeUser({ _id: '12345' }).attributes)});

        return _.defer(function() {
          expect(s.finished()).toBe(true);
          expect(s.failed).toBeFalsy();

          // It shouldn't send any more requests after loading
          expect(s.resources[1].loadsAttempted).toBe(3);
          expect(jasmine.Ajax.requests.all().length).toBe(3);
          jasmine.clock().tick(60000);
          expect(s.resources[1].loadsAttempted).toBe(3);
          expect(jasmine.Ajax.requests.all().length).toBe(3);
          return done();
        });
      });
    });
  });

  describe('events', () => it('triggers "loaded-all" when finished', function(done) {
    const s = new SuperModel();
    const m = new User({_id: '12345'});
    let triggered = false;
    s.once('loaded-all', () => triggered = true);
    s.loadModel(m);
    const request = jasmine.Ajax.requests.mostRecent();
    request.respondWith({status: 200, responseText: '{}'});
    return _.defer(function() {
      expect(triggered).toBe(true);
      return done();
    });
  }));

  return describe('collection loading', () => it('combines models which are fetched from multiple sources', function() {
    const s = new SuperModel();

    const c1 = new LevelComponents();
    c1.url = '/db/level.component?v=1';
    s.loadCollection(c1, 'components');

    const c2 = new LevelComponents();
    c2.url = '/db/level.component?v=2';
    s.loadCollection(c2, 'components');

    const request = jasmine.Ajax.requests.sendResponses({
      '/db/level.component?v=1': [{"_id":"id","name":"Something"}],
      '/db/level.component?v=2': [{"_id":"id","description":"This is something"}]
    });

    expect(s.models['/db/level.component/id'].get('name')).toBe('Something');
    return expect(s.models['/db/level.component/id'].get('description')).toBe('This is something');
  }));
});
