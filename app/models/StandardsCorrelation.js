import CocoModel from 'app/models/CocoModel'
import schema from 'schemas/models/standards_correlation.schema'

class StandardsCorrelation extends CocoModel { }

StandardsCorrelation.className = 'StandardsCorrelation'
StandardsCorrelation.schema = schema
StandardsCorrelation.urlRoot = '/db/standards'
StandardsCorrelation.prototype.urlRoot = '/db/standards'

module.exports = StandardsCorrelation
