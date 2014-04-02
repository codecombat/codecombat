/**
 * |-------------------|
 * | Backbone-Mediator |
 * |-------------------|
 *  Backbone-Mediator is freely distributable under the MIT license.
 *
 *  <a href="https://github.com/chalbert/Backbone-Mediator">More details & documentation</a>
 *
 * @author Nicolas Gilbert
 * @author Ruben Vereecken
 *
 * @requires _
 * @requires Backbone
 * @requires tv4
 */
(function(factory){
    'use strict';

    if (typeof define === 'function' && define.amd) {
        define(['underscore', 'backbone'], factory);
    } else {
        factory(_, Backbone);
    }

})(function (_, Backbone){
    'use strict';

    /**
     * @static
     */
    var channels = {},
        Subscriber,
        /** @borrows Backbone.View#delegateEvents */
        delegateEvents = Backbone.View.prototype.delegateEvents,
        /** @borrows Backbone.View#delegateEvents */
        undelegateEvents = Backbone.View.prototype.undelegateEvents;

    /**
     * @class
     */
    Backbone.Mediator = {
        tv4: window['tv4'].freshApi(),

        validationEnabled: true,

        defSchemas: {},

        channelSchemas: {},

        addChannelSchema: function(channel, schema) {
            this.channelSchemas[channel] = schema;
        },

        addDefSchema: function(schema) {
            this.tv4.addSchema(schema);
        },

        addChannelSchemas: function(schemas) {
            for (var key in schemas) {
                this.channelSchemas[key] = schemas[key];
            }
        },

        addDefSchemas: function(schemas) {
            for (var key in schemas) {
                this.tv4.addSchema(schemas[key]);
            }
        },

        /**
         * Sets up the tv4 validator.
         */
        setUpValidator: function() {
            this.tv4 = window['tv4'].freshApi();
        },

        setValidationEnabled: function(enabled) {
            this.validationEnabled = enabled;
        },

        /**
         * Subscribe to a channel
         *
         * @param channel
         */
        subscribe: function(channel, subscription, context, once) {
            if (!channels[channel]) channels[channel] = [];
            channels[channel].push({fn: subscription, context: context || this, once: once});
        },

        /**
         * Trigger all callbacks for a channel
         *
         * @param channel
         * @params N Extra parametter to pass to handler
         */
        publish: function(channel, arg) {
            if (!channels[channel]) return;

            if (channel in this.channelSchemas && this.validationEnabled) {
                var valid = this.tv4.validate(arg, this.channelSchemas[channel]);
                if (!valid) {
                    console.error("Dropping published object because of validation error.");
                    console.error(arg);
                    console.error(this.tv4.error);
                    return;
                } else if (this.tv4.missing.length) {
                    console.warn("Missing schema reference to " + this.tv4.missing[0]);
                } else {
                    console.debug("Validation successful");
                    console.debug(arg);
                }
            }

            var subscription;

            for (var i = 0; i < channels[channel].length; i++) {
                subscription = channels[channel][i];
                subscription.fn.call(subscription.context, arg);
                if (subscription.once) {
                    Backbone.Mediator.unsubscribe(channel, subscription.fn, subscription.context);
                    i--;
                }
            }
        },

        /**
         * Cancel subscription
         *
         * @param channel
         * @param fn
         * @param context
         */

        unsubscribe: function(channel, fn, context){
            if (!channels[channel]) return;

            var subscription;
            for (var i = 0; i < channels[channel].length; i++) {
                subscription = channels[channel][i];
                if (subscription.fn === fn && subscription.context === context) {
                    channels[channel].splice(i, 1);
                    i--;
                }
            }
        },

        /**
         * Subscribing to one event only
         *
         * @param channel
         * @param subscription
         * @param context
         */
        subscribeOnce: function (channel, subscription, context) {
            Backbone.Mediator.subscribe(channel, subscription, context, true);
        }

    };

    /**
     * Allow to define convention-based subscriptions
     * as an 'subscriptions' hash on a view. Subscriptions
     * can then be easily setup and cleaned.
     *
     * @class
     */


    Subscriber = {

        /**
         * Extend delegateEvents() to set subscriptions
         */
        delegateEvents: function(){
            delegateEvents.apply(this, arguments);
            this.setSubscriptions();
        },

        /**
         * Extend undelegateEvents() to unset subscriptions
         */
        undelegateEvents: function(){
            undelegateEvents.apply(this, arguments);
            this.unsetSubscriptions();
        },

        /** @property {Object} List of subscriptions, to be defined */
        subscriptions: {},

        /**
         * Subscribe to each subscription
         * @param {Object} [subscriptions] An optional hash of subscription to add
         */

        setSubscriptions: function(subscriptions){
            if (subscriptions) _.extend(this.subscriptions || {}, subscriptions);
            subscriptions = subscriptions || this.subscriptions;
            if (!subscriptions || _.isEmpty(subscriptions)) return;
            // Just to be sure we don't set duplicate
            this.unsetSubscriptions(subscriptions);

            _.each(subscriptions, function(subscription, channel){
                var once;
                if (subscription.$once) {
                    subscription = subscription.$once;
                    once = true;
                }
                if (_.isString(subscription)) {
                    subscription = this[subscription];
                }
                Backbone.Mediator.subscribe(channel, subscription, this, once);
            }, this);
        },

        /**
         * Unsubscribe to each subscription
         * @param {Object} [subscriptions] An optional hash of subscription to remove
         */
        unsetSubscriptions: function(subscriptions){
            subscriptions = subscriptions || this.subscriptions;
            if (!subscriptions || _.isEmpty(subscriptions)) return;
            _.each(subscriptions, function(subscription, channel){
                if (_.isString(subscription)) {
                    subscription = this[subscription];
                }
                Backbone.Mediator.unsubscribe(channel, subscription.$once || subscription, this);
            }, this);
        }
    };

    /**
     * @lends Backbone.View.prototype
     */
    _.extend(Backbone.View.prototype, Subscriber);

    /**
     * @lends Backbone.Mediator
     */
    _.extend(Backbone.Mediator, {
        /**
         * Shortcut for publish
         * @function
         */
        pub: Backbone.Mediator.publish,
        /**
         * Shortcut for subscribe
         * @function
         */
        sub: Backbone.Mediator.subscribe
    });

    return Backbone;

});