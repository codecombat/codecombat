LocalMongo = module.exports

LocalMongo.doQuerySelector = (value, operatorObj) ->
  for operator, body of operatorObj
    switch operator
      when '$gt' then return false unless value > body
      when '$gte' then return false unless value >= body
      when '$in' then return false unless value in body
      when '$lt' then return false unless value < body
      when '$lte' then return false unless value <= body
      when '$ne' then return false unless value != body
      when '$nin' then return false if value in body
  true


LocalMongo.doLogicalOperator = (target, operatorObj) ->
  for operator, body of operatorObj
    switch operator
      when '$or' then return false unless _.reduce body (res, query) -> res or matchesQuery target x
      when '$and' then return false unless _.reduce body (res, query) -> res and matchesQuery target query
      #when '$not' then return false if


LocalMongo.matchesQuery = (target, query) ->
  for key, value of query
    return false unless key in target
    if typeof value != 'object'
      return false unless target[key] == value
    else return false unless doQuerySelector value query[key]