

//##############################################################################
// version.js
//##############################################################################

this.createjs = this.createjs || {};

(function () {

	/**
	 * Static class holding library specific information such as the version and buildDate of the library.
	 * The SoundJS class has been renamed {{#crossLink "Sound"}}{{/crossLink}}.  Please see {{#crossLink "Sound"}}{{/crossLink}}
	 * for information on using sound.
	 * @class SoundJS
	 **/
	var s = createjs.SoundJS = createjs.SoundJS || {};

	/**
	 * The version string for this release.
	 * @property version
	 * @type String
	 * @static
	 **/
	s.version = /*=version*/""; // injected by build process

	/**
	 * The build date for this release in UTC format.
	 * @property buildDate
	 * @type String
	 * @static
	 **/
	s.buildDate = /*=date*/""; // injected by build process

})();

//##############################################################################
// extend.js
//##############################################################################

this.createjs = this.createjs||{};

/**
 * @class Utility Methods
 */

/**
 * Sets up the prototype chain and constructor property for a new class.
 *
 * This should be called right after creating the class constructor.
 *
 * 	function MySubClass() {}
 * 	createjs.extend(MySubClass, MySuperClass);
 * 	ClassB.prototype.doSomething = function() { }
 *
 * 	var foo = new MySubClass();
 * 	console.log(foo instanceof MySuperClass); // true
 * 	console.log(foo.prototype.constructor === MySubClass); // true
 *
 * @method extends
 * @param {Function} subclass The subclass.
 * @param {Function} superclass The superclass to extend.
 * @return {Function} Returns the subclass's new prototype.
 */
createjs.extend = function(subclass, superclass) {
	"use strict";

	function o() { this.constructor = subclass; }
	o.prototype = superclass.prototype;
	return (subclass.prototype = new o());
};

//##############################################################################
// promote.js
//##############################################################################

this.createjs = this.createjs||{};

/**
 * @class Utility Methods
 */

/**
 * Promotes any methods on the super class that were overridden, by creating an alias in the format `prefix_methodName`.
 * It is recommended to use the super class's name as the prefix.
 * An alias to the super class's constructor is always added in the format `prefix_constructor`.
 * This allows the subclass to call super class methods without using `function.call`, providing better performance.
 *
 * For example, if `MySubClass` extends `MySuperClass`, and both define a `draw` method, then calling `promote(MySubClass, "MySuperClass")`
 * would add a `MySuperClass_constructor` method to MySubClass and promote the `draw` method on `MySuperClass` to the
 * prototype of `MySubClass` as `MySuperClass_draw`.
 *
 * This should be called after the class's prototype is fully defined.
 *
 * 	function ClassA(name) {
 * 		this.name = name;
 * 	}
 * 	ClassA.prototype.greet = function() {
 * 		return "Hello "+this.name;
 * 	}
 *
 * 	function ClassB(name, punctuation) {
 * 		this.ClassA_constructor(name);
 * 		this.punctuation = punctuation;
 * 	}
 * 	createjs.extend(ClassB, ClassA);
 * 	ClassB.prototype.greet = function() {
 * 		return this.ClassA_greet()+this.punctuation;
 * 	}
 * 	createjs.promote(ClassB, "ClassA");
 *
 * 	var foo = new ClassB("World", "!?!");
 * 	console.log(foo.greet()); // Hello World!?!
 *
 * @method promote
 * @param {Function} subclass The class to promote super class methods on.
 * @param {String} prefix The prefix to add to the promoted method names. Usually the name of the superclass.
 * @return {Function} Returns the subclass.
 */
createjs.promote = function(subclass, prefix) {
	"use strict";

	var subP = subclass.prototype, supP = (Object.getPrototypeOf&&Object.getPrototypeOf(subP))||subP.__proto__;
	if (supP) {
		subP[(prefix+="_") + "constructor"] = supP.constructor; // constructor is not always innumerable
		for (var n in supP) {
			if (subP.hasOwnProperty(n) && (typeof supP[n] == "function")) { subP[prefix + n] = supP[n]; }
		}
	}
	return subclass;
};

//##############################################################################
// IndexOf.js
//##############################################################################

this.createjs = this.createjs||{};

/**
 * @class Utility Methods
 */

/**
 * Finds the first occurrence of a specified value searchElement in the passed in array, and returns the index of
 * that value.  Returns -1 if value is not found.
 *
 *      var i = createjs.indexOf(myArray, myElementToFind);
 *
 * @method indexOf
 * @param {Array} array Array to search for searchElement
 * @param searchElement Element to find in array.
 * @return {Number} The first index of searchElement in array.
 */
createjs.indexOf = function (array, searchElement){
	"use strict";

	for (var i = 0,l=array.length; i < l; i++) {
		if (searchElement === array[i]) {
			return i;
		}
	}
	return -1;
};

//##############################################################################
// Proxy.js
//##############################################################################

this.createjs = this.createjs||{};

/**
 * Various utilities that the CreateJS Suite uses. Utilities are created as separate files, and will be available on the
 * createjs namespace directly.
 *
 * <h4>Example</h4>
 *
 *      myObject.addEventListener("change", createjs.proxy(myMethod, scope));
 *
 * @class Utility Methods
 * @main Utility Methods
 */

(function() {
	"use strict";

	/**
	 * A function proxy for methods. By default, JavaScript methods do not maintain scope, so passing a method as a
	 * callback will result in the method getting called in the scope of the caller. Using a proxy ensures that the
	 * method gets called in the correct scope.
	 *
	 * Additional arguments can be passed that will be applied to the function when it is called.
	 *
	 * <h4>Example</h4>
	 *
	 *      myObject.addEventListener("event", createjs.proxy(myHandler, this, arg1, arg2));
	 *
	 *      function myHandler(arg1, arg2) {
	 *           // This gets called when myObject.myCallback is executed.
	 *      }
	 *
	 * @method proxy
	 * @param {Function} method The function to call
	 * @param {Object} scope The scope to call the method name on
	 * @param {mixed} [arg] * Arguments that are appended to the callback for additional params.
	 * @public
	 * @static
	 */
	createjs.proxy = function (method, scope) {
		var aArgs = Array.prototype.slice.call(arguments, 2);
		return function () {
			return method.apply(scope, Array.prototype.slice.call(arguments, 0).concat(aArgs));
		};
	}

}());

//##############################################################################
// definePropertySupported.js
//##############################################################################

this.createjs = this.createjs||{};

/**
 * @class Utility Methods
 */
(function() {
	"use strict";

	/**
	 * Boolean value indicating if Object.defineProperty is supported.
	 *
	 * <h4>Example</h4>
	 *
	 *      if (createjs.definePropertySupported) { // add getter / setter}
	 *
	 * @property definePropertySupported
	 * @type {Boolean}
	 * @default true
	 */
	var t = Object.defineProperty ? true : false;

	// IE8 has Object.defineProperty, but only for DOM objects, so check if fails to suppress errors
	var foo = {};
	try {
		Object.defineProperty(foo, "bar", {
			get: function () {
				return this._bar;
			},
			set: function (value) {
				this._bar = value;
			}
		});
	} catch (e) {
		t = false;
	}

	createjs.definePropertySupported = t;
}());

//##############################################################################
// BrowserDetect.js
//##############################################################################

this.createjs = this.createjs||{};

/**
 * @class Utility Methods
 */
(function() {
	"use strict";

	/**
	 * An object that determines the current browser, version, operating system, and other environment
	 * variables via user agent string.
	 *
	 * Used for audio because feature detection is unable to detect the many limitations of mobile devices.
	 *
	 * <h4>Example</h4>
	 *
	 *      if (createjs.BrowserDetect.isIOS) { // do stuff }
	 *
	 * @property BrowserDetect
	 * @type {Object}
	 * @param {Boolean} isFirefox True if our browser is Firefox.
	 * @param {Boolean} isOpera True if our browser is opera.
	 * @param {Boolean} isChrome True if our browser is Chrome.  Note that Chrome for Android returns true, but is a
	 * completely different browser with different abilities.
	 * @param {Boolean} isIOS True if our browser is safari for iOS devices (iPad, iPhone, and iPod).
	 * @param {Boolean} isAndroid True if our browser is Android.
	 * @param {Boolean} isBlackberry True if our browser is Blackberry.
	 * @constructor
	 * @static
	 */
	function BrowserDetect() {
		throw "BrowserDetect cannot be instantiated";
	};

	var agent = BrowserDetect.agent = window.navigator.userAgent;
	BrowserDetect.isWindowPhone = (agent.indexOf("IEMobile") > -1) || (agent.indexOf("Windows Phone") > -1);
	BrowserDetect.isFirefox = (agent.indexOf("Firefox") > -1);
	BrowserDetect.isOpera = (window.opera != null);
	BrowserDetect.isChrome = (agent.indexOf("Chrome") > -1);  // NOTE that Chrome on Android returns true but is a completely different browser with different abilities
	BrowserDetect.isIOS = (agent.indexOf("iPod") > -1 || agent.indexOf("iPhone") > -1 || agent.indexOf("iPad") > -1) && !BrowserDetect.isWindowPhone;
	BrowserDetect.isAndroid = (agent.indexOf("Android") > -1) && !BrowserDetect.isWindowPhone;
	BrowserDetect.isBlackberry = (agent.indexOf("Blackberry") > -1);

	createjs.BrowserDetect = BrowserDetect;

}());

//##############################################################################
// EventDispatcher.js
//##############################################################################

this.createjs = this.createjs||{};

(function() {
	"use strict";


// constructor:
	/**
	 * EventDispatcher provides methods for managing queues of event listeners and dispatching events.
	 *
	 * You can either extend EventDispatcher or mix its methods into an existing prototype or instance by using the
	 * EventDispatcher {{#crossLink "EventDispatcher/initialize"}}{{/crossLink}} method.
	 * 
	 * Together with the CreateJS Event class, EventDispatcher provides an extended event model that is based on the
	 * DOM Level 2 event model, including addEventListener, removeEventListener, and dispatchEvent. It supports
	 * bubbling / capture, preventDefault, stopPropagation, stopImmediatePropagation, and handleEvent.
	 * 
	 * EventDispatcher also exposes a {{#crossLink "EventDispatcher/on"}}{{/crossLink}} method, which makes it easier
	 * to create scoped listeners, listeners that only run once, and listeners with associated arbitrary data. The 
	 * {{#crossLink "EventDispatcher/off"}}{{/crossLink}} method is merely an alias to
	 * {{#crossLink "EventDispatcher/removeEventListener"}}{{/crossLink}}.
	 * 
	 * Another addition to the DOM Level 2 model is the {{#crossLink "EventDispatcher/removeAllEventListeners"}}{{/crossLink}}
	 * method, which can be used to listeners for all events, or listeners for a specific event. The Event object also 
	 * includes a {{#crossLink "Event/remove"}}{{/crossLink}} method which removes the active listener.
	 *
	 * <h4>Example</h4>
	 * Add EventDispatcher capabilities to the "MyClass" class.
	 *
	 *      EventDispatcher.initialize(MyClass.prototype);
	 *
	 * Add an event (see {{#crossLink "EventDispatcher/addEventListener"}}{{/crossLink}}).
	 *
	 *      instance.addEventListener("eventName", handlerMethod);
	 *      function handlerMethod(event) {
	 *          console.log(event.target + " Was Clicked");
	 *      }
	 *
	 * <b>Maintaining proper scope</b><br />
	 * Scope (ie. "this") can be be a challenge with events. Using the {{#crossLink "EventDispatcher/on"}}{{/crossLink}}
	 * method to subscribe to events simplifies this.
	 *
	 *      instance.addEventListener("click", function(event) {
	 *          console.log(instance == this); // false, scope is ambiguous.
	 *      });
	 *      
	 *      instance.on("click", function(event) {
	 *          console.log(instance == this); // true, "on" uses dispatcher scope by default.
	 *      });
	 * 
	 * If you want to use addEventListener instead, you may want to use function.bind() or a similar proxy to manage scope.
	 *      
	 *
	 * @class EventDispatcher
	 * @constructor
	 **/
	function EventDispatcher() {
	
	
	// private properties:
		/**
		 * @protected
		 * @property _listeners
		 * @type Object
		 **/
		this._listeners = null;
		
		/**
		 * @protected
		 * @property _captureListeners
		 * @type Object
		 **/
		this._captureListeners = null;
	}
	var p = EventDispatcher.prototype;


// static public methods:
	/**
	 * Static initializer to mix EventDispatcher methods into a target object or prototype.
	 * 
	 * 		EventDispatcher.initialize(MyClass.prototype); // add to the prototype of the class
	 * 		EventDispatcher.initialize(myObject); // add to a specific instance
	 * 
	 * @method initialize
	 * @static
	 * @param {Object} target The target object to inject EventDispatcher methods into. This can be an instance or a
	 * prototype.
	 **/
	EventDispatcher.initialize = function(target) {
		target.addEventListener = p.addEventListener;
		target.on = p.on;
		target.removeEventListener = target.off =  p.removeEventListener;
		target.removeAllEventListeners = p.removeAllEventListeners;
		target.hasEventListener = p.hasEventListener;
		target.dispatchEvent = p.dispatchEvent;
		target._dispatchEvent = p._dispatchEvent;
		target.willTrigger = p.willTrigger;
	};
	

// public methods:
	/**
	 * Adds the specified event listener. Note that adding multiple listeners to the same function will result in
	 * multiple callbacks getting fired.
	 *
	 * <h4>Example</h4>
	 *
	 *      displayObject.addEventListener("click", handleClick);
	 *      function handleClick(event) {
	 *         // Click happened.
	 *      }
	 *
	 * @method addEventListener
	 * @param {String} type The string type of the event.
	 * @param {Function | Object} listener An object with a handleEvent method, or a function that will be called when
	 * the event is dispatched.
	 * @param {Boolean} [useCapture] For events that bubble, indicates whether to listen for the event in the capture or bubbling/target phase.
	 * @return {Function | Object} Returns the listener for chaining or assignment.
	 **/
	p.addEventListener = function(type, listener, useCapture) {
		var listeners;
		if (useCapture) {
			listeners = this._captureListeners = this._captureListeners||{};
		} else {
			listeners = this._listeners = this._listeners||{};
		}
		var arr = listeners[type];
		if (arr) { this.removeEventListener(type, listener, useCapture); }
		arr = listeners[type]; // remove may have deleted the array
		if (!arr) { listeners[type] = [listener];  }
		else { arr.push(listener); }
		return listener;
	};
	
	/**
	 * A shortcut method for using addEventListener that makes it easier to specify an execution scope, have a listener
	 * only run once, associate arbitrary data with the listener, and remove the listener.
	 * 
	 * This method works by creating an anonymous wrapper function and subscribing it with addEventListener.
	 * The created anonymous function is returned for use with .removeEventListener (or .off).
	 * 
	 * <h4>Example</h4>
	 * 
	 * 		var listener = myBtn.on("click", handleClick, null, false, {count:3});
	 * 		function handleClick(evt, data) {
	 * 			data.count -= 1;
	 * 			console.log(this == myBtn); // true - scope defaults to the dispatcher
	 * 			if (data.count == 0) {
	 * 				alert("clicked 3 times!");
	 * 				myBtn.off("click", listener);
	 * 				// alternately: evt.remove();
	 * 			}
	 * 		}
	 * 
	 * @method on
	 * @param {String} type The string type of the event.
	 * @param {Function | Object} listener An object with a handleEvent method, or a function that will be called when
	 * the event is dispatched.
	 * @param {Object} [scope] The scope to execute the listener in. Defaults to the dispatcher/currentTarget for function listeners, and to the listener itself for object listeners (ie. using handleEvent).
	 * @param {Boolean} [once=false] If true, the listener will remove itself after the first time it is triggered.
	 * @param {*} [data] Arbitrary data that will be included as the second parameter when the listener is called.
	 * @param {Boolean} [useCapture=false] For events that bubble, indicates whether to listen for the event in the capture or bubbling/target phase.
	 * @return {Function} Returns the anonymous function that was created and assigned as the listener. This is needed to remove the listener later using .removeEventListener.
	 **/
	p.on = function(type, listener, scope, once, data, useCapture) {
		if (listener.handleEvent) {
			scope = scope||listener;
			listener = listener.handleEvent;
		}
		scope = scope||this;
		return this.addEventListener(type, function(evt) {
				listener.call(scope, evt, data);
				once&&evt.remove();
			}, useCapture);
	};

	/**
	 * Removes the specified event listener.
	 *
	 * <b>Important Note:</b> that you must pass the exact function reference used when the event was added. If a proxy
	 * function, or function closure is used as the callback, the proxy/closure reference must be used - a new proxy or
	 * closure will not work.
	 *
	 * <h4>Example</h4>
	 *
	 *      displayObject.removeEventListener("click", handleClick);
	 *
	 * @method removeEventListener
	 * @param {String} type The string type of the event.
	 * @param {Function | Object} listener The listener function or object.
	 * @param {Boolean} [useCapture] For events that bubble, indicates whether to listen for the event in the capture or bubbling/target phase.
	 **/
	p.removeEventListener = function(type, listener, useCapture) {
		var listeners = useCapture ? this._captureListeners : this._listeners;
		if (!listeners) { return; }
		var arr = listeners[type];
		if (!arr) { return; }
		for (var i=0,l=arr.length; i<l; i++) {
			if (arr[i] == listener) {
				if (l==1) { delete(listeners[type]); } // allows for faster checks.
				else { arr.splice(i,1); }
				break;
			}
		}
	};
	
	/**
	 * A shortcut to the removeEventListener method, with the same parameters and return value. This is a companion to the
	 * .on method.
	 *
	 * @method off
	 * @param {String} type The string type of the event.
	 * @param {Function | Object} listener The listener function or object.
	 * @param {Boolean} [useCapture] For events that bubble, indicates whether to listen for the event in the capture or bubbling/target phase.
	 **/
	p.off = p.removeEventListener;

	/**
	 * Removes all listeners for the specified type, or all listeners of all types.
	 *
	 * <h4>Example</h4>
	 *
	 *      // Remove all listeners
	 *      displayObject.removeAllEventListeners();
	 *
	 *      // Remove all click listeners
	 *      displayObject.removeAllEventListeners("click");
	 *
	 * @method removeAllEventListeners
	 * @param {String} [type] The string type of the event. If omitted, all listeners for all types will be removed.
	 **/
	p.removeAllEventListeners = function(type) {
		if (!type) { this._listeners = this._captureListeners = null; }
		else {
			if (this._listeners) { delete(this._listeners[type]); }
			if (this._captureListeners) { delete(this._captureListeners[type]); }
		}
	};

	/**
	 * Dispatches the specified event to all listeners.
	 *
	 * <h4>Example</h4>
	 *
	 *      // Use a string event
	 *      this.dispatchEvent("complete");
	 *
	 *      // Use an Event instance
	 *      var event = new createjs.Event("progress");
	 *      this.dispatchEvent(event);
	 *
	 * @method dispatchEvent
	 * @param {Object | String | Event} eventObj An object with a "type" property, or a string type.
	 * While a generic object will work, it is recommended to use a CreateJS Event instance. If a string is used,
	 * dispatchEvent will construct an Event instance with the specified type.
	 * @return {Boolean} Returns the value of eventObj.defaultPrevented.
	 **/
	p.dispatchEvent = function(eventObj) {
		if (typeof eventObj == "string") {
			// won't bubble, so skip everything if there's no listeners:
			var listeners = this._listeners;
			if (!listeners || !listeners[eventObj]) { return false; }
			eventObj = new createjs.Event(eventObj);
		} else if (eventObj.target && eventObj.clone) {
			// redispatching an active event object, so clone it:
			eventObj = eventObj.clone();
		}
		try { eventObj.target = this; } catch (e) {} // try/catch allows redispatching of native events

		if (!eventObj.bubbles || !this.parent) {
			this._dispatchEvent(eventObj, 2);
		} else {
			var top=this, list=[top];
			while (top.parent) { list.push(top = top.parent); }
			var i, l=list.length;

			// capture & atTarget
			for (i=l-1; i>=0 && !eventObj.propagationStopped; i--) {
				list[i]._dispatchEvent(eventObj, 1+(i==0));
			}
			// bubbling
			for (i=1; i<l && !eventObj.propagationStopped; i++) {
				list[i]._dispatchEvent(eventObj, 3);
			}
		}
		return eventObj.defaultPrevented;
	};

	/**
	 * Indicates whether there is at least one listener for the specified event type.
	 * @method hasEventListener
	 * @param {String} type The string type of the event.
	 * @return {Boolean} Returns true if there is at least one listener for the specified event.
	 **/
	p.hasEventListener = function(type) {
		var listeners = this._listeners, captureListeners = this._captureListeners;
		return !!((listeners && listeners[type]) || (captureListeners && captureListeners[type]));
	};
	
	/**
	 * Indicates whether there is at least one listener for the specified event type on this object or any of its
	 * ancestors (parent, parent's parent, etc). A return value of true indicates that if a bubbling event of the
	 * specified type is dispatched from this object, it will trigger at least one listener.
	 * 
	 * This is similar to {{#crossLink "EventDispatcher/hasEventListener"}}{{/crossLink}}, but it searches the entire
	 * event flow for a listener, not just this object.
	 * @method willTrigger
	 * @param {String} type The string type of the event.
	 * @return {Boolean} Returns `true` if there is at least one listener for the specified event.
	 **/
	p.willTrigger = function(type) {
		var o = this;
		while (o) {
			if (o.hasEventListener(type)) { return true; }
			o = o.parent;
		}
		return false;
	};

	/**
	 * @method toString
	 * @return {String} a string representation of the instance.
	 **/
	p.toString = function() {
		return "[EventDispatcher]";
	};


// private methods:
	/**
	 * @method _dispatchEvent
	 * @param {Object | String | Event} eventObj
	 * @param {Object} eventPhase
	 * @protected
	 **/
	p._dispatchEvent = function(eventObj, eventPhase) {
		var l, listeners = (eventPhase==1) ? this._captureListeners : this._listeners;
		if (eventObj && listeners) {
			var arr = listeners[eventObj.type];
			if (!arr||!(l=arr.length)) { return; }
			try { eventObj.currentTarget = this; } catch (e) {}
			try { eventObj.eventPhase = eventPhase; } catch (e) {}
			eventObj.removed = false;
			arr = arr.slice(); // to avoid issues with items being removed or added during the dispatch
			for (var i=0; i<l && !eventObj.immediatePropagationStopped; i++) {
				var o = arr[i];
				if (o.handleEvent) { o.handleEvent(eventObj); }
				else { o(eventObj); }
				if (eventObj.removed) {
					this.off(eventObj.type, o, eventPhase==1);
					eventObj.removed = false;
				}
			}
		}
	};


	createjs.EventDispatcher = EventDispatcher;
}());

//##############################################################################
// Event.js
//##############################################################################

this.createjs = this.createjs||{};

(function() {
	"use strict";

// constructor:
	/**
	 * Contains properties and methods shared by all events for use with
	 * {{#crossLink "EventDispatcher"}}{{/crossLink}}.
	 * 
	 * Note that Event objects are often reused, so you should never
	 * rely on an event object's state outside of the call stack it was received in.
	 * @class Event
	 * @param {String} type The event type.
	 * @param {Boolean} bubbles Indicates whether the event will bubble through the display list.
	 * @param {Boolean} cancelable Indicates whether the default behaviour of this event can be cancelled.
	 * @constructor
	 **/
	function Event(type, bubbles, cancelable) {
		
	
	// public properties:
		/**
		 * The type of event.
		 * @property type
		 * @type String
		 **/
		this.type = type;
	
		/**
		 * The object that generated an event.
		 * @property target
		 * @type Object
		 * @default null
		 * @readonly
		*/
		this.target = null;
	
		/**
		 * The current target that a bubbling event is being dispatched from. For non-bubbling events, this will
		 * always be the same as target. For example, if childObj.parent = parentObj, and a bubbling event
		 * is generated from childObj, then a listener on parentObj would receive the event with
		 * target=childObj (the original target) and currentTarget=parentObj (where the listener was added).
		 * @property currentTarget
		 * @type Object
		 * @default null
		 * @readonly
		*/
		this.currentTarget = null;
	
		/**
		 * For bubbling events, this indicates the current event phase:<OL>
		 * 	<LI> capture phase: starting from the top parent to the target</LI>
		 * 	<LI> at target phase: currently being dispatched from the target</LI>
		 * 	<LI> bubbling phase: from the target to the top parent</LI>
		 * </OL>
		 * @property eventPhase
		 * @type Number
		 * @default 0
		 * @readonly
		*/
		this.eventPhase = 0;
	
		/**
		 * Indicates whether the event will bubble through the display list.
		 * @property bubbles
		 * @type Boolean
		 * @default false
		 * @readonly
		*/
		this.bubbles = !!bubbles;
	
		/**
		 * Indicates whether the default behaviour of this event can be cancelled via
		 * {{#crossLink "Event/preventDefault"}}{{/crossLink}}. This is set via the Event constructor.
		 * @property cancelable
		 * @type Boolean
		 * @default false
		 * @readonly
		*/
		this.cancelable = !!cancelable;
	
		/**
		 * The epoch time at which this event was created.
		 * @property timeStamp
		 * @type Number
		 * @default 0
		 * @readonly
		*/
		this.timeStamp = (new Date()).getTime();
	
		/**
		 * Indicates if {{#crossLink "Event/preventDefault"}}{{/crossLink}} has been called
		 * on this event.
		 * @property defaultPrevented
		 * @type Boolean
		 * @default false
		 * @readonly
		*/
		this.defaultPrevented = false;
	
		/**
		 * Indicates if {{#crossLink "Event/stopPropagation"}}{{/crossLink}} or
		 * {{#crossLink "Event/stopImmediatePropagation"}}{{/crossLink}} has been called on this event.
		 * @property propagationStopped
		 * @type Boolean
		 * @default false
		 * @readonly
		*/
		this.propagationStopped = false;
	
		/**
		 * Indicates if {{#crossLink "Event/stopImmediatePropagation"}}{{/crossLink}} has been called
		 * on this event.
		 * @property immediatePropagationStopped
		 * @type Boolean
		 * @default false
		 * @readonly
		*/
		this.immediatePropagationStopped = false;
		
		/**
		 * Indicates if {{#crossLink "Event/remove"}}{{/crossLink}} has been called on this event.
		 * @property removed
		 * @type Boolean
		 * @default false
		 * @readonly
		*/
		this.removed = false;
	}
	var p = Event.prototype;
	

// public methods:
	/**
	 * Sets {{#crossLink "Event/defaultPrevented"}}{{/crossLink}} to true.
	 * Mirrors the DOM event standard.
	 * @method preventDefault
	 **/
	p.preventDefault = function() {
		this.defaultPrevented = this.cancelable&&true;
	};

	/**
	 * Sets {{#crossLink "Event/propagationStopped"}}{{/crossLink}} to true.
	 * Mirrors the DOM event standard.
	 * @method stopPropagation
	 **/
	p.stopPropagation = function() {
		this.propagationStopped = true;
	};

	/**
	 * Sets {{#crossLink "Event/propagationStopped"}}{{/crossLink}} and
	 * {{#crossLink "Event/immediatePropagationStopped"}}{{/crossLink}} to true.
	 * Mirrors the DOM event standard.
	 * @method stopImmediatePropagation
	 **/
	p.stopImmediatePropagation = function() {
		this.immediatePropagationStopped = this.propagationStopped = true;
	};
	
	/**
	 * Causes the active listener to be removed via removeEventListener();
	 * 
	 * 		myBtn.addEventListener("click", function(evt) {
	 * 			// do stuff...
	 * 			evt.remove(); // removes this listener.
	 * 		});
	 * 
	 * @method remove
	 **/
	p.remove = function() {
		this.removed = true;
	};
	
	/**
	 * Returns a clone of the Event instance.
	 * @method clone
	 * @return {Event} a clone of the Event instance.
	 **/
	p.clone = function() {
		return new Event(this.type, this.bubbles, this.cancelable);
	};
	
	/**
	 * Provides a chainable shortcut method for setting a number of properties on the instance.
	 *
	 * @method set
	 * @param {Object} props A generic object containing properties to copy to the instance.
	 * @return {Event} Returns the instance the method is called on (useful for chaining calls.)
	*/
	p.set = function(props) {
		for (var n in props) { this[n] = props[n]; }
		return this;
	};

	/**
	 * Returns a string representation of this object.
	 * @method toString
	 * @return {String} a string representation of the instance.
	 **/
	p.toString = function() {
		return "[Event (type="+this.type+")]";
	};

	createjs.Event = Event;
}());

//##############################################################################
// ErrorEvent.js
//##############################################################################

this.createjs = this.createjs||{};

(function() {
	"use strict";

	/**
	 * A general error event, which describes an error that occurred, as well as any details.
	 * @class ErrorEvent
	 * @param {String} [title] The error title
	 * @param {String} [message] The error description
	 * @param {Object} [data] Additional error data
	 * @constructor
	 */
	function ErrorEvent(title, message, data) {
		this.Event_constructor("error");

		/**
		 * The short error title, which indicates the type of error that occurred.
		 * @property title
		 * @type String
		 */
		this.title = title;

		/**
		 * The verbose error message, containing details about the error.
		 * @property message
		 * @type String
		 */
		this.message = message;

		/**
		 * Additional data attached to an error.
		 * @property data
		 * @type {Object}
		 */
		this.data = data;
	}

	var p = createjs.extend(ErrorEvent, createjs.Event);

	p.clone = function() {
		return new createjs.ErrorEvent(this.title, this.message, this.data);
	};

	createjs.ErrorEvent = createjs.promote(ErrorEvent, "Event");

}());

//##############################################################################
// ProgressEvent.js
//##############################################################################

this.createjs = this.createjs || {};

(function (scope) {
	"use strict";

	/**
	 * A createjs Event that is dispatched when progress changes.
	 * @class ProgressEvent
	 * @param {Number} loaded The amount that has been loaded. This can be any number relative to the total.
	 * @param {Number} [total] The total amount that will load. This will default to 0, so does not need to be passed in,
	 * as long as the loaded value is a progress value (between 0 and 1).
	 * @constructor
	 */
	function ProgressEvent(loaded, total) {
		this.Event_constructor("progress");

		/**
		 * The amount that has been loaded (out of a total amount)
		 * @property loaded
		 * @type {Number}
		 */
		this.loaded = loaded;

		/**
		 * The total "size" of the load.
		 * @oroperty size
		 * @type {Number}
		 * @default 1
		 */
		this.total = (total == null) ? 1 : total;

		/**
		 * The percentage (out of 1) that the load has been completed. This is calculated using `loaded/total`.
		 * @property progress
		 * @type {Number}
		 * @default 0
		 */
		this.progress = (total == 0) ? 0 : this.loaded / this.total;
	};

	var p = createjs.extend(ProgressEvent, createjs.Event);

	/**
	 * Returns a clone of the ProgressEvent instance.
	 * @method clone
	 * @return {ProgressEvent} a clone of the Event instance.
	 **/
	p.clone = function() {
		return new createjs.ProgressEvent(this.loaded, this.total);
	};

	createjs.ProgressEvent = createjs.promote(ProgressEvent, "Event");

}(window));

