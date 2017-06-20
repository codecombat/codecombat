RootComponent = require 'views/core/RootComponent'

# template = require 'templates/base-flat'

pets = [
  { name: 'Raven', canFly: true, hasFur: false, color: 'black', imageSrc: '/images/pages/minigames/conditionals/raven.png'}
  { name: 'Wolf', canFly: false, hasFur: true, color: 'grey', imageSrc: '/images/pages/minigames/conditionals/wolf.png' }
  { name: 'Fox', canFly: false, hasFur: true, color: 'blue', imageSrc: '/images/pages/minigames/conditionals/fox.png' }
  { name: 'Bear', canFly: false, hasFur: true, color: 'white', imageSrc: '/images/pages/minigames/conditionals/bear.png' }
  { name: 'Rat', canFly: false, hasFur: true, color: 'brown', imageSrc: '/images/pages/minigames/conditionals/rat.jpg' }
  { name: 'Dog', canFly: false, hasFur: true, color: 'tan', imageSrc: '/images/pages/minigames/conditionals/dog.png' }
]

ogreImageSrc = '/images/pages/minigames/conditionals/ogre.png'
gemImageSrc = '/images/pages/minigames/conditionals/gem.png'

petProperties = {}

for pet in pets
  for key in _.keys(pet)
    continue if key in ['name', 'imageSrc']
    petProperties[key] ?= []
    petProperties[key].push(pet[key])
    petProperties[key] =  _.unique(petProperties[key])

# console.log "petProperties", petProperties

baseRoundTime = 10

ConditionalMinigameComponent = Vue.extend
  template: require('templates/minigames/conditional-minigame-component')()
  data: -> {
    intro: true
    property: ''
    operator: '=='
    value: null
    pet: {}
    answeredCorrectly: null
    answer: ''
    intervalID: null
    roundStartTime: null
    nextRoundStart: null
    age: null
    lastTick: null
    score: {
      total: 0
      correct: 0
      incorrect: 0
    }
    rounds: []
    gameOver: false
    maxRounds: 10
  }
  computed: {
    animalTop: -> if @answer is 'else' then '200px' else '10px'
    animalLeft: -> 
      roundPercent = @age / @roundEndAt
      if @answer
        return '650px'
      else if roundPercent > 1
        return '25%'
      else
        roundPercent*25 +'%'
    ifAnswerImage: -> if @correctAnswer is 'if' then gemImageSrc else ogreImageSrc
    elseAnswerImage: -> if @correctAnswer is 'else' then gemImageSrc else ogreImageSrc
    correctAnswer: -> if @pet[@property] is @value then 'if' else 'else'

  }
  methods: {
    setupRound: ->
      @property = _.sample(_.keys(petProperties))
      @value = _.sample(petProperties[@property])
      @pet = _.sample(pets)
      @answeredCorrectly = null
      @answer = ''
      @roundStartTime = moment()
      @roundEndAt = baseRoundTime
      @age = 0
      @nextRoundStart = null
      @dt = 0

    playerAnswered: (answer, event) ->
      return if @nextRoundStart
      @answer = answer
      @answeredCorrectly = answer is @correctAnswer
      @doAnswer @answeredCorrectly

    doAnswer: (correct=false) ->
      @score.total++
      if correct
        @score.correct++
      else
        @score.incorrect++
      @nextRoundStart = @age + 1
      @rounds.push  { correct: correct, imgSrc: if correct then gemImageSrc else ogreImageSrc } 
      @playSound correct

    playSound: (correct) ->
      sound = if correct then @$refs.gemSound else @$refs.ogreSound
      sound.play()

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
        if @score.total >= @maxRounds
          # For now, end the game after 10 rounds.
          @endGame()
        if @age > @nextRoundStart
          @setupRound()
      else if @age > @roundEndAt
        @doAnswer(false) unless @answeredCorrectly

      @lastTick = moment()

    endGame: ->
      @stopGameLoop()
      @gameOver = true

    startGame: ->
      @intro = false
      @setupRound()
      @gameOver = false
      @rounds = []
      @score = { total: 0, correct: 0, incorrect: 0 }
      @startGameLoop()

  }
  created: ->
    @intro = true
    @property = _.sample(_.keys(petProperties))
    @value = _.sample(petProperties[@property])
    @pet = _.sample(pets)


module.exports = class ConditionalMinigameView extends RootComponent
  id: 'conditional-minigame-view'
  template: -> '<div><div id="site-content-area"></div></div>'
  className: 'style-flat'
  VueComponent: ConditionalMinigameComponent
  # vuexModule: -> { }
