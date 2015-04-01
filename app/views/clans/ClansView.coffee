app = require 'core/application'
RootView = require 'views/core/RootView'
template = require 'templates/clans/clans'
CocoCollection = require 'collections/CocoCollection'
Clan = require 'models/Clan'

module.exports = class MainAdminView extends RootView
  id: 'clans-view'
  template: template

  events:
    'click .create-clan-btn': 'onClickCreateClan'

  constructor: (options) ->
    super options
    @publicClans = new CocoCollection([], { url: '/db/clan', model: Clan, comparator:'_id' })
    @supermodel.loadCollection(@publicClans, 'public_clans', {cache: false})

  getRenderData: ->
    context = super()
    context.publicClans = @publicClans.models
    context.myClans = @publicClans.where({ownerID: me.get('_id')})
    context.myClanIDs = _.map context.myClans, (c) -> c.id
    context

  onClickCreateClan: (e) ->
    if name = $('.create-clan-name').val()
      # TODO: async creating message
      clan = new Clan()
      clan.set 'type', 'public'
      clan.set 'name', name
      clan.save {},
        error: (model, response, options) =>
          console.error 'Error saving clan', response
        success: (model, response, options) =>
          app.router.navigate "/clans/#{model.id}"
          window.location.reload()
    else
      # TODO: Invalid name message
      console.log 'Invalid name'
