View = require 'views/kinds/RootView'
module.exports = class ContributeClassView extends View

  {me} = require('lib/auth')
  
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
    subscriptions = me.get('emailSubscriptions') ? []
    if checked and not (subscription in subscriptions)
      subscriptions.push(subscription)
      if me.get 'anonymous'
        @openModalView new SignupModalView()
    if not checked
      subscriptions = _.without subscriptions, subscription
    el.parent().find('.saved-notification').finish().show('fast').delay(3000).fadeOut(2000)

    me.set('emailSubscriptions', subscriptions)
    me.save()