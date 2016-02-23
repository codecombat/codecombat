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
    
  onClickMissionLink: ->
    @scrollToLink('#mission')
    
  onClickTeamLink: ->
    @scrollToLink('#team')
    
  onClickCommunityLink: ->
    @scrollToLink('#community')
    
  onClickStoryLink: ->
    @scrollToLink('#story')
    
  onClickJobsLink: ->
    @scrollToLink('#jobs')
    
  onClickContactLink: ->
    @scrollToLink('#contact')
    
