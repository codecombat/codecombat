RootView = require 'views/core/RootView'
template = require 'templates/editor/verifier/verifier-view'
VerifierTest = require './VerifierTest'

module.exports = class VerifierView extends RootView
  className: 'style-flat'
  template: template
  id: 'verifier-view'

  constructor: (options, @levelID) ->
    super options
    # TODO: rework to handle N at a time instead of all at once
    # TODO: sort tests by unexpected result first
    @passed = 0
    @failed = 0
    testLevels = ["dungeons-of-kithgard", "gems-in-the-deep", "shadow-guard", "kounter-kithwise", "crawlways-of-kithgard", "enemy-mine", "illusory-interruption", "forgetful-gemsmith", "signs-and-portents", "favorable-odds", "true-names", "the-prisoner", "banefire", "the-raised-sword", "kithgard-librarian", "fire-dancing", "loop-da-loop", "haunted-kithmaze", "riddling-kithmaze", "descending-further", "the-second-kithmaze", "dread-door", "cupboards-of-kithgard", "hack-and-dash", "known-enemy", "master-of-names", "lowly-kithmen", "closing-the-distance", "tactical-strike", "the-skeleton", "a-mayhem-of-munchkins", "the-final-kithmaze", "the-gauntlet", "radiant-aura", "kithgard-gates", "destroying-angel", "deadly-dungeon-rescue", "kithgard-brawl", "cavern-survival", "breakout", "attack-wisely", "kithgard-mastery", "kithgard-apprentice", "robot-ragnarok", "defense-of-plainswood", "peasant-protection", "forest-fire-dancing"]
    #testLevels = testLevels.slice 0, 15
    @levelIDs = if @levelID then [@levelID] else testLevels
    @testCount = @levelIDs.length * 2 #One per langauge
    #supermodel = if @levelID then @supermodel else undefined
    @tests = []
    async.eachSeries @levelIDs, (levelID, lnext) =>
      async.eachSeries ['python','javascript'], (lang, next) =>
        test = new VerifierTest levelID, (e) =>

          @update(e)
          if e.state in ['complete', 'error']
            if test.isSucessful()
              ++@passed
            else
              ++@failed
            next()
        , @supermodel, lang
        @tests.unshift test
      , -> lnext()
    , () => @render()
  update: (event) =>
    # TODO: show unworkable tests instead of hiding them
    # TODO: destroy them Tests after or something
    console.log 'got event', event, 'on some test'
    @tests = _.filter @tests, (test) -> test.state isnt 'error'
    @render()