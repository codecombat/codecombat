# Not paired with a document in the DB, just handles coordinating between
# the stripe property in the user with what's being stored in Stripe.

Handler = require '../commons/Handler'
config = require '../../server_config'
stripe = require('stripe')(config.stripe.secretKey)

class DiscountHandler extends Handler
  logDiscountError: (req, msg) ->
    console.warn "Discount Error: #{req.user.get('slug')} (#{req.user._id}): '#{msg}'"

  discountUser: (req, user, done) ->
    if (not user) or user.isAnonymous()
      return done({res: 'User must not be anonymous.', code: 403})

    couponID = req.body.stripe.couponID
    if not couponID
      @logDiscountError(req, 'Missing couponID.')
      return done({res: 'Missing couponID.', code: 422})
      
    stripe.coupons.retrieve couponID, (err, coupon) =>
      if (err)
        return done({res: 'No coupon with id '+couponID, code: 404})
        
      if customerID = user.get('stripe')?.customerID
        options = { coupon: coupon.id }
        stripe.customers.update customerID, options, (err, customer) =>
          if err
            @logDiscountError(req, 'Error applying coupon to customer'+customerID)
            return done({res: 'Error applying coupon to customer.', code: 500})
          done()
        
      else
        # couponID will be set on the user by the handler
        done()

  removeDiscountFromCustomer: (req, user, done) ->
    customerID = user.get('stripe').customerID
    return done() unless customerID
    
    stripe.customers.deleteDiscount customerID, (err, customer) =>
      if err
        console.log 'err?', err
        @logDiscountError(req, 'Error removing coupon from customer ' + customerID)
        return done({res: 'Error applying coupon to customer.', code: 500})
      done()
      
module.exports = new DiscountHandler()