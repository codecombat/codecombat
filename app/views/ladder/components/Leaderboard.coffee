LeaderboardComponent = require('./Leaderboard.vue').default
CocoView = require('views/core/CocoView')
store = require('core/store')
silentStore = { commit: _.noop, dispatch: _.noop }
CocoCollection = require 'collections/CocoCollection'

class TournamentLeaderboardCollection extends CocoCollection
  url: ''
  model: Tournament

  constructor: (tournamentId, options) ->
    super()
    @url = "/db/tournament/#{tournamentId}/rankings?#{$.param(options)}"



module.exports = class LeaderboardView extends CocoView
  id: 'ladder-tab-view'
  template: require('templates/play/ladder/leaderboard-view')
  VueComponent: LeaderboardComponent
  constructor: (options) ->
    { league, tournament } = options
    params = @collectionParameters(order: -1, scoreOffset: HIGHEST_SCORE, limit: @limit)
    @propsData = { @tableTitles, @rankings}
    super options

  render: ->
    super()
    @afterRender()
    @

  onLoaded: -> @render()

  afterRender: ->
    if @vueComponent
      @$el.find('#ladder-tab-view').replaceWith(@vueComponent.$el)
    else
      if @vuexModule
        unless _.isFunction(@vuexModule)
          throw new Error('@vuexModule should be a function')
        store.registerModule('page', @vuexModule())

      @vueComponent = new @VueComponent({
        el: @$el.find('#ladder-tab-view')[0]
        propsData: @propsData
        store
      })

    super(arguments...)

  destroy: ->
    if @vuexModule
      store.unregisterModule('page')
    @vueComponent.$destroy()
    @vueComponent.$store = silentStore
    # ignore all further changes to the store, since the module has been unregistered.
    # may later want to just ignore mutations and actions to the page module.

  refreshLadder: ->
    return