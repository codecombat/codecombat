RootComponent = require 'views/core/RootComponent'

# template = require 'templates/base-flat'

pets = [
  { name: 'Raven', canFly: true, hasFur: false, color: 'black' }
  { name: 'Wolf', canFly: false, hasFur: true, color: 'grey' }
]

petProperties = {}

for pet in pets
  for key in _.keys(pet)
    continue if key is 'name'
    petProperties[key] ?= []
    petProperties[key].push(pet[key])
    petProperties[key] =  _.unique(petProperties[key])

# console.log "petProperties", petProperties

baseRoundTime = 10

ConditionalMinigameComponent = Vue.extend
  template: require('templates/minigames/conditional-minigame-component')()
  data: -> {
    property: ''
    operator: '=='
    value: null
    pet: {}
    answeredCorrectly: null
    intervalID: null
    roundStartTime: null
    roundEndTime: null
    nextRoundStart: null
    secondsUntilNextRound: 0
    age: null
    lastTick: null
    score: {
      total: 0
      correct: 0
      incorrect: 0
    }
    gameOver: false
  }
  methods: {
    setupRound: ->
      @property = _.sample(_.keys(petProperties))
      @value = _.sample(petProperties[@property])
      @pet = _.sample(pets)
      @answeredCorrectly = null
      @roundStartTime = moment()
      @roundEndAt = baseRoundTime
      @age = 0
      @nextRoundStart = null
      @secondsUntilNextRound = 0
      @dt = 0
      @gameOver = false

    playerAnswered: (answer, event) ->
      return if @nextRoundStart
      @answeredCorrectly = (answer is 'if') == (@pet[@property] is @value)
      @doAnswer @answeredCorrectly

    doAnswer: (correct=false) ->
      @score.total++
      if correct
        @score.correct++
      else
        @score.incorrect++
      @nextRoundStart = @age + 3
      @secondsUntilNextRound = 3


    startGameLoop: ->
      return if @intervalID
      @intervalID = setInterval( (() => @update()) , 100)

    stopGameLoop: ->
      return unless @intervalID
      clearInterval(@intervalID)
      @intervalID = null

    update: ->
      @dt = if @lastTick then moment().diff(@lastTick) / 1000 else 0
      @age = moment().diff(@roundStartTime) / 1000

      if @nextRoundStart
        if @score.total >= 10
          # For now, end the game after 10 rounds.
          @endGame()
        if @age > @nextRoundStart
          @setupRound()
      else if @age > @roundEndAt
        @doAnswer(false) unless @answeredCorrectly

      @secondsUntilNextRound = Math.max(0, @secondsUntilNextRound - @dt)
      @lastTick = moment()

    endGame: ->
      @stopGameLoop()
      @gameOver = true

  }
  created: ->
    @setupRound()
    @startGameLoop()

module.exports = class ConditionalMinigameView extends RootComponent
  id: 'conditional-minigame-view'
  template: -> '<div><div id="site-content-area"></div></div>'
  className: 'style-flat'
  VueComponent: ConditionalMinigameComponent
  # vuexModule: -> { }
