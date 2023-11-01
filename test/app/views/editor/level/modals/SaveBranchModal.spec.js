factories = require 'test/app/factories'
SaveBranchModal = require 'views/editor/level/modals/SaveBranchModal'
LevelComponents = require 'collections/LevelComponents'
LevelSystems = require 'collections/LevelSystems'
modelDeltas = require 'lib/modelDeltas'

makeBranch = (attrs={}, {systems, components}) ->
  branch = new Branch(attrs)
  patches = []
  for component in components.models
    patches.push(modelDeltas.makePatch(component).toJSON())
  for system in systems.models
    patches.push(modelDeltas.makePatch(system).toJSON())
  branch.set({patches})
  return branch

describe 'SaveBranchModal', ->
  it 'saves a new branch with all local changes to systems and components', (done) ->
    
    # a couple that don't have changes
    component = factories.makeLevelComponent({name: 'Unchanged Component'})
    system = factories.makeLevelSystem({name: 'Unchanged System'})
    
    # a couple with changes
    changedComponent = factories.makeLevelComponent({name: 'Changed Component'})
    changedSystem = factories.makeLevelSystem({name: 'Changed System'})
    changedComponent.markToRevert()
    changedComponent.set('description', 'new description')
    changedSystem.markToRevert()
    changedSystem.set('description', 'also a new description')
    
    # a component with history
    componentV0 = factories.makeLevelComponent({
      name: 'Versioned Component'
      version: {
        major: 0
        minor: 0
        isLatestMajor: false
        isLatestMinor: false
      }
    })
    componentV1 = factories.makeLevelComponent({
      name: 'Versioned Component', 
      original: componentV0.get('original'),
      description:'Recent description change'
      version: {
        major: 0
        minor: 1
        isLatestMajor: true
        isLatestMinor: true
      }
    })
    componentV0Changed = componentV0.clone()
    componentV0Changed.markToRevert()
    componentV0Changed.set({name: 'Unconflicting change', description: 'Conflicting change'})
    
    modal = new SaveBranchModal({ 
      components: new LevelComponents([component, changedComponent, componentV1]),
      systems: new LevelSystems([changedSystem, system])
    })
    jasmine.demoModal(modal)
    jasmine.Ajax.requests.mostRecent().respondWith({
      status: 200,
      responseText: JSON.stringify([
        { 
          name: 'First Branch',
          patches: [
            modelDeltas.makePatch(componentV0Changed).toJSON()
          ]
          updatedBy: me.id
          updatedByName: 'Myself'
          updated: moment().subtract(1, 'day').toISOString()
        }
        {
          name: 'Newer Branch By Someone Else'
          updatedBy: _.uniqueId('user_')
          updatedByName: 'Someone Else'
          updated: moment().subtract(5, 'hours').toISOString()
        }
        {
          name: 'Older Branch By Me'
          updatedBy: me.id
          updatedByName: 'Myself'
          updated: moment().subtract(2, 'days').toISOString()
        }
        {
          name: 'Older Branch By Someone Else'
          updatedBy: _.uniqueId('user_')
          updatedByName: 'Someone Else'
          updated: moment().subtract(1, 'week').toISOString()
        }
      ])
    })
    _.defer =>
      componentRequest = jasmine.Ajax.requests.mostRecent()
      expect(componentRequest.url).toBe(componentV0.url())
      componentRequest.respondWith({
        status: 200,
        responseText: JSON.stringify(componentV0.toJSON())
      })
      modal.$('#branches-list-group input').val('Branch Name')
      modal.$('#save-branch-btn').click()
      saveBranchRequest = jasmine.Ajax.requests.mostRecent()
      expect(saveBranchRequest.url).toBe('/db/branches')
      expect(saveBranchRequest.method).toBe('POST')
      body = JSON.parse(saveBranchRequest.params)
      expect(body.patches.length).toBe(2)
      targetIds = _.map(body.patches, (patch) -> patch.id)
      expect(_.contains(targetIds, changedComponent.id))
      expect(_.contains(targetIds, changedSystem.id))
      done()
