<template lang="pug">
  .content#minigame-content

    .left-column
      audio(src='/sounds/pages/minigames/conditionals/gem_pickup.mp3' ref="gemSound")
      audio(src='/sounds/pages/minigames/conditionals/ogre_munchkin_raah.mp3' ref="ogreSound")
      audio(src='/sounds/pages/minigames/conditionals/firetrap_die.mp3' ref="trapSound")

      .header.text-center
        h1 Pet Dilemma!

      .game-progress
        div(v-for="round in rounds")
          img(v-bind:src="round.imgSrc")
        div(v-for="r in maxRounds - rounds.length")
          span x


      .path(v-bind:class="{ exploded: exploded }")
        .intro(v-if="intro")
          div.help#intro-if
            | Click this button if the conditional is TRUE
            =" "
            span.glyphicon.glyphicon-arrow-right
          div.help#intro-else
            | Click this button if the conditional is FALSE
            =" "
            span.glyphicon.glyphicon-arrow-right
          div.help#intro-conditional
            | This is the conditional
            =" "
            span.glyphicon.glyphicon-arrow-right
          div.help#intro-properties
            //- span.glyphicon.glyphicon-arrow-down
            //- =" "
            | Properties of the pet

        .trap
          img.trap-image(v-bind:src="trapImageSrc")
        .pet(v-bind:style="{ top: animalTop, left: animalLeft }")
          img.pet-image(v-bind:src="pet.imageSrc")
        .if-conditional
          code if {{property}} {{operator}} {{JSON.stringify(value)}}
        .else-conditional
          code else
        .choice.if-path
          //- button.btn.btn-primary.btn-lg(v-on:click="playerAnswered('if', $event)" v-bind:class="{ disabled: nextRoundStart || gameOver }") ?

          button.btn.btn-primary.btn-lg(v-on:click="playerAnswered('if', $event)" v-if="!answer && !nextRoundStart" v-bind:class="{ disabled: nextRoundStart || gameOver || intro}") ?
          img.answer-image(v-bind:src="ifAnswerImage" v-else)

        .choice.else-path
          button.btn.btn-primary.btn-lg(v-on:click="playerAnswered('else', $event)" v-if="!answer && !nextRoundStart" v-bind:class="{ disabled: nextRoundStart || gameOver || intro}") ?
          img.answer-image(v-bind:src="elseAnswerImage" v-else)

        .properties
          ul
            li(v-for="(val, key) in pet" v-if="key != 'imageSrc'")
              code {{key}}
              = ": "
              code {{JSON.stringify(val)}}


      .score(v-if="gameOver")
        h3 You got {{score.correct}} correct out of {{score.total}}!
          button.btn.btn-primary.btn-lg(v-on:click="startGame()") Play Again!

    .right-column
      .intro
        h2  Help the lost pets find their way out of the forest!

        p A
          strong conditional statement
          | is a branch in the path your code takes.
        p The path the code chooses to take depends on whether or not the condition is true.
        p If it is true, the code takes the "if" path.
        p Otherwise, the code takes the "else" path.
        button.btn.btn-primary.btn-lg(v-on:click="startGame()" v-if="intro") Play!

</template>

<script lang="coffee">

# RootComponent = require 'views/core/RootComponent'

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
trapImageSrc = '/images/pages/minigames/conditionals/fire_trap.png'

petProperties = {}

for pet in pets
  for key in _.keys(pet)
    continue if key in ['name', 'imageSrc']
    petProperties[key] ?= []
    petProperties[key].push(pet[key])
    petProperties[key] =  _.unique(petProperties[key])

# console.log "petProperties", petProperties

baseRoundTime = 10

module.exports = Vue.extend
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
    trapImageSrc: trapImageSrc
    exploded: false
  }
  computed: {
    animalTop: ->
      if @answer is 'if'
        return '60px'
      if @answer is 'else'
        return '300px'
      return '200px'
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
      @exploded = false

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
      imgSrc = if correct then gemImageSrc else (if @answer is '' then trapImageSrc else ogreImageSrc)
      @exploded = (not correct and @answer is '')
      @rounds.push  { correct: correct, imgSrc: imgSrc }
      @playSound correct

    playSound: (correct) ->
      sound = if correct then @$refs.gemSound else (if @answer is '' then @$refs.trapSound else @$refs.ogreSound)
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

</script>

<style lang="sass">
@import "app/styles/style-flat-variables"

#minigame-content

  min-height: 100vh

  .left-column
    width: 900px

  .right-column
    position: absolute
    left: 900px
    top: 0px
    width: 400px
    padding: 10px
    margin-top: 60px
    text-align: left


  div.intro

    h2
      font-weight: bold

    .help
      background-color: red
      color: white
      padding: 2px 10px
      border-radius: 10px
      position: absolute

    #intro-if
      top: 172px
      right: 120px
    #intro-else
      top: 410px
      right: 120px
    #intro-conditional
      top: 96px
      left: 120px
    #intro-properties
      top: 420px
      left: 5px

  div.game-progress
    padding-left: 100px
    padding-bottom: 10px
    div
      margin-left: 20px
      text-align: center
      display: inline-block
      width: 40px
      height: 40px
    img
      height: 40px
      width: 40px

  @keyframes wigglyWobblyAnim
    10%, 90%
      transform: translate3d(-1px, 0, 0)
    20%, 80%
      transform: translate3d(2px, 0, 0)
    30%, 50%, 70%
      transform: translate3d(-4px, 0, 0)
    40%, 60%
      transform: translate3d(4px, 0, 0)

  div.path.exploded
    animation: wigglyWobblyAnim 1s cubic-bezier(.36,.07,.19,.97) infinite both
    transform: translate3d(0, 0, 0)
    backface-visibility: hidden
    // perspective: 1000px

  div.path
    position: relative
    background-color: #aaffaa
    height: 600px
    width: 900px
    background-image: url("/images/pages/minigames/conditionals/forked-path.jpg")
    background-size: 110% 100%
    background-position: top 2px left -91px

    .trap
      position: absolute
      top: 280px
      left: 280px

    .pet
      position: absolute
      img
        width: 100px
        max-height: 120px

    .if-conditional
      font-size: 150%
      position: absolute
      left: 350px
      top: 95px

    .else-conditional
      font-size: 150%
      position: absolute
      left: 350px
      top: 322px


    .choice
      position: absolute
      right: 10px

      button
        width: 100px
        height: 100px
        font-size: 40px
        box-shadow: 10px 10px 10px 0px rgba(0,0,0,0.75)
        border: 2px solid black
        // border-radius: 10px

      &.if-path
        top: 106px
      &.else-path
        top: 345px

      img.answer-image
        height: 100px

    div.properties
      position: absolute
      bottom: 10px
      left: 10px

      ul
        background-color: white
        border-radius: 2px
        padding-left: 10px
      li
        list-style-type: none

  .score
    width: 900px
    text-align: center

    button
      margin-left: 10px



</style>
