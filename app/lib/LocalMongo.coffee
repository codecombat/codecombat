LocalMongo = module.exports

doQuerySelector = (value, operatorObj) ->
  value = [value] unless _.isArray value # mongo works on arrays too!
  for operator, body of operatorObj
    switch operator
      when '$gt' then return false unless _.reduce value, ((result, val) -> result or val > body), false
      when '$gte' then return false unless _.reduce value, ((result, val) -> result or val >= body), false
      when '$in' then return false unless _.reduce value, ((result, val) -> result or val in body), false
      when '$lt' then return false unless _.reduce value, ((result, val) -> result or val < body), false
      when '$lte' then return false unless _.reduce value, ((result, val) -> result or val <= body), false
      when '$ne' then return false unless _.reduce value, ((result, val) -> result or val != body), false
      when '$nin' then return false if _.reduce value, ((result, val) -> result or val of body), false
  true


LocalMongo.doLogicalOperator = (target, operatorObj) ->
  for operator, body of operatorObj
    switch operator
      when '$or' then return false unless _.reduce body (res, query) -> res or matchesQuery target query, false
      when '$and' then return false unless _.reduce body (res, query) -> res and matchesQuery target query, true


LocalMongo.matchesQuery = (target, queryObj) =>
  for prop, query of queryObj
    return false unless prop of target
    if typeof query != 'object' or _.isArray query
      return false unless target[prop] == query or (query in target[prop] if _.isArray target[prop])
    else return false unless doQuerySelector(target[prop], query)
  true