factories = require 'test/app/factories'
LoadBranchModal = require 'views/editor/level/modals/LoadBranchModal'
LevelComponents = require 'collections/LevelComponents'
LevelSystems = require 'collections/LevelSystems'
modelDeltas = require 'lib/modelDeltas'

describe 'LoadBranchModal', ->
  it 'loads branch patches into local systems and components', (done) ->
    
    patches = []
    
    # CASE 0: no changes
    component = factories.makeLevelComponent({name: 'Unchanged'})
    system = factories.makeLevelSystem({name: 'Unchanged System'})
    
    # CASE 1: changes that will be applied no problem
    componentFine = factories.makeLevelComponent({name: 'BasicCase'})
    componentFine.markToRevert()
    componentFine.set('description', 'Adding a description')
    patches.push modelDeltas.makePatch(componentFine).toJSON()
    componentFine.revert()
    
    # CASE 2: there are existing local changes to the component that will be overwritten
    componentOverwrite = factories.makeLevelComponent({name: 'OverWriting'})
    componentOverwrite.markToRevert()
    componentOverwrite.set('description', 'Adding a description')
    patches.push modelDeltas.makePatch(componentOverwrite).toJSON()

    componentOverwrite.revert()
    componentOverwrite.set('searchStrings', 'unrelated setting that will be overwritten')
    componentOverwrite.set('description', 'local change to description that will be overwritten')
    
    # CASE 3: we're applying changes to an old version, but the patch will still work
    componentOldVersion = factories.makeLevelComponent({name: 'OldVersion'})
    componentOldVersion.markToRevert()
    componentOldVersion.set('description', 'Change that should make it')
    patches.push modelDeltas.makePatch(componentOldVersion).toJSON()

    # the new version (without changes) will be given to the modal...
    componentNewVersion = componentOldVersion.clone(false)
    componentNewVersion.set({
      _id: _.uniqueId('new_version')
      'version': {
        major: 0
        minor: 1
        isLatestMajor: true
        isLatestMinor: true
      }
      system: 'ai' # unconflicting change
    })
    componentNewVersion.markToRevert() # make it as if it was loaded from the db, unchanged
    
    # ... and the old version (also without changes) will be loaded separately
    componentOldVersion.revert()
    componentOldVersion.set('version', {
      major: 0
      minor: 0
      isLatestMajor: false
      isLatestMinor: false
    })
    componentOldVersion.markToRevert()
    
    # CASE 4: The delta could not be applied
    componentOldWillFailVersion = factories.makeLevelComponent({
      name: 'ErrorCausingChangesVersion'
      dependencies: [{
        majorVersion: 0
        original: '1234'
      }]
    })
    componentOldWillFailVersion.markToRevert()
    componentOldWillFailVersion.set('dependencies', [{
      majorVersion: 1 # patch will show majorVersion going from 0 to 1
      original: '1234'
    }])
    patches.push modelDeltas.makePatch(componentOldWillFailVersion).toJSON()
    
    # the new version which will break when the patch is applied is given to the modal...
    componentNewWillFailVersion = componentOldWillFailVersion.clone(false)
    componentNewWillFailVersion.set({
      _id: _.uniqueId('new_version')
      'version': {
        major: 0
        minor: 1
        isLatestMajor: true
        isLatestMinor: true
      }
      dependencies: null # conflicting change, won't be able to apply change to dependency subdoc
    })
    componentNewWillFailVersion.markToRevert()
    
    # ... and the old version (also without changes) will be loaded separately
    componentOldWillFailVersion.revert()
    componentOldWillFailVersion.set('version', {
      major: 0
      minor: 0
      isLatestMajor: false
      isLatestMinor: false
    })
    componentOldWillFailVersion.markToRevert()
    
    branch = {
      name: 'First Branch'
      patches
      updatedBy: me.id
      updatedByName: 'Author name'
      updated: moment().subtract(1, 'day').toISOString()
    }
    
    components = new LevelComponents([component, componentFine, componentOverwrite, componentNewVersion, componentNewWillFailVersion])
    modal = new LoadBranchModal({ 
      components: components
      systems: new LevelSystems([system])
    })
    jasmine.demoModal(modal)
    jasmine.Ajax.requests.mostRecent().respondWith({
      status: 200,
      responseText: JSON.stringify([branch])
    })
    
    _.defer =>
      # handle requests for components which were targeted by patches but not given to the modal
      requests = jasmine.Ajax.requests.all()
      
      willWorkComponentRequest = _.find(requests, (r) -> _.string.endsWith(r.url, componentOldVersion.id))
      willWorkComponentRequest.respondWith({
        status: 200
        responseText: JSON.stringify(componentOldVersion.toJSON())
      })

      willNotWorkComponentRequest = _.find(requests, (r) -> _.string.endsWith(r.url, componentOldWillFailVersion.id))
      willNotWorkComponentRequest.respondWith({
        status: 200
        responseText: JSON.stringify(componentOldWillFailVersion.toJSON())
      })

      expect(componentFine.get('description')).toBeUndefined()
      expect(componentOverwrite.get('searchStrings')).toBe('unrelated setting that will be overwritten')
      expect(componentOverwrite.get('description')).toBe('local change to description that will be overwritten')
      expect(componentNewVersion.get('system')).toBe('ai')
      
      unexpectedChanges = 0
      component.on('change', -> unexpectedChanges++)
      componentNewWillFailVersion.on('change', -> unexpectedChanges++)
      modal.hide = _.noop # so it doesn't close for demos
      modal.$('#load-branch-btn').click()
      
      # case 0 (unchanged component) and case 4 (cannot apply patch): no changes!
      expect(unexpectedChanges).toBe(0)

      # case 1: definition should be changed
      expect(componentFine.get('description')).toBe('Adding a description')
      
      # case 2: search strings and the description which were local, unsaved changes, have been removed
      expect(componentOverwrite.get('searchStrings')).toBeUndefined()
      expect(componentOverwrite.get('description')).toBe('Adding a description')
      
      # case 3: the changes from v0 -> v1 should remain, and the patch to v0 are applied
      expect(componentNewVersion.get('system')).toBe('ai')
      expect(componentNewVersion.get('description')).toBe('Change that should make it')
      done()
