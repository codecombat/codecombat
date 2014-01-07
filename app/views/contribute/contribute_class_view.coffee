SignupModalView = require 'views/modal/signup_modal'
View = require 'views/kinds/RootView'
{me} = require('lib/auth')

module.exports = class ContributeClassView extends View
  navPrefix: '/contribute'

  events:
    'change input[type="checkbox"]': 'onCheckboxChanged'

  getRenderData: ->
    c = super()
    c.navPrefix = @navPrefix
    c

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
