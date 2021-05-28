import { loadStripe } from '@stripe/stripe-js'

async function getStripeLib() {
  const isProd = document.location.href.includes('codecombat.com')
  const STRIPE_PUBLISHABLE_KEY = isProd ? 'pk_live_27jQZozjDGN1HSUTnSuM578g' : 'pk_test_BqKtc6bIKPn6FeSA4GhuRrwT'
  return loadStripe(STRIPE_PUBLISHABLE_KEY);
}

module.exports = {
  getStripeLib
};
