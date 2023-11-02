describe 'Local Mongo queries', ->
  LocalMongo = require 'lib/LocalMongo'

  beforeEach ->
    @fixture1 =
      'id': 'somestring'
      'value': 9000
      'levels': [3, 8, 21]
      'worth': 6
      'type': 'unicorn'
      'likes': ['poptarts', 'popsicles', 'popcorn']
      nested: {
        str:'ing'
      }

    @fixture2 = this: is: so: 'deep'

  it 'regular match of a property', ->
    expect(LocalMongo.matchesQuery(@fixture1, 'gender': 'unicorn')).toBeFalsy()
    expect(LocalMongo.matchesQuery(@fixture1, 'type': 'unicorn')).toBeTruthy()
    expect(LocalMongo.matchesQuery(@fixture1, 'type': 'zebra')).toBeFalsy()
    expect(LocalMongo.matchesQuery(@fixture1, 'type': 'unicorn', 'id': 'somestring')).toBeTruthy()

  it 'array match of a property', ->
    expect(LocalMongo.matchesQuery(@fixture1, 'likes': 'poptarts')).toBeTruthy()
    expect(LocalMongo.matchesQuery(@fixture1, 'likes': 'walks on the beach')).toBeFalsy()

  it 'nested match', ->
    expect(LocalMongo.matchesQuery(@fixture2, 'this.is.so': 'deep')).toBeTruthy()
    expect(LocalMongo.matchesQuery(@fixture2, {this:{is:{so: 'deep'}}})).toBeTruthy()
    expect(LocalMongo.matchesQuery(@fixture2, {'this.is':{so: 'deep'}})).toBeTruthy()
    mixedQuery = { nested: {str:'ing'}, worth: {$gt:3} }
    expect(LocalMongo.matchesQuery(@fixture1, mixedQuery)).toBeTruthy()
    expect(LocalMongo.matchesQuery(@fixture2, mixedQuery)).toBeFalsy()

  it '$gt selector', ->
    expect(LocalMongo.matchesQuery(@fixture1, 'value': '$gt': 8000)).toBeTruthy()
    expect(LocalMongo.matchesQuery(@fixture1, 'value': '$gt': [8000, 10000])).toBeTruthy()
    expect(LocalMongo.matchesQuery(@fixture1, 'levels': '$gt': [10, 20, 30])).toBeTruthy()
    expect(LocalMongo.matchesQuery(@fixture1, 'value': '$gt': 9000)).toBeFalsy()
    expect(LocalMongo.matchesQuery(@fixture1, 'value': {'$gt': 8000}, 'worth': {'$gt': 5})).toBeTruthy()

  it '$gte selector', ->
    expect(LocalMongo.matchesQuery(@fixture1, 'value': '$gte': 9001)).toBeFalsy()
    expect(LocalMongo.matchesQuery(@fixture1, 'value': '$gte': 9000)).toBeTruthy()
    expect(LocalMongo.matchesQuery(@fixture1, 'value': '$gte': [9000, 10000])).toBeTruthy()
    expect(LocalMongo.matchesQuery(@fixture1, 'levels': '$gte': [21, 30])).toBeTruthy()

  it '$lt selector', ->
    expect(LocalMongo.matchesQuery(@fixture1, 'value': '$lt': 9001)).toBeTruthy()
    expect(LocalMongo.matchesQuery(@fixture1, 'value': '$lt': 9000)).toBeFalsy()
    expect(LocalMongo.matchesQuery(@fixture1, 'value': '$lt': [9001, 9000])).toBeTruthy()
    expect(LocalMongo.matchesQuery(@fixture1, 'levels': '$lt': [10, 20, 30])).toBeTruthy()
    expect(LocalMongo.matchesQuery(@fixture1, 'value': {'$lt': 9001}, 'worth': {'$lt': 7})).toBeTruthy()

  it '$lte selector', ->
    expect(LocalMongo.matchesQuery(@fixture1, 'value': '$lte': 9000)).toBeTruthy()
    expect(LocalMongo.matchesQuery(@fixture1, 'value': '$lte': 8000)).toBeFalsy()
    expect(LocalMongo.matchesQuery(@fixture1, 'value': {'$lte': 9000}, 'worth': {'$lte': [6, 5]})).toBeTruthy()

  it '$ne selector', ->
    expect(LocalMongo.matchesQuery(@fixture1, 'value': '$ne': 9000)).toBeFalsy()
    expect(LocalMongo.matchesQuery(@fixture1, 'id': '$ne': 'otherstring')).toBeTruthy()
    expect(LocalMongo.matchesQuery(@fixture1, 'id': '$ne': ['otherstring', 'somestring'])).toBeFalsy()
    expect(LocalMongo.matchesQuery(@fixture1, 'likes': '$ne': ['popcorn', 'chicken'])).toBeFalsy()

  it '$in selector', ->
    expect(LocalMongo.matchesQuery(@fixture1, 'type': '$in': ['unicorn', 'zebra'])).toBeTruthy()
    expect(LocalMongo.matchesQuery(@fixture1, 'type': '$in': ['cats', 'dogs'])).toBeFalsy()
    expect(LocalMongo.matchesQuery(@fixture1, 'likes': '$in': ['popcorn', 'chicken'])).toBeTruthy()

  it '$nin selector', ->
    expect(LocalMongo.matchesQuery(@fixture1, 'type': '$nin': ['unicorn', 'zebra'])).toBeFalsy()
    expect(LocalMongo.matchesQuery(@fixture1, 'type': '$nin': ['cats', 'dogs'])).toBeTruthy()
    expect(LocalMongo.matchesQuery(@fixture1, 'likes': '$nin': ['popcorn', 'chicken'])).toBeFalsy()

  it '$or operator', ->
    expect(LocalMongo.matchesQuery(@fixture1, $or: [{value: 9000}, {type: 'zebra'}])).toBeTruthy()
    expect(LocalMongo.matchesQuery(@fixture1, $or: [{value: 9001}, {worth: '$lt': 10}])).toBeTruthy()

  it '$and operator', ->
    expect(LocalMongo.matchesQuery(@fixture1, $and: [{value: 9000}, {type: 'zebra'}])).toBeFalsy()
    expect(LocalMongo.matchesQuery(@fixture1, $and: [{value: 9000}, {type: 'unicorn'}])).toBeTruthy()
    expect(LocalMongo.matchesQuery(@fixture1, $and: [{value: '$gte': 9000}, {worth: '$lt': 10}])).toBeTruthy()

  it '$exists operator', ->
    expect(LocalMongo.matchesQuery(@fixture1, type: $exists: true)).toBeTruthy()
    expect(LocalMongo.matchesQuery(@fixture1, interesting: $exists: false)).toBeTruthy()
