SignupModalView = require 'views/modal/signup_modal'
View = require 'views/kinds/RootView'
{me} = require('lib/auth')
contributorSignupAnonymousTemplate = require 'templates/contribute/contributor_signup_anonymous'
contributorSignupTemplate = require 'templates/contribute/contributor_signup'
contributorListTemplate = require 'templates/contribute/contributor_list'

module.exports = class ContributeClassView extends View
  navPrefix: '/contribute'

  events:
    'change input[type="checkbox"]': 'onCheckboxChanged'

  getRenderData: ->
    c = super()
    c.navPrefix = @navPrefix
    c.contributors = @contributors
    c

  afterRender: ->
    super()
    @$el.find('.contributor-signup-anonymous').replaceWith(contributorSignupAnonymousTemplate(me: me))
    @$el.find('.contributor-signup').each ->
      context = me: me, contributorClassID: $(@).data('contributor-class-id'), contributorClassName: $(@).data('contributor-class-name')
      $(@).replaceWith(contributorSignupTemplate(context))
    @$el.find('#contributor-list').replaceWith(contributorListTemplate(contributors: @contributors, contributorClassName: @contributorClassName))

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

  contributors: []