//##############################################################################
// LoadItem.js
//##############################################################################

this.createjs = this.createjs || {};

(function () {
	"use strict";

	/**
	 * @class LoadItem
	 *
	 * @constructor
	 */
	function LoadItem() {
		/**
		 * The source of the file that is being loaded. This property is <b>required</b>. The source can
		 * either be a string (recommended), or an HTML tag.</li>
		 *
		 * @type {null}
		 */
		this.src = null;

		/**
		 * The source of the file that is being loaded. This property is <b>required</b>. The source can
		 * either be a string (recommended), or an HTML tag.
		 *
		 * Check {{#crossLink "DataTypes"}}DataTypes{{/crossLink}} for the full list of supported types.
		 *
		 * @type {String|HTMLMediaElement|HTMLImageElement|HTMLLinkElement}
		 */
		this.type = createjs.AbstractLoader.TEXT;

		/**
		 * A string identifier which can be used to reference the loaded object.
		 *
		 * @type {String|Number}
		 */
		this.id = null;

		/**
		 * Set to `true` to ensure this asset loads in the order defined in the manifest. This
		 * will happen when the max connections has been set above 1 (using {{#crossLink "LoadQueue/setMaxConnections"}}{{/crossLink}}),
		 * and will only affect other assets also defined as `maintainOrder`. Everything else will finish as it is
		 * loaded. Ordered items are combined with script tags loading in order when {{#crossLink "LoadQueue/maintainScriptOrder:property"}}{{/crossLink}}
		 * is set to `true`.
		 *
		 * @type {boolean}
		 */
		this.maintainOrder = false;

		/**
		 * Optional, used for JSONP requests, to define what method to call when the JSONP is loaded.
		 *
		 * @type {String}
		 */
		this.callback = null;

		/**
		 * An arbitrary data object, which is included with the loaded object
		 *
		 * @type {Object}
		 */
		this.data = null;

		/**
		 * uUsed to define if this request uses GET or POST when sending data to the server. The default value is "GET"
		 *
		 * @type {String}
		 */
		this.method = createjs.LoadItem.GET;

		/**
		 * Optional object of name/value pairs to send to the server.
		 *
		 * @type {Object}
		 */
		this.values = null;

		/**
		 * Optional object hash of headers to attach to an XHR request. PreloadJS will automatically
		 * attach some default headers when required, including Origin, Content-Type, and X-Requested-With. You may
		 * override the default headers if needed.
		 *
		 * @type {Object}
		 */
		this.headers = null;

		/**
		 * Default false; Set to true if you need to enable credentials for XHR requests.
		 *
		 * @type {boolean}
		 */
		this.withCredentials = false;

		/**
		 * String, Default for text bases files (json, xml, text, css, js) "text/plain; charset=utf-8"; Sets the mime type of XHR.
		 *
		 * @type {String}
		 */
		this.mimeType = null;

		/**
		 * Sets the crossorigin attribute on images.
		 *
		 * @default Anonymous
		 *
		 * @type {boolean}
		 */
		this.crossOrigin = "Anonymous";

		/**
		 * how long before we stop a request.  Only applies to Tag loading and XHR level one loading.
		 *
		 * @type {number}
		 */
		this.loadTimeout = 8000;
	};

	var p = LoadItem.prototype = {};
	var s = LoadItem;

	s.create = function (value) {
		if (typeof value == "string") {
			var item = new LoadItem();
			item.src = value;
			return item;
		} else if (value instanceof s) {
			return value;
		} else if (value instanceof Object) { // Don't modify object, allows users to attach random data to the item.
			return value;
		} else {
			throw new Error("Type not recognized.");
		}
	};

	/**
	 * Provides a chainable shortcut method for setting a number of properties on the instance.
	 *
	 * <h4>Example</h4>
	 *
	 *      var loadItem = new createjs.LoadItem().set({src:"image.png", maintainOrder:true});
	 *
	 * @method set
	 * @param {Object} props A generic object containing properties to copy to the LoadItem instance.
	 * @return {LoadItem} Returns the instance the method is called on (useful for chaining calls.)
	*/
	p.set = function(props) {
		for (var n in props) { this[n] = props[n]; }
		return this;
	};

	createjs.LoadItem = s;

}());

//##############################################################################
// RequestUtils.js
//##############################################################################

