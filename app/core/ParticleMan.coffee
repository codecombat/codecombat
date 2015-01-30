CocoClass = require 'core/CocoClass'

module.exports = ParticleMan = class ParticleMan extends CocoClass

  constructor: ->
    return @unsupported = true unless Modernizr.webgl
    @renderer = new THREE.WebGLRenderer alpha: true
    $(@renderer.domElement).addClass 'particle-man'
    @scene = new THREE.Scene()
    @clock = new THREE.Clock()
    @particleGroups = []

  destroy: ->
    @detach()
    # TODO: figure out how to dispose everything
    # scene.remove(mesh)
    # mesh.dispose()
    # geometry.dispose()
    # material.dispose()
    # texture.dispose()
    super()

  attach: (@$el) ->
    return if @unsupported
    width = @$el.innerWidth()
    height = @$el.innerHeight()
    @aspectRatio = width / height
    @renderer.setSize(width, height)
    @$el.append @renderer.domElement
    @camera = camera = new THREE.OrthographicCamera(
      100 * -0.5,                 # Left
      100 * 0.5,                  # Right
      100 * 0.5 * @aspectRatio,   # Top
      100 * -0.5 * @aspectRatio,  # Bottom
      0,                          # Near
      1000                        # Far
    )
    @camera.position.set(0, 0, 100)
    #@camera.position.set(0, 0, 0)
    #@camera.lookAt particleGroup.mesh.position
    @camera.up = new THREE.Vector3(0, 1, 0)  # this might help?  http://stackoverflow.com/questions/14271672/moving-the-camera-lookat-and-rotations-in-three-js
    @camera.lookAt new THREE.Vector3(0, 0, 0)
    unless @started
      @started = true
      @render()

  detach: ->
    return if @unsupported
    @renderer.domElement.remove()
    @started = false

  render: =>
    return if @unsupported
    return if @destroyed
    return unless @started
    @renderer.render @scene, @camera
    dt = @clock.getDelta()
    for group in @particleGroups
      group.tick dt
    requestAnimationFrame @render
    #@countFPS()

  countFPS: ->
    @framesRendered ?= 0
    ++@framesRendered
    @lastFPS ?= new Date()
    now = new Date()
    if now - @lastFPS > 1000
      console.log @framesRendered, 'fps with', @particleGroups.length, 'particle groups.'
      @framesRendered = 0
      @lastFPS = now

  addEmitter: (x, y, kind="star-fountain") ->
    return if @unsupported
    options = $.extend true, {}, particleKinds[kind]
    options.group.texture = THREE.ImageUtils.loadTexture "/images/common/particles/#{options.group.texture}.png"
    scale = 100
    aspectRatio = @$el
    group = new SPE.Group options.group
    group.mesh.position.x = scale * (-0.5 + x)
    group.mesh.position.y = scale * (-0.5 + y) * @aspectRatio
    emitter = new SPE.Emitter options.emitter
    group.addEmitter emitter
    @particleGroups.push group
    @scene.add group.mesh
    group

  removeEmitter: (group) ->
    return if @unsupported
    @scene.remove group.mesh
    @particleGroups = _.without @particleGroups, group

  removeEmitters: ->
    return if @unsupported
    @removeEmitter group for group in @particleGroups.slice()
 
  #addTestCube: ->
    #geometry = new THREE.BoxGeometry 5, 5, 5
    #material = new THREE.MeshLambertMaterial color: 0xFF0000
    #mesh = new THREE.Mesh geometry, material
    #@scene.add mesh
    #light = new THREE.PointLight 0xFFFF00
    #light.position.set 10, 0, 20
    #@scene.add light


particleKinds =
  'star-fountain':
    group:
      texture: 'star'
      maxAge: 4
      hasPerspective: 1
      colorize: 1
      transparent: 1
      alphaTest: 0.5
      depthWrite: false
      depthTest: true
      blending: THREE.NormalBlending
    emitter:
      type: "cube"
      particleCount: 60
      position: new THREE.Vector3(0, 0, 0)
      #positionSpread: new THREE.Vector3(2, 2, 0)
      positionSpread: new THREE.Vector3(1, 0, 1)
      acceleration: new THREE.Vector3(0, -1, 0)
      accelerationSpread: new THREE.Vector3(0, 0, 0)
      velocity: new THREE.Vector3(0, 4, 0)
      velocitySpread: new THREE.Vector3(2, 2, 2)
      sizeStart: 8
      sizeStartSpread: 0
      sizeMiddle: 4
      sizeMiddleSpread: 0
      sizeEnd: 1
      sizeEndSpread: 0
      angleStart: 0
      angleStartSpread: 0
      angleMiddle: 0
      angleMiddleSpread: 0
      angleEnd: 0
      angleEndSpread: 0
      angleAlignVelocity: false
      colorStart: new THREE.Color(0xb9c5ff)
      colorStartSpread: new THREE.Vector3(0, 0, 0)
      colorMiddle: new THREE.Color(0x535eff)
      colorMiddleSpread: new THREE.Vector3(0, 0, 0)
      colorEnd: new THREE.Color(0x0000c4)
      colorEndSpread: new THREE.Vector3(0, 0, 0)
      opacityStart: 1
      opacityStartSpread: 0
      opacityMiddle: 0.5
      opacityMiddleSpread: 0
      opacityEnd: 0
      opacityEndSpread: 0
      duration: null
      alive: 1
      isStatic: 0
