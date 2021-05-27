const fetchJson = require('./fetch-json');

const createPaymentCustomerPortal = () => {
  return fetchJson('/db/payments/customer-portal', {
    method: 'POST',
  });
}

module.exports = {
  createPaymentCustomerPortal
};
