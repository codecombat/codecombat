mongoose = require('mongoose')
deltas = require '../../app/lib/deltas'
log = require 'winston'
{handlers} = require '../commons/mapping'

PurchaseSchema = new mongoose.Schema({status: String}, {strict: false})
PurchaseSchema.index({recipient: 1, 'purchase.original': 1}, {unique: true, name: 'unique purchase'})

module.exports = mongoose.model('purchase', PurchaseSchema)
