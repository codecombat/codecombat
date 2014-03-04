View = require 'views/kinds/RootView'
template = require 'templates/play'

module.exports = class PlayView extends View
  id: "play-view"
  template: template

  getRenderData: (context={}) ->
    context = super(context)
    context.home = true
    context.notFound = @getQueryVariable 'not_found'
    tutorials = [
      {
        name: 'Rescue Mission'
        id: 'rescue-mission'
        description: "Tharin has been captured!"
        image: '/file/db/level/52740644904ac0411700067c/rescue_mission_icon.png'
        difficulty: 1
      }
      {
        name: 'Grab the Mushroom'
        difficulty: 1
        image: '/file/db/level/529662dfe0df8f0000000007/grab_the_mushroom_icon.png'
        id: 'grab-the-mushroom'
        description: "Grab a powerup and smash a big ogre."
      }
      {
        name: 'Drink Me'
        difficulty: 1
        image: '/file/db/level/525dc5589a0765e496000006/drink_me_icon.png'
        id: 'drink-me'
        description: "Drink up and slay two munchkins."
      }
      {
        name: 'Taunt the Guards'
        difficulty: 1
        image: '/file/db/level/5276c9bdcf83207a2801ff8f/taunt_icon.png'
        id: 'taunt-the-guards'
        description: "Tharin, if clever, can escape with Phoebe."
      }
      {
        name: "It's a Trap"
        difficulty: 1
        image: '/file/db/level/528aea2d7f37fc4e0700016b/its_a_trap_icon.png'
        id: 'its-a-trap'
        description: "Organize a dungeon ambush with archers."
      }
      {
        name: 'Break the Prison'
        difficulty: 1
        image: '/file/db/level/5275272c69abdcb12401216e/break_the_prison_icon.png'
        id: 'break-the-prison'
        description: "More comrades are imprisoned!"
      }
      {
        name: 'Taunt'
        difficulty: 1
        image: '/file/db/level/525f150306e1ab0962000018/taunt_icon.png'
        id: 'taunt'
        description: "Taunt the ogre to claim victory."
      }
      {
        name: 'Cowardly Taunt'
        difficulty: 1
        image: '/file/db/level/525abfd9b12777d78e000009/cowardly_taunt_icon.png'
        id: 'cowardly-taunt'
        description: "Lure infuriated ogres to their doom."
      }
      {
        name: 'Commanding Followers'
        difficulty: 1
        image: '/file/db/level/525ef8ef06e1ab0962000003/commanding_followers_icon.png'
        id: 'commanding-followers'
        description: "Lead allied soldiers into battle."
      }
      {
        name: 'Mobile Artillery'
        difficulty: 1
        image: '/file/db/level/525085419851b83f4b000001/mobile_artillery_icon.png'
        id: 'mobile-artillery'
        description: "Blow ogres up!"
      }
    ]

    experienced = [
      {
        name: 'Hunter Triplets'
        id: 'hunter-triplets'
        description: "Three soldiers go ogre hunting."
        image: '/file/db/level/526711d9add4f8965f000002/hunter_triplets_icon.png'
        difficulty: 2
      }
      {
        name: 'Emphasis on Aim'
        difficulty: 2
        image: '/file/db/level/525f384d96cd77000000000f/munchkin_masher_icon.png'
        id: 'emphasis-on-aim'
        description: "Chose your targets carefully."
      }
      {
        name: 'Zone of Danger'
        id: 'zone-of-danger'
        description: "Target the ogres swarming into arrow range."
        image: '/file/db/level/526ae95c1e5cd30000000008/zone_of_danger_icon.png'
        difficulty: 3
      }
      {
        name: 'Molotov Medic'
        difficulty: 2
        image: '/file/db/level/52602ecb026e8481e7000001/generic_1.png'
        id: 'molotov-medic'
        description: "Tharin must play support in this dungeon battle."
      }
#      {
#        name: 'The Herd'
#        id: 'the-herd'
#        description: "Stop an ogre stampede with deadly artillery."
#        image: '/images/generic-icon.png'
#        difficulty: 3
#        disabled: true
#      }
      {
        name: 'Gridmancer'
        id: 'gridmancer'
        description: "Challenge! Beat this level, get a job!"
        image: '/file/db/level/52ae2460ef42c52f13000008/gridmancer_icon.png'
        difficulty: 5
      }
    ]

#    arenas = [
#      {
#        name: 'Forest Arena'
#        difficulty: 3
#        id: 'forest-arena'
#        image: '/images/levels/forest_arena_icon.png'
#        description: "Play head-to-head against friends!"
#        disabled: true
#      }
#    ]

    playerCreated = [
      {
        name: 'Extra Extrapolation'
        difficulty: 2
        id: 'extra-extrapolation'
        image: '/file/db/level/526bda3fe79aefde2a003e36/mobile_artillery_icon.png'
        description: "Predict your target's position for deadly aim. - by Sootn"
      }
      {
        name: 'The Right Route'
        difficulty: 1
        id: 'the-right-route'
        image: '/file/db/level/526fd3043c637ece50001bb2/the_herd_icon.png'
        description: "Strike at the weak point in an array of enemies. - by Aftermath"
      }
      {
        name: 'Bubble Sort Bootcamp Battle'
        difficulty: 3
        id: 'bubble-sort-bootcamp-battle'
        image: '/file/db/level/525ef8ef06e1ab0962000003/commanding_followers_icon.png'
        description: "Write a bubble sort to organize your soldiers. - by Alexandru"
      }
      {
        name: 'Enemy Artillery'
        difficulty: 1
        id: 'enemy-artillery'
        image: '/file/db/level/526dba94a188322044000a40/mobile_artillery_icon.png'
        description: "Take cover while shells fly, then strike! - by mcdavid1991"
        disabled: true
      }
    ]

    context.campaigns = [
      {id: "beginner", name: "Beginner Campaign", description: "... in which you learn the wizardry of programming.", levels: tutorials}
      {id: "dev", name: "Random Harder Levels", description: "... in which you learn the interface while doing something a little harder.", levels: experienced}
#      {id: "multiplayer", name: "Multiplayer Arenas", description: "... in which you code head-to-head against other players.", levels: arenas}
      {id: "player_created", name: "Player-Created", description: "... in which you battle against the creativity of your fellow <a href=\"/contribute#artisan\">Artisan Wizards</a>.", levels: playerCreated}
    ]

    context

  afterRender: ->
    super()
    @$el.find('.modal').on 'shown.bs.modal', ->
      $('input:visible:first', @).focus()
