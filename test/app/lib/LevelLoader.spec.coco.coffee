Level = require 'models/Level'
LevelSession = require 'models/LevelSession'
SuperModel = require 'models/SuperModel'
LevelComponent = require 'models/LevelComponent'
LevelLoader = require 'lib/LevelLoader'

# LEVELS

levelWithOgreWithMace = {
  thangs: [{
    thangType: 'ogre'
    components: [{
      original: LevelComponent.EquipsID
      majorVersion: 0
      config: { inventory: { 'left-hand': 'mace' } }
    }]
  }]
}

levelWithShaman = {
  thangs: [{
    thangType: 'shaman'
  }]
}

levelWithShamanWithSuperWand = {
  thangs: [{
    thangType: 'shaman'
    components: [{
      original: LevelComponent.EquipsID
      majorVersion: 0
      config: { inventory: { 'left-hand': 'super-wand' } }
    }]
  }]
}

# SESSIONS

sessionWithTharinWithHelmet = { heroConfig: { thangType: 'tharin', inventory: { 'head': 'helmet' }}}

sessionWithAnyaWithGloves = { heroConfig: { thangType: 'anya', inventory: { 'head': 'gloves' }}}

# THANG TYPES

thangTypeOgreWithPhysicalComponent = {
  name: 'Ogre'
  original: 'ogre'
  components: [{
    original: 'physical'
    majorVersion: 0
  }]
}

thangTypeShamanWithWandEquipped = {
  name: 'Shaman'
  original: 'shaman'
  components: [{
    original: LevelComponent.EquipsID
    majorVersion: 0
    config: { inventory: { 'left-hand': 'wand' }}
  }]
}

thangTypeTharinWithHealsComponent = {
  name: 'Tharin'
  original: 'tharin'
  components: [{
    original: 'heals'
    majorVersion: 0
  }]
}

thangTypeWand = {
  name: 'Wand'
  original: 'wand'
  components: [{
    original: 'poisons'
    majorVersion: 0
  }]
}

thangTypeAnyaWithJumpsComponent = {
  name: 'Anya'
  original: 'anya'
  components: [{
    original: 'jumps'
    majorVersion: 0
  }]
}



describe 'LevelLoader', ->
  describe 'loadDependenciesForSession', ->
    it 'loads hero and item thang types from heroConfig in the given session', ->
      levelLoader = new LevelLoader({supermodel:new SuperModel(), sessionID: 'id', levelID: 'id'})
      levelLoader.sessionDependenciesRegistered = {}
      session = new LevelSession(sessionWithAnyaWithGloves)
      levelLoader.loadDependenciesForSession(session)
      requests = jasmine.Ajax.requests.all()
      urls = (r.url for r in requests)
      expect('/db/thang.type/gloves/version?project=name,components,original,rasterIcon,kind' in urls).toBeTruthy()
      expect('/db/thang.type/anya/version' in urls).toBeTruthy()

    it 'loads components for the hero in the heroConfig in the given session', ->
      levelLoader = new LevelLoader({supermodel:new SuperModel(), sessionID: 'id', levelID: 'id'})
      levelLoader.sessionDependenciesRegistered = {}
      session = new LevelSession(sessionWithAnyaWithGloves)
      levelLoader.loadDependenciesForSession(session)
      responses = {
        '/db/thang.type/anya/version': thangTypeAnyaWithJumpsComponent
      }
      jasmine.Ajax.requests.sendResponses(responses)
      requests = jasmine.Ajax.requests.all()
      urls = (r.url for r in requests)
      expect('/db/level.component/jumps/version/0' in urls).toBeTruthy()

    it 'is idempotent', ->
      levelLoader = new LevelLoader({supermodel:new SuperModel(), sessionID: 'id', levelID: 'id'})

      # first load Tharin by the 'normal' session load
      responses = '/db/level/id': levelWithOgreWithMace
      jasmine.Ajax.requests.sendResponses(responses)
      responses = '/db/level.session/id': sessionWithTharinWithHelmet
      jasmine.Ajax.requests.sendResponses(responses)

      # then try to load Tharin some more
      session = new LevelSession(sessionWithTharinWithHelmet)
      levelLoader.loadDependenciesForSession(session)
      numRequestsBefore = jasmine.Ajax.requests.count()
      levelLoader.loadDependenciesForSession(session)
      levelLoader.loadDependenciesForSession(session)
      numRequestsAfter = jasmine.Ajax.requests.count()
      expect(numRequestsAfter).toBe(numRequestsBefore)

  it 'loads thangs for items that the level thangs have in their Equips component configs', ->
    new LevelLoader({supermodel:supermodel = new SuperModel(), sessionID: 'id', levelID: 'id'})

    responses = {
      '/db/level/id': levelWithOgreWithMace
    }

    jasmine.Ajax.requests.sendResponses(responses)
    requests = jasmine.Ajax.requests.all()
    urls = (r.url for r in requests)
    expect('/db/thang.type/mace/version?project=name,components,original,rasterIcon,kind,prerenderedSpriteSheetData' in urls).toBeTruthy()

  it 'loads components which are inherited by level thangs from thang type default components', ->
    new LevelLoader({supermodel:new SuperModel(), sessionID: 'id', levelID: 'id'})

    responses =
      '/db/level/id': levelWithOgreWithMace
      '/db/thang.type/names': [thangTypeOgreWithPhysicalComponent]

    jasmine.Ajax.requests.sendResponses(responses)
    requests = jasmine.Ajax.requests.all()
    urls = (r.url for r in requests)
    expect('/db/level.component/physical/version/0' in urls).toBeTruthy()

  it 'loads item thang types which are inherited by level thangs from thang type default equips component configs', ->
    new LevelLoader({supermodel:new SuperModel(), sessionID: 'id', levelID: 'id'})

    responses =
      '/db/level/id': levelWithShaman
      '/db/thang.type/names': [thangTypeShamanWithWandEquipped]

    jasmine.Ajax.requests.sendResponses(responses)
    requests = jasmine.Ajax.requests.all()
    urls = (r.url for r in requests)
    expect('/db/thang.type/wand/version?project=name,components,original,rasterIcon,kind,prerenderedSpriteSheetData' in urls).toBeTruthy()

  it 'loads components for item thang types which are inherited by level thangs from thang type default equips component configs', ->
    new LevelLoader({supermodel:new SuperModel(), sessionID: 'id', levelID: 'id'})

    responses =
      '/db/level/id': levelWithShaman
      '/db/thang.type/names': [thangTypeShamanWithWandEquipped]
      '/db/thang.type/wand/version?project=name,components,original,rasterIcon,kind': thangTypeWand

    jasmine.Ajax.requests.sendResponses(responses)
    requests = jasmine.Ajax.requests.all()
    urls = (r.url for r in requests)
    expect('/db/level.component/poisons/version/0' in urls).toBeTruthy()
