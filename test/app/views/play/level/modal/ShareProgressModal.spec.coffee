ShareProgressModal = require 'views/play/modal/ShareProgressModal'
Course = require 'models/Course'
Level = require 'models/Level'
LevelSession = require 'models/LevelSession'
Achievements = require 'collections/Achievements'

describe 'ShareProgressModal', ->
  beforeEach ->
    me.clear()
  
  describe 'continue button in other languages', ->
    modal = null

    beforeEach (done) ->
      # Not sure why this isn't affecting the modal. Do I need to load the locale file?
      me.set('preferredLanguage', 'es-ES')
      # Can position testing be done? These values are zeros at runtime
      modal = new ShareProgressModal()
      modal.render()
      _.defer done
      
    xit 'should be positioned high enough', ->
      jasmine.demoModal(modal)
      link = modal.$('.continue-link')
      linkBottom = link.offset().top + link.height()
      background = modal.$('.background-img')
      backgroundBottom = background.offset().top + background.height()
      expect(linkBottom).toBeLessThan(backgroundBottom - 30)

    it '(demo)', -> jasmine.demoModal(modal)
