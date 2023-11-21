Language = require './language'
parserHolder = {}

module.exports = class CPP extends Language
  name: 'C++'
  id: 'cpp'
  parserID: 'cpp'

  constructor: ->
    super arguments...

  hasChangedASTs: (a, b) -> true
  usesFunctionWrapping: () -> false

  obviouslyCannotTranspile: (rawCode) ->
    false
