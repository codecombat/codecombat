deltasLib = require '../../app/core/deltas'

exports.isJustFillingTranslations = (delta) ->
  flattened = deltasLib.flattenDelta(delta)
  _.all flattened, (delta) ->
    # sometimes coverage gets moved around... allow other changes to happen to i18nCoverage
    return false unless _.isArray(delta.o)
    return true if 'i18nCoverage' in delta.dataPath
    return false unless delta.o.length is 1
    index = delta.deltaPath.indexOf('i18n')
    return false if index is -1
    return false if delta.deltaPath[index+1] in ['en', 'en-US', 'en-GB']  # English speakers are most likely just spamming, so always treat those as patches, not saves.
    return true
