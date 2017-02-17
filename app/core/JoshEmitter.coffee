utils = require 'core/utils'

module.exports = class JoshEmitter extends SPE.Emitter
  constructor: (options) ->
    SPE.Emitter.call(@, options)
    @time = 0
    @isStatic = 0.0
    @particleCount = 2000
    @liveCount = 20
    @levelParticles = {}
    @behaviors = new Array(@particleCount)
    @nextPossiblePosition = 0
    @white = new THREE.Color('white') 

  randomEdge: ->
    if Math.random() > 0.5
      {x: Math.random() * 100, y: if Math.random() > 0.5 then -10 else 110}
    else
      {y: Math.random() * 100, x: if Math.random() > 0.5 then -10 else 110}

  getParticle: ->
    idx = ++@nextPossiblePosition
    start = @randomEdge()
    @vertices[idx].x = start.x
    @vertices[idx].y = start.y
    #@attributes.alive.value[idx] = 1.0
    @attributes.colorStart.value[idx] = new THREE.Color utils.hslToHex([Math.random(), Math.random(), 0.8])
    @behaviors[idx] =
      alive: true
      idx: idx
      speed: 20


  updateWorldInfo: (data) ->
    console.log "Incoming world", data
    @levelInfo = {}
    for key, level of data
      @levelInfo[level.slug] = level

    console.log(@levelInfo)


  updateLevelInfo: (data) ->
    console.log "Incoming data", data
    #sum = Object.values(data).reduceRight ((a,b) -> a + b), 0
    #@liveCount = sum
    @counts = data.level_player_counts

    for level, count of data.level_player_counts
      continue unless @levelInfo[level]
      @levelParticles[level] ?= []
      for x in [0...count-1]
        p = @getParticle()

        @moveParticleTarget p, null, level
        @levelParticles[level].push p

  moveParticleTarget: (x, from, to) ->
    console.log "MPT #{from} -> #{to}"
    x.level = to

    
    if from and @levelParticles[from]?
      oldidx = @levelParticles[from].indexOf(x)
      @levelParticles[from].splice(oldidx, 1, null)

    if to
      unless @levelInfo[to].position?
        console.log "Couldnt locaate", to

      x.position ?= {}
      x.position.x = @levelInfo[to].position.x
      x.position.y = @levelInfo[to].position.y

      @levelParticles[to] ?= []
      targetidx = @levelParticles[to].indexOf null

      if targetidx is -1
        x.idx = @levelParticles[to].length
      else
        x.idx = targetidx

      @levelParticles[to][x.idx] = x
    else
      where = @randomEdge()
      x.position.x = where.x
      x.position.y = where.y
      console.log "killing particle from", from

    

  updateEdgeInfo: (data) ->
    console.log "Got Edge Info"
    console.log data.transitions.map (x) -> "#{x.to} -> #{x.from} [#{x.count}]"
    updates = []
    for d in data.transitions
      fromInfo = @levelInfo[d.from]
      toInfo = @levelInfo[d.to]
      continue unless fromInfo? or not d.from
      continue unless toInfo? or not d.to
      do (d) =>
        toUpdate = d.count
        if d.from
          list = _.shuffle @levelParticles[d.from]
          getParticle = =>
            for x in list
              continue unless x? and not x.banned > 0
              return x

            console.log "Out of Particles...", d.from

        else
          getParticle = =>
            console.log "Created particle for", d.to
            x = @getParticle()
            @attributes.alive.value[x.idx] = 1.0
            return x

        for j in [0..toUpdate]
          updates.push =>
            x = getParticle()
            if x?
              x.banned = 5
              @moveParticleTarget x, d.from, d.to


    updates = _.shuffle updates
    console.log "Schedueled #{updates.length} updates @ #{(data.update_interval_secs * 1000)/updates.length} ups"
    for u,i in updates
      setTimeout u, i * (data.update_interval_secs * 1000)/updates.length
      
      

  moveAtSpeed: (a, b, s) ->
    d = b - a
    return b if ( Math.abs(d) < s )
    if ( d > 0 )
      return a + s
    else
      return a - s

  moveTowardTargetAtSpeed: (f, t, s) ->
    d = Math.sqrt((f.x-t.x)*(f.x-t.x)+(f.y-t.y)*(f.y-t.y))
    return t unless d > s
    ang = Math.atan2(t.y - f.y, t.x - f.x)
    {x: f.x + Math.cos(ang) * s, y: f.y + Math.sin(ang) * s}
    

  tick: (dt) ->
    @time += dt    
    speed = 20
    for i in [0..@vertices.length-1]
      wasAlive = @attributes.alive.value[i] > 0.5
      
      behavior = @behaviors[i]
      isAlive = (behavior?.alive)?

      ar = @aspectRatio
      
      #idealX = 0.1*Math.random() + Math.sin((i+time)/spots*3.1415*2)*radius + 31
      #idealY = 0.1*Math.random() + Math.cos((i+time)/spots*3.1415*2)*radius*ar + 21 * ar
      
      
      if isAlive
        
        behavior.banned -= dt

        if behavior.level
          tot = @levelParticles[behavior.level].length - 1
          radius = if tot > 20 then 5 else 3
          spots = 5.5 + Math.floor(z/10)
          z = behavior.idx
          partialRadius = 1+(z/tot)*radius
        
          idealX = 0.1*Math.random() + Math.sin(-@time + z/spots*3.1415*2)*partialRadius + behavior.position.x
          idealY = 0.1*Math.random() + Math.cos(-@time + z/spots*3.1415*2)*partialRadius*ar + behavior.position.y * ar + 1.8

        else
          idealX = behavior.position.x
          idealY = behavior.position.y * ar

        if wasAlive or true
          newxy = @moveTowardTargetAtSpeed({x: @vertices[i].x, y: @vertices[i].y}, {x: idealX, y: idealY}, behavior.speed*dt)
          @vertices[i].x = newxy.x
          @vertices[i].y = newxy.y
        else
          @vertices[i].x = idealX
          @vertices[i].y = idealY
          

      @attributes.alive.value[i] = if isAlive then 1.0 else 0.0
      @attributes.age.value[i] = 0
      @attributes.size.value[i] = new THREE.Vector3 10.0, 10.0, 10.0
      

    @
    #super(dt)