# http://codingowl.com/readblog.php?blogid=124
module.exports.CollisionCategory = class CollisionCategory
  @className: 'CollisionCategory'
  constructor: (name, @superteamIndex=null, @collisionSystem) ->
    # @superteamIndex is null for 'none', 'obstacles', and 'dead'.
    # It's 0 for 'ground', 'air', and 'ground_and_air' units with no superteams.
    # It's 1, 2, or 3 for the superteams it gets after that. We can only have 16 collision categories.
    @ground = name.search('ground') isnt -1
    @air = name.search('air') isnt -1
    @name = CollisionCategory.nameFor name, @superteamIndex
    @superteamIndex ?= 0 if @ground or @air
    @number = 1 << @collisionSystem.totalCategories++
    if @collisionSystem.totalCategories > 16 then console.log 'There should only be 16 collision categories!'
    @mask = 0
    @collisionSystem.allCategories[@name] = @
    for otherCatName, otherCat of @collisionSystem.allCategories
      if @collidesWith otherCat
        @mask = @mask | otherCat.number
        otherCat.mask = otherCat.mask | @number

  collidesWith: (cat) ->
    # 'none' collides with nothing
    return false if @name is 'none' or cat.name is 'none'

    # 'obstacles' collides with everything; could also try letting air units (but not ground_and_air) fly over these
    return true if cat.name is 'obstacles' or @name is 'obstacles'

    # 'dead' collides only with obstacles
    return cat.name is 'obstacles' if @name is 'dead'
    return @name is 'obstacles' if cat.name is 'dead'

    # 'ground_and_air_<team>' units don't hit ground or air units on their team (so missiles don't hit same team)
    sameTeam = @superteamIndex and cat.superteamIndex is @superteamIndex
    return false if sameTeam and @ground and @air

    # actually, 'ground_and_air<team>' units don't hit any ground_and_air units (temp missile collision fix)
    return false if @ground and @air and cat.ground and cat.air

    # 'ground' collides with 'ground'
    return true if cat.ground and @ground

    # 'air' collides with 'air'
    return true if cat.air and @air

    # doesn't collide (probably 'ground' and 'air')
    false

  @nameFor: (name, superteamIndex=null) ->
    return name unless name.match('ground') or name.match('air')
    name + '_' + (superteamIndex or 0)
