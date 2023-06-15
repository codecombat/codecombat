const storage = require('core/storage')
const TEMPORARY_PREMIUM_KEY = 'temporary-premium-access'
const TRACKED_PREMIUM = 'tracked-premium'

function setTemporaryPremiumAccess() {
  storage.save(`${TEMPORARY_PREMIUM_KEY}-${me.get('_id')}`, true, 3)
}

function hasTemporaryPremiumAccess() {
  return storage.load(`${TEMPORARY_PREMIUM_KEY}-${me.get('_id')}`)
}

function setTrackedPremiumPurchase() {
  storage.save(`${TRACKED_PREMIUM}-${me.get('_id')}`, true, 6 * 60)
}

function hasTrackedPremiumAccess() {
  return storage.load(`${TRACKED_PREMIUM}-${me.get('_id')}`)
}

function getTrackingData ({ amount, duration }) {
  const options = {}
  if (amount) {
    const numericalAmount = parseInt(amount)
    options.purchaseAmount = numericalAmount
    options.currency = 'USD'
    options.predictedLtv = numericalAmount * getLtvMultiplier(duration)
  }
  return options
}

function getLtvMultiplier (duration) {
  if (!duration)
    return 1
  if (duration.includes('year'))
    return 2
  if (duration.includes('month')) {
    const interval = parseInt(duration.split('_')[0])
    // assuming user will pay us for a year, so if user pays monthly, multiply by 12.
    // If user pays quarterly, multiply by 12 / 3 = 4
    return Math.round(12 / interval)
  }
  return 1
}

module.exports = {
  setTemporaryPremiumAccess,
  hasTemporaryPremiumAccess,
  setTrackedPremiumPurchase,
  hasTrackedPremiumAccess,
  getTrackingData
}
