RootView = require 'views/core/RootView'
template = require 'templates/admin/pending-patches-view'
CocoCollection = require 'collections/CocoCollection'
Patch = require 'models/Patch'

class PendingPatchesCollection extends CocoCollection
  url: '/db/patch?view=pending'
  model: Patch

module.exports = class PendingPatchesView extends RootView
  id: 'pending-patches-view'
  template: template

  constructor: (options) ->
    super options
    @nameMap = {}
    @patches = @supermodel.loadCollection(new PendingPatchesCollection(), 'patches', {cache: false}).model

  onLoaded: ->
    super()
    @loadUserNames()
    @loadAllModelNames()

  getRenderData: ->
    c = super()
    c.patches = []
    if @supermodel.finished()
      comparator = (m) -> m.target.collection + ' ' + m.target.original
      patches = _.sortBy (_.clone(patch.attributes) for patch in @patches.models), comparator
      c.patches = _.uniq patches, comparator
      for patch in c.patches
        patch.creatorName = @nameMap[patch.creator] or patch.creator
        if name = @nameMap[patch.target.original]
          patch.name = name
          patch.slug = _.string.slugify name
          patch.url = '/editor/' + switch patch.target.collection
            when 'level', 'achievement', 'article', 'campaign', 'poll'
              "#{patch.target.collection}/#{patch.slug}"
            when 'thang_type'
              "thang/#{patch.slug}"
            when 'level_system', 'level_component'
              "level/items?#{patch.target.collection}=#{patch.slug}"
            when 'course'
              "course/#{patch.slug}"
            else
              console.log "Where do we review a #{patch.target.collection} patch?"
              ''
    c

  loadUserNames: ->
    # Only fetch the names for the userIDs we don't already have in @nameMap
    ids = []
    for patch in @patches.models
      unless id = patch.get('creator')
        console.error 'Found bad user ID in malformed patch', patch
        continue
      ids.push id unless @nameMap[id]
    ids = _.uniq ids
    return unless ids.length

    success = (nameMap) =>
      return if @destroyed
      for patch in @patches.models
        creatorID = patch.get 'creator'
        continue if @nameMap[creatorID]
        creator = nameMap[creatorID]
        name = creator?.name
        name ||= creator.firstName + ' ' + creator.lastName if creator?.firstName
        name ||= "Anonymous #{creatorID.substr(18)}" if creator
        name ||= '<bad patch data>'
        if name.length > 21
          name = name.substr(0, 18) + '...'
        @nameMap[creatorID] = name
      @render()

    userNamesRequest = @supermodel.addRequestResource 'user_names', {
      url: '/db/user/-/names'
      data: {ids: ids}
      method: 'POST'
      success: success
    }, 0
    userNamesRequest.load()

  loadAllModelNames: ->
    allPatches = (p.attributes for p in @patches.models)
    allPatches = _.groupBy allPatches, (p) -> p.target.collection
    @loadCollectionModelNames collection, patches for collection, patches of allPatches

  loadCollectionModelNames: (collection, patches) ->
    ids = (patch.target.original for patch in patches when not @nameMap[patch.target.original])
    ids = _.uniq ids
    return unless ids.length
    success = (nameMapArray) =>
      return if @destroyed
      nameMap = {}
      for model, modelIndex in nameMapArray
        unless model
          console.warn "No model found for id #{ids[modelIndex]}"
          continue
        nameMap[model.original or model._id] = model.name
      for patch in patches
        original = patch.target.original
        name = nameMap[original]
        if name and name.length > 60
          name = name.substr(0, 57) + '...'
        @nameMap[original] = name
      @render()

    modelNamesRequest = @supermodel.addRequestResource 'patches', {
      url: "/db/#{collection.replace('_', '.')}/names"
      data: {ids: ids}
      method: 'POST'
      success: success
    }, 0
    modelNamesRequest.load()
