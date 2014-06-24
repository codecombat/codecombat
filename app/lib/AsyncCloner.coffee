#CocoClass = require 'lib/CocoClass'
#
#module.exports = class AsyncCloner extends CocoClass
#  constructor: (@source, @depth=2) ->
#    # passing in a depth of 0 will just _.clone the first layer, and will result in 1 indexList
#    super()
#    @indexLists = []
#    @initClone()
#
#  initClone: () ->
#    @target = AsyncCloner.cloneToDepth(@source, @depth)
#    @indexLists = [_.keys(@target)] if _.isObject @target
#
#  @cloneToDepth: (value, depth) ->
#    value = _.clone(value)
#    return value unless depth and _.isObject value
#    value[key] = @cloneToDepth(value[key], depth-1) for key in _.keys value
#    value
#
#  clone: ->
#    while @indexLists.length
#      #console.log 'Clone loop:', JSON.stringify @indexLists
#      @moveIndexForward() # fills or empties the index so @indexLists.length === @depth + 1
#      break if @done()
#      @cloneOne()
#      @moveIndexForwardOne()
#      break if @done() or @timeToSleep()
#
#  moveIndexForward: ->
#    while @indexLists.length
#      nextValue = @getNextValue()
#      if _.isObject(nextValue)
#        if @indexLists.length <= @depth
#          # push a new list if it's a collection
#          @indexLists.push _.keys(nextValue)
#          continue
#        else
#          break # we done, the next value needs to be deep cloned
#      #console.log 'Skipping:', @getNextPath()
#      @moveIndexForwardOne() # move past this value otherwise
#      #console.log '\tMoved index forward', JSON.stringify @indexLists
#
#  getNextValue: ->
#    value = @target
#    value = value[indexList[0]] for indexList in @indexLists
#    value
#
#  getNextParent: ->
#    parent = @target
#    parent = parent[indexList[0]] for indexList in @indexLists[...-1]
#    parent
#
#  getNextPath: ->
#    (indexList[0] for indexList in @indexLists when indexList.length).join '.'
#
#  moveIndexForwardOne: ->
#    @indexLists[@indexLists.length-1].shift() # move the index forward one
#    # if we reached the end of an index list, trim down through all finished lists
#    while @indexLists.length and not @indexLists[@indexLists.length-1].length
#      @indexLists.pop()
#      @indexLists[@indexLists.length-1].shift() if @indexLists.length
#
#  cloneOne: ->
#    if @indexLists.length isnt @depth + 1
#      throw new Error('Cloner is in an invalid state!')
#    parent = @getNextParent()
#    key = @indexLists[@indexLists.length-1][0]
#    parent[key] = _.cloneDeep parent[key]
#    #console.log 'Deep Cloned:', @getNextPath()
#
#  done: -> not @indexLists.length
#
#  timeToSleep: -> false


###
  Overall, the loop is:
    Fill indexes if we need to to the depth we've cloned
    Clone that one, popping it off the list.
    If the last list is now empty, pop that list and every subsequent list if needed.
    Check for doneness, or timeout.
###
