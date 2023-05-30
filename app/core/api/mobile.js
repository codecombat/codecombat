import fetchJson from './fetch-json';

export default {
  register (options) {
    return fetchJson('/mobile/new-registration', {
      method: 'POST',
      json: options
    })
  }
};
