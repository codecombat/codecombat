describe 'Local Mongo queries', ->
  LocalMongo = require 'lib/LocalMongo'
  console.warn 'matchesQuery' in LocalMongo

  beforeEach ->
    this.fixture1 =
      'id': 'somestring'
      'value': 9000
      'worth': 6
      'type': 'unicorn'
      'likes': ['poptarts', 'popsicles', 'popcorn']

  it 'regular match of a property', ->
    expect(LocalMongo.matchesQuery(this.fixture1, 'gender': 'unicorn')).toBeFalsy()
    expect(LocalMongo.matchesQuery(this.fixture1, 'type':'unicorn')).toBeTruthy()
    expect(LocalMongo.matchesQuery(this.fixture1, 'type':'zebra')).toBeFalsy()
    expect(LocalMongo.matchesQuery(this.fixture1, 'type':'unicorn', 'id':'somestring')).toBeTruthy()

  xit 'array match of a property', ->
    expect(LocalMongo.matchesQuery(this.fixture1, 'likes':'poptarts')).toBeTruthy()
    expect(LocalMongo.matchesQuery(this.fixture1, 'likes':'walks on the beach')).toBeFalsy()

  xit '$gt selector', ->
    expect(LocalMongo.matchesQuery(this.fixture1, 'value': '$gt': 8000)).toBeTruthy()
    expect(LocalMongo.matchesQuery(this.fixture1, 'value': '$gt': [8000, 10000])).toBeTruthy()
    expect(LocalMongo.matchesQuery(this.fixture1, 'value': '$gt': 9000)).toBeFalsy()
    expect(LocalMongo.matchesQuery(this.fixture1, 'value': {'$gt': 8000}, 'worth': {'$gt': 5})).toBeTruthy()

  xit '$gte selector', ->
    expect(LocalMongo.matchesQuery(this.fixture1, 'value': '$gte': 9001)).toBeFalsy()
    expect(LocalMongo.matchesQuery(this.fixture1, 'value': '$gte': 9000)).toBeTruthy()
    expect(LocalMongo.matchesQuery(this.fixture1, 'value': '$gte': [9000, 10000])).toBeTruthy()

  xit '$in selector', ->
    expect(LocalMongo.matchesQuery(this.fixture1, 'type': '$in': ['unicorn', 'zebra'])).toBeTruthy()
    expect(LocalMongo.matchesQuery(this.fixture1, 'type': '$in': ['cats', 'dogs'])).toBeFalsy()
    expect(LocalMongo.matchesQuery(this.fixture1, 'likes': '$in': ['popcorn', 'chicken'])).toBeTruthy()

  xit '$lt selector', ->
    expect(LocalMongo.matchesQuery(this.fixture1, 'value': '$lt': 9001)).toBeTruthy()
    expect(LocalMongo.matchesQuery(this.fixture1, 'value': '$lt': 9000)).toBeFalsy()
    expect(LocalMongo.matchesQuery(this.fixture1, 'value': {'$lt': 9001}, 'worth': {'$lt': 7})).toBeTruthy()

  xit '$lte selector', ->
    expect(LocalMongo.matchesQuery(this.fixture1, 'value': '$lte': 9000)).toBeTruthy()
    expect(LocalMongo.matchesQuery(this.fixture1, 'value': '$lte': 8000)).toBeFalsy()
    expect(LocalMongo.matchesQuery(this.fixture1, 'value': {'$lte': 9000}, 'value': {'$lte': [6, 5]})).toBeTruthy()

  xit '$ne selector', ->
    expect(LocalMongo.matchesQuery(this.fixture1, 'value': '$ne': 9000)).toBeFalsy()
    expect(LocalMongo.matchesQuery(this.fixture1, 'id': '$ne': 'otherstring')).toBeTruthy()
    expect(LocalMongo.matchesQuery(this.fixture1, 'id': '$ne': ['otherstring', 'somestring'])).toBeFalsy()

  xit '$in selector', ->
    expect(LocalMongo.matchesQuery(this.fixture1, 'type': '$nin': ['unicorn', 'zebra'])).toBeFalsy()
    expect(LocalMongo.matchesQuery(this.fixture1, 'type': '$nin': ['cats', 'dogs'])).toBeTruthy()
    expect(LocalMongo.matchesQuery(this.fixture1, 'likes': '$nin': ['popcorn', 'chicken'])).toBeFalsy()

