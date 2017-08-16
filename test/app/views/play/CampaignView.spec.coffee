factories = require 'test/app/factories'
CampaignView = require 'views/play/CampaignView'
Levels = require 'collections/Levels'

describe 'CampaignView', ->

  describe 'when 4 earned levels', ->
    beforeEach ->
      @campaignView = new CampaignView()
      @campaignView.levelStatusMap = {}
      levels = new Levels(_.times(4, -> factories.makeLevel()))
      @campaignView.campaign = factories.makeCampaign({}, {levels})
      @levels = (level.toJSON() for level in levels.models)
      earned = me.get('earned') or {}
      earned.levels ?= []
      earned.levels.push(level.original) for level in @levels
      me.set('earned', earned)

    describe 'and 3rd one is practice in classroom only', ->
      beforeEach ->
        # Not named "Level Name [ABCD]", so not actually a practice level in home version.
        @levels[2].practice = true
        @campaignView.annotateLevels(@levels)
      it 'does not hide the not-really-practice level', ->
        expect(@levels[2].hidden).toEqual(false)
        expect(@levels[3].hidden).toEqual(false)

    describe 'and 2nd rewards a practice a non-practice level', ->
      beforeEach ->
        @campaignView.levelStatusMap[@levels[0].slug] = 'complete'
        @campaignView.levelStatusMap[@levels[1].slug] = 'complete'
        @levels[1].rewards = [{level: @levels[2].original}, {level: @levels[3].original}]
        @levels[2].practice = true
        @levels[2].name += ' A'
        @levels[2].slug += '-a'
        @campaignView.annotateLevels(@levels)
        @campaignView.determineNextLevel(@levels)
      it 'points at practice level first', ->
        expect(@levels[2].next).toEqual(true)
        expect(@levels[3].next).not.toBeDefined(true)
