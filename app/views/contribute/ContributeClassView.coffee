CreateAccountModal = require 'views/core/CreateAccountModal'
RootView = require 'views/core/RootView'
{me} = require 'core/auth'
contributorSignupAnonymousTemplate = require 'templates/contribute/contributor_signup_anonymous'
contributorSignupTemplate = require 'templates/contribute/contributor_signup'
contributorListTemplate = require 'templates/contribute/contributor_list'

module.exports = class ContributeClassView extends RootView

  events:
    'change input[type="checkbox"]': 'onCheckboxChanged'

  afterRender: ->
    super()
    @$el.find('.contributor-signup-anonymous').replaceWith(contributorSignupAnonymousTemplate(me: me))
    @$el.find('.contributor-signup').each ->
      context = me: me, contributorClassName: $(@).data('contributor-class-name')
      $(@).replaceWith(contributorSignupTemplate(context))
    @$el.find('#contributor-list').replaceWith(contributorListTemplate(contributors: @contributors, contributorClassName: @contributorClassName))

    checkboxes = @$el.find('input[type="checkbox"]').toArray()
    _.forEach checkboxes, (el) ->
      el = $(el)
      el.prop('checked', true) if me.isEmailSubscriptionEnabled(el.attr('name')+'News')

  onCheckboxChanged: (e) ->
    el = $(e.target)
    checked = el.prop('checked')
    subscription = el.attr('name')

    me.setEmailSubscription subscription+'News', checked
    me.patch()
    @openModalView new CreateAccountModal() if me.get 'anonymous'
    el.parent().find('.saved-notification').finish().show('fast').delay(3000).fadeOut(2000)
