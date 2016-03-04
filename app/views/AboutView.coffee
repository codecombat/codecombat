RootView = require 'views/core/RootView'
template = require 'templates/about'

module.exports = class AboutView extends RootView
  id: 'about-view'
  template: template

  logoutRedirectURL: false

  events:
    'click #mission-link': 'onClickMissionLink'
    'click #team-link': 'onClickTeamLink'
    'click #community-link': 'onClickCommunityLink'
    'click #story-link': 'onClickStoryLink'
    'click #jobs-link': 'onClickJobsLink'
    'click #contact-link': 'onClickContactLink'
    'click .screen-thumbnail': 'onClickScreenThumbnail'
    'click #carousel-left': 'onLeftPressed'
    'click #carousel-right': 'onRightPressed'

  shortcuts:
    'right': 'onRightPressed'
    'left': 'onLeftPressed'
    'esc': 'onEscapePressed'

  afterRender: ->
    super(arguments...)
    @$('#fixed-nav').affix({
      offset:
        top: ->
          $('#nav-container').offset().top
    })
    #TODO: Maybe cache top value between page resizes to save CPU
    $('body').scrollspy(
      target: '#nav-container'
      offset: 150
    )
    @$('#screenshot-lightbox').modal()

    @$('#screenshot-carousel').carousel({
      interval: 0
      keyboard: false
    })

  onClickMissionLink: (event) ->
    event.preventDefault()
    @scrollToLink('#mission')

  onClickTeamLink: (event) ->
    event.preventDefault()
    @scrollToLink('#team')

  onClickCommunityLink: (event) ->
    event.preventDefault()
    @scrollToLink('#community')

  onClickStoryLink: (event) ->
    event.preventDefault()
    @scrollToLink('#story')

  onClickJobsLink: (event) ->
    event.preventDefault()
    @scrollToLink('#jobs')

  onClickContactLink: (event) ->
    event.preventDefault()
    @scrollToLink('#contact')

  onRightPressed: (event) ->
    # Special handling, otherwise after you click the control, keyboard presses move the slide twice
    return if event.type is 'keydown' and $(document.activeElement).is('.carousel-control')
    if $('#screenshot-lightbox').data('bs.modal')?.isShown
      event.preventDefault()
      $('#screenshot-carousel').carousel('next')

  onLeftPressed: (event) ->
    return if event.type is 'keydown' and $(document.activeElement).is('.carousel-control')
    if $('#screenshot-lightbox').data('bs.modal')?.isShown
      event.preventDefault()
      $('#screenshot-carousel').carousel('prev')

  onEscapePressed: (event) ->
    if $('#screenshot-lightbox').data('bs.modal')?.isShown
      event.preventDefault()
      $('#screenshot-lightbox').modal('hide')

  onClickScreenThumbnail: (event) ->
    unless $('#screenshot-lightbox').data('bs.modal')?.isShown
      event.preventDefault()
      # Modal opening happens automatically from bootstrap
      $('#screenshot-carousel').carousel($(event.currentTarget).data("index"))
