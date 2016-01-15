NewModelModal = require 'views/editor/modal/NewModelModal'
template = require 'templates/editor/level/modal/new-achievement'
forms = require 'core/forms'
Achievement = require 'models/Achievement'

module.exports = class NewAchievementModal extends NewModelModal
  id: 'new-achievement-modal'
  template: template
  plain: false

  events:
    'click #save-new-achievement-link': 'onAchievementSubmitted'

  constructor: (options) ->
    super options
    @level = options.level

  onAchievementSubmitted: (e) ->
    slug = _.string.slugify @$el.find('#name').val()
    url = "/editor/achievement/#{slug}"
    window.open url, '_blank'

  createQuery: ->
    checked = @$el.find('[name=queryOptions]:checked')
    checkedValues = ($(check).val() for check in checked)
    query = {}
    for id in checkedValues
      switch id
        when 'misc-level-completion'
          query['state.complete'] = true
        else
          query["state.goalStates.#{id}.status"] = 'success'
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
