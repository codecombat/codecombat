RootView = require 'views/kinds/RootView'
waterfallLib = require 'test/demo/fixtures/waterfall'
librarianLib = require 'test/demo/fixtures/librarian'

class WebGLDemoView extends RootView
  template: -> '<canvas id="visible-canvas" width="1200" height="700" style="background: #ddd"><canvas id="invisible-canvas" width="0" height="0" style="display: none">'

  testMovieClipWithRasterizedSpriteChildren: ->
    # put two rasterized sprites into a movie clip and show that
    stage = new createjs.Stage(@$el.find('canvas')[0])
    createjs.Ticker.addEventListener "tick", stage

    child1Shape = new createjs.Shape(new createjs.Graphics().beginFill("#999999").drawCircle(30, 30, 30))
    child2Shape = new createjs.Shape(new createjs.Graphics().beginFill("#5a9cfb").drawCircle(50, 50, 30))
    builder = new createjs.SpriteSheetBuilder()
    builder.addFrame(child1Shape, {x:0, y:0, width: 200, height: 200})
    builder.addFrame(child2Shape, {x:0, y:0, width: 200, height: 200})
    sheet = builder.build()
    child1Sprite = new createjs.Sprite(sheet, 0)
    child2Sprite = new createjs.Sprite(sheet, 1)
    child2Sprite.stop()

    mc = new createjs.MovieClip(null, 0, true, {start: 20})
    stage.addChild mc
    mc.timeline.addTween createjs.Tween.get(child1Sprite).to(x: 0).to({x: 60}, 50).to({x: 0}, 50)
    mc.timeline.addTween createjs.Tween.get(child2Sprite).to(x: 60).to({x: 0}, 50).to({x: 60}, 50)
    mc.gotoAndPlay "start"

  testMovieClipWithEmptyObjectChildren: ->
    # See if I can have the movie clip animate empty objects so we have the properties in
    # an object that we can update our real sprites with
    stage = new createjs.Stage(@$el.find('#visible-canvas')[0])
    createjs.Ticker.addEventListener "tick", stage

    d1 = {}
    d2 = {}
    mc = new createjs.MovieClip(null, 0, true, {start: 20})
    stage.addChild mc
    mc.timeline.addTween createjs.Tween.get(d1).to(x: 0).to({x: 60}, 50).to({x: 0}, 50)
    mc.timeline.addTween createjs.Tween.get(d2).to(x: 60).to({x: 0}, 50).to({x: 60}, 50)
    mc.gotoAndPlay "start"
    window.d1 = d1
    window.d2 = d2

    f = ->
      console.log(JSON.stringify([d1, d2]))
    setInterval(f, 1000)
    # Seems to work. Can perhaps have the movieclip do the heavy lifting of moving containers around
    # and then copy the info over to individual sprites in a separate stage

  testWaterfallRasteredPerformance: ->
    # rasterize waterfall movieclip (this is what we do now)
    stage = new createjs.Stage(@$el.find('canvas')[0])
    createjs.Ticker.addEventListener "tick", stage

    builder = new createjs.SpriteSheetBuilder()
    waterfall = new waterfallLib.waterfallRed_JSCC()
    builder.addMovieClip(waterfall)
    t0 = new Date().getTime()
    sheet = builder.build()
    t1 = new Date().getTime()
    console.log "Time to build waterfall sprite sheet: #{t1-t0}ms"
    sprite = new createjs.Sprite(sheet, 'start')
    stage.addChild(sprite)

  test11: ->
    # Replace the Container constructors in the waterfall lib with a stub class
    # that will instead return our constructed sheet.
    stage = new createjs.Stage(@$el.find('canvas')[0])
    createjs.Ticker.addEventListener "tick", stage

    builder = new createjs.SpriteSheetBuilder()
    frames = []

    createClass = (frame) ->
      class Stub
        constructor: ->
          sprite = new createjs.Sprite(sheet, frame)
          sprite.stop()
          return sprite

    for name, klass of waterfallLib
      window.klass = klass
      continue if name is 'waterfallRed_JSCC'
      instance = new klass()
      builder.addFrame(instance, instance.nominalBounds)
      waterfallLib[name] = createClass(frames.length)
      frames.push frames.length

    t0 = new Date().getTime()
    sheet = builder.build()
    t1 = new Date().getTime()
    console.log "Time to build waterfall containers: #{t1-t0}ms"

    waterfall = new waterfallLib.waterfallRed_JSCC()
    stage.addChild(waterfall)
    @$el.append(sheet._images[0])
    @$el.find('canvas:last').css('background', '#aaf')
    @$el.find('canvas:last').css('width', '100%')
    window.stage = stage


  testMovieClipStageUpdatePerformance: ->
    # test how performant having a ton of movie clips is, removing the graphics part of it
    stage = new createjs.Stage(@$el.find('#invisible-canvas')[0])
    createjs.Ticker.addEventListener "tick", stage
    console.log 'fps', createjs.Ticker.getFPS()

    builder = new createjs.SpriteSheetBuilder()
    frames = []

    createClass = (frame) ->
      class Stub
        constructor: ->
          sprite = new createjs.Sprite(sheet, frame)
          sprite.stop()
          return sprite

    for name, klass of waterfallLib
      window.klass = klass
      continue if name is 'waterfallRed_JSCC'
      instance = new klass()
      builder.addFrame(instance, instance.nominalBounds)
      waterfallLib[name] = createClass(frames.length)
      frames.push frames.length

    sheet = builder.build()

    i = 0
    while i < 100
      i += 1
      waterfall = new waterfallLib.waterfallRed_JSCC()
      window.waterfall = waterfall
      waterfall.x = (i%10) * 10
      waterfall.y = i * 2
      stage.addChild(waterfall)
    window.stage = stage

    # (20FPS)
    # nothing going on: 1%
    # 20 waterfalls w/graphics: 25%
    # 100 waterfalls w/graphics: 90%
    # 100 waterfalls w/out graphics: 42%

    # these waterfalls have 20 containers in them, so you'd be able to update 2000 containers
    # at 20FPS using 42% CPU

  testAnimateWaterfallContainersWithMovieClip: ->
    invisibleStage = new createjs.Stage(@$el.find('#invisible-canvas')[0])
    visibleStage = new createjs.Stage(@$el.find('#visible-canvas')[0])
    createjs.Ticker.addEventListener "tick", invisibleStage

    builder = new createjs.SpriteSheetBuilder()
    frames = []

    createClass = (frame) ->
      class Stub
        constructor: ->
          sprite = new createjs.Sprite(sheet, frame)
          sprite.stop()
          return sprite

    for name, klass of waterfallLib
      window.klass = klass
      continue if name is 'waterfallRed_JSCC'
      instance = new klass()
      builder.addFrame(instance, instance.nominalBounds)
      waterfallLib[name] = createClass(frames.length)
      frames.push frames.length

    sheet = builder.build()

    waterfall = new waterfallLib.waterfallRed_JSCC()
    invisibleStage.addChild(waterfall)

    #visibleStage.children = waterfall.children # hoped this would work, but you need the ticker
    listener = {
      handleEvent: ->
        visibleStage.children = waterfall.children
        visibleStage.update()
    }
    createjs.Ticker.addEventListener "tick", listener

  testAnimateManyWaterfallContainersWithMovieClip: ->
    # Performance testing
    invisibleStage = new createjs.Stage(@$el.find('#invisible-canvas')[0])
    visibleStage = new createjs.SpriteStage(@$el.find('#visible-canvas')[0])
    createjs.Ticker.addEventListener "tick", invisibleStage
    listener = {
      handleEvent: ->
        for child, index in visibleStage.children
          child.children = invisibleStage.children[index].children
        visibleStage.update()
    }
    createjs.Ticker.addEventListener "tick", listener

    builder = new createjs.SpriteSheetBuilder()
    frames = []

    createClass = (frame) ->
      class SuperContainer extends createjs.Container
        constructor: ->
          sprite = new createjs.Sprite(sheet, frame)
          sprite.stop()
          return sprite

    for name, klass of waterfallLib
      window.klass = klass
      continue if name is 'waterfallRed_JSCC'
      instance = new klass()
      builder.addFrame(instance, instance.nominalBounds)
      waterfallLib[name] = createClass(frames.length)
      frames.push frames.length

    sheet = builder.build()

    i = 0
    while i < 100
      waterfall = new waterfallLib.waterfallRed_JSCC()
      window.waterfall = waterfall
      invisibleStage.addChild(waterfall)
      c = new createjs.SpriteContainer(sheet)
      c.x = (i%10) * 15
      c.y = i * 3
      visibleStage.addChild(c)
      i += 1

    window.visibleStage = visibleStage
    # About 45% with SpriteStage, over 100% with regular stage


  testAnimateSomeWaterfalls: ->
    # Performance testing
    invisibleStage = new createjs.Stage(@$el.find('#invisible-canvas')[0])
    visibleStage = new createjs.SpriteStage(@$el.find('#visible-canvas')[0])

    builder = new createjs.SpriteSheetBuilder()
    frames = []

    createClass = (frame) ->
      class SuperContainer extends createjs.Container
        constructor: ->
          sprite = new createjs.Sprite(sheet, frame)
          sprite.stop()
          return sprite

    for name, klass of waterfallLib
      continue if name is 'waterfallRed_JSCC'
      instance = new klass()
      builder.addFrame(instance, instance.nominalBounds)
      waterfallLib[name] = createClass(frames.length)
      frames.push frames.length

    sheet = builder.build()

    movieClips = []
    spriteContainers = []
    i = 0

    while i < 100
