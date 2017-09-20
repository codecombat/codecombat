TreemaUtils = require '../../bower_components/treema/treema-utils.js'

exports.updateI18NCoverage = (doc) ->
  # TODO: Share this code between server and client (client version in CocoModel)
  langCodeArrays = []
  pathToData = {}

  #  console.log 'doc schema', doc.schema.statics.jsonSchema, doc.schema
  TreemaUtils.walk(doc.toObject(), doc.schema.statics.jsonSchema, null, (path, data, workingSchema) ->
    # Store parent data for the next block...
    if data?.i18n
      pathToData[path] = data

    if _.str.endsWith path, 'i18n'
      i18n = data

      # grab the parent data
      parentPath = path[0...-5]
      parentData = pathToData[parentPath]

      # use it to determine what properties actually need to be translated
      props = workingSchema.props or []
      props = (prop for prop in props when parentData[prop] and prop not in ['sound', 'soundTriggers'])
      return unless props.length
      return if 'additionalProperties' of i18n  # Workaround for #2630: Programmable is weird

      # get a list of lang codes where its object has keys for every prop to be translated
      coverage = _.filter(_.keys(i18n), (langCode) ->
        translations = i18n[langCode]
        translations and _.all((translations[prop] for prop in props))
      )
      #console.log 'got coverage', coverage, 'for', path, props, workingSchema, parentData
      langCodeArrays.push coverage
  )

  return unless langCodeArrays.length
  # language codes that are covered for every i18n object are fully covered
  overallCoverage = _.intersection(langCodeArrays...)
  doc.set('i18nCoverage', overallCoverage)
