require('app/styles/editor/level/modal/save-branch-modal.sass')
ModalView = require 'views/core/ModalView'
template = require 'templates/editor/level/modal/save-branch-modal'
DeltaView = require 'views/editor/DeltaView'
deltasLib = require 'core/deltas'
modelDeltas = require 'lib/modelDeltas'
Branch = require 'models/Branch'
Branches = require 'collections/Branches'
LevelComponents = require 'collections/LevelComponents'
LevelSystems = require 'collections/LevelSystems'
modelDeltas = require 'lib/modelDeltas'


module.exports = class SaveBranchModal extends ModalView
  id: 'save-branch-modal'
  template: template
  modalWidthPercent: 99
  events:
    'click #save-branch-btn': 'onClickSaveBranchButton'
    'click #branches-list-group .list-group-item': 'onClickBranch'
    'click .delete-branch-btn': 'onClickDeleteBranchButton'
    'click #stash-branch-btn': 'onClickStashBranchButton'

  initialize: ({ @components, @systems }) ->
    # Should be given all loaded, up to date systems and components with existing changes
    
    # Create a list of components and systems we'll be saving a branch for
    @componentsWithChanges = new LevelComponents(@components.filter((c) -> c.hasLocalChanges()))
    @systemsWithChanges = new LevelSystems(@systems.filter((c) -> c.hasLocalChanges()))
    
    # Load existing branches
    @branches = new Branches()
    @branches.fetch({url: '/db/branches'})
    .then(=>
      
      # Load any patch target we don't already have
      fetches = []
      for branch in @branches.models
        for patch in branch.get('patches') or []
          collection = if patch.target.collection is 'level_component' then @components else @systems
          model = collection.get(patch.target.id)
          if not model
            model = new collection.model({ _id: patch.target.id })
            fetches.push(model.fetch())
            model.once 'sync', -> @markToRevert()
            collection.add(model)
      return $.when(fetches...)
      
    ).then(=>
      
      # Go through each branch and make clones of patch targets, with patches applied, so we can show the deltas
      for branch in @branches.models
        branch.components = new Backbone.Collection()
        branch.systems = new Backbone.Collection()
        for patch in branch.get('patches') or []
          patch.id = _.uniqueId()
          if patch.target.collection is 'level_component'
            allModels = @components
            changedModels = branch.components
          else
            allModels = @systems
            changedModels = branch.systems
          model = allModels.get(patch.target.id).clone(false)
          model.markToRevert()
          modelDeltas.applyDelta(model, patch.delta)
          changedModels.add(model)
      @selectedBranch = @branches.first()
      @render()
    )

  afterRender: ->
    super()
    @renderSelectedBranch()
    
    # insert all the Delta views for the systems/components which will form the branch
    changeEls = @$el.find('.component-changes-stub')
    for changeEl in changeEls
      componentId = $(changeEl).data('component-id')
      component = @componentsWithChanges.find((c) -> c.id is componentId)
      @insertDeltaView(component, changeEl)

    changeEls = @$el.find('.system-changes-stub')
    for changeEl in changeEls
      systemId = $(changeEl).data('system-id')
      system = @systemsWithChanges.find((c) -> c.id is systemId)
      @insertDeltaView(system, changeEl)
      
  insertDeltaView: (model, changeEl, headModel) ->
    try
      deltaView = new DeltaView({model: model, headModel, skipPaths: deltasLib.DOC_SKIP_PATHS})
      @insertSubView(deltaView, $(changeEl))
      return deltaView
    catch e
      console.error 'Couldn\'t create delta view:', e
        
  renderSelectedBranch: ->
    # insert delta subviews for the selected branch, including the 'headComponent' which shows
    # what, if any, conflicts the existing branch has with the client's local changes
    
    @removeSubView(view) for view in @selectedBranchDeltaViews if @selectedBranchDeltaViews
    @selectedBranchDeltaViews = []
    @renderSelectors('#selected-branch-col')
    changeEls = @$el.find('#selected-branch-col .component-changes-stub')
    for changeEl in changeEls
      componentId = $(changeEl).data('component-id')
      component = @selectedBranch.components.get(componentId)
      targetComponent = @components.find((c) -> c.get('original') is component.get('original') and c.get('version').isLatestMajor)
      preBranchSave = component.clone()
      preBranchSave.markToRevert()
      componentDiff = targetComponent.clone()
      preBranchSave.set(componentDiff.attributes)
      @selectedBranchDeltaViews.push(@insertDeltaView(preBranchSave, changeEl))

    changeEls = @$el.find('#selected-branch-col .system-changes-stub')
    for changeEl in changeEls
      systemId = $(changeEl).data('system-id')
      system = @selectedBranch.systems.get(systemId)
      targetSystem = @systems.find((c) -> c.get('original') is system.get('original') and c.get('version').isLatestMajor)
      preBranchSave = system.clone()
      preBranchSave.markToRevert()
      systemDiff = targetSystem.clone()
      preBranchSave.set(systemDiff.attributes)
      @selectedBranchDeltaViews.push(@insertDeltaView(preBranchSave, changeEl))

  onClickBranch: (e) ->
    $(e.currentTarget).closest('.list-group').find('.active').removeClass('active')
    $(e.currentTarget).addClass('active')
    branchCid = $(e.currentTarget).data('branch-cid')
    @selectedBranch = if branchCid then @branches.get(branchCid) else null
    @renderSelectedBranch()

  onClickStashBranchButton: (e) ->
    @saveBranch(e, {deleteSavedChanges: true})

  onClickSaveBranchButton: (e) ->
    @saveBranch(e, {deleteSavedChanges: false})

  saveBranch: (e, {deleteSavedChanges}) ->
    if @selectedBranch
      branch = @selectedBranch
    else
      name = @$('#new-branch-name-input').val()
      if not name
        return noty text: 'Name required', layout: 'topCenter', type: 'error', killer: false
      slug = _.string.slugify(name)
      if @branches.findWhere({slug})
        return noty text: 'Name taken', layout: 'topCenter', type: 'error', killer: false
      branch = new Branch({name})
    
    patches = []
    toRevert = []
    selectedComponents = _.map(@$('.component-checkbox:checked'), (checkbox) => @componentsWithChanges.get($(checkbox).data('component-id')))
    for component in selectedComponents
      patches.push(modelDeltas.makePatch(component).toJSON())
      toRevert.push(component)
    
    selectedSystems = _.map(@$('.system-checkbox:checked'), (checkbox) => @systemsWithChanges.get($(checkbox).data('system-id')))
    for system in selectedSystems
      patches.push(modelDeltas.makePatch(system).toJSON())
      toRevert.push(system)
    branch.set({patches})
    jqxhr = branch.save()
    button = $(e.currentTarget)
    if not jqxhr
      return button.text('Save Failed (validation error)')
      
    button.attr('disabled', true).text('Saving...')
    Promise.resolve(jqxhr)
    .then =>
      if deleteSavedChanges
        model.revert() for model in toRevert
      @hide()
    .catch (e) =>
      button.attr('disabled', false).text('Save Failed (network/runtime error)')
      throw e

  onClickDeleteBranchButton: (e) ->
    e.preventDefault()
    e.stopImmediatePropagation()
    branchCid = $(e.currentTarget).closest('.list-group-item').data('branch-cid')
    branch = @branches.get(branchCid)
    return unless confirm('Really delete this branch?')
    branch.destroy()
    @branches.remove(branch)
    if branch is @selectedBranch
      @selectedBranch = null
      @renderSelectedBranch()
    $(e.currentTarget).closest('.list-group-item').remove()