(function () {

	var s = {};

	/**
	 * The Regular Expression used to test file URLS for an absolute path.
	 * @property ABSOLUTE_PATH
	 * @static
	 * @type {RegExp}
	 * @since 0.4.2
	 */
	s.ABSOLUTE_PATT = /^(?:\w+:)?\/{2}/i;

	/**
	 * The Regular Expression used to test file URLS for an absolute path.
	 * @property RELATIVE_PATH
	 * @static
	 * @type {RegExp}
	 * @since 0.4.2
	 */
	s.RELATIVE_PATT = (/^[./]*?\//i);

	/**
	 * The Regular Expression used to test file URLS for an extension. Note that URIs must already have the query string
	 * removed.
	 * @property EXTENSION_PATT
	 * @static
	 * @type {RegExp}
	 * @since 0.4.2
	 */
	s.EXTENSION_PATT = /\/?[^/]+\.(\w{1,5})$/i;

	/**
	 * @method _parseURI
	 * Parse a file path to determine the information we need to work with it. Currently, PreloadJS needs to know:
	 * <ul>
	 *     <li>If the path is absolute. Absolute paths start with a protocol (such as `http://`, `file://`, or
	 *     `//networkPath`)</li>
	 *     <li>If the path is relative. Relative paths start with `../` or `/path` (or similar)</li>
	 *     <li>The file extension. This is determined by the filename with an extension. Query strings are dropped, and
	 *     the file path is expected to follow the format `name.ext`.</li>
	 * </ul>
	 *
	 * <strong>Note:</strong> This has changed from earlier versions, which used a single, complicated Regular Expression, which
	 * was difficult to maintain, and over-aggressive in determining all file properties. It has been simplified to
	 * only pull out what it needs.
	 * @param path
	 * @returns {Object} An Object with an `absolute` and `relative` Boolean, as well as an optional 'extension` String
	 * property, which is the lowercase extension.
	 * @private
	 */
	s.parseURI = function (path) {
		var info = {absolute: false, relative: false};
		if (path == null) { return info; }

		// Drop the query string
		var queryIndex = path.indexOf("?");
		if (queryIndex > -1) {
			path = path.substr(0, queryIndex);
		}

		// Absolute
		var match;
		if (s.ABSOLUTE_PATT.test(path)) {
			info.absolute = true;

			// Relative
		} else if (s.RELATIVE_PATT.test(path)) {
			info.relative = true;
		}

		// Extension
		if (match = path.match(s.EXTENSION_PATT)) {
			info.extension = match[1].toLowerCase();
		}
		return info;
	};

	/**
	 * Formats an object into a query string for either a POST or GET request.
	 * @method _formatQueryString
	 * @param {Object} data The data to convert to a query string.
	 * @param {Array} [query] Existing name/value pairs to append on to this query.
	 * @private
	 */
	s.formatQueryString = function (data, query) {
		if (data == null) {
			throw new Error('You must specify data.');
		}
		var params = [];
		for (var n in data) {
			params.push(n + '=' + escape(data[n]));
		}
		if (query) {
			params = params.concat(query);
		}
		return params.join('&');
	};

	/**
	 * A utility method that builds a file path using a source and a data object, and formats it into a new path. All
	 * of the loaders in PreloadJS use this method to compile paths when loading.
	 * @method buildPath
	 * @param {String} src The source path to add values to.
	 * @param {Object} [data] Object used to append values to this request as a query string. Existing parameters on the
	 * path will be preserved.
	 * @returns {string} A formatted string that contains the path and the supplied parameters.
	 * @since 0.3.1
	 */
	s.buildPath = function (src, data) {
		if (data == null) {
			return src;
		}

		var query = [];
		var idx = src.indexOf('?');

		if (idx != -1) {
			var q = src.slice(idx + 1);
			query = query.concat(q.split('&'));
		}

		if (idx != -1) {
			return src.slice(0, idx) + '?' + this._formatQueryString(data, query);
		} else {
			return src + '?' + this._formatQueryString(data, query);
		}
	};

	/**
	 * @method _isCrossDomain
	 * @param {Object} item A load item with a `src` property
	 * @return {Boolean} If the load item is loading from a different domain than the current location.
	 * @private
	 */
	s.isCrossDomain = function (item) {
		var target = document.createElement("a");
		target.href = item.src;

		var host = document.createElement("a");
		host.href = location.href;

		var crossdomain = (target.hostname != "") &&
						  (target.port != host.port ||
						   target.protocol != host.protocol ||
						   target.hostname != host.hostname);
		return crossdomain;
	};

	/**
	 * @method _isLocal
	 * @param {Object} item A load item with a `src` property
	 * @return {Boolean} If the load item is loading from the "file:" protocol. Assume that the host must be local as
	 * well.
	 * @private
	 */
	s.isLocal = function (item) {
		var target = document.createElement("a");
		target.href = item.src;
		return target.hostname == "" && target.protocol == "file:";
	};

	/**
	 * Determine if a specific type should be loaded as a binary file. Currently, only images and items marked
	 * specifically as "binary" are loaded as binary. Note that audio is <b>not</b> a binary type, as we can not play
	 * back using an audio tag if it is loaded as binary. Plugins can change the item type to binary to ensure they get
	 * a binary result to work with. Binary files are loaded using XHR2.
	 * @method isBinary
	 * @param {String} type The item type.
	 * @return {Boolean} If the specified type is binary.
	 * @private
	 */
	s.isBinary = function (type) {
		switch (type) {
			case createjs.AbstractLoader.IMAGE:
			case createjs.AbstractLoader.BINARY:
				return true;
			default:
				return false;
		}
	};

	/**
	 * Utility function to check if item is a valid HTMLImageElement
	 *
	 * @param item {object}
	 * @returns {boolean}
	 */
	s.isImageTag = function(item) {
		return item instanceof HTMLImageElement;
	};

	/**
	 * Utility function to check if item is a valid HTMLAudioElement
	 *
	 * @param item
	 * @returns {boolean}
	 */
	s.isAudioTag = function(item) {
		if (window.HTMLAudioElement) {
			return item instanceof HTMLAudioElement;
		} else {
			return false;
		}
	};

	/**
	 * Utility function to check if item is a valid HTMLVideoElement
	 *
	 * @param item
	 * @returns {boolean}
	 */
	s.isVideoTag = function(item) {
		if (window.HTMLVideoElement) {
			return item instanceof HTMLVideoElement;
		} else {
			false;
		}
	};

	/**
	 * Determine if a specific type is a text based asset, and should be loaded as UTF-8.
	 * @method isText
	 * @param {String} type The item type.
	 * @return {Boolean} If the specified type is text.
	 * @private
	 */
	s.isText = function (type) {
		switch (type) {
			case createjs.AbstractLoader.TEXT:
			case createjs.AbstractLoader.JSON:
			case createjs.AbstractLoader.MANIFEST:
			case createjs.AbstractLoader.XML:
			case createjs.AbstractLoader.HTML:
			case createjs.AbstractLoader.CSS:
			case createjs.AbstractLoader.SVG:
			case createjs.AbstractLoader.JAVASCRIPT:
				return true;
			default:
				return false;
		}
	};

	/**
	 * Determine the type of the object using common extensions. Note that the type can be passed in with the load item
	 * if it is an unusual extension.
	 * @param {String} extension The file extension to use to determine the load type.
	 * @return {String} The determined load type (for example, <code>AbstractLoader.IMAGE</code> or null if it can not be
	 * determined by the extension.
	 * @private
	 */
	s.getTypeByExtension = function (extension) {
		if (extension == null) {
			return createjs.AbstractLoader.TEXT;
		}

		switch (extension.toLowerCase()) {
			case "jpeg":
			case "jpg":
			case "gif":
			case "png":
			case "webp":
			case "bmp":
				return createjs.AbstractLoader.IMAGE;
			case "ogg":
			case "mp3":
			case "webm":
				return createjs.AbstractLoader.SOUND;
			case "mp4":
			case "webm":
			case "ts":
				return createjs.AbstractLoader.VIDEO;
			case "json":
				return createjs.AbstractLoader.JSON;
			case "xml":
				return createjs.AbstractLoader.XML;
			case "css":
				return createjs.AbstractLoader.CSS;
			case "js":
				return createjs.AbstractLoader.JAVASCRIPT;
			case 'svg':
				return createjs.AbstractLoader.SVG;
			default:
				return createjs.AbstractLoader.TEXT;
		}
	};

	createjs.RequestUtils = s;

}());

//##############################################################################
// AbstractLoader.js
//##############################################################################

this.createjs = this.createjs || {};

(function () {
	"use strict";

// constructor
	/**
	 * The base loader, which defines all the generic methods, properties, and events. All loaders extend this class,
	 * including the {{#crossLink "LoadQueue"}}{{/crossLink}}.
	 * @class AbstractLoader
	 * @param {LoadItem|object|string} The item to be loaded.
	 * @param {Boolean} [preferXHR] Determines if the LoadItem should <em>try</em> and load using XHR, or take a
	 * tag-based approach, which can be better in cross-domain situations. Not all loaders can load using one or the
	 * other, so this is a suggested directive.
	 * @oaram {String} [type] The type of loader. Loader types are defined as constants on the AbstractLoader class,
	 * such as {{#crossLink "IMAGE:property"}}{{/crossLink}}, {{#crossLink "CSS:property"}}{{/crossLink}}, etc.
	 * @extends EventDispatcher
	 */
	function AbstractLoader(loadItem, preferXHR, type) {
		this.EventDispatcher_constructor();

		// public properties
		/**
		 * If the loader has completed loading. This provides a quick check, but also ensures that the different approaches
		 * used for loading do not pile up resulting in more than one <code>complete</code> event.
		 * @property loaded
		 * @type {Boolean}
		 * @default false
		 */
		this.loaded = false;

		/**
		 * Determine if the loader was canceled. Canceled loads will not fire complete events. Note that
		 * {{#crossLink "LoadQueue"}}{{/crossLink}} queues should be closed using {{#crossLink "AbstractLoader/close"}}{{/crossLink}}
		 * instead of setting this property.
		 * @property canceled
		 * @type {Boolean}
		 * @default false
		 */
		this.canceled = false;

		/**
		 * The current load progress (percentage) for this item. This will be a number between 0 and 1.
		 *
		 * <h4>Example</h4>
		 *
		 *     var queue = new createjs.LoadQueue();
		 *     queue.loadFile("largeImage.png");
		 *     queue.on("progress", function() {
		 *         console.log("Progress:", queue.progress, event.progress);
		 *     });
		 *
		 * @property progress
		 * @type {Number}
		 * @default 0
		 */
		this.progress = 0;

		/**
		 * The type of this item.
		 * See {{#crossLink}}DataTypes{{/crossLink}} for a full list of supported types.
		 *
		 * @type {null}
		 */
		this.type = type;

		// protected properties
		/**
		 * The item this loader represents. Note that this is null in a {{#crossLink "LoadQueue"}}{{/crossLink}}, but will
		 * be available on loaders such as {{#crossLink "XMLLoader"}}{{/crossLink}} and {{#crossLink "ImageLoader"}}{{/crossLink}}.
		 * @property _item
		 * @type {Object}
		 * @private
		 */
		if (loadItem) {
			this._item = createjs.LoadItem.create(loadItem);
		} else {
			this._item = null;
		}

		this._preferXHR = preferXHR;

		this._rawResult = null;

		/**
		 * A list of items that loaders load behind the scenes. This does not include the main item the loader is
		 * responsible for loading. Examples of loaders that have subitems include the {{#crossLink "SpriteSheetLoader"}}{{/crossLink}} and
		 * {{#crossLink "ManifestLoader"}}{{/crossLink}}.
		 * @property _loadItems
		 * @type {null}
		 * @protected
		 */
		this._loadedItems = null;
	};

	var p = createjs.extend(AbstractLoader, createjs.EventDispatcher);
	var s = AbstractLoader;

	/**
	 * Defines a POST request, use for a method value when loading data.
	 * @property POST
	 * @type {string}
	 * @default post
	 */
	s.POST = "POST";

	/**
	 * Defines a GET request, use for a method value when loading data.
	 * @property GET
	 * @type {string}
	 * @default get
	 */
	s.GET = "GET";

	/**
	 * The preload type for generic binary types. Note that images are loaded as binary files when using XHR.
	 * @property BINARY
	 * @type {String}
	 * @default binary
	 * @static
	 * @since 0.6.0
	 */
	s.BINARY = "binary";

	/**
	 * The preload type for css files. CSS files are loaded using a &lt;link&gt; when loaded with XHR, or a
	 * &lt;style&gt; tag when loaded with tags.
	 * @property CSS
	 * @type {String}
	 * @default css
	 * @static
	 * @since 0.6.0
	 */
	s.CSS = "css";

	/**
	 * The preload type for image files, usually png, gif, or jpg/jpeg. Images are loaded into an &lt;image&gt; tag.
	 * @property IMAGE
	 * @type {String}
	 * @default image
	 * @static
	 * @since 0.6.0
	 */
	s.IMAGE = "image";

	/**
	 * The preload type for javascript files, usually with the "js" file extension. JavaScript files are loaded into a
	 * &lt;script&gt; tag.
	 *
	 * Since version 0.4.1+, due to how tag-loaded scripts work, all JavaScript files are automatically injected into
	 * the body of the document to maintain parity between XHR and tag-loaded scripts. In version 0.4.0 and earlier,
	 * only tag-loaded scripts are injected.
	 * @property JAVASCRIPT
	 * @type {String}
	 * @default javascript
	 * @static
	 * @since 0.6.0
	 */
	s.JAVASCRIPT = "javascript";

	/**
	 * The preload type for json files, usually with the "json" file extension. JSON data is loaded and parsed into a
	 * JavaScript object. Note that if a `callback` is present on the load item, the file will be loaded with JSONP,
	 * no matter what the {{#crossLink "LoadQueue/preferXHR:property"}}{{/crossLink}} property is set to, and the JSON
	 * must contain a matching wrapper function.
	 * @property JSON
	 * @type {String}
	 * @default json
	 * @static
	 * @since 0.6.0
	 */
	s.JSON = "json";

	/**
	 * The preload type for jsonp files, usually with the "json" file extension. JSON data is loaded and parsed into a
	 * JavaScript object. You are required to pass a callback parameter that matches the function wrapper in the JSON.
	 * Note that JSONP will always be used if there is a callback present, no matter what the {{#crossLink "LoadQueue/preferXHR:property"}}{{/crossLink}}
	 * property is set to.
	 * @property JSONP
	 * @type {String}
	 * @default jsonp
	 * @static
	 * @since 0.6.0
	 */
	s.JSONP = "jsonp";

	/**
	 * The preload type for json-based manifest files, usually with the "json" file extension. The JSON data is loaded
	 * and parsed into a JavaScript object. PreloadJS will then look for a "manifest" property in the JSON, which is an
	 * Array of files to load, following the same format as the {{#crossLink "LoadQueue/loadManifest"}}{{/crossLink}}
	 * method. If a "callback" is specified on the manifest object, then it will be loaded using JSONP instead,
	 * regardless of what the {{#crossLink "LoadQueue/preferXHR:property"}}{{/crossLink}} property is set to.
	 * @property MANIFEST
	 * @type {String}
	 * @default manifest
	 * @static
	 * @since 0.6.0
	 */
	s.MANIFEST = "manifest";

	/**
	 * The preload type for sound files, usually mp3, ogg, or wav. When loading via tags, audio is loaded into an
	 * &lt;audio&gt; tag.
	 * @property SOUND
	 * @type {String}
	 * @default sound
	 * @static
	 * @since 0.6.0
	 */
	s.SOUND = "sound";

	/**
	 * The preload type for video files, usually mp4, ts, or ogg. When loading via tags, video is loaded into an
	 * &lt;video&gt; tag.
	 * @property VIDEO
	 * @type {String}
	 * @default video
	 * @static
	 * @since 0.6.0
	 */
	s.VIDEO = "video";

	/**
	 * The preload type for SpriteSheet files. SpriteSheet files are JSON files that contain string image paths.
	 * @property SPRITESHEET
	 * @type {String}
	 * @default spritesheet
	 * @static
	 * @since 0.6.0
	 */
	s.SPRITESHEET = "spritesheet";

	/**
	 * The preload type for SVG files.
	 * @property SVG
	 * @type {String}
	 * @default svg
	 * @static
	 * @since 0.6.0
	 */
	s.SVG = "svg";

	/**
	 * The preload type for text files, which is also the default file type if the type can not be determined. Text is
	 * loaded as raw text.
	 * @property TEXT
	 * @type {String}
	 * @default text
	 * @static
	 * @since 0.6.0
	 */
	s.TEXT = "text";

	/**
	 * The preload type for xml files. XML is loaded into an XML document.
	 * @property XML
	 * @type {String}
	 * @default xml
	 * @static
	 * @since 0.6.0
	 */
	s.XML = "xml";

// Events
	/**
	 * The {{#crossLink "ProgressEvent"}}{{/crossLink}} that is fired when the overall progress changes. Prior to
	 * version 0.6.0, this was just a regular {{#crossLink "Event"}}{{/crossLink}}.
	 * @event progress
	 * @since 0.3.0
	 */

	/**
	 * The {{#crossLink "Event"}}{{/crossLink}} that is fired when a load starts.
	 * @event loadstart
	 * @param {Object} target The object that dispatched the event.
	 * @param {String} type The event type.
	 * @since 0.3.1
	 */

	/**
	 * The {{#crossLink "Event"}}{{/crossLink}} that is fired when the entire queue has been loaded.
	 * @event complete
	 * @param {Object} target The object that dispatched the event.
	 * @param {String} type The event type.
	 * @since 0.3.0
	 */

	/**
	 * The {{#crossLink "ErrorEvent"}}{{/crossLink}} that is fired when the loader encounters an error. If the error was
	 * encountered by a file, the event will contain the item that caused the error. Prior to version 0.6.0, this was
	 * just a regular {{#crossLink "Event"}}{{/crossLink}}.
	 * @event error
	 * @since 0.3.0
	 */

	/**
	 * The {{#crossLink "Event"}}{{/crossLink}} that is fired when the loader encounters an internal file load error.
	 * This enables loaders to maintain internal queues, and surface file load errors.
	 * @event fileerror
	 * @param {Object} target The object that dispatched the event.
	 * @param {String} type The even type ("fileerror")
	 * @param {LoadItem|object} The item that encountered the error
	 * @since 0.6.0
	 */

	/**
	 * The {{#crossLink "Event"}}{{/crossLink}} that is fired when a loader internally loads a file. This enables
	 * loaders such as {{#crossLink "ManifestLoader"}}{{/crossLink}} to maintain internal {{#crossLink "LoadQueue"}}{{/crossLink}}s
	 * and notify when they have loaded a file. The {{#crossLink "LoadQueue"}}{{/crossLink}} class dispatches a
	 * slightly different {{#crossLink "LoadQueue/fileload:event"}}{{/crossLink}} event.
	 * @event fileload
	 * @param {Object} target The object that dispatched the event.
	 * @param {String} type The event type ("fileload")
	 * @param {Object} item The file item which was specified in the {{#crossLink "LoadQueue/loadFile"}}{{/crossLink}}
	 * or {{#crossLink "LoadQueue/loadManifest"}}{{/crossLink}} call. If only a string path or tag was specified, the
	 * object will contain that value as a `src` property.
	 * @param {Object} result The HTML tag or parsed result of the loaded item.
	 * @param {Object} rawResult The unprocessed result, usually the raw text or binary data before it is converted
	 * to a usable object.
	 * @since 0.6.0
	 */

	/**
	 * The {{#crossLink "Event"}}{{/crossLink}} that is fired after the internal request is created, but before a load.
	 * This allows updates to the loader for specific loading needs, such as binary or XHR image loading.
	 * @event initialize
	 * @param {Object} target The object that dispatched the event.
	 * @param {String} type The event type ("initialize")
	 * @param {AbstractLoader} loader The loader that has been initialized.
	 */


	/**
	 * Get a reference to the manifest item that is loaded by this loader. In some cases this will be the value that was
	 * passed into {{#crossLink "LoadQueue"}}{{/crossLink}} using {{#crossLink "LoadQueue/loadFile"}}{{/crossLink}} or
	 * {{#crossLink "LoadQueue/loadManifest"}}{{/crossLink}}. However if only a String path was passed in, then it will
	 * be a {{#crossLink "LoadItem"}}{{/crossLink}}.
	 * @method getItem
	 * @return {Object} The manifest item that this loader is responsible for loading.
	 * @since 0.6.0
	 */
	p.getItem = function () {
		return this._item;
	};

	/**
	 * Get a reference to the content that was loaded by the loader (only available after the {{#crossLink "complete:event"}}{{/crossLink}}
	 * event is dispatched.
	 * @method getResult
	 * @param {Boolean} [raw=false] Determines if the returned result will be the formatted content, or the raw loaded
	 * data (if it exists).
	 * @return {Object}
	 * @since 0.6.0
	 */
	p.getResult = function (raw) {
		return raw ? this._rawResult : this._result;
	};

	/**
	 * Return the `tag` this object creates or uses for loading.
	 * @method getTag
	 * @return {Object} The tag instance
	 * @since 0.6.0
	 */
	p.getTag = function () {
		return this._tag;
	};

	/**
	 * Set the `tag` this item uses for loading.
	 * @method setTag
	 * @param {Object} tag The tag instance
	 * @since 0.6.0
	 */
	p.setTag = function(tag) {
	  this._tag = tag;
	};

	/**
	 * Begin loading the item. This method is required when using a loader by itself.
	 *
	 * <h4>Example</h4>
	 *
	 *      var queue = new createjs.LoadQueue();
	 *      queue.addEventListener("complete", handleComplete);
	 *      queue.loadManifest(fileArray, false); // Note the 2nd argument that tells the queue not to start loading yet
	 *      queue.load();
	 *
	 * @method load
	 */
	p.load = function () {
		this._createRequest();

		this._request.on("complete", this, this);
		this._request.on("progress", this, this);
		this._request.on("loadStart", this, this);
		this._request.on("abort", this, this);
		this._request.on("timeout", this, this);
		this._request.on("error", this, this);

		var evt = new createjs.Event("initialize");
		evt.loader = this._request;
		this.dispatchEvent(evt);

		this._request.load();
	};

	/**
	 * Close the the item. This will stop any open requests (although downloads using HTML tags may still continue in
	 * the background), but events will not longer be dispatched.
	 * @method cancel
	 */
	p.cancel = function () {
		this.canceled = true;
		this.destroy();
	};

	/**
	 * Clean up the loader.
	 * @method destroy
	 */
	p.destroy = function() {
		if (this._request) {
			this._request.removeAllEventListeners();
			this._request.destroy();
		}

		this._request = null;

		this._item = null;
		this._rawResult = null;
		this._result = null;

		this._loadItems = null;

		this.removeAllEventListeners();
	};

	/**
	 * Get any items loaded internally by the loader. The enables loaders such as {{#crossLink "ManifestLoader"}}{{/crossLink}}
	 * to expose items it loads internally.
	 * @method getLoadedItems
	 * @return {Array} A list of the items loaded by the loader.
	 * @since 0.6.0
	 */
	p.getLoadedItems = function () {
		return this._loadedItems;
	};


	// Private methods
	/**
	 * Create an internal request used for loading. By default, an {{#crossLink "XHRRequest"}}{{/crossLink}} or
	 * {{#crossLink "TagRequest"}}{{/crossLink}} is created, depending on the value of {{#crossLink "preferXHR:property"}}{{/crossLink}}.
	 * Other loaders may override this to use different request types, such as {{#crossLink "ManifestLoader"}}{{/crossLink}},
	 * which uses {{#crossLink "JSONLoader"}}{{/crossLink}} or {{#crossLink "JSONPLoader"}}{{/crossLink}} under the hood.
	 * @method _createRequest
	 * @private
	 */
	p._createRequest = function() {
		if (!this._preferXHR) {
			this._request = new createjs.TagRequest(this._item, false, this._tag || this._createTag(), this._tagSrcAttribute);
		} else {
			this._request = new createjs.XHRRequest(this._item, false);
		}
	};

	/**
	 * Dispatch a loadstart {{#crossLink "Event"}}{{/crossLink}}. Please see the {{#crossLink "AbstractLoader/loadstart:event"}}{{/crossLink}}
	 * event for details on the event payload.
	 * @method _sendLoadStart
	 * @protected
	 */
	p._sendLoadStart = function () {
		if (this._isCanceled()) { return; }
		this.dispatchEvent("loadstart");
	};

	/**
	 * Dispatch a {{#crossLink "ProgressEvent"}}{{/crossLink}}.
	 * @method _sendProgress
	 * @param {Number | Object} value The progress of the loaded item, or an object containing <code>loaded</code>
	 * and <code>total</code> properties.
	 * @protected
	 */
	p._sendProgress = function (value) {
		if (this._isCanceled()) { return; }
		var event = null;
		if (typeof(value) == "number") {
			this.progress = value;
			event = new createjs.ProgressEvent(this.progress);
		} else {
			event = value;
			this.progress = value.loaded / value.total;
			event.progress = this.progress;
			if (isNaN(this.progress) || this.progress == Infinity) { this.progress = 0; }
		}
		this.hasEventListener("progress") && this.dispatchEvent(event);
	};

	/**
	 * Dispatch a complete {{#crossLink "Event"}}{{/crossLink}}. Please see the {{#crossLink "AbstractLoader/complete:event"}}{{/crossLink}} event
	 * @method _sendComplete
	 * @protected
	 */
	p._sendComplete = function () {
		if (this._isCanceled()) { return; }

		this.loaded = true;

		var event = new createjs.Event("complete");
		event.rawResult = this._rawResult;

		if (this._result != null) {
			event.result = this._result;
		}

		this.dispatchEvent(event);
	};

	/**
	 * Dispatch an error {{#crossLink "Event"}}{{/crossLink}}. Please see the {{#crossLink "AbstractLoader/error:event"}}{{/crossLink}}
	 * event for details on the event payload.
	 * @method _sendError
	 * @param {ErrorEvent} event The event object containing specific error properties.
	 * @protected
	 */
	p._sendError = function (event) {
		if (this._isCanceled() || !this.hasEventListener("error")) { return; }
		if (event == null) {
			event = new createjs.ErrorEvent("PRELOAD_ERROR_EMPTY"); // TODO: Populate error
		}
		this.dispatchEvent(event);
	};

	/**
	 * Determine if the load has been canceled. This is important to ensure that method calls or asynchronous events
	 * do not cause issues after the queue has been cleaned up.
	 * @method _isCanceled
	 * @return {Boolean} If the loader has been canceled.
	 * @protected
	 */
	p._isCanceled = function () {
		if (window.createjs == null || this.canceled) {
			return true;
		}
		return false;
	};

	/**
	 * A custom result formatter function, which is called just before a request dispatches its complete event. Most
	 * loader types already have an internal formatter, but this can be user-overridden for custom formatting. The
	 * formatted result will be available on Loaders using {{#crossLink "getResult"}}{{/crossLink}}, and passing `true`.
	 * @property resultFormatter
	 * @type Function
	 * @return {Object} The formatted result
	 * @since 0.6.0
	 */
	p.resultFormatter = null; //TODO: Add support for async formatting.

	/**
	 * Handle events from internal requests. By default, loaders will handle, and redispatch the necessary events, but
	 * this method can be overridden for custom behaviours.
	 * @method handleEvent
	 * @param {Event} The event that the internal request dispatches.
	 * @private
	 * @since 0.6.0
	 */
	p.handleEvent = function (event) {
		switch (event.type) {
			case "complete":
				this._rawResult = event.target._response;
				var result = this.resultFormatter && this.resultFormatter(this);
				var _this = this;
				if (result instanceof Function) {
					result(function(result) {
						_this._result = result;
						_this._sendComplete();
					});
				} else {
					this._result =  result || this._rawResult;
					this._sendComplete();
				}
				break;
			case "progress":
				this._sendProgress(event);
				break;
			case "error":
				this._sendError(event);
				break;
			case "loadstart":
				this._sendLoadStart();
				break;
			case "abort":
			case "timeout":
				if (!this._isCanceled()) {
					this.dispatchEvent(event.type);
				}
				break;
		}
	};

	/**
	 * @method buildPath
	 * @deprecated Use the {{#crossLink "RequestUtils"}}{{/crossLink}} method {{#crossLink "RequestUtils/buildPath"}}{{/crossLink}}
	 * instead.
	 */
	p.buildPath = function (src, data) {
		return createjs.RequestUtils.buildPath(src, data);
	};

	/**
	 * @method toString
	 * @return {String} a string representation of the instance.
	 */
	p.toString = function () {
		return "[PreloadJS AbstractLoader]";
	};

	createjs.AbstractLoader = createjs.promote(AbstractLoader, "EventDispatcher");

}());

//##############################################################################
// AbstractMediaLoader.js
//##############################################################################

this.createjs = this.createjs || {};

(function () {
	"use strict";

	// constructor
	/**
	 * The AbstractMediaLoader class description goes here.
	 *
	 */
	function AbstractMediaLoader(loadItem, preferXHR, type) {
		this.AbstractLoader_constructor(loadItem, preferXHR, type);

		// public properties

		// protected properties
		this._tagSrcAttribute = "src";

		/**
		 * Used to determine what type of tag to create, for example "audio"
		 * @property _tagType
		 * @type {string}
		 * @private
		 */
		this._tagType = type;

		this.resultFormatter = this._formatResult;
	};

	var p = createjs.extend(AbstractMediaLoader, createjs.AbstractLoader);
	// static properties

	// public methods

	// protected methods
	p.load = function () {
		// TagRequest will handle most of this, but Sound / Video need a few custom properties, so just handle them here.
		if (!this._tag) {
			this._tag = this._createTag(this._item.src);
		}

		this._tag.preload = "auto";
		this._tag.load();

		this.AbstractLoader_load();
	};

	/**
	 * Abstract, create a new tag if none exist.
	 *
	 * @private
	 */
	p._createTag = function () {

	};

	p._formatResult = function (loader) {
		this._tag.removeEventListener && this._tag.removeEventListener("canplaythrough", this._loadedHandler);
		this._tag.onstalled = null;
		if (this._preferXHR) {
			loader.getTag().src = loader.getResult(true);
		}
		return loader.getTag();
	};

	createjs.AbstractMediaLoader = createjs.promote(AbstractMediaLoader, "AbstractLoader");

}());

//##############################################################################
// AbstractRequest.js
//##############################################################################

this.createjs = this.createjs || {};

(function () {
	"use strict";

	var AbstractRequest = function (item) {
		this._item = item;
	};

	var p = createjs.extend(AbstractRequest, createjs.EventDispatcher);
	var s = AbstractRequest;

	/**
	 * Abstract function.
	 *
	 */
	p.load =  function() {

	};

	p.destroy = function() {

	};

	p.cancel = function() {

	};

	createjs.AbstractRequest = createjs.promote(AbstractRequest, "EventDispatcher");

}());

//##############################################################################
// TagRequest.js
//##############################################################################

this.createjs = this.createjs || {};

(function () {
	"use strict";

	// constructor
	/**
	 * The TagRequest class description goes here.
	 *
	 */
	function TagRequest(loadItem, preferXHR, tag, srcAttribute) {
		this.AbstractRequest_constructor(loadItem, preferXHR);

		// public properties

		// protected properties
		this._tag = tag;
		this._tagSrcAttribute = srcAttribute;

		this._loadedHandler = createjs.proxy(this._handleTagComplete, this);
	};

	var p = createjs.extend(TagRequest, createjs.AbstractRequest);
	var s = TagRequest;

	p.load = function () {
		window.document.body.appendChild(this._tag);

		this._tag.onload = createjs.proxy(this._handleTagComplete, this);
		this._tag.onreadystatechange = createjs.proxy(this._handleReadyStateChange, this);

		var evt = new createjs.Event("initialize");
		evt.loader = this._tag;

		this.dispatchEvent(evt);

		this._tag[this._tagSrcAttribute] = this._item.src;
	};

	p.destroy = function() {
		this._clean();
		this._tag = null;

		this.AbstractRequest_destory();
	};

	/**
	 * Handle the readyStateChange event from a tag. We sometimes need this in place of the onload event (mainly SCRIPT
	 * and LINK tags), but other cases may exist.
	 * @method _handleReadyStateChange
	 * @private
	 */
	p._handleReadyStateChange = function () {
		clearTimeout(this._loadTimeout);
		// This is strictly for tags in browsers that do not support onload.
		var tag = this._tag;

		// Complete is for old IE support.
		if (tag.readyState == "loaded" || tag.readyState == "complete") {
			this._handleTagComplete();
		}
	};

	p._handleTagComplete = function () {
		this._rawResult = this._tag;
		this._result = this.resultFormatter && this.resultFormatter(this) || this._rawResult;

		this._clean();

		this.dispatchEvent("complete");
	};

	/**
	 * Remove event listeners, but don't destory the request object
	 *
	 * @private
	 */
	p._clean = function() {
		this._tag.onload = null;
		this._tag.onreadystatechange = null;
	};

	/**
	 * Handle a stalled audio event. The main place we seem to get these is with HTMLAudio in Chrome when we try and
	 * playback audio that is already in a load, but not complete.
	 * @method _handleStalled
	 * @private
	 */
	p._handleStalled = function () {
		//Ignore, let the timeout take care of it. Sometimes its not really stopped.
	};

	createjs.TagRequest = createjs.promote(TagRequest, "AbstractRequest");

}());

//##############################################################################
// MediaTagRequest.js
//##############################################################################

this.createjs = this.createjs || {};

(function () {
	"use strict";

	// constructor
	/**
	 * The TagRequest class description goes here.
	 *
	 */
	function MediaTagRequest(loadItem, preferXHR, tag, srcAttribute) {
		this.AbstractRequest_constructor(loadItem, preferXHR);

		// public properties

		// protected properties
		this._tag = tag;
		this._tagSrcAttribute = srcAttribute;

		this._loadedHandler = createjs.proxy(this._handleTagComplete, this);
	};

	var p = createjs.extend(MediaTagRequest, createjs.TagRequest);
	var s = MediaTagRequest;

	p.load = function () {
		this._tag.onstalled = createjs.proxy(this._handleStalled, this);
		this._tag.onprogress = createjs.proxy(this._handleProgress, this);

		// This will tell us when audio is buffered enough to play through, but not when its loaded.
		// The tag doesn't keep loading in Chrome once enough has buffered, and we have decided that behaviour is sufficient.
		this._tag.addEventListener && this._tag.addEventListener("canplaythrough", this._loadedHandler); // canplaythrough callback doesn't work in Chrome, so we use an event.

		this.TagRequest_load();
	};

	/**
	 * Handle the readyStateChange event from a tag. We sometimes need this in place of the onload event (mainly SCRIPT
	 * and LINK tags), but other cases may exist.
	 * @method _handleReadyStateChange
	 * @private
	 */
	p._handleReadyStateChange = function () {
		clearTimeout(this._loadTimeout);
		// This is strictly for tags in browsers that do not support onload.
		var tag = this._tag;

		// Complete is for old IE support.
		if (tag.readyState == "loaded" || tag.readyState == "complete") {
			this._handleTagComplete();
		}
	};

	/**
	 * Handle a stalled audio event. The main place we seem to get these is with HTMLAudio in Chrome when we try and
	 * playback audio that is already in a load, but not complete.
	 * @method _handleStalled
	 * @private
	 */
	p._handleStalled = function () {
		//Ignore, let the timeout take care of it. Sometimes its not really stopped.
	};

	/**
	 * The XHR request has reported progress.
	 * @method _handleProgress
	 * @param {Object} event The XHR progress event.
	 * @private
	 */
	p._handleProgress = function (event) {
		if (!event || event.loaded > 0 && event.total == 0) {
			return; // Sometimes we get no "total", so just ignore the progress event.
		}

		var newEvent = new createjs.ProgressEvent(event.loaded, event.total);
		this.dispatchEvent(newEvent);
	};

	/**
	 *
	 * @private
	 */
	p._clean = function () {
		this._tag.removeEventListener && this._tag.removeEventListener("canplaythrough", this._loadedHandler);
		this._tag.onstalled = null;
		this._tag.onprogress = null;

		this.TagRequest__clean();
	};

	createjs.MediaTagRequest = createjs.promote(MediaTagRequest, "TagRequest");

}());

//##############################################################################
// XHRRequest.js
//##############################################################################

this.createjs = this.createjs || {};

(function () {
	"use strict";

// constructor
	/**
	 * A preloader that loads items using XHR requests, usually XMLHttpRequest. However XDomainRequests will be used
	 * for cross-domain requests if possible, and older versions of IE fall back on to ActiveX objects when necessary.
	 * XHR requests load the content as text or binary data, provide progress and consistent completion events, and
	 * can be canceled during load. Note that XHR is not supported in IE 6 or earlier, and is not recommended for
	 * cross-domain loading.
	 * @class XHRRequest
	 * @constructor
	 * @param {Object} item The object that defines the file to load. Please see the {{#crossLink "LoadQueue/loadFile"}}{{/crossLink}}
	 * for an overview of supported file properties.
	 * @extends AbstractLoader
	 */
	function XHRRequest(item) {
		this.AbstractRequest_constructor(item);

		// protected properties
		/**
		 * A reference to the XHR request used to load the content.
		 * @property _request
		 * @type {XMLHttpRequest | XDomainRequest | ActiveX.XMLHTTP}
		 * @private
		 */
		this._request = null;

		/**
		 * A manual load timeout that is used for browsers that do not support the onTimeout event on XHR (XHR level 1,
		 * typically IE9).
		 * @property _loadTimeout
		 * @type {Number}
		 * @private
		 */
		this._loadTimeout = null;

		/**
		 * The browser's XHR (XMLHTTPRequest) version. Supported versions are 1 and 2. There is no official way to detect
		 * the version, so we use capabilities to make a best guess.
		 * @property _xhrLevel
		 * @type {Number}
		 * @default 1
		 * @private
		 */
		this._xhrLevel = 1;

		/**
		 * The response of a loaded file. This is set because it is expensive to look up constantly. This property will be
		 * null until the file is loaded.
		 * @property _response
		 * @type {mixed}
		 * @private
		 */
		this._response = null;

		/**
		 * The response of the loaded file before it is modified. In most cases, content is converted from raw text to
		 * an HTML tag or a formatted object which is set to the <code>result</code> property, but the developer may still
		 * want to access the raw content as it was loaded.
		 * @property _rawResponse
		 * @type {String|Object}
		 * @private
		 */
		this._rawResponse = null;

		this._canceled = false;

		// Setup our event handlers now.
		this._handleLoadStartProxy = createjs.proxy(this._handleLoadStart, this);
		this._handleProgressProxy = createjs.proxy(this._handleProgress, this);
		this._handleAbortProxy = createjs.proxy(this._handleAbort, this);
		this._handleErrorProxy = createjs.proxy(this._handleError, this);
		this._handleTimeoutProxy = createjs.proxy(this._handleTimeout, this);
		this._handleLoadProxy = createjs.proxy(this._handleLoad, this);
		this._handleReadyStateChangeProxy = createjs.proxy(this._handleReadyStateChange, this);

		if (!this._createXHR(item)) {
			//TODO: Throw error?
		}
	};

	var p = createjs.extend(XHRRequest, createjs.AbstractRequest);

// static properties
	/**
	 * A list of XMLHTTP object IDs to try when building an ActiveX object for XHR requests in earlier versions of IE.
	 * @property ACTIVEX_VERSIONS
	 * @type {Array}
	 * @since 0.4.2
	 * @private
	 */
	XHRRequest.ACTIVEX_VERSIONS = [
		"Msxml2.XMLHTTP.6.0",
		"Msxml2.XMLHTTP.5.0",
		"Msxml2.XMLHTTP.4.0",
		"MSXML2.XMLHTTP.3.0",
		"MSXML2.XMLHTTP",
		"Microsoft.XMLHTTP"
	];

// Public methods
	/**
	 * Look up the loaded result.
	 * @method getResult
	 * @param {Boolean} [raw=false] Return a raw result instead of a formatted result. This applies to content
	 * loaded via XHR such as scripts, XML, CSS, and Images. If there is no raw result, the formatted result will be
	 * returned instead.
	 * @return {Object} A result object containing the content that was loaded, such as:
	 * <ul>
	 *      <li>An image tag (&lt;image /&gt;) for images</li>
	 *      <li>A script tag for JavaScript (&lt;script /&gt;). Note that scripts loaded with tags may be added to the
	 *      HTML head.</li>
	 *      <li>A style tag for CSS (&lt;style /&gt;)</li>
	 *      <li>Raw text for TEXT</li>
	 *      <li>A formatted JavaScript object defined by JSON</li>
	 *      <li>An XML document</li>
	 *      <li>An binary arraybuffer loaded by XHR</li>
	 * </ul>
	 * Note that if a raw result is requested, but not found, the result will be returned instead.
	 */
	p.getResult = function (raw) {
		if (raw && this._rawResponse) {
			return this._rawResponse;
		}
		return this._response;
	};

	// Overrides abstract method in AbstractRequest
	p.cancel = function () {
		this.canceled = true;
		this._clean();
		this._request.abort();
	};

	// Overrides abstract method in AbstractLoader
	p.load = function () {
		if (this._request == null) {
			this._handleError();
			return;
		}

		//Events
		this._request.addEventListener("loadstart", this._handleLoadStartProxy);
		this._request.addEventListener("progress", this._handleProgressProxy);
		this._request.addEventListener("abort", this._handleAbortProxy);
		this._request.addEventListener("error",this._handleErrorProxy);
		this._request.addEventListener("timeout", this._handleTimeoutProxy);

		// Note: We don't get onload in all browsers (earlier FF and IE). onReadyStateChange handles these.
		this._request.addEventListener("load", this._handleLoadProxy);
		this._request.addEventListener("readystatechange", this._handleReadyStateChangeProxy);

		// Set up a timeout if we don't have XHR2
		if (this._xhrLevel == 1) {
			this._loadTimeout = setTimeout(createjs.proxy(this._handleTimeout, this), this.getItem().loadTimeout);
		}

		// Sometimes we get back 404s immediately, particularly when there is a cross origin request.  // note this does not catch in Chrome
		try {
			if (!this._item.values || this._item.method == createjs.AbstractLoader.GET) {
				this._request.send();
			} else if (this._item.method == createjs.AbstractLoader.POST) {
				this._request.send(createjs.RequestUtils.formatQueryString(this._item.values));
			}
		} catch (error) {
			this.dispatchEvent(new createjs.ErrorEvent("XHR_SEND", null, error));
		}
	};

	p.setResponseType = function (type) {
		this._request.responseType = type;
	};

	/**
	 * Get all the response headers from the XmlHttpRequest.
	 *
	 * <strong>From the docs:</strong> Return all the HTTP headers, excluding headers that are a case-insensitive match
	 * for Set-Cookie or Set-Cookie2, as a single string, with each header line separated by a U+000D CR U+000A LF pair,
	 * excluding the status line, and with each header name and header value separated by a U+003A COLON U+0020 SPACE
	 * pair.
	 * @method getAllResponseHeaders
	 * @return {String}
	 * @since 0.4.1
	 */
	p.getAllResponseHeaders = function () {
		if (this._request.getAllResponseHeaders instanceof Function) {
			return this._request.getAllResponseHeaders();
		} else {
			return null;
		}
	};

	/**
	 * Get a specific response header from the XmlHttpRequest.
	 *
	 * <strong>From the docs:</strong> Returns the header field value from the response of which the field name matches
	 * header, unless the field name is Set-Cookie or Set-Cookie2.
	 * @method getResponseHeader
	 * @param {String} header The header name to retrieve.
	 * @return {String}
	 * @since 0.4.1
	 */
	p.getResponseHeader = function (header) {
		if (this._request.getResponseHeader instanceof Function) {
			return this._request.getResponseHeader(header);
		} else {
			return null;
		}
	};

// protected methods
	/**
	 * The XHR request has reported progress.
	 * @method _handleProgress
	 * @param {Object} event The XHR progress event.
	 * @private
	 */
	p._handleProgress = function (event) {
		if (!event || event.loaded > 0 && event.total == 0) {
			return; // Sometimes we get no "total", so just ignore the progress event.
		}

		var newEvent = new createjs.ProgressEvent(event.loaded, event.total);
		this.dispatchEvent(newEvent);
	};

	/**
	 * The XHR request has reported a load start.
	 * @method _handleLoadStart
	 * @param {Object} event The XHR loadStart event.
	 * @private
	 */
	p._handleLoadStart = function (event) {
		clearTimeout(this._loadTimeout);
		this.dispatchEvent("loadstart");
	};

	/**
	 * The XHR request has reported an abort event.
	 * @method handleAbort
	 * @param {Object} event The XHR abort event.
	 * @private
	 */
	p._handleAbort = function (event) {
		this._clean();
		this.dispatchEvent(new createjs.ErrorEvent("XHR_ABORTED", null, event));
	};

	/**
	 * The XHR request has reported an error event.
	 * @method _handleError
	 * @param {Object} event The XHR error event.
	 * @private
	 */
	p._handleError = function (event) {
		this._clean();


		this.dispatchEvent(new createjs.ErrorEvent(null, null, event));
	};

	/**
	 * The XHR request has reported a readyState change. Note that older browsers (IE 7 & 8) do not provide an onload
	 * event, so we must monitor the readyStateChange to determine if the file is loaded.
	 * @method _handleReadyStateChange
	 * @param {Object} event The XHR readyStateChange event.
	 * @private
	 */
	p._handleReadyStateChange = function (event) {
		if (this._request.readyState == 4) {
			this._handleLoad();
		}
	};

	/**
	 * The XHR request has completed. This is called by the XHR request directly, or by a readyStateChange that has
	 * <code>request.readyState == 4</code>. Only the first call to this method will be processed.
	 * @method _handleLoad
	 * @param {Object} event The XHR load event.
	 * @private
	 */
	p._handleLoad = function (event) {
		if (this.loaded) {
			return;
		}
		this.loaded = true;

		var error = this._checkError();
		if (error) {
			this._handleError(error);
			return;
		}

		this._response = this._getResponse();
		this._clean();

		this.dispatchEvent(new createjs.Event("complete"));
	};

	/**
	 * The XHR request has timed out. This is called by the XHR request directly, or via a <code>setTimeout</code>
	 * callback.
	 * @method _handleTimeout
	 * @param {Object} [event] The XHR timeout event. This is occasionally null when called by the backup setTimeout.
	 * @private
	 */
	p._handleTimeout = function (event) {
		this._clean();

		this.dispatchEvent(new createjs.ErrorEvent("PRELOAD_TIMEOUT", null, event));
	};

// Protected
	/**
	 * Determine if there is an error in the current load. This checks the status of the request for problem codes. Note
	 * that this does not check for an actual response. Currently, it only checks for 404 or 0 error code.
	 * @method _checkError
	 * @return {int} If the request status returns an error code.
	 * @private
	 */
	p._checkError = function () {
		//LM: Probably need additional handlers here, maybe 501
		var status = parseInt(this._request.status);

		switch (status) {
			case 404:   // Not Found
			case 0:     // Not Loaded
				return new Error(status);
		}
		return null;
	};

	/**
	 * Validate the response. Different browsers have different approaches, some of which throw errors when accessed
	 * in other browsers. If there is no response, the <code>_response</code> property will remain null.
	 * @method _getResponse
	 * @private
	 */
	p._getResponse = function () {
		if (this._response != null) {
			return this._response;
		}

		if (this._request.response != null) {
			return this._request.response;
		}

		// Android 2.2 uses .responseText
		try {
			if (this._request.responseText != null) {
				return this._request.responseText;
			}
		} catch (e) {
		}

		// When loading XML, IE9 does not return .response, instead it returns responseXML.xml
		try {
			if (this._request.responseXML != null) {
				return this._request.responseXML;
			}
		} catch (e) {
		}

		return null;
	};

	/**
	 * Create an XHR request. Depending on a number of factors, we get totally different results.
	 * <ol><li>Some browsers get an <code>XDomainRequest</code> when loading cross-domain.</li>
	 *      <li>XMLHttpRequest are created when available.</li>
	 *      <li>ActiveX.XMLHTTP objects are used in older IE browsers.</li>
	 *      <li>Text requests override the mime type if possible</li>
	 *      <li>Origin headers are sent for crossdomain requests in some browsers.</li>
	 *      <li>Binary loads set the response type to "arraybuffer"</li></ol>
	 * @method _createXHR
	 * @param {Object} item The requested item that is being loaded.
	 * @return {Boolean} If an XHR request or equivalent was successfully created.
	 * @private
	 */
	p._createXHR = function (item) {
		// Check for cross-domain loads. We can't fully support them, but we can try.
		var crossdomain = createjs.RequestUtils.isCrossDomain(item);
		var headers = {};

		// Create the request. Fallback to whatever support we have.
		var req = null;
		if (window.XMLHttpRequest) {
			req = new XMLHttpRequest();
			// This is 8 or 9, so use XDomainRequest instead.
			if (crossdomain && req.withCredentials === undefined && window.XDomainRequest) {
				req = new XDomainRequest();
			}
		} else { // Old IE versions use a different approach
			for (var i = 0, l = s.ACTIVEX_VERSIONS.length; i < l; i++) {
				var axVersion = s.ACTIVEX_VERSIONS[i];
				try {
					req = new ActiveXObject(axVersions);
					break;
				} catch (e) {}
			}
			if (req == null) { return false; }
		}

		// IE9 doesn't support overrideMimeType(), so we need to check for it.
		if (item.mimeType && req.overrideMimeType) {
			req.overrideMimeType(item.mimeType);
		}

		// Determine the XHR level
		this._xhrLevel = (typeof req.responseType === "string") ? 2 : 1;

		var src = null;
		if (item.method == createjs.AbstractLoader.GET) {
			src = createjs.RequestUtils.buildPath(item.src, item.values);
		} else {
			src = item.src;
		}

		// Open the request.  Set cross-domain flags if it is supported (XHR level 1 only)
		req.open(item.method || createjs.AbstractLoader.GET, src, true);

		if (crossdomain && req instanceof XMLHttpRequest && this._xhrLevel == 1) {
			headers["Origin"] = location.origin;
		}

		// To send data we need to set the Content-type header)
		if (item.values && item.method == createjs.AbstractLoader.POST) {
			headers["Content-Type"] = "application/x-www-form-urlencoded";
		}

		if (!crossdomain && !headers["X-Requested-With"]) {
			headers["X-Requested-With"] = "XMLHttpRequest";
		}

		if (item.headers) {
			for (var n in item.headers) {
				headers[n] = item.headers[n];
			}
		}

		for (n in headers) {
			req.setRequestHeader(n, headers[n])
		}

		if (req instanceof XMLHttpRequest && item.withCredentials !== undefined) {
			req.withCredentials = item.withCredentials;
		}

		this._request = req;

		return true;
	};

	/**
	 * A request has completed (or failed or canceled), and needs to be disposed.
	 * @method _clean
	 * @private
	 */
	p._clean = function () {
		clearTimeout(this._loadTimeout);

		this._request.removeEventListener("loadstart", this._handleLoadStartProxy);
		this._request.removeEventListener("progress", this._handleProgressProxy);
		this._request.removeEventListener("abort", this._handleAbortProxy);
		this._request.removeEventListener("error",this._handleErrorProxy);
		this._request.removeEventListener("timeout", this._handleTimeoutProxy);
		this._request.removeEventListener("load", this._handleLoadProxy);
		this._request.removeEventListener("readystatechange", this._handleReadyStateChangeProxy);
	};

	p.toString = function () {
		return "[PreloadJS XHRRequest]";
	};

	createjs.XHRRequest = createjs.promote(XHRRequest, "AbstractRequest");

}());

//##############################################################################
// SoundLoader.js
//##############################################################################

this.createjs = this.createjs || {};

(function () {
	"use strict";

	// constructor
	/**
	 * The SoundLoader class description goes here.
	 *
	 */
	function SoundLoader(loadItem, preferXHR) {
		this.AbstractMediaLoader_constructor(loadItem, preferXHR, createjs.AbstractLoader.SOUND);

		this._tagType = "audio";

		if (createjs.RequestUtils.isAudioTag(loadItem) || createjs.RequestUtils.isAudioTag(loadItem.src)) {
			this._preferXHR = false;
			this._tag =createjs.RequestUtils.isAudioTag(loadItem)?loadItem:loadItem.src;
		}
	};

	var p = createjs.extend(SoundLoader, createjs.AbstractMediaLoader);
	var s = SoundLoader;
	/**
	 * LoadQueue calls this when it creates loaders.
	 * Each loader has the option to say either yes (true) or no (false).
	 *
	 * @private
	 * @param item The LoadItem LoadQueue is trying to load.
	 * @returns {boolean}
	 */
	s.canLoadItem = function (item) {
		return item.type == createjs.AbstractLoader.SOUND;
	};

	p._createRequest = function() {
		if (!this._preferXHR) {
			this._request = new createjs.MediaTagRequest(this._item, false, this._tag || this._createTag(), this._tagSrcAttribute);
		} else {
			this._request = new createjs.XHRRequest(this._item, false);
		}
	};

	/**
	 * Create an HTML audio tag.
	 * @method _createTag
	 * @param {String} src The source file to set for the audio tag.
	 * @return {HTMLElement} Returns an HTML audio tag.
	 * @protected
	 */
	p._createTag = function (src) {
		var tag = document.createElement(this._tagType);
		tag.autoplay = false;
		tag.preload = "none";

		//LM: Firefox fails when this the preload="none" for other tags, but it needs to be "none" to ensure PreloadJS works.
		tag.src = src;
		return tag;
	};

	createjs.SoundLoader = createjs.promote(SoundLoader, "AbstractMediaLoader");

}());

//##############################################################################
// Sound.js
//##############################################################################

this.createjs = this.createjs || {};



(function () {
	"use strict";

	/**
	 * The Sound class is the public API for creating sounds, controlling the overall sound levels, and managing plugins.
	 * All Sound APIs on this class are static.
	 *
	 * <b>Registering and Preloading</b><br />
	 * Before you can play a sound, it <b>must</b> be registered. You can do this with {{#crossLink "Sound/registerSound"}}{{/crossLink}},
	 * or register multiple sounds using {{#crossLink "Sound/registerSounds"}}{{/crossLink}}. If you don't register a
	 * sound prior to attempting to play it using {{#crossLink "Sound/play"}}{{/crossLink}} or create it using {{#crossLink "Sound/createInstance"}}{{/crossLink}},
	 * the sound source will be automatically registered but playback will fail as the source will not be ready. If you use
	 * <a href="http://preloadjs.com" target="_blank">PreloadJS</a>, registration is handled for you when the sound is
	 * preloaded. It is recommended to preload sounds either internally using the register functions or externally using
	 * PreloadJS so they are ready when you want to use them.
	 *
	 * <b>Playback</b><br />
	 * To play a sound once it's been registered and preloaded, use the {{#crossLink "Sound/play"}}{{/crossLink}} method.
	 * This method returns a {{#crossLink "AbstractSoundInstance"}}{{/crossLink}} which can be paused, resumed, muted, etc.
	 * Please see the {{#crossLink "AbstractSoundInstance"}}{{/crossLink}} documentation for more on the instance control APIs.
	 *
	 * <b>Plugins</b><br />
	 * By default, the {{#crossLink "WebAudioPlugin"}}{{/crossLink}} or the {{#crossLink "HTMLAudioPlugin"}}{{/crossLink}}
	 * are used (when available), although developers can change plugin priority or add new plugins (such as the
	 * provided {{#crossLink "FlashAudioPlugin"}}{{/crossLink}}). Please see the {{#crossLink "Sound"}}{{/crossLink}} API
	 * methods for more on the playback and plugin APIs. To install plugins, or specify a different plugin order, see
	 * {{#crossLink "Sound/installPlugins"}}{{/crossLink}}.
	 *
	 * <h4>Example</h4>
	 *      createjs.Sound.registerPlugins([createjs.WebAudioPlugin, createjs.FlashAudioPlugin]);
	 *      createjs.Sound.alternateExtensions = ["mp3"];
	 *      createjs.Sound.addEventListener("fileload", createjs.proxy(this.loadHandler, (this));
	 *      createjs.Sound.registerSound("path/to/mySound.ogg", "sound");
	 *      function loadHandler(event) {
     *          // This is fired for each sound that is registered.
     *          var instance = createjs.Sound.play("sound");  // play using id.  Could also use full source path or event.src.
     *          instance.addEventListener("complete", createjs.proxy(this.handleComplete, this));
     *          instance.volume = 0.5;
	 *      }
	 *
	 * The maximum number of concurrently playing instances of the same sound can be specified in the "data" argument
	 * of {{#crossLink "Sound/registerSound"}}{{/crossLink}}.  Note that if not specified, the active plugin will apply
	 * a default limit.  Currently HTMLAudioPlugin sets a default limit of 2, while WebAudioPlugin and FlashAudioPlugin set a
	 * default limit of 100.
	 *
	 *      createjs.Sound.registerSound("sound.mp3", "soundId", 4);
	 *
	 * Sound can be used as a plugin with PreloadJS to help preload audio properly. Audio preloaded with PreloadJS is
	 * automatically registered with the Sound class. When audio is not preloaded, Sound will do an automatic internal
	 * load. As a result, it may fail to play the first time play is called if the audio is not finished loading. Use the
	 * {{#crossLink "Sound/fileload"}}{{/crossLink}} event to determine when a sound has finished internally preloading.
	 * It is recommended that all audio is preloaded before it is played.
	 *
	 *      var queue = new createjs.LoadQueue();
	 *		queue.installPlugin(createjs.Sound);
	 *
	 * <b>Audio Sprites</b><br />
	 * SoundJS has added support for Audio Sprites, available as of version 0.6.0.
	 * For those unfamiliar with audio sprites, they are much like CSS sprites or sprite sheets: multiple audio assets
	 * grouped into a single file.
	 *
	 * Benefits of Audio Sprites
	 * <ul><li>More robust support for older browsers and devices that only allow a single audio instance, such as iOS 5.</li>
	 * <li>They provide a work around for the Internet Explorer 9 audio tag limit, which until now restricted how many
	 * different sounds we could load at once.</li>
	 * <li>Faster loading by only requiring a single network request for several sounds, especially on mobile devices
	 * where the network round trip for each file can add significant latency.</li></ul>
	 *
	 * Drawbacks of Audio Sprites
	 * <ul><li>No guarantee of smooth looping when using HTML or Flash audio.  If you have a track that needs to loop
	 * smoothly and you are supporting non-web audio browsers, do not use audio sprites for that sound if you can avoid it.</li>
	 * <li>No guarantee that HTML audio will play back immediately, especially the first time. In some browsers (Chrome!),
	 * HTML audio will only load enough to play through – so we rely on the “canplaythrough” event to determine if the audio is loaded.
	 * Since audio sprites must jump ahead to play specific sounds, the audio may not yet have downloaded.</li>
	 * <li>Audio sprites share the same core source, so if you have a sprite with 5 sounds and are limited to 2
	 * concurrently playing instances, that means you can only play 2 of the sounds at the same time.</li></ul>
	 *
	 * <h4>Example</h4>
	 *      createjs.Sound.initializeDefaultPlugins();
	 *		var assetsPath = "./assets/";
	 *		var sounds = [{
	 *			src:"MyAudioSprite.ogg", data: {
	 *				audioSprite: [
	 *					{id:"sound1", startTime:0, duration:500},
	 *					{id:"sound2", startTime:1000, duration:400},
	 *					{id:"sound3", startTime:1700, duration: 1000}
	 *				]}
 *				}
	 *		];
	 *		createjs.Sound.alternateExtensions = ["mp3"];
	 *		createjs.Sound.addEventListener("fileload", loadSound);
	 *		createjs.Sound.registerSounds(sounds, assetsPath);
	 *		// after load is complete
	 *		createjs.Sound.play("sound2");
	 *
	 * You can also create audio sprites on the fly by setting the startTime and duration when creating an new AbstractSoundInstance.
	 *
	 * 		createjs.Sound.play("MyAudioSprite", {startTime: 1000, duration: 400});
	 *
	 * <b>Mobile Safe Approach</b><br />
	 * Mobile devices require sounds to be played inside of a user initiated event (touch/click) in varying degrees.
	 * As of SoundJS 0.4.1, you can launch a site inside of a user initiated event and have audio playback work. To
	 * enable as broadly as possible, the site needs to setup the Sound plugin in its initialization (for example via
	 * <code>createjs.Sound.initializeDefaultPlugins();</code>), and all sounds need to be played in the scope of the
	 * application.  See the MobileSafe demo for a working example.
	 *
	 * <h4>Example</h4>
	 *     document.getElementById("status").addEventListener("click", handleTouch, false);    // works on Android and iPad
	 *     function handleTouch(event) {
	 *       document.getElementById("status").removeEventListener("click", handleTouch, false);    // remove the listener
	 *       var thisApp = new myNameSpace.MyApp();    // launch the app
	 *     }
	 *
	 * <h4>Known Browser and OS issues</h4>
	 * <b>IE 9 HTML Audio limitations</b><br />
	 * <ul><li>There is a delay in applying volume changes to tags that occurs once playback is started. So if you have
	 * muted all sounds, they will all play during this delay until the mute applies internally. This happens regardless of
	 * when or how you apply the volume change, as the tag seems to need to play to apply it.</li>
     * <li>MP3 encoding will not always work for audio tags, particularly in Internet Explorer. We've found default
	 * encoding with 64kbps works.</li>
	 * <li>Occasionally very short samples will get cut off.</li>
	 * <li>There is a limit to how many audio tags you can load and play at once, which appears to be determined by
	 * hardware and browser settings.  See {{#crossLink "HTMLAudioPlugin.MAX_INSTANCES"}}{{/crossLink}} for a safe estimate.</li></ul>
	 *
	 * <b>Firefox 25 Web Audio limitations</b>
	 * <ul><li>mp3 audio files do not load properly on all windows machines, reported
	 * <a href="https://bugzilla.mozilla.org/show_bug.cgi?id=929969" target="_blank">here</a>. </br>
	 * For this reason it is recommended to pass another FF supported type (ie ogg) first until this bug is resolved, if possible.</li></ul>

	 * <b>Safari limitations</b><br />
	 * <ul><li>Safari requires Quicktime to be installed for audio playback.</li></ul>
	 *
	 * <b>iOS 6 Web Audio limitations</b><br />
	 * <ul><li>Sound is initially muted and will only unmute through play being called inside a user initiated event
	 * (touch/click).</li>
	 * <li>A bug exists that will distort un-cached web audio when a video element is present in the DOM that has audio at a different sampleRate.</li>
	 * <li>Note HTMLAudioPlugin is not supported on iOS by default.  See {{#crossLink "HTMLAudioPlugin"}}{{/crossLink}}
	 * for more details.</li>
	 * </ul>
	 *
	 * <b>Android HTML Audio limitations</b><br />
	 * <ul><li>We have no control over audio volume. Only the user can set volume on their device.</li>
	 * <li>We can only play audio inside a user event (touch/click).  This currently means you cannot loop sound or use
	 * a delay.</li></ul>
	 *
	 *
	 * @class Sound
	 * @static
	 * @uses EventDispatcher
	 */
	function Sound() {
		throw "Sound cannot be instantiated";
	}

	var s = Sound;


// Static Properties
	/**
	 * The interrupt value to interrupt any currently playing instance with the same source, if the maximum number of
	 * instances of the sound are already playing.
	 * @property INTERRUPT_ANY
	 * @type {String}
	 * @default any
	 * @static
	 */
	s.INTERRUPT_ANY = "any";

	/**
	 * The interrupt value to interrupt the earliest currently playing instance with the same source that progressed the
	 * least distance in the audio track, if the maximum number of instances of the sound are already playing.
	 * @property INTERRUPT_EARLY
	 * @type {String}
	 * @default early
	 * @static
	 */
	s.INTERRUPT_EARLY = "early";

	/**
	 * The interrupt value to interrupt the currently playing instance with the same source that progressed the most
	 * distance in the audio track, if the maximum number of instances of the sound are already playing.
	 * @property INTERRUPT_LATE
	 * @type {String}
	 * @default late
	 * @static
	 */
	s.INTERRUPT_LATE = "late";

	/**
	 * The interrupt value to not interrupt any currently playing instances with the same source, if the maximum number of
	 * instances of the sound are already playing.
	 * @property INTERRUPT_NONE
	 * @type {String}
	 * @default none
	 * @static
	 */
	s.INTERRUPT_NONE = "none";

	/**
	 * Defines the playState of an instance that is still initializing.
	 * @property PLAY_INITED
	 * @type {String}
	 * @default playInited
	 * @static
	 */
	s.PLAY_INITED = "playInited";

	/**
	 * Defines the playState of an instance that is currently playing or paused.
	 * @property PLAY_SUCCEEDED
	 * @type {String}
	 * @default playSucceeded
	 * @static
	 */
	s.PLAY_SUCCEEDED = "playSucceeded";

	/**
	 * Defines the playState of an instance that was interrupted by another instance.
	 * @property PLAY_INTERRUPTED
	 * @type {String}
	 * @default playInterrupted
	 * @static
	 */
	s.PLAY_INTERRUPTED = "playInterrupted";

	/**
	 * Defines the playState of an instance that completed playback.
	 * @property PLAY_FINISHED
	 * @type {String}
	 * @default playFinished
	 * @static
	 */
	s.PLAY_FINISHED = "playFinished";

	/**
	 * Defines the playState of an instance that failed to play. This is usually caused by a lack of available channels
	 * when the interrupt mode was "INTERRUPT_NONE", the playback stalled, or the sound could not be found.
	 * @property PLAY_FAILED
	 * @type {String}
	 * @default playFailed
	 * @static
	 */
	s.PLAY_FAILED = "playFailed";

	/**
	 * A list of the default supported extensions that Sound will <i>try</i> to play. Plugins will check if the browser
	 * can play these types, so modifying this list before a plugin is initialized will allow the plugins to try to
	 * support additional media types.
	 *
	 * NOTE this does not currently work for {{#crossLink "FlashAudioPlugin"}}{{/crossLink}}.
	 *
	 * More details on file formats can be found at <a href="http://en.wikipedia.org/wiki/Audio_file_format" target="_blank">http://en.wikipedia.org/wiki/Audio_file_format</a>.<br />
	 * A very detailed list of file formats can be found at <a href="http://www.fileinfo.com/filetypes/audio" target="_blank">http://www.fileinfo.com/filetypes/audio</a>.
	 * @property SUPPORTED_EXTENSIONS
	 * @type {Array[String]}
	 * @default ["mp3", "ogg", "mpeg", "wav", "m4a", "mp4", "aiff", "wma", "mid"]
	 * @since 0.4.0
	 */
	s.SUPPORTED_EXTENSIONS = ["mp3", "ogg", "mpeg", "wav", "m4a", "mp4", "aiff", "wma", "mid"];

	/**
	 * Some extensions use another type of extension support to play (one of them is a codex).  This allows you to map
	 * that support so plugins can accurately determine if an extension is supported.  Adding to this list can help
	 * plugins determine more accurately if an extension is supported.
	 *
 	 * A useful list of extensions for each format can be found at <a href="http://html5doctor.com/html5-audio-the-state-of-play/" target="_blank">http://html5doctor.com/html5-audio-the-state-of-play/</a>.
	 * @property EXTENSION_MAP
	 * @type {Object}
	 * @since 0.4.0
	 * @default {m4a:"mp4"}
	 */
	s.EXTENSION_MAP = {
		m4a:"mp4"
	};

	/**
	 * The RegExp pattern used to parse file URIs. This supports simple file names, as well as full domain URIs with
	 * query strings. The resulting match is: protocol:$1 domain:$2 path:$3 file:$4 extension:$5 query:$6.
	 * @property FILE_PATTERN
	 * @type {RegExp}
	 * @static
	 * @protected
	 */
	s.FILE_PATTERN = /^(?:(\w+:)\/{2}(\w+(?:\.\w+)*\/?))?([/.]*?(?:[^?]+)?\/)?((?:[^/?]+)\.(\w+))(?:\?(\S+)?)?$/;


// Class Public properties
	/**
	 * Determines the default behavior for interrupting other currently playing instances with the same source, if the
	 * maximum number of instances of the sound are already playing.  Currently the default is {{#crossLink "Sound/INTERRUPT_NONE:property"}}{{/crossLink}}
	 * but this can be set and will change playback behavior accordingly.  This is only used when {{#crossLink "Sound/play"}}{{/crossLink}}
	 * is called without passing a value for interrupt.
	 * @property defaultInterruptBehavior
	 * @type {String}
	 * @default Sound.INTERRUPT_NONE, or "none"
	 * @static
	 * @since 0.4.0
	 */
	s.defaultInterruptBehavior = s.INTERRUPT_NONE;  // OJR does s.INTERRUPT_ANY make more sense as default?  Needs game dev testing to see which case makes more sense.

	/**
	 * An array of extensions to attempt to use when loading sound, if the default is unsupported by the active plugin.
	 * These are applied in order, so if you try to Load Thunder.ogg in a browser that does not support ogg, and your
	 * extensions array is ["mp3", "m4a", "wav"] it will check mp3 support, then m4a, then wav. The audio files need
	 * to exist in the same location, as only the extension is altered.
	 *
	 * Note that regardless of which file is loaded, you can call {{#crossLink "Sound/createInstance"}}{{/crossLink}}
	 * and {{#crossLink "Sound/play"}}{{/crossLink}} using the same id or full source path passed for loading.
	 * <h4>Example</h4>
	 *	var sounds = [
	 *		{src:"myPath/mySound.ogg", id:"example"},
	 *	];
	 *	createjs.Sound.alternateExtensions = ["mp3"]; // now if ogg is not supported, SoundJS will try asset0.mp3
	 *	createjs.Sound.addEventListener("fileload", handleLoad); // call handleLoad when each sound loads
	 *	createjs.Sound.registerSounds(sounds, assetPath);
	 *	// ...
	 *	createjs.Sound.play("myPath/mySound.ogg"); // works regardless of what extension is supported.  Note calling with ID is a better approach
	 *
	 * @property alternateExtensions
	 * @type {Array}
	 * @since 0.5.2
	 */
	s.alternateExtensions = [];

	/**
	 * The currently active plugin. If this is null, then no plugin could be initialized. If no plugin was specified,
	 * Sound attempts to apply the default plugins: {{#crossLink "WebAudioPlugin"}}{{/crossLink}}, followed by
	 * {{#crossLink "HTMLAudioPlugin"}}{{/crossLink}}.
	 * @property activePlugin
	 * @type {Object}
	 * @static
	 */
    s.activePlugin = null;


// Class Private properties
	/**
	 * Determines if the plugins have been registered. If false, the first call to play() will instantiate the default
	 * plugins ({{#crossLink "WebAudioPlugin"}}{{/crossLink}}, followed by {{#crossLink "HTMLAudioPlugin"}}{{/crossLink}}).
	 * If plugins have been registered, but none are applicable, then sound playback will fail.
	 * @property _pluginsRegistered
	 * @type {Boolean}
	 * @default false
	 * @static
	 * @protected
	 */
	s._pluginsRegistered = false;

	/**
	 * Used internally to assign unique IDs to each AbstractSoundInstance.
	 * @property _lastID
	 * @type {Number}
	 * @static
	 * @protected
	 */
	s._lastID = 0;

	/**
	 * The master volume value, which affects all sounds. Use {{#crossLink "Sound/getVolume"}}{{/crossLink}} and
	 * {{#crossLink "Sound/setVolume"}}{{/crossLink}} to modify the volume of all audio.
	 * @property _masterVolume
	 * @type {Number}
	 * @default 1
	 * @protected
	 * @since 0.4.0
	 */
	s._masterVolume = 1;

	/**
	 * The master mute value, which affects all sounds.  This is applies to all sound instances.  This value can be set
	 * through {{#crossLink "Sound/setMute"}}{{/crossLink}} and accessed via {{#crossLink "Sound/getMute"}}{{/crossLink}}.
	 * @property _masterMute
	 * @type {Boolean}
	 * @default false
	 * @protected
	 * @static
	 * @since 0.4.0
	 */
	s._masterMute = false;

	/**
	 * An array containing all currently playing instances. This allows Sound to control the volume, mute, and playback of
	 * all instances when using static APIs like {{#crossLink "Sound/stop"}}{{/crossLink}} and {{#crossLink "Sound/setVolume"}}{{/crossLink}}.
	 * When an instance has finished playback, it gets removed via the {{#crossLink "Sound/finishedPlaying"}}{{/crossLink}}
	 * method. If the user replays an instance, it gets added back in via the {{#crossLink "Sound/_beginPlaying"}}{{/crossLink}}
	 * method.
	 * @property _instances
	 * @type {Array}
	 * @protected
	 * @static
	 */
	s._instances = [];

	/**
	 * An object hash storing objects with sound sources, startTime, and duration via there corresponding ID.
	 * @property _idHash
	 * @type {Object}
	 * @protected
	 * @static
	 */
	s._idHash = {};

	/**
	 * An object hash that stores preloading sound sources via the parsed source that is passed to the plugin.  Contains the
	 * source, id, and data that was passed in by the user.  Parsed sources can contain multiple instances of source, id,
	 * and data.
	 * @property _preloadHash
	 * @type {Object}
	 * @protected
	 * @static
	 */
	s._preloadHash = {};


// EventDispatcher methods:
	s.addEventListener = null;
	s.removeEventListener = null;
	s.removeAllEventListeners = null;
	s.dispatchEvent = null;
	s.hasEventListener = null;
	s._listeners = null;

	createjs.EventDispatcher.initialize(s); // inject EventDispatcher methods.


// Events
	/**
	 * This event is fired when a file finishes loading internally. This event is fired for each loaded sound,
	 * so any handler methods should look up the <code>event.src</code> to handle a particular sound.
	 * @event fileload
	 * @param {Object} target The object that dispatched the event.
	 * @param {String} type The event type.
	 * @param {String} src The source of the sound that was loaded.
	 * @param {String} [id] The id passed in when the sound was registered. If one was not provided, it will be null.
	 * @param {Number|Object} [data] Any additional data associated with the item. If not provided, it will be undefined.
	 * @since 0.4.1
	 */

	/**
	 * This event is fired when a file fails loading internally. This event is fired for each loaded sound,
	 * so any handler methods should look up the <code>event.src</code> to handle a particular sound.
	 * @event fileerror
	 * @param {Object} target The object that dispatched the event.
	 * @param {String} type The event type.
	 * @param {String} src The source of the sound that was loaded.
	 * @param {String} [id] The id passed in when the sound was registered. If one was not provided, it will be null.
	 * @param {Number|Object} [data] Any additional data associated with the item. If not provided, it will be undefined.
	 * @since 0.6.0
	 */


// Class Public Methods
	/**
	 * Get the preload rules to allow Sound to be used as a plugin by <a href="http://preloadjs.com" target="_blank">PreloadJS</a>.
	 * Any load calls that have the matching type or extension will fire the callback method, and use the resulting
	 * object, which is potentially modified by Sound. This helps when determining the correct path, as well as
	 * registering the audio instance(s) with Sound. This method should not be called, except by PreloadJS.
	 * @method getPreloadHandlers
	 * @return {Object} An object containing:
	 * <ul><li>callback: A preload callback that is fired when a file is added to PreloadJS, which provides
	 *      Sound a mechanism to modify the load parameters, select the correct file format, register the sound, etc.</li>
	 *      <li>types: A list of file types that are supported by Sound (currently supports "sound").</li>
	 *      <li>extensions: A list of file extensions that are supported by Sound (see {{#crossLink "Sound.SUPPORTED_EXTENSIONS"}}{{/crossLink}}).</li></ul>
	 * @static
	 * @protected
	 */
	s.getPreloadHandlers = function () {
		return {
			callback:createjs.proxy(s.initLoad, s),
			types:["sound"],
			extensions:s.SUPPORTED_EXTENSIONS
		};
	};

	/**
	 * Used to dispatch fileload events from internal loading.
	 * @method _handleLoadComplete
	 * @param event A loader event.
	 * @protected
	 * @static
	 * @since 0.6.0
	 */
	s._handleLoadComplete = function(event) {
		var src = event.target.getItem().src;
		if (!s._preloadHash[src]) {return;}

		for (var i = 0, l = s._preloadHash[src].length; i < l; i++) {
			var item = s._preloadHash[src][i];
			s._preloadHash[src][i] = true;

			if (!s.hasEventListener("fileload")) { continue; }

			var event = new createjs.Event("fileload");
			event.src = item.src;
			event.id = item.id;
			event.data = item.data;
			event.sprite = item.sprite;

			s.dispatchEvent(event);
		}
	};

	/**
	 * Used to dispatch error events from internal preloading.
	 * @param event
	 * @protected
	 * @since 0.6.0
	 */
	s._handleLoadError = function(event) {
		var src = event.target.getItem().src;
		if (!s._preloadHash[src]) {return;}

		for (var i = 0, l = s._preloadHash[src].length; i < l; i++) {
			var item = s._preloadHash[src][i];
			s._preloadHash[src][i] = false;

			if (!s.hasEventListener("fileerror")) { continue; }

			var event = new createjs.Event("fileerror");
			event.src = item.src;
			event.id = item.id;
			event.data = item.data;
			event.sprite = item.sprite;

			s.dispatchEvent(event);
		}
	};

	/**
	 * Used by {{#crossLink "Sound/registerPlugins"}}{{/crossLink}} to register a Sound plugin.
	 *
	 * @method _registerPlugin
	 * @param {Object} plugin The plugin class to install.
	 * @return {Boolean} Whether the plugin was successfully initialized.
	 * @static
	 * @private
	 */
	s._registerPlugin = function (plugin) {
		// Note: Each plugin is passed in as a class reference, but we store the activePlugin as an instance
		if (plugin.isSupported()) {
			s.activePlugin = new plugin();
			return true;
		}
		return false;
	};

	/**
	 * Register a list of Sound plugins, in order of precedence. To register a single plugin, pass a single element in the array.
	 *
	 * <h4>Example</h4>
	 *      createjs.FlashAudioPlugin.swfPath = "../src/soundjs/flashaudio/";
	 *      createjs.Sound.registerPlugins([createjs.WebAudioPlugin, createjs.HTMLAudioPlugin, createjs.FlashAudioPlugin]);
	 *
	 * @method registerPlugins
	 * @param {Array} plugins An array of plugins classes to install.
	 * @return {Boolean} Whether a plugin was successfully initialized.
	 * @static
	 */
	s.registerPlugins = function (plugins) {
		s._pluginsRegistered = true;
		for (var i = 0, l = plugins.length; i < l; i++) {
			if (s._registerPlugin(plugins[i])) {
				return true;
			}
		}
		return false;
	};

	/**
	 * Initialize the default plugins. This method is automatically called when any audio is played or registered before
	 * the user has manually registered plugins, and enables Sound to work without manual plugin setup. Currently, the
	 * default plugins are {{#crossLink "WebAudioPlugin"}}{{/crossLink}} followed by {{#crossLink "HTMLAudioPlugin"}}{{/crossLink}}.
	 *
	 * <h4>Example</h4>
	 * 	if (!createjs.initializeDefaultPlugins()) { return; }
	 *
	 * @method initializeDefaultPlugins
	 * @returns {Boolean} True if a plugin was initialized, false otherwise.
	 * @since 0.4.0
	 */
	s.initializeDefaultPlugins = function () {
		if (s.activePlugin != null) {return true;}
		if (s._pluginsRegistered) {return false;}
		if (s.registerPlugins([createjs.WebAudioPlugin, createjs.HTMLAudioPlugin])) {return true;}
		return false;
	};

	/**
	 * Determines if Sound has been initialized, and a plugin has been activated.
	 *
	 * <h4>Example</h4>
	 * This example sets up a Flash fallback, but only if there is no plugin specified yet.
	 *
	 * 	if (!createjs.Sound.isReady()) {
	 *		createjs.FlashAudioPlugin.swfPath = "../src/soundjs/flashaudio/";
	 * 		createjs.Sound.registerPlugins([createjs.WebAudioPlugin, createjs.HTMLAudioPlugin, createjs.FlashAudioPlugin]);
	 *	}
	 *
	 * @method isReady
	 * @return {Boolean} If Sound has initialized a plugin.
	 * @static
	 */
	s.isReady = function () {
		return (s.activePlugin != null);
	};

	/**
	 * Get the active plugins capabilities, which help determine if a plugin can be used in the current environment,
	 * or if the plugin supports a specific feature. Capabilities include:
	 * <ul>
	 *     <li><b>panning:</b> If the plugin can pan audio from left to right</li>
	 *     <li><b>volume;</b> If the plugin can control audio volume.</li>
	 *     <li><b>tracks:</b> The maximum number of audio tracks that can be played back at a time. This will be -1
	 *     if there is no known limit.</li>
	 * <br />An entry for each file type in {{#crossLink "Sound/SUPPORTED_EXTENSIONS:property"}}{{/crossLink}}:
	 *     <li><b>mp3:</b> If MP3 audio is supported.</li>
	 *     <li><b>ogg:</b> If OGG audio is supported.</li>
	 *     <li><b>wav:</b> If WAV audio is supported.</li>
	 *     <li><b>mpeg:</b> If MPEG audio is supported.</li>
	 *     <li><b>m4a:</b> If M4A audio is supported.</li>
	 *     <li><b>mp4:</b> If MP4 audio is supported.</li>
	 *     <li><b>aiff:</b> If aiff audio is supported.</li>
	 *     <li><b>wma:</b> If wma audio is supported.</li>
	 *     <li><b>mid:</b> If mid audio is supported.</li>
	 * </ul>
	 * @method getCapabilities
	 * @return {Object} An object containing the capabilities of the active plugin.
	 * @static
	 */
	s.getCapabilities = function () {
		if (s.activePlugin == null) {return null;}
		return s.activePlugin._capabilities;
	};

	/**
	 * Get a specific capability of the active plugin. See {{#crossLink "Sound/getCapabilities"}}{{/crossLink}} for a
	 * full list of capabilities.
	 *
	 * <h4>Example</h4>
	 *      var maxAudioInstances = createjs.Sound.getCapability("tracks");
	 *
	 * @method getCapability
	 * @param {String} key The capability to retrieve
	 * @return {Number|Boolean} The value of the capability.
	 * @static
	 * @see getCapabilities
	 */
	s.getCapability = function (key) {
		if (s.activePlugin == null) {return null;}
		return s.activePlugin._capabilities[key];
	};

	/**
	 * Process manifest items from <a href="http://preloadjs.com" target="_blank">PreloadJS</a>. This method is intended
	 * for usage by a plugin, and not for direct interaction.
	 * @method initLoad
	 * @param {String | Object} src The src or object to load. This is usually a string path, but can also be an
	 * HTMLAudioElement or similar audio playback object.
	 * @param {String} [type] The type of object. Will likely be "sound" or null.
	 * @param {String} [id] An optional user-specified id that is used to play sounds.
	 * @param {Number|String|Boolean|Object} [data] Data associated with the item. Sound uses the data parameter as the
	 * number of channels for an audio instance, however a "channels" property can be appended to the data object if
	 * this property is used for other information. The audio channels will set a default based on plugin if no value is found.
	 * @return {Boolean|Object} An object with the modified values of those that were passed in, or false if the active
	 * plugin can not play the audio type.
	 * @protected
	 * @static
	 */
	s.initLoad = function (src, type, id, data) {
		return s._registerSound(src, id, data);
	};

	/**
	 * Internal method for loading sounds.  This should not be called directly.
	 *
	 * @method _registerSound
	 * @param {String | Object} src The source to load.
	 * @param {String} [id] An id specified by the user to play the sound later.
	 * @param {Number | Object} [data] Data associated with the item. Sound uses the data parameter as the number of
	 * channels for an audio instance, however a "channels" property can be appended to the data object if it is used
	 * for other information. The audio channels will set a default based on plugin if no value is found.
	 * Sound also uses the data property to hold an audioSprite array of objects in the following format {id, startTime, duration}.<br/>
	 *   id used to play the sound later, in the same manner as a sound src with an id.<br/>
	 *   startTime is the initial offset to start playback and loop from, in milliseconds.<br/>
	 *   duration is the amount of time to play the clip for, in milliseconds.<br/>
	 * This allows Sound to support audio sprites that are played back by id.
	 * @return {Object} An object with the modified values that were passed in, which defines the sound.
	 * Returns false if the source cannot be parsed or no plugins can be initialized.
	 * Returns true if the source is already loaded.
	 * @static
	 * @private
	 * @since 0.6.0
	 */

	s._registerSound = function (src, id, data) {
		if (!s.initializeDefaultPlugins()) {return false;}

		var details = s._parsePath(src);
		if (details == null) {return false;}
		details.type = "sound";
		details.id = id;
		details.data = data;

		var numChannels = s.activePlugin.defaultNumChannels || null;
		if (data != null) {
			if (!isNaN(data.channels)) {
				numChannels = parseInt(data.channels);
			} else if (!isNaN(data)) {
				numChannels = parseInt(data);
			}

			if(data.audioSprite) {
				var sp;
				for(var i = data.audioSprite.length; i--; ) {
					sp = data.audioSprite[i];
					s._idHash[sp.id] = {src: details.src, startTime: parseInt(sp.startTime), duration: parseInt(sp.duration)};
				}
			}
		}
		if (id != null) {s._idHash[id] = {src: details.src}};
		var loader = s.activePlugin.register(details.src, numChannels);  // Note only HTML audio uses numChannels

		SoundChannel.create(details.src, numChannels);

		// return the number of instances to the user.  This will also be returned in the load event.
		if (data == null || !isNaN(data)) {
			details.data = numChannels || SoundChannel.maxPerChannel();
		} else {
			details.data.channels = numChannels || SoundChannel.maxPerChannel();
		}

		details.loader = loader;
		if (loader.onload) {details.completeHandler = loader.onload;}	// used by preloadJS
		if (loader.type) {details.type = loader.type;}

		return details;
	};

	/**
	 * Register an audio file for loading and future playback in Sound. This is automatically called when using
	 * <a href="http://preloadjs.com" target="_blank">PreloadJS</a>.  It is recommended to register all sounds that
	 * need to be played back in order to properly prepare and preload them. Sound does internal preloading when required.
	 *
	 * <h4>Example</h4>
	 *      createjs.Sound.alternateExtensions = ["mp3"];
	 *      createjs.Sound.addEventListener("fileload", handleLoad); // add an event listener for when load is completed
	 *      createjs.Sound.registerSound("myAudioPath/mySound.ogg", "myID", 3);
	 *
	 * @method registerSound
	 * @param {String | Object} src The source or an Object with a "src" property
	 * @param {String} [id] An id specified by the user to play the sound later.
	 * @param {Number | Object} [data] Data associated with the item. Sound uses the data parameter as the number of
	 * channels for an audio instance, however a "channels" property can be appended to the data object if it is used
	 * for other information. The audio channels will set a default based on plugin if no value is found.
	 * Sound also uses the data property to hold an audioSprite array of objects in the following format {id, startTime, duration}.<br/>
	 *   id used to play the sound later, in the same manner as a sound src with an id.<br/>
	 *   startTime is the initial offset to start playback and loop from, in milliseconds.<br/>
	 *   duration is the amount of time to play the clip for, in milliseconds.<br/>
	 * This allows Sound to support audio sprites that are played back by id.
	 * @param {string} basePath Set a path that will be prepended to src for loading.
	 * @return {Object} An object with the modified values that were passed in, which defines the sound.
	 * Returns false if the source cannot be parsed or no plugins can be initialized.
	 * Returns true if the source is already loaded.
	 * @static
	 * @since 0.4.0
	 */
	s.registerSound = function (src, id, data, basePath) {
		if (src instanceof Object) {
			basePath = id;
			id = src.id;
			data = src.data;
			src = src.src;
		}

		if (basePath != null) {src = basePath + src;}

		var details = s._registerSound(src, id, data);
		if(!details) {return false;}

		if (!s._preloadHash[details.src]) {	s._preloadHash[details.src] = [];}
		s._preloadHash[details.src].push({src:src, id:id, data:details.data});
		if (s._preloadHash[details.src].length == 1) {
			// OJR note this will disallow reloading a sound if loading fails or the source changes
			var loader = details.loader;
			loader.on("complete", createjs.proxy(this._handleLoadComplete, this));
			loader.on("error", createjs.proxy(this._handleLoadError, this));
			s.activePlugin.preload(details.loader);
		} else {
			if (s._preloadHash[details.src][0] == true) {return true;}
		}

		return details;
	};

	/**
	 * Register an array of audio files for loading and future playback in Sound. It is recommended to register all
	 * sounds that need to be played back in order to properly prepare and preload them. Sound does internal preloading
	 * when required.
	 *
	 * <h4>Example</h4>
	 *      var sounds = [
	 *          {src:"asset0.ogg", id:"example"},
	 *          {src:"asset1.ogg", id:"1", data:6},
	 *          {src:"asset2.mp3", id:"works"}
	 *      ];
	 *      createjs.Sound.alternateExtensions = ["mp3"];	// if the passed extension is not supported, try this extension
	 *      createjs.Sound.addEventListener("fileload", handleLoad); // call handleLoad when each sound loads
	 *      createjs.Sound.registerSounds(sounds, assetPath);
	 *
	 * @method registerSounds
	 * @param {Array} sounds An array of objects to load. Objects are expected to be in the format needed for
	 * {{#crossLink "Sound/registerSound"}}{{/crossLink}}: <code>{src:srcURI, id:ID, data:Data}</code>
	 * with "id" and "data" being optional.  You can also set an optional path property that will be prepended to the src of each object.
	 * @param {string} basePath Set a path that will be prepended to each src when loading.  When creating, playing, or removing
	 * audio that was loaded with a basePath by src, the basePath must be included.
	 * @return {Object} An array of objects with the modified values that were passed in, which defines each sound.
	 * Like registerSound, it will return false for any values when the source cannot be parsed or if no plugins can be initialized.
	 * Also, it will return true for any values when the source is already loaded.
	 * @static
	 * @since 0.6.0
	 */
	s.registerSounds = function (sounds, basePath) {
		var returnValues = [];
		if (sounds.path) {
			if (!basePath) {
				basePath = sounds.path;
			} else {
				basePath = basePath + sounds.path;
			}
		}
		for (var i = 0, l = sounds.length; i < l; i++) {
			returnValues[i] = createjs.Sound.registerSound(sounds[i].src, sounds[i].id, sounds[i].data, basePath);
		}
		return returnValues;
	};

	/**
	 * Deprecated.  Please use {{#crossLink "Sound/registerSounds"}}{{/crossLink} instead.
	 *
	 * @method registerManifest
	 * @param {Array} sounds An array of objects to load. Objects are expected to be in the format needed for
	 * {{#crossLink "Sound/registerSound"}}{{/crossLink}}: <code>{src:srcURI, id:ID, data:Data}</code>
	 * with "id" and "data" being optional.
	 * @param {string} basePath Set a path that will be prepended to each src when loading.  When creating, playing, or removing
	 * audio that was loaded with a basePath by src, the basePath must be included.
	 * @return {Object} An array of objects with the modified values that were passed in, which defines each sound.
	 * Like registerSound, it will return false for any values when the source cannot be parsed or if no plugins can be initialized.
	 * Also, it will return true for any values when the source is already loaded.
	 * @since 0.4.0
	 * @depreacted
 	 */
	s.registerManifest = function(manifest, basePath) {
		try {
			console.log("createjs.Sound.registerManifest is deprecated, please use createjs.Sound.registerSounds.")
		} catch (error) {

		};
		return this.registerSounds(manifest, basePath);
	};

	/**
	 * Remove a sound that has been registered with {{#crossLink "Sound/registerSound"}}{{/crossLink}} or
	 * {{#crossLink "Sound/registerSounds"}}{{/crossLink}}.
	 * <br />Note this will stop playback on active instances playing this sound before deleting them.
	 * <br />Note if you passed in a basePath, you need to pass it or prepend it to the src here.
	 *
	 * <h4>Example</h4>
	 *      createjs.Sound.removeSound("myAudioBasePath/mySound.ogg");
	 *      createjs.Sound.removeSound("myID");
	 *
	 * @method removeSound
	 * @param {String | Object} src The src or ID of the audio, or an Object with a "src" property
	 * @param {string} basePath Set a path that will be prepended to each src when removing.
	 * @return {Boolean} True if sound is successfully removed.
	 * @static
	 * @since 0.4.1
	 */
	s.removeSound = function(src, basePath) {
		if (s.activePlugin == null) {return false;}

		if (src instanceof Object) {src = src.src;}
		src = s._getSrcById(src).src;
		if (basePath != null) {src = basePath + src;}

		var details = s._parsePath(src);
		if (details == null) {return false;}
		src = details.src;

		for(var prop in s._idHash){
			if(s._idHash[prop].src == src) {
				delete(s._idHash[prop]);
			}
		}

		// clear from SoundChannel, which also stops and deletes all instances
		SoundChannel.removeSrc(src);

		delete(s._preloadHash[src]);

		s.activePlugin.removeSound(src);

		return true;
	};

	/**
	 * Remove an array of audio files that have been registered with {{#crossLink "Sound/registerSound"}}{{/crossLink}} or
	 * {{#crossLink "Sound/registerSounds"}}{{/crossLink}}.
	 * <br />Note this will stop playback on active instances playing this audio before deleting them.
	 * <br />Note if you passed in a basePath, you need to pass it or prepend it to the src here.
	 *
	 * <h4>Example</h4>
	 *      var sounds = [
	 *          {src:"asset0.ogg", id:"example"},
	 *          {src:"asset1.ogg", id:"1", data:6},
	 *          {src:"asset2.mp3", id:"works"}
	 *      ];
	 *      createjs.Sound.removeSounds(sounds, assetPath);
	 *
	 * @method removeSounds
	 * @param {Array} sounds An array of objects to remove. Objects are expected to be in the format needed for
	 * {{#crossLink "Sound/removeSound"}}{{/crossLink}}: <code>{srcOrID:srcURIorID}</code>.
	 * You can also set an optional path property that will be prepended to the src of each object.
	 * @param {string} basePath Set a path that will be prepended to each src when removing.
	 * @return {Object} An array of Boolean values representing if the sounds with the same array index were
	 * successfully removed.
	 * @static
	 * @since 0.4.1
	 */
	s.removeSounds = function (sounds, basePath) {
		var returnValues = [];
		if (sounds.path) {
			if (!basePath) {
				basePath = sounds.path;
			} else {
				basePath = basePath + sounds.path;
			}
		}
		for (var i = 0, l = sounds.length; i < l; i++) {
			returnValues[i] = createjs.Sound.removeSound(sounds[i].src, basePath);
		}
		return returnValues;
	};

	/**
	 * Deprecated.  Please use {{#crossLink "Sound/removeSounds"}}{{/crossLink}} instead.
	 *
	 * @method removeManifest
	 * @param {Array} manifest An array of objects to remove. Objects are expected to be in the format needed for
	 * {{#crossLink "Sound/removeSound"}}{{/crossLink}}: <code>{srcOrID:srcURIorID}</code>
	 * @param {string} basePath Set a path that will be prepended to each src when removing.
	 * @return {Object} An array of Boolean values representing if the sounds with the same array index in manifest was
	 * successfully removed.
	 * @static
	 * @since 0.4.1
	 * @deprecated
	 */
	s.removeManifest = function (manifest, basePath) {
		try {
			console.log("createjs.Sound.removeManifest is deprecated, please use createjs.Sound.removeSounds.");
		} catch (error) {

		};
		return s.removeSounds(manifest, basePath);
	};

	/**
	 * Remove all sounds that have been registered with {{#crossLink "Sound/registerSound"}}{{/crossLink}} or
	 * {{#crossLink "Sound/registerSounds"}}{{/crossLink}}.
	 * <br />Note this will stop playback on all active sound instances before deleting them.
	 *
	 * <h4>Example</h4>
	 *     createjs.Sound.removeAllSounds();
	 *
	 * @method removeAllSounds
	 * @static
	 * @since 0.4.1
	 */
	s.removeAllSounds = function() {
		s._idHash = {};
		s._preloadHash = {};
		SoundChannel.removeAll();
		if (s.activePlugin) {s.activePlugin.removeAllSounds();}
	};

	/**
	 * Check if a source has been loaded by internal preloaders. This is necessary to ensure that sounds that are
	 * not completed preloading will not kick off a new internal preload if they are played.
	 *
	 * <h4>Example</h4>
	 *     var mySound = "assetPath/asset0.ogg";
	 *     if(createjs.Sound.loadComplete(mySound) {
	 *         createjs.Sound.play(mySound);
	 *     }
	 *
	 * @method loadComplete
	 * @param {String} src The src or id that is being loaded.
	 * @return {Boolean} If the src is already loaded.
	 * @since 0.4.0
	 */
	s.loadComplete = function (src) {
		if (!s.isReady()) { return false; }
		var details = s._parsePath(src);
		if (details) {
			src = s._getSrcById(details.src).src;
		} else {
			src = s._getSrcById(src).src;
		}
		return (s._preloadHash[src][0] == true);  // src only loads once, so if it's true for the first it's true for all
	};

	/**
	 * Parse the path of a sound. alternate extensions will be attempted in order if the
	 * current extension is not supported
	 * @method _parsePath
	 * @param {String} value The path to an audio source.
	 * @return {Object} A formatted object that can be registered with the {{#crossLink "Sound/activePlugin:property"}}{{/crossLink}}
	 * and returned to a preloader like <a href="http://preloadjs.com" target="_blank">PreloadJS</a>.
	 * @protected
	 */
	s._parsePath = function (value) {
		if (typeof(value) != "string") {value = value.toString();}

		var match = value.match(s.FILE_PATTERN);
		if (match == null) {return false;}

		var name = match[4];
		var ext = match[5];
		var c = s.getCapabilities();
		var i = 0;
		while (!c[ext]) {
			ext = s.alternateExtensions[i++];
			if (i > s.alternateExtensions.length) { return null;}	// no extensions are supported
		}
		value = value.replace("."+match[5], "."+ext);

		var ret = {name:name, src:value, extension:ext};
		return ret;
	};

	/* ---------------
	 Static API.
	 --------------- */
	/**
	 * Play a sound and get a {{#crossLink "AbstractSoundInstance"}}{{/crossLink}} to control. If the sound fails to play, a
	 * AbstractSoundInstance will still be returned, and have a playState of {{#crossLink "Sound/PLAY_FAILED:property"}}{{/crossLink}}.
	 * Note that even on sounds with failed playback, you may still be able to call AbstractSoundInstance {{#crossLink "AbstractSoundInstance/play"}}{{/crossLink}},
	 * since the failure could be due to lack of available channels. If the src does not have a supported extension or
	 * if there is no available plugin, a default AbstractSoundInstance will be returned which will not play any audio, but will not generate errors.
	 *
	 * <h4>Example</h4>
	 *      createjs.Sound.addEventListener("fileload", handleLoad);
	 *      createjs.Sound.registerSound("myAudioPath/mySound.mp3", "myID", 3);
	 *      function handleLoad(event) {
	 *      	createjs.Sound.play("myID");
	 *      	// we can pass in options we want to set inside of an object, and store off AbstractSoundInstance for controlling
	 *      	var myInstance = createjs.Sound.play("myID", {interrupt: createjs.Sound.INTERRUPT_ANY, loop:-1});
	 *      	// alternately, we can pass full source path and specify each argument individually
	 *      	var myInstance = createjs.Sound.play("myAudioPath/mySound.mp3", createjs.Sound.INTERRUPT_ANY, 0, 0, -1, 1, 0);
	 *      }
	 *
	 * NOTE to create an audio sprite that has not already been registered, both startTime and duration need to be set.
	 * This is only when creating a new audio sprite, not when playing using the id of an already registered audio sprite.
	 *
	 * @method play
	 * @param {String} src The src or ID of the audio.
	 * @param {String | Object} [interrupt="none"|options] How to interrupt any currently playing instances of audio with the same source,
	 * if the maximum number of instances of the sound are already playing. Values are defined as <code>INTERRUPT_TYPE</code>
	 * constants on the Sound class, with the default defined by {{#crossLink "Sound/defaultInterruptBehavior:property"}}{{/crossLink}}.
	 * <br /><strong>OR</strong><br />
	 * This parameter can be an object that contains any or all optional properties by name, including: interrupt,
	 * delay, offset, loop, volume, pan, startTime, and duration (see the above code sample).
	 * @param {Number} [delay=0] The amount of time to delay the start of audio playback, in milliseconds.
	 * @param {Number} [offset=0] The offset from the start of the audio to begin playback, in milliseconds.
	 * @param {Number} [loop=0] How many times the audio loops when it reaches the end of playback. The default is 0 (no
	 * loops), and -1 can be used for infinite playback.
	 * @param {Number} [volume=1] The volume of the sound, between 0 and 1. Note that the master volume is applied
	 * against the individual volume.
	 * @param {Number} [pan=0] The left-right pan of the sound (if supported), between -1 (left) and 1 (right).
	 * @param {Number} [startTime=null] To create an audio sprite (with duration), the initial offset to start playback and loop from, in milliseconds.
	 * @param {Number} [duration=null] To create an audio sprite (with startTime), the amount of time to play the clip for, in milliseconds.
	 * @return {AbstractSoundInstance} A {{#crossLink "AbstractSoundInstance"}}{{/crossLink}} that can be controlled after it is created.
	 * @static
	 */
	s.play = function (src, interrupt, delay, offset, loop, volume, pan, startTime, duration) {
		if (interrupt instanceof Object) {
			delay = interrupt.delay;
			offset = interrupt.offset;
			loop = interrupt.loop;
			volume = interrupt.volume;
			pan = interrupt.pan;
			startTime = interrupt.startTime;
			duration = interrupt.duration;
			interrupt = interrupt.interrupt;

		}
		var instance = s.createInstance(src, startTime, duration);
		var ok = s._playInstance(instance, interrupt, delay, offset, loop, volume, pan);
		if (!ok) {instance._playFailed();}
		return instance;
	};

	/**
	 * Creates a {{#crossLink "AbstractSoundInstance"}}{{/crossLink}} using the passed in src. If the src does not have a
	 * supported extension or if there is no available plugin, a default AbstractSoundInstance will be returned that can be
	 * called safely but does nothing.
	 *
	 * <h4>Example</h4>
	 *      var myInstance = null;
	 *      createjs.Sound.addEventListener("fileload", handleLoad);
	 *      createjs.Sound.registerSound("myAudioPath/mySound.mp3", "myID", 3);
	 *      function handleLoad(event) {
	 *      	myInstance = createjs.Sound.createInstance("myID");
	 *      	// alternately we could call the following
	 *      	myInstance = createjs.Sound.createInstance("myAudioPath/mySound.mp3");
	 *      }
	 *
	 * NOTE to create an audio sprite that has not already been registered, both startTime and duration need to be set.
	 * This is only when creating a new audio sprite, not when playing using the id of an already registered audio sprite.
	 *
	 * @method createInstance
	 * @param {String} src The src or ID of the audio.
	 * @param {Number} [startTime=null] To create an audio sprite (with duration), the initial offset to start playback and loop from, in milliseconds.
	 * @param {Number} [duration=null] To create an audio sprite (with startTime), the amount of time to play the clip for, in milliseconds.
	 * @return {AbstractSoundInstance} A {{#crossLink "AbstractSoundInstance"}}{{/crossLink}} that can be controlled after it is created.
	 * Unsupported extensions will return the default AbstractSoundInstance.
	 * @since 0.4.0
	 */
	s.createInstance = function (src, startTime, duration) {
		if (!s.initializeDefaultPlugins()) {return new createjs.DefaultSoundInstance(src, startTime, duration);}

		src = s._getSrcById(src);

		var details = s._parsePath(src.src);

		var instance = null;
		if (details != null && details.src != null) {
			SoundChannel.create(details.src);
			if (startTime == null) {startTime = src.startTime;}
			instance = s.activePlugin.create(details.src, startTime, duration || src.duration);
		} else {
			instance = new createjs.DefaultSoundInstance(src, startTime, duration);;
		}

		instance.uniqueId = s._lastID++;

		return instance;
	};

	/**
	 * Set the master volume of Sound. The master volume is multiplied against each sound's individual volume.  For
	 * example, if master volume is 0.5 and a sound's volume is 0.5, the resulting volume is 0.25. To set individual
	 * sound volume, use AbstractSoundInstance {{#crossLink "AbstractSoundInstance/setVolume"}}{{/crossLink}} instead.
	 *
	 * <h4>Example</h4>
	 *     createjs.Sound.setVolume(0.5);
	 *
	 * @method setVolume
	 * @param {Number} value The master volume value. The acceptable range is 0-1.
	 * @static
	 */
	s.setVolume = function (value) {
		if (Number(value) == null) {return false;}
		value = Math.max(0, Math.min(1, value));
		s._masterVolume = value;
		if (!this.activePlugin || !this.activePlugin.setVolume || !this.activePlugin.setVolume(value)) {
			var instances = this._instances;
			for (var i = 0, l = instances.length; i < l; i++) {
				instances[i].setMasterVolume(value);
			}
		}
	};

	/**
	 * Get the master volume of Sound. The master volume is multiplied against each sound's individual volume.
	 * To get individual sound volume, use AbstractSoundInstance {{#crossLink "AbstractSoundInstance/volume:property"}}{{/crossLink}} instead.
	 *
	 * <h4>Example</h4>
	 *     var masterVolume = createjs.Sound.getVolume();
	 *
	 * @method getVolume
	 * @return {Number} The master volume, in a range of 0-1.
	 * @static
	 */
	s.getVolume = function () {
		return s._masterVolume;
	};

	/**
	 * Mute/Unmute all audio. Note that muted audio still plays at 0 volume. This global mute value is maintained
	 * separately and when set will override, but not change the mute property of individual instances. To mute an individual
	 * instance, use AbstractSoundInstance {{#crossLink "AbstractSoundInstance/setMute"}}{{/crossLink}} instead.
	 *
	 * <h4>Example</h4>
	 *     createjs.Sound.setMute(true);
	 *
	 * @method setMute
	 * @param {Boolean} value Whether the audio should be muted or not.
	 * @return {Boolean} If the mute was set.
	 * @static
	 * @since 0.4.0
	 */
	s.setMute = function (value) {
		if (value == null) {return false;}

		this._masterMute = value;
		if (!this.activePlugin || !this.activePlugin.setMute || !this.activePlugin.setMute(value)) {
			var instances = this._instances;
			for (var i = 0, l = instances.length; i < l; i++) {
				instances[i].setMasterMute(value);
			}
		}
		return true;
	};

	/**
	 * Returns the global mute value. To get the mute value of an individual instance, use AbstractSoundInstance
	 * {{#crossLink "AbstractSoundInstance/getMute"}}{{/crossLink}} instead.
	 *
	 * <h4>Example</h4>
	 *     var muted = createjs.Sound.getMute();
	 *
	 * @method getMute
	 * @return {Boolean} The mute value of Sound.
	 * @static
	 * @since 0.4.0
	 */
	s.getMute = function () {
		return this._masterMute;
	};

	/**
	 * Stop all audio (global stop). Stopped audio is reset, and not paused. To play audio that has been stopped,
	 * call AbstractSoundInstance {{#crossLink "AbstractSoundInstance/play"}}{{/crossLink}}.
	 *
	 * <h4>Example</h4>
	 *     createjs.Sound.stop();
	 *
	 * @method stop
	 * @static
	 */
	s.stop = function () {
		var instances = this._instances;
		for (var i = instances.length; i--; ) {
			instances[i].stop();  // NOTE stop removes instance from this._instances
		}
	};


	/* ---------------
	 Internal methods
	 --------------- */
	/**
	 * Play an instance. This is called by the static API, as well as from plugins. This allows the core class to
	 * control delays.
	 * @method _playInstance
	 * @param {AbstractSoundInstance} instance The {{#crossLink "AbstractSoundInstance"}}{{/crossLink}} to start playing.
	 * @param {String | Object} [interrupt="none"|options] How to interrupt any currently playing instances of audio with the same source,
	 * if the maximum number of instances of the sound are already playing. Values are defined as <code>INTERRUPT_TYPE</code>
	 * constants on the Sound class, with the default defined by {{#crossLink "Sound/defaultInterruptBehavior"}}{{/crossLink}}.
	 * <br /><strong>OR</strong><br />
	 * This parameter can be an object that contains any or all optional properties by name, including: interrupt,
	 * delay, offset, loop, volume, and pan (see the above code sample).
	 * @param {Number} [delay=0] Time in milliseconds before playback begins.
	 * @param {Number} [offset=instance.offset] Time into the sound to begin playback in milliseconds.  Defaults to the
	 * current value on the instance.
	 * @param {Number} [loop=0] The number of times to loop the audio. Use 0 for no loops, and -1 for an infinite loop.
	 * @param {Number} [volume] The volume of the sound between 0 and 1. Defaults to current instance value.
	 * @param {Number} [pan] The pan of the sound between -1 and 1. Defaults to current instance value.
	 * @return {Boolean} If the sound can start playing. Sounds that fail immediately will return false. Sounds that
	 * have a delay will return true, but may still fail to play.
	 * @protected
	 * @static
	 */
	s._playInstance = function (instance, interrupt, delay, offset, loop, volume, pan) {
		if (interrupt instanceof Object) {
			delay = interrupt.delay;
			offset = interrupt.offset;
			loop = interrupt.loop;
			volume = interrupt.volume;
			pan = interrupt.pan;
			interrupt = interrupt.interrupt;
		}

		interrupt = interrupt || s.defaultInterruptBehavior;
		if (delay == null) {delay = 0;}
		if (offset == null) {offset = instance.getPosition();}
		if (loop == null) {loop = instance.loop;}
		if (volume == null) {volume = instance.volume;}
		if (pan == null) {pan = instance.pan;}

		if (delay == 0) {
			var ok = s._beginPlaying(instance, interrupt, offset, loop, volume, pan);
			if (!ok) {return false;}
		} else {
			//Note that we can't pass arguments to proxy OR setTimeout (IE only), so just wrap the function call.
			// OJR WebAudio may want to handle this differently, so it might make sense to move this functionality into the plugins in the future
			var delayTimeoutId = setTimeout(function () {
				s._beginPlaying(instance, interrupt, offset, loop, volume, pan);
			}, delay);
			instance.delayTimeoutId = delayTimeoutId;
		}

		this._instances.push(instance);

		return true;
	};

	/**
	 * Begin playback. This is called immediately or after delay by {{#crossLink "Sound/playInstance"}}{{/crossLink}}.
	 * @method _beginPlaying
	 * @param {AbstractSoundInstance} instance A {{#crossLink "AbstractSoundInstance"}}{{/crossLink}} to begin playback.
	 * @param {String} [interrupt=none] How this sound interrupts other instances with the same source. Defaults to
	 * {{#crossLink "Sound/INTERRUPT_NONE:property"}}{{/crossLink}}. Interrupts are defined as <code>INTERRUPT_TYPE</code>
	 * constants on Sound.
	 * @param {Number} [offset] Time in milliseconds into the sound to begin playback.  Defaults to the current value on
	 * the instance.
	 * @param {Number} [loop=0] The number of times to loop the audio. Use 0 for no loops, and -1 for an infinite loop.
	 * @param {Number} [volume] The volume of the sound between 0 and 1. Defaults to the current value on the instance.
	 * @param {Number} [pan=instance.pan] The pan of the sound between -1 and 1. Defaults to current instance value.
	 * @return {Boolean} If the sound can start playing. If there are no available channels, or the instance fails to
	 * start, this will return false.
	 * @protected
	 * @static
	 */
	s._beginPlaying = function (instance, interrupt, offset, loop, volume, pan) {
		if (!SoundChannel.add(instance, interrupt)) {
			return false;
		}
		var result = instance._beginPlaying(offset, loop, volume, pan);
		if (!result) {
			var index = createjs.indexOf(this._instances, instance);
			if (index > -1) {this._instances.splice(index, 1);}
			return false;
		}
		return true;
	};

	/**
	 * Get the source of a sound via the ID passed in with a register call. If no ID is found the value is returned
	 * instead.
	 * @method _getSrcById
	 * @param {String} value The ID the sound was registered with.
	 * @return {String} The source of the sound if it has been registered with this ID or the value that was passed in.
	 * @protected
	 * @static
	 */
	s._getSrcById = function (value) {
		return s._idHash[value] || {src: value};
	};

	/**
	 * A sound has completed playback, been interrupted, failed, or been stopped. This method removes the instance from
	 * Sound management. It will be added again, if the sound re-plays. Note that this method is called from the
	 * instances themselves.
	 * @method _playFinished
	 * @param {AbstractSoundInstance} instance The instance that finished playback.
	 * @protected
	 * @static
	 */
	s._playFinished = function (instance) {
		SoundChannel.remove(instance);
		var index = createjs.indexOf(this._instances, instance);
		if (index > -1) {this._instances.splice(index, 1);}	// OJR this will always be > -1, there is no way for an instance to exist without being added to this._instances
	};

	createjs.Sound = Sound;

	/**
	 * An internal class that manages the number of active {{#crossLink "AbstractSoundInstance"}}{{/crossLink}} instances for
	 * each sound type. This method is only used internally by the {{#crossLink "Sound"}}{{/crossLink}} class.
	 *
	 * The number of sounds is artificially limited by Sound in order to prevent over-saturation of a
	 * single sound, as well as to stay within hardware limitations, although the latter may disappear with better
	 * browser support.
	 *
	 * When a sound is played, this class ensures that there is an available instance, or interrupts an appropriate
	 * sound that is already playing.
	 * #class SoundChannel
	 * @param {String} src The source of the instances
	 * @param {Number} [max=1] The number of instances allowed
	 * @constructor
	 * @protected
	 */
	function SoundChannel(src, max) {
		this.init(src, max);
	}

	/* ------------
	 Static API
	 ------------ */
	/**
	 * A hash of channel instances indexed by source.
	 * #property channels
	 * @type {Object}
	 * @static
	 */
	SoundChannel.channels = {};

	/**
	 * Create a sound channel. Note that if the sound channel already exists, this will fail.
	 * #method create
	 * @param {String} src The source for the channel
	 * @param {Number} max The maximum amount this channel holds. The default is {{#crossLink "SoundChannel.maxDefault"}}{{/crossLink}}.
	 * @return {Boolean} If the channels were created.
	 * @static
	 */
	SoundChannel.create = function (src, max) {
		var channel = SoundChannel.get(src);
		if (channel == null) {
			SoundChannel.channels[src] = new SoundChannel(src, max);
			return true;
		}
		return false;
	};
	/**
	 * Delete a sound channel, stop and delete all related instances. Note that if the sound channel does not exist, this will fail.
	 * #method remove
	 * @param {String} src The source for the channel
	 * @return {Boolean} If the channels were deleted.
	 * @static
	 */
	SoundChannel.removeSrc = function (src) {
		var channel = SoundChannel.get(src);
		if (channel == null) {return false;}
		channel._removeAll();	// this stops and removes all active instances
		delete(SoundChannel.channels[src]);
		return true;
	};
	/**
	 * Delete all sound channels, stop and delete all related instances.
	 * #method removeAll
	 * @static
	 */
	SoundChannel.removeAll = function () {
		for(var channel in SoundChannel.channels) {
			SoundChannel.channels[channel]._removeAll();	// this stops and removes all active instances
		}
		SoundChannel.channels = {};
	};
	/**
	 * Add an instance to a sound channel.
	 * #method add
	 * @param {AbstractSoundInstance} instance The instance to add to the channel
	 * @param {String} interrupt The interrupt value to use. Please see the {{#crossLink "Sound/play"}}{{/crossLink}}
	 * for details on interrupt modes.
	 * @return {Boolean} The success of the method call. If the channel is full, it will return false.
	 * @static
	 */
	SoundChannel.add = function (instance, interrupt) {
		var channel = SoundChannel.get(instance.src);
		if (channel == null) {return false;}
		return channel._add(instance, interrupt);
	};
	/**
	 * Remove an instance from the channel.
	 * #method remove
	 * @param {AbstractSoundInstance} instance The instance to remove from the channel
	 * @return The success of the method call. If there is no channel, it will return false.
	 * @static
	 */
	SoundChannel.remove = function (instance) {
		var channel = SoundChannel.get(instance.src);
		if (channel == null) {return false;}
		channel._remove(instance);
		return true;
	};
	/**
	 * Get the maximum number of sounds you can have in a channel.
	 * #method maxPerChannel
	 * @return {Number} The maximum number of sounds you can have in a channel.
	 */
	SoundChannel.maxPerChannel = function () {
		return p.maxDefault;
	};
	/**
	 * Get a channel instance by its src.
	 * #method get
	 * @param {String} src The src to use to look up the channel
	 * @static
	 */
	SoundChannel.get = function (src) {
		return SoundChannel.channels[src];
	};

	var p = SoundChannel.prototype;
	p.constructor = SoundChannel;

	/**
	 * The source of the channel.
	 * #property src
	 * @type {String}
	 */
	p.src = null;

	/**
	 * The maximum number of instances in this channel.  -1 indicates no limit
	 * #property max
	 * @type {Number}
	 */
	p.max = null;

	/**
	 * The default value to set for max, if it isn't passed in.  Also used if -1 is passed.
	 * #property maxDefault
	 * @type {Number}
	 * @default 100
	 * @since 0.4.0
	 */
	p.maxDefault = 100;

	/**
	 * The current number of active instances.
	 * #property length
	 * @type {Number}
	 */
	p.length = 0;

	/**
	 * Initialize the channel.
	 * #method init
	 * @param {String} src The source of the channel
	 * @param {Number} max The maximum number of instances in the channel
	 * @protected
	 */
	p.init = function (src, max) {
		this.src = src;
		this.max = max || this.maxDefault;
		if (this.max == -1) {this.max = this.maxDefault;}
		this._instances = [];
	};

	/**
	 * Get an instance by index.
	 * #method get
	 * @param {Number} index The index to return.
	 * @return {AbstractSoundInstance} The AbstractSoundInstance at a specific instance.
	 */
	p._get = function (index) {
		return this._instances[index];
	};

	/**
	 * Add a new instance to the channel.
	 * #method add
	 * @param {AbstractSoundInstance} instance The instance to add.
	 * @return {Boolean} The success of the method call. If the channel is full, it will return false.
	 */
	p._add = function (instance, interrupt) {
		if (!this._getSlot(interrupt, instance)) {return false;}
		this._instances.push(instance);
		this.length++;
		return true;
	};

	/**
	 * Remove an instance from the channel, either when it has finished playing, or it has been interrupted.
	 * #method remove
	 * @param {AbstractSoundInstance} instance The instance to remove
	 * @return {Boolean} The success of the remove call. If the instance is not found in this channel, it will
	 * return false.
	 */
	p._remove = function (instance) {
		var index = createjs.indexOf(this._instances, instance);
		if (index == -1) {return false;}
		this._instances.splice(index, 1);
		this.length--;
		return true;
	};

	/**
	 * Stop playback and remove all instances from the channel.  Usually in response to a delete call.
	 * #method removeAll
	 */
	p._removeAll = function () {
		// Note that stop() removes the item from the list
		for (var i=this.length-1; i>=0; i--) {
			this._instances[i].stop();
		}
	};

	/**
	 * Get an available slot depending on interrupt value and if slots are available.
	 * #method getSlot
	 * @param {String} interrupt The interrupt value to use.
	 * @param {AbstractSoundInstance} instance The sound instance that will go in the channel if successful.
	 * @return {Boolean} Determines if there is an available slot. Depending on the interrupt mode, if there are no slots,
	 * an existing AbstractSoundInstance may be interrupted. If there are no slots, this method returns false.
	 */
	p._getSlot = function (interrupt, instance) {
		var target, replacement;

		if (interrupt != Sound.INTERRUPT_NONE) {
			// First replacement candidate
			replacement = this._get(0);
			if (replacement == null) {
				return true;
			}
		}

		for (var i = 0, l = this.max; i < l; i++) {
			target = this._get(i);

			// Available Space
			if (target == null) {
				return true;
			}

			// Audio is complete or not playing
			if (target.playState == Sound.PLAY_FINISHED ||
				target.playState == Sound.PLAY_INTERRUPTED ||
				target.playState == Sound.PLAY_FAILED) {
				replacement = target;
				break;
			}

			if (interrupt == Sound.INTERRUPT_NONE) {
				continue;
			}

			// Audio is a better candidate than the current target, according to playhead
			if ((interrupt == Sound.INTERRUPT_EARLY && target.getPosition() < replacement.getPosition()) ||
				(interrupt == Sound.INTERRUPT_LATE && target.getPosition() > replacement.getPosition())) {
					replacement = target;
			}
		}

		if (replacement != null) {
			replacement._interrupt();
			this._remove(replacement);
			return true;
		}
		return false;
	};

	p.toString = function () {
		return "[Sound SoundChannel]";
	};
	// do not add SoundChannel to namespace

}());

//##############################################################################
// AbstractSoundInstance.js
//##############################################################################

this.createjs = this.createjs || {};

/**
 * A AbstractSoundInstance is created when any calls to the Sound API method {{#crossLink "Sound/play"}}{{/crossLink}} or
 * {{#crossLink "Sound/createInstance"}}{{/crossLink}} are made. The AbstractSoundInstance is returned by the active plugin
 * for control by the user.
 *
 * <h4>Example</h4>
 *      var myInstance = createjs.Sound.play("myAssetPath/mySrcFile.mp3");
 *
 * A number of additional parameters provide a quick way to determine how a sound is played. Please see the Sound
 * API method {{#crossLink "Sound/play"}}{{/crossLink}} for a list of arguments.
 *
 * Once a AbstractSoundInstance is created, a reference can be stored that can be used to control the audio directly through
 * the AbstractSoundInstance. If the reference is not stored, the AbstractSoundInstance will play out its audio (and any loops), and
 * is then de-referenced from the {{#crossLink "Sound"}}{{/crossLink}} class so that it can be cleaned up. If audio
 * playback has completed, a simple call to the {{#crossLink "AbstractSoundInstance/play"}}{{/crossLink}} instance method
 * will rebuild the references the Sound class need to control it.
 *
 *      var myInstance = createjs.Sound.play("myAssetPath/mySrcFile.mp3", {loop:2});
 *      myInstance.addEventListener("loop", handleLoop);
 *      function handleLoop(event) {
 *          myInstance.volume = myInstance.volume * 0.5;
 *      }
 *
 * Events are dispatched from the instance to notify when the sound has completed, looped, or when playback fails
 *
 *      var myInstance = createjs.Sound.play("myAssetPath/mySrcFile.mp3");
 *      myInstance.addEventListener("complete", handleComplete);
 *      myInstance.addEventListener("loop", handleLoop);
 *      myInstance.addEventListener("failed", handleFailed);
 *
 *
 * @class AbstractSoundInstance
 * @param {String} src The path to and file name of the sound.
 * @param {Number} startTime Audio sprite property used to apply an offset, in milliseconds.
 * @param {Number} duration Audio sprite property used to set the time the clip plays for, in milliseconds.
 * @param {Object} playbackResource Any resource needed by plugin to support audio playback.
 * @extends EventDispatcher
 * @constructor
 */

(function () {
	"use strict";


// Constructor:
	var AbstractSoundInstance = function (src, startTime, duration, playbackResource) {
		this.EventDispatcher_constructor();


	// public properties:
		/**
		 * The source of the sound.
		 * @property src
		 * @type {String}
		 * @default null
		 */
		this.src = src;

		/**
		 * The unique ID of the instance. This is set by {{#crossLink "Sound"}}{{/crossLink}}.
		 * @property uniqueId
		 * @type {String} | Number
		 * @default -1
		 */
		this.uniqueId = -1;

		/**
		 * The play state of the sound. Play states are defined as constants on {{#crossLink "Sound"}}{{/crossLink}}.
		 * @property playState
		 * @type {String}
		 * @default null
		 */
		this.playState = null;

		/**
		 * A Timeout created by {{#crossLink "Sound"}}{{/crossLink}} when this AbstractSoundInstance is played with a delay.
		 * This allows AbstractSoundInstance to remove the delay if stop, pause, or cleanup are called before playback begins.
		 * @property delayTimeoutId
		 * @type {timeoutVariable}
		 * @default null
		 * @protected
		 * @since 0.4.0
		 */
		this.delayTimeoutId = null;
		// TODO consider moving delay into AbstractSoundInstance so it can be handled by plugins


	// private properties
		/**
		 * Audio sprite property used to determine the starting offset.
		 * @type {Number}
		 * @default null
		 * @protected
		 */
		this._startTime = Math.max(0, startTime || 0);
		//TODO add a getter / setter for startTime?


	// Getter / Setter Properties
		// OJR TODO find original reason that we didn't use defined functions.  I think it was performance related
		/**
		 * The volume of the sound, between 0 and 1.
		 * <br />Note this uses a getter setter, which is not supported by Firefox versions 3.6 or lower and Opera versions 11.50 or lower,
		 * and Internet Explorer 8 or lower.  Instead use {{#crossLink "AbstractSoundInstance/setVolume"}}{{/crossLink}} and {{#crossLink "AbstractSoundInstance/getVolume"}}{{/crossLink}}.
		 *
		 * The actual output volume of a sound can be calculated using:
		 * <code>myInstance.volume * createjs.Sound.getVolume();</code>
		 *
		 * @property volume
		 * @type {Number}
		 * @default 1
		 */
		this._volume =  1;
		if (createjs.definePropertySupported) {
			Object.defineProperty(this, "volume", {
			get: this.getVolume,
			set: this.setVolume
			});
		}

		/**
		 * The pan of the sound, between -1 (left) and 1 (right). Note that pan is not supported by HTML Audio.
		 *
		 * <br />Note this uses a getter setter, which is not supported by Firefox versions 3.6 or lower, Opera versions 11.50 or lower,
		 * and Internet Explorer 8 or lower.  Instead use {{#crossLink "AbstractSoundInstance/setPan"}}{{/crossLink}} and {{#crossLink "AbstractSoundInstance/getPan"}}{{/crossLink}}.
		 * <br />Note in WebAudioPlugin this only gives us the "x" value of what is actually 3D audio.
		 *
		 * @property pan
		 * @type {Number}
		 * @default 0
		 */
		this._pan =  0;
		if (createjs.definePropertySupported) {
			Object.defineProperty(this, "pan", {
				get: this.getPan,
				set: this.setPan
			});
		}

		/**
		 * The length of the audio clip, in milliseconds.
		 *
		 * <br />Note this uses a getter setter, which is not supported by Firefox versions 3.6 or lower, Opera versions 11.50 or lower,
		 * and Internet Explorer 8 or lower.  Instead use {{#crossLink "AbstractSoundInstance/setDuration"}}{{/crossLink}} and {{#crossLink "AbstractSoundInstance/getDuration"}}{{/crossLink}}.
		 *
		 * @property duration
		 * @type {Number}
		 * @default 0
		 * @since 0.6.0
		 */
		this._duration = Math.max(0, duration || 0);
		if (createjs.definePropertySupported) {
			Object.defineProperty(this, "duration", {
				get: this.getDuration,
				set: this.setDuration
			});
		}

		/**
		 * Object that holds plugin specific resource need for audio playback.
		 * This is set internally by the plugin.  For example, WebAudioPlugin will set an array buffer,
		 * HTMLAudioPlugin will set a tag, FlashAudioPlugin will set a flash reference.
		 *
		 * @property playbackResource
		 * @type {Object}
		 * @default null
		 */
		this._playbackResource = null;
		if (createjs.definePropertySupported) {
			Object.defineProperty(this, "playbackResource", {
				get: this.getPlaybackResource,
				set: this.setPlaybackResource
			});
		}
		if(playbackResource !== false && playbackResource !== true) { this.setPlaybackResource(playbackResource); }

		/**
		 * The position of the playhead in milliseconds. This can be set while a sound is playing, paused, or stopped.
		 *
		 * <br />Note this uses a getter setter, which is not supported by Firefox versions 3.6 or lower, Opera versions 11.50 or lower,
		 * and Internet Explorer 8 or lower.  Instead use {{#crossLink "AbstractSoundInstance/setPosition"}}{{/crossLink}} and {{#crossLink "AbstractSoundInstance/getPosition"}}{{/crossLink}}.
		 *
		 * @property position
		 * @type {Number}
		 * @default 0
		 * @since 0.6.0
		 */
		this._position = 0;
		if (createjs.definePropertySupported) {
			Object.defineProperty(this, "position", {
				get: this.getPosition,
				set: this.setPosition
			});
		}

		/**
		 * The number of play loops remaining. Negative values will loop infinitely.
		 *
  		 * <br />Note this uses a getter setter, which is not supported by Firefox versions 3.6 or lower, Opera versions 11.50 or lower,
		 * and Internet Explorer 8 or lower.  Instead use {{#crossLink "AbstractSoundInstance/setLoop"}}{{/crossLink}} and {{#crossLink "AbstractSoundInstance/getLoop"}}{{/crossLink}}.
		 *
		 * @property loop
		 * @type {Number}
		 * @default 0
		 * @public
		 * @since 0.6.0
		 */
		this._loop = 0;
		if (createjs.definePropertySupported) {
			Object.defineProperty(this, "loop", {
				get: this.getLoop,
				set: this.setLoop
			});
		}

		/**
		 * Determines if the audio is currently muted.
		 *
		 * <br />Note this uses a getter setter, which is not supported by Firefox versions 3.6 or lower, Opera versions 11.50 or lower,
		 * and Internet Explorer 8 or lower.  Instead use {{#crossLink "AbstractSoundInstance/setMute"}}{{/crossLink}} and {{#crossLink "AbstractSoundInstance/getMute"}}{{/crossLink}}.
		 *
		 * @property muted
		 * @type {Boolean}
		 * @default false
		 * @since 0.6.0
		 */
		this._muted = false;
		if (createjs.definePropertySupported) {
			Object.defineProperty(this, "muted", {
				get: this.getMuted,
				set: this.setMuted
			});
		}

		/**
		 * Tells you if the audio is currently paused.
		 *
		 * <br />Note this uses a getter setter, which is not supported by Firefox versions 3.6 or lower, Opera versions 11.50 or lower,
		 * and Internet Explorer 8 or lower.
		 * Use {{#crossLink "AbstractSoundInstance/pause:method"}}{{/crossLink}} and {{#crossLink "AbstractSoundInstance/resume:method"}}{{/crossLink}} to set.
		 *
		 * @property paused
		 * @type {Boolean}
		 */
		this._paused = false;
		if (createjs.definePropertySupported) {
			Object.defineProperty(this, "paused", {
				get: this.getPaused,
				set: this.setPaused
			});
		}


	// Events
		/**
		 * The event that is fired when playback has started successfully.
		 * @event succeeded
		 * @param {Object} target The object that dispatched the event.
		 * @param {String} type The event type.
		 * @since 0.4.0
		 */

		/**
		 * The event that is fired when playback is interrupted. This happens when another sound with the same
		 * src property is played using an interrupt value that causes this instance to stop playing.
		 * @event interrupted
		 * @param {Object} target The object that dispatched the event.
		 * @param {String} type The event type.
		 * @since 0.4.0
		 */

		/**
		 * The event that is fired when playback has failed. This happens when there are too many channels with the same
		 * src property already playing (and the interrupt value doesn't cause an interrupt of another instance), or
		 * the sound could not be played, perhaps due to a 404 error.
		 * @event failed
		 * @param {Object} target The object that dispatched the event.
		 * @param {String} type The event type.
		 * @since 0.4.0
		 */

		/**
		 * The event that is fired when a sound has completed playing but has loops remaining.
		 * @event loop
		 * @param {Object} target The object that dispatched the event.
		 * @param {String} type The event type.
		 * @since 0.4.0
		 */

		/**
		 * The event that is fired when playback completes. This means that the sound has finished playing in its
		 * entirety, including its loop iterations.
		 * @event complete
		 * @param {Object} target The object that dispatched the event.
		 * @param {String} type The event type.
		 * @since 0.4.0
		 */
	};

	var p = createjs.extend(AbstractSoundInstance, createjs.EventDispatcher);


// Public Methods:
	/**
	 * Play an instance. This method is intended to be called on SoundInstances that already exist (created
	 * with the Sound API {{#crossLink "Sound/createInstance"}}{{/crossLink}} or {{#crossLink "Sound/play"}}{{/crossLink}}).
	 *
	 * <h4>Example</h4>
	 *      var myInstance = createjs.Sound.createInstance(mySrc);
	 *      myInstance.play({offset:1, loop:2, pan:0.5});	// options as object properties
	 *      myInstance.play(createjs.Sound.INTERRUPT_ANY);	// options as parameters
	 *
	 * Note that if this sound is already playing, this call will do nothing.
	 *
	 * @method play
	 * @param {String | Object} [interrupt="none"|options] How to interrupt any currently playing instances of audio with the same source,
	 * if the maximum number of instances of the sound are already playing. Values are defined as <code>INTERRUPT_TYPE</code>
	 * constants on the Sound class, with the default defined by Sound {{#crossLink "Sound/defaultInterruptBehavior:property"}}{{/crossLink}}.
	 * <br /><strong>OR</strong><br />
	 * This parameter can be an object that contains any or all optional properties by name, including: interrupt,
	 * delay, offset, loop, volume, and pan (see the above code sample).
	 * @param {Number} [delay=0] The delay in milliseconds before the sound starts
	 * @param {Number} [offset=0] How far into the sound to begin playback, in milliseconds.
	 * @param {Number} [loop=0] The number of times to loop the audio. Use -1 for infinite loops.
	 * @param {Number} [volume=1] The volume of the sound, between 0 and 1.
	 * @param {Number} [pan=0] The pan of the sound between -1 (left) and 1 (right). Note that pan is not supported
	 * for HTML Audio.
	 * @return {AbstractSoundInstance} A reference to itself, intended for chaining calls.
	 */
	p.play = function (interrupt, delay, offset, loop, volume, pan) {
		if (this.playState == createjs.Sound.PLAY_SUCCEEDED) {
			if (interrupt instanceof Object) {
				offset = interrupt.offset;
				loop = interrupt.loop;
				volume = interrupt.volume;
				pan = interrupt.pan;
			}
			if (offset != null) { this.setPosition(offset) }
			if (loop != null) { this.setLoop(loop); }
			if (volume != null) { this.setVolume(volume); }
			if (pan != null) { this.setPan(pan); }
			if (this._paused) {	this.setPaused(false); }
			return;
		}
		this._cleanUp();
		createjs.Sound._playInstance(this, interrupt, delay, offset, loop, volume, pan);	// make this an event dispatch??
		return this;
	};

	/**
	 * Deprecated, please use {{#crossLink "AbstractSoundInstance/paused:property"}}{{/crossLink}} instead.
	 *
	 * @method pause
	 * @return {Boolean} If the pause call succeeds. This will return false if the sound isn't currently playing.
	 * @deprecated
	 */
	p.pause = function () {
		if (this._paused || this.playState != createjs.Sound.PLAY_SUCCEEDED) {return false;}
		this.setPaused(true);
		return true;
	};

	/**
	 * Deprecated, please use {{#crossLink "AbstractSoundInstance/paused:property"}}{{/crossLink}} instead.
	 *
	 * @method resume
	 * @return {Boolean} If the resume call succeeds. This will return false if called on a sound that is not paused.
	 * @deprecated
	 */
	p.resume = function () {
		if (!this._paused) {return false;}
		this.setPaused(false);
		return true;
	};

	/**
	 * Stop playback of the instance. Stopped sounds will reset their position to 0, and calls to {{#crossLink "AbstractSoundInstance/resume"}}{{/crossLink}}
	 * will fail.  To start playback again, call {{#crossLink "AbstractSoundInstance/play"}}{{/crossLink}}.
	 *
	 * <h4>Example</h4>
	 *
	 *     myInstance.stop();
	 *
	 * @method stop
	 * @return {AbstractSoundInstance} A reference to itself, intended for chaining calls.
	 */
	p.stop = function () {
		this._position = 0;
		this._paused = false;
		this._handleStop();
		this._cleanUp();
		this.playState = createjs.Sound.PLAY_FINISHED;
		return this;
	};

	/**
	 * Remove all external references and resources from AbstractSoundInstance.  Note this is irreversible and AbstractSoundInstance will no longer work
	 * @method destroy
	 * @since 0.6.0
	 */
	p.destroy = function() {
		this._cleanUp();
		this.src = null;
		this.playbackResource = null;

		this.removeAllEventListeners();
	};

	p.toString = function () {
		return "[AbstractSoundInstance]";
	};


// get/set methods that allow support for IE8
	/**
	 * NOTE {{#crossLink "AbstractSoundInstance/paused:property"}}{{/crossLink}} can be accessed directly as a property,
	 * and getPaused remains to allow support for IE8 with FlashAudioPlugin.
	 *
	 * Returns true if the instance is currently paused.
	 *
	 * @method getPaused
	 * @returns {boolean} If the instance is currently paused
	 * @since 0.6.0
	 */
	p.getPaused = function() {
		return this._paused;
	};

	/**
	 * NOTE {{#crossLink "AbstractSoundInstance/paused:property"}}{{/crossLink}} can be accessed directly as a property,
	 * setPaused remains to allow support for IE8 with FlashAudioPlugin.
	 *
	 * Pause or resume the instance.  Note you can also resume playback with {{#crossLink "AbstractSoundInstance/play"}}{{/crossLink}}.
	 *
	 * @param {boolean} value
	 * @since 0.6.0
	 * @return {AbstractSoundInstance} A reference to itself, intended for chaining calls.
	 */
	p.setPaused = function (value) {
		if ((value !== true && value !== false) || this._paused == value) {return;}
		if (value == true && this.playState != createjs.Sound.PLAY_SUCCEEDED) {return;}
		this._paused = value;
		if(value) {
			this._pause();
		} else {
			this._resume();
		}
		clearTimeout(this.delayTimeoutId);
		return this;
	};

	/**
	 * NOTE {{#crossLink "AbstractSoundInstance/volume:property"}}{{/crossLink}} can be accessed directly as a property,
	 * setVolume remains to allow support for IE8 with FlashAudioPlugin.
	 *
	 * Set the volume of the instance.
	 *
	 * <h4>Example</h4>
	 *      myInstance.setVolume(0.5);
	 *
	 * Note that the master volume set using the Sound API method {{#crossLink "Sound/setVolume"}}{{/crossLink}}
	 * will be applied to the instance volume.
	 *
	 * @method setVolume
	 * @param value The volume to set, between 0 and 1.
	 * @return {AbstractSoundInstance} A reference to itself, intended for chaining calls.
	 */
	p.setVolume = function (value) {
		if (value == this._volume) { return this; }
		this._volume = Math.max(0, Math.min(1, value));
		if (!this._muted) {
			this._updateVolume();
		}
		return this;
	};

	/**
	 * NOTE {{#crossLink "AbstractSoundInstance/volume:property"}}{{/crossLink}} can be accessed directly as a property,
	 * getVolume remains to allow support for IE8 with FlashAudioPlugin.
	 *
	 * Get the volume of the instance. The actual output volume of a sound can be calculated using:
	 * <code>myInstance.getVolume() * createjs.Sound.getVolume();</code>
	 *
	 * @method getVolume
	 * @return The current volume of the sound instance.
	 */
	p.getVolume = function () {
		return this._volume;
	};

	/**
	 * Deprecated, please use {{#crossLink "AbstractSoundInstance/muted:property"}}{{/crossLink}} instead.
	 *
	 * @method setMute
	 * @param {Boolean} value If the sound should be muted.
	 * @return {Boolean} If the mute call succeeds.
	 * @deprecated
	 */
	p.setMute = function (value) {
		this.setMuted(value);
	};

	/**
	 * Deprecated, please use {{#crossLink "AbstractSoundInstance/muted:property"}}{{/crossLink}} instead.
	 *
	 * @method getMute
	 * @return {Boolean} If the sound is muted.
	 * @deprecated
	 */
	p.getMute = function () {
		return this._muted;
	};

	/**
	 * NOTE {{#crossLink "AbstractSoundInstance/muted:property"}}{{/crossLink}} can be accessed directly as a property,
	 * setMuted exists to allow support for IE8 with FlashAudioPlugin.
	 *
	 * Mute and unmute the sound. Muted sounds will still play at 0 volume. Note that an unmuted sound may still be
	 * silent depending on {{#crossLink "Sound"}}{{/crossLink}} volume, instance volume, and Sound muted.
	 *
	 * <h4>Example</h4>
	 *     myInstance.setMuted(true);
	 *
	 * @method setMute
	 * @param {Boolean} value If the sound should be muted.
	 * @return {AbstractSoundInstance} A reference to itself, intended for chaining calls.
	 * @since 0.6.0
	 */
	p.setMuted = function (value) {
		if (value !== true && value !== false) {return;}
		this._muted = value;
		this._updateVolume();
		return this;
	};

	/**
	 * NOTE {{#crossLink "AbstractSoundInstance/muted:property"}}{{/crossLink}} can be accessed directly as a property,
	 * getMuted remains to allow support for IE8 with FlashAudioPlugin.
	 *
	 * Get the mute value of the instance.
	 *
	 * <h4>Example</h4>
	 *      var isMuted = myInstance.getMuted();
	 *
	 * @method getMute
	 * @return {Boolean} If the sound is muted.
	 * @since 0.6.0
	 */
	p.getMuted = function () {
		return this._muted;
	};

	/**
	 * NOTE {{#crossLink "AbstractSoundInstance/pan:property"}}{{/crossLink}} can be accessed directly as a property,
	 * getPan remains to allow support for IE8 with FlashAudioPlugin.
	 *
	 * Set the left(-1)/right(+1) pan of the instance. Note that {{#crossLink "HTMLAudioPlugin"}}{{/crossLink}} does not
	 * support panning, and only simple left/right panning has been implemented for {{#crossLink "WebAudioPlugin"}}{{/crossLink}}.
	 * The default pan value is 0 (center).
	 *
	 * <h4>Example</h4>
	 *
	 *     myInstance.setPan(-1);  // to the left!
	 *
	 * @method setPan
	 * @param {Number} value The pan value, between -1 (left) and 1 (right).
	 * @return {AbstractSoundInstance} Returns reference to itself for chaining calls
	 */
	p.setPan = function (value) {
		if(value == this._pan) { return this; }
		this._pan = Math.max(-1, Math.min(1, value));
		this._updatePan();
		return this;
	};

	/**
	 * NOTE {{#crossLink "AbstractSoundInstance/pan:property"}}{{/crossLink}} can be accessed directly as a property,
	 * getPan remains to allow support for IE8 with FlashAudioPlugin.
	 *
	 * Get the left/right pan of the instance. Note in WebAudioPlugin this only gives us the "x" value of what is
	 * actually 3D audio.
	 *
	 * <h4>Example</h4>
	 *
	 *     var myPan = myInstance.getPan();
	 *
	 * @method getPan
	 * @return {Number} The value of the pan, between -1 (left) and 1 (right).
	 */
	p.getPan = function () {
		return this._pan;
	};

	/**
	 * NOTE {{#crossLink "AbstractSoundInstance/position:property"}}{{/crossLink}} can be accessed directly as a property,
	 * getPosition remains to allow support for IE8 with FlashAudioPlugin.
	 *
	 * Get the position of the playhead of the instance in milliseconds.
	 *
	 * <h4>Example</h4>
	 *     var currentOffset = myInstance.getPosition();
	 *
	 * @method getPosition
	 * @return {Number} The position of the playhead in the sound, in milliseconds.
	 */
	p.getPosition = function () {
		if (!this._paused && this.playState == createjs.Sound.PLAY_SUCCEEDED) {
			return this._calculateCurrentPosition();	// sets this._position
		}
		return this._position;
	};

	/**
	 * NOTE {{#crossLink "AbstractSoundInstance/position:property"}}{{/crossLink}} can be accessed directly as a property,
	 * setPosition remains to allow support for IE8 with FlashAudioPlugin.
	 *
	 * Set the position of the playhead in the instance. This can be set while a sound is playing, paused, or
	 * stopped.
	 *
	 * <h4>Example</h4>
	 *      myInstance.setPosition(myInstance.getDuration()/2); // set audio to its halfway point.
	 *
	 * @method setPosition
	 * @param {Number} value The position to place the playhead, in milliseconds.
	 * @return {AbstractSoundInstance} Returns reference to itself for chaining calls
	 */
	p.setPosition = function (value) {
		this._position = Math.max(0, value);
		if (this.playState == createjs.Sound.PLAY_SUCCEEDED) {
			this._updatePosition();
		}
		return this;
	};

	/**
	 * NOTE {{#crossLink "AbstractSoundInstance/duration:property"}}{{/crossLink}} can be accessed directly as a property,
	 * getDuration exists to allow support for IE8 with FlashAudioPlugin.
	 *
	 * Get the duration of the instance, in milliseconds.
	 * Note a sound needs to be loaded before it will have duration, unless it was set manually to create an audio sprite.
	 *
	 * <h4>Example</h4>
	 *     var soundDur = myInstance.getDuration();
	 *
	 * @method getDuration
	 * @return {Number} The duration of the sound instance in milliseconds.
	 */
	p.getDuration = function () {
		return this._duration;
	};

	/**
	 * NOTE {{#crossLink "AbstractSoundInstance/duration:property"}}{{/crossLink}} can be accessed directly as a property,
	 * setDuration exists to allow support for IE8 with FlashAudioPlugin.
	 *
	 * Set the duration of the audio.  Generally this is not called, but it can be used to create an audio sprite out of an existing AbstractSoundInstance.
	 *
	 * @method setDuration
	 * @param {number} value The new duration time in milli seconds.
	 * @return {AbstractSoundInstance} Returns reference to itself for chaining calls
	 * @since 0.6.0
	 */
	p.setDuration = function (value) {
		if (value == this._duration) { return this; }
		this._duration = Math.max(0, value || 0);
		this._updateDuration();
		return this;
	};

	/**
	 * NOTE {{#crossLink "AbstractSoundInstance/playbackResource:property"}}{{/crossLink}} can be accessed directly as a property,
	 * setPlaybackResource exists to allow support for IE8 with FlashAudioPlugin.
	 *
	 * An object containing any resources needed for audio playback, set by the plugin.
	 * Only meant for use by advanced users.
	 *
	 * @method setPlayback
	 * @param {Object} value The new playback resource.
	 * @return {AbstractSoundInstance} Returns reference to itself for chaining calls
	 * @since 0.6.0
	 **/
	p.setPlaybackResource = function (value) {
		this._playbackResource = value;
		if (this._duration == 0) { this._setDurationFromSource(); }
		return this;
	};

	/**
	 * NOTE {{#crossLink "AbstractSoundInstance/playbackResource:property"}}{{/crossLink}} can be accessed directly as a property,
	 * getPlaybackResource exists to allow support for IE8 with FlashAudioPlugin.
	 *
	 * An object containing any resources needed for audio playback, usually set by the plugin.
	 *
	 * @method setPlayback
	 * @param {Object} value The new playback resource.
	 * @return {Object} playback resource used for playing audio
	 * @since 0.6.0
	 **/
	p.getPlaybackResource = function () {
		return this._playbackResource;
	};

	/**
	 * NOTE {{#crossLink "AbstractSoundInstance/loop:property"}}{{/crossLink}} can be accessed directly as a property,
	 * getLoop exists to allow support for IE8 with FlashAudioPlugin.
	 *
	 * The number of play loops remaining. Negative values will loop infinitely.
	 *
	 * @method getLoop
	 * @return {number}
	 * @since 0.6.0
	 **/
	p.getLoop = function () {
		return this._loop;
	};

	/**
	 * NOTE {{#crossLink "AbstractSoundInstance/loop:property"}}{{/crossLink}} can be accessed directly as a property,
	 * setLoop exists to allow support for IE8 with FlashAudioPlugin.
	 *
	 * Set the number of play loops remaining.
	 *
	 * @method setLoop
	 * @param {number} value The number of times to loop after play.
	 * @since 0.6.0
	 */
	p.setLoop = function (value) {
		if(this._playbackResource != null) {
			// remove looping
			if (this._loop != 0 && value == 0) {
				this._removeLooping(value);
			}
			// add looping
			if (this._loop == 0 && value != 0) {
				this._addLooping(value);
			}
		}
		this._loop = value;
	};


// Private Methods:
	/**
	 * A helper method that dispatches all events for AbstractSoundInstance.
	 * @method _sendEvent
	 * @param {String} type The event type
	 * @protected
	 */
	p._sendEvent = function (type) {
		var event = new createjs.Event(type);
		this.dispatchEvent(event);
	};

	/**
	 * Clean up the instance. Remove references and clean up any additional properties such as timers.
	 * @method _cleanUp
	 * @protected
	 */
	p._cleanUp = function () {
		clearTimeout(this.delayTimeoutId); // clear timeout that plays delayed sound
		this._handleCleanUp();
		this._paused = false;

		createjs.Sound._playFinished(this);	// TODO change to an event
	};

	/**
	 * The sound has been interrupted.
	 * @method _interrupt
	 * @protected
	 */
	p._interrupt = function () {
		this._cleanUp();
		this.playState = createjs.Sound.PLAY_INTERRUPTED;
		this._sendEvent("interrupted");
	};

	/**
	 * Called by the Sound class when the audio is ready to play (delay has completed). Starts sound playing if the
	 * src is loaded, otherwise playback will fail.
	 * @method _beginPlaying
	 * @param {Number} offset How far into the sound to begin playback, in milliseconds.
	 * @param {Number} loop The number of times to loop the audio. Use -1 for infinite loops.
	 * @param {Number} volume The volume of the sound, between 0 and 1.
	 * @param {Number} pan The pan of the sound between -1 (left) and 1 (right). Note that pan does not work for HTML Audio.
	 * @return {Boolean} If playback succeeded.
	 * @protected
	 */
	p._beginPlaying = function (offset, loop, volume, pan) {
		this.setPosition(offset);
		this.setLoop(loop);
		this.setVolume(volume);
		this.setPan(pan);

		if (this._playbackResource != null && this._position < this._duration) {
			this._paused = false;
			this._handleSoundReady();
			this.playState = createjs.Sound.PLAY_SUCCEEDED;
			this._sendEvent("succeeded");
			return true;
		} else {
			this._playFailed();
			return false;
		}
	};

	/**
	 * Play has failed, which can happen for a variety of reasons.
	 * Cleans up instance and dispatches failed event
	 * @method _playFailed
	 * @private
	 */
	p._playFailed = function () {
		this._cleanUp();
		this.playState = createjs.Sound.PLAY_FAILED;
		this._sendEvent("failed");
	};

	/**
	 * Audio has finished playing. Manually loop it if required.
	 * @method _handleSoundComplete
	 * @param event
	 * @protected
	 */
	p._handleSoundComplete = function (event) {
		this._position = 0;  // have to set this as it can be set by pause during playback

		if (this._loop != 0) {
			this._loop--;  // NOTE this introduces a theoretical limit on loops = float max size x 2 - 1
			this._handleLoop();
			this._sendEvent("loop");
			return;
		}

		this._cleanUp();
		this.playState = createjs.Sound.PLAY_FINISHED;
		this._sendEvent("complete");
	};

// Plugin specific code
	/**
	 * Handles starting playback when the sound is ready for playing.
	 * @method _handleSoundReady
	 * @protected
 	 */
	p._handleSoundReady = function () {
		// plugin specific code
	};

	/**
	 * Internal function used to update the volume based on the instance volume, master volume, instance mute value,
	 * and master mute value.
	 * @method _updateVolume
	 * @protected
	 */
	p._updateVolume = function () {
		// plugin specific code
	};

	/**
	 * Internal function used to update the pan
	 * @method _updatePan
	 * @protected
	 * @since 0.6.0
	 */
	p._updatePan = function () {
		// plugin specific code
	};

	/**
	 * Internal function used to update the duration of the audio.
	 * @method _updateDuration
	 * @protected
	 * @since 0.6.0
	 */
	p._updateDuration = function () {
		// plugin specific code
	};

	/**
	 * Internal function used to get the duration of the audio from the source we'll be playing.
	 * @method _updateDuration
	 * @protected
	 * @since 0.6.0
	 */
	p._setDurationFromSource = function () {
		// plugin specific code
	};

	/**
	 * Internal function that calculates the current position of the playhead and sets it on this._position
	 * @method _updatePosition
	 * @protected
	 * @since 0.6.0
	 */
	p._calculateCurrentPosition = function () {
		// plugin specific code that sets this.position
	};

	/**
	 * Internal function used to update the position of the playhead.
	 * @method _updatePosition
	 * @protected
	 * @since 0.6.0
	 */
	p._updatePosition = function () {
		// plugin specific code
	};

	/**
	 * Internal function called when looping is removed during playback.
	 * @method _removeLooping
	 * @protected
	 * @since 0.6.0
	 */
	p._removeLooping = function () {
		// plugin specific code
	};

	/**
	 * Internal function called when looping is added during playback.
	 * @method _addLooping
	 * @protected
	 * @since 0.6.0
	 */
	p._addLooping = function () {
		// plugin specific code
	};

	/**
	 * Internal function called when pausing playback
	 * @method _pause
	 * @protected
	 * @since 0.6.0
	 */
	p._pause = function () {
		// plugin specific code
	};

	/**
	 * Internal function called when resuming playback
	 * @method _resume
	 * @protected
	 * @since 0.6.0
	 */
	p._resume = function () {
		// plugin specific code
	};

	/**
	 * Internal function called when stopping playback
	 * @method _handleStop
	 * @protected
	 * @since 0.6.0
	 */
	p._handleStop = function() {
		// plugin specific code
	};

	/**
	 * Internal function called when AbstractSoundInstance is being cleaned up
	 * @method _handleCleanUp
	 * @protected
	 * @since 0.6.0
	 */
	p._handleCleanUp = function() {
		// plugin specific code
	};

	/**
	 * Internal function called when AbstractSoundInstance has played to end and is looping
	 * @method _handleCleanUp
	 * @protected
	 * @since 0.6.0
	 */
	p._handleLoop = function () {
		// plugin specific code
	};

	createjs.AbstractSoundInstance = createjs.promote(AbstractSoundInstance, "EventDispatcher");
	createjs.DefaultSoundInstance = createjs.AbstractSoundInstance;	// used when no plugin is supported
}());

//##############################################################################
// AbstractPlugin.js
//##############################################################################

this.createjs = this.createjs || {};

(function () {
	"use strict";


// constructor:
 	/**
	 * A default plugin class used as a base for all other plugins.
	 * @class AbstractPlugin
	 * @constructor
	 * @since 0.6.0
	 */

	var AbstractPlugin = function () {
	// private properties:
		/**
		 * The capabilities of the plugin.
		 * method and is used internally.
		 * @property _capabilities
		 * @type {Object}
		 * @default null
		 * @protected
		 * @static
		 */
		this._capabilities = null;

		/**
		 * Object hash indexed by the source URI of all created loaders, used to properly destroy them if sources are removed.
		 * @type {Object}
		 * @protected
		 */
		this._loaders = {};

		/**
		 * Object hash indexed by the source URI of each file to indicate if an audio source has begun loading,
		 * is currently loading, or has completed loading.  Can be used to store non boolean data after loading
		 * is complete (for example arrayBuffers for web audio).
		 * @property _audioSources
		 * @type {Object}
		 * @protected
		 */
		this._audioSources = {};

		/**
		 * Object hash indexed by the source URI of all created SoundInstances, updates the playbackResource if it loads after they are created,
		 * and properly destroy them if sources are removed
		 * @type {Object}
		 * @protected
		 */
		this._soundInstances = {};

		/**
		 * A reference to a loader class used by a plugin that must be set.
		 * @type {Object}
		 * @protected
		 */
		this._loaderClass;

		/**
		 * A reference to an AbstractSoundInstance class used by a plugin that must be set.
		 * @type {Object}
		 * @protected;
		 */
		this._soundInstanceClass;
	};
	var p = AbstractPlugin.prototype;


// Static Properties:
// NOTE THESE PROPERTIES NEED TO BE ADDED TO EACH PLUGIN
	/**
	 * The capabilities of the plugin. This is generated via the {{#crossLink "WebAudioPlugin/_generateCapabilities:method"}}{{/crossLink}}
	 * method and is used internally.
	 * @property _capabilities
	 * @type {Object}
	 * @default null
	 * @protected
	 * @static
	 */
	AbstractPlugin._capabilities = null;

	/**
	 * Determine if the plugin can be used in the current browser/OS.
	 * @method isSupported
	 * @return {Boolean} If the plugin can be initialized.
	 * @static
	 */
	AbstractPlugin.isSupported = function () {
		return true;
	};


// public methods:
	/**
	 * Pre-register a sound for preloading and setup. This is called by {{#crossLink "Sound"}}{{/crossLink}}.
	 * Note all plugins provide a <code>Loader</code> instance, which <a href="http://preloadjs.com" target="_blank">PreloadJS</a>
	 * can use to assist with preloading.
	 * @method register
	 * @param {String} src The source of the audio
	 * @param {Number} instances The number of concurrently playing instances to allow for the channel at any time.
	 * Note that not every plugin will manage this value.
	 * @return {Object} A result object, containing a "tag" for preloading purposes.
	 */
	p.register = function (src, instances) {
		this._audioSources[src] = true;
		this._soundInstances[src] = [];
		if(this._loaders[src]) {return this._loaders[src];}	// already loading/loaded this, so don't load twice
		// OJR potential issue that we won't be firing loaded event, might need to trigger if this is already loaded?
		var loader = new this._loaderClass(src);
		loader.on("complete", createjs.proxy(this._handlePreloadComplete, this));
		this._loaders[src] = loader;
		return loader;
	};

	// note sound calls register before calling preload
	/**
	 * Internally preload a sound.
	 * @method preload
	 * @param {Loader} loader The sound URI to load.
	 */
	p.preload = function (loader) {
		loader.on("error", createjs.proxy(this._handlePreloadError, this));
		loader.load();
	};

	/**
	 * Checks if preloading has started for a specific source. If the source is found, we can assume it is loading,
	 * or has already finished loading.
	 * @method isPreloadStarted
	 * @param {String} src The sound URI to check.
	 * @return {Boolean}
	 */
	p.isPreloadStarted = function (src) {
		return (this._audioSources[src] != null);
	};

	/**
	 * Checks if preloading has finished for a specific source.
	 * @method isPreloadComplete
	 * @param {String} src The sound URI to load.
	 * @return {Boolean}
	 */
	p.isPreloadComplete = function (src) {
		return (!(this._audioSources[src] == null || this._audioSources[src] == true));
	};

	/**
	 * Remove a sound added using {{#crossLink "WebAudioPlugin/register"}}{{/crossLink}}. Note this does not cancel a preload.
	 * @method removeSound
	 * @param {String} src The sound URI to unload.
	 */
	p.removeSound = function (src) {
		for (var i = this._soundInstances[src].length; i--; ) {
			var item = this._soundInstances[src][i];
			item.destroy();
		}
		delete(this._soundInstances[src]);
		delete(this._audioSources[src]);
		this._loaders[src].destroy();
		delete(this._loaders[src]);
	};

	/**
	 * Remove all sounds added using {{#crossLink "WebAudioPlugin/register"}}{{/crossLink}}. Note this does not cancel a preload.
	 * @method removeAllSounds
	 * @param {String} src The sound URI to unload.
	 */
	p.removeAllSounds = function () {
		for(var key in this._audioSources) {
			this.removeSound(key);
		}
	};

	/**
	 * Create a sound instance. If the sound has not been preloaded, it is internally preloaded here.
	 * @method create
	 * @param {String} src The sound source to use.
	 * @param {Number} startTime Audio sprite property used to apply an offset, in milliseconds.
	 * @param {Number} duration Audio sprite property used to set the time the clip plays for, in milliseconds.
	 * @return {AbstractSoundInstance} A sound instance for playback and control.
	 */
	p.create = function (src, startTime, duration) {
		if (!this.isPreloadStarted(src)) {
			this.preload(this.register(src));
		}
		var si = new this._soundInstanceClass(src, startTime, duration, this._audioSources[src]);
		this._soundInstances[src].push(si);
		return si;
	};

	// TODO Volume & mute Getter / Setter??
	// TODO change calls to return nothing or this for chaining??
	// if a plugin does not support volume and mute, it should set these to null
	/**
	 * Set the master volume of the plugin, which affects all SoundInstances.
	 * @method setVolume
	 * @param {Number} value The volume to set, between 0 and 1.
	 * @return {Boolean} If the plugin processes the setVolume call (true). The Sound class will affect all the
	 * instances manually otherwise.
	 */
	p.setVolume = function (value) {
		this._volume = value;
		this._updateVolume();
		return true;
	};

	/**
	 * Get the master volume of the plugin, which affects all SoundInstances.
	 * @method getVolume
	 * @return The volume level, between 0 and 1.
	 */
	p.getVolume = function () {
		return this._volume;
	};

	/**
	 * Mute all sounds via the plugin.
	 * @method setMute
	 * @param {Boolean} value If all sound should be muted or not. Note that plugin-level muting just looks up
	 * the mute value of Sound {{#crossLink "Sound/getMute"}}{{/crossLink}}, so this property is not used here.
	 * @return {Boolean} If the mute call succeeds.
	 */
	p.setMute = function (value) {
		this._updateVolume();
		return true;
	};

	// plugins should overwrite this method
	p.toString = function () {
		return "[AbstractPlugin]";
	};


// private methods:
	/**
	 * Handles internal preload completion.
	 * @method _handlePreloadComplete
	 * @protected
	 */
	p._handlePreloadComplete = function (event) {
		var src = event.target.getItem().src;
		this._audioSources[src] = event.result;
		for (var i = 0, l = this._soundInstances[src].length; i < l; i++) {
			var item = this._soundInstances[src][i];
			item.setPlaybackResource(this._audioSources[src]);
			// ToDo consider adding play call here if playstate == playfailed
		}
	};

	/**
	 * Handles internal preload erros
	 * @method _handlePreloadError
	 * @param event
	 * @protected
	 */
	p._handlePreloadError = function(event) {
		//delete(this._audioSources[src]);
	};

	/**
	 * Set the gain value for master audio. Should not be called externally.
	 * @method _updateVolume
	 * @protected
	 */
	p._updateVolume = function () {
		// Plugin Specific code
	};

	createjs.AbstractPlugin = AbstractPlugin;
}());

//##############################################################################
// WebAudioLoader.js
//##############################################################################

this.createjs = this.createjs || {};

(function () {
	"use strict";

	/**
	 * Loader provides a mechanism to preload Web Audio content via PreloadJS or internally. Instances are returned to
	 * the preloader, and the load method is called when the asset needs to be requested.
	 *
	 * @class WebAudioLoader
	 * @param {String} src The path to the sound
	 * @param {Object} flash The flash instance that will do the preloading.
	 * @extends XHRRequest
	 * @protected
	 */
	function Loader(src) {
		this.AbstractLoader_constructor(src, true, createjs.AbstractLoader.SOUND);

	};
	var p = createjs.extend(Loader, createjs.AbstractLoader);

	/**
	 * web audio context required for decoding audio
	 * @property context
	 * @type {AudioContext}
	 * @static
	 */
	Loader.context = null;


// public methods
	p.toString = function () {
		return "[WebAudioLoader]";
	};


// private methods
	p._createRequest = function() {
		this._request = new createjs.XHRRequest(this._item, false);
		this._request.setResponseType("arraybuffer");
	};

	p._sendComplete = function (event) {
		// OJR we leave this wrapped in Loader because we need to reference src and the handler only receives a single argument, the decodedAudio
		Loader.context.decodeAudioData(this._rawResult,
	         createjs.proxy(this._handleAudioDecoded, this),
	         createjs.proxy(this._handleError, this));
	};


	/**
	* The audio has been decoded.
	* @method handleAudioDecoded
	 * @param decoded
	* @protected
	*/
	p._handleAudioDecoded = function (decodedAudio) {
		this._result = decodedAudio;
		this.AbstractLoader__sendComplete();
	};

	createjs.WebAudioLoader = createjs.promote(Loader, "AbstractLoader");
}());

//##############################################################################
// WebAudioSoundInstance.js
//##############################################################################

this.createjs = this.createjs || {};

/**
 * WebAudioSoundInstance extends the base api of {{#crossLink "AbstractSoundInstance"}}{{/crossLink}} and is used by
 * {{#crossLink "WebAudioPlugin"}}{{/crossLink}}.
 *
 * WebAudioSoundInstance exposes audioNodes for advanced users.
 *
 * @param {String} src The path to and file name of the sound.
 * @param {Number} startTime Audio sprite property used to apply an offset, in milliseconds.
 * @param {Number} duration Audio sprite property used to set the time the clip plays for, in milliseconds.
 * @param {Object} playbackResource Any resource needed by plugin to support audio playback.
 * @class WebAudioSoundInstance
 * @extends AbstractSoundInstance
 * @constructor
 */
(function () {
	"use strict";

	function WebAudioSoundInstance(src, startTime, duration, playbackResource) {
		this.AbstractSoundInstance_constructor(src, startTime, duration, playbackResource);


// public properties
		/**
		 * NOTE this is only intended for use by advanced users.
		 * <br />GainNode for controlling <code>WebAudioSoundInstance</code> volume. Connected to the {{#crossLink "WebAudioSoundInstance/destinationNode:property"}}{{/crossLink}}.
		 * @property gainNode
		 * @type {AudioGainNode}
		 * @since 0.4.0
		 *
		 */
		this.gainNode = s.context.createGain();

		/**
		 * NOTE this is only intended for use by advanced users.
		 * <br />A panNode allowing left and right audio channel panning only. Connected to WebAudioSoundInstance {{#crossLink "WebAudioSoundInstance/gainNode:property"}}{{/crossLink}}.
		 * @property panNode
		 * @type {AudioPannerNode}
		 * @since 0.4.0
		 */
		this.panNode = s.context.createPanner();
		this.panNode.panningModel = s._panningModel;
		this.panNode.connect(this.gainNode);

		/**
		 * NOTE this is only intended for use by advanced users.
		 * <br />sourceNode is the audio source. Connected to WebAudioSoundInstance {{#crossLink "WebAudioSoundInstance/panNode:property"}}{{/crossLink}}.
		 * @property sourceNode
		 * @type {AudioNode}
		 * @since 0.4.0
		 *
		 */
		this.sourceNode = null;


// private properties
		/**
		 * Timeout that is created internally to handle sound playing to completion.
		 * Stored so we can remove it when stop, pause, or cleanup are called
		 * @property _soundCompleteTimeout
		 * @type {timeoutVariable}
		 * @default null
		 * @protected
		 * @since 0.4.0
		 */
		this._soundCompleteTimeout = null;

		/**
		 * NOTE this is only intended for use by very advanced users.
		 * _sourceNodeNext is the audio source for the next loop, inserted in a look ahead approach to allow for smooth
		 * looping. Connected to {{#crossLink "WebAudioSoundInstance/gainNode:property"}}{{/crossLink}}.
		 * @property _sourceNodeNext
		 * @type {AudioNode}
		 * @default null
		 * @protected
		 * @since 0.4.1
		 *
		 */
		this._sourceNodeNext = null;

		/**
		 * Time audio started playback, in seconds. Used to handle set position, get position, and resuming from paused.
		 * @property _playbackStartTime
		 * @type {Number}
		 * @default 0
		 * @protected
		 * @since 0.4.0
		 */
		this._playbackStartTime = 0;

		// Proxies, make removing listeners easier.
		this._endedHandler = createjs.proxy(this._handleSoundComplete, this);
	};
	var p = createjs.extend(WebAudioSoundInstance, createjs.AbstractSoundInstance);
	var s = WebAudioSoundInstance;

	/**
	 * Note this is only intended for use by advanced users.
	 * <br />Audio context used to create nodes.  This is and needs to be the same context used by {{#crossLink "WebAudioPlugin"}}{{/crossLink}}.
  	 * @property context
	 * @type {AudioContext}
	 * @static
	 * @since 0.6.0
	 */
	s.context = null;

	/**
	 * Note this is only intended for use by advanced users.
	 * <br /> Audio node from WebAudioPlugin that sequences to <code>context.destination</code>
	 * @property destinationNode
	 * @type {AudioNode}
	 * @static
	 * @since 0.6.0
	 */
	s.destinationNode = null;

	/**
	 * Value to set panning model to equal power for WebAudioSoundInstance.  Can be "equalpower" or 0 depending on browser implementation.
	 * @property _panningModel
	 * @type {Number / String}
	 * @protected
	 * @static
	 * @since 0.6.0
	 */
	s._panningModel = "equalpower";


// Public methods
	p.destroy = function() {
		this.AbstractSoundInstance_destroy();

		this.panNode.disconnect(0);
		this.panNode = null;
		this.gainNode.disconnect(0);
		this.gainNode = null;
	};

	p.toString = function () {
		return "[WebAudioSoundInstance]";
	};


// Private Methods
	p._updatePan = function() {
		this.panNode.setPosition(this._pan, 0, -0.5);
		// z need to be -0.5 otherwise the sound only plays in left, right, or center
	};

	p._removeLooping = function() {
		this._sourceNodeNext = this._cleanUpAudioNode(this._sourceNodeNext);
	};

	p._addLooping = function() {
		if (this.playState != createjs.Sound.PLAY_SUCCEEDED) { return; }
		this._sourceNodeNext = this._createAndPlayAudioNode(this._playbackStartTime, 0);
	};

	p._setDurationFromSource = function () {
		this._duration = this.playbackResource.duration * 1000;
	};

	p._handleCleanUp = function () {
		if (this.sourceNode && this.playState == createjs.Sound.PLAY_SUCCEEDED) {
			this.sourceNode = this._cleanUpAudioNode(this.sourceNode);
			this._sourceNodeNext = this._cleanUpAudioNode(this._sourceNodeNext);
		}

		if (this.gainNode.numberOfOutputs != 0) {this.gainNode.disconnect(0);}
		// OJR there appears to be a bug that this doesn't always work in webkit (Chrome and Safari). According to the documentation, this should work.

		clearTimeout(this._soundCompleteTimeout);

		this._playbackStartTime = 0;	// This is used by getPosition
	};

	/**
	 * Turn off and disconnect an audioNode, then set reference to null to release it for garbage collection
	 * @method _cleanUpAudioNode
	 * @param audioNode
	 * @return {audioNode}
	 * @protected
	 * @since 0.4.1
	 */
	p._cleanUpAudioNode = function(audioNode) {
		if(audioNode) {
			audioNode.stop(0);
			audioNode.disconnect(0);
			audioNode = null;
		}
		return audioNode;
	};

	p._handleSoundReady = function (event) {
		this.gainNode.connect(s.destinationNode);  // this line can cause a memory leak.  Nodes need to be disconnected from the audioDestination or any sequence that leads to it.

		var dur = this._duration * 0.001;
		var pos = this._position * 0.001;
		this.sourceNode = this._createAndPlayAudioNode((s.context.currentTime - dur), pos);
		this._playbackStartTime = this.sourceNode.startTime - pos;

		this._soundCompleteTimeout = setTimeout(this._endedHandler, (dur - pos) * 1000);

		if(this._loop != 0) {
			this._sourceNodeNext = this._createAndPlayAudioNode(this._playbackStartTime, 0);
		}
	};

	/**
	 * Creates an audio node using the current src and context, connects it to the gain node, and starts playback.
	 * @method _createAndPlayAudioNode
	 * @param {Number} startTime The time to add this to the web audio context, in seconds.
	 * @param {Number} offset The amount of time into the src audio to start playback, in seconds.
	 * @return {audioNode}
	 * @protected
	 * @since 0.4.1
	 */
	p._createAndPlayAudioNode = function(startTime, offset) {
		var audioNode = s.context.createBufferSource();
		audioNode.buffer = this.playbackResource;
		audioNode.connect(this.panNode);
		var dur = this._duration * 0.001;
		audioNode.startTime = startTime + dur;
		audioNode.start(audioNode.startTime, offset+(this._startTime*0.001), dur - offset);
		return audioNode;
	};

	p._pause = function () {
		this._position = (s.context.currentTime - this._playbackStartTime) * 1000;  // * 1000 to give milliseconds, lets us restart at same point
		this.sourceNode = this._cleanUpAudioNode(this.sourceNode);
		this._sourceNodeNext = this._cleanUpAudioNode(this._sourceNodeNext);

		if (this.gainNode.numberOfOutputs != 0) {this.gainNode.disconnect(0);}

		clearTimeout(this._soundCompleteTimeout);
	};

	p._resume = function () {
		this._handleSoundReady();
	};

	/*
	p._handleStop = function () {
		// web audio does not need to do anything extra
	};
	*/

	p._updateVolume = function () {
		var newVolume = this._muted ? 0 : this._volume;
	  	if (newVolume != this.gainNode.gain.value) {
		  this.gainNode.gain.value = newVolume;
  		}
	};

	p._calculateCurrentPosition = function () {
		return ((s.context.currentTime - this._playbackStartTime) * 1000); // pos in seconds * 1000 to give milliseconds
	};

	p._updatePosition = function () {
		this.sourceNode = this._cleanUpAudioNode(this.sourceNode);
		this._sourceNodeNext = this._cleanUpAudioNode(this._sourceNodeNext);
		clearTimeout(this._soundCompleteTimeout);

		if (!this._paused) {this._handleSoundReady();}
	};

	// OJR we are using a look ahead approach to ensure smooth looping.
	// We add _sourceNodeNext to the audio context so that it starts playing even if this callback is delayed.
	// This technique is described here:  http://www.html5rocks.com/en/tutorials/audio/scheduling/
	// NOTE the cost of this is that our audio loop may not always match the loop event timing precisely.
	p._handleLoop = function () {
		this._cleanUpAudioNode(this.sourceNode);
		this.sourceNode = this._sourceNodeNext;
		this._playbackStartTime = this.sourceNode.startTime;
		this._sourceNodeNext = this._createAndPlayAudioNode(this._playbackStartTime, 0);
		this._soundCompleteTimeout = setTimeout(this._endedHandler, this._duration);
	};

	p._updateDuration = function () {
		this._pause();
		this._resume();
	};

	createjs.WebAudioSoundInstance = createjs.promote(WebAudioSoundInstance, "AbstractSoundInstance");
}());

//##############################################################################
// WebAudioPlugin.js
//##############################################################################

this.createjs = this.createjs || {};

(function () {

	"use strict";

	/**
	 * Play sounds using Web Audio in the browser. The WebAudioPlugin is currently the default plugin, and will be used
	 * anywhere that it is supported. To change plugin priority, check out the Sound API
	 * {{#crossLink "Sound/registerPlugins"}}{{/crossLink}} method.

	 * <h4>Known Browser and OS issues for Web Audio</h4>
	 * <b>Firefox 25</b>
	 * <ul><li>mp3 audio files do not load properly on all windows machines, reported
	 * <a href="https://bugzilla.mozilla.org/show_bug.cgi?id=929969" target="_blank">here</a>. </br>
	 * For this reason it is recommended to pass another FF supported type (ie ogg) first until this bug is resolved, if possible.</li></ul>
	 * <br />
	 * <b>Webkit (Chrome and Safari)</b>
	 * <ul><li>AudioNode.disconnect does not always seem to work.  This can cause the file size to grow over time if you
	 * are playing a lot of audio files.</li></ul>
	 * <br />
	 * <b>iOS 6 limitations</b>
	 * 	<ul><li>Sound is initially muted and will only unmute through play being called inside a user initiated event (touch/click).</li>
	 *	<li>A bug exists that will distort uncached audio when a video element is present in the DOM.  You can avoid this bug
	 * 	by ensuring the audio and video audio share the same sampleRate.</li>
	 * </ul>
	 * @class WebAudioPlugin
	 * @extends AbstractPlugin
	 * @constructor
	 * @since 0.4.0
	 */
	function WebAudioPlugin() {
		this.AbstractPlugin_constructor();


// Private Properties
		/**
		 * Value to set panning model to equal power for WebAudioSoundInstance.  Can be "equalpower" or 0 depending on browser implementation.
		 * @property _panningModel
		 * @type {Number / String}
		 * @protected
		 */
		this._panningModel = s._panningModel;;

		/**
		 * The internal master volume value of the plugin.
		 * @property _volume
		 * @type {Number}
		 * @default 1
		 * @protected
		 */
		this._volume = 1;

		/**
		 * The web audio context, which WebAudio uses to play audio. All nodes that interact with the WebAudioPlugin
		 * need to be created within this context.
		 * @property context
		 * @type {AudioContext}
		 */
		this.context = s.context;

		/**
		 * A DynamicsCompressorNode, which is used to improve sound quality and prevent audio distortion.
		 * It is connected to <code>context.destination</code>.
		 *
		 * Can be accessed by advanced users through createjs.Sound.activePlugin.dynamicsCompressorNode.
		 * @property dynamicsCompressorNode
		 * @type {AudioNode}
		 */
		this.dynamicsCompressorNode = this.context.createDynamicsCompressor();
		this.dynamicsCompressorNode.connect(this.context.destination);

		/**
		 * A GainNode for controlling master volume. It is connected to {{#crossLink "WebAudioPlugin/dynamicsCompressorNode:property"}}{{/crossLink}}.
		 *
		 * Can be accessed by advanced users through createjs.Sound.activePlugin.gainNode.
		 * @property gainNode
		 * @type {AudioGainNode}
		 */
		this.gainNode = this.context.createGain();
		this.gainNode.connect(this.dynamicsCompressorNode);
		createjs.WebAudioSoundInstance.destinationNode = this.gainNode;

		this._capabilities = s._capabilities;

		this._loaderClass = createjs.WebAudioLoader;
		this._soundInstanceClass = createjs.WebAudioSoundInstance;

		this._addPropsToClasses();
	}
	var p = createjs.extend(WebAudioPlugin, createjs.AbstractPlugin);


// Static Properties
	var s = WebAudioPlugin;
	/**
	 * The capabilities of the plugin. This is generated via the {{#crossLink "WebAudioPlugin/_generateCapabilities:method"}}{{/crossLink}}
	 * method and is used internally.
	 * @property _capabilities
	 * @type {Object}
	 * @default null
	 * @protected
	 * @static
	 */
	s._capabilities = null;

	/**
	 * Value to set panning model to equal power for WebAudioSoundInstance.  Can be "equalpower" or 0 depending on browser implementation.
	 * @property _panningModel
	 * @type {Number / String}
	 * @protected
	 * @static
	 */
	s._panningModel = "equalpower";

	/**
	 * The web audio context, which WebAudio uses to play audio. All nodes that interact with the WebAudioPlugin
	 * need to be created within this context.
	 *
	 * Advanced users can set this to an existing context, but <b>must</b> do so before they call
	 * {{#crossLink "Sound/registerPlugins"}}{{/crossLink}} or {{#crossLink "Sound/initializeDefaultPlugins"}}{{/crossLink}}.
	 *
	 * @property context
	 * @type {AudioContext}
	 * @static
	 */
	s.context = null;


// Static Public Methods
	/**
	 * Determine if the plugin can be used in the current browser/OS.
	 * @method isSupported
	 * @return {Boolean} If the plugin can be initialized.
	 * @static
	 */
	s.isSupported = function () {
		// check if this is some kind of mobile device, Web Audio works with local protocol under PhoneGap and it is unlikely someone is trying to run a local file
		var isMobilePhoneGap = createjs.BrowserDetect.isIOS || createjs.BrowserDetect.isAndroid || createjs.BrowserDetect.isBlackberry;
		// OJR isMobile may be redundant with _isFileXHRSupported available.  Consider removing.
		if (location.protocol == "file:" && !isMobilePhoneGap && !this._isFileXHRSupported()) { return false; }  // Web Audio requires XHR, which is not usually available locally
		s._generateCapabilities();
		if (s.context == null) {return false;}
		return true;
	};

	/**
	 * Plays an empty sound in the web audio context.  This is used to enable web audio on iOS devices, as they
	 * require the first sound to be played inside of a user initiated event (touch/click).  This is called when
	 * {{#crossLink "WebAudioPlugin"}}{{/crossLink}} is initialized (by Sound {{#crossLink "Sound/initializeDefaultPlugins"}}{{/crossLink}}
	 * for example).
	 *
	 * <h4>Example</h4>
	 *     function handleTouch(event) {
	 *         createjs.WebAudioPlugin.playEmptySound();
	 *     }
	 *
	 * @method playEmptySound
	 * @static
	 * @since 0.4.1
	 */
	s.playEmptySound = function() {
		var source = s.context.createBufferSource();
		source.buffer = s.context.createBuffer(1, 1, 22050);
		source.connect(s.context.destination);
		source.start(0, 0, 0);
	};


// Static Private Methods
	/**
	 * Determine if XHR is supported, which is necessary for web audio.
	 * @method _isFileXHRSupported
	 * @return {Boolean} If XHR is supported.
	 * @since 0.4.2
	 * @protected
	 * @static
	 */
	s._isFileXHRSupported = function() {
		// it's much easier to detect when something goes wrong, so let's start optimistically
		var supported = true;

		var xhr = new XMLHttpRequest();
		try {
			xhr.open("GET", "WebAudioPluginTest.fail", false); // loading non-existant file triggers 404 only if it could load (synchronous call)
		} catch (error) {
			// catch errors in cases where the onerror is passed by
			supported = false;
			return supported;
		}
		xhr.onerror = function() { supported = false; }; // cause irrelevant
		// with security turned off, we can get empty success results, which is actually a failed read (status code 0?)
		xhr.onload = function() { supported = this.status == 404 || (this.status == 200 || (this.status == 0 && this.response != "")); };
		try {
			xhr.send();
		} catch (error) {
			// catch errors in cases where the onerror is passed by
			supported = false;
		}

		return supported;
	};

	/**
	 * Determine the capabilities of the plugin. Used internally. Please see the Sound API {{#crossLink "Sound/getCapabilities"}}{{/crossLink}}
	 * method for an overview of plugin capabilities.
	 * @method _generateCapabilities
	 * @static
	 * @protected
	 */
	s._generateCapabilities = function () {
		if (s._capabilities != null) {return;}
		// Web Audio can be in any formats supported by the audio element, from http://www.w3.org/TR/webaudio/#AudioContext-section
		var t = document.createElement("audio");
		if (t.canPlayType == null) {return null;}

		if (s.context == null) {
			if (window.AudioContext) {
				s.context = new AudioContext();
			} else if (window.webkitAudioContext) {
				s.context = new webkitAudioContext();
			} else {
				return null;
			}
		}

		s._compatibilitySetUp();

		// playing this inside of a touch event will enable audio on iOS, which starts muted
		s.playEmptySound();

		s._capabilities = {
			panning:true,
			volume:true,
			tracks:-1
		};

		// determine which extensions our browser supports for this plugin by iterating through Sound.SUPPORTED_EXTENSIONS
		var supportedExtensions = createjs.Sound.SUPPORTED_EXTENSIONS;
		var extensionMap = createjs.Sound.EXTENSION_MAP;
		for (var i = 0, l = supportedExtensions.length; i < l; i++) {
			var ext = supportedExtensions[i];
			var playType = extensionMap[ext] || ext;
			s._capabilities[ext] = (t.canPlayType("audio/" + ext) != "no" && t.canPlayType("audio/" + ext) != "") || (t.canPlayType("audio/" + playType) != "no" && t.canPlayType("audio/" + playType) != "");
		}  // OJR another way to do this might be canPlayType:"m4a", codex: mp4

		// 0=no output, 1=mono, 2=stereo, 4=surround, 6=5.1 surround.
		// See http://www.w3.org/TR/webaudio/#AudioChannelSplitter for more details on channels.
		if (s.context.destination.numberOfChannels < 2) {
			s._capabilities.panning = false;
		}
	};

	/**
	 * Set up compatibility if only deprecated web audio calls are supported.
	 * See http://www.w3.org/TR/webaudio/#DeprecationNotes
	 * Needed so we can support new browsers that don't support deprecated calls (Firefox) as well as old browsers that
	 * don't support new calls.
	 *
	 * @method _compatibilitySetUp
	 * @static
	 * @protected
	 * @since 0.4.2
	 */
	s._compatibilitySetUp = function() {
		s._panningModel = "equalpower";
		//assume that if one new call is supported, they all are
		if (s.context.createGain) { return; }

		// simple name change, functionality the same
		s.context.createGain = s.context.createGainNode;

		// source node, add to prototype
		var audioNode = s.context.createBufferSource();
		audioNode.__proto__.start = audioNode.__proto__.noteGrainOn;	// note that noteGrainOn requires all 3 parameters
		audioNode.__proto__.stop = audioNode.__proto__.noteOff;

		// panningModel
		s._panningModel = 0;
	};


// Public Methods
	p.toString = function () {
		return "[WebAudioPlugin]";
	};


// Private Methods
	/**
	 * Set up needed properties on supported classes WebAudioSoundInstance and WebAudioLoader.
	 * @method _addPropsToClasses
	 * @static
	 * @protected
	 * @since 0.6.0
	 */
	p._addPropsToClasses = function() {
		var c = this._soundInstanceClass;
		c.context = this.context;
		c.destinationNode = this.gainNode;
		c._panningModel = this._panningModel;

		this._loaderClass.context = this.context;
	};


	/**
	 * Set the gain value for master audio. Should not be called externally.
	 * @method _updateVolume
	 * @protected
	 */
	p._updateVolume = function () {
		var newVolume = createjs.Sound._masterMute ? 0 : this._volume;
		if (newVolume != this.gainNode.gain.value) {
			this.gainNode.gain.value = newVolume;
		}
	};

	createjs.WebAudioPlugin = createjs.promote(WebAudioPlugin, "AbstractPlugin");
}());

//##############################################################################
// HTMLAudioTagPool.js
//##############################################################################

this.createjs = this.createjs || {};

//TODO verify that tags no longer need to be precreated (mac and pc)
//TODO modify this now that tags do not need to be precreated
(function () {
	"use strict";

	/**
	 * The TagPool is an object pool for HTMLAudio tag instances. In Chrome, we have to pre-create the number of HTML
	 * audio tag instances that we are going to play before we load the data, otherwise the audio stalls.
	 * (Note: This seems to be a bug in Chrome)
	 * @class HTMLAudioTagPool
	 * @param {String} src The source of the channel.
	 * @protected
	 */
	function TagPool(src) {


//Public Properties
		/**
		 * The source of the tag pool.
		 * #property src
		 * @type {String}
		 * @protected
		 */
		this.src = src;

		/**
		 * The total number of HTMLAudio tags in this pool. This is the maximum number of instance of a certain sound
		 * that can play at one time.
		 * #property length
		 * @type {Number}
		 * @default 0
		 * @protected
		 */
		this.length = 0;

		/**
		 * The number of unused HTMLAudio tags.
		 * #property available
		 * @type {Number}
		 * @default 0
		 * @protected
		 */
		this.available = 0;

		/**
		 * A list of all available tags in the pool.
		 * #property tags
		 * @type {Array}
		 * @protected
		 */
		this.tags = [];

		/**
		 * The duration property of all audio tags, converted to milliseconds, which originally is only available on the
		 * last tag in the tags array because that is the one that is loaded.
		 * #property
		 * @type {Number}
		 * @protected
		 */
		this.duration = 0;
	};

	var p = TagPool.prototype;
	p.constructor = TagPool;
	var s = TagPool;


// Static Properties
	/**
	 * A hash lookup of each sound channel, indexed by the audio source.
	 * #property tags
	 * @static
	 * @protected
	 */
	s.tags = {};


// Static Methods
	/**
	 * Get a tag pool. If the pool doesn't exist, create it.
	 * #method get
	 * @param {String} src The source file used by the audio tag.
	 * @static
	 * @protected
	 */
	s.get = function (src) {
		var channel = s.tags[src];
		if (channel == null) {
			channel = s.tags[src] = new TagPool(src);
		}
		return channel;
	};

	/**
	 * Delete a TagPool and all related tags. Note that if the TagPool does not exist, this will fail.
	 * #method remove
	 * @param {String} src The source for the tag
	 * @return {Boolean} If the TagPool was deleted.
	 * @static
	 */
	s.remove = function (src) {
		var channel = s.tags[src];
		if (channel == null) {return false;}
		channel.removeAll();
		delete(s.tags[src]);
		return true;
	};

	/**
	 * Get a tag instance. This is a shortcut method.
	 * #method getInstance
	 * @param {String} src The source file used by the audio tag.
	 * @static
	 * @protected
	 */
	s.getInstance = function (src) {
		var channel = s.tags[src];
		if (channel == null) {return null;}
		return channel.get();
	};

	/**
	 * Return a tag instance. This is a shortcut method.
	 * #method setInstance
	 * @param {String} src The source file used by the audio tag.
	 * @param {HTMLElement} tag Audio tag to set.
	 * @static
	 * @protected
	 */
	s.setInstance = function (src, tag) {
		var channel = s.tags[src];
		if (channel == null) {return null;}
		return channel.set(tag);
	};

	/**
	 * Gets the duration of the src audio in milliseconds
	 * #method getDuration
	 * @param {String} src The source file used by the audio tag.
	 * @return {Number} Duration of src in milliseconds
	 */
	s.getDuration= function (src) {
		var channel = s.tags[src];
		if (channel == null) {return 0;}
		return channel.getDuration();
	};


// Public Methods
	/**
	 * Add an HTMLAudio tag into the pool.
	 * #method add
	 * @param {HTMLAudioElement} tag A tag to be used for playback.
	 */
	p.add = function (tag) {
		this.tags.push(tag);
		this.length++;
		this.available++;
	};

	/**
	 * Remove all tags from the channel.  Usually in response to a delete call.
	 * #method removeAll
	 */
	p.removeAll = function () {
		var tag;
		while(this.length--) {
			tag = this.tags[this.length];
			if(tag.parentNode) {
				tag.parentNode.removeChild(tag);
			}
			delete(this.tags[this.length]);	// NOTE that the audio playback is already stopped by this point
		}
		this.src = null;
		this.tags.length = 0;
	};

	/**
	 * Get an HTMLAudioElement for immediate playback. This takes it out of the pool.
	 * #method get
	 * @return {HTMLAudioElement} An HTML audio tag.
	 */
	p.get = function () {
		if (this.tags.length == 0) {return null;}
		this.available = this.tags.length;
		var tag = this.tags.pop();
		if (tag.parentNode == null) {document.body.appendChild(tag);}
		return tag;
	};

	/**
	 * Put an HTMLAudioElement back in the pool for use.
	 * #method set
	 * @param {HTMLAudioElement} tag HTML audio tag
	 */
	p.set = function (tag) {
		var index = createjs.indexOf(this.tags, tag);
		if (index == -1) {this.tags.push(tag);}
		this.available = this.tags.length;
	};

	/**
	 * Gets the duration for the src audio and on first call stores it to this.duration
	 * #method getDuration
	 * @return {Number} Duration of the src in milliseconds
	 */
	p.getDuration = function () {
		// this will work because this will be only be run the first time a sound instance is created and before any tags are taken from the pool
		if (!this.duration) {this.duration = this.tags[this.tags.length - 1].duration * 1000;}
		return this.duration;
	};

	p.toString = function () {
		return "[HTMLAudioTagPool]";
	};

	createjs.HTMLAudioTagPool = TagPool;
}());

//##############################################################################
// HTMLAudioSoundInstance.js
//##############################################################################

this.createjs = this.createjs || {};

(function () {
	"use strict";

	/**
	 * HTMLAudioSoundInstance extends the base api of {{#crossLink "AbstractSoundInstance"}}{{/crossLink}} and is used by
	 * {{#crossLink "HTMLAudioPlugin"}}{{/crossLink}}.
	 *
	 * @param {String} src The path to and file name of the sound.
	 * @param {Number} startTime Audio sprite property used to apply an offset, in milliseconds.
	 * @param {Number} duration Audio sprite property used to set the time the clip plays for, in milliseconds.
	 * @param {Object} playbackResource Any resource needed by plugin to support audio playback.
	 * @class HTMLAudioSoundInstance
	 * @extends AbstractSoundInstance
	 * @constructor
	 */
	function HTMLAudioSoundInstance(src, startTime, duration, playbackResource) {
		this.AbstractSoundInstance_constructor(src, startTime, duration, playbackResource);


// Private Properties
		this._audioSpriteStopTime = null;
		this._delayTimeoutId = null;

		// Proxies, make removing listeners easier.
		this._endedHandler = createjs.proxy(this._handleSoundComplete, this);
		this._readyHandler = createjs.proxy(this._handleTagReady, this);
		this._stalledHandler = createjs.proxy(this.playFailed, this);
		this._audioSpriteEndHandler = createjs.proxy(this._handleAudioSpriteLoop, this);
		this._loopHandler = createjs.proxy(this._handleSoundComplete, this);

		if (duration) {
			this._audioSpriteStopTime = (startTime + duration) * 0.001;
		} else {
			this._duration = createjs.HTMLAudioTagPool.getDuration(this.src);
		}
	}
	var p = createjs.extend(HTMLAudioSoundInstance, createjs.AbstractSoundInstance);


// Public Methods
	/**
	 * Called by {{#crossLink "Sound"}}{{/crossLink}} when plugin does not handle master volume.
	 * undoc'd because it is not meant to be used outside of Sound
	 * #method setMasterVolume
	 * @param value
	 */
	p.setMasterVolume = function (value) {
		this._updateVolume();
	};

	/**
	 * Called by {{#crossLink "Sound"}}{{/crossLink}} when plugin does not handle master mute.
	 * undoc'd because it is not meant to be used outside of Sound
	 * #method setMasterMute
	 * @param value
	 */
	p.setMasterMute = function (isMuted) {
		this._updateVolume();
	};

	p.toString = function () {
		return "[HTMLAudioSoundInstance]";
	};

//Private Methods
	p._removeLooping = function() {
		if(this._playbackResource == null) {return;}
		this._playbackResource.loop = false;
		this._playbackResource.removeEventListener(createjs.HTMLAudioPlugin._AUDIO_SEEKED, this._loopHandler, false);
	};

	p._addLooping = function() {
		if(this._playbackResource == null  || this._audioSpriteStopTime) {return;}
		this._playbackResource.addEventListener(createjs.HTMLAudioPlugin._AUDIO_SEEKED, this._loopHandler, false);
		this._playbackResource.loop = true;
	};

	p._handleCleanUp = function () {
		var tag = this._playbackResource;
		if (tag != null) {
			tag.pause();
			tag.loop = false;
			tag.removeEventListener(createjs.HTMLAudioPlugin._AUDIO_ENDED, this._endedHandler, false);
			tag.removeEventListener(createjs.HTMLAudioPlugin._AUDIO_READY, this._readyHandler, false);
			tag.removeEventListener(createjs.HTMLAudioPlugin._AUDIO_STALLED, this._stalledHandler, false);
			tag.removeEventListener(createjs.HTMLAudioPlugin._AUDIO_SEEKED, this._loopHandler, false);
			tag.removeEventListener(createjs.HTMLAudioPlugin._TIME_UPDATE, this._audioSpriteEndHandler, false);

			try {
				tag.currentTime = this._startTime;
			} catch (e) {
			} // Reset Position
			createjs.HTMLAudioTagPool.setInstance(this.src, tag);
			this._playbackResource = null;
		}
	};

	p._beginPlaying = function (offset, loop, volume, pan) {
		this._playbackResource = createjs.HTMLAudioTagPool.getInstance(this.src);
		return this.AbstractSoundInstance__beginPlaying(offset, loop, volume, pan);
	};

	p._handleSoundReady = function (event) {
		if (this._playbackResource.readyState !== 4) {
			var tag = this._playbackResource;
			tag.addEventListener(createjs.HTMLAudioPlugin._AUDIO_READY, this._readyHandler, false);
			tag.addEventListener(createjs.HTMLAudioPlugin._AUDIO_STALLED, this._stalledHandler, false);
			tag.preload = "auto"; // This is necessary for Firefox, as it won't ever "load" until this is set.
			tag.load();
			return;
		}

		this._updateVolume();
		this._playbackResource.currentTime = (this._startTime + this._position) * 0.001;
		if (this._audioSpriteStopTime) {
			this._playbackResource.addEventListener(createjs.HTMLAudioPlugin._TIME_UPDATE, this._audioSpriteEndHandler, false);
		} else {
			this._playbackResource.addEventListener(createjs.HTMLAudioPlugin._AUDIO_ENDED, this._endedHandler, false);
			if(this._loop != 0) {
				this._playbackResource.addEventListener(createjs.HTMLAudioPlugin._AUDIO_SEEKED, this._loopHandler, false);
				this._playbackResource.loop = true;
			}
		}

		this._playbackResource.play();
	};

	/**
	 * Used to handle when a tag is not ready for immediate playback when it is returned from the HTMLAudioTagPool.
	 * @method _handleTagReady
	 * @param event
	 * @protected
	 */
	p._handleTagReady = function (event) {
		this._playbackResource.removeEventListener(createjs.HTMLAudioPlugin._AUDIO_READY, this._readyHandler, false);
		this._playbackResource.removeEventListener(createjs.HTMLAudioPlugin._AUDIO_STALLED, this._stalledHandler, false);

		this._handleSoundReady();
	};

	p._pause = function () {
		this._playbackResource.pause();
	};

	p._resume = function () {
		this._playbackResource.play();
	};

	p._updateVolume = function () {
		if (this._playbackResource != null) {
			var newVolume = (this._muted || createjs.Sound._masterMute) ? 0 : this._volume * createjs.Sound._masterVolume;
			if (newVolume != this._playbackResource.volume) {this._playbackResource.volume = newVolume;}
		}
	};

	p._calculateCurrentPosition = function() {
		return (this._playbackResource.currentTime * 1000) - this._startTime;
	};

	p._updatePosition = function() {
		this._playbackResource.removeEventListener(createjs.HTMLAudioPlugin._AUDIO_SEEKED, this._loopHandler, false);
		this._playbackResource.addEventListener(createjs.HTMLAudioPlugin._AUDIO_SEEKED, this._handleSetPositionSeek, false);
		try {
			this._playbackResource.currentTime = (this._position + this._startTime) * 0.001;
		} catch (error) { // Out of range
			this._handleSetPositionSeek(null);
		}
	};

	/**
	 * Used to enable setting position, as we need to wait for that seek to be done before we add back our loop handling seek listener
	 * @method _handleSetPositionSeek
	 * @param event
	 * @protected
	 */
	p._handleSetPositionSeek = function(event) {
		if (this._playbackResource == null) { return; }
		this._playbackResource.removeEventListener(createjs.HTMLAudioPlugin._AUDIO_SEEKED, this._handleSetPositionSeek, false);
		this._playbackResource.addEventListener(createjs.HTMLAudioPlugin._AUDIO_SEEKED, this._loopHandler, false);
	};

	/**
	 * Timer used to loop audio sprites.
	 * NOTE because of the inaccuracies in the timeupdate event (15 - 250ms) and in setting the tag to the desired timed
	 * (up to 300ms), it is strongly recommended not to loop audio sprites with HTML Audio if smooth looping is desired
	 *
	 * @method _handleAudioSpriteLoop
	 * @param event
	 * @private
	 */
	p._handleAudioSpriteLoop = function (event) {
		if(this._playbackResource.currentTime <= this._audioSpriteStopTime) {return;}
		this._playbackResource.pause();
		if(this._loop == 0) {
			this._handleSoundComplete(null);
		} else {
			this._position = 0;
			this._loop--;
			this._playbackResource.currentTime = this._startTime * 0.001;
			if(!this._paused) {this._playbackResource.play();}
			this._sendEvent("loop");
		}
	};

	// NOTE with this approach audio will loop as reliably as the browser allows
	// but we could end up sending the loop event after next loop playback begins
	p._handleLoop = function (event) {
		if(this._loop == 0) {
			this._playbackResource.loop = false;
			this._playbackResource.removeEventListener(createjs.HTMLAudioPlugin._AUDIO_SEEKED, this._loopHandler, false);
		}
	};

	p._updateDuration = function () {
		this._audioSpriteStopTime = (startTime + duration) * 0.001;

		if(this.playState == createjs.Sound.PLAY_SUCCEEDED) {
			this._playbackResource.removeEventListener(createjs.HTMLAudioPlugin._AUDIO_ENDED, this._endedHandler, false);
			this._playbackResource.addEventListener(createjs.HTMLAudioPlugin._TIME_UPDATE, this._audioSpriteEndHandler, false);
		}
	};

	/*	This should never change
	p._setDurationFromSource = function () {
		this._duration = createjs.HTMLAudioTagPool.getDuration(this.src);
	};
	*/

	createjs.HTMLAudioSoundInstance = createjs.promote(HTMLAudioSoundInstance, "AbstractSoundInstance");
}());

//##############################################################################
// HTMLAudioPlugin.js
//##############################################################################

this.createjs = this.createjs || {};

(function () {

	"use strict";

	/**
	 * Play sounds using HTML &lt;audio&gt; tags in the browser. This plugin is the second priority plugin installed
	 * by default, after the {{#crossLink "WebAudioPlugin"}}{{/crossLink}}.  For older browsers that do not support html
	 * audio, include and install the {{#crossLink "FlashAudioPlugin"}}{{/crossLink}}.
	 *
	 * <h4>Known Browser and OS issues for HTML Audio</h4>
	 * <b>All browsers</b><br />
	 * Testing has shown in all browsers there is a limit to how many audio tag instances you are allowed.  If you exceed
	 * this limit, you can expect to see unpredictable results.  This will be seen as soon as you register sounds, as
	 * tags are precreated to allow Chrome to load them.  Please use {{#crossLink "Sound.MAX_INSTANCES"}}{{/crossLink}} as
	 * a guide to how many total audio tags you can safely use in all browsers.
	 *
     * <b>IE html limitations</b><br />
     * <ul><li>There is a delay in applying volume changes to tags that occurs once playback is started. So if you have
     * muted all sounds, they will all play during this delay until the mute applies internally. This happens regardless of
     * when or how you apply the volume change, as the tag seems to need to play to apply it.</li>
     * <li>MP3 encoding will not always work for audio tags if it's not default.  We've found default encoding with
     * 64kbps works.</li>
	 * <li>Occasionally very short samples will get cut off.</li>
	 * <li>There is a limit to how many audio tags you can load and play at once, which appears to be determined by
	 * hardware and browser settings.  See {{#crossLink "HTMLAudioPlugin.MAX_INSTANCES"}}{{/crossLink}} for a safe estimate.
	 * Note that audio sprites can be used as a solution to this issue.</li></ul>
	 *
	 * <b>Safari limitations</b><br />
	 * <ul><li>Safari requires Quicktime to be installed for audio playback.</li></ul>
	 *
	 * <b>iOS 6 limitations</b><br />
	 * <ul><li>Note it is recommended to use {{#crossLink "WebAudioPlugin"}}{{/crossLink}} for iOS (6+)</li>
	 * 		<li>HTML Audio is disabled by default because</li>
	 * 		<li>can only have one &lt;audio&gt; tag</li>
	 * 		<li>can not preload or autoplay the audio</li>
	 * 		<li>can not cache the audio</li>
	 * 		<li>can not play the audio except inside a user initiated event.</li>
	 * 		<li>audio sprites can be used to mitigate some of these issues and are strongly recommended on iOS</li>
	 * </ul>
	 *
	 * <b>Android Native Browser limitations</b><br />
	 * <ul><li>We have no control over audio volume. Only the user can set volume on their device.</li>
	 *      <li>We can only play audio inside a user event (touch/click).  This currently means you cannot loop sound or use a delay.</li></ul>
	 * <b> Android Chrome 26.0.1410.58 specific limitations</b><br />
	 * <ul> <li>Can only play 1 sound at a time.</li>
	 *      <li>Sound is not cached.</li>
	 *      <li>Sound can only be loaded in a user initiated touch/click event.</li>
	 *      <li>There is a delay before a sound is played, presumably while the src is loaded.</li>
	 * </ul>
	 *
	 * See {{#crossLink "Sound"}}{{/crossLink}} for general notes on known issues.
	 *
	 * @class HTMLAudioPlugin
	 * @extends AbstractPlugin
	 * @constructor
	 */
	function HTMLAudioPlugin() {
		this.AbstractPlugin_constructor();


	// Public Properties
		/**
		 * The default number of instances to allow.  Used by {{#crossLink "Sound"}}{{/crossLink}} when a source
		 * is registered using the {{#crossLink "Sound/register"}}{{/crossLink}} method.  This is only used if
		 * a value is not provided.
		 *
		 * <b>NOTE this property only exists as a limitation of HTML audio.</b>
		 * @property defaultNumChannels
		 * @type {Number}
		 * @default 2
		 * @since 0.4.0
		 */
		this.defaultNumChannels = 2;

		this._capabilities = s._capabilities;

		this._loaderClass = createjs.SoundLoader;
		this._soundInstanceClass = createjs.HTMLAudioSoundInstance;
	}

	var p = createjs.extend(HTMLAudioPlugin, createjs.AbstractPlugin);
	var s = HTMLAudioPlugin;


// Static Properties
	/**
	 * The maximum number of instances that can be loaded and played. This is a browser limitation, primarily limited to IE9.
	 * The actual number varies from browser to browser (and is largely hardware dependant), but this is a safe estimate.
	 * Audio sprites work around this limitation.
	 * @property MAX_INSTANCES
	 * @type {Number}
	 * @default 30
	 * @static
	 */
	s.MAX_INSTANCES = 30;

	/**
	 * Event constant for the "canPlayThrough" event for cleaner code.
	 * @property _AUDIO_READY
	 * @type {String}
	 * @default canplaythrough
	 * @static
	 * @protected
	 */
	s._AUDIO_READY = "canplaythrough";

	/**
	 * Event constant for the "ended" event for cleaner code.
	 * @property _AUDIO_ENDED
	 * @type {String}
	 * @default ended
	 * @static
	 * @protected
	 */
	s._AUDIO_ENDED = "ended";

	/**
	 * Event constant for the "seeked" event for cleaner code.  We utilize this event for maintaining loop events.
	 * @property _AUDIO_SEEKED
	 * @type {String}
	 * @default seeked
	 * @static
	 * @protected
	 */
	s._AUDIO_SEEKED = "seeked";

	/**
	 * Event constant for the "stalled" event for cleaner code.
	 * @property _AUDIO_STALLED
	 * @type {String}
	 * @default stalled
	 * @static
	 * @protected
	 */
	s._AUDIO_STALLED = "stalled";

	/**
	 * Event constant for the "timeupdate" event for cleaner code.  Utilized for looping audio sprites.
	 * This event callsback ever 15 to 250ms and can be dropped by the browser for performance.
	 * @property _TIME_UPDATE
	 * @type {String}
	 * @default timeupdate
	 * @static
	 * @protected
	 */
	s._TIME_UPDATE = "timeupdate";

	/**
	 * The capabilities of the plugin. This is generated via the {{#crossLink "HTMLAudioPlugin/_generateCapabilities"}}{{/crossLink}}
	 * method. Please see the Sound {{#crossLink "Sound/getCapabilities"}}{{/crossLink}} method for an overview of all
	 * of the available properties.
	 * @property _capabilities
	 * @type {Object}
	 * @protected
	 * @static
	 */
	s._capabilities = null;

	/**
	 * Deprecated now that we have audio sprite support.  Audio sprites are strongly recommend on iOS for the following reasons:
	 * <li>it can only have one &lt;audio&gt; tag</li>
	 * <li>can not preload or autoplay the audio</li>
	 * <li>can not cache the audio</li>
	 * <li>can not play the audio except inside a user initiated event</li>
	 *
	 * @property enableIOS
	 * @type {Boolean}
	 * @default false
	 * @deprecated
	 */
	s.enableIOS = false;


// Static Methods
	/**
	 * Determine if the plugin can be used in the current browser/OS. Note that HTML audio is available in most modern
	 * browsers, but is disabled in iOS because of its limitations.
	 * @method isSupported
	 * @return {Boolean} If the plugin can be initialized.
	 * @static
	 */
	s.isSupported = function () {
		s._generateCapabilities();
		if (s._capabilities == null) {return false;}
		return true;
	};

	/**
	 * Determine the capabilities of the plugin. Used internally. Please see the Sound API {{#crossLink "Sound/getCapabilities"}}{{/crossLink}}
	 * method for an overview of plugin capabilities.
	 * @method _generateCapabilities
	 * @static
	 * @protected
	 */
	s._generateCapabilities = function () {
		if (s._capabilities != null) {return;}
		var t = document.createElement("audio");
		if (t.canPlayType == null) {return null;}

		s._capabilities = {
			panning:true,
			volume:true,
			tracks:-1
		};

		// determine which extensions our browser supports for this plugin by iterating through Sound.SUPPORTED_EXTENSIONS
		var supportedExtensions = createjs.Sound.SUPPORTED_EXTENSIONS;
		var extensionMap = createjs.Sound.EXTENSION_MAP;
		for (var i = 0, l = supportedExtensions.length; i < l; i++) {
			var ext = supportedExtensions[i];
			var playType = extensionMap[ext] || ext;
			s._capabilities[ext] = (t.canPlayType("audio/" + ext) != "no" && t.canPlayType("audio/" + ext) != "") || (t.canPlayType("audio/" + playType) != "no" && t.canPlayType("audio/" + playType) != "");
		}  // OJR another way to do this might be canPlayType:"m4a", codex: mp4
	};


// public methods
	p.register = function (src, instances) {
		var channel = createjs.HTMLAudioTagPool.get(src);
		var tag = null;
		for (var i = 0; i < instances; i++) {
			tag = this._createTag(src);
			channel.add(tag);
		}

		var loader = this.AbstractPlugin_register(src, instances);
		loader.setTag(tag);

		return loader;
	};

	p.removeSound = function (src) {
		this.AbstractPlugin_removeSound(src);
		createjs.HTMLAudioTagPool.remove(src);
	};

	p.create = function (src, startTime, duration) {
		var si = this.AbstractPlugin_create(src, startTime, duration);
		si.setPlaybackResource(null);
		return si;
	};

	p.toString = function () {
		return "[HTMLAudioPlugin]";
	};

	// plugin does not support these
	p.setVolume = p.getVolume = p.setMute = null;


// private methods
	/**
	 * Create an HTML audio tag.
	 * @method _createTag
	 * @param {String} src The source file to set for the audio tag.
	 * @return {HTMLElement} Returns an HTML audio tag.
	 * @protected
	 */
	// TODO move this to tagpool when it changes to be a standard object pool
	p._createTag = function (src) {
		var tag = document.createElement("audio");
		tag.autoplay = false;
		tag.preload = "none";
		//LM: Firefox fails when this the preload="none" for other tags, but it needs to be "none" to ensure PreloadJS works.
		tag.src = src;
		return tag;
	};

	createjs.HTMLAudioPlugin = createjs.promote(HTMLAudioPlugin, "AbstractPlugin");
}());