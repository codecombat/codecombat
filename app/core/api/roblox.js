import fetchJson from './fetch-json';

export default {
  waitlistSignup (options) {
    return fetchJson('/roblox/waitlist-signup', {
      method: 'POST',
      json: options
    })
  }
};
