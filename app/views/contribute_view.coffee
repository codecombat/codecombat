View = require 'views/kinds/RootView'
template = require 'templates/contribute'
{me} = require('lib/auth')

module.exports = class ContributeView extends View
  id: "contribute-view"
  template: template

  events:
    'change input[type="checkbox"]': 'onCheckboxChanged'

  afterRender: ->
    super()
    checkboxes = @$el.find('input[type="checkbox"]').toArray()
    _.forEach checkboxes, (el) ->
      el = $(el)
      if el.attr('name') in me.get('emailSubscriptions')
        el.prop('checked', true)

  onCheckboxChanged: (e) ->
    el = $(e.target)
    checked = el.prop('checked')
    subscription = el.attr('name')
    subscriptions = me.get('emailSubscriptions')
    if checked and not (subscription in subscriptions)
      subscriptions.push(subscription)
    if not checked
      subscriptions = _.without subscriptions, subscription

    me.set('emailSubscriptions', subscriptions)
    me.save()
