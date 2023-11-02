createjs = require 'lib/createjs-parts'
esprima = require 'esprima'

module.exports = class SpriteParser
  constructor: (@thangTypeModel) ->
    # Create a new ThangType, or work with one we've been building
    @thangType = $.extend(true, {}, @thangTypeModel.attributes.raw)
    @thangType ?= {}
    @thangType.shapes ?= {}
    @thangType.containers ?= {}
    @thangType.animations ?= {}

    # Internal parser state
    @shapeLongKeys = {}
    @containerLongKeys = {}
    @containerRenamings = {}
    @animationLongKeys = {}
    @animationRenamings = {}
    @populateLongKeys()

  populateLongKeys: ->
    for shortKey, shape of @thangType.shapes
      longKey = JSON.stringify(_.values(shape))
      @shapeLongKeys[longKey] = shortKey
    for shortKey, container of @thangType.containers
      longKey = JSON.stringify(_.values(container))
      @containerLongKeys[longKey] = shortKey
    for shortKey, animation of @thangType.animations
      longKey = JSON.stringify(_.values(animation))
      @animationLongKeys[longKey] = shortKey

  parse: (source) ->
    # Grab the library properties' width/height so we can subtract half of each from frame bounds
    properties = source.match(/.*lib\.properties = \{\n.*?width: (\d+),\n.*?height: (\d+)/im)
    @width = parseInt(properties?[1] ? '0', 10)
    @height = parseInt(properties?[2] ? '0', 10)

    # Remove webfontAvailable line, not relevant
    source = source.replace /lib\.webfontAvailable = (.|\n)+?};/, ''

    options = {loc: false, range: true}
    ast = esprima.parse source, options
    blocks = @findBlocks ast, source
    containers = _.filter blocks, {kind: 'Container'}
    movieClips = _.filter blocks, {kind: 'MovieClip'}

    mainClip = _.last(movieClips) ? _.last(containers)
    @animationName = mainClip.name
    for container, index in containers
      if index is containers.length - 1 and not movieClips.length and container.bounds?.length
        container.bounds[0] -= @width / 2
        container.bounds[1] -= @height / 2
      [shapeKeys, localShapes] = @getShapesFromBlock container, source
      localContainers = @getContainersFromMovieClip container, source, true # Added true because anya attack was breaking, but might break other imports
      addChildArgs = @getAddChildCallArguments container, source
      instructions = []
      for bn in addChildArgs
        gotIt = false
        for shape in localShapes
          if shape.bn is bn
            instructions.push shape.gn
            gotIt = true
            break
        continue if gotIt
        for c in localContainers
          if c.bn is bn
            instructions.push {t: c.t, gn: c.gn}
            break
      continue unless container.bounds and instructions.length
      @addContainer {c: instructions, b: container.bounds}, container.name

    childrenMovieClips = []

    for movieClip, index in movieClips
      lastBounds = null
      # fill in bounds which are null...
      for bounds, boundsIndex in movieClip.frameBounds
        if not bounds
          movieClip.frameBounds[boundsIndex] = _.clone(lastBounds)
        else
          lastBounds = bounds

      localGraphics = @getGraphicsFromBlock(movieClip, source)
      [shapeKeys, localShapes] = @getShapesFromBlock movieClip, source
      localContainers = @getContainersFromMovieClip movieClip, source, true
      localAnimations = @getAnimationsFromMovieClip movieClip, source, true
      for animation in localAnimations
        childrenMovieClips.push(animation.gn)
      localTweens = @getTweensFromMovieClip movieClip, source, localShapes, localContainers, localAnimations
      @addAnimation {
        shapes: localShapes
        containers: localContainers
        animations: localAnimations
        tweens: localTweens
        graphics: localGraphics
        bounds: movieClip.bounds
        frameBounds: movieClip.frameBounds
      }, movieClip.name

    for movieClip in movieClips
      if movieClip.name not in childrenMovieClips
        for bounds in movieClip.frameBounds
          bounds[0] -= @width / 2
          bounds[1] -= @height / 2
        movieClip.bounds[0] -= @width / 2
        movieClip.bounds[1] -= @height / 2

    @saveToModel()
    return movieClips[0]?.name

  saveToModel: ->
    @thangTypeModel.set('raw', @thangType)

  addShape: (shape) ->
    longKey = JSON.stringify(_.values(shape))
    shortKey = @shapeLongKeys[longKey]
    unless shortKey?
      shortKey = '' + _.size @thangType.shapes
      shortKey += '+' while @thangType.shapes[shortKey]
      @thangType.shapes[shortKey] = shape
      @shapeLongKeys[longKey] = shortKey
    return shortKey

  addContainer: (container, name) ->
    longKey = JSON.stringify(_.values(container))
    shortKey = @containerLongKeys[longKey]
    if not shortKey?
      shortKey = name
      if @thangType.containers[shortKey]?
        shortKey = @animationName + ':' + name
      @thangType.containers[shortKey] = container
      @containerLongKeys[longKey] = shortKey
    @containerRenamings[name] = shortKey
    return shortKey

  addAnimation: (animation, name) ->
    longKey = JSON.stringify(_.values(animation))
    shortKey = @animationLongKeys[longKey]
    if shortKey?
      @animationRenamings[shortKey] = name
    else
      shortKey = name
      if @thangType.animations[shortKey]?
        shortKey = @animationName + ':' + name
      @thangType.animations[shortKey] = animation
      @animationLongKeys[longKey] = shortKey
      @animationRenamings[name] = shortKey
    return shortKey

  walk: (node, parent, fn) ->
    node.parent = parent
    for key, child of node
      continue if key is 'parent'
      if _.isArray child
        for grandchild in child
          @walk grandchild, node, fn if _.isString grandchild?.type
      else if _.isString child?.type
        node.parent = parent
        @walk child, node, fn
    fn node

  orphanify: (node) ->
    delete node.parent if node.parent
    for key, child of node
      continue if key is 'parent'
      if _.isArray child
        for grandchild in child
          @orphanify grandchild if _.isString grandchild?.type
      else if _.isString child?.type
        delete node.parent if node.parent
        @orphanify child

  subSourceFromRange: (range, source) ->
    source[range[0] ... range[1]]

  grabFunctionArguments: (source, literal=false) ->
    # Replace first and last parens with brackets to turn args into array
    args = source.replace(/.*?\(/, '[').replace(/\)[^)]*?$/, ']')
    if literal then eval(args) else args

  findBlocks: (ast, source) ->
    functionExpressions = []
    rectangles = []
    gatherFunctionExpressions = (node) =>
      if node.type is 'FunctionExpression'
        name = node.parent?.left?.property?.name
        if name
          expression = node.parent.parent
          unless expression.parent?.right?.right
            if /frame_[\d]+/.test name  # Skip some useless KR function things
              return
          kind = expression.parent.right.right.callee.property.name
          statement = node.parent.parent.parent.parent
          statementIndex = _.indexOf statement.parent.body, statement
          nominalBoundsStatement = statement.parent.body[statementIndex + 1]
          nominalBoundsRange = nominalBoundsStatement.expression.right.range
          nominalBoundsSource = @subSourceFromRange nominalBoundsRange, source
          nominalBounds = @grabFunctionArguments nominalBoundsSource, true

          frameBoundsStatement = statement.parent.body[statementIndex + 2]
          if frameBoundsStatement
            frameBoundsRange = frameBoundsStatement.expression.right.range
            frameBoundsSource = @subSourceFromRange frameBoundsRange, source
            if frameBoundsSource.search(/\[rect/) is -1  # some other statement; we don't have multiframe bounds
              console.log 'Didn\'t have multiframe bounds for this movie clip.'
              frameBounds = [_.clone(nominalBounds)]
            else
              lastRect = nominalBounds
              frameBounds = []
              for arg, i in frameBoundsStatement.expression.right.elements
                bounds = null
                argSource = @subSourceFromRange arg.range, source
                if arg.type is 'Identifier'
                  bounds = lastRect
                else if arg.type is 'NewExpression'
                  bounds = @grabFunctionArguments argSource, true
                else if arg.type is 'AssignmentExpression'
                  bounds = @grabFunctionArguments argSource.replace('rect=', ''), true
                  lastRect = bounds
                else if arg.type is 'Literal' and arg.value is null
                  bounds = [0, 0, 1, 1]  # Let's try this.
                frameBounds.push _.clone bounds
          else
            frameBounds = [_.clone(nominalBounds)]

          functionExpressions.push {name: name, bounds: nominalBounds, frameBounds: frameBounds, expression: node.parent.parent, kind: kind}
    @walk ast, null, gatherFunctionExpressions
    functionExpressions

  ###
    this.shape_1.graphics.f('#605E4A').s().p('AAOD/IgOgaIAEhkIgmgdIgMgBIgPgFIgVgJQA1h9g8jXQAQAHAOASQAQAUAKAeQARAuAJBJQAHA/gBA5IAAADIACAfIAFARIACAGIAEAHIAHAHQAVAXAQAUQAUAaANAUIABACIgsgdIgggXIAAAnIABAwIgBgBg');
    this.shape_1.sett(23.2,30.1);

    this.shape.graphics.f().s('#000000').ss(0.1,1,1).p('AAAAAQAAAAAAAA');
    this.shape.sett(3.8,22.4);
  ###

  getGraphicsFromBlock: (block, source) ->
    block = block.expression.object.right.body
    localGraphics = []
    gatherShapeDefinitions = (node) =>
      return unless node.type is 'NewExpression' and node.callee.property.name is 'Graphics'
      blockName = node.parent.parent.parent.id.name
      graphicsString = node.parent.parent.arguments[0].value
      localGraphics.push {p:graphicsString, bn:blockName}

    @walk block, null, gatherShapeDefinitions
    return localGraphics

  getShapesFromBlock: (block, source) ->
    block = block.expression.object.right.body
    shapeKeys = []
    localShapes = []
    gatherShapeDefinitions = (node) =>
      return unless node.type is 'MemberExpression'
      name = node.object?.object?.property?.name
      if not name
        name = node.parent?.parent?.id?.name
        return unless name and name.indexOf('mask') is 0 and node.property?.name is 'Shape'
        shape = {bn: name, im: true}
        localShapes.push shape
        return
      return unless name.search('shape') is 0 and node.object.property?.name is 'graphics'
      fillCall = node.parent
      if fillCall.callee.property.name is 'lf'
        linearGradientFillSource = @subSourceFromRange fillCall.parent.range, source
        linearGradientFill = @grabFunctionArguments linearGradientFillSource.replace(/.*?lf\(/, 'lf('), true
      else if fillCall.callee.property.name is 'rf'
        radialGradientFillSource = @subSourceFromRange fillCall.parent.range, source
        radialGradientFill = @grabFunctionArguments radialGradientFillSource.replace(/.*?lf\(/, 'lf('), true
      else
        fillColor = fillCall.arguments[0]?.value ? null
        callName = fillCall.callee.property.name
        console.error 'What is this?! Not a fill!', callName unless callName is 'f'
      strokeCall = node.parent.parent.parent.parent
      if strokeCall.object.callee.property.name is 'ls'
        linearGradientStrokeSource = @subSourceFromRange strokeCall.parent.range, source
        linearGradientStroke = @grabFunctionArguments linearGradientStrokeSource.replace(/.*?ls\(/, 'ls(').replace(/\).ss\(.*/, ')'), true
      else
        strokeColor = strokeCall.object.arguments?[0]?.value ? null
        console.error 'What is this?! Not a stroke!' unless strokeCall.object.callee.property.name is 's'
      strokeStyle = null
      graphicsStatement = strokeCall.parent
      if strokeColor or linearGradientStroke
        # There might now be an extra node, ss, for stroke style
        strokeStyleSource = @subSourceFromRange strokeCall.parent.range, source
        if strokeStyleSource.search(/ss\(/) isnt -1
          strokeStyle = @grabFunctionArguments strokeStyleSource.replace(/.*?ss\(/, 'ss('), true
          graphicsStatement = strokeCall.parent.parent.parent
      if graphicsStatement.callee.property.name is 'de'
        drawEllipseSource = @subSourceFromRange graphicsStatement.parent.range, source
        drawEllipse = @grabFunctionArguments drawEllipseSource.replace(/.*?de\(/, 'de('), true
      else
        path = graphicsStatement.arguments?[0]?.value ? null
        console.error 'What is this?! Not a path!' unless graphicsStatement.callee.property.name is 'p'
      body = graphicsStatement.parent.parent.body
      graphicsStatementIndex = _.indexOf body, graphicsStatement.parent
      t = body[graphicsStatementIndex + 1].expression
      tSource = @subSourceFromRange t.range, source
      if tSource.search('setTransform') is -1
        t = [0, 0]
      else
        t = @grabFunctionArguments tSource, true

      for statement in body.slice(graphicsStatementIndex + 2)
        # Handle things like
        # this.shape.mask = this.shape_1.mask = this.shape_2.mask = this.shape_3.mask = mask;
        continue unless statement.expression?.left?.property?.name is 'mask'
        exp = statement.expression
        matchedName = false
        while exp
          matchedName = matchedName or exp.left?.object?.property?.name is name
          mask = exp.name
          exp = exp.right
        continue unless matchedName
        break

      shape = {t: t}
      shape.p = path if path
      shape.de = drawEllipse if drawEllipse
      shape.sc = strokeColor if strokeColor
      shape.ss = strokeStyle if strokeStyle
      shape.fc = fillColor if fillColor
      shape.lf = linearGradientFill if linearGradientFill
      shape.rf = radialGradientFill if radialGradientFill
      shape.ls = linearGradientStroke if linearGradientStroke
      if name.search('shape') isnt -1 and shape.fc is 'rgba(0,0,0,0.451)' and not shape.ss and not shape.sc
        console.log 'Skipping a shadow', name, shape, 'because we\'re doing shadows separately now.'
        return
      #if name.search('shape') isnt -1 and shape.fc is 'rgba(0,0,0,0.498)' and not shape.ss and not shape.sc
      #  console.log 'Skipping a KR shadow', name, shape, 'because we\'re doing shadows separately now.'
      #  return
      shapeKeys.push shapeKey = @addShape shape
      localShape = {bn: name, gn: shapeKey}
      localShape.m = mask if mask
      localShapes.push localShape

    @walk block, null, gatherShapeDefinitions
    return [shapeKeys, localShapes]

  getContainersFromMovieClip: (movieClip, source, possibleAnimations=false) ->
    block = movieClip.expression.object.right.body
    localContainers = []
    gatherContainerDefinitions = (node) =>
      return unless node.type is 'Identifier' and node.name is 'lib'
      args = node.parent.parent.arguments
      libName = node.parent.property.name
      return if args.length and not possibleAnimations  # might be animation, not container
      gn = @containerRenamings[libName]
      return if possibleAnimations and not gn  # not a container we know about
      bn = node.parent.parent.parent.left.property.name
      expressionStatement = node.parent.parent.parent.parent
      body = expressionStatement.parent.body
      expressionStatementIndex = _.indexOf body, expressionStatement
      t = body[expressionStatementIndex + 1].expression
      tSource = @subSourceFromRange t.range, source
      t = @grabFunctionArguments tSource, true
      o = body[expressionStatementIndex + 2].expression
      localContainer = {bn: bn, t: t, gn: gn}
      if o and o.left?.object?.property?.name is bn and o.left.property?.name is '_off'
        localContainer.o = o.right.value
      else if o and o.left?.property?.name is 'alpha'
        localContainer.al = o.right.value
      localContainers.push localContainer

    @walk block, null, gatherContainerDefinitions
    return localContainers

  getAnimationsFromMovieClip: (movieClip, source, possibleContainers=false) ->
    block = movieClip.expression.object.right.body
    localAnimations = []
    gatherAnimationDefinitions = (node) =>
      return unless node.type is 'Identifier' and node.name is 'lib'
      args = node.parent.parent.arguments
      libName = node.parent.property.name
      return unless args.length or possibleContainers  # might be container, not animation
      return if @containerRenamings[libName] and not @animationRenamings[libName]  # we have it as a container
      args = @grabFunctionArguments @subSourceFromRange(node.parent.parent.range, source), true
      bn = node.parent.parent.parent.left.property.name
      expressionStatement = node.parent.parent.parent.parent
      body = expressionStatement.parent.body
      expressionStatementIndex = _.indexOf body, expressionStatement
      t = body[expressionStatementIndex + 1].expression
      tSource = @subSourceFromRange t.range, source
      t = @grabFunctionArguments tSource, true
      gn = @animationRenamings[libName] ? libName
      localAnimation = {bn: bn, t: t, gn: gn, a: args}
      localAnimations.push localAnimation

    @walk block, null, gatherAnimationDefinitions
    return localAnimations

  getTweensFromMovieClip: (movieClip, source, localShapes, localContainers, localAnimations) ->
    block = movieClip.expression.object.right.body
    localTweens = []
    gatherTweens = (node) =>
      return unless node.property?.name is 'addTween'
      callExpressions = []
      tweenNode = node
      gatherCallExpressions = (node) =>
        return unless node.type is 'CallExpression'
        name = node.callee.property?.name
        return unless name in ['get', 'to', 'wait']
        return if name is 'get' and callExpressions.length # avoid Ease calls in the tweens
        flattenedRanges = _.flatten [(a.range for a in node.arguments)]
        range = [_.min(flattenedRanges), _.max(flattenedRanges)]
        # Replace 'this.<local>' references with just the 'name'
        argsSource = @subSourceFromRange(range, source)
        argsSource = argsSource.replace(/mask/g, 'this.mask') # so the mask thing will be handled correctly as a blockName in the next line
        argsSource = argsSource.replace(/this\.([a-z_0-9]+)/ig, '"$1"') # turns this.shape literal to 'shape' string
        argsSource = argsSource.replace(/cjs(.+)\)/, '"createjs$1)"') # turns cjs.Ease.get(0.5)
        argsSource = '{}' if argsSource is 'this' # not sure what this should be but it looks like we don't need it for KR sprites

        args = eval "[#{argsSource}]"
        shadowTween = args[0]?.search?('shape') is 0 and not _.find(localShapes, bn: args[0])
        shadowTween = shadowTween or args[0]?.state?[0]?.t?.search?('shape') is 0 and not _.find(localShapes, bn: args[0].state[0].t)
        if shadowTween
          console.log 'Skipping tween', name, argsSource, args, 'from localShapes', localShapes, 'presumably because it\'s a shadow we skipped.'
          return
        callExpressions.push {n: name, a: args}
      @walk node.parent.parent, null, gatherCallExpressions
      localTweens.push callExpressions

    @walk block, null, gatherTweens
    return localTweens

  getAddChildCallArguments: (block, source) ->
    block = block.expression.object.right.body
    localArgs = []
    gatherAddChildCalls = (node) =>
      return unless node.type is 'Identifier' and node.name is 'addChild'
      args = node.parent.parent.arguments
      args = (arg.property.name for arg in args)
      localArgs.push arg for arg in args
      return

    @walk block, null, gatherAddChildCalls
    return localArgs
###

  this.timeline.addTween(cjs.Tween.get(this.instance).to({scaleX:0.82,scaleY:0.79,rotation:-10.8,x:98.4,y:-86.5},4).to({scaleY:0.7,rotation:9.3,x:95.6,y:-48.8},1).to({scaleX:0.82,scaleY:0.61,rotation:29.4,x:92.8,y:-11},1).to({regX:7.3,scaleX:0.82,scaleY:0.53,rotation:49.7,x:90.1,y:26.6},1).to({regX:7.2,regY:29.8,scaleY:0.66,rotation:19.3,x:101.2,y:-27.8},2).to({regY:29.9,scaleY:0.79,rotation:-10.8,x:98.4,y:-86.5},2).to({scaleX:0.84,scaleY:0.83,rotation:-30.7,x:68.4,y:-110},2).to({regX:7.3,scaleX:0.84,scaleY:0.84,rotation:-33.9,x:63.5,y:-114},1).wait(1));

###

###
simpleSample = """
(function (lib, img, cjs) {

var p; // shortcut to reference prototypes

// stage content:
(lib.enemy_flying_move_side = function(mode,startPosition,loop) {
  this.initialize(mode,startPosition,loop,{});

  // D_Head
  this.instance = new lib.Dragon_Head();
  this.instance.setTransform(227,200.5,1,1,0,0,0,51.9,42.5);

  this.timeline.addTween(cjs.Tween.get(this.instance).to({y:182.9},7).to({y:200.5},7).wait(1));

  // Layer 7
  this.shape = new cjs.Shape();
  this.shape.graphics.f('#4F6877').s().p('AgsAxQgSgVgB');
  this.shape.setTransform(283.1,146.1);

  // Layer 7 2
  this.shape_1 = new cjs.Shape();
  this.shape_1.graphics.f('rgba(255,255,255,0.4)').s().p('ArTs0QSMB7EbVGQhsBhiGBHQjg1IvVkhg');
  this.shape_1.setTransform(400.2,185.5);

  this.timeline.addTween(cjs.Tween.get({}).to({state:[]}).to({state:[{t:this.shape}]},7).to({state:[]},2).wait(6));

  // Wing
  this.instance_9 = new lib.Wing_Animation('synched',0);
  this.instance_9.setTransform(313.9,145.6,1,1,0,0,0,49,-83.5);

  this.timeline.addTween(cjs.Tween.get(this.instance_9).to({y:128,startPosition:7},7).wait(1));

  // Example hard one with two shapes
  this.timeline.addTween(cjs.Tween.get({}).to({state:[]}).to({state:[{t:this.shape}]},7).to({state:[{t:this.shape_1}]},1).to({state:[]},1).wait(7));


}).prototype = p = new cjs.MovieClip();
p.nominalBounds = new cjs.Rectangle(7.1,48.9,528.7,431.1);

(lib.Dragon_Head = function() {
  this.initialize();

  // Isolation Mode
  this.shape = new cjs.Shape();
  this.shape.graphics.f('#1D2226').s().p('AgVAwQgUgdgN');
  this.shape.setTransform(75,25.8);

  this.shape_1 = new cjs.Shape();
  this.shape_1.graphics.f('#1D2226').s().p('AgnBXQACABAF');
  this.shape_1.setTransform(80.8,22);

  this.addChild(this.shape_1,this.shape);
}).prototype = p = new cjs.Container();
p.nominalBounds = new cjs.Rectangle(5.8,0,87.9,85);

(lib.WingPart_01 = function() {
  this.initialize();

  // Layer 1
  this.shape = new cjs.Shape();
  this.shape.graphics.f('#DBDDBC').s().p('Ag3BeQgCgRA');
  this.shape.setTransform(10.6,19.7,1.081,1.081);

  this.shape_1 = new cjs.Shape();
  this.shape_1.graphics.f('#1D2226').s().p('AB4CDQgGg');
  this.shape_1.setTransform(19.9,17.6,1.081,1.081);

  this.shape_2 = new cjs.Shape();
  this.shape_2.graphics.f('#605E4A').s().p('AiECbQgRg');
  this.shape_2.setTransform(19.5,18.4,1.081,1.081);

  this.addChild(this.shape_2,this.shape_1,this.shape);
}).prototype = p = new cjs.Container();
p.nominalBounds = new cjs.Rectangle(0,-3.1,40,41.6);


(lib.Wing_Animation = function(mode,startPosition,loop) {
  this.initialize(mode,startPosition,loop,{});

  // WP_02
  this.instance = new lib.WingPart_01();
  this.instance.setTransform(53.6,-121.9,0.854,0.854,-40.9,0,0,7.2,29.9);

  this.timeline.addTween(cjs.Tween.get(this.instance).to({scaleY:0.7,rotation:9.3,x:95.6,y:-48.8},1).wait(1));

}).prototype = p = new cjs.MovieClip();
p.nominalBounds = new cjs.Rectangle(-27.7,-161.6,153.4,156.2);

})(lib = lib||{}, images = images||{}, createjs = createjs||{});
var lib, images, createjs;
"""
###
