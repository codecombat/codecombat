config = require '../../server_config'
stripe = require('stripe')(config.stripe.secretKey)
User = require '../users/User'
Payment = require '../payments/Payment'
errors = require '../commons/errors'

module.exports.setup = (app) ->
  app.post '/stripe/webhook', (req, res) ->
    if req.body.type is 'invoice.payment_succeeded' # if they actually paid, give em some gems

      invoiceID = req.body.data.object.id
      stripe.invoices.retrieve invoiceID, (err, invoice) =>
        return res.send(500, '') if err
        return res.send(200, '') unless invoice.total # invoices made when trialing, probably given for people who resubscribe after unsubscribing
        
        stripe.customers.retrieve invoice.customer, (err, customer) =>
          return res.send(500, '') if err
          
          userID = customer.metadata.id
          User.findById userID, (err, user) =>
            return res.send(500, '') if err
            return res.send(200) if not user # just for the sake of testing...
            
            Payment.findOne {'stripe.invoiceID': invoiceID}, (err, payment) =>
              return res.send(200, '') if payment
              payment = new Payment({
                'purchaser': user._id
                'recipient': user._id
                'created': new Date().toISOString()
                'service': 'stripe'
                'amount': invoice.total
                'gems': 3500
                'stripe': {
                  customerID: invoice.customer
                  invoiceID: invoice.id
                  subscriptionID: 'basic'
                }
              })
              payment.save (err) =>
                return res.send(500, '') if err
                
                Payment.find({recipient: user._id}).select('gems').exec (err, payments) ->
                  gems = _.reduce payments, ((sum, p) -> sum + p.get('gems')), 0
                  purchased = _.clone(user.get('purchased'))
                  purchased ?= {}
                  purchased.gems = gems
                  user.set('purchased', purchased)
                  user.save (err) ->
                    return res.send(500, '') if err
                    return res.send(201, '')

    else if req.body.type is 'customer.subscription.deleted'
      User.findOne {'stripe.subscriptionID': req.body.data.object.id}, (err, user) ->
        return res.send(200, '') unless user

        stripeInfo = _.cloneDeep(user.get('stripe'))
        delete stripeInfo.planID
        delete stripeInfo.subscriptionID
        user.set('stripe', stripeInfo)
        user.save (err) =>
          return res.send(500, '') if err
          return res.send(200, '')

    else # ignore all other notifications
      return res.send(200, '')
      
  app.get '/stripe/coupons', (req, res) ->
    return errors.forbidden(res) unless req.user?.isAdmin()
    stripe.coupons.list {limit: 100}, (err, coupons) ->
      return errors.serverError(res) if err
      res.send(200, coupons.data)
      return res.end()
      
    