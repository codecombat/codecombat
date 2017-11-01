require('app/styles/editor/level/modal/load-branch-modal.sass')
ModalView = require 'views/core/ModalView'
template = require 'templates/editor/level/modal/load-branch-modal'
DeltaView = require 'views/editor/DeltaView'
deltasLib = require 'core/deltas'
modelDeltas = require 'lib/modelDeltas'
Branch = require 'models/Branch'
Branches = require 'collections/Branches'
LevelComponents = require 'collections/LevelComponents'
LevelSystems = require 'collections/LevelSystems'


module.exports = class LoadBranchModal extends ModalView
  id: 'load-branch-modal'
  template: template
  modalWidthPercent: 99
  events:
    'click #load-branch-btn': 'onClickLoadBranchButton'
    'click #unstash-branch-btn': 'onClickUnstashBranchButton'
    'click #branches-list-group .list-group-item': 'onClickBranch'
    'click .delete-branch-btn': 'onClickDeleteBranchButton'
    

  initialize: ({ @components, @systems }) ->
    # Should be given all loaded, up to date systems and components with existing changes
    
    # Load existing branches
    @branches = new Branches()
    @branches.fetch({url: '/db/branches'})
    .then(=>
      @selectedBranch = @branches.first()
      
      # Load any patch target we don't already have
      fetches = []
      for branch in @branches.models
        for patch in branch.get('patches')
          collection = if patch.target.collection is 'level_component' then @components else @systems
          model = collection.get(patch.target.id)
          if not model
            model = new collection.model({ _id: patch.target.id })
            fetches.push(model.fetch())
            model.once 'sync', -> @markToRevert()
            collection.add(model)
      return $.when(fetches...)
      
    ).then(=>

      # Go through each branch and figure out what their patch statuses are
      for branch in @branches.models
        for patch in branch.get('patches')
          patch.id = _.uniqueId()
          collection = if patch.target.collection is 'level_component' then @components else @systems

          # make a model that represents what the patch represented when it was made
          originalChange = collection.get(patch.target.id).clone(false)
          originalChange.markToRevert()
          modelDeltas.applyDelta(originalChange, patch.delta)
          
          # make a model that represents what will change locally
          currentModel = collection.find (model) -> _.all([
            model.get('original') is patch.target.original,
            model.get('version').isLatestMajor
          ])
          postLoadChange = currentModel.clone()
          postLoadChange.markToRevert() # includes whatever local changes we have now
          
          toApply = currentModel.clone(false)
          applied = modelDeltas.applyDelta(toApply, patch.delta)
          if applied
            postLoadChange.set(toApply.attributes)
            for key in postLoadChange.keys()
              if not toApply.has(key)
                postLoadChange.unset(key)
            # now postLoadChange has current state -> future state
          
          # properties used in rendering and loading
          _.assign(patch, {
            # the original target with patch applied
            originalChange
            
            # the current target with local changes removed and patch applied (if successful)
            # Whether the patch was applied or not, this is how the model will be after loading
            postLoadChange
            
            # whether applying the patch to the current target was successful
            applied
            
            # so we can label this part of the patch as overwriting local changes
            currentModelHasLocalChanges: currentModel.hasLocalChanges()
            
            # so we can label changes being applied to a newer version of the model
            modelHasChangedSincePatchCreated: originalChange.id isnt currentModel.id
            
            # the target model as it was passed into the modal, unchanged
            currentModel
          })
    ).then(=> @render())
    
  afterRender: ->
    super()
    @renderSelectedBranch()

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
    return unless @selectedBranch
    for patch in @selectedBranch.get('patches')
      originalChangeEl = @$(".changes-stub[data-patch-id='#{patch.id}'][data-prop='original-change']")
      @insertDeltaView(patch.originalChange, originalChangeEl)
      postLoadChangeEl = @$(".changes-stub[data-patch-id='#{patch.id}'][data-prop='post-load-change']")
      @insertDeltaView(patch.postLoadChange, postLoadChangeEl)
    
  onClickBranch: (e) ->
    $(e.currentTarget).closest('.list-group').find('.active').removeClass('active')
    $(e.currentTarget).addClass('active')
    branchCid = $(e.currentTarget).data('branch-cid')
    @selectedBranch = @branches.get(branchCid)
    @renderSelectedBranch()

  onClickUnstashBranchButton: (e) ->
    @loadBranch({deleteBranch: true})

  onClickLoadBranchButton: (e) ->
    @loadBranch({deleteBranch: false})

  loadBranch: ({deleteBranch}) ->
    selectedBranch = @$('#branches-list-group .active')
    branchCid = selectedBranch.data('branch-cid')
    branch = @branches.get(branchCid)
    for patch in branch.get('patches')
      continue if not patch.applied
      { currentModel, postLoadChange } = patch
      
      currentModel.set(postLoadChange.attributes)
      for key in currentModel.keys()
        if not postLoadChange.has(key)
          currentModel.unset(key)
    if deleteBranch
      Promise.resolve(branch.destroy()).catch((e) => noty text: 'Failed to delete branch after unstashing', layout: 'topCenter', type: 'error', killer: false)
    @hide()

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
