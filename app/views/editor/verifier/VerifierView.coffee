utils = require 'core/utils'

RootView = require 'views/core/RootView'
template = require 'templates/editor/verifier/verifier-view'
VerifierTest = require './VerifierTest'
SuperModel = require 'models/SuperModel'

module.exports = class VerifierView extends RootView
  className: 'style-flat'
  template: template
  id: 'verifier-view'

  constructor: (options, @levelID) ->
    super options
    # TODO: sort tests by unexpected result first
    @passed = 0
    @failed = 0
    @problem = 0

    testLevels = [
      'dungeons-of-kithgard', 'gems-in-the-deep', 'shadow-guard', 'kounter-kithwise', 'crawlways-of-kithgard',
      'enemy-mine', 'illusory-interruption', 'forgetful-gemsmith', 'signs-and-portents', 'favorable-odds',
      'true-names', 'the-prisoner', 'banefire', 'the-raised-sword', 'kithgard-librarian', 'fire-dancing',
      'loop-da-loop', 'haunted-kithmaze', 'riddling-kithmaze', 'descending-further', 'the-second-kithmaze',
      'dread-door', 'cupboards-of-kithgard', 'hack-and-dash', 'known-enemy', 'master-of-names', 'lowly-kithmen',
      'closing-the-distance', 'tactical-strike', 'the-skeleton', 'a-mayhem-of-munchkins', 'the-final-kithmaze',
      'the-gauntlet', 'radiant-aura', 'kithgard-gates', 'destroying-angel', 'deadly-dungeon-rescue',
      'breakout', 'attack-wisely', 'kithgard-mastery', 'kithgard-apprentice', 'robot-ragnarok',
      'defense-of-plainswood', 'peasant-protection', 'forest-fire-dancing', 'course-winding-trail',
      'patrol-buster', 'endangered-burl', 'thumb-biter', 'gems-or-death', 'village-guard', 'thornbush-farm',
      'back-to-back', 'ogre-encampment', 'woodland-cleaver', 'shield-rush', 'range-finder', 'munchkin-swarm',
      'stillness-in-motion', 'the-agrippa-defense', 'backwoods-bombardier', 'coinucopia', 'copper-meadows',
      'drop-the-flag', 'mind-the-trap', 'signal-corpse', 'rich-forager',

      'the-mighty-sand-yak', 'oasis', 'sarven-road', 'sarven-gaps', 'thunderhooves', 'minesweeper',
      'medical-attention', 'sarven-sentry', 'keeping-time', 'hoarding-gold', 'decoy-drill', 'continuous-alchemy',
      'dust', 'desert-combat', 'sarven-savior', 'lurkers', 'preferential-treatment', 'sarven-shepherd',
      'shine-getter',

      'a-fine-mint', 'borrowed-sword', 'cloudrip-commander', 'crag-tag',
      'hunters-and-prey', 'hunting-party',
      'leave-it-to-cleaver', 'library-tactician', 'mad-maxer', 'mad-maxer-strikes-back',
      'mirage-maker', 'mixed-unit-tactics', 'mountain-mercenaries',
      'noble-sacrifice', 'odd-sandstorm', 'ogre-gorge-gouger', 'reaping-fire',
      'return-to-thornbush-farm', 'ring-bearer', 'sand-snakes',
      'slalom', 'steelclaw-gap', 'the-geometry-of-flowers',
      'the-two-flowers', 'timber-guard', 'toil-and-trouble', 'village-rover',
      'vital-powers', 'zoo-keeper',
    ]

    defaultCores = 2
    cores = Math.max(window.navigator.hardwareConcurrency, defaultCores)

    #testLevels = testLevels.slice 0, 15
    @linksQueryString = window.location.search
    @levelIDs = if @levelID then [@levelID] else testLevels
    languages = utils.getQueryVariable 'languages', 'python,javascript'
    #supermodel = if @levelID then @supermodel else undefined
    @tests = []
    @taskList = []
    @tasksList = _.flatten _.map @levelIDs, (v) ->
      # TODO: offer good interface for choosing which languages, better performance for skipping missing solutions
      #_.map ['python', 'javascript', 'coffeescript', 'lua'], (l) ->
      _.map languages.split(','), (l) ->
      #_.map ['javascript'], (l) ->
        level: v, language: l

    @testCount = @tasksList.length
    chunks = _.groupBy @tasksList, (v,i) -> i%cores
    supermodels = [@supermodel]

    _.forEach chunks, (chunk, i) =>
      _.delay =>
        parentSuperModel = supermodels[supermodels.length-1]
        chunkSupermodel = new SuperModel()
        chunkSupermodel.models = _.clone parentSuperModel.models
        chunkSupermodel.collections = _.clone parentSuperModel.collections
        supermodels.push chunkSupermodel

        async.eachSeries chunk, (task, next) =>
          test = new VerifierTest task.level, (e) =>
            @update(e)
            if e.state in ['complete', 'error', 'no-solution']
              if e.state is 'complete'
                if test.isSuccessful()
                  ++@passed
                else
                  ++@failed
              else if e.state is 'no-solution'
                --@testCount
              else
                ++@problem

              next()
          , chunkSupermodel, task.language
          @tests.unshift test
          @render()
        , => @render()
      , if i > 0 then 5000 + i * 1000 else 0

  update: (event) =>
    @render()
