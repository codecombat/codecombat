NewModelModal = require 'views/modal/NewModelModal'
template = require 'templates/editor/level/modal/new-achievement'
forms = require 'lib/forms'
Achievement = require 'models/Achievement'

module.exports = class NewAchievementModal extends NewModelModal
  id: 'new-achievement-modal'
  template: template
  plain: false

  constructor: (options) ->
    super options
    @level = options.level

  getRenderData: ->
    c = super()
    c.level = @level
    console.debug 'level', c.level
    c

  createQuery: ->
    checked = @$el.find('[name=queryOptions]:checked')
    checkedValues = ($(check).val() for check in checked)
    subQueries = []
    for id in checkedValues
      switch id
        when 'misc-level-completion'
          subQueries.push state: complete: true
        else # It's a goal
          q = state: goalStates: {}
          q.state.goalStates[id] = {}
          q.state.goalStates[id].status = 'success'
          subQueries.push q
    unless subQueries.length
      query = {}
    else if subQueries.length is 1
      query = subQueries[0]
    else
      query = $or: subQueries
    query['level.original'] = @level.get 'original'
    query

  makeNewModel: ->
    achievement = new Achievement
    name = @$el.find('#name').val()
    description = @$el.find('#description').val()
    query = @createQuery()

    achievement.set 'name', name
    achievement.set 'description', description
    achievement.set 'query', query
    achievement.set 'collection', 'level.sessions'
    achievement.set 'userField', 'creator'
    achievement.set 'related', @level.get('original')

    achievement
