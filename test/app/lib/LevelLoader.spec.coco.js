/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
const Level = require('models/Level');
const LevelSession = require('models/LevelSession');
const SuperModel = require('models/SuperModel');
const LevelComponent = require('models/LevelComponent');
const LevelLoader = require('lib/LevelLoader');

// LEVELS

const levelWithOgreWithMace = {
  thangs: [{
    thangType: 'ogre',
    components: [{
      original: LevelComponent.EquipsID,
      majorVersion: 0,
      config: { inventory: { 'left-hand': 'mace' } }
    }]
  }]
};

const levelWithShaman = {
  thangs: [{
    thangType: 'shaman'
  }]
};

const levelWithShamanWithSuperWand = {
  thangs: [{
    thangType: 'shaman',
    components: [{
      original: LevelComponent.EquipsID,
      majorVersion: 0,
      config: { inventory: { 'left-hand': 'super-wand' } }
    }]
  }]
};

// SESSIONS

const sessionWithTharinWithHelmet = { heroConfig: { thangType: 'tharin', inventory: { 'head': 'helmet' }}};

const sessionWithAnyaWithGloves = { heroConfig: { thangType: 'anya', inventory: { 'head': 'gloves' }}};

// THANG TYPES

const thangTypeOgreWithPhysicalComponent = {
  name: 'Ogre',
  original: 'ogre',
  components: [{
    original: 'physical',
    majorVersion: 0
  }]
};

const thangTypeShamanWithWandEquipped = {
  name: 'Shaman',
  original: 'shaman',
  components: [{
    original: LevelComponent.EquipsID,
    majorVersion: 0,
    config: { inventory: { 'left-hand': 'wand' }}
  }]
};

const thangTypeTharinWithHealsComponent = {
  name: 'Tharin',
  original: 'tharin',
  components: [{
    original: 'heals',
    majorVersion: 0
  }]
};

const thangTypeWand = {
  name: 'Wand',
  original: 'wand',
  components: [{
    original: 'poisons',
    majorVersion: 0
  }]
};

const thangTypeAnyaWithJumpsComponent = {
  name: 'Anya',
  original: 'anya',
  components: [{
    original: 'jumps',
    majorVersion: 0
  }]
};



describe('LevelLoader', function() {
  describe('loadDependenciesForSession', function() {
    it('loads hero and item thang types from heroConfig in the given session', function() {
      const levelLoader = new LevelLoader({supermodel:new SuperModel(), sessionID: 'id', levelID: 'id'});
      levelLoader.sessionDependenciesRegistered = {};
      const session = new LevelSession(sessionWithAnyaWithGloves);
      levelLoader.loadDependenciesForSession(session);
      const requests = jasmine.Ajax.requests.all();
      const urls = (Array.from(requests).map((r) => r.url));
      expect(Array.from(urls).includes('/db/thang.type/gloves/version?project=name,components,original,rasterIcon,kind')).toBeTruthy();
      return expect(Array.from(urls).includes('/db/thang.type/anya/version')).toBeTruthy();
    });

    it('loads components for the hero in the heroConfig in the given session', function() {
      const levelLoader = new LevelLoader({supermodel:new SuperModel(), sessionID: 'id', levelID: 'id'});
      levelLoader.sessionDependenciesRegistered = {};
      const session = new LevelSession(sessionWithAnyaWithGloves);
      levelLoader.loadDependenciesForSession(session);
      const responses = {
        '/db/thang.type/anya/version': thangTypeAnyaWithJumpsComponent
      };
      jasmine.Ajax.requests.sendResponses(responses);
      const requests = jasmine.Ajax.requests.all();
      const urls = (Array.from(requests).map((r) => r.url));
      return expect(Array.from(urls).includes('/db/level.component/jumps/version/0')).toBeTruthy();
    });

    return it('is idempotent', function() {
      const levelLoader = new LevelLoader({supermodel:new SuperModel(), sessionID: 'id', levelID: 'id'});

      // first load Tharin by the 'normal' session load
      let responses = {'/db/level/id': levelWithOgreWithMace};
      jasmine.Ajax.requests.sendResponses(responses);
      responses = {'/db/level.session/id': sessionWithTharinWithHelmet};
      jasmine.Ajax.requests.sendResponses(responses);

      // then try to load Tharin some more
      const session = new LevelSession(sessionWithTharinWithHelmet);
      levelLoader.loadDependenciesForSession(session);
      const numRequestsBefore = jasmine.Ajax.requests.count();
      levelLoader.loadDependenciesForSession(session);
      levelLoader.loadDependenciesForSession(session);
      const numRequestsAfter = jasmine.Ajax.requests.count();
      return expect(numRequestsAfter).toBe(numRequestsBefore);
    });
  });

  it('loads thangs for items that the level thangs have in their Equips component configs', function() {
    let supermodel;
    new LevelLoader({supermodel:(supermodel = new SuperModel()), sessionID: 'id', levelID: 'id'});

    const responses = {
      '/db/level/id': levelWithOgreWithMace
    };

    jasmine.Ajax.requests.sendResponses(responses);
    const requests = jasmine.Ajax.requests.all();
    const urls = (Array.from(requests).map((r) => r.url));
    return expect(Array.from(urls).includes('/db/thang.type/mace/version?project=name,components,original,rasterIcon,kind,prerenderedSpriteSheetData')).toBeTruthy();
  });

  it('loads components which are inherited by level thangs from thang type default components', function() {
    new LevelLoader({supermodel:new SuperModel(), sessionID: 'id', levelID: 'id'});

    const responses = {
      '/db/level/id': levelWithOgreWithMace,
      '/db/thang.type/names': [thangTypeOgreWithPhysicalComponent]
    };

    jasmine.Ajax.requests.sendResponses(responses);
    const requests = jasmine.Ajax.requests.all();
    const urls = (Array.from(requests).map((r) => r.url));
    return expect(Array.from(urls).includes('/db/level.component/physical/version/0')).toBeTruthy();
  });

  it('loads item thang types which are inherited by level thangs from thang type default equips component configs', function() {
    new LevelLoader({supermodel:new SuperModel(), sessionID: 'id', levelID: 'id'});

    const responses = {
      '/db/level/id': levelWithShaman,
      '/db/thang.type/names': [thangTypeShamanWithWandEquipped]
    };

    jasmine.Ajax.requests.sendResponses(responses);
    const requests = jasmine.Ajax.requests.all();
    const urls = (Array.from(requests).map((r) => r.url));
    return expect(Array.from(urls).includes('/db/thang.type/wand/version?project=name,components,original,rasterIcon,kind,prerenderedSpriteSheetData')).toBeTruthy();
  });

  return it('loads components for item thang types which are inherited by level thangs from thang type default equips component configs', function() {
    new LevelLoader({supermodel:new SuperModel(), sessionID: 'id', levelID: 'id'});

    const responses = {
      '/db/level/id': levelWithShaman,
      '/db/thang.type/names': [thangTypeShamanWithWandEquipped],
      '/db/thang.type/wand/version?project=name,components,original,rasterIcon,kind': thangTypeWand
    };

    jasmine.Ajax.requests.sendResponses(responses);
    const requests = jasmine.Ajax.requests.all();
    const urls = (Array.from(requests).map((r) => r.url));
    return expect(Array.from(urls).includes('/db/level.component/poisons/version/0')).toBeTruthy();
  });
});
