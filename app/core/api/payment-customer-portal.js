import fetchJson from './fetch-json';

const createPaymentCustomerPortal = () => {
  return fetchJson('/db/payments/customer-portal', {
    method: 'POST',
  });
}

export default {
  createPaymentCustomerPortal
};
