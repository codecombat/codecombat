# Usage:
# > coffee scripts/node/2016-12-14-autotag-concepts.coffee run

require('coffee-script');
require('coffee-script/register');

_ = require 'lodash'
str = require 'underscore.string'
concepts = require '../../app/schemas/concepts'
esper = require '../../bower_components/esper.js/esper.modern.js'

getSolutions = (level) ->
  return [] unless hero = _.find (level.get("thangs") ? []), id: 'Hero Placeholder'
  return [] unless plan = _.find(hero.components ? [], (x) -> x.config?.programmableMethods?.plan)?.config.programmableMethods.plan
  solutions = _.cloneDeep plan.solutions ? []
  for solution in solutions
    try
      solution.source = _.template(solution.source)(plan.context)
    catch e
      console.error "Problem with template and solution comments for", level.get('slug'), e
  solutions

tagSolution = (solution) ->
  code = solution.source
  engine = new esper.Engine()
  try
    engine.load(code)
    ast = engine.evaluator.ast
  catch err
    console.error err
    return null
  result = []
  for key of concepts
    tkn = concepts[key].tagger
    continue unless tkn
    if typeof tkn is 'function'
      result.push concepts[key].concept if tkn(ast)
    else
      result.push concepts[key].concept if ast.find(tkn).length > 0
  result

exports.run = ->
  mongoose = require 'mongoose'
  Level = require '../../server/models/Level'
  query = Level.find(slug: {$exists: true}, concepts: {$exists: true})
  modified = 0
  saved = 0
  query.exec (err, levels) ->
    console.log "Found #{levels.length} levels with concepts."
    for level in levels
      unless solution = _.find getSolutions(level), {language: 'javascript'}
        console.log "No solution for", level.get('name'), '\n'
        continue
      oldTags = level.get('concepts')
      autoTags = tagSolution solution
      unless autoTags?
        console.log "Couldn't parse solution for #{level.get('name')}\n#{solution.source}"
        continue
      console.log 'Find concepts for', level.get('name')#, '\n' + solution.source
      console.log "Old     : #{oldTags.join(', ')}"
      console.log "Concepts: #{autoTags.join(', ')}"
      combinedTags = autoTags.concat (tag for tag in oldTags when _.find(concepts, (concept) -> concept.concept is tag and not concept.automatic and not concept.deprecated))
      console.log "Combined: #{combinedTags.join(', ')}\n"
      if _.isEqual _.clone(oldTags).sort(), _.clone(combinedTags).sort()
        console.log 'No change--skipping'
        continue
      level.set('concepts', combinedTags)
      level.save (err, result) ->
        if err
          console.log 'err saving', err
        else
          saved += 1
          console.log 'Saved', saved, 'levels.'
      modified += 1

    console.log("Modified #{modified} / #{levels.length} levels.")

if _.last(process.argv) is 'run'
  database = require '../../server/commons/database'
  mongoose = require 'mongoose'

  ### SET UP ###
  do (setupLodash = this) ->
    GLOBAL._ = require 'lodash'
    _.str = require 'underscore.string'
    _.mixin _.str.exports()
    GLOBAL.tv4 = require('tv4').tv4

  database.connect()
  exports.run()