#      beStatic = false
      beStatic = i % 2
#      beStatic = true

      waterfall = new waterfallLib.waterfallRed_JSCC()
      if beStatic
        waterfall.gotoAndStop(0)
      else
        invisibleStage.addChild(waterfall)
      invisibleStage.addChild(waterfall)
      c = new createjs.SpriteContainer(sheet)
      c.x = (i%10) * 95
      c.y = i * 6
      c.scaleX = 0.3
      c.scaleY = 0.3
      visibleStage.addChild(c)

      movieClips.push(waterfall)
      spriteContainers.push(c)
      i += 1

    createjs.Ticker.addEventListener "tick", invisibleStage
    listener = {
      handleEvent: ->
        for child, index in spriteContainers
          child.children = movieClips[index].children
        visibleStage.update()
    }
    createjs.Ticker.addEventListener "tick", listener

    # All waterfalls animating: 50%
    # Stopping all waterfalls movieclips: 18%
    # Removing movieclips from the animation stage and just showing a static frame: 9%
    # Setting movie clip mode to SINGLE_FRAME and leaving them on the stage provides no performance improvement
    # Time to build 100 waterfalls: 223ms. Could experiment with pools, caching.
    # We would need a bunch of movieclips, one for each animation and sprite.


  testAnimateManyRasteredWaterfalls: ->
    # rasterize waterfall movieclip. It's so performant, the movie clips they take so much!
    stage = new createjs.SpriteStage(@$el.find('canvas')[0])
    createjs.Ticker.addEventListener "tick", stage

    builder = new createjs.SpriteSheetBuilder()
    waterfall = new waterfallLib.waterfallRed_JSCC()
    builder.addMovieClip(waterfall)
    sheet = builder.build()
    i = 0
    while i < 2000
      sprite = new createjs.Sprite(sheet, 'start')
      sprite.x = (i%20) * 45
      sprite.y = i * 0.23
      sprite.scaleX = 0.3
      sprite.scaleY = 0.3
      stage.addChild(sprite)
      i += 1


  testManualMovieClipUpdating: ->
    # Take control of the MovieClip directly, rather than using a separate stage
    visibleStage = new createjs.Stage(@$el.find('#visible-canvas')[0])

    builder = new createjs.SpriteSheetBuilder()
    frames = []

    createClass = (frame) ->
      class SuperContainer extends createjs.Container
        constructor: ->
          sprite = new createjs.Sprite(sheet, frame)
          sprite.stop()
          return sprite

    for name, klass of waterfallLib
      window.klass = klass
      continue if name is 'waterfallRed_JSCC'
      instance = new klass()
      builder.addFrame(instance, instance.nominalBounds)
      waterfallLib[name] = createClass(frames.length)
      frames.push frames.length

    sheet = builder.build()

    waterfall = new waterfallLib.waterfallRed_JSCC()
    visibleStage.children = waterfall.children

    i = 0
    listener = {
      handleEvent: ->
        i += 0.4
        waterfall.gotoAndPlay(i)
        visibleStage.update()
    }
    createjs.Ticker.addEventListener "tick", listener

    # It works, and we can set the movie clip to go to an arbitrary frame.
    # So we can set up the frame rates ourselves. Will have to, because movie clips
    # don't have frame rate systems like sprites do.
    # Also looks like with this system we don't have to move the children over each time


  testManyWaterfallsWithManualAnimation: ->
    visibleStage = new createjs.SpriteStage(@$el.find('#visible-canvas')[0])

    builder = new createjs.SpriteSheetBuilder()
    frames = []

    createClass = (frame) ->
      class Stub
        constructor: ->
          sprite = new createjs.Sprite(sheet, frame)
          sprite.stop()
          return sprite

    for name, klass of waterfallLib
      continue if name is 'waterfallRed_JSCC'
      instance = new klass()
      builder.addFrame(instance, instance.nominalBounds)
      waterfallLib[name] = createClass(frames.length)
      frames.push frames.length

    sheet = builder.build()
    movieClips = []
    spriteContainers = []
    i = 0

    while i < 100
      beStatic = false
