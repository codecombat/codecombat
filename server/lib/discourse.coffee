_ = require 'lodash'
co = require 'co'
request = require 'request'
Promise = require 'bluebird'
Promise.promisifyAll(request)
config = require('../../server_config')

host = 'https://discourse.codecombat.com'

getUrl = (path, params) ->
  params = _.assign {}, params, {
    api_username: 'phoenix'
    api_key: config.discourse.apiKey
  }
  queryString = '?' + Object.keys(params).map((key) -> "#{key}=#{params[key]}").join('&')
  return host + path + queryString

# userByEmail = (_email) ->
#   _getUser = _.once co.wrap ->
#     res = yield request.getAsync({ url: getUrl("/users/#{_username}.json"), json: true })
#     foundUser = res.body.user
#     if not foundUser
#       throw new Error('Discourse: No user found with that name!')
#     return foundUser
#   return {
#     getGroups: co.wrap ->
#       _user = yield _getUser()
#       console.log _user
#       return _user.groups
#   }

# NOTE: This is VERY SLOW. Do not use in a server endpoint!
# Fetches Discourse users, 100 at a time.
getAllUsers = co.wrap () ->
  page = 1
  users = []
  while true
    pageOfUsers = (yield request.getAsync({ url: getUrl('/admin/users/list/all.json', {show_emails: true, page}), json: true })).body
    console.log "Got a page of #{pageOfUsers.length} users (#{pageOfUsers[0]?.id})"
    if pageOfUsers.length is 0
      break
    users = users.concat(pageOfUsers)
    page += 1
  return users

user = (_username) ->
  _getUser = _.once co.wrap ->
    res = yield request.getAsync({ url: getUrl("/users/#{_username}.json"), json: true })
    foundUser = res.body.user
    if not foundUser
      throw new Error('Discourse: No user found with that name!')
    return foundUser
  return {
    get: co.wrap ->
      _user = yield _getUser()
      return _user
    getGroups: co.wrap ->
      _user = yield _getUser()
      console.log _user
      return _user.groups
  }
  

group = (_groupName) ->
  getGroupByName = _.once co.wrap (name) ->
    res = yield request.getAsync({ url: getUrl('/groups/search.json'), json: true })
    groups = res.body
    foundGroup = _.find(groups, { name })
    if not foundGroup
      throw new Error('Discourse: No group found with that name!')
    return foundGroup
  return {
    getUsers: co.wrap ->
      _group = yield getGroupByName(_groupName) # Maybe not necessary for get users? Since we can use group name
      res = yield request.getAsync({ url: getUrl("/groups/#{_group.name}/members.json"), json: true })
      users = res.body
      # TODO: Handle response limit (if #members > 20)
      return users
    addUsers: co.wrap (usernames) ->
      _group = yield getGroupByName(_groupName)
      if _.isArray(usernames)
        usernames = usernames.join(',')
      res = yield request.putAsync({
        url: getUrl("/groups/#{_group.id}/members.json"),
        json: { usernames }
      })
      if res.body.errors
        throw new Error('Error adding user go Discourse group: \n'+res.body.errors.join('\n'))
      return #res.body.success
    removeUser: co.wrap (user_id) -> # Discourse user.id, not CoCo userID
      _group = yield getGroupByName(_groupName)
      _group = yield getGroupByName(_groupName) # Maybe not necessary for get users? Since we can use group name
      res = yield request.delAsync({
        url: getUrl("/groups/#{_group.id}/members.json"),
        json: { user_id }
      })
      console.log res.body
      return
  }
  
discourse = {
  getAllUsers
  user
  group
}

module.exports = discourse

# (co.wrap () ->
#   console.log yield discourse.group('verified_teachers').getUsers()
#   phoenix = yield discourse.user('phoenix').get()
#   console.log yield discourse.group('verified_teachers').removeUser(phoenix.id)
#   console.log yield discourse.group('verified_teachers').getUsers()
#   console.log yield discourse.group('verified_teachers').addUsers('phoenix')
#   console.log yield discourse.group('verified_teachers').getUsers()
#   # users = discourse.getAllUsers()
#   # console.log _.map(users, 'email')
#   # console.log users.length
# )().catch((e) ->
#   # console.log "Error:", e
#   console.log e.stack
# )
