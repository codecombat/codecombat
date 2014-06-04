LocalMongo = module.exports

# Checks whether func(l, r) is true for at least one value of left for at least one value of right
mapred = (left, right, func) ->
  _.reduce(left, ((result, singleLeft) ->
    result or (_.reduce (_.map right, (singleRight) -> func(singleLeft, singleRight)),
      ((intermediate, value) -> intermediate or value), false)), false)

doQuerySelector = (value, operatorObj) ->
  value = [value] unless _.isArray value # left hand can be an array too
  for operator, body of operatorObj
    body = [body] unless _.isArray body # right hand can be an array too
    switch operator
      when '$gt' then return false unless mapred value, body, (l, r) -> l > r
      when '$gte' then return false unless mapred value, body, (l, r) -> l >= r
      when '$lt' then return false unless mapred value, body, (l, r) -> l < r
      when '$lte' then return false unless mapred value, body, (l, r) -> l <= r
      when '$ne' then return false if mapred value, body, (l, r) -> l == r
      when '$in' then return false unless _.reduce value, ((result, val) -> result or val in body), false
      when '$nin' then return false if _.reduce value, ((result, val) -> result or val in body), false
      when '$exists' then return false if value[0]? isnt body[0]
      else return false
  true

matchesQuery = (target, queryObj) ->
  return true unless queryObj
  for prop, query of queryObj
    if prop[0] == '$'
      switch prop
        when '$or' then return false unless _.reduce query, ((res, obj) -> res or matchesQuery target, obj), false
        when '$and' then return false unless _.reduce query, ((res, obj) -> res and matchesQuery target, obj), true
        else return false
    else
      # Do nested properties
      pieces = prop.split('.')
      obj = target
      for piece in pieces
        unless piece of obj
          obj = null
          break
        obj = obj[piece]
      if typeof query != 'object' or _.isArray query
        return false unless obj == query or (query in obj if _.isArray obj)
      else return false unless doQuerySelector obj, query
  true

LocalMongo.matchesQuery = matchesQuery
