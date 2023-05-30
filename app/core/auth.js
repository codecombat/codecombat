// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let addLoggerGlobalContext;
import { backboneFailure, genericFailure, parseServerError } from 'core/errors';
import User from 'models/User';
import storage from 'core/storage';
const BEEN_HERE_BEFORE_KEY = 'beenHereBefore';
import { getQueryVariable, isOzaria } from 'core/utils';
import api from 'core/api';

if (isOzaria) {
  ({ addLoggerGlobalContext } = require('ozaria/site/common/logger'));
}

const init = function() {
  export const me = window.me = new User(window.userObject); // inserted into main.html
  module.exports.me.onLoaded();

  trackFirstArrival();
  if (isOzaria) {
    addLoggerGlobalContext('userId', window.me.get('_id'));
  }

  // set country and geo fields for returning users if not set during account creation (/server/models/User - makeNew)
  if (!me.get('country')) {
    api.users.setCountryGeo()
    .then(function(res) {
      me.set(res);
      return setTestGroupNumberUS();}).catch(e => console.error("Error in setting country and geo:", e));
  }
  if (me && (me.get('testGroupNumber') == null)) {
    // Assign testGroupNumber to returning visitors; new ones in server/routes/auth
    me.set('testGroupNumber', Math.floor(Math.random() * 256));
    me.patch();
  }
  setTestGroupNumberUS();
  const preferredLanguage = getQueryVariable('preferredLanguage');
  if (me && preferredLanguage) {
    me.set('preferredLanguage', preferredLanguage);
    me.save();
  }

  return Backbone.listenTo(me, 'sync', () => Backbone.Mediator.publish('auth:me-synced', {me}));
};

export const logoutUser = function(options) {
  if (options == null) { options = {}; }
  if (options.error == null) { options.error = genericFailure; }
  return me.logout(options);
};

export const sendRecoveryEmail = function(email, options) {
  if (options == null) { options = {}; }
  options = _.merge(options,
    {method: 'POST', url: '/auth/reset', data: { email }}
  );
  return $.ajax(options);
};

const onSetVolume = function(e) {
  if (e.volume === me.get('volume')) { return; }
  me.set('volume', e.volume);
  return me.save();
};

Backbone.Mediator.subscribe('level:set-volume', onSetVolume, module.exports);

var trackFirstArrival = function() {
  // will have to filter out users who log in with existing accounts separately
  // but can at least not track logouts as first arrivals using local storage
  const beenHereBefore = storage.load(BEEN_HERE_BEFORE_KEY);
  if (beenHereBefore) { return; }
  if (window.tracker != null) {
    window.tracker.trackEvent('First Arrived');
  }
  return storage.save(BEEN_HERE_BEFORE_KEY, true);
};

var setTestGroupNumberUS = function() {
  if (me && (me.get("country") === 'united-states') && (me.get('testGroupNumberUS') == null)) {
    // Assign testGroupNumberUS to returning visitors; new ones in server/models/User
    me.set('testGroupNumberUS', Math.floor(Math.random() * 256));
    return me.patch();
  }
};

init();