#      beStatic = i % 2
#      beStatic = true

      waterfall = new waterfallLib.waterfallRed_JSCC()
      c = new createjs.SpriteContainer(sheet)
      c.x = (i%10) * 95
      c.y = i * 6
      c.scaleX = 0.3
      c.scaleY = 0.3
      visibleStage.addChild(c)

      movieClips.push(waterfall)
      spriteContainers.push(c)
      c.children = waterfall.children
      i += 1

    i = 0
    listener = {
      handleEvent: ->
#        for child, index in spriteContainers
#          child.children = movieClips[index].children
        i += 0.4
        for waterfall, index in movieClips
#          continue if i > 1 and index % 2
          waterfall.gotoAndPlay(i*index/12)
        visibleStage.update()
    }
    createjs.Ticker.addEventListener "tick", listener

    # well this is a bit better. 33% CPU for 100 waterfalls going at various speeds
    # and 23% if half the waterfalls are being updated.
    # still, you take a pretty big hit for manipulating the positions of containers with the movieclip


  testLibrarianHorde: ->
    visibleStage = new createjs.SpriteStage(@$el.find('#visible-canvas')[0])
    builder = new createjs.SpriteSheetBuilder()
    frames = []

    createClass = (frame) ->
      class Stub
        constructor: ->
          sprite = new createjs.Sprite(sheet, frame)
          sprite.stop()
          return sprite

    for name, klass of librarianLib
      continue if name is 'Librarian_SideWalk_JSCC'
      instance = new klass()
      builder.addFrame(instance, instance.nominalBounds)
      librarianLib[name] = createClass(frames.length)
      frames.push frames.length

    sheet = builder.build()
    movieClips = []
    spriteContainers = []
    i = 0

    class SpriteContainerChildClass extends createjs.SpriteContainer
      constructor: (spriteSheet) ->
        @initialize(spriteSheet)

    while i < 100
      beStatic = false
      #      beStatic = i % 2
      #      beStatic = true

      librarian = new librarianLib.Librarian_SideWalk_JSCC()
      c = new SpriteContainerChildClass(sheet)
      c.x = (i%10) * 95
      c.y = i * 6
      c.scaleX = 1
      c.scaleY = 1
      visibleStage.addChild(c)

      movieClips.push(librarian)
      spriteContainers.push(c)
      c.children = librarian.children
      i += 1

    i = 0
    listener = {
      handleEvent: ->
        i += 0.4
        for librarian, index in movieClips
          librarian.gotoAndPlay(i*index/12)
        visibleStage.update()
    }
    createjs.Ticker.addEventListener "tick", listener

    # 20% CPU
  
  testGiantCanvas: ->
    builder = new createjs.SpriteSheetBuilder()
    
    # mess with these
    builder.maxWidth = 4096
    builder.maxHeight = 4096
    scale = 3.9
    duplicates = 100
    
    frames = []

    createClass = (frame) ->
      class Stub
        constructor: ->
          sprite = new createjs.Sprite(sheet, frame)
          sprite.stop()
          return sprite

    for name, klass of librarianLib
      continue if name is 'Librarian_SideWalk_JSCC'
      instance = new klass()
      builder.addFrame(instance, instance.nominalBounds, scale) for i in _.range(duplicates)
      librarianLib[name] = createClass(frames.length)
      frames.push frames.length

    sheet = builder.build()
    $('body').attr('class', '').empty().css('background', 'white').append($(sheet._images))
    for image, index in sheet._images
      console.log "Sheet ##{index}: #{$(image).attr('width')}x#{$(image).attr('height')}"
    
  afterRender: ->
#    @testMovieClipWithRasterizedSpriteChildren()
#    @testMovieClipWithEmptyObjectChildren()
#    @testWaterfallRasteredPerformance()
#    @testMovieClipStageUpdatePerformance()
#    @testAnimateWaterfallContainersWithMovieClip()
#    @testAnimateManyWaterfallContainersWithMovieClip()
#    @testAnimateSomeWaterfalls()
#    @testAnimateManyRasteredWaterfalls()
#    @testManualMovieClipUpdating()
#    @testManyWaterfallsWithManualAnimation()
    @testLibrarianHorde()

module.exports = ->
  v = new WebGLDemoView()
  v.render()
  window.v = v
  v