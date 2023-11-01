/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS103: Rewrite code to no longer use __guard__, or convert again using --optional-chaining
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let FacebookHandler;
const CocoClass = require('core/CocoClass');
const {me} = require('core/auth');
const {backboneFailure} = require('core/errors');
const storage = require('core/storage');

// facebook user object props to
const userPropsToSave = {
  'first_name': 'firstName',
  'last_name': 'lastName',
  'gender': 'gender',
  'email': 'email',
  'id': 'facebookID'
};

module.exports = (FacebookHandler = (FacebookHandler = (function() {
  FacebookHandler = class FacebookHandler extends CocoClass {
    static initClass() {
  
      this.prototype.startedLoading = false;
      this.prototype.apiLoaded = false;
      this.prototype.connected = false;
      this.prototype.person = null;
    }
    constructor() {
      if (!me.useSocialSignOn()) { throw new Error('Social single sign on not supported'); }
      super();
    }

    token() { return (this.authResponse != null ? this.authResponse.accessToken : undefined); }

    fakeAPI() {
      window.FB = {
        login(cb, options) {
          return cb({status: 'connected', authResponse: { accessToken: '1234' }});
        },
        api(url, options, cb) {
          return cb({
            first_name: 'Mr',
            last_name: 'Bean',
            id: 'abcd',
            email: 'some@email.com'
          });
        }
      };

      this.startedLoading = true;
      return this.apiLoaded = true;
    }

    loadAPI(options) {
      if (options == null) { options = {}; }
      if (options.success == null) { options.success = _.noop; }
      if (options.context == null) { options.context = options; }
      if (this.apiLoaded) {
        options.success.bind(options.context)();
      } else {
        this.once('load-api', options.success, options.context);
      }

      if (!this.startedLoading) {
        // Load the SDK asynchronously
        this.startedLoading = true;
        (function(d) {
          let js = undefined;
          const id = 'facebook-jssdk';
          const ref = d.getElementsByTagName('script')[0];
          if (d.getElementById(id)) { return; }
          js = d.createElement('script');
          js.id = id;
          js.async = true;
          js.src = '//connect.facebook.net/en_US/sdk.js';

          //js.src = '//connect.facebook.net/en_US/all/debug.js'
          ref.parentNode.insertBefore(js, ref);
        })(document);

        return window.fbAsyncInit = () => {
          FB.init({
            appId: (document.location.origin === 'http://localhost:3000' ? '607435142676437' : '148832601965463'), // App ID
            channelUrl: document.location.origin + '/channel.html', // Channel File
            cookie: true, // enable cookies to allow the server to access the session
            xfbml: true, // parse XFBML
            version: 'v3.2'
          });
          return FB.getLoginStatus(response => {
            if (response.status === 'connected') {
              this.connected = true;
              this.authResponse = response.authResponse;
              this.trigger('connect', { response });
            }
            this.apiLoaded = true;
            return this.trigger('load-api');
          });
        };
      }
    }


    connect(options) {
      if (options == null) { options = {}; }
      if (options.success == null) { options.success = _.noop; }
      if (options.context == null) { options.context = options; }
      return FB.login((response => {
        if (response.status === 'connected') {
          this.connected = true;
          this.authResponse = response.authResponse;
          this.trigger('connect', { response });
          return options.success.bind(options.context)();
        }
      }
      ), {scope: 'email'});
    }


    loadPerson(options) {
      if (options == null) { options = {}; }
      if (options.success == null) { options.success = _.noop; }
      if (options.context == null) { options.context = options; }
      return FB.api('/me', {fields: 'email,last_name,first_name,gender'}, person => {
        const attrs = {};
        for (var fbProp in userPropsToSave) {
          var userProp = userPropsToSave[fbProp];
          var value = person[fbProp];
          if (value) {
            attrs[userProp] = value;
          }
        }
        this.trigger('load-person', attrs);
        return options.success.bind(options.context)(attrs);
      });
    }

    renderButtons() {
      if (__guard__(typeof FB !== 'undefined' && FB !== null ? FB.XFBML : undefined, x => x.parse)) { return setTimeout(FB.XFBML.parse, 10); }
    }
  };
  FacebookHandler.initClass();
  return FacebookHandler;  // Handles FB login and Like
})()));

function __guard__(value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined;
}