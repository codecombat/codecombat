Handler = require '../commons/Handler'
AnalyticsStripeInvoice = require './../models/AnalyticsStripeInvoice'

class AnalyticsStripeInvoiceHandler extends Handler
  modelClass: AnalyticsStripeInvoice
  jsonSchema: require '../../app/schemas/models/analytics_stripe_invoice'

  hasAccess: (req) -> req.user?.isAdmin()

  getByRelationship: (req, res, args...) ->
    return @sendForbiddenError(res) unless @hasAccess(req)
    return @getAll(req, res) if args[1] is 'all'
    super(arguments...)

  getAll: (req, res) ->
    AnalyticsStripeInvoice.find {}, (err, docs) =>
      return @sendDatabaseError(res, err) if err
      @sendSuccess(res, docs)

module.exports = new AnalyticsStripeInvoiceHandler()
