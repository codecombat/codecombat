/**
 * @module SoundJS
 */
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
	s.version = /*version*/"NEXT"; // injected by build process

	/**
	 * The build date for this release in UTC format.
	 * @property buildDate
	 * @type String
	 * @static
	 **/
	s.buildDate = /*date*/"Wed, 27 Nov 2013 19:49:18 GMT"; // injected by build process

})();
/*
* EventDispatcher
* Visit http://createjs.com/ for documentation, updates and examples.
*
* Copyright (c) 2010 gskinner.com, inc.
*
* Permission is hereby granted, free of charge, to any person
* obtaining a copy of this software and associated documentation
* files (the "Software"), to deal in the Software without
* restriction, including without limitation the rights to use,
* copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the
* Software is furnished to do so, subject to the following
* conditions:
*
* The above copyright notice and this permission notice shall be
* included in all copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
* EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
* OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
* NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
* HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
* WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
* FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
* OTHER DEALINGS IN THE SOFTWARE.
*/

/**
 * @module CreateJS
 */

// namespace:
this.createjs = this.createjs||{};

(function() {
	"use strict";

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
var EventDispatcher = function() {
/*	this.initialize(); */ // not needed.
};
var p = EventDispatcher.prototype;


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
	};
	
// constructor:

// private properties:
	/**
	 * @protected
	 * @property _listeners
	 * @type Object
	 **/
	p._listeners = null;

	/**
	 * @protected
	 * @property _captureListeners
	 * @type Object
	 **/
	p._captureListeners = null;

// constructor:
	/**
	 * Initialization method.
	 * @method initialize
	 * @protected
	 **/
	p.initialize = function() {};

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
	 * @param {Object} [target] The object to use as the target property of the event object. This will default to the
	 * dispatching object. <b>This parameter is deprecated and will be removed.</b>
	 * @return {Boolean} Returns the value of eventObj.defaultPrevented.
	 **/
	p.dispatchEvent = function(eventObj, target) {
		if (typeof eventObj == "string") {
			// won't bubble, so skip everything if there's no listeners:
			var listeners = this._listeners;
			if (!listeners || !listeners[eventObj]) { return false; }
			eventObj = new createjs.Event(eventObj);
		}
		// TODO: deprecated. Target param is deprecated, only use case is MouseEvent/mousemove, remove.
		eventObj.target = target||this;

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
	 * Indicates whether there is at least one listener for the specified event type and `useCapture` value.
	 * @method hasEventListener
	 * @param {String} type The string type of the event.
	 * @return {Boolean} Returns true if there is at least one listener for the specified event.
	 **/
	p.hasEventListener = function(type) {
		var listeners = this._listeners, captureListeners = this._captureListeners;
		return !!((listeners && listeners[type]) || (captureListeners && captureListeners[type]));
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
			eventObj.currentTarget = this;
			eventObj.eventPhase = eventPhase;
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
/*
* Event
* Visit http://createjs.com/ for documentation, updates and examples.
*
* Copyright (c) 2010 gskinner.com, inc.
*
* Permission is hereby granted, free of charge, to any person
* obtaining a copy of this software and associated documentation
* files (the "Software"), to deal in the Software without
* restriction, including without limitation the rights to use,
* copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the
* Software is furnished to do so, subject to the following
* conditions:
*
* The above copyright notice and this permission notice shall be
* included in all copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
* EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
* OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
* NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
* HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
* WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
* FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
* OTHER DEALINGS IN THE SOFTWARE.
*/

/**
 * A collection of Classes that are shared across all the CreateJS libraries.  The classes are included in the minified
 * files of each library and are available on the createsjs namespace directly.
 *
 * <h4>Example</h4>
 *      myObject.addEventListener("change", createjs.proxy(myMethod, scope));
 *
 * @module CreateJS
 * @main CreateJS
 */

// namespace:
this.createjs = this.createjs||{};

(function() {
	"use strict";

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
var Event = function(type, bubbles, cancelable) {
  this.initialize(type, bubbles, cancelable);
};
var p = Event.prototype;

// events:

// public properties:

	/**
	 * The type of event.
	 * @property type
	 * @type String
	 **/
	p.type = null;

	/**
	 * The object that generated an event.
	 * @property target
	 * @type Object
	 * @default null
	 * @readonly
	*/
	p.target = null;

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
	p.currentTarget = null;

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
	p.eventPhase = 0;

	/**
	 * Indicates whether the event will bubble through the display list.
	 * @property bubbles
	 * @type Boolean
	 * @default false
	 * @readonly
	*/
	p.bubbles = false;

	/**
	 * Indicates whether the default behaviour of this event can be cancelled via
	 * {{#crossLink "Event/preventDefault"}}{{/crossLink}}. This is set via the Event constructor.
	 * @property cancelable
	 * @type Boolean
	 * @default false
	 * @readonly
	*/
	p.cancelable = false;

	/**
	 * The epoch time at which this event was created.
	 * @property timeStamp
	 * @type Number
	 * @default 0
	 * @readonly
	*/
	p.timeStamp = 0;

	/**
	 * Indicates if {{#crossLink "Event/preventDefault"}}{{/crossLink}} has been called
	 * on this event.
	 * @property defaultPrevented
	 * @type Boolean
	 * @default false
	 * @readonly
	*/
	p.defaultPrevented = false;

	/**
	 * Indicates if {{#crossLink "Event/stopPropagation"}}{{/crossLink}} or
	 * {{#crossLink "Event/stopImmediatePropagation"}}{{/crossLink}} has been called on this event.
	 * @property propagationStopped
	 * @type Boolean
	 * @default false
	 * @readonly
	*/
	p.propagationStopped = false;

	/**
	 * Indicates if {{#crossLink "Event/stopImmediatePropagation"}}{{/crossLink}} has been called
	 * on this event.
	 * @property immediatePropagationStopped
	 * @type Boolean
	 * @default false
	 * @readonly
	*/
	p.immediatePropagationStopped = false;
	
	/**
	 * Indicates if {{#crossLink "Event/remove"}}{{/crossLink}} has been called on this event.
	 * @property removed
	 * @type Boolean
	 * @default false
	 * @readonly
	*/
	p.removed = false;

// constructor:
	/**
	 * Initialization method.
	 * @method initialize
	 * @param {String} type The event type.
	 * @param {Boolean} bubbles Indicates whether the event will bubble through the display list.
	 * @param {Boolean} cancelable Indicates whether the default behaviour of this event can be cancelled.
	 * @protected
	 **/
	p.initialize = function(type, bubbles, cancelable) {
		this.type = type;
		this.bubbles = bubbles;
		this.cancelable = cancelable;
		this.timeStamp = (new Date()).getTime();
	};

// public methods:

	/**
	 * Sets {{#crossLink "Event/defaultPrevented"}}{{/crossLink}} to true.
	 * Mirrors the DOM event standard.
	 * @method preventDefault
	 **/
	p.preventDefault = function() {
		this.defaultPrevented = true;
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
	 * Returns a string representation of this object.
	 * @method toString
	 * @return {String} a string representation of the instance.
	 **/
	p.toString = function() {
		return "[Event (type="+this.type+")]";
	};

createjs.Event = Event;
}());
/*
* IndexOf
* Visit http://createjs.com/ for documentation, updates and examples.
*
* Copyright (c) 2010 gskinner.com, inc.
* 
* Permission is hereby granted, free of charge, to any person
* obtaining a copy of this software and associated documentation
* files (the "Software"), to deal in the Software without
* restriction, including without limitation the rights to use,
* copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the
* Software is furnished to do so, subject to the following
* conditions:
* 
* The above copyright notice and this permission notice shall be
* included in all copies or substantial portions of the Software.
* 
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
* EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
* OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
* NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
* HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
* WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
* FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
* OTHER DEALINGS IN THE SOFTWARE.
*/

/**
  * @module CreateJS
 */

// namespace:
this.createjs = this.createjs||{};

/**
 * @class Utility Methods
 */
(function() {
	"use strict";

	/*
	 * Employs Duff's Device to make a more performant implementation of indexOf.
	 * see http://jsperf.com/duffs-indexof/2
	 * #method indexOf
	 * @param {Array} array Array to search for searchElement
	 * @param searchElement Element to search array for.
	 * @return {Number} The position of the first occurrence of a specified value searchElement in the passed in array ar.
	 * @constructor
	 */
	/* replaced with simple for loop for now, perhaps will be researched further
	createjs.indexOf = function (ar, searchElement) {
		var l = ar.length;

		var n = (l * 0.125) ^ 0;	// 0.125 == 1/8, using multiplication because it's faster in some browsers	// ^0 floors result
		for (var i = 0; i < n; i++) {
			if(searchElement === ar[i*8])   { return (i*8);}
			if(searchElement === ar[i*8+1]) { return (i*8+1);}
			if(searchElement === ar[i*8+2]) { return (i*8+2);}
			if(searchElement === ar[i*8+3]) { return (i*8+3);}
			if(searchElement === ar[i*8+4]) { return (i*8+4);}
			if(searchElement === ar[i*8+5]) { return (i*8+5);}
			if(searchElement === ar[i*8+6]) { return (i*8+6);}
			if(searchElement === ar[i*8+7]) { return (i*8+7);}
		}

		var n = l % 8;
		for (var i = 0; i < n; i++) {
			if (searchElement === ar[l-n+i]) {
				return l-n+i;
			}
		}

		return -1;
	}
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
		for (var i = 0,l=array.length; i < l; i++) {
			if (searchElement === array[i]) {
				return i;
			}
		}
		return -1;
	}

}());/*
* Proxy
* Visit http://createjs.com/ for documentation, updates and examples.
*
* Copyright (c) 2010 gskinner.com, inc.
* 
* Permission is hereby granted, free of charge, to any person
* obtaining a copy of this software and associated documentation
* files (the "Software"), to deal in the Software without
* restriction, including without limitation the rights to use,
* copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the
* Software is furnished to do so, subject to the following
* conditions:
* 
* The above copyright notice and this permission notice shall be
* included in all copies or substantial portions of the Software.
* 
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
* EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
* OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
* NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
* HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
* WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
* FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
* OTHER DEALINGS IN THE SOFTWARE.
*/

/**
 * @module CreateJS
 */

// namespace:
this.createjs = this.createjs||{};

/**
 * Various utilities that the CreateJS Suite uses. Utilities are created as separate files, and will be available on the
 * createjs namespace directly:
 *
 * <h4>Example</h4>
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

}());/*
 * Sound
 * Visit http://createjs.com/ for documentation, updates and examples.
 *
 *
 * Copyright (c) 2012 gskinner.com, inc.
 *
 * Permission is hereby granted, free of charge, to any person
 * obtaining a copy of this software and associated documentation
 * files (the "Software"), to deal in the Software without
 * restriction, including without limitation the rights to use,
 * copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following
 * conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 * OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 * HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 * WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 * OTHER DEALINGS IN THE SOFTWARE.
 */


// namespace:
this.createjs = this.createjs || {};

/**
 * The SoundJS library manages the playback of audio on the web. It works via plugins which abstract the actual audio
 * implementation, so playback is possible on any platform without specific knowledge of what mechanisms are necessary
 * to play sounds.
 *
 * To use SoundJS, use the public API on the {{#crossLink "Sound"}}{{/crossLink}} class. This API is for:
 * <ul><li>Installing audio playback Plugins</li>
 *      <li>Registering (and preloading) sounds</li>
 *      <li>Creating and playing sounds</li>
 *      <li>Master volume, mute, and stop controls for all sounds at once</li>
 * </ul>
 *
 * <b>Please note that as of version 0.4.0, the "SoundJS" object only provides version information. All APIs from
 * SoundJS are now available on the {{#crossLink "Sound"}}{{/crossLink}} class.</b>
 *
 * <b>Controlling Sounds</b><br />
 * Playing sounds creates {{#crossLink "SoundInstance"}}{{/crossLink}} instances, which can be controlled individually.
 * <ul><li>Pause, resume, seek, and stop sounds</li>
 *      <li>Control a sound's volume, mute, and pan</li>
 *      <li>Listen for events on sound instances to get notified when they finish, loop, or fail</li>
 * </ul>
 *
 * <h4>Feature Set Example</h4>
 *      createjs.Sound.alternateExtensions = ["mp3"];
 *      createjs.Sound.addEventListener("fileload", createjs.proxy(this.loadHandler, this));
 *      createjs.Sound.registerSound("path/to/mySound.ogg", "sound");
 *      function loadHandler(event) {
 *          // This is fired for each sound that is registered.
 *          var instance = createjs.Sound.play("sound");  // play using id.  Could also use full sourcepath or event.src.
 *          instance.addEventListener("complete", createjs.proxy(this.handleComplete, this));
 *          instance.volume = 0.5;
 *      }
 *
 * <h4>Browser Support</h4>
 * Audio will work in browsers which support HTMLAudioElement (<a href="http://caniuse.com/audio">http://caniuse.com/audio</a>)
 * or WebAudio (<a href="http://caniuse.com/audio-api">http://caniuse.com/audio-api</a>). A Flash fallback can be added
 * as well, which will work in any browser that supports the Flash player.
 * @module SoundJS
 * @main SoundJS
 */

(function () {

	"use strict";

	//TODO: Interface to validate plugins and throw warnings
	//TODO: Determine if methods exist on a plugin before calling  // OJR this is only an issue if something breaks or user changes something
	//TODO: Interface to validate instances and throw warnings
	//TODO: Surface errors on audio from all plugins
	//TODO: Timeouts  // OJR for?
	/**
	 * The Sound class is the public API for creating sounds, controlling the overall sound levels, and managing plugins.
	 * All Sound APIs on this class are static.
	 *
	 * <b>Registering and Preloading</b><br />
	 * Before you can play a sound, it <b>must</b> be registered. You can do this with {{#crossLink "Sound/registerSound"}}{{/crossLink}},
	 * or register multiple sounds using {{#crossLink "Sound/registerManifest"}}{{/crossLink}}. If you don't register a
	 * sound prior to attempting to play it using {{#crossLink "Sound/play"}}{{/crossLink}} or create it using {{#crossLink "Sound/createInstance"}}{{/crossLink}},
	 * the sound source will be automatically registered but playback will fail as the source will not be ready. If you use
	 * <a href="http://preloadjs.com" target="_blank">PreloadJS</a>, this is handled for you when the sound is
	 * preloaded. It is recommended to preload sounds either internally using the register functions or externally using
	 * PreloadJS so they are ready when you want to use them.
	 *
	 * <b>Playback</b><br />
	 * To play a sound once it's been registered and preloaded, use the {{#crossLink "Sound/play"}}{{/crossLink}} method.
	 * This method returns a {{#crossLink "SoundInstance"}}{{/crossLink}} which can be paused, resumed, muted, etc.
	 * Please see the {{#crossLink "SoundInstance"}}{{/crossLink}} documentation for more on the instance control APIs.
	 *
	 * <b>Plugins</b><br />
	 * By default, the {{#crossLink "WebAudioPlugin"}}{{/crossLink}} or the {{#crossLink "HTMLAudioPlugin"}}{{/crossLink}}
	 * are used (when available), although developers can change plugin priority or add new plugins (such as the
	 * provided {{#crossLink "FlashPlugin"}}{{/crossLink}}). Please see the {{#crossLink "Sound"}}{{/crossLink}} API
	 * methods for more on the playback and plugin APIs. To install plugins, or specify a different plugin order, see
	 * {{#crossLink "Sound/installPlugins"}}{{/crossLink}}.
	 *
	 * <h4>Example</h4>
	 *      createjs.Sound.registerPlugins([createjs.WebAudioPlugin, createjs.FlashPlugin]);
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
	 * a default limit.  Currently HTMLAudioPlugin sets a default limit of 2, while WebAudioPlugin and FlashPlugin set a
	 * default limit of 100.
	 *
	 *      createjs.Sound.registerSound("sound.mp3", "soundId", 4);
	 *
	 * Sound can be used as a plugin with PreloadJS to help preload audio properly. Audio preloaded with PreloadJS is
	 * automatically registered with the Sound class. When audio is not preloaded, Sound will do an automatic internal
	 * load. As a result, it may not play immediately the first time play is called. Use the
	 * {{#crossLink "Sound/fileload"}}{{/crossLink}} event to determine when a sound has finished internally preloading.
	 * It is recommended that all audio is preloaded before it is played.
	 *
	 *      createjs.PreloadJS.installPlugin(createjs.Sound);
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
	 * <li>There is a limit to how many audio tags you can load and play at once, which appears to be determined by
	 * hardware and browser settings.  See {{#crossLink "HTMLAudioPlugin.MAX_INSTANCES"}}{{/crossLink}} for a safe estimate.</li></ul>
	 *
	 * <b>Firefox 25 Web Audio limitations</b>
	 * <ul><li>mp3 audio files do not load properly on all windows machines, reported
	 * <a href="https://bugzilla.mozilla.org/show_bug.cgi?id=929969" target="_blank">here</a>. </br>
	 * For this reason it is recommended to pass ogg file first until this bug is resolved, if possible.</li></ul>

	 * <b>Safari limitations</b><br />
	 * <ul><li>Safari requires Quicktime to be installed for audio playback.</li></ul>
	 *
	 * <b>iOS 6 Web Audio limitations</b><br />
	 * <ul><li>Sound is initially muted and will only unmute through play being called inside a user initiated event
	 * (touch/click).</li>
	 * <li>Despite suggestions to the opposite, we have control over audio volume through our gain nodes.</li>
	 * <li>A bug exists that will distort un-cached web audio when a video element is present in the DOM.</li>
	 * <li>Note HTMLAudioPlugin is not supported on iOS by default.  See {{#crossLink "HTMLAudioPlugin"}}{{/crossLink}}
	 * for more details.<li>
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

	/**
	 * This approach has is being replaced by {{#crossLink "Sound/alternateExtensions:property"}}{{/crossLink}}, and
	 * support will be removed in the next version.
	 * The character (or characters) that are used to split multiple paths from an audio source.
	 * @property DELIMITER
	 * @type {String}
	 * @default |
	 * @static
	 * @deprecated
	 */
	s.DELIMITER = "|";

	/**
	 * The duration in milliseconds to determine a timeout.
	 * @property AUDIO_TIMEOUT
	 * @static
	 * @type {Number}
	 * @default 8000
	 * @protected
	 */
	s.AUDIO_TIMEOUT = 8000; // TODO: This is not implemented  // OJR remove property? doc'd as protected to remove from docs for now

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

// The playState in plugins should be implemented with these values.
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
	 * NOTE this does not currently work for {{#crossLink "FlashPlugin"}}{{/crossLink}}.
	 *
	 * More details on file formats can be found at http://en.wikipedia.org/wiki/Audio_file_format. A very detailed
	 * list of file formats can be found at http://www.fileinfo.com/filetypes/audio. A useful list of extensions for
	 * each format can be found at http://html5doctor.com/html5-audio-the-state-of-play/
	 * @property SUPPORTED_EXTENSIONS
	 * @type {Array[String]}
	 * @default ["mp3", "ogg", "mpeg", "wav", "m4a", "mp4", "aiff", "wma", "mid"]
	 */
	s.SUPPORTED_EXTENSIONS = ["mp3", "ogg", "mpeg", "wav", "m4a", "mp4", "aiff", "wma", "mid"];  // OJR FlashPlugin does not currently support

	/**
	 * Some extensions use another type of extension support to play (one of them is a codex).  This allows you to map
	 * that support so plugins can accurately determine if an extension is supported.  Adding to this list can help
	 * plugins determine more accurately if an extension is supported.
	 * @property EXTENSION_MAP
	 * @type {Object}
	 * @since 0.4.0
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

	/**
	 * Determines the default behavior for interrupting other currently playing instances with the same source, if the
	 * maximum number of instances of the sound are already playing.  Currently the default is {{#crossLink "Sound/INTERRUPT_NONE:property"}}{{/crossLink}}
	 * but this can be set and will change playback behavior accordingly.  This is only used when {{#crossLink "Sound/play"}}{{/crossLink}}
	 * is called without passing a value for interrupt.
	 * @property defaultInterruptBehavior
	 * @type {String}
	 * @default none
	 * @static
	 * @since 0.4.0
	 */
	s.defaultInterruptBehavior = s.INTERRUPT_NONE;  // OJR does s.INTERRUPT_ANY make more sense as default?  Needs game dev testing to see which case makes more sense.

	/**
	 * An array of extensions to attempt to use when loading sound, if the default is unsupported by the active plugin.
	 * These are applied in order, so if you try to Load Thunder.ogg in a browser that does not support ogg, and your
	 * extensions array is ["mp3", "m4a", "wav"] it will check mp3 support, then m4a, then wav. These audio files need
	 * to exist in the same location.
	 *
	 * <h4>Example</h4>
	 *      var manifest = [
	 *          {src:"asset0.ogg", id:"example"},
	 *      ];
	 * 		createjs.Sound.alternateExtensions = ["mp3"];	// now if ogg is not supported, SoundJS will try asset0.mp3
	 *      createjs.Sound.addEventListener("fileload", handleLoad); // call handleLoad when each sound loads
	 *      createjs.Sound.registerManifest(manifest, assetPath);
	 *
	 * Note that regardless of which file is loaded, you can create and play instances using the id or the same
	 * assetPath + src passed for loading.
	 * @property alternateExtensions
	 * @type {Array}
	 * @since 0.5.2
	 */
	s.alternateExtensions = [];

	/**
	 * Used internally to assign unique IDs to each SoundInstance.
	 * @property lastID
	 * @type {Number}
	 * @static
	 * @protected
	 */
	s.lastId = 0;

	/**
	 * The currently active plugin. If this is null, then no plugin could be initialized. If no plugin was specified,
	 * Sound attempts to apply the default plugins: {{#crossLink "WebAudioPlugin"}}{{/crossLink}}, followed by
	 * {{#crossLink "HTMLAudioPlugin"}}{{/crossLink}}.
	 * @property activePlugin
	 * @type {Object}
	 * @static
	 */
    s.activePlugin = null;

	/**
	 * Determines if the plugins have been registered. If false, the first call to play() will instantiate the default
	 * plugins ({{#crossLink "WebAudioPlugin"}}{{/crossLink}}, followed by {{#crossLink "HTMLAudioPlugin"}}{{/crossLink}}).
	 * If plugins have been registered, but none are applicable, then sound playback will fail.
	 * @property pluginsRegistered
	 * @type {Boolean}
	 * @default false
	 * @static
	 * @protected
	 */
	s.pluginsRegistered = false;

	/**
	 * The master volume value, which affects all sounds. Use {{#crossLink "Sound/getVolume"}}{{/crossLink}} and
	 * {{#crossLink "Sound/setVolume"}}{{/crossLink}} to modify the volume of all audio.
	 * @property masterVolume
	 * @type {Number}
	 * @default 1
	 * @protected
	 * @since 0.4.0
	 */
	s.masterVolume = 1;

	/**
	 * The master mute value, which affects all sounds.  This is applies to all sound instances.  This value can be set
	 * through {{#crossLink "Sound/setMute"}}{{/crossLink}} and accessed via {{#crossLink "Sound/getMute"}}{{/crossLink}}.
	 * @property masterMute
	 * @type {Boolean}
	 * @default false
	 * @protected
	 * @static
	 * @since 0.4.0
	 */
	s.masterMute = false;

	/**
	 * An array containing all currently playing instances. This allows Sound to control the volume, mute, and playback of
	 * all instances when using static APIs like {{#crossLink "Sound/stop"}}{{/crossLink}} and {{#crossLink "Sound/setVolume"}}{{/crossLink}}.
	 * When an instance has finished playback, it gets removed via the {{#crossLink "Sound/finishedPlaying"}}{{/crossLink}}
	 * method. If the user replays an instance, it gets added back in via the {{#crossLink "Sound/beginPlaying"}}{{/crossLink}}
	 * method.
	 * @property instances
	 * @type {Array}
	 * @protected
	 * @static
	 */
	s.instances = [];

	/**
	 * An object hash storing sound sources via there corresponding ID.
	 * @property idHash
	 * @type {Object}
	 * @protected
	 * @static
	 */
	s.idHash = {};

	/**
	 * An object hash that stores preloading sound sources via the parsed source that is passed to the plugin.  Contains the
	 * source, id, and data that was passed in by the user.  Parsed sources can contain multiple instances of source, id,
	 * and data.
	 * @property preloadHash
	 * @type {Object}
	 * @protected
	 * @static
	 */
	s.preloadHash = {};

	/**
	 * An object that stands in for audio that fails to play. This allows developers to continue to call methods
	 * on the failed instance without having to check if it is valid first. The instance is instantiated once, and
	 * shared to keep the memory footprint down.
	 * @property defaultSoundInstance
	 * @type {Object}
	 * @protected
	 * @static
	 */
	s.defaultSoundInstance = null;

// mix-ins:
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

	//TODO: Deprecated
	/**
	 * REMOVED. Use {{#crossLink "EventDispatcher/addEventListener"}}{{/crossLink}} and the {{#crossLink "Sound/fileload:event"}}{{/crossLink}}
	 * event.
	 * @property onLoadComplete
	 * @type {Function}
	 * @deprecated Use addEventListener and the fileload event.
	 * @since 0.4.0
	 */

	/**
	 * Used by external plugins to dispatch file load events.
	 * @method sendFileLoadEvent
	 * @param {String} src A sound file has completed loading, and should be dispatched.
	 * @protected
	 * @static
	 * @since 0.4.1
	 */
	s.sendFileLoadEvent = function (src) {
		if (!s.preloadHash[src]) {
			return;
		}
		for (var i = 0, l = s.preloadHash[src].length; i < l; i++) {
			var item = s.preloadHash[src][i];
			s.preloadHash[src][i] = true;

			if (!s.hasEventListener("fileload")) { continue; }

			var event = new createjs.Event("fileload");
			event.src = item.src;
			event.id = item.id;
			event.data = item.data;

			s.dispatchEvent(event);
		}
	};

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
	 * Deprecated in favor of {{#crossLink "Sound/registerPlugins"}}{{/crossLink}} with a single argument.
	 *      createjs.Sound.registerPlugins([createjs.WebAudioPlugin]);
	 *
	 * @method registerPlugin
	 * @param {Object} plugin The plugin class to install.
	 * @return {Boolean} Whether the plugin was successfully initialized.
	 * @static
	 * @deprecated
	 */
	s.registerPlugin = function (plugin) {
		return s._registerPlugin(plugin);
	};

	/**
	 * Register a Sound plugin. Plugins handle the actual playback of audio. The default plugins are
	 * ({{#crossLink "WebAudioPlugin"}}{{/crossLink}} followed by {{#crossLink "HTMLAudioPlugin"}}{{/crossLink}}),
	 * and are installed if no other plugins are present when the user attempts to start playback or register sound.
	 * <h4>Example</h4>
	 *      createjs.FlashPlugin.swfPath = "../src/SoundJS/";
	 *      createjs.Sound._registerPlugin(createjs.FlashPlugin);
	 *
	 * To register multiple plugins, use {{#crossLink "Sound/registerPlugins"}}{{/crossLink}}.
	 *
	 * @method _registerPlugin
	 * @param {Object} plugin The plugin class to install.
	 * @return {Boolean} Whether the plugin was successfully initialized.
	 * @static
	 * @private
	 */
	s._registerPlugin = function (plugin) {
		s.pluginsRegistered = true;
		if (plugin == null) {
			return false;
		}
		// Note: Each plugin is passed in as a class reference, but we store the activePlugin as an instance
		if (plugin.isSupported()) {
			s.activePlugin = new plugin();
			//TODO: Check error on initialization
			return true;
		}
		return false;
	};

	/**
	 * Register a list of Sound plugins, in order of precedence. To register a single plugin, pass a single element in the array.
	 *
	 * <h4>Example</h4>
	 *      createjs.FlashPlugin.swfPath = "../src/SoundJS/";
	 *      createjs.Sound.registerPlugins([createjs.WebAudioPlugin, createjs.HTMLAudioPlugin, createjs.FlashPlugin]);
	 *
	 * @method registerPlugins
	 * @param {Array} plugins An array of plugins classes to install.
	 * @return {Boolean} Whether a plugin was successfully initialized.
	 * @static
	 */
	s.registerPlugins = function (plugins) {
		for (var i = 0, l = plugins.length; i < l; i++) {
			var plugin = plugins[i];
			if (s._registerPlugin(plugin)) {
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
	 *  * <h4>Example</h4>
	 *      if (!createjs.initializeDefaultPlugins()) { return; }
	 *
	 * @method initializeDefaultPlugins
	 * @returns {Boolean} If a plugin is initialized (true) or not (false). If the browser does not have the
	 * capabilities to initialize any available plugins, this will return false.
	 * @since 0.4.0
	 */
	s.initializeDefaultPlugins = function () {
		if (s.activePlugin != null) {
			return true;
		}
		if (s.pluginsRegistered) {
			return false;
		}
		if (s.registerPlugins([createjs.WebAudioPlugin, createjs.HTMLAudioPlugin])) {
			return true;
		}
		return false;
	};

	/**
	 * Determines if Sound has been initialized, and a plugin has been activated.
	 *
	 * <h4>Example</h4>
	 * This example sets up a Flash fallback, but only if there is no plugin specified yet.
	 *
	 *      if (!createjs.Sound.isReady()) {
	 *			createjs.FlashPlugin.swfPath = "../src/SoundJS/";
	 *      	createjs.Sound.registerPlugins([createjs.WebAudioPlugin, createjs.HTMLAudioPlugin, createjs.FlashPlugin]);
	 *      }
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
	 *     <li><b>mp3:</b> If MP3 audio is supported.</li>
	 *     <li><b>ogg:</b> If OGG audio is supported.</li>
	 *     <li><b>wav:</b> If WAV audio is supported.</li>
	 *     <li><b>mpeg:</b> If MPEG audio is supported.</li>
	 *     <li><b>m4a:</b> If M4A audio is supported.</li>
	 *     <li><b>mp4:</b> If MP4 audio is supported.</li>
	 *     <li><b>aiff:</b> If aiff audio is supported.</li>
	 *     <li><b>wma:</b> If wma audio is supported.</li>
	 *     <li><b>mid:</b> If mid audio is supported.</li>
	 *     <li><b>tracks:</b> The maximum number of audio tracks that can be played back at a time. This will be -1
	 *     if there is no known limit.</li>
	 * @method getCapabilities
	 * @return {Object} An object containing the capabilities of the active plugin.
	 * @static
	 */
	s.getCapabilities = function () {
		if (s.activePlugin == null) {
			return null;
		}
		return s.activePlugin.capabilities;
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
		if (s.activePlugin == null) {
			return null;
		}
		return s.activePlugin.capabilities[key];
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
	 * this property is used for other information. The audio channels will default to 1 if no value is found.
	 * @param {String} [path] A combined basepath and subPath from PreloadJS that has already been prepended to src.
	 * @return {Boolean|Object} An object with the modified values of those that were passed in, or false if the active
	 * plugin can not play the audio type.
	 * @protected
	 * @static
	 */
	s.initLoad = function (src, type, id, data, path) {
		// remove path from src so we can continue to support "|" splitting of src files	// TODO remove this when "|" is removed
		src = src.replace(path, "");
		var details = s.registerSound(src, id, data, false, path);
		if (details == null) {
			return false;
		}
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
	 * @param {Boolean} [preload=true] If the sound should be internally preloaded so that it can be played back
	 * without an external preloader.
	 * @param {string} basePath Set a path that will be prepended to src for loading.
	 * @return {Object} An object with the modified values that were passed in, which defines the sound.
	 * Returns false if the source cannot be parsed or no plugins can be initialized.
	 * Returns true if the source is already loaded.
	 * @static
	 * @since 0.4.0
	 */
	s.registerSound = function (src, id, data, preload, basePath) {
		if (!s.initializeDefaultPlugins()) {
			return false;
		}

		if (src instanceof Object) {
			basePath = id;	//this assumes preload has not be passed in as a property // OJR check if arguments == 3 would be less fragile
			//?? preload = src.preload;
			// OJR refactor how data is passed in to make the parameters work better
			id = src.id;
			data = src.data;
			src = src.src;
		}

		// branch to different parse based on alternate formats setting
		if (s.alternateExtensions.length) {
			var details = s.parsePath2(src, "sound", id, data);
		} else {
			var details = s.parsePath(src, "sound", id, data);
		}
		if (details == null) {
			return false;
		}
		if (basePath != null) {details.src = basePath + details.src;}

		if (id != null) {
			s.idHash[id] = details.src;
		}

		var numChannels = null; // null tells SoundChannel to set this to it's internal maxDefault
		if (data != null) {
			if (!isNaN(data.channels)) {
				numChannels = parseInt(data.channels);
			}
			else if (!isNaN(data)) {
				numChannels = parseInt(data);
			}
		}
		var loader = s.activePlugin.register(details.src, numChannels);  // Note only HTML audio uses numChannels

		if (loader != null) {	// all plugins currently return a loader
			if (loader.numChannels != null) {
				numChannels = loader.numChannels;
			} // currently only HTMLAudio returns this
			SoundChannel.create(details.src, numChannels);

			// return the number of instances to the user.  This will also be returned in the load event.
			if (data == null || !isNaN(data)) {
				data = details.data = numChannels || SoundChannel.maxPerChannel();
			} else {
				data.channels = details.data.channels = numChannels || SoundChannel.maxPerChannel();
			}

			// If the loader returns a tag, return it instead for preloading.
			if (loader.tag != null) {
				details.tag = loader.tag;
			} else if (loader.src) {
				details.src = loader.src;
			}
			// If the loader returns a complete handler, pass it on to the prelaoder.
			if (loader.completeHandler != null) {
				details.completeHandler = loader.completeHandler;
			}
			if (loader.type) {
				details.type = loader.type;
			}
		}

		if (preload != false) {
			if (!s.preloadHash[details.src]) {
				s.preloadHash[details.src] = [];
			}  // we do this so we can store multiple id's and data if needed
			s.preloadHash[details.src].push({src:src, id:id, data:data});  // keep this data so we can return it in fileload event
			if (s.preloadHash[details.src].length == 1) {
				// if already loaded once, don't load a second time  // OJR note this will disallow reloading a sound if loading fails or the source changes
				s.activePlugin.preload(details.src, loader);
			} else {
				// if src already loaded successfully, return true
				if (s.preloadHash[details.src][0] == true) {return true;}
			}
		}

		return details;
	};

	/**
	 * Register a manifest of audio files for loading and future playback in Sound. It is recommended to register all
	 * sounds that need to be played back in order to properly prepare and preload them. Sound does internal preloading
	 * when required.
	 *
	 * <h4>Example</h4>
	 *      var manifest = [
	 *          {src:"asset0.ogg", id:"example"},
	 *          {src:"asset1.ogg", id:"1", data:6},
	 *          {src:"asset2.mp3", id:"works"}
	 *      ];
	 *      createjs.Sound.alternateExtensions = ["mp3"];	// if the passed extension is not supported, try this extension
	 *      createjs.Sound.addEventListener("fileload", handleLoad); // call handleLoad when each sound loads
	 *      createjs.Sound.registerManifest(manifest, assetPath);
	 *
	 * @method registerManifest
	 * @param {Array} manifest An array of objects to load. Objects are expected to be in the format needed for
	 * {{#crossLink "Sound/registerSound"}}{{/crossLink}}: <code>{src:srcURI, id:ID, data:Data, preload:UseInternalPreloader}</code>
	 * with "id", "data", and "preload" being optional.
	 * @param {string} basePath Set a path that will be prepended to each src when loading.  When creating or playing
	 * audio that was loaded with a basePath by src, the basePath must be included.
	 * @return {Object} An array of objects with the modified values that were passed in, which defines each sound.
	 * Like registerSound, it will return false for any values that the source cannot be parsed or if no plugins can be initialized.
	 * Also, it will returns true for any values that the source is already loaded.
	 * @static
	 * @since 0.4.0
	 */
	s.registerManifest = function (manifest, basePath) {
		var returnValues = [];
		for (var i = 0, l = manifest.length; i < l; i++) {
			returnValues[i] = createjs.Sound.registerSound(manifest[i].src, manifest[i].id, manifest[i].data, manifest[i].preload, basePath);
		}
		return returnValues;
	};

	/**
	 * Remove a sound that has been registered with {{#crossLink "Sound/registerSound"}}{{/crossLink}} or
	 * {{#crossLink "Sound/registerManifest"}}{{/crossLink}}.
	 * Note this will stop playback on active instances playing this sound before deleting them.
	 * Note if you passed in a basePath, you need to prepend it to the src here.
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
		if (s.activePlugin == null) {
			return false;
		}

		if (src instanceof Object) {
			src = src.src;
		}
		src = s.getSrcById(src);

		if (s.alternateExtensions.length) {
			var details = s.parsePath2(src);
		} else {
			var details = s.parsePath(src);
		}
		if (details == null) {
			return false;
		}
		if (basePath != null) {details.src = basePath + details.src;}
		src = details.src;

		// remove src from idHash	// Note "for in" can be a slow operation
		for(var prop in s.idHash){
			if(s.idHash[prop] == src) {
				delete(s.idHash[prop]);
			}
		}

		// clear from SoundChannel, which also stops and deletes all instances
		SoundChannel.removeSrc(src);

		// remove src from preloadHash
		delete(s.preloadHash[src]);

		// activePlugin cleanup
		s.activePlugin.removeSound(src);

		return true;
	};

	/**
	 * Remove a manifest of audio files that have been registered with {{#crossLink "Sound/registerSound"}}{{/crossLink}} or
	 * {{#crossLink "Sound/registerManifest"}}{{/crossLink}}.
	 * Note this will stop playback on active instances playing this audio before deleting them.
	 * Note if you passed in a basePath, you do not need to pass it or add it to the src here.
	 *
	 * <h4>Example</h4>
	 *      var manifest = [
	 *          {src:"asset0.ogg", id:"example"},
	 *          {src:"asset1.ogg", id:"1", data:6},
	 *          {src:"asset2.mp3", id:"works"}
	 *      ];
	 *      createjs.Sound.removeManifest(manifest, assetPath);
	 *
	 * @method removeManifest
	 * @param {Array} manifest An array of objects to remove. Objects are expected to be in the format needed for
	 * {{#crossLink "Sound/removeSound"}}{{/crossLink}}: <code>{srcOrID:srcURIorID}</code>
	 * @param {string} basePath Set a path that will be prepended to each src when removing.
	 * @return {Object} An array of Boolean values representing if the sounds with the same array index in manifest was
	 * successfully removed.
	 * @static
	 * @since 0.4.1
	 */
	s.removeManifest = function (manifest, basePath) {
		var returnValues = [];
		for (var i = 0, l = manifest.length; i < l; i++) {
			returnValues[i] = createjs.Sound.removeSound(manifest[i].src, basePath);
		}
		return returnValues;
	};

	/**
	 * Remove all sounds that have been registered with {{#crossLink "Sound/registerSound"}}{{/crossLink}} or
	 * {{#crossLink "Sound/registerManifest"}}{{/crossLink}}.
	 * Note this will stop playback on all active sound instances before deleting them.
	 *
	 * <h4>Example</h4>
	 *     createjs.Sound.removeAllSounds();
	 *
	 * @method removeAllSounds
	 * @static
	 * @since 0.4.1
	 */
	s.removeAllSounds = function() {
		s.idHash = {};
		s.preloadHash = {};
		SoundChannel.removeAll();
		s.activePlugin.removeAllSounds();
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
		if (s.alternateExtensions.length) {
			var details = s.parsePath2(src, "sound");
		} else {
			var details = s.parsePath(src, "sound");
		}
		if (details) {
			src = s.getSrcById(details.src);
		} else {
			src = s.getSrcById(src);
		}
		return (s.preloadHash[src][0] == true);  // src only loads once, so if it's true for the first it's true for all
	};

	/**
	 * Parse the path of a sound, usually from a manifest item. Manifest items support single file paths, as well as
	 * composite paths using {{#crossLink "Sound/DELIMITER:property"}}{{/crossLink}}, which defaults to "|". The first path supported by the
	 * current browser/plugin will be used.
	 * NOTE the "|" approach is deprecated and will be removed in the next version
	 * @method parsePath
	 * @param {String} value The path to an audio source.
	 * @param {String} [type] The type of path. This will typically be "sound" or null.
	 * @param {String} [id] The user-specified sound ID. This may be null, in which case the src will be used instead.
	 * @param {Number | String | Boolean | Object} [data] Arbitrary data appended to the sound, usually denoting the
	 * number of channels for the sound. This method doesn't currently do anything with the data property.
	 * @return {Object} A formatted object that can be registered with the {{#crossLink "Sound/activePlugin:property"}}{{/crossLink}}
	 * and returned to a preloader like <a href="http://preloadjs.com" target="_blank">PreloadJS</a>.
	 * @protected
	 */
	s.parsePath = function (value, type, id, data) {
        if (typeof(value) != "string") {value = value.toString();}
		var sounds = value.split(s.DELIMITER);
		var ret = {type:type || "sound", id:id, data:data};
		var c = s.getCapabilities();
		for (var i = 0, l = sounds.length; i < l; i++) {
			var sound = sounds[i];

			var match = sound.match(s.FILE_PATTERN);
			if (match == null) {
				return false;
			}
			var name = match[4];
			var ext = match[5];

			if (c[ext] && createjs.indexOf(s.SUPPORTED_EXTENSIONS, ext) > -1) {
				ret.name = name;
				ret.src = sound;
				ret.extension = ext;
				return ret;
			}
		}
		return null;
	};

	// new approach, when old approach is deprecated this will become parsePath
	s.parsePath2 = function (value, type, id, data) {
		if (typeof(value) != "string") {value = value.toString();}

		var match = value.match(s.FILE_PATTERN);
		if (match == null) {
			return false;
		}
		var name = match[4];
		var ext = match[5];

		var c = s.getCapabilities();
		var i = 0;
		while (!c[ext]) {
			ext = s.alternateExtensions[i++];
			if (i > s.alternateExtensions.length) { return null;}	// no extensions are supported
		}

		value = value.replace("."+match[5], "."+ext);
		var ret = {type:type || "sound", id:id, data:data};
		ret.name = name;
		ret.src = value;
		ret.extension = ext;
		return ret;
	};

	/* ---------------
	 Static API.
	 --------------- */
	/**
	 * Play a sound and get a {{#crossLink "SoundInstance"}}{{/crossLink}} to control. If the sound fails to play, a
	 * SoundInstance will still be returned, and have a playState of {{#crossLink "Sound/PLAY_FAILED:property"}}{{/crossLink}}.
	 * Note that even on sounds with failed playback, you may still be able to call SoundInstance {{#crossLink "SoundInstance/play"}}{{/crossLink}},
	 * since the failure could be due to lack of available channels. If the src does not have a supported extension or
	 * if there is no available plugin, {{#crossLink "Sound/defaultSoundInstance:property"}}{{/crossLink}} will be
	 * returned, which will not play any audio, but will not generate errors.
	 *
	 * <h4>Example</h4>
	 *      createjs.Sound.addEventListener("fileload", handleLoad);
	 *      createjs.Sound.registerSound("myAudioPath/mySound.mp3", "myID", 3);
	 *      function handleLoad(event) {
	 *      	createjs.Sound.play("myID");
	 *      	// alternately we could call the following
	 *      	var myInstance = createjs.Sound.play("myAudioPath/mySound.mp3", createjs.Sound.INTERRUPT_ANY, 0, 0, -1, 1, 0);
	 *      	// another alternative is to pass in just the options we want to set inside of an object
	 *      	var myInstance = createjs.Sound.play("myAudioPath/mySound.mp3", {interrupt: createjs.Sound.INTERRUPT_ANY, loop:-1});
	 *      }
	 *
	 * @method play
	 * @param {String} src The src or ID of the audio.
	 * @param {String | Object} [interrupt="none"|options] How to interrupt any currently playing instances of audio with the same source,
	 * if the maximum number of instances of the sound are already playing. Values are defined as <code>INTERRUPT_TYPE</code>
	 * constants on the Sound class, with the default defined by {{#crossLink "Sound/defaultInterruptBehavior:property"}}{{/crossLink}}.
	 * <br /><strong>OR</strong><br />
	 * This parameter can be an object that contains any or all optional properties by name, including: interrupt,
	 * delay, offset, loop, volume, and pan (see the above code sample).
	 * @param {Number} [delay=0] The amount of time to delay the start of audio playback, in milliseconds.
	 * @param {Number} [offset=0] The offset from the start of the audio to begin playback, in milliseconds.
	 * @param {Number} [loop=0] How many times the audio loops when it reaches the end of playback. The default is 0 (no
	 * loops), and -1 can be used for infinite playback.
	 * @param {Number} [volume=1] The volume of the sound, between 0 and 1. Note that the master volume is applied
	 * against the individual volume.
	 * @param {Number} [pan=0] The left-right pan of the sound (if supported), between -1 (left) and 1 (right).
	 * @return {SoundInstance} A {{#crossLink "SoundInstance"}}{{/crossLink}} that can be controlled after it is created.
	 * @static
	 */
	s.play = function (src, interrupt, delay, offset, loop, volume, pan) {
		var instance = s.createInstance(src);

		var ok = s.playInstance(instance, interrupt, delay, offset, loop, volume, pan);
		if (!ok) {
			instance.playFailed();
		}
		return instance;
	};

	/**
	 * Creates a {{#crossLink "SoundInstance"}}{{/crossLink}} using the passed in src. If the src does not have a
	 * supported extension or if there is no available plugin, a {{#crossLink "Sound/defaultSoundInstance:property"}}{{/crossLink}}
	 * will be returned that can be called safely but does nothing.
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
	 * @method createInstance
	 * @param {String} src The src or ID of the audio.
	 * @return {SoundInstance} A {{#crossLink "SoundInstance"}}{{/crossLink}} that can be controlled after it is created.
	 * Unsupported extensions will return the default SoundInstance.
	 * @since 0.4.0
	 */
	s.createInstance = function (src) {
		if (!s.initializeDefaultPlugins()) {
			return s.defaultSoundInstance;
		}

		src = s.getSrcById(src);

		if (s.alternateExtensions.length) {
			var details = s.parsePath2(src, "sound");
		} else {
			var details = s.parsePath(src, "sound");
		}

		var instance = null;
		if (details != null && details.src != null) {
			// make sure that we have a sound channel (sound is registered or previously played)
			SoundChannel.create(details.src);
			instance = s.activePlugin.create(details.src);
		} else {
			// the src is not supported, so give back a dummy instance.
			// This can happen if PreloadJS fails because the plugin does not support the ext, and was passed an id which
			// will not get added to the idHash.
			instance = Sound.defaultSoundInstance;
		}

		instance.uniqueId = s.lastId++;  // OJR moved this here so we can have multiple plugins active in theory

		return instance;
	};

	/**
	 * Set the master volume of Sound. The master volume is multiplied against each sound's individual volume.  For
	 * example, if master volume is 0.5 and a sound's volume is 0.5, the resulting volume is 0.25. To set individual
	 * sound volume, use SoundInstance {{#crossLink "SoundInstance/setVolume"}}{{/crossLink}} instead.
	 *
	 * <h4>Example</h4>
	 *     createjs.Sound.setVolume(0.5);
	 *
	 * @method setVolume
	 * @param {Number} value The master volume value. The acceptable range is 0-1.
	 * @static
	 */
	s.setVolume = function (value) {
		if (Number(value) == null) {
			return false;
		}
		value = Math.max(0, Math.min(1, value));
		s.masterVolume = value;
		if (!this.activePlugin || !this.activePlugin.setVolume || !this.activePlugin.setVolume(value)) {
			var instances = this.instances;  // OJR does this impact garbage collection more than it helps performance?
			for (var i = 0, l = instances.length; i < l; i++) {
				instances[i].setMasterVolume(value);
			}
		}
	};

	/**
	 * Get the master volume of Sound. The master volume is multiplied against each sound's individual volume.
	 * To get individual sound volume, use SoundInstance {{#crossLink "SoundInstance/volume"}}{{/crossLink}} instead.
	 *
	 * <h4>Example</h4>
	 *     var masterVolume = createjs.Sound.getVolume();
	 *
	 * @method getVolume
	 * @return {Number} The master volume, in a range of 0-1.
	 * @static
	 */
	s.getVolume = function () {
		return s.masterVolume;
	};

	/**
	 * REMOVED. Please see {{#crossLink "Sound/setMute"}}{{/crossLink}}.
	 * @method mute
	 * @param {Boolean} value Whether the audio should be muted or not.
	 * @static
	 * @deprecated This function has been deprecated. Please use setMute instead.
	 */

	/**
	 * Mute/Unmute all audio. Note that muted audio still plays at 0 volume. This global mute value is maintained
	 * separately and when set will override, but not change the mute property of individual instances. To mute an individual
	 * instance, use SoundInstance {{#crossLink "SoundInstance/setMute"}}{{/crossLink}} instead.
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
		if (value == null || value == undefined) {
			return false;
		}

		this.masterMute = value;
		if (!this.activePlugin || !this.activePlugin.setMute || !this.activePlugin.setMute(value)) {
			var instances = this.instances;
			for (var i = 0, l = instances.length; i < l; i++) {
				instances[i].setMasterMute(value);
			}
		}
		return true;
	}

	/**
	 * Returns the global mute value. To get the mute value of an individual instance, use SoundInstance
	 * {{#crossLink "SoundInstance/getMute"}}{{/crossLink}} instead.
	 *
	 * <h4>Example</h4>
	 *     var masterMute = createjs.Sound.getMute();
	 *
	 * @method getMute
	 * @return {Boolean} The mute value of Sound.
	 * @static
	 * @since 0.4.0
	 */
	s.getMute = function () {
		return this.masterMute;
	};

	/**
	 * Stop all audio (global stop). Stopped audio is reset, and not paused. To play audio that has been stopped,
	 * call {{#crossLink "SoundInstance.play"}}{{/crossLink}}.
	 *
	 * <h4>Example</h4>
	 *     createjs.Sound.stop();
	 *
	 * @method stop
	 * @static
	 */
	s.stop = function () {
		var instances = this.instances;
		for (var i = instances.length; i--; ) {
			instances[i].stop();  // NOTE stop removes instance from this.instances
		}
	};


	/* ---------------
	 Internal methods
	 --------------- */
	/**
	 * Play an instance. This is called by the static API, as well as from plugins. This allows the core class to
	 * control delays.
	 * @method playInstance
	 * @param {SoundInstance} instance The {{#crossLink "SoundInstance"}}{{/crossLink}} to start playing.
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
	s.playInstance = function (instance, interrupt, delay, offset, loop, volume, pan) {
		if (interrupt instanceof Object) {
			delay = interrupt.delay;
			offset = interrupt.offset;
			loop = interrupt.loop;
			volume = interrupt.volume;
			pan = interrupt.pan;
		}

		interrupt = interrupt || s.defaultInterruptBehavior;
		if (delay == null) {delay = 0;}
		if (offset == null) {offset = instance.getPosition();}
		if (loop == null) {loop = 0;}
		if (volume == null) {volume = instance.volume;}
		if (pan == null) {pan = instance.pan;}

		if (delay == 0) {
			var ok = s.beginPlaying(instance, interrupt, offset, loop, volume, pan);
			if (!ok) {
				return false;
			}
		} else {
			//Note that we can't pass arguments to proxy OR setTimeout (IE only), so just wrap the function call.
			// OJR WebAudio may want to handle this differently, so it might make sense to move this functionality into the plugins in the future
			var delayTimeoutId = setTimeout(function () {
				s.beginPlaying(instance, interrupt, offset, loop, volume, pan);
			}, delay);
			instance.delayTimeoutId = delayTimeoutId;
		}

		this.instances.push(instance);

		return true;
	};

	/**
	 * Begin playback. This is called immediately or after delay by {{#crossLink "Sound/playInstance"}}{{/crossLink}}.
	 * @method beginPlaying
	 * @param {SoundInstance} instance A {{#crossLink "SoundInstance"}}{{/crossLink}} to begin playback.
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
	s.beginPlaying = function (instance, interrupt, offset, loop, volume, pan) {
		if (!SoundChannel.add(instance, interrupt)) {
			return false;
		}
		var result = instance.beginPlaying(offset, loop, volume, pan);
		if (!result) {
			//LM: Should we remove this from the SoundChannel (see finishedPlaying)
			var index = createjs.indexOf(this.instances, instance);
			if (index > -1) {
				this.instances.splice(index, 1);
			}
			return false;
		}
		return true;
	};

	/**
	 * Get the source of a sound via the ID passed in with a register call. If no ID is found the value is returned
	 * instead.
	 * @method getSrcById
	 * @param {String} value The ID the sound was registered with.
	 * @return {String} The source of the sound.  Returns null if src has been registered with this id.
	 * @protected
	 * @static
	 */
	s.getSrcById = function (value) {
		if (s.idHash == null || s.idHash[value] == null) {
			return value;
		}
		return s.idHash[value];
	};

	/**
	 * A sound has completed playback, been interrupted, failed, or been stopped. This method removes the instance from
	 * Sound management. It will be added again, if the sound re-plays. Note that this method is called from the
	 * instances themselves.
	 * @method playFinished
	 * @param {SoundInstance} instance The instance that finished playback.
	 * @protected
	 * @static
	 */
	s.playFinished = function (instance) {
		SoundChannel.remove(instance);
		var index = createjs.indexOf(this.instances, instance);
		if (index > -1) {
			this.instances.splice(index, 1);
		}
	};

	/**
	 * REMOVED.  Please use createjs.proxy instead
	 * @method proxy
	 * @param {Function} method The function to call
	 * @param {Object} scope The scope to call the method name on
	 * @protected
	 * @static
	 * @deprecated Deprecated in favor of createjs.proxy.
	 */

	createjs.Sound = Sound;

	/**
	 * An internal class that manages the number of active {{#crossLink "SoundInstance"}}{{/crossLink}} instances for
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
		if (channel == null) {
			return false;
		}
		channel.removeAll();	// this stops and removes all active instances
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
			SoundChannel.channels[channel].removeAll();	// this stops and removes all active instances
		}
		SoundChannel.channels = {};
	};
	/**
	 * Add an instance to a sound channel.
	 * #method add
	 * @param {SoundInstance} instance The instance to add to the channel
	 * @param {String} interrupt The interrupt value to use. Please see the {{#crossLink "Sound/play"}}{{/crossLink}}
	 * for details on interrupt modes.
	 * @return {Boolean} The success of the method call. If the channel is full, it will return false.
	 * @static
	 */
	SoundChannel.add = function (instance, interrupt) {
		var channel = SoundChannel.get(instance.src);
		if (channel == null) {
			return false;
		}
		return channel.add(instance, interrupt);
	};
	/**
	 * Remove an instance from the channel.
	 * #method remove
	 * @param {SoundInstance} instance The instance to remove from the channel
	 * @return The success of the method call. If there is no channel, it will return false.
	 * @static
	 */
	SoundChannel.remove = function (instance) {
		var channel = SoundChannel.get(instance.src);
		if (channel == null) {
			return false;
		}
		channel.remove(instance);
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
		if (this.max == -1) {
			this.max = this.maxDefault;
		}
		this.instances = [];
	};

	/**
	 * Get an instance by index.
	 * #method get
	 * @param {Number} index The index to return.
	 * @return {SoundInstance} The SoundInstance at a specific instance.
	 */
	p.get = function (index) {
		return this.instances[index];
	};

	/**
	 * Add a new instance to the channel.
	 * #method add
	 * @param {SoundInstance} instance The instance to add.
	 * @return {Boolean} The success of the method call. If the channel is full, it will return false.
	 */
	p.add = function (instance, interrupt) {
		if (!this.getSlot(interrupt, instance)) {
			return false;
		}
		this.instances.push(instance);
		this.length++;
		return true;
	};

	/**
	 * Remove an instance from the channel, either when it has finished playing, or it has been interrupted.
	 * #method remove
	 * @param {SoundInstance} instance The instance to remove
	 * @return {Boolean} The success of the remove call. If the instance is not found in this channel, it will
	 * return false.
	 */
	p.remove = function (instance) {
		var index = createjs.indexOf(this.instances, instance);
		if (index == -1) {
			return false;
		}
		this.instances.splice(index, 1);
		this.length--;
		return true;
	};

	/**
	 * Stop playback and remove all instances from the channel.  Usually in response to a delete call.
	 * #method removeAll
	 */
	p.removeAll = function () {
		// Note that stop() removes the item from the list, but we don't want to assume that.
		for (var i=this.length-1; i>=0; i--) {
			this.instances[i].stop();
		}
	};

	/**
	 * Get an available slot depending on interrupt value and if slots are available.
	 * #method getSlot
	 * @param {String} interrupt The interrupt value to use.
	 * @param {SoundInstance} instance The sound instance that will go in the channel if successful.
	 * @return {Boolean} Determines if there is an available slot. Depending on the interrupt mode, if there are no slots,
	 * an existing SoundInstance may be interrupted. If there are no slots, this method returns false.
	 */
	p.getSlot = function (interrupt, instance) {
		var target, replacement;

		for (var i = 0, l = this.max; i < l; i++) {
			target = this.get(i);

			// Available Space
			if (target == null) {
				return true;
			} else if (interrupt == Sound.INTERRUPT_NONE && target.playState != Sound.PLAY_FINISHED) {
				continue;
			}

			// First replacement candidate
			if (i == 0) {
				replacement = target;
				continue;
			}

			// Audio is complete or not playing
			if (target.playState == Sound.PLAY_FINISHED ||
					target.playState == Sound.PLAY_INTERRUPTED ||
					target.playState == Sound.PLAY_FAILED) {
				replacement = target;

				// Audio is a better candidate than the current target, according to playhead
			} else if (
					(interrupt == Sound.INTERRUPT_EARLY && target.getPosition() < replacement.getPosition()) ||
							(interrupt == Sound.INTERRUPT_LATE && target.getPosition() > replacement.getPosition())) {
				replacement = target;
			}
		}

		if (replacement != null) {
			replacement.interrupt();
			this.remove(replacement);
			return true;
		}
		return false;
	};

	p.toString = function () {
		return "[Sound SoundChannel]";
	};

	// do not add SoundChannel to namespace


	// This is a dummy sound instance, which allows Sound to return something so developers don't need to check nulls.
	function SoundInstance() {
		this.isDefault = true;
		this.addEventListener = this.removeEventListener = this.removeAllEventListeners = this.dispatchEvent = this.hasEventListener = this._listeners = this.interrupt = this.playFailed = this.pause = this.resume = this.play = this.beginPlaying = this.cleanUp = this.stop = this.setMasterVolume = this.setVolume = this.mute = this.setMute = this.getMute = this.setPan = this.getPosition = this.setPosition = function () {
			return false;
		};
		this.getVolume = this.getPan = this.getDuration = function () {
			return 0;
		}
		this.playState = Sound.PLAY_FAILED;
		this.toString = function () {
			return "[Sound Default Sound Instance]";
		}
	}

	Sound.defaultSoundInstance = new SoundInstance();

	//TODO: Moved to createjs/utils/Proxy.js. Deprecate on next version.
	if (createjs.proxy == null) {
		createjs.proxy = function() {
			throw("Proxy has been moved to an external file, and must be included separately.");
		}
	}


	/**
	 * An additional module to determine the current browser, version, operating system, and other environment
	 * variables. It is not publically documented.
	 * #class BrowserDetect
	 * @param {Boolean} isFirefox True if our browser is Firefox.
	 * @param {Boolean} isOpera True if our browser is opera.
	 * @param {Boolean} isChrome True if our browser is Chrome.  Note that Chrome for Android returns true, but is a
	 * completely different browser with different abilities.
	 * @param {Boolean} isIOS True if our browser is safari for iOS devices (iPad, iPhone, and iPad).
	 * @param {Boolean} isAndroid True if our browser is Android.
	 * @param {Boolean} isBlackberry True if our browser is Blackberry.
	 * @constructor
	 * @static
	 */
	function BrowserDetect() {
	}

	BrowserDetect.init = function () {
		var agent = window.navigator.userAgent;
		BrowserDetect.isFirefox = (agent.indexOf("Firefox") > -1);
		BrowserDetect.isOpera = (window.opera != null);
		BrowserDetect.isChrome = (agent.indexOf("Chrome") > -1);  // NOTE that Chrome on Android returns true but is a completely different browser with different abilities
		BrowserDetect.isIOS = agent.indexOf("iPod") > -1 || agent.indexOf("iPhone") > -1 || agent.indexOf("iPad") > -1;
		BrowserDetect.isAndroid = (agent.indexOf("Android") > -1);
		BrowserDetect.isBlackberry = (agent.indexOf("Blackberry") > -1);
	};

	BrowserDetect.init();

	createjs.Sound.BrowserDetect = BrowserDetect;

}());
/*
 * WebAudioPlugin
 * Visit http://createjs.com/ for documentation, updates and examples.
 *
 *
 * Copyright (c) 2012 gskinner.com, inc.
 *
 * Permission is hereby granted, free of charge, to any person
 * obtaining a copy of this software and associated documentation
 * files (the "Software"), to deal in the Software without
 * restriction, including without limitation the rights to use,
 * copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following
 * conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 * OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 * HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 * WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 * OTHER DEALINGS IN THE SOFTWARE.
 */

/**
 * @module SoundJS
 */

// namespace:
this.createjs = this.createjs || {};

(function () {

	"use strict";

	/**
	 * Play sounds using Web Audio in the browser. The WebAudio plugin has been successfully tested with:
	 * <ul><li>Google Chrome, version 23+ on OS X and Windows</li>
	 *      <li>Safari 6+ on OS X</li>
	 *      <li>Mobile Safari on iOS 6+</li>
	 *      <li>Firefox 25+ on OS X, Windows, and Fx OS</li>
	 * </ul>
	 *
	 * The WebAudioPlugin is currently the default plugin, and will be used anywhere that it is supported. Currently
	 * Chrome and Safari offer support.  Firefox and Android Chrome both offer support for web audio in upcoming
	 * releases.  To change plugin priority, check out the Sound API {{#crossLink "Sound/registerPlugins"}}{{/crossLink}} method.

	 * <h4>Known Browser and OS issues for Web Audio Plugin</h4>
	 * <b>Firefox 25</b>
	 * <ul><li>mp3 audio files do not load properly on all windows machines, reported
	 * <a href="https://bugzilla.mozilla.org/show_bug.cgi?id=929969" target="_blank">here</a>. </br>
	 * For this reason it is recommended to pass ogg file first until this bug is resolved, if possible.</li></ul>
	 * <br />
	 * <b>Webkit (Chrome and Safari)</b>
	 * <ul><li>AudioNode.disconnect does not always seem to work.  This can cause the file size to grow over time if you
	 * are playing a lot of audio files.</li></ul>
	 * <br />
	 * <b>iOS 6 limitations</b>
	 * 	<ul><li>Sound is initially muted and will only unmute through play being called inside a user initiated event (touch/click).</li>
	 *  <li>Despite suggestions to the opposite, we have relative control over audio volume through the gain nodes.</li>
	 *	<li>A bug exists that will distort uncached audio when a video element is present in the DOM.</li>
	 * </ul>
	 * @class WebAudioPlugin
	 * @constructor
	 * @since 0.4.0
	 */
	function WebAudioPlugin() {
		this.init();
	}


	var s = WebAudioPlugin;

	/**
	 * The capabilities of the plugin. This is generated via the {{#crossLink "WebAudioPlugin/generateCapabilities:method"}}{{/crossLink}}
	 * method and is used internally.
	 * @property capabilities
	 * @type {Object}
	 * @default null
	 * @protected
	 * @static
	 */
	s.capabilities = null;

	/**
	 * Determine if the plugin can be used in the current browser/OS.
	 * @method isSupported
	 * @return {Boolean} If the plugin can be initialized.
	 * @static
	 */
	s.isSupported = function () {
		// check if this is some kind of mobile device, Web Audio works with local protocol under PhoneGap and it is unlikely someone is trying to run a local file
		var isMobilePhoneGap = createjs.Sound.BrowserDetect.isIOS || createjs.Sound.BrowserDetect.isAndroid || createjs.Sound.BrowserDetect.isBlackberry;
		// OJR isMobile may be redundant with isFileXHRSupported available.  Consider removing.
		if (location.protocol == "file:" && !isMobilePhoneGap && !this.isFileXHRSupported()) { return false; }  // Web Audio requires XHR, which is not usually available locally
		s.generateCapabilities();
		if (s.context == null) {
			return false;
		}
		return true;
	};

	/**
	 * Determine if XHR is supported, which is necessary for web audio.
	 * @method isFileXHRSupported
	 * @return {Boolean} If XHR is supported.
	 * @since 0.4.2
	 * @protected
	 * @static
	 */
	s.isFileXHRSupported = function() {
		// it's much easier to detect when something goes wrong, so let's start optimisticaly
		var supported = true;

		var xhr = new XMLHttpRequest();
		try {
			xhr.open("GET", "fail.fail", false); // loading non-existant file triggers 404 only if it could load (synchronous call)
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
	 * @method generateCapabiities
	 * @static
	 * @protected
	 */
	s.generateCapabilities = function () {
		if (s.capabilities != null) {
			return;
		}
		// Web Audio can be in any formats supported by the audio element, from http://www.w3.org/TR/webaudio/#AudioContext-section,
		// therefore tag is still required for the capabilities check
		var t = document.createElement("audio");

		if (t.canPlayType == null) {
			return null;
		}

		// This check is first because it's what is currently used, but the spec calls for it to be AudioContext so this
		//  will probably change in time
		if (window.webkitAudioContext) {
			s.context = new webkitAudioContext();
		} else if (window.AudioContext) {
			s.context = new AudioContext();
		} else {
			return null;
		}

		// this handles if only deprecated Web Audio API calls are supported
		s.compatibilitySetUp();

		// playing this inside of a touch event will enable audio on iOS, which starts muted
		s.playEmptySound();

		s.capabilities = {
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
			s.capabilities[ext] = (t.canPlayType("audio/" + ext) != "no" && t.canPlayType("audio/" + ext) != "") || (t.canPlayType("audio/" + playType) != "no" && t.canPlayType("audio/" + playType) != "");
		}  // OJR another way to do this might be canPlayType:"m4a", codex: mp4

		// 0=no output, 1=mono, 2=stereo, 4=surround, 6=5.1 surround.
		// See http://www.w3.org/TR/webaudio/#AudioChannelSplitter for more details on channels.
		if (s.context.destination.numberOfChannels < 2) {
			s.capabilities.panning = false;
		}

		// set up AudioNodes that all of our source audio will connect to
		s.dynamicsCompressorNode = s.context.createDynamicsCompressor();
		s.dynamicsCompressorNode.connect(s.context.destination);
		s.gainNode = s.context.createGain();
		s.gainNode.connect(s.dynamicsCompressorNode);
	};

	/**
	 * Set up compatibility if only deprecated web audio calls are supported.
	 * See http://www.w3.org/TR/webaudio/#DeprecationNotes
	 * Needed so we can support new browsers that don't support deprecated calls (Firefox) as well as old browsers that
	 * don't support new calls.
	 *
	 * @method compatibilitySetUp
	 * @protected
	 * @since 0.4.2
	 */
	s.compatibilitySetUp = function() {
		//assume that if one new call is supported, they all are
		if (s.context.createGain) { return; }

		// simple name change, functionality the same
		s.context.createGain = s.context.createGainNode;

		// source node, add to prototype
		var audioNode = s.context.createBufferSource();
		audioNode.__proto__.start = audioNode.__proto__.noteGrainOn;	// note that noteGrainOn requires all 3 parameters
		audioNode.__proto__.stop = audioNode.__proto__.noteOff;

		// panningModel
		this.panningModel = 0;
	};

	/**
	 * Plays an empty sound in the web audio context.  This is used to enable web audio on iOS devices, as they
	 * require the first sound to be played inside of a user initiated event (touch/click).  This is called when
	 * {{#crossLink "WebAudioPlugin"}}{{/crossLink}} is initialized (by Sound {{#crossLink "Sound/initializeDefaultPlugins"}}{{/crossLink}}
	 * for example).
	 *
	 * <h4>Example</h4>
	 *
	 *     function handleTouch(event) {
	 *         createjs.WebAudioPlugin.playEmptySound();
	 *     }
	 *
	 * @method playEmptySound
	 * @since 0.4.1
	 */
	s.playEmptySound = function() {
		// create empty buffer
		var buffer = this.context.createBuffer(1, 1, 22050);
		var source = this.context.createBufferSource();
		source.buffer = buffer;

		// connect to output (your speakers)
		source.connect(this.context.destination);

		// play the file
		source.start(0, 0, 0);
	};


	var p = WebAudioPlugin.prototype;

	p.capabilities = null; // doc'd above

	/**
	 * The internal volume value of the plugin.
	 * @property volume
	 * @type {Number}
	 * @default 1
	 * @protected
	 */
	// TODO refactor Sound.js so we can use getter setter for volume
	p.volume = 1;

	/**
	 * The web audio context, which WebAudio uses to play audio. All nodes that interact with the WebAudioPlugin
	 * need to be created within this context.
	 * @property context
	 * @type {AudioContext}
	 */
	p.context = null;

	/**
	 * Value to set panning model to equal power for SoundInstance.  Can be "equalpower" or 0 depending on browser implementation.
	 * @property panningModel
	 * @type {Number / String}
	 * @protected
	 */
	p.panningModel = "equalpower";

	/**
	 * A DynamicsCompressorNode, which is used to improve sound quality and prevent audio distortion according to
	 * http://www.w3.org/TR/webaudio/#DynamicsCompressorNode. It is connected to <code>context.destination</code>.
	 * @property dynamicsCompressorNode
	 * @type {AudioNode}
	 */
	p.dynamicsCompressorNode = null;

	/**
	 * A GainNode for controlling master volume. It is connected to {{#crossLink "WebAudioPlugin/dynamicsCompressorNode:property"}}{{/crossLink}}.
	 * @property gainNode
	 * @type {AudioGainNode}
	 */
	p.gainNode = null;

	/**
	 * An object hash used internally to store ArrayBuffers, indexed by the source URI used  to load it. This
	 * prevents having to load and decode audio files more than once. If a load has been started on a file,
	 * <code>arrayBuffers[src]</code> will be set to true. Once load is complete, it is set the the loaded
	 * ArrayBuffer instance.
	 * @property arrayBuffers
	 * @type {Object}
	 * @protected
	 */
	p.arrayBuffers = null;

	/**
	 * An initialization function run by the constructor
	 * @method init
	 * @protected
	 */
	p.init = function () {
		this.capabilities = s.capabilities;
		this.arrayBuffers = {};

		this.context = s.context;
		this.gainNode = s.gainNode;
		this.dynamicsCompressorNode = s.dynamicsCompressorNode;
	};

	/**
	 * Pre-register a sound for preloading and setup. This is called by {{#crossLink "Sound"}}{{/crossLink}}.
	 * Note that WebAudio provides a <code>Loader</code> instance, which <a href="http://preloadjs.com">PreloadJS</a>
	 * can use to assist with preloading.
	 * @method register
	 * @param {String} src The source of the audio
	 * @param {Number} instances The number of concurrently playing instances to allow for the channel at any time.
	 * Note that the WebAudioPlugin does not manage this property.
	 * @return {Object} A result object, containing a "tag" for preloading purposes.
	 */
	p.register = function (src, instances) {
		this.arrayBuffers[src] = true;  // This is needed for PreloadJS
		var tag = new createjs.WebAudioPlugin.Loader(src, this);
		return {
			tag:tag
		};
	};

	/**
	 * Checks if preloading has started for a specific source. If the source is found, we can assume it is loading,
	 * or has already finished loading.
	 * @method isPreloadStarted
	 * @param {String} src The sound URI to check.
	 * @return {Boolean}
	 */
	p.isPreloadStarted = function (src) {
		return (this.arrayBuffers[src] != null);
	};

	/**
	 * Checks if preloading has finished for a specific source.
	 * @method isPreloadComplete
	 * @param {String} src The sound URI to load.
	 * @return {Boolean}
	 */
	p.isPreloadComplete = function (src) {
		return (!(this.arrayBuffers[src] == null || this.arrayBuffers[src] == true));
	};

	/**
	 * Remove a source from our preload list. Note this does not cancel a preload.
	 * @method removeFromPreload
	 * @param {String} src The sound URI to unload.
	 * @deprecated
	 */
	p.removeFromPreload = function (src) {
		delete(this.arrayBuffers[src]);
	};

	/**
	 * Remove a sound added using {{#crossLink "WebAudioPlugin/register"}}{{/crossLink}}. Note this does not cancel a preload.
	 * @method removeSound
	 * @param {String} src The sound URI to unload.
	 * @since 0.4.1
	 */
	p.removeSound = function (src) {
		delete(this.arrayBuffers[src]);
	};

	/**
	 * Remove all sounds added using {{#crossLink "WebAudioPlugin/register"}}{{/crossLink}}. Note this does not cancel a preload.
	 * @method removeAllSounds
	 * @param {String} src The sound URI to unload.
	 * @since 0.4.1
	 */
	p.removeAllSounds = function () {
		this.arrayBuffers = {};
	};

	/**
	 * Add loaded results to the preload object hash.
	 * @method addPreloadResults
	 * @param {String} src The sound URI to unload.
	 * @return {Boolean}
	 */
	p.addPreloadResults = function (src, result) {
		this.arrayBuffers[src] = result;
	};

	/**
	 * Handles internal preload completion.
	 * @method handlePreloadComplete
	 * @protected
	 */
	p.handlePreloadComplete = function () {
		//LM: I would recommend having the Loader include an "event" in the onload, and properly binding this callback.
		createjs.Sound.sendFileLoadEvent(this.src);  // fire event or callback on Sound
		// note "this" will reference Loader object
	};

	/**
	 * Internally preload a sound. Loading uses XHR2 to load an array buffer for use with WebAudio.
	 * @method preload
	 * @param {String} src The sound URI to load.
	 * @param {Object} instance Not used in this plugin.
	 * @protected
	 */
	p.preload = function (src, instance) {
		this.arrayBuffers[src] = true;
		var loader = new createjs.WebAudioPlugin.Loader(src, this);
		loader.onload = this.handlePreloadComplete;
		loader.load();
	};

	/**
	 * Create a sound instance. If the sound has not been preloaded, it is internally preloaded here.
	 * @method create
	 * @param {String} src The sound source to use.
	 * @return {SoundInstance} A sound instance for playback and control.
	 */
	p.create = function (src) {
		if (!this.isPreloadStarted(src)) {
			this.preload(src);
		}
		return new createjs.WebAudioPlugin.SoundInstance(src, this);
	};

	/**
	 * Set the master volume of the plugin, which affects all SoundInstances.
	 * @method setVolume
	 * @param {Number} value The volume to set, between 0 and 1.
	 * @return {Boolean} If the plugin processes the setVolume call (true). The Sound class will affect all the
	 * instances manually otherwise.
	 */
	p.setVolume = function (value) {
		this.volume = value;
		this.updateVolume();
		return true;
	};

	/**
	 * Set the gain value for master audio. Should not be called externally.
	 * @method updateVolume
	 * @protected
	 */
	p.updateVolume = function () {
		var newVolume = createjs.Sound.masterMute ? 0 : this.volume;
		if (newVolume != this.gainNode.gain.value) {
			this.gainNode.gain.value = newVolume;
		}
	};

	/**
	 * Get the master volume of the plugin, which affects all SoundInstances.
	 * @method getVolume
	 * @return The volume level, between 0 and 1.
	 */
	p.getVolume = function () {
		return this.volume;
	};

	/**
	 * Mute all sounds via the plugin.
	 * @method setMute
	 * @param {Boolean} value If all sound should be muted or not. Note that plugin-level muting just looks up
	 * the mute value of Sound {{#crossLink "Sound/getMute"}}{{/crossLink}}, so this property is not used here.
	 * @return {Boolean} If the mute call succeeds.
	 */
	p.setMute = function (value) {
		this.updateVolume();
		return true;
	};

	p.toString = function () {
		return "[WebAudioPlugin]";
	};

	createjs.WebAudioPlugin = WebAudioPlugin;
}());

(function () {

	"use strict";

	/**
	 * A SoundInstance is created when any calls to the Sound API method {{#crossLink "Sound/play"}}{{/crossLink}} or
	 * {{#crossLink "Sound/createInstance"}}{{/crossLink}} are made. The SoundInstance is returned by the active plugin
	 * for control by the user.
	 *
	 * <h4>Example</h4>
	 *
	 *      var myInstance = createjs.Sound.play("myAssetPath/mySrcFile.mp3");
	 *
	 * A number of additional parameters provide a quick way to determine how a sound is played. Please see the Sound
	 * API method {{#crossLink "Sound/play"}}{{/crossLink}} for a list of arguments.
	 *
	 * Once a SoundInstance is created, a reference can be stored that can be used to control the audio directly through
	 * the SoundInstance. If the reference is not stored, the SoundInstance will play out its audio (and any loops), and
	 * is then de-referenced from the {{#crossLink "Sound"}}{{/crossLink}} class so that it can be cleaned up. If audio
	 * playback has completed, a simple call to the {{#crossLink "SoundInstance/play"}}{{/crossLink}} instance method
	 * will rebuild the references the Sound class need to control it.
	 *
	 *      var myInstance = createjs.Sound.play("myAssetPath/mySrcFile.mp3");
	 *      myInstance.addEventListener("complete", playAgain);
	 *      function playAgain(event) {
	 *          myInstance.play();
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
	 * @class SoundInstance
	 * @param {String} src The path to and file name of the sound.
	 * @param {Object} owner The plugin instance that created this SoundInstance.
	 * @extends EventDispatcher
	 * @constructor
	 */
	function SoundInstance(src, owner) {
		this.init(src, owner);
	}

	var p = SoundInstance.prototype = new createjs.EventDispatcher();

	/**
	 * The source of the sound.
	 * @property src
	 * @type {String}
	 * @default null
	 * @protected
	 */
	p.src = null;

	/**
	 * The unique ID of the instance. This is set by {{#crossLink "Sound"}}{{/crossLink}}.
	 * @property uniqueId
	 * @type {String} | Number
	 * @default -1
	 */
	p.uniqueId = -1;

	/**
	 * The play state of the sound. Play states are defined as constants on {{#crossLink "Sound"}}{{/crossLink}}.
	 * @property playState
	 * @type {String}
	 * @default null
	 */
	p.playState = null;

	/**
	 * The plugin that created the instance
	 * @property owner
	 * @type {WebAudioPlugin}
	 * @default null
	 * @protected
	 */
	p.owner = null;

	/**
	 * How far into the sound to begin playback in milliseconds. This is passed in when play is called and used by
	 * pause and setPosition to track where the sound should be at.
	 * Note this is converted from milliseconds to seconds for consistency with the WebAudio API.
	 * @property offset
	 * @type {Number}
	 * @default 0
	 * @protected
	 */
	p.offset = 0;

	/**
	 * The time in milliseconds before the sound starts.
	 * Note this is handled by {{#crossLink "Sound"}}{{/crossLink}}.
	 * @property delay
	 * @type {Number}
	 * @default 0
	 * @protected
	 */
	p.delay = 0;


	/**
	 * The volume of the sound, between 0 and 1.
	 * Note this uses a getter setter, which is not supported by Firefox versions 3.6 or lower and Opera versions 11.50 or lower,
	 * and Internet Explorer 8 or lower.  Instead use {{#crossLink "SoundInstance/setVolume"}}{{/crossLink}} and {{#crossLink "SoundInstance/getVolume"}}{{/crossLink}}.
	 *
	 * The actual output volume of a sound can be calculated using:
	 * <code>myInstance.volume * createjs.Sound.getVolume();</code>
	 *
	 * @property volume
	 * @type {Number}
	 * @default 1
	 */
	p._volume =  1;
	// IE8 has Object.defineProperty, but only for DOM objects, so check if fails to suppress errors
	try {
		Object.defineProperty(p, "volume", {
		get: function() {
			return this._volume;
		},
		set: function(value) {
			if (Number(value) == null) {return false}
			value = Math.max(0, Math.min(1, value));
			this._volume = value;
			this.updateVolume();
		}
		});
	} catch (e) {
		// dispatch message or error?
	};

	/**
	 * The pan of the sound, between -1 (left) and 1 (right). Note that pan does not work for HTML Audio.
	 * Note this uses a getter setter, which is not supported by Firefox versions 3.6 or lower, Opera versions 11.50 or lower,
	 * and Internet Explorer 8 or lower.  Instead use {{#crossLink "SoundInstance/setPan"}}{{/crossLink}} and {{#crossLink "SoundInstance/getPan"}}{{/crossLink}}.
	 * Note in WebAudioPlugin this only gives us the "x" value of what is actually 3D audio.
	 *
	 * @property pan
	 * @type {Number}
	 * @default 0
	 */
	p._pan =  0;
	// IE8 has Object.defineProperty, but only for DOM objects, so check if fails to suppress errors
	try {
		Object.defineProperty(p, "pan", {
			get: function() {
				return this._pan;
			},
			set: function(value) {
				if (!this.owner.capabilities.panning || Number(value) == null) {return false;}

				value = Math.max(-1, Math.min(1, value));	// force pan to stay in the -1 to 1 range
				// Note that panning in WebAudioPlugin can support 3D audio, but our implementation does not.
				this._pan = value;  // Unfortunately panner does not give us a way to access this after it is set http://www.w3.org/TR/webaudio/#AudioPannerNode
				this.panNode.setPosition(value, 0, -0.5);  // z need to be -0.5 otherwise the sound only plays in left, right, or center
			}
		});
	} catch (e) {
		// dispatch message or error?
	};


/**
	 * The length of the audio clip, in milliseconds.
	 * Use {{#crossLink "SoundInstance/getDuration:method"}}{{/crossLink}} to access.
	 * @property pan
	 * @type {Number}
	 * @default 0
	 * @protected
	 */
	p.duration = 0;

	/**
	 * The number of play loops remaining. Negative values will loop infinitely.
	 * @property remainingLoops
	 * @type {Number}
	 * @default 0
	 * @protected
	 */
	p.remainingLoops = 0;

	/**
	 * A Timeout created by {{#crossLink "Sound"}}{{/crossLink}} when this SoundInstance is played with a delay.
	 * This allows SoundInstance to remove the delay if stop or pause or cleanup are called before playback begins.
	 * @property delayTimeoutId
	 * @type {timeoutVariable}
	 * @default null
	 * @protected
	 * @since 0.4.0
	 */
	p.delayTimeoutId = null;

	/**
	 * Timeout that is created internally to handle sound playing to completion. Stored so we can remove it when
	 * stop, pause, or cleanup are called
	 * @property soundCompleteTimeout
	 * @type {timeoutVariable}
	 * @default null
	 * @protected
	 * @since 0.4.0
	 */
	p.soundCompleteTimeout = null;

	/**
	 * NOTE this only exists as a {{#crossLink "WebAudioPlugin"}}{{/crossLink}} property and is only intended for use by advanced users.
	 * GainNode for controlling <code>SoundInstance</code> volume. Connected to the WebAudioPlugin {{#crossLink "WebAudioPlugin/gainNode:property"}}{{/crossLink}}
	 * that sequences to <code>context.destination</code>.
	 * @property gainNode
	 * @type {AudioGainNode}
	 * @default null
	 * @since 0.4.0
	 *
	 */
	p.gainNode = null;

	/**
	 * NOTE this only exists as a {{#crossLink "WebAudioPlugin"}}{{/crossLink}} property and is only intended for use by advanced users.
	 * A panNode allowing left and right audio channel panning only. Connected to SoundInstance {{#crossLink "SoundInstance/gainNode:property"}}{{/crossLink}}.
	 * @property panNode
	 * @type {AudioPannerNode}
	 * @default null
	 * @since 0.4.0
	 */
	p.panNode = null;

	/**
	 * NOTE this only exists as a {{#crossLink "WebAudioPlugin"}}{{/crossLink}} property and is only intended for use by advanced users.
	 * sourceNode is the audio source. Connected to {{#crossLink "SoundInstance/gainNode:property"}}{{/crossLink}}.
	 * @property sourceNode
	 * @type {AudioNode}
	 * @default null
	 * @since 0.4.0
	 *
	 */
	p.sourceNode = null;

	/**
	 * NOTE this only exists as a {{#crossLink "WebAudioPlugin"}}{{/crossLink}} property and is only intended for use by advanced users.
	 * sourceNodeNext is the audio source for the next loop, inserted in a look ahead approach to allow for smooth
	 * looping. Connected to {{#crossLink "SoundInstance/gainNode:property"}}{{/crossLink}}.
	 * @property sourceNodeNext
	 * @type {AudioNode}
	 * @default null
	 * @protected
	 * @since 0.4.1
	 *
	 */
	p.sourceNodeNext = null;

	/**
	 * Determines if the audio is currently muted.
	 * Use {{#crossLink "SoundInstance/getMute:method"}}{{/crossLink}} and {{#crossLink "SoundInstance/setMute:method"}}{{/crossLink}} to access.
	 * @property muted
	 * @type {Boolean}
	 * @default false
	 * @protected
	 */
	p.muted = false;

	/**
	 * Determines if the audio is currently paused.
	 * Use {{#crossLink "SoundInstance/pause:method"}}{{/crossLink}} and {{#crossLink "SoundInstance/resume:method"}}{{/crossLink}} to set.
	 * @property paused
	 * @type {Boolean}
	 * @default false
	 * @protected
	 */
	p.paused = false;

	/**
	 * WebAudioPlugin only.
	 * Time audio started playback, in seconds. Used to handle set position, get position, and resuming from paused.
	 * @property startTime
	 * @type {Number}
	 * @default 0
	 * @protected
	 * @since 0.4.0
	 */
	p.startTime = 0;

	// Proxies, make removing listeners easier.
	p.endedHandler = null;
	p.readyHandler = null;
	p.stalledHandler = null;

// Events
	/**
	 * The event that is fired when a sound is ready to play.
	 * @event ready
	 * @param {Object} target The object that dispatched the event.
	 * @param {String} type The event type.
	 * @since 0.4.0
	 */

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

	//TODO: Deprecated
	/**
	 * REMOVED. Use {{#crossLink "EventDispatcher/addEventListener"}}{{/crossLink}} and the {{#crossLink "SoundInstance/ready:event"}}{{/crossLink}}
	 * event.
	 * @property onReady
	 * @type {Function}
	 * @deprecated Use addEventListener and the "ready" event.
	 */
	/**
	 * REMOVED. Use {{#crossLink "EventDispatcher/addEventListener"}}{{/crossLink}} and the {{#crossLink "SoundInstance/succeeded:event"}}{{/crossLink}}
	 * event.
	 * @property onPlaySucceeded
	 * @type {Function}
	 * @deprecated Use addEventListener and the "succeeded" event.
	 */
	/**
	 * REMOVED. Use {{#crossLink "EventDispatcher/addEventListener"}}{{/crossLink}} and the {{#crossLink "SoundInstance/interrupted:event"}}{{/crossLink}}
	 * event.
	 * @property onPlayInterrupted
	 * @type {Function}
	 * @deprecated Use addEventListener and the "interrupted" event.
	 */
	/**
	 * REMOVED. Use {{#crossLink "EventDispatcher/addEventListener"}}{{/crossLink}} and the {{#crossLink "SoundInstance/failed:event"}}{{/crossLink}}
	 * event.
	 * @property onPlayFailed
	 * @type {Function}
	 * @deprecated Use addEventListener and the "failed" event.
	 */
	/**
	 * REMOVED. Use {{#crossLink "EventDispatcher/addEventListener"}}{{/crossLink}} and the {{#crossLink "SoundInstance/complete:event"}}{{/crossLink}}
	 * event.
	 * @property onComplete
	 * @type {Function}
	 * @deprecated Use addEventListener and the "complete" event.
	 */
	/**
	 * REMOVED. Use {{#crossLink "EventDispatcher/addEventListener"}}{{/crossLink}} and the {{#crossLink "SoundInstance/loop:event"}}{{/crossLink}}
	 * event.
	 * @property onLoop
	 * @type {Function}
	 * @deprecated Use addEventListener and the "loop" event.
	 */

	/**
	 * A helper method that dispatches all events for SoundInstance.
	 * @method sendEvent
	 * @param {String} type The event type
	 * @protected
	 */
	p.sendEvent = function (type) {
		var event = new createjs.Event(type);
		this.dispatchEvent(event);
	};

// Constructor
	/**
	 * Initialize the SoundInstance. This is called from the constructor.
	 * @method init
	 * @param {string} src The source of the audio.
	 * @param {Class} owner The plugin that created this instance.
	 * @protected
	 */
	p.init = function (src, owner) {
		this.owner = owner;
		this.src = src;

		this.gainNode = this.owner.context.createGain();

		this.panNode = this.owner.context.createPanner();  //TODO test how this affects when we have mono audio
		this.panNode.panningModel = this.owner.panningModel;
		this.panNode.connect(this.gainNode);

		if (this.owner.isPreloadComplete(this.src)) {
			this.duration = this.owner.arrayBuffers[this.src].duration * 1000;
		}

		this.endedHandler = createjs.proxy(this.handleSoundComplete, this);
		this.readyHandler = createjs.proxy(this.handleSoundReady, this);
		this.stalledHandler = createjs.proxy(this.handleSoundStalled, this);
	};

	/**
	 * Clean up the instance. Remove references and clean up any additional properties such as timers.
	 * @method cleanup
	 * @protected
	 */
	p.cleanUp = function () {
		if (this.sourceNode && this.playState == createjs.Sound.PLAY_SUCCEEDED) {
			this.sourceNode = this.cleanUpAudioNode(this.sourceNode);
			this.sourceNodeNext = this.cleanUpAudioNode(this.sourceNodeNext);
		}

		if (this.gainNode.numberOfOutputs != 0) {
			this.gainNode.disconnect(0);
		}  // this works because we only have one connection, and it returns 0 if we've already disconnected it.
		// OJR there appears to be a bug that this doesn't always work in webkit (Chrome and Safari). According to the documentation, this should work.

		clearTimeout(this.delayTimeoutId); // clear timeout that plays delayed sound
		clearTimeout(this.soundCompleteTimeout);  // clear timeout that triggers sound complete

		this.startTime = 0;	// This is used by getPosition

		if (window.createjs == null) {
			return;
		}
		createjs.Sound.playFinished(this);
	};

	/**
	 * Turn off and disconnect an audioNode, then set reference to null to release it for garbage collection
	 * @param audioNode
	 * @return {audioNode}
	 * @protected
	 * @since 0.4.1
	 */
	p.cleanUpAudioNode = function(audioNode) {
		if(audioNode) {
			audioNode.stop(0);
			audioNode.disconnect(this.panNode);
			audioNode = null;	// release reference so Web Audio can handle removing references and garbage collection
		}
		return audioNode;
	};

	/**
	 * The sound has been interrupted.
	 * @method interrupt
	 * @protected
	 */
	p.interrupt = function () {
		this.cleanUp();
		this.playState = createjs.Sound.PLAY_INTERRUPTED;
		this.paused = false;
		this.sendEvent("interrupted");
	};

	// Playback has stalled, and therefore failed.
	p.handleSoundStalled = function (event) {
		this.sendEvent("failed");
	};

	// The sound is ready for playing
	p.handleSoundReady = function (event) {
		if (window.createjs == null) {
			return;
		}

		if ((this.offset*1000) > this.getDuration()) {	// converting offset to ms
			this.playFailed();
			return;
		} else if (this.offset < 0) {  // may not need this check if play ignores negative values, this is not specified in the API http://www.w3.org/TR/webaudio/#AudioBufferSourceNode
			this.offset = 0;
		}

		this.playState = createjs.Sound.PLAY_SUCCEEDED;
		this.paused = false;

		this.gainNode.connect(this.owner.gainNode);  // this line can cause a memory leak.  Nodes need to be disconnected from the audioDestination or any sequence that leads to it.

		var dur = this.owner.arrayBuffers[this.src].duration;
		this.sourceNode = this.createAndPlayAudioNode((this.owner.context.currentTime - dur), this.offset);
		this.duration = dur * 1000;	// NOTE *1000 because WebAudio reports everything in seconds but js uses milliseconds
		this.startTime = this.sourceNode.startTime - this.offset;

		this.soundCompleteTimeout = setTimeout(this.endedHandler, (dur - this.offset) * 1000);

		if(this.remainingLoops != 0) {
			this.sourceNodeNext = this.createAndPlayAudioNode(this.startTime, 0);
		}
	};

	/**
	 * Creates an audio node using the current src and context, connects it to the gain node, and starts playback.
	 * @method createAudioNode
	 * @param {Number} startTime The time to add this to the web audio context, in seconds.
	 * @param {Number} offset The amount of time into the src audio to start playback, in seconds.
	 * @return {audioNode}
	 * @protected
	 * @since 0.4.1
	 */
	p.createAndPlayAudioNode = function(startTime, offset) {
		// WebAudio supports BufferSource, MediaElementSource, and MediaStreamSource.
		// NOTE MediaElementSource requires different commands to play, pause, and stop because it uses audio tags.
		// The same is assumed for MediaStreamSource, although it may share the same commands as MediaElementSource.
		var audioNode = this.owner.context.createBufferSource();
		audioNode.buffer = this.owner.arrayBuffers[this.src];
		audioNode.connect(this.panNode);
		var currentTime = this.owner.context.currentTime;
		audioNode.startTime = startTime + audioNode.buffer.duration;	//currentTime + audioNode.buffer.duration - (currentTime - startTime);
		audioNode.start(audioNode.startTime, offset, audioNode.buffer.duration - offset);
		return audioNode;
	};

	// Public API
	/**
	 * Play an instance. This method is intended to be called on SoundInstances that already exist (created
	 * with the Sound API {{#crossLink "Sound/createInstance"}}{{/crossLink}} or {{#crossLink "Sound/play"}}{{/crossLink}}).
	 *
	 * <h4>Example</h4>
	 *      var myInstance = createjs.Sound.createInstance(mySrc);
	 *      myInstance.play(createjs.Sound.INTERRUPT_ANY);
	 *      // alternatively, we can pass in options we want to set in an object
	 *      myInstance.play({offset:1, loop:2, pan:0.5});
	 *
	 * @method play
	 * @param {String | Object} [interrupt="none"|options] How to interrupt any currently playing instances of audio with the same source,
	 * if the maximum number of instances of the sound are already playing. Values are defined as <code>INTERRUPT_TYPE</code>
	 * constants on the Sound class, with the default defined by {{#crossLink "Sound/defaultInterruptBehavior"}}{{/crossLink}}.
	 * <br /><strong>OR</strong><br />
	 * This parameter can be an object that contains any or all optional properties by name, including: interrupt,
	 * delay, offset, loop, volume, and pan (see the above code sample).
	 * @param {Number} [delay=0] The delay in milliseconds before the sound starts
	 * @param {Number} [offset=0] How far into the sound to begin playback, in milliseconds.
	 * @param {Number} [loop=0] The number of times to loop the audio. Use -1 for infinite loops.
	 * @param {Number} [volume=1] The volume of the sound, between 0 and 1.
	 * @param {Number} [pan=0] The pan of the sound between -1 (left) and 1 (right). Note that pan is not supported
	 * for HTML Audio.
	 */
	p.play = function (interrupt, delay, offset, loop, volume, pan) {
		this.cleanUp();
		createjs.Sound.playInstance(this, interrupt, delay, offset, loop, volume, pan);
	};

	/**
	 * Called by the Sound class when the audio is ready to play (delay has completed). Starts sound playing if the
	 * src is loaded, otherwise playback will fail.
	 * @method beginPlaying
	 * @param {Number} offset How far into the sound to begin playback, in milliseconds.
	 * @param {Number} loop The number of times to loop the audio. Use -1 for infinite loops.
	 * @param {Number} volume The volume of the sound, between 0 and 1.
	 * @param {Number} pan The pan of the sound between -1 (left) and 1 (right). Note that pan does not work for HTML Audio.
	 * @protected
	 */
	p.beginPlaying = function (offset, loop, volume, pan) {
		if (window.createjs == null) {
			return;
		}

		if (!this.src) {
			return;
		}

		this.offset = offset / 1000;  //convert ms to sec
		this.remainingLoops = loop;
		this.volume = volume;
		this.pan = pan;

		if (this.owner.isPreloadComplete(this.src)) {
			this.handleSoundReady(null);
			this.sendEvent("succeeded");
			return 1;
		} else {
			this.playFailed();
			return;
		}
	};

	/**
	 * Pause the instance. Paused audio will stop at the current time, and can be resumed using
	 * {{#crossLink "SoundInstance/resume"}}{{/crossLink}}.
	 *
	 * <h4>Example</h4>
	 *
	 *      myInstance.pause();
	 *
	 * @method pause
	 * @return {Boolean} If the pause call succeeds. This will return false if the sound isn't currently playing.
	 */
	p.pause = function () {
		if (!this.paused && this.playState == createjs.Sound.PLAY_SUCCEEDED) {
			this.paused = true;

			this.offset = this.owner.context.currentTime - this.startTime;  // this allows us to restart the sound at the same point in playback
			this.cleanUpAudioNode(this.sourceNode);
			this.cleanUpAudioNode(this.sourceNodeNext);

			if (this.gainNode.numberOfOutputs != 0) {
				this.gainNode.disconnect();
			}  // this works because we only have one connection, and it returns 0 if we've already disconnected it.

			clearTimeout(this.delayTimeoutId); // clear timeout that plays delayed sound
			clearTimeout(this.soundCompleteTimeout);  // clear timeout that triggers sound complete
			return true;
		}
		return false;
	};

	/**
	 * Resume an instance that has been paused using {{#crossLink "SoundInstance/pause"}}{{/crossLink}}. Audio that
	 * has not been paused will not playback when this method is called.
	 *
	 * <h4>Example</h4>
	 *
	 *     myInstance.pause();
	 *     // do some stuff
	 *     myInstance.resume();
	 *
	 * @method resume
	 * @return {Boolean} If the resume call succeeds. This will return false if called on a sound that is not paused.
	 */
	p.resume = function () {
		if (!this.paused) {
			return false;
		}
		this.handleSoundReady(null);
		return true;
	};

	/**
	 * Stop playback of the instance. Stopped sounds will reset their position to 0, and calls to {{#crossLink "SoundInstance/resume"}}{{/crossLink}}
	 * will fail.  To start playback again, call {{#crossLink "SoundInstance/play"}}{{/crossLink}}.
	 *
	 * <h4>Example</h4>
	 *
	 *     myInstance.stop();
	 *
	 * @method stop
	 * @return {Boolean} If the stop call succeeds.
	 */
	p.stop = function () {
		this.cleanUp();
		this.playState = createjs.Sound.PLAY_FINISHED;
		this.offset = 0;  // set audio to start at the beginning
		return true;
	};

	/**
	 * NOTE that you can set volume directly, and setVolume remains to allow support for IE8 with FlashPlugin.
	 * Set the volume of the instance. You can retrieve the volume using {{#crossLink "SoundInstance/getVolume"}}{{/crossLink}}.
	 *
	 * <h4>Example</h4>
	 *
	 *      myInstance.setVolume(0.5);
	 *
	 * Note that the master volume set using the Sound API method {{#crossLink "Sound/setVolume"}}{{/crossLink}}
	 * will be applied to the instance volume.
	 *
	 * @method setVolume
	 * @param value The volume to set, between 0 and 1.
	 * @return {Boolean} If the setVolume call succeeds.
	 */
	p.setVolume = function (value) {
		this.volume = value;
		return true;  // This is always true because even if the volume is not updated, the value is set
	};

	/**
	 * Internal function used to update the volume based on the instance volume, master volume, instance mute value,
	 * and master mute value.
	 * @method updateVolume
	 * @return {Boolean} if the volume was updated.
	 * @protected
	 */
	p.updateVolume = function () {
		var newVolume = this.muted ? 0 : this._volume;
		if (newVolume != this.gainNode.gain.value) {
			this.gainNode.gain.value = newVolume;
			return true;
		}
		return false;
	};

	/**
	 * NOTE that you can get volume directly, and getVolume remains to allow support for IE8 with FlashPlugin.
	 *
	 * Get the volume of the instance. The actual output volume of a sound can be calculated using:
	 * <code>myInstance.getVolume() * createjs.Sound.getVolume();</code>
	 *
	 * @method getVolume
	 * @return The current volume of the sound instance.
	 */
	p.getVolume = function () {
		return this.volume;
	};

	/**
	 * REMOVED. <strong>Please use {{#crossLink "SoundInstance/setMute"}}{{/crossLink}} instead</strong>.
	 * @method mute
	 * @param {Boolean} value If the sound should be muted or not.
	 * @return {Boolean} If the mute call succeeds.
	 * @deprecated This method has been replaced by setMute.
	 */

	/**
	 * Mute and unmute the sound. Muted sounds will still play at 0 volume. Note that an unmuted sound may still be
	 * silent depending on {{#crossLink "Sound"}}{{/crossLink}} volume, instance volume, and Sound mute.
	 *
	 * <h4>Example</h4>
	 *
	 *     myInstance.setMute(true);
	 *
	 * @method setMute
	 * @param {Boolean} value If the sound should be muted.
	 * @return {Boolean} If the mute call succeeds.
	 * @since 0.4.0
	 */
	p.setMute = function (value) {
		if (value == null || value == undefined) {
			return false;
		}

		this.muted = value;
		this.updateVolume();
		return true;
	};

	/**
	 * Get the mute value of the instance.
	 *
	 * <h4>Example</h4>
	 *
	 *      var isMuted = myInstance.getMute();
	 *
	 * @method getMute
	 * @return {Boolean} If the sound is muted.
	 * @since 0.4.0
	 */
	p.getMute = function () {
		return this.muted;
	};

	/**
	 * NOTE that you can set pan directly, and getPan remains to allow support for IE8 with FlashPlugin.
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
	 * @return {Number} If the setPan call succeeds.
	 */
	p.setPan = function (value) {
		this.pan = value;  // Unfortunately panner does not give us a way to access this after it is set http://www.w3.org/TR/webaudio/#AudioPannerNode
		if(this.pan != value) {return false;}
	};

	/**
	 * NOTE that you can get volume directly, and getPan remains to allow support for IE8 with FlashPlugin.
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
		return this.pan;
	};

	/**
	 * Get the position of the playhead in the instance in milliseconds.
	 *
	 * <h4>Example</h4>
	 *
	 *     var currentOffset = myInstance.getPosition();
	 *
	 * @method getPosition
	 * @return {Number} The position of the playhead in the sound, in milliseconds.
	 */
	p.getPosition = function () {
		if (this.paused || this.sourceNode == null) {
			var pos = this.offset;
		} else {
			var pos = this.owner.context.currentTime - this.startTime;
		}

		return pos * 1000; // pos in seconds * 1000 to give milliseconds
	};

	/**
	 * Set the position of the playhead in the instance. This can be set while a sound is playing, paused, or even
	 * stopped.
	 *
	 * <h4>Example</h4>
	 *
	 *      myInstance.setPosition(myInstance.getDuration()/2); // set audio to its halfway point.
	 *
	 * @method setPosition
	 * @param {Number} value The position to place the playhead, in milliseconds.
	 */
	p.setPosition = function (value) {
		this.offset = value / 1000; // convert milliseconds to seconds

		if (this.sourceNode && this.playState == createjs.Sound.PLAY_SUCCEEDED) {
			// we need to stop this sound from continuing to play, as we need to recreate the sourceNode to change position
			this.cleanUpAudioNode(this.sourceNode);
			this.cleanUpAudioNode(this.sourceNodeNext);
			clearTimeout(this.soundCompleteTimeout);  // clear timeout that triggers sound complete
		}  // NOTE we cannot just call cleanup because it also calls the Sound function playFinished which releases this instance in SoundChannel

		if (!this.paused && this.playState == createjs.Sound.PLAY_SUCCEEDED) {
			this.handleSoundReady(null);
		}

		return true;
	};

	/**
	 * Get the duration of the instance, in milliseconds. Note in most cases, you need to play a sound using
	 * {{#crossLink "SoundInstance/play"}}{{/crossLink}} or the Sound API {{#crossLink "Sound.play"}}{{/crossLink}}
	 * method before its duration can be reported accurately.
	 *
	 * <h4>Example</h4>
	 *
	 *     var soundDur = myInstance.getDuration();
	 *
	 * @method getDuration
	 * @return {Number} The duration of the sound instance in milliseconds.
	 */
	p.getDuration = function () {
		return this.duration;
	};

	// Audio has finished playing. Manually loop it if required.
	// called internally by soundCompleteTimeout in WebAudioPlugin
	p.handleSoundComplete = function (event) {
		this.offset = 0;  // have to set this as it can be set by pause during playback


		if (this.remainingLoops != 0) {
			this.remainingLoops--;  // NOTE this introduces a theoretical limit on loops = float max size x 2 - 1

			// OJR we are using a look ahead approach to ensure smooth looping.  We add sourceNodeNext to the audio
			// context so that it starts playing even if this callback is delayed.  This technique and the reasons for
			// using it are described in greater detail here:  http://www.html5rocks.com/en/tutorials/audio/scheduling/
			// NOTE the cost of this is that our audio loop may not always match the loop event timing precisely.
			if(this.sourceNodeNext) { // this can be set to null, but this should not happen when looping
				this.cleanUpAudioNode(this.sourceNode);
				this.sourceNode = this.sourceNodeNext;
				this.startTime = this.sourceNode.startTime;
				this.sourceNodeNext = this.createAndPlayAudioNode(this.startTime, 0);
				this.soundCompleteTimeout = setTimeout(this.endedHandler, this.duration);
			}
			else {
				this.handleSoundReady(null);
			}

			this.sendEvent("loop");
			return;
		}

		if (window.createjs == null) {
			return;
		}
		this.cleanUp();
		this.playState = createjs.Sound.PLAY_FINISHED;
		this.sendEvent("complete");
	};

	// Play has failed, which can happen for a variety of reasons.
	p.playFailed = function () {
		if (window.createjs == null) {
			return;
		}
		this.cleanUp();
		this.playState = createjs.Sound.PLAY_FAILED;
		this.sendEvent("failed");
	};

	p.toString = function () {
		return "[WebAudioPlugin SoundInstance]";
	};

	createjs.WebAudioPlugin.SoundInstance = SoundInstance;
}());

(function () {

	"use strict";

	/**
	 * An internal helper class that preloads web audio via XHR. Note that this class and its methods are not documented
	 * properly to avoid generating HTML documentation.
	 * #class Loader
	 * @param {String} src The source of the sound to load.
	 * @param {Object} owner A reference to the class that created this instance.
	 * @constructor
	 */
	function Loader(src, owner) {
		this.init(src, owner);
	}

	var p = Loader.prototype;

	// the request object for or XHR2 request
	p.request = null;

	p.owner = null;
	p.progress = -1;

	/**
	 * The source of the sound to load. Used by callback functions when we return this class.
	 * #property src
	 * @type {String}
	 */
	p.src = null;

	/**
	 * The original source of the sound, before it is altered with a basePath.
	 * #property src
	 * @type {String}
	 */
	p.originalSrc = null;

	/**
	 * The decoded AudioBuffer array that is returned when loading is complete.
	 * #property result
	 * @type {AudioBuffer}
	 * @protected
	 */
	p.result = null;

	// Calbacks
	/**
	 * The callback that fires when the load completes. This follows HTML tag naming.
	 * #property onload
	 * @type {Method}
	 */
	p.onload = null;

	/**
	 * The callback that fires as the load progresses. This follows HTML tag naming.
	 * #property onprogress
	 * @type {Method}
	 */
	p.onprogress = null;

	/**
	 * The callback that fires if the load hits an error.
	 * #property onError
	 * @type {Method}
	 * @protected
	 */
	p.onError = null;

	// constructor
	p.init = function (src, owner) {
		this.src = src;
		this.originalSrc = src;
		this.owner = owner;
	};

	/**
	 * Begin loading the content.
	 * #method load
	 * @param {String} src The path to the sound.
	 */
	p.load = function (src) {
		if (src != null) {
			// TODO does this need to set this.originalSrc
			this.src = src;
		}

		this.request = new XMLHttpRequest();
		this.request.open("GET", this.src, true);
		this.request.responseType = "arraybuffer";
		this.request.onload = createjs.proxy(this.handleLoad, this);
		this.request.onError = createjs.proxy(this.handleError, this);
		this.request.onprogress = createjs.proxy(this.handleProgress, this);

		this.request.send();
	};

	/**
	 * The loader has reported progress.
	 *
	 * <strong>Note</strong>: this is not a public API, but is used to allow preloaders to subscribe to load
	 * progress as if this is an HTML audio tag. This reason is why this still uses a callback instead of an event.
	 * #method handleProgress
	 * @param {Number} loaded The loaded amount.
	 * @param {Number} total The total amount.
	 * @protected
	 */
	p.handleProgress = function (loaded, total) {
		this.progress = loaded / total;
		this.onprogress != null && this.onprogress({loaded:loaded, total:total, progress:this.progress});
	};

	/**
	 * The sound has completed loading.
	 * #method handleLoad
	 * @protected
	 */
	p.handleLoad = function () {
		this.owner.context.decodeAudioData(this.request.response,
				createjs.proxy(this.handleAudioDecoded, this),
				createjs.proxy(this.handleError, this));
	};

	/**
	 * The audio has been decoded.
	 * #method handleAudioDecoded
	 * @protected
	 */
	p.handleAudioDecoded = function (decodedAudio) {
		this.progress = 1;
		this.result = decodedAudio;
		this.src = this.originalSrc;
		this.owner.addPreloadResults(this.src, this.result);
		this.onload && this.onload();
	};

	/**
	 * Errors have been caused by the loader.
	 * #method handleError
	 * @protected
	 */
	p.handleError = function (evt) {
		this.owner.removeSound(this.src);
		this.onerror && this.onerror(evt);
	};

	p.toString = function () {
		return "[WebAudioPlugin Loader]";
	};

	createjs.WebAudioPlugin.Loader = Loader;

}());
/*
 * HTMLAudioPlugin
 * Visit http://createjs.com/ for documentation, updates and examples.
 *
 *
 * Copyright (c) 2012 gskinner.com, inc.
 *
 * Permission is hereby granted, free of charge, to any person
 * obtaining a copy of this software and associated documentation
 * files (the "Software"), to deal in the Software without
 * restriction, including without limitation the rights to use,
 * copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following
 * conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 * OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 * HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 * WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 * OTHER DEALINGS IN THE SOFTWARE.
 */

/**
 * @module SoundJS
 */

// namespace:
this.createjs = this.createjs || {};

(function () {

	"use strict";

	/**
	 * Play sounds using HTML &lt;audio&gt; tags in the browser. This plugin is the second priority plugin installed
	 * by default, after the {{#crossLink "WebAudioPlugin"}}{{/crossLink}}.  For older browsers that do not support html
	 * audio, include and install the {{#crossLink "FlashPlugin"}}{{/crossLink}}.
	 *
	 * <h4>Known Browser and OS issues for HTML Audio</h4>
	 * <b>All browsers</b><br />
	 * Testing has shown in all browsers there is a limit to how many audio tag instances you are allowed.  If you exceed
	 * this limit, you can expect to see unpredictable results.  This will be seen as soon as you register sounds, as
	 * tags are precreated to all Chrome to load them.  Please use {{#crossLink "Sound.MAX_INSTANCES"}}{{/crossLink}} as
	 * a guide to how many total audio tags you can safely use in all browsers.
	 *
     * <b>IE 9 html limitations</b><br />
     * <ul><li>There is a delay in applying volume changes to tags that occurs once playback is started. So if you have
     * muted all sounds, they will all play during this delay until the mute applies internally. This happens regardless of
     * when or how you apply the volume change, as the tag seems to need to play to apply it.</li>
     * <li>MP3 encoding will not always work for audio tags if it's not default.  We've found default encoding with
     * 64kbps works.</li>
	 * <li>There is a limit to how many audio tags you can load and play at once, which appears to be determined by
	 * hardware and browser settings.  See {{#crossLink "HTMLAudioPlugin.MAX_INSTANCES"}}{{/crossLink}} for a safe estimate.</li></ul>
	 *
	 * <b>Safari limitations</b><br />
	 * <ul><li>Safari requires Quicktime to be installed for audio playback.</li></ul>
	 *
	 * <b>iOS 6 limitations</b><br />
	 * Note it is recommended to use {{#crossLink "WebAudioPlugin"}}{{/crossLink}} for iOS (6+). HTML Audio is disabled by
	 * default as it can only have one &lt;audio&gt; tag, can not preload or autoplay the audio, can not cache the audio,
	 * and can not play the audio except inside a user initiated event.
	 *<br /><br />
	 * <b>Android HTML Audio limitations</b><br />
	 * <ul><li>We have no control over audio volume. Only the user can set volume on their device.</li>
	 *      <li>We can only play audio inside a user event (touch/click).  This currently means you cannot loop sound or use a delay.</li>
	 * <b> Android Chrome 26.0.1410.58 specific limitations</b><br />
	 * 		<li>Chrome reports true when you run createjs.Sound.BrowserDetect.isChrome, but is a different browser
	 *      with different abilities.</li>
	 *      <li>Can only play 1 sound at a time.</li>
	 *      <li>Sound is not cached.</li>
	 *      <li>Sound can only be loaded in a user initiated touch/click event.</li>
	 *      <li>There is a delay before a sound is played, presumably while the src is loaded.</li>
	 * </ul>
	 *
	 * See {{#crossLink "Sound"}}{{/crossLink}} for general notes on known issues.
	 *
	 * @class HTMLAudioPlugin
	 * @constructor
	 */
	function HTMLAudioPlugin() {
		this.init();
	}

	var s = HTMLAudioPlugin;

	/**
	 * The maximum number of instances that can be loaded and played. This is a browser limitation, primarily limited to IE9.
	 * The actual number varies from browser to browser (and is largely hardware dependant), but this is a safe estimate.
	 * @property MAX_INSTANCES
	 * @type {Number}
	 * @default 30
	 * @static
	 */
	s.MAX_INSTANCES = 30;

	/**
	 * The capabilities of the plugin. This is generated via the the SoundInstance {{#crossLink "HTMLAudioPlugin/generateCapabilities"}}{{/crossLink}}
	 * method. Please see the Sound {{#crossLink "Sound/getCapabilities"}}{{/crossLink}} method for an overview of all
	 * of the available properties.
	 * @property capabilities
	 * @type {Object}
	 * @protected
	 * @static
	 */
	s.capabilities = null;

	/**
	 * Event constant for the "canPlayThrough" event for cleaner code.
	 * @property AUDIO_READY
	 * @type {String}
	 * @default canplaythrough
	 * @static
	 */
	s.AUDIO_READY = "canplaythrough";

	/**
	 * Event constant for the "ended" event for cleaner code.
	 * @property AUDIO_ENDED
	 * @type {String}
	 * @default ended
	 * @static
	 */
	s.AUDIO_ENDED = "ended";

	/**
	 * Event constant for the "seeked" event for cleaner code.  We utilize this event for maintaining loop events.
	 * @property AUDIO_SEEKED
	 * @type {String}
	 * @default seeked
	 * @static
	 */
	s.AUDIO_SEEKED = "seeked";

	/**
	 * Event constant for the "error" event for cleaner code.
	 * @property AUDIO_ERROR
	 * @type {String}
	 * @default error
	 * @static
	 */
	s.AUDIO_ERROR = "error"; //TODO: Handle error cases

	/**
	 * Event constant for the "stalled" event for cleaner code.
	 * @property AUDIO_STALLED
	 * @type {String}
	 * @default stalled
	 * @static
	 */
	s.AUDIO_STALLED = "stalled";


	/**
	 * Allows users to enable HTML audio on IOS, which is disabled by default.
	 * Note this needs to be set before HTMLAudioPlugin is registered with SoundJS.
	 * This is not recommend because of severe limitations on IOS devices including:
	 * <li>it can only have one &lt;audio&gt; tag</li>
	 * <li>can not preload or autoplay the audio</li>
	 * <li>can not cache the audio</li>
	 * <li>can not play the audio except inside a user initiated event</li>
	 *
	 * @property enableIOS
	 * @type {Boolean}
	 * @default false
	 */
	s.enableIOS = false;

	/**
	 * Determine if the plugin can be used in the current browser/OS. Note that HTML audio is available in most modern
	 * browsers, but is disabled in iOS because of its limitations.
	 * @method isSupported
	 * @return {Boolean} If the plugin can be initialized.
	 * @static
	 */
	s.isSupported = function () {
		// HTML audio can be enable on iOS by removing this if statement, but it is not recommended due to the limitations:
		// iOS can only have a single <audio> instance, cannot preload or autoplay, cannot cache sound, and can only be
		// played in response to a user event (click)
		if (createjs.Sound.BrowserDetect.isIOS && !s.enableIOS) {
			return false;
		}
		s.generateCapabilities();
		var t = s.tag;  // OJR do we still need this check, when cap will already be null if this is the case
		if (t == null || s.capabilities == null) {
			return false;
		}
		return true;
	};

	/**
	 * Determine the capabilities of the plugin. Used internally. Please see the Sound API {{#crossLink "Sound/getCapabilities"}}{{/crossLink}}
	 * method for an overview of plugin capabilities.
	 * @method generateCapabiities
	 * @static
	 * @protected
	 */
	s.generateCapabilities = function () {
		if (s.capabilities != null) {
			return;
		}
		var t = s.tag = document.createElement("audio");
		if (t.canPlayType == null) {
			return null;
		}

		s.capabilities = {
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
			s.capabilities[ext] = (t.canPlayType("audio/" + ext) != "no" && t.canPlayType("audio/" + ext) != "") || (t.canPlayType("audio/" + playType) != "no" && t.canPlayType("audio/" + playType) != "");
		}  // OJR another way to do this might be canPlayType:"m4a", codex: mp4
	}

	var p = HTMLAudioPlugin.prototype;

	// doc'd above
	p.capabilities = null;

	/**
	 * Object hash indexed by the source of each file to indicate if an audio source is loaded, or loading.
	 * @property audioSources
	 * @type {Object}
	 * @protected
	 * @since 0.4.0
	 */
	p.audioSources = null;

	/**
	 * The default number of instances to allow.  Passed back to {{#crossLink "Sound"}}{{/crossLink}} when a source
	 * is registered using the {{#crossLink "Sound/register"}}{{/crossLink}} method.  This is only used if
	 * a value is not provided.
	 *
	 * <b>NOTE this property only exists as a limitation of HTML audio.</b>
	 * @property defaultNumChannels
	 * @type {Number}
	 * @default 2
	 * @since 0.4.0
	 */
	p.defaultNumChannels = 2;

	// Proxies, make removing listeners easier.
	p.loadedHandler = null;

	/**
	 * An initialization function run by the constructor
	 * @method init
	 * @protected
	 */
	p.init = function () {
		this.capabilities = s.capabilities;
		this.audioSources = {};
	};

	/**
	 * Pre-register a sound instance when preloading/setup. This is called by {{#crossLink "Sound"}}{{/crossLink}}.
	 * Note that this provides an object containing a tag used for preloading purposes, which
	 * <a href="http://preloadjs.com">PreloadJS</a> can use to assist with preloading.
	 * @method register
	 * @param {String} src The source of the audio
	 * @param {Number} instances The number of concurrently playing instances to allow for the channel at any time.
	 * @return {Object} A result object, containing a tag for preloading purposes and a numChannels value for internally
	 * controlling how many instances of a source can be played by default.
	 */
	p.register = function (src, instances) {
		this.audioSources[src] = true;  // Note this does not mean preloading has started
		var channel = createjs.HTMLAudioPlugin.TagPool.get(src);
		var tag = null;
		var l = instances || this.defaultNumChannels;
		for (var i = 0; i < l; i++) {  // OJR should we be enforcing s.MAX_INSTANCES here?  Does the chrome bug still exist, or can we change this code?
			tag = this.createTag(src);
			channel.add(tag);
		}

		tag.id = src;	// co-opting id as we need a way to store original src in case it is changed before loading
		this.loadedHandler = createjs.proxy(this.handleTagLoad, this);  // we need this bind to be able to remove event listeners
		tag.addEventListener && tag.addEventListener("canplaythrough", this.loadedHandler);
		if(tag.onreadystatechange == null) {
			tag.onreadystatechange = this.loadedHandler;
		} else {
			var f = tag.onreadystatechange;
			// OJR will this lose scope?
			tag.onreadystatechange = function() {
				f();
				this.loadedHandler();
			}
		}

		return {
			tag:tag, // Return one instance for preloading purposes
			numChannels:l  // The default number of channels to make for this Sound or the passed in value
		};
	};

	/**
	 * Checks if src was changed on tag used to create instances in TagPool before loading
	 * Currently PreloadJS does this when a basePath is set, so we are replicating that behavior for internal preloading.
	 * @method handleTagLoad
	 * @param event
	 * @protected
	 */
	p.handleTagLoad = function(event) {
		// cleanup and so we don't send the event more than once
		event.target.removeEventListener && event.target.removeEventListener("canplaythrough", this.loadedHandler);
		event.target.onreadystatechange = null;

		if (event.target.src == event.target.id) { return; }
		// else src has changed before loading, and we need to make the change to TagPool because we pre create tags
		createjs.HTMLAudioPlugin.TagPool.checkSrc(event.target.id);
	};

	/**
	 * Create an HTML audio tag.
	 * @method createTag
	 * @param {String} src The source file to set for the audio tag.
	 * @return {HTMLElement} Returns an HTML audio tag.
	 * @protected
	 */
	p.createTag = function (src) {
		var tag = document.createElement("audio");
		tag.autoplay = false;
		tag.preload = "none";
		//LM: Firefox fails when this the preload="none" for other tags, but it needs to be "none" to ensure PreloadJS works.
		tag.src = src;
		return tag;
	};

	/**
	 * Remove a sound added using {{#crossLink "HTMLAudioPlugin/register"}}{{/crossLink}}. Note this does not cancel
	 * a preload.
	 * @method removeSound
	 * @param {String} src The sound URI to unload.
	 * @since 0.4.1
	 */
	p.removeSound = function (src) {
		delete(this.audioSources[src]);
		createjs.HTMLAudioPlugin.TagPool.remove(src);
	};

	/**
	 * Remove all sounds added using {{#crossLink "HTMLAudioPlugin/register"}}{{/crossLink}}. Note this does not cancel a preload.
	 * @method removeAllSounds
	 * @param {String} src The sound URI to unload.
	 * @since 0.4.1
	 */
	p.removeAllSounds = function () {
		this.audioSources = {};	// this drops all references, in theory freeing them for garbage collection
		createjs.HTMLAudioPlugin.TagPool.removeAll();
	};

	/**
	 * Create a sound instance. If the sound has not been preloaded, it is internally preloaded here.
	 * @method create
	 * @param {String} src The sound source to use.
	 * @return {SoundInstance} A sound instance for playback and control.
	 */
	p.create = function (src) {
		// if this sound has not be registered, create a tag and preload it
		if (!this.isPreloadStarted(src)) {
			var channel = createjs.HTMLAudioPlugin.TagPool.get(src);
			var tag = this.createTag(src);
			tag.id = src;
			channel.add(tag);
			this.preload(src, {tag:tag});
		}

		return new createjs.HTMLAudioPlugin.SoundInstance(src, this);
	};

	/**
	 * Checks if preloading has started for a specific source.
	 * @method isPreloadStarted
	 * @param {String} src The sound URI to check.
	 * @return {Boolean} If the preload has started.
	 * @since 0.4.0
	 */
	p.isPreloadStarted = function (src) {
		return (this.audioSources[src] != null);
	};

	/**
	 * Internally preload a sound.
	 * @method preload
	 * @param {String} src The sound URI to load.
	 * @param {Object} instance An object containing a tag property that is an HTML audio tag used to load src.
	 * @since 0.4.0
	 */
	p.preload = function (src, instance) {
		this.audioSources[src] = true;
		new createjs.HTMLAudioPlugin.Loader(src, instance.tag);
	};

	p.toString = function () {
		return "[HTMLAudioPlugin]";
	};

	createjs.HTMLAudioPlugin = HTMLAudioPlugin;
}());


(function () {

	"use strict";

	// NOTE Documentation for the SoundInstance class in WebAudioPlugin file. Each plugin generates a SoundInstance that
	// follows the same interface.
	function SoundInstance(src, owner) {
		this.init(src, owner);
	}

	var p = SoundInstance.prototype = new createjs.EventDispatcher();

	p.src = null,
	p.uniqueId = -1;
	p.playState = null;
	p.owner = null;
	p.loaded = false;
	p.offset = 0;
	p.delay = 0;
	p._volume =  1;
	// IE8 has Object.defineProperty, but only for DOM objects, so check if fails to suppress errors
	try {
		Object.defineProperty(p, "volume", {
			get: function() {
				return this._volume;
			},
			set: function(value) {
				if (Number(value) == null) {return;}
				value = Math.max(0, Math.min(1, value));
				this._volume = value;
				this.updateVolume();
			}
		});
	} catch (e) {
		// dispatch message or error?
	};
	p.pan = 0;
	p.duration = 0;
	p.remainingLoops = 0;
	p.delayTimeoutId = null;
	p.tag = null;
	p.muted = false;
	p.paused = false;

	// Proxies, make removing listeners easier.
	p.endedHandler = null;
	p.readyHandler = null;
	p.stalledHandler = null;
	p.loopHandler = null;

// Constructor
	p.init = function (src, owner) {
		this.src = src;
		this.owner = owner;

		this.endedHandler = createjs.proxy(this.handleSoundComplete, this);
		this.readyHandler = createjs.proxy(this.handleSoundReady, this);
		this.stalledHandler = createjs.proxy(this.handleSoundStalled, this);
		this.loopHandler = createjs.proxy(this.handleSoundLoop, this);
	};

	p.sendEvent = function (type) {
		var event = new createjs.Event(type);
		this.dispatchEvent(event);
	};

	p.cleanUp = function () {
		var tag = this.tag;
		if (tag != null) {
			tag.pause();
			tag.removeEventListener(createjs.HTMLAudioPlugin.AUDIO_ENDED, this.endedHandler, false);
			tag.removeEventListener(createjs.HTMLAudioPlugin.AUDIO_READY, this.readyHandler, false);
			tag.removeEventListener(createjs.HTMLAudioPlugin.AUDIO_SEEKED, this.loopHandler, false);
			try {
				tag.currentTime = 0;
			} catch (e) {
			} // Reset Position
			createjs.HTMLAudioPlugin.TagPool.setInstance(this.src, tag);
			this.tag = null;
		}

		clearTimeout(this.delayTimeoutId);
		if (window.createjs == null) {
			return;
		}
		createjs.Sound.playFinished(this);
	};

	p.interrupt = function () {
		if (this.tag == null) {
			return;
		}
		this.playState = createjs.Sound.PLAY_INTERRUPTED;
		this.cleanUp();
		this.paused = false;
		this.sendEvent("interrupted");
	};

// Public API
	p.play = function (interrupt, delay, offset, loop, volume, pan) {
		this.cleanUp(); //LM: Is this redundant?
		createjs.Sound.playInstance(this, interrupt, delay, offset, loop, volume, pan);
	};

	p.beginPlaying = function (offset, loop, volume, pan) {
		if (window.createjs == null) {
			return -1;
		}
		var tag = this.tag = createjs.HTMLAudioPlugin.TagPool.getInstance(this.src);
		if (tag == null) {
			this.playFailed();
			return -1;
		}

		tag.addEventListener(createjs.HTMLAudioPlugin.AUDIO_ENDED, this.endedHandler, false);

		// Reset this instance.
		this.offset = offset;
		this.volume = volume;
		this.pan = pan;	// not pan has no effect
		this.updateVolume();  // note this will set for mute and masterMute
		this.remainingLoops = loop;

		if (tag.readyState !== 4) {
			tag.addEventListener(createjs.HTMLAudioPlugin.AUDIO_READY, this.readyHandler, false);
			tag.addEventListener(createjs.HTMLAudioPlugin.AUDIO_STALLED, this.stalledHandler, false);
			tag.preload = "auto"; // This is necessary for Firefox, as it won't ever "load" until this is set.
			tag.load();
		} else {
			this.handleSoundReady(null);
		}

		this.sendEvent("succeeded");
		return 1;
	};

	// Note: Sounds stall when trying to begin playback of a new audio instance when the existing instances
	//  has not loaded yet. This doesn't mean the sound will not play.
	p.handleSoundStalled = function (event) {
		this.cleanUp();  // OJR NOTE this will stop playback, and I think we should remove this and let the developer decide how to handle stalled instances
		this.sendEvent("failed");
	};

	p.handleSoundReady = function (event) {
		if (window.createjs == null) {
			return;
		}

		// OJR would like a cleaner way to do this in init, discuss with LM
		this.duration = this.tag.duration * 1000;  // need this for setPosition on stopped sounds

		this.playState = createjs.Sound.PLAY_SUCCEEDED;
		this.paused = false;
		this.tag.removeEventListener(createjs.HTMLAudioPlugin.AUDIO_READY, this.readyHandler, false);

		if (this.offset >= this.getDuration()) {
			this.playFailed();  // OJR: throw error?
			return;
		} else if (this.offset > 0) {
			this.tag.currentTime = this.offset * 0.001;
		}
		if (this.remainingLoops == -1) {
			this.tag.loop = true;
		}
		if(this.remainingLoops != 0) {
			this.tag.addEventListener(createjs.HTMLAudioPlugin.AUDIO_SEEKED, this.loopHandler, false);
			this.tag.loop = true;
		}
		this.tag.play();
	};

	p.pause = function () {
		if (!this.paused && this.playState == createjs.Sound.PLAY_SUCCEEDED && this.tag != null) {
			this.paused = true;
			// Note: when paused by user, we hold a reference to our tag. We do not release it until stopped.
			this.tag.pause();

			clearTimeout(this.delayTimeoutId);

			return true;
		}
		return false;
	};

	p.resume = function () {
		if (!this.paused || this.tag == null) {
			return false;
		}
		this.paused = false;
		this.tag.play();
		return true;
	};

	p.stop = function () {
		this.offset = 0;
		this.pause();
		this.playState = createjs.Sound.PLAY_FINISHED;
		this.cleanUp();
		return true;
	};

	p.setMasterVolume = function (value) {
		this.updateVolume();
		return true;
	};

	p.setVolume = function (value) {
		this.volume = value;
		return true;
	};

	p.updateVolume = function () {
		if (this.tag != null) {
			var newVolume = (this.muted || createjs.Sound.masterMute) ? 0 : this._volume * createjs.Sound.masterVolume;
			if (newVolume != this.tag.volume) {
				this.tag.volume = newVolume;
			}
			return true;
		} else {
			return false;
		}
	};

	p.getVolume = function (value) {
		return this.volume;
	};

	p.setMasterMute = function (isMuted) {
		this.updateVolume();
		return true;
	};

	p.setMute = function (isMuted) {
		if (isMuted == null || isMuted == undefined) {
			return false;
		}

		this.muted = isMuted;
		this.updateVolume();
		return true;
	};

	p.getMute = function () {
		return this.muted;
	};

	// Can not set pan in HTML
	p.setPan = function (value) {
		return false;
	};

	p.getPan = function () {
		return 0;
	};

	p.getPosition = function () {
		if (this.tag == null) {
			return this.offset;
		}
		return this.tag.currentTime * 1000;
	};

	p.setPosition = function (value) {
		if (this.tag == null) {
			this.offset = value
		} else {
			this.tag.removeEventListener(createjs.HTMLAudioPlugin.AUDIO_SEEKED, this.loopHandler, false);
			try {
				this.tag.currentTime = value * 0.001;
			} catch (error) { // Out of range
				return false;
			}
			this.tag.addEventListener(createjs.HTMLAudioPlugin.AUDIO_SEEKED, this.loopHandler, false);
		}
		return true;
	};

	p.getDuration = function () {  // NOTE this will always return 0 until sound has been played.
		return this.duration;
	};

	p.handleSoundComplete = function (event) {
		this.offset = 0;

		if (window.createjs == null) {
			return;
		}
		this.playState = createjs.Sound.PLAY_FINISHED;
		this.cleanUp();
		this.sendEvent("complete");
	};

	// handles looping functionality
	// NOTE with this approach audio will loop as reliably as the browser allows
	// but we could end up sending the loop event after next loop playback begins
	p.handleSoundLoop = function (event) {
		this.offset = 0;

		this.remainingLoops--;
		if(this.remainingLoops == 0) {
			this.tag.loop = false;
			this.tag.removeEventListener(createjs.HTMLAudioPlugin.AUDIO_SEEKED, this.loopHandler, false);
		}
		this.sendEvent("loop");
	};

	p.playFailed = function () {
		if (window.createjs == null) {
			return;
		}
		this.playState = createjs.Sound.PLAY_FAILED;
		this.cleanUp();
		this.sendEvent("failed");
	};

	p.toString = function () {
		return "[HTMLAudioPlugin SoundInstance]";
	};

	createjs.HTMLAudioPlugin.SoundInstance = SoundInstance;

}());


(function () {

	"use strict";

	/**
	 * An internal helper class that preloads html audio via HTMLAudioElement tags. Note that PreloadJS will NOT use
	 * this load class like it does Flash and WebAudio plugins.
	 * Note that this class and its methods are not documented properly to avoid generating HTML documentation.
	 * #class Loader
	 * @param {String} src The source of the sound to load.
	 * @param {HTMLAudioElement} tag The audio tag of the sound to load.
	 * @constructor
	 * @protected
	 * @since 0.4.0
	 */
	function Loader(src, tag) {
		this.init(src, tag);
	}

	var p = Loader.prototype;

	/**
	 * The source to be loaded.
	 * #property src
	 * @type {String}
	 * @default null
	 * @protected
	 */
	p.src = null;

	/**
	 * The tag to load the source with / into.
	 * #property tag
	 * @type {AudioTag}
	 * @default null
	 * @protected
	 */
	p.tag = null;

	/**
	 * An interval used to give us progress.
	 * #property preloadTimer
	 * @type {String}
	 * @default null
	 * @protected
	 */
	p.preloadTimer = null;

	// Proxies, make removing listeners easier.
	p.loadedHandler = null;

	// constructor
	p.init = function (src, tag) {
		this.src = src;
		this.tag = tag;

		this.preloadTimer = setInterval(createjs.proxy(this.preloadTick, this), 200);

		// This will tell us when audio is buffered enough to play through, but not when its loaded.
		// The tag doesn't keep loading in Chrome once enough has buffered, and we have decided that behaviour is sufficient.
		// Note that canplaythrough callback doesn't work in Chrome, we have to use the event.
		this.loadedHandler = createjs.proxy(this.sendLoadedEvent, this);  // we need this bind to be able to remove event listeners
		this.tag.addEventListener && this.tag.addEventListener("canplaythrough", this.loadedHandler);
		if(this.tag.onreadystatechange == null) {
			this.tag.onreadystatechange = createjs.proxy(this.sendLoadedEvent, this);  // OJR not 100% sure we need this, just copied from PreloadJS
		} else {
			var f = this.tag.onreadystatechange;
			this.tag.onreadystatechange = function() {
				f();
				this.tag.onreadystatechange = createjs.proxy(this.sendLoadedEvent, this);  // OJR not 100% sure we need this, just copied from PreloadJS
			}
		}

		this.tag.preload = "auto";
		//this.tag.src = src;
		this.tag.load();
	};

	/**
	 * Allows us to have preloading progress and tell when its done.
	 * #method preloadTick
	 * @protected
	 */
	p.preloadTick = function () {
		var buffered = this.tag.buffered;
		var duration = this.tag.duration;

		if (buffered.length > 0) {
			if (buffered.end(0) >= duration - 1) {
				this.handleTagLoaded();
			}
		}
	};

	/**
	 * Internal handler for when a tag is loaded.
	 * #method handleTagLoaded
	 * @protected
	 */
	p.handleTagLoaded = function () {
		clearInterval(this.preloadTimer);
	};

	/**
	 * Communicates back to Sound that a load is complete.
	 * #method sendLoadedEvent
	 * @param {Object} evt The load Event
	 */
	p.sendLoadedEvent = function (evt) {
		this.tag.removeEventListener && this.tag.removeEventListener("canplaythrough", this.loadedHandler);  // cleanup and so we don't send the event more than once
		this.tag.onreadystatechange = null;  // cleanup and so we don't send the event more than once
		createjs.Sound.sendFileLoadEvent(this.src);  // fire event or callback on Sound
	};

	// used for debugging
	p.toString = function () {
		return "[HTMLAudioPlugin Loader]";
	}

	createjs.HTMLAudioPlugin.Loader = Loader;

}());


(function () {

	"use strict";

	/**
	 * The TagPool is an object pool for HTMLAudio tag instances. In Chrome, we have to pre-create the number of HTML
	 * audio tag instances that we are going to play before we load the data, otherwise the audio stalls.
	 * (Note: This seems to be a bug in Chrome)
	 * #class TagPool
	 * @param {String} src The source of the channel.
	 * @protected
	 */
	function TagPool(src) {
		this.init(src);
	}

	var s = TagPool;

	/**
	 * A hash lookup of each sound channel, indexed by the audio source.
	 * #property tags
	 * @static
	 * @protected
	 */
	s.tags = {};

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
	}

	/**
	 * Delete a TagPool and all related tags. Note that if the TagPool does not exist, this will fail.
	 * #method remove
	 * @param {String} src The source for the tag
	 * @return {Boolean} If the TagPool was deleted.
	 * @static
	 */
	s.remove = function (src) {
		var channel = s.tags[src];
		if (channel == null) {
			return false;
		}
		channel.removeAll();
		delete(s.tags[src]);
		return true;
	}

	/**
	 * Delete all TagPools and all related tags.
	 * #method removeAll
	 * @static
	 */
	s.removeAll = function () {
		for(var channel in s.tags) {
			s.tags[channel].removeAll();	// this stops and removes all active instances
		}
		s.tags = {};
	}

	/**
	 * Get a tag instance. This is a shortcut method.
	 * #method getInstance
	 * @param {String} src The source file used by the audio tag.
	 * @static
	 * @protected
	 */
	s.getInstance = function (src) {
		var channel = s.tags[src];
		if (channel == null) {
			return null;
		}
		return channel.get();
	}

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
		if (channel == null) {
			return null;
		}
		return channel.set(tag);
	}

	/**
	 * A function to check if src has changed in the loaded audio tag.
	 * This is required because PreloadJS appends a basePath to the src before loading.
	 * Note this is currently only called when a change is detected
	 * #method checkSrc
	 * @param src the unaltered src that is used to store the channel.
	 * @static
	 * @protected
	 */
	s.checkSrc = function (src) {
		var channel = s.tags[src];
		if (channel == null) {
			return null;
		}
		channel.checkSrcChange();
	}

	var p = TagPool.prototype;

	/**
	 * The source of the tag pool.
	 * #property src
	 * @type {String}
	 * @protected
	 */
	p.src = null;

	/**
	 * The total number of HTMLAudio tags in this pool. This is the maximum number of instance of a certain sound
	 * that can play at one time.
	 * #property length
	 * @type {Number}
	 * @default 0
	 * @protected
	 */
	p.length = 0;

	/**
	 * The number of unused HTMLAudio tags.
	 * #property available
	 * @type {Number}
	 * @default 0
	 * @protected
	 */
	p.available = 0;

	/**
	 * A list of all available tags in the pool.
	 * #property tags
	 * @type {Array}
	 * @protected
	 */
	p.tags = null;

	// constructor
	p.init = function (src) {
		this.src = src;
		this.tags = [];
	};

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
		// This may not be neccessary
		while(this.length--) {
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
		if (this.tags.length == 0) {
			return null;
		}
		this.available = this.tags.length;
		var tag = this.tags.pop();
		if (tag.parentNode == null) {
			document.body.appendChild(tag);
		}
		return tag;
	};

	/**
	 * Put an HTMLAudioElement back in the pool for use.
	 * #method set
	 * @param {HTMLAudioElement} tag HTML audio tag
	 */
	p.set = function (tag) {
		var index = createjs.indexOf(this.tags, tag);
		if (index == -1) {
			this.tags.push(tag);
		}
		this.available = this.tags.length;
	};

	/**
	 * Make sure the src of all other tags is correct after load.
	 * This is needed because PreloadJS appends a basePath to src before loading.
	 * #method checkSrcChange
	 */
	p.checkSrcChange = function () {
		// the last tag always has the latest src after loading
		//var i = this.length-1;	// this breaks in Firefox because it is not correctly removing an event listener
		var i = this.tags.length - 1;
        if(i == -1) return;  // CodeCombat addition; sometimes errors in IE without this...
		var newSrc = this.tags[i].src;
		while(i--) {
			this.tags[i].src = newSrc;
		}
	};

	p.toString = function () {
		return "[HTMLAudioPlugin TagPool]";
	}

	createjs.HTMLAudioPlugin.TagPool = TagPool;

}());