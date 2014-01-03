this.createjs = this.createjs||{};

(function() {
	"use strict";

	/**
	 * Static class holding library specific information such as the version and buildDate of
	 * the library.
	 *
	 * The old PreloadJS class has been renamed to LoadQueue. Please see the {{#crossLink "LoadQueue"}}{{/crossLink}}
	 * class for information on loading files.
	 * @class PreloadJS
	 **/
	var s = createjs.PreloadJS = createjs.PreloadJS || {};

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
	s.buildDate = /*date*/"Wed, 20 Nov 2013 16:17:10 GMT"; // injected by build process

})();
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
* AbstractLoader
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
 * @module PreloadJS
 */

// namespace:
this.createjs = this.createjs||{};

(function() {
	"use strict";
	/**
	 * The base loader, which defines all the generic callbacks and events. All loaders extend this class, including the
	 * {{#crossLink "LoadQueue"}}{{/crossLink}}.
	 * @class AbstractLoader
	 * @uses EventDispatcher
	 */
	var AbstractLoader = function () {
		this.init();
	};

	AbstractLoader.prototype = {};
	var p = AbstractLoader.prototype;
	var s = AbstractLoader;

	/**
	 * The RegExp pattern to use to parse file URIs. This supports simple file names, as well as full domain URIs with
	 * query strings. The resulting match is: protocol:$1 domain:$2 path:$3 file:$4 extension:$5 query:$6.
	 * @property FILE_PATTERN
	 * @type {RegExp}
	 * @static
	 * @protected
	 */
	s.FILE_PATTERN = /^(?:(\w+:)\/{2}(\w+(?:\.\w+)*\/?))?([/.]*?(?:[^?]+)?\/)?((?:[^/?]+)\.(\w+))(?:\?(\S+)?)?$/;

	/**
	 * If the loader has completed loading. This provides a quick check, but also ensures that the different approaches
	 * used for loading do not pile up resulting in more than one <code>complete</code> event.
	 * @property loaded
	 * @type {Boolean}
	 * @default false
	 */
	p.loaded = false;

	/**
	 * Determine if the loader was canceled. Canceled loads will not fire complete events. Note that
	 * {{#crossLink "LoadQueue"}}{{/crossLink}} queues should be closed using {{#crossLink "AbstractLoader/close"}}{{/crossLink}}
	 * instead of canceled.
	 * @property canceled
	 * @type {Boolean}
	 * @default false
	 */
	p.canceled = false;

	/**
	 * The current load progress (percentage) for this item. This will be a number between 0 and 1.
	 * @property progress
	 * @type {Number}
	 * @default 0
	 */
	p.progress = 0;

	/**
	 * The item this loader represents. Note that this is null in a {{#crossLink "LoadQueue"}}{{/crossLink}}, but will
	 * be available on loaders such as {{#crossLink "XHRLoader"}}{{/crossLink}} and {{#crossLink "TagLoader"}}{{/crossLink}}.
	 * @property _item
	 * @type {Object}
	 * @private
	 */
	p._item = null;

	/**
	 * A path that will be prepended on to the item's source parameter before it is loaded.
	 * @property _basePath
	 * @type {String}
	 * @private
	 * @since 0.3.1
	 */
	p._basePath = null;

// Events
	/**
	 * The event that is fired when the overall progress changes.
	 * @event progress
	 * @param {Object} target The object that dispatched the event.
	 * @param {String} type The event type.
	 * @param {Number} loaded The amount that has been loaded so far. Note that this is may just be a percentage of 1,
	 * since file sizes can not be determined before a load is kicked off, if at all.
	 * @param {Number} total The total number of bytes. Note that this may just be 1.
	 * @param {Number} progress The ratio that has been loaded between 0 and 1.
	 * @since 0.3.0
	 */

	/**
	 * The event that is fired when a load starts.
	 * @event loadstart
	 * @param {Object} target The object that dispatched the event.
	 * @param {String} type The event type.
	 * @since 0.3.1
	 */

	/**
	 * The event that is fired when the entire queue has been loaded.
	 * @event complete
	 * @param {Object} target The object that dispatched the event.
	 * @param {String} type The event type.
	 * @since 0.3.0
	 */

	/**
	 * The event that is fired when the loader encounters an error. If the error was encountered by a file, the event will
	 * contain the item that caused the error. There may be additional properties such as the error reason on event
	 * objects.
	 * @event error
	 * @param {Object} target The object that dispatched the event.
	 * @param {String} type The event type.
	 * @param {Object} [item] The item that was being loaded that caused the error. The item was specified in
	 * the {{#crossLink "LoadQueue/loadFile"}}{{/crossLink}} or {{#crossLink "LoadQueue/loadManifest"}}{{/crossLink}}
	 * call. If only a string path or tag was specified, the object will contain that value as a property.
	 * @param {String} [error] The error object or text.
	 * @since 0.3.0
	 */

	//TODO: Deprecated
	/**
	 * REMOVED. Use {{#crossLink "EventDispatcher/addEventListener"}}{{/crossLink}} and the {{#crossLink "AbstractLoader/progress:event"}}{{/crossLink}}
	 * event.
	 * @property onProgress
	 * @type {Function}
	 * @deprecated Use addEventListener and the "progress" event.
	 */
	/**
	 * REMOVED. Use {{#crossLink "EventDispatcher/addEventListener"}}{{/crossLink}} and the {{#crossLink "AbstractLoader/loadstart:event"}}{{/crossLink}}
	 * event.
	 * @property onLoadStart
	 * @type {Function}
	 * @deprecated Use addEventListener and the "loadstart" event.
	 */
	/**
	 * REMOVED. Use {{#crossLink "EventDispatcher/addEventListener"}}{{/crossLink}} and the {{#crossLink "AbstractLoader/complete:event"}}{{/crossLink}}
	 * event.
	 * @property onComplete
	 * @type {Function}
	 * @deprecated Use addEventListener and the "complete" event.
	 */
	/**
	 * REMOVED. Use {{#crossLink "EventDispatcher/addEventListener"}}{{/crossLink}} and the {{#crossLink "AbstractLoader/error:event"}}{{/crossLink}}
	 * event.
	 * @property onError
	 * @type {Function}
	 * @deprecated Use addEventListener and the "error" event.
	 */


// mix-ins:
	// EventDispatcher methods:
	p.addEventListener = null;
	p.removeEventListener = null;
	p.removeAllEventListeners = null;
	p.dispatchEvent = null;
	p.hasEventListener = null;
	p._listeners = null;
	createjs.EventDispatcher.initialize(p);


	/**
	 * Get a reference to the manifest item that is loaded by this loader. In most cases this will be the value that was
	 * passed into {{#crossLink "LoadQueue"}}{{/crossLink}} using {{#crossLink "LoadQueue/loadFile"}}{{/crossLink}} or
	 * {{#crossLink "LoadQueue/loadManifest"}}{{/crossLink}}. However if only a String path was passed in, then it will
	 * be an Object created by the LoadQueue.
	 * @return {Object} The manifest item that this loader is responsible for loading.
	 */
	p.getItem = function() {
		return this._item;
	};

	/**
	 * Initialize the loader. This is called by the constructor.
	 * @method init
	 * @private
	 */
	p.init = function () {};

	/**
	 * Begin loading the queued items. This method can be called when a {{#crossLink "LoadQueue"}}{{/crossLink}} is set
	 * up but not started immediately.
	 * @example
	 *      var queue = new createjs.LoadQueue();
	 *      queue.addEventListener("complete", handleComplete);
	 *      queue.loadManifest(fileArray, false); // Note the 2nd argument that tells the queue not to start loading yet
	 *      queue.load();
	 * @method load
	 */
	p.load = function() {};

	/**
	 * Close the active queue. Closing a queue completely empties the queue, and prevents any remaining items from
	 * starting to download. Note that currently any active loads will remain open, and events may be processed.
	 *
	 * To stop and restart a queue, use the {{#crossLink "LoadQueue/setPaused"}}{{/crossLink}} method instead.
	 * @method close
	 */
	p.close = function() {};


//Callback proxies
	/**
	 * Dispatch a loadstart event. Please see the {{#crossLink "AbstractLoader/loadstart:event"}}{{/crossLink}} event
	 * for details on the event payload.
	 * @method _sendLoadStart
	 * @protected
	 */
	p._sendLoadStart = function() {
		if (this._isCanceled()) { return; }
		this.dispatchEvent("loadstart");
	};

	/**
	 * Dispatch a progress event. Please see the {{#crossLink "AbstractLoader/progress:event"}}{{/crossLink}} event for
	 * details on the event payload.
	 * @method _sendProgress
	 * @param {Number | Object} value The progress of the loaded item, or an object containing <code>loaded</code>
	 * and <code>total</code> properties.
	 * @protected
	 */
	p._sendProgress = function(value) {
		if (this._isCanceled()) { return; }
		var event = null;
		if (typeof(value) == "number") {
			this.progress = value;
			event = new createjs.Event("progress");
			event.loaded = this.progress;
			event.total = 1;
		} else {
			event = value;
			this.progress = value.loaded / value.total;
			if (isNaN(this.progress) || this.progress == Infinity) { this.progress = 0; }
		}
		event.progress = this.progress;
		this.hasEventListener("progress") && this.dispatchEvent(event);
	};

	/**
	 * Dispatch a complete event. Please see the {{#crossLink "AbstractLoader/complete:event"}}{{/crossLink}} event
	 * for details on the event payload.
	 * @method _sendComplete
	 * @protected
	 */
	p._sendComplete = function() {
		if (this._isCanceled()) { return; }
		this.dispatchEvent("complete");
	};

	/**
	 * Dispatch an error event. Please see the {{#crossLink "AbstractLoader/error:event"}}{{/crossLink}} event for
	 * details on the event payload.
	 * @method _sendError
	 * @param {Object} event The event object containing specific error properties.
	 * @protected
	 */
	p._sendError = function(event) {
		if (this._isCanceled() || !this.hasEventListener("error")) { return; }
		if (event == null) {
			event = new createjs.Event("error");
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
	p._isCanceled = function() {
		if (window.createjs == null || this.canceled) {
			return true;
		}
		return false;
	};

	/**
	 * Parse a file URI using the <code>AbstractLoader.FILE_PATTERN</code> RegExp pattern.
	 * @method _parseURI
	 * @param {String} path The file path to parse.
	 * @return {Array} The matched file contents. Please see the <code>AbstractLoader.FILE_PATTERN</code> property for
	 * details on the return value. This will return null if it does not match.
	 * @protected
	 */
	p._parseURI = function(path) {
		if (!path) { return null; }
		return path.match(s.FILE_PATTERN);
	};

	/**
	 * Formats an object into a query string for either a POST or GET request.
	 * @method _formatQueryString
	 * @param {Object} data The data to convert to a query string.
	 * @param {Array} [query] Existing name/value pairs to append on to this query.
	 * @private
	 */
	p._formatQueryString = function(data, query) {
		if (data == null) {
			throw new Error('You must specify data.');
		}
		var params = [];
		for (var n in data) {
			params.push(n+'='+escape(data[n]));
		}
		if (query) {
			params = params.concat(query);
		}
		return params.join('&');
	};

	/**
	 * A utility method that builds a file path using a source, a basePath, and a data object, and formats it into a new
	 * path. All of the loaders in PreloadJS use this method to compile paths when loading.
	 * @method buildPath
	 * @param {String} src The source path to add values to.
	 * @param {String} [basePath] A string to prepend to the file path. Sources beginning with http:// or similar will
	 * not receive a base path.
	 * @param {Object} [data] Object used to append values to this request as a query string. Existing parameters on the
	 * path will be preserved.
	 * @returns {string} A formatted string that contains the path and the supplied parameters.
	 * @since 0.3.1
	 */
	p.buildPath = function(src, _basePath, data) {
		if (_basePath != null) {
			var match = this._parseURI(src);
			// IE 7,8 Return empty string here.
			if (match == null || match[1] == null || match[1] == '') {
				src = _basePath + src;
			}
		}
		if (data == null) {
			return src;
		}

		var query = [];
		var idx = src.indexOf('?');

		if (idx != -1) {
			var q = src.slice(idx+1);
			query = query.concat(q.split('&'));
		}

		if (idx != -1) {
			return src.slice(0, idx) + '?' + this._formatQueryString(data, query);
		} else {
			return src + '?' + this._formatQueryString(data, query);
		}
	};

	/**
	 * @method toString
	 * @return {String} a string representation of the instance.
	 */
	p.toString = function() {
		return "[PreloadJS AbstractLoader]";
	};

	createjs.AbstractLoader = AbstractLoader;

}());
/*
* LoadQueue
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
 * PreloadJS provides a consistent way to preload content for use in HTML applications. Preloading can be done using
 * HTML tags, as well as XHR.
 *
 * By default, PreloadJS will try and load content using XHR, since it provides better support for progress and
 * completion events, <b>however due to cross-domain issues, it may still be preferable to use tag-based loading
 * instead</b>. Note that some content requires XHR to work (plain text, web audio), and some requires tags (HTML audio).
 * Note this is handled automatically where possible.
 *
 * PreloadJS currently supports all modern browsers, and we have done our best to include support for most older
 * browsers. If you find an issue with any specific OS/browser combination, please visit http://community.createjs.com/
 * and report it.
 *
 * <h4>Getting Started</h4>
 * To get started, check out the {{#crossLink "LoadQueue"}}{{/crossLink}} class, which includes a quick overview of how
 * to load files and process results.
 *
 * <h4>Example</h4>
 *      var queue = new createjs.LoadQueue();
 *      queue.installPlugin(createjs.Sound);
 *      queue.on("complete", handleComplete, this);
 *      queue.loadFile({id:"sound", src:"http://path/to/sound.mp3"});
 *      queue.loadManifest([
 *          {id: "myImage", src:"path/to/myImage.jpg"}
 *      ]);
 *      function handleComplete() {
 *          createjs.Sound.play("sound");
 *          var image = queue.getResult("myImage");
 *          document.body.appendChild(image);
 *      }
 *
 * <b>Important note on plugins:</b> Plugins must be installed <i>before</i> items are added to the queue, otherwise
 * they will not be processed, even if the load has not actually kicked off yet. Plugin functionality is handled when
 * the items are added to the LoadQueue.
 *
 * <h4>Browser Support</h4>
 * PreloadJS is partially supported in all browsers, and fully supported in all modern browsers. Known exceptions:
 * <ul><li>XHR loading of any content will not work in many older browsers (See a matrix here: <a href="http://caniuse.com/xhr2">http://caniuse.com/xhr2</a>).
 *      In many cases, you can fall back on tag loading (images, audio, CSS, scripts, SVG, and JSONP). Text and
 *      WebAudio will only work with XHR.</li>
 *      <li>Some formats have poor support for complete events in IE 6, 7, and 8 (SVG, tag loading of scripts, XML/JSON)</li>
 *      <li>Opera has poor support for SVG loading with XHR</li>
 *      <li>CSS loading in Android and Safari will not work with tags (currently, a workaround is in progress)</li>
 * </li>
 *
 * @module PreloadJS
 * @main PreloadJS
 */

// namespace:
this.createjs = this.createjs||{};

//TODO: addHeadTags support

/*
TODO: WINDOWS ISSUES
	* No error for HTML audio in IE 678
	* SVG no failure error in IE 67 (maybe 8) TAGS AND XHR
	* No script complete handler in IE 67 TAGS (XHR is fine)
	* No XML/JSON in IE6 TAGS
	* Need to hide loading SVG in Opera TAGS
	* No CSS onload/readystatechange in Safari or Android TAGS (requires rule checking)
	* SVG no load or failure in Opera XHR
	* Reported issues with IE7/8
 */

(function() {
	"use strict";

	/**
	 * The LoadQueue class is the main API for preloading content. LoadQueue is a load manager, which maintains
	 * a single file, or a queue of files.
	 *
	 * <b>Creating a Queue</b><br />
	 * To use LoadQueue, create a LoadQueue instance. If you want to force tag loading where possible, set the useXHR
	 * argument to false.
	 *
	 *      var queue = new createjs.LoadQueue(true);
	 *
	 * <b>Listening for Events</b><br />
	 * Add any listeners you want to the queue. Since PreloadJS 0.3.0, the {{#crossLink "EventDispatcher"}}{{/crossLink}}
	 * lets you add as many listeners as you want for events. You can subscribe to complete, error, fileload, progress,
	 * and fileprogress.
	 *
	 *      queue.on("fileload", handleFileLoad, this);
	 *      queue.on("complete", handleComplete, this);
	 *
	 * <b>Adding files and manifests</b><br />
	 * Add files you want to load using {{#crossLink "LoadQueue/loadFile"}}{{/crossLink}} or add multiple files at a
	 * time using {{#crossLink "LoadQueue/loadManifest"}}{{/crossLink}}. Files are appended to the queue, so you can use
	 * these methods as many times as you like, whenever you like.
	 *
	 *      queue.loadFile("filePath/file.jpg");
	 *      queue.loadFile({id:"image", src:"filePath/file.jpg"});
	 *      queue.loadManifest(["filePath/file.jpg", {id:"image", src:"filePath/file.jpg"}];
	 *
	 * If you pass <code>false</code> as the second parameter, the queue will not immediately load the files (unless it
	 * has already been started). Call the {{#crossLink "AbstractLoader/load"}}{{/crossLink}} method to begin a paused queue.
	 * Note that a paused queue will automatically resume when new files are added to it.
	 *
	 *      queue.load();
	 *
	 * <b>File Types</b><br />
	 * The file type of a manifest item is auto-determined by the file extension. The pattern matching in PreloadJS
	 * should handle the majority of standard file and url formats, and works with common file extensions. If you have
	 * either a non-standard file extension, or are serving the file using a proxy script, then you can pass in a
	 * <code>type</code> property with any manifest item.
	 *
	 *      queue.loadFile({src:"path/to/myFile.mp3x", type:createjs.LoadQueue.SOUND});
	 *
	 *      // Note that PreloadJS will not read a file extension from the query string
	 *      queue.loadFile({src:"http://server.com/proxy?file=image.jpg"}, type:createjs.LoadQueue.IMAGE});
	 *
	 * Supported types include:
	 * <ul>
	 *     <li>createjs.LoadQueue.BINARY (Raw binary data via XHR)</li>
	 *     <li>createjs.LoadQueue.CSS (CSS files)</li>
	 *     <li>createjs.LoadQueue.IMAGE (Common image formats)</li>
	 *     <li>createjs.LoadQueue.JAVASCRIPT (JavaScript files)</li>
	 *     <li>createjs.LoadQueue.JSON (JSON data)</li>
	 *     <li>createjs.LoadQueue.JSONP (JSON files cross-domain)</li>
	 *     <li>createjs.LoadQueue.MANIFEST (A list of files to load in JSON format, see {{#crossLink "LoadQueue/MANIFEST:property"}}{{/crossLink}} )</li>
	 *     <li>createjs.LoadQueue.SOUND (Audio file formats)</li>
	 *     <li>createjs.LoadQueue.SVG (SVG files)</li>
	 *     <li>createjs.LoadQueue.TEXT (Text files - XHR only)</li>
	 *     <li>createjs.LoadQueue.XML (XML data)</li>
	 * </ul>
	 *
	 * <b>Handling Results</b><br />
	 * When a file is finished downloading, a "fileload" event is dispatched. In an example above, there is an event
	 * listener snippet for fileload. Loaded files are always an object that can be used immediately, including:
	 * <ul>
	  *     <li>Image: An &lt;img /&gt; tag</li>
	  *     <li>Audio: An &lt;audio /&gt; tag</a>
	  *     <li>JavaScript: A &lt;script /&gt; tag</li>
	  *     <li>CSS: A &lt;link /&gt; tag</li>
	  *     <li>XML: An XML DOM node</li>
	  *     <li>SVG: An &lt;object /&gt; tag</li>
	  *     <li>JSON: A formatted JavaScript Object</li>
	  *     <li>Text: Raw text</li>
	  *     <li>Binary: The binary loaded result</li>
	  * </ul>
	 *
	 *      function handleFileLoad(event) {
	 *          var item = event.item; // A reference to the item that was passed in
	 *          var type = item.type;
	 *
	 *          // Add any images to the page body.
	 *          if (type == createjs.LoadQueue.IMAGE) {
	 *              document.body.appendChild(event.result);
	 *          }
	 *      }
	 *
	 * At any time after the file has been loaded (usually after the queue has completed), any result can be looked up
	 * via its "id" using {{#crossLink "LoadQueue/getResult"}}{{/crossLink}}. If no id was provided, then the "src" or
	 * file path can be used instead. It is recommended to always pass an id.
	 *
	 *      var image = queue.getResult("image");
	 *      document.body.appendChild(image);
	 *
	 * Raw loaded content can be accessed using the <code>rawResult</code> property of the <code>fileload</code> event,
	 * or can be looked up using {{#crossLink "LoadQueue/getResult"}}{{/crossLink}}, and <code>true</code> as the 2nd
	 * parameter. This is only applicable for content that has been parsed for the browser, specifically, JavaScript,
	 * CSS, XML, SVG, and JSON objects.
	 *
	 *      var image = queue.getResult("image", true);
	 *
	 * <b>Plugins</b><br />
	 * LoadQueue has a simple plugin architecture to help process and preload content. For example, to preload audio,
	 * make sure to install the <a href="http://soundjs.com">SoundJS</a> Sound class, which will help preload HTML
	 * audio, Flash audio, and WebAudio files. This should be installed <b>before</b> loading any audio files.
	 *
	 *      queue.installPlugin(createjs.Sound);
	 *
	 * <h4>Known Browser Issues</h4>
	 * <ul>
	 *     <li>Browsers without audio support can not load audio files.</li>
	 *     <li>Safari on Mac OS X can only play HTML audio if QuickTime is installed</li>
	 *     <li>HTML Audio tags will only download until their <code>canPlayThrough</code> event is fired. Browsers other
	 *     than Chrome will continue to download in the background.</li>
	 *     <li>When loading scripts using tags, they are automatically added to the document.</li>
	 *     <li>Scripts loaded via XHR may not be properly inspectable with browser tools.</li>
	 *     <li>IE6 and IE7 (and some other browsers) may not be able to load XML, Text, or JSON, since they require
	 *     XHR to work.</li>
	 *     <li>Content loaded via tags will not show progress, and will continue to download in the background when
	 *     canceled, although no events will be dispatched.</li>
	 * </ul>
	 *
	 * @class LoadQueue
	 * @param {Boolean} [useXHR=true] Determines whether the preload instance will favor loading with XHR (XML HTTP Requests),
	 * or HTML tags. When this is <code>false</code>, LoadQueue will use tag loading when possible, and fall back on XHR
	 * when necessary.
	 * @param {String} basePath A path that will be prepended on to the source parameter of all items in the queue
	 * before they are loaded.  Sources beginning with http:// or similar will not receive a base path.
	 * Note that a basePath provided to any loadFile or loadManifest call will override the
	 * basePath specified on the LoadQueue constructor.
	 * @constructor
	 * @extends AbstractLoader
	 */
	var LoadQueue = function(useXHR, basePath) {
		this.init(useXHR, basePath);
	};

	var p = LoadQueue.prototype = new createjs.AbstractLoader();
	var s = LoadQueue;

	/**
	 * Time in milliseconds to assume a load has failed.
	 * @property LOAD_TIMEOUT
	 * @type {Number}
	 * @default 8000
	 * @static
	 */
	s.LOAD_TIMEOUT = 8000;

// Preload Types
	/**
	 * The preload type for generic binary types. Note that images and sound files are treated as binary.
	 * @property BINARY
	 * @type {String}
	 * @default binary
	 * @static
	 */
	s.BINARY = "binary";

	/**
	 * The preload type for css files. CSS files are loaded into a LINK or STYLE tag (depending on the load type)
	 * @property CSS
	 * @type {String}
	 * @default css
	 * @static
	 */
	s.CSS = "css";

	/**
	 * The preload type for image files, usually png, gif, or jpg/jpeg. Images are loaded into an IMAGE tag.
	 * @property IMAGE
	 * @type {String}
	 * @default image
	 * @static
	 */
	s.IMAGE = "image";

	/**
	 * The preload type for javascript files, usually with the "js" file extension. JavaScript files are loaded into a
	 * SCRIPT tag.
	 *
	 * Since version 0.4.1+, due to how tag-loaded scripts work, all JavaScript files are automatically injected into
	 * the BODY of the document to maintain parity between XHR and tag-loaded scripts. In version 0.4.0 and earlier,
	 * only tag-loaded scripts were injected.
	 * @property JAVASCRIPT
	 * @type {String}
	 * @default javascript
	 * @static
	 */
	s.JAVASCRIPT = "javascript";

	/**
	 * The preload type for json files, usually with the "json" file extension. JSON data is loaded and parsed into a
	 * JavaScript object. Note that if a `callback` is present on the load item, the file will be loaded with JSONP,
	 * no matter what the {{#crossLink "LoadQueue/useXHR:property"}}{{/crossLink}} property is set to.
	 * @property JSON
	 * @type {String}
	 * @default json
	 * @static
	 */
	s.JSON = "json";

	/**
	 * The preload type for jsonp files, usually with the "json" file extension. JSON data is loaded and parsed into a
	 * JavaScript object. You are required to pass a callback parameter that matches the function wrapper in the JSON.
	 * Note that JSONP will always be used if there is a callback present, no matter what the {{#crossLink "LoadQueue/useXHR:property"}}{{/crossLink}}
	 * property is set to.
	 * @property JSONP
	 * @type {String}
	 * @default jsonp
	 * @static
	 */
	s.JSONP = "jsonp";

	/**
	 * The preload type for json-based manifest files, usually with the "json" file extension. The JSON data is loaded
	 * and parsed into a JavaScript object, and parsed. PreloadJS will then look for a "manifest" property in the JSON,
	 * which is an array of files to load, following the same format as the {{#crossLink "LoadQueue/loadManifest"}}{{/crossLink}}
	 * method. If a "callback" is specified on the manifest object, then it will be loaded using JSONP instead,
	 * regardless of what the {{#crossLink "LoadQueue/useXHR:property"}}{{/crossLink}} property is set to.
	 * @property MANIFEST
	 * @type {String}
	 * @default manifest
	 * @static
	 * @since 0.4.1
	 */
	s.MANIFEST = "manifest";

	/**
	 * The preload type for sound files, usually mp3, ogg, or wav. Audio is loaded into an AUDIO tag.
	 * @property SOUND
	 * @type {String}
	 * @default sound
	 * @static
	 */
	s.SOUND = "sound";

	/**
     * The preload type for SVG files.
	 * @property SVG
	 * @type {String}
	 * @default svg
	 * @static
	 */
	s.SVG = "svg";

	/**
	 * The preload type for text files, which is also the default file type if the type can not be determined. Text is
	 * loaded as raw text.
	 * @property TEXT
	 * @type {String}
	 * @default text
	 * @static
	 */
	s.TEXT = "text";

	/**
	 * The preload type for xml files. XML is loaded into an XML document.
	 * @property XML
	 * @type {String}
	 * @default xml
	 * @static
	 */
	s.XML = "xml";

	/**
	 * Defines a POST request, use for a method value when loading data.
	 *
	 * @type {string}
	 */
	s.POST = 'POST';

	/**
	 * Defines a GET request, use for a method value when loading data.
	 *
	 * @type {string}
	 */
	s.GET = 'GET';


// Prototype
	/**
	 * Use XMLHttpRequest (XHR) when possible. Note that LoadQueue will default to tag loading or XHR loading depending
	 * on the requirements for a media type. For example, HTML audio can not be loaded with XHR, and WebAudio can not be
	 * loaded with tags, so it will default the the correct type instead of using the user-defined type.
	 *
	 * <b>Note: This property is read-only.</b> To change it, please use the {{#crossLink "LoadQueue/setUseXHR"}}{{/crossLink}}
	 * method, or specify the `useXHR` argument in the LoadQueue constructor.
	 *
	 * @property useXHR
	 * @type {Boolean}
	 * @readOnly
	 * @default true
	 */
	p.useXHR = true;

	/**
	 * Determines if the LoadQueue will stop processing the current queue when an error is encountered.
	 * @property stopOnError
	 * @type {Boolean}
	 * @default false
	 */
	p.stopOnError = false;

	/**
	 * Ensure loaded scripts "complete" in the order they are specified. Note that scripts loaded via tags will only
	 * load one at a time, and will be added to the document when they are loaded.
	 * @property maintainScriptOrder
	 * @type {Boolean}
	 * @default true
	 */
	p.maintainScriptOrder = true;

	/**
	 * The next preload queue to process when this one is complete. If an error is thrown in the current queue, and
	 * {{#crossLink "LoadQueue/stopOnError:property"}}{{/crossLink}} is `true`, the next queue will not be processed.
	 * @property next
	 * @type {LoadQueue}
	 * @default null
	 */
	p.next = null;

// Events
	/**
	 * This event is fired when an individual file has loaded, and been processed.
	 * @event fileload
	 * @param {Object} target The object that dispatched the event.
	 * @param {String} type The event type.
	 * @param {Object} item The file item which was specified in the {{#crossLink "LoadQueue/loadFile"}}{{/crossLink}}
	 * or {{#crossLink "LoadQueue/loadManifest"}}{{/crossLink}} call. If only a string path or tag was specified, the
	 * object will contain that value as a property.
	 * @param {Object} result The HTML tag or parsed result of the loaded item.
	 * @param {Object} rawResult The unprocessed result, usually the raw text or binary data before it is converted
	 * to a usable object.
	 * @since 0.3.0
	 */

	/**
	 * This event is fired when an an individual file progress changes.
	 * @event fileprogress
	 * @param {Object} The object that dispatched the event.
	 * @param {String} type The event type.
	 * @param {Object} item The file item which was specified in the {{#crossLink "LoadQueue/loadFile"}}{{/crossLink}}
	 * or {{#crossLink "LoadQueue/loadManifest"}}{{/crossLink}} call. If only a string path or tag was specified, the
	 * object will contain that value as a property.
	 * @param {Number} loaded The number of bytes that have been loaded. Note that this may just be a percentage of 1.
	 * @param {Number} total The total number of bytes. If it is unknown, the value is 1.
	 * @param {Number} progress The amount that has been loaded between 0 and 1.
	 * @since 0.3.0
	 */

	/**
	 * This event is fired when an individual file starts to load.
	 * @event filestart
	 * @param {Object} The object that dispatched the event.
	 * @param {String} type The event type.
	 * @param {Object} item The file item which was specified in the {{#crossLink "LoadQueue/loadFile"}}{{/crossLink}}
	 * or {{#crossLink "LoadQueue/loadManifest"}}{{/crossLink}} call. If only a string path or tag was specified, the
	 * object will contain that value as a property.
	 */

	//TODO: Deprecated
	/**
	 * REMOVED. Use {{#crossLink "EventDispatcher/addEventListener"}}{{/crossLink}} and the {{#crossLink "LoadQueue/fileload:event"}}{{/crossLink}}
	 * event.
	 * @property onFileLoad
	 * @type {Function}
	 * @deprecated Use addEventListener and the "fileload" event.
	 */
	/**
	 * REMOVED. Use {{#crossLink "EventDispatcher/addEventListener"}}{{/crossLink}} and the {{#crossLink "LoadQueue/fileprogress:event"}}{{/crossLink}}
	 * event.
	 * @property onFileProgress
	 * @type {Function}
	 * @deprecated Use addEventListener and the "fileprogress" event.
	 */


// Protected
	/**
	 * An object hash of callbacks that are fired for each file type before the file is loaded, giving plugins the
	 * ability to override properties of the load. Please see the {{#crossLink "LoadQueue/installPlugin"}}{{/crossLink}}
	 * method for more information.
	 * @property _typeCallbacks
	 * @type {Object}
	 * @private
	 */
	p._typeCallbacks = null;

	/**
	 * An object hash of callbacks that are fired for each file extension before the file is loaded, giving plugins the
	 * ability to override properties of the load. Please see the {{#crossLink "LoadQueue/installPlugin"}}{{/crossLink}}
	 * method for more information.
	 * @property _extensionCallbacks
	 * @type {null}
	 * @private
	 */
	p._extensionCallbacks = null;

	/**
	 * Determines if the loadStart event was dispatched already. This event is only fired one time, when the first
	 * file is requested.
	 * @property _loadStartWasDispatched
	 * @type {Boolean}
	 * @default false
	 * @private
	 */
	p._loadStartWasDispatched = false;

	/**
	 * The number of maximum open connections that a loadQueue tries to maintain. Please see
	 * {{#crossLink "LoadQueue/setMaxConnections"}}{{/crossLink}} for more information.
	 * @property _maxConnections
	 * @type {Number}
	 * @default 1
	 * @private
	 */
	p._maxConnections = 1;

	/**
	 * Determines if there is currently a script loading. This helps ensure that only a single script loads at once when
	 * using a script tag to do preloading.
	 * @property _currentlyLoadingScript
	 * @type {Boolean}
	 * @private
	 */
	p._currentlyLoadingScript = null;

	/**
	 * An array containing the currently downloading files.
	 * @property _currentLoads
	 * @type {Array}
	 * @private
	 */
	p._currentLoads = null;

	/**
	 * An array containing the queued items that have not yet started downloading.
	 * @property _loadQueue
	 * @type {Array}
	 * @private
	 */
	p._loadQueue = null;

	/**
	 * An array containing downloads that have not completed, so that the LoadQueue can be properly reset.
	 * @property _loadQueueBackup
	 * @type {Array}
	 * @private
	 */
	p._loadQueueBackup = null;

	/**
	 * An object hash of items that have finished downloading, indexed by item IDs.
	 * @property _loadItemsById
	 * @type {Object}
	 * @private
	 */
	p._loadItemsById = null;

	/**
	 * An object hash of items that have finished downloading, indexed by item source.
	 * @property _loadItemsBySrc
	 * @type {Object}
	 * @private
	 */
	p._loadItemsBySrc = null;

	/**
	 * An object hash of loaded items, indexed by the ID of the load item.
	 * @property _loadedResults
	 * @type {Object}
	 * @private
	 */
	p._loadedResults = null;

	/**
	 * An object hash of un-parsed loaded items, indexed by the ID of the load item.
	 * @property _loadedRawResults
	 * @type {Object}
	 * @private
	 */
	p._loadedRawResults = null;

	/**
	 * The number of items that have been requested. This helps manage an overall progress without knowing how large
	 * the files are before they are downloaded.
	 * @property _numItems
	 * @type {Number}
	 * @default 0
	 * @private
	 */
	p._numItems = 0;

	/**
	 * The number of items that have completed loaded. This helps manage an overall progress without knowing how large
	 * the files are before they are downloaded.
	 * @property _numItemsLoaded
	 * @type {Number}
	 * @default 0
	 * @private
	 */
	p._numItemsLoaded = 0;

	/**
	 * A list of scripts in the order they were requested. This helps ensure that scripts are "completed" in the right
	 * order.
	 * @property _scriptOrder
	 * @type {Array}
	 * @private
	 */
	p._scriptOrder = null;

	/**
	 * A list of scripts that have been loaded. Items are added to this list as <code>null</code> when they are
	 * requested, contain the loaded item if it has completed, but not been dispatched to the user, and <code>true</true>
	 * once they are complete and have been dispatched.
	 * @property _loadedScripts
	 * @type {Array}
	 * @private
	 */
	p._loadedScripts = null;

	// Overrides abstract method in AbstractLoader
	p.init = function(useXHR, basePath) {
		this._numItems = this._numItemsLoaded = 0;
		this._paused = false;
		this._loadStartWasDispatched = false;

		this._currentLoads = [];
		this._loadQueue = [];
		this._loadQueueBackup = [];
		this._scriptOrder = [];
		this._loadedScripts = [];
		this._loadItemsById = {};
		this._loadItemsBySrc = {};
		this._loadedResults = {};
		this._loadedRawResults = {};

		// Callbacks for plugins
		this._typeCallbacks = {};
		this._extensionCallbacks = {};

		this._basePath = basePath;
		this.setUseXHR(useXHR);
	};

	/**
	 * Change the usXHR value. Note that if this is set to true, it may fail depending on the browser's capabilities.
	 * @method setUseXHR
	 * @param {Boolean} value The new useXHR value to set.
	 * @return {Boolean} The new useXHR value. If XHR is not supported by the browser, this will return false, even if
	 * the provided value argument was true.
	 * @since 0.3.0
	 */
	p.setUseXHR = function(value) {
		// Determine if we can use XHR. XHR defaults to TRUE, but the browser may not support it.
		//TODO: Should we be checking for the other XHR types? Might have to do a try/catch on the different types similar to createXHR.
		this.useXHR = (value != false && window.XMLHttpRequest != null);
		return this.useXHR;
	};

	/**
	 * Stops all queued and loading items, and clears the queue. This also removes all internal references to loaded
	 * content, and allows the queue to be used again. Items that have not yet started can be kicked off again using
	 * the {{#crossLink "AbstractLoader/load"}}{{/crossLink}} method.
	 * @method removeAll
	 * @since 0.3.0
	 */
	p.removeAll = function() {
		this.remove();
	};

	/**
	 * Stops an item from being loaded, and removes it from the queue. If nothing is passed, all items are removed.
	 * This also removes internal references to loaded item(s).
	 * @method remove
	 * @param {String | Array} idsOrUrls The id or ids to remove from this queue. You can pass an item, an array of
	 * items, or multiple items as arguments.
	 * @since 0.3.0
	 */
	p.remove = function(idsOrUrls) {
		var args = null;

		if (idsOrUrls && !(idsOrUrls instanceof Array)) {
			args = [idsOrUrls];
		} else if (idsOrUrls) {
			args = idsOrUrls;
		} else if (arguments.length > 0) {
			return;
		}

		var itemsWereRemoved = false;

		// Destroy everything
		if (!args) {
			this.close();

			for (var n in this._loadItemsById) {
				this._disposeItem(this._loadItemsById[n]);
			}

			this.init(this.useXHR);

		// Remove specific items
		} else {
			while (args.length) {
				var item = args.pop();
				var r = this.getResult(item);

				//Remove from the main load Queue
				for (i = this._loadQueue.length-1;i>=0;i--) {
					loadItem = this._loadQueue[i].getItem();
					if (loadItem.id == item || loadItem.src == item) {
						this._loadQueue.splice(i,1)[0].cancel();
						break;
					}
				}

				//Remove from the backup queue
				for (i = this._loadQueueBackup.length-1;i>=0;i--) {
					loadItem = this._loadQueueBackup[i].getItem();
					if (loadItem.id == item || loadItem.src == item) {
						this._loadQueueBackup.splice(i,1)[0].cancel();
						break;
					}
				}

				if (r) {
					delete this._loadItemsById[r.id];
					delete this._loadItemsBySrc[r.src];
					this._disposeItem(r);
				} else {
					for (var i=this._currentLoads.length-1;i>=0;i--) {
						var loadItem = this._currentLoads[i].getItem();
						if (loadItem.id == item || loadItem.src == item) {
							this._currentLoads.splice(i,1)[0].cancel();
							itemsWereRemoved = true;
							break;
						}
					}
				}
			}

			// If this was called during a load, try to load the next item.
			if (itemsWereRemoved) {
				this._loadNext();
			}
		}
	};

	/**
	 * Stops all open loads, destroys any loaded items, and resets the queue, so all items can
	 * be reloaded again by calling {{#crossLink "AbstractLoader/load"}}{{/crossLink}}. Items are not removed from the
	 * queue. To remove items use the {{#crossLink "LoadQueue/remove"}}{{/crossLink}} or
	 * {{#crossLink "LoadQueue/removeAll"}}{{/crossLink}} method.
	 * @method reset
	 * @since 0.3.0
	 */
	p.reset = function() {
		this.close();
		for (var n in this._loadItemsById) {
			this._disposeItem(this._loadItemsById[n]);
		}

		//Reset the queue to its start state
		var a = [];
		for (var i=0, l=this._loadQueueBackup.length; i<l; i++) {
			a.push(this._loadQueueBackup[i].getItem());
		}

		this.loadManifest(a, false);
	};

	/**
	 * Determine if a specific type should be loaded as a binary file. Currently, only images and items marked
	 * specifically as "binary" are loaded as binary. Note that audio is <b>not</b> a binary type, as we can not play
	 * back using an audio tag if it is loaded as binary. Plugins can change the item type to binary to ensure they get
	 * a binary result to work with. Binary files are loaded using XHR2.
	 * @method isBinary
	 * @param {String} type The item type.
	 * @return If the specified type is binary.
	 * @private
	 */
	s.isBinary = function(type) {
		switch (type) {
			case createjs.LoadQueue.IMAGE:
			case createjs.LoadQueue.BINARY:
				return true;
			default:
				return false;
		}
	};

	/**
	 * Register a plugin. Plugins can map to load types (sound, image, etc), or specific extensions (png, mp3, etc).
	 * Currently, only one plugin can exist per type/extension.
	 *
	 * When a plugin is installed, a <code>getPreloadHandlers()</code> method will be called on it. For more information
	 * on this method, check out the {{#crossLink "SamplePlugin/getPreloadHandlers"}}{{/crossLink}} method in the
	 * {{#crossLink "SamplePlugin"}}{{/crossLink}} class.
	 *
	 * Before a file is loaded, a matching plugin has an opportunity to modify the load. If a `callback` is returned
	 * from the {{#crossLink "SamplePlugin/getPreloadHandlers"}}{{/crossLink}} method, it will be invoked first, and its
	 * result may cancel or modify the item. The callback method can also return a `completeHandler` to be fired when
	 * the file is loaded, or a `tag` object, which will manage the actual download. For more information on these
	 * methods, check out the {{#crossLink "SamplePlugin/preloadHandler"}}{{/crossLink}} and {{#crossLink "SamplePlugin/fileLoadHandler"}}{{/crossLink}}
	 * methods on the {{#crossLink "SamplePlugin"}}{{/crossLink}}.
	 *
	 * @method installPlugin
	 * @param {Function} plugin The plugin class to install.
	 */
	p.installPlugin = function(plugin) {
		if (plugin == null || plugin.getPreloadHandlers == null) { return; }
		var map = plugin.getPreloadHandlers();
		map.scope = plugin;

		if (map.types != null) {
			for (var i=0, l=map.types.length; i<l; i++) {
				this._typeCallbacks[map.types[i]] = map;
			}
		}
		if (map.extensions != null) {
			for (i=0, l=map.extensions.length; i<l; i++) {
				this._extensionCallbacks[map.extensions[i]] = map;
			}
		}
	};

	/**
	 * Set the maximum number of concurrent connections. Note that browsers and servers may have a built-in maximum
	 * number of open connections, so any additional connections may remain in a pending state until the browser
	 * opens the connection. Note that when loading scripts using tags, and {{#crossLink "LoadQueue/maintainScriptOrder:property"}}{{/crossLink}}
	 * is `true`, only one script is loaded at a time due to browser limitations.
	 * @method setMaxConnections
	 * @param {Number} value The number of concurrent loads to allow. By default, only a single connection per LoadQueue
	 * is open at any time.
	 */
	p.setMaxConnections = function (value) {
		this._maxConnections = value;
		if (!this._paused && this._loadQueue.length > 0) {
			this._loadNext();
		}
	}

	/**
	 * Load a single file. To add multiple files at once, use the {{#crossLink "LoadQueue/loadManifest"}}{{/crossLink}}
	 * method.
	 *
	 * Note that files are always appended to the current queue, so this method can be used multiple times to add files.
	 * To clear the queue first, use the {{#crossLink "AbstractLoader/close"}}{{/crossLink}} method.
	 * @method loadFile
	 * @param {Object | String} file The file object or path to load. A file can be either
     * <ol>
     *     <li>a path to a resource (string). Note that this kind of load item will be
     *     converted to an object (see below) in the background.</li>
     *     <li>OR an object that contains:<ul>
     *         <li>src: The source of the file that is being loaded. This property is <b>required</b>. The source can
	 *         either be a string (recommended), or an HTML tag.</li>
     *         <li>type: The type of file that will be loaded (image, sound, json, etc). PreloadJS does auto-detection
	 *         of types using the extension. Supported types are defined on LoadQueue, such as <code>LoadQueue.IMAGE</code>.
	 *         It is recommended that a type is specified when a non-standard file URI (such as a php script) us used.</li>
     *         <li>id: A string identifier which can be used to reference the loaded object.</li>
	 *         <li>callback: Optional, used for JSONP requests, to define what method to call when the JSONP is loaded.</li>
     *         <li>data: An arbitrary data object, which is included with the loaded object</li>
	 *         <li>method: used to define if this request uses GET or POST when sending data to the server. Default; GET</li>
	 *         <li>values: Optional object of name/value pairs to send to the server.</li>
     *     </ul>
     * </ol>
	 * @param {Boolean} [loadNow=true] Kick off an immediate load (true) or wait for a load call (false). The default
	 * value is true. If the queue is paused using {{#crossLink "LoadQueue/setPaused"}}{{/crossLink}}, and the value is
	 * true, the queue will resume automatically.
	 * @param {String} [basePath] An optional base path prepended to the file source when the file is loaded.
	 * Sources beginning with http:// or similar will not receive a base path.
	 * The load item will not be modified.
	 */
	p.loadFile = function(file, loadNow, basePath) {
		if (file == null) {
			var event = new createjs.Event("error");
			event.text = "PRELOAD_NO_FILE";
			this._sendError(event);
			return;
		}
		this._addItem(file, basePath);

		if (loadNow !== false) {
			this.setPaused(false);
		} else {
			this.setPaused(true);
		}
	}

	/**
	 * Load an array of items. To load a single file, use the {{#crossLink "LoadQueue/loadFile"}}{{/crossLink}} method.
	 * The files in the manifest are requested in the same order, but may complete in a different order if the max
	 * connections are set above 1 using {{#crossLink "LoadQueue/setMaxConnections"}}{{/crossLink}}. Scripts will load
	 * in the right order as long as {{#crossLink "LoadQueue/maintainScriptOrder"}}{{/crossLink}} is true (which is
	 * default).
	 *
	 * Note that files are always appended to the current queue, so this method can be used multiple times to add files.
	 * To clear the queue first, use the {{#crossLink "AbstractLoader/close"}}{{/crossLink}} method.
	 * @method loadManifest
	 * @param {Array|String|Object} manifest The list of files to load. If a single object or string is passed, it will
	 * be loaded the same as a single-item array. Each load item can be either:
	 * <ol>
	 *     <li>a path to a resource (string). Note that this kind of load item will be
	 *      converted to an object (see below) in the background.</li>
	 *     <li>OR an object that contains:<ul>
	 *         <li>src: The source of the file that is being loaded. This property is <b>required</b>.
	 *         The source can either be a string (recommended), or an HTML tag. </li>
	 *         <li>type: The type of file that will be loaded (image, sound, json, etc). PreloadJS does auto-detection
	 *         of types using the extension. Supported types are defined on LoadQueue, such as <code>LoadQueue.IMAGE</code>.
	 *         It is recommended that a type is specified when a non-standard file URI (such as a php script) us used.</li>
	 *         <li>id: A string identifier which can be used to reference the loaded object.</li>
	 *         <li>data: An arbitrary data object, which is returned with the loaded object</li>
	 *     </ul>
	 * </ol>
	 * @param {Boolean} [loadNow=true] Kick off an immediate load (true) or wait for a load call (false). The default
	 * value is true. If the queue is paused using {{#crossLink "LoadQueue/setPaused"}}{{/crossLink}} and this value is
	 * true, the queue will resume automatically.
	 * @param {String} [basePath] An optional base path prepended to each of the files' source when the file is loaded.
	 * Sources beginning with http:// or similar will not receive a base path.
	 * The load items will not be modified.
	 */
	p.loadManifest = function(manifest, loadNow, basePath) {
		var data = null;

		// Proper list of items
		if (manifest instanceof Array) {
			if (manifest.length == 0) {
				var event = new createjs.Event("error");
				event.text = "PRELOAD_MANIFEST_EMPTY";
				this._sendError(event);
				return;
			}
			data = manifest;

		} else {

			// Empty/null
			if (manifest == null) {
				var event = new createjs.Event("error");
				event.text = "PRELOAD_MANIFEST_NULL";
				this._sendError(event);
				return;
			}

			data = [manifest];
		}

		for (var i=0, l=data.length; i<l; i++) {
			this._addItem(data[i], basePath);
		}

		if (loadNow !== false) {
			this.setPaused(false);
		} else {
			this.setPaused(true);
		}

	};

	// Overrides abstract method in AbstractLoader
	p.load = function() {
		this.setPaused(false);
	};

	/**
	 * Look up a load item using either the "id" or "src" that was specified when loading it.
	 * @method getItem
	 * @param {String} value The <code>id</code> or <code>src</code> of the load item.
	 * @return {Object} The load item that was initially requested using {{#crossLink "LoadQueue/loadFile"}}{{/crossLink}}
	 * or {{#crossLink "LoadQueue/loadManifest"}}{{/crossLink}}. This object is also returned via the "fileload" event
	 * as the "item" parameter.
	 */
	p.getItem = function(value) {
		return this._loadItemsById[value] || this._loadItemsBySrc[value];
	};

	/**
	 * Look up a loaded result using either the "id" or "src" that was specified when loading it.
	 * @method getResult
	 * @param {String} value The <code>id</code> or <code>src</code> of the load item.
	 * @param {Boolean} [rawResult=false] Return a raw result instead of a formatted result. This applies to content
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
	 *      <li>An audio tag (&lt;audio &gt;) for HTML audio. Note that it is recommended to use SoundJS APIs to play
	 *      loaded audio. Specifically, audio loaded by Flash and WebAudio will return a loader object using this method
	 *      which can not be used to play audio back.</li>
	 * </ul>
     * This object is also returned via the "fileload" event as the "item" parameter. Note that if a raw result is
	 * requested, but not found, the result will be returned instead.
	 */
	p.getResult = function(value, rawResult) {
		var item = this._loadItemsById[value] || this._loadItemsBySrc[value];
		if (item == null) { return null; }
		var id = item.id;
		if (rawResult && this._loadedRawResults[id]) {
			return this._loadedRawResults[id];
		}
		return this._loadedResults[id];
	};

	/**
	 * Pause or resume the current load. Active loads will not be cancelled, but the next items in the queue will not
	 * be processed when active loads complete. LoadQueues are not paused by default.
	 * @method setPaused
	 * @param {Boolean} value Whether the queue should be paused or not.
	 */
	p.setPaused = function(value) {
		this._paused = value;
		if (!this._paused) {
			this._loadNext();
		}
	};

	// Overrides abstract method in AbstractLoader
	p.close = function() {
		while (this._currentLoads.length) {
			this._currentLoads.pop().cancel();
		}
		this._scriptOrder.length = 0;
		this._loadedScripts.length = 0;
		this.loadStartWasDispatched = false;
	};


//Protected Methods
	/**
	 * Add an item to the queue. Items are formatted into a usable object containing all the properties necessary to
	 * load the content. The load queue is populated with the loader instance that handles preloading, and not the load
	 * item that was passed in by the user. To look up the load item by id or src, use the {{#crossLink "LoadQueue.getItem"}}{{/crossLink}}
	 * method.
	 * @method _addItem
	 * @param {String|Object} value The item to add to the queue.
	 * @param {String} basePath A path to prepend to the item's source.
	 * 	Sources beginning with http:// or similar will not receive a base path.
	 * @private
	 */
	p._addItem = function(value, basePath) {
		var item = this._createLoadItem(value);
		if (item == null) { return; } // Sometimes plugins or types should be skipped.
		var loader = this._createLoader(item, basePath);
		if (loader != null) {
			this._loadQueue.push(loader);
			this._loadQueueBackup.push(loader);

			this._numItems++;
			this._updateProgress();

			// Only worry about script order when using XHR to load scripts. Tags are only loading one at a time.
			if (this.maintainScriptOrder
					&& item.type == createjs.LoadQueue.JAVASCRIPT
					&& loader instanceof createjs.XHRLoader) {
				this._scriptOrder.push(item);
				this._loadedScripts.push(null);
			}
		}
	};

	/**
	 * Create a refined load item, which contains all the required properties (src, type, extension, tag). The type of
	 * item is determined by browser support, requirements based on the file type, and developer settings. For example,
	 * XHR is only used for file types that support it in new browsers.
	 *
	 * Before the item is returned, any plugins registered to handle the type or extension will be fired, which may
	 * alter the load item.
	 * @method _createLoadItem
	 * @param {String | Object | HTMLAudioElement | HTMLImageElement} value The item that needs to be preloaded.
	 * @return {Object} The loader instance that will be used.
	 * @private
	 */
	p._createLoadItem = function(value) {
		var item = null;

		// Create/modify a load item
		switch(typeof(value)) {
			case "string":
				item = {
					src: value
				}; break;
			case "object":
				if (window.HTMLAudioElement && value instanceof HTMLAudioElement) {
					item = {
						tag: value,
						src: item.tag.src,
						type: createjs.LoadQueue.SOUND
					};
				} else {
					item = value;
				}
				break;
			default:
				return null;
		}

		// Note: This does NOT account for basePath. It should be fine.
		var match = this._parseURI(item.src);
		if (match != null) { item.ext = match[5]; }
		if (item.type == null) {
			item.type = this._getTypeByExtension(item.ext);
		}

		if (item.type == createjs.LoadQueue.JSON || item.type == createjs.LoadQueue.MANIFEST) {
			item._loadAsJSONP = (item.callback != null);
		}

		if (item.type == createjs.LoadQueue.JSONP && item.callback == null) {
			throw new Error('callback is required for loading JSONP requests.');
		}

		// Create a tag for the item. This ensures there is something to either load with or populate when finished.
		if (item.tag == null) {
			item.tag = this._createTag(item.type);
		}

		// If there's no id, set one now.
		if (item.id == null || item.id == "") {
            item.id = item.src;
		}

		// Give plugins a chance to modify the loadItem:
		var customHandler = this._typeCallbacks[item.type] || this._extensionCallbacks[item.ext];
		if (customHandler) {
			var result = customHandler(item.src, item.type, item.id, item.data);
			//Plugin will handle the load, so just ignore it.
			if (result === false) {
				return null;

			// Load as normal:
			} else if (result === true) {
				// Do Nothing

			// Result is a loader class:
			} else {
				if (result.src != null) { item.src = result.src; }
				if (result.id != null) { item.id = result.id; }
				if (result.tag != null && result.tag.load instanceof Function) { //Item has what we need load
					item.tag = result.tag;
				}
                if (result.completeHandler != null) {item.completeHandler = result.completeHandler;}  // we have to call back this function when we are done loading
			}

			// Allow type overriding:
			if (result.type) { item.type = result.type; }

			// Update the extension in case the type changed:
			match = this._parseURI(item.src);
			if (match != null && match[5] != null) { item.ext = match[5].toLowerCase(); }
		}

		// Store the item for lookup. This also helps clean-up later.
		this._loadItemsById[item.id] = item;
		this._loadItemsBySrc[item.src] = item;

		return item;
	};

	/**
	 * Create a loader for a load item.
	 * @method _createLoader
	 * @param {Object} item A formatted load item that can be used to generate a loader.
	 * @param {String} basePath A path that will be prepended on to the source parameter of all items in the queue before they are loaded. Note that a basePath provided to any loadFile or loadManifest call will override the basePath specified on the LoadQueue constructor.
	 * @return {AbstractLoader} A loader that can be used to load content.
	 * @private
	 */
	p._createLoader = function(item, basePath) {
		// Initially, try and use the provided/supported XHR mode:
		var useXHR = this.useXHR;

		// Determine the XHR usage overrides:
		switch (item.type) {
			case createjs.LoadQueue.JSON:
			case createjs.LoadQueue.MANIFEST:
				useXHR = !item._loadAsJSONP;
				break;
			case createjs.LoadQueue.XML:
			case createjs.LoadQueue.TEXT:
				useXHR = true; // Always use XHR2 with text/XML
				break;
			case createjs.LoadQueue.SOUND:
			case createjs.LoadQueue.JSONP:
				useXHR = false; // Never load audio using XHR. WebAudio will provide its own loader.
				break;
			case null:
				return null;
			// Note: IMAGE, CSS, SCRIPT, SVG can all use TAGS or XHR.
		}

		// If no basepath was provided here (from _addItem), then use the LoadQueue._basePath instead.
		if (basePath == null) { basePath = this._basePath; }

		if (useXHR) {
			return new createjs.XHRLoader(item, basePath);
		} else {
			return new createjs.TagLoader(item, basePath);
		}
	};


	/**
	 * Load the next item in the queue. If the queue is empty (all items have been loaded), then the complete event
	 * is processed. The queue will "fill up" any empty slots, up to the max connection specified using
	 * {{#crossLink "LoadQueue.setMaxConnections"}}{{/crossLink}} method. The only exception is scripts that are loaded
	 * using tags, which have to be loaded one at a time to maintain load order.
	 * @method _loadNext
	 * @private
	 */
	p._loadNext = function() {
		if (this._paused) { return; }

		// Only dispatch loadstart event when the first file is loaded.
		if (!this._loadStartWasDispatched) {
			this._sendLoadStart();
			this._loadStartWasDispatched = true;
		}

		// The queue has completed.
		if (this._numItems == this._numItemsLoaded) {
			this.loaded = true;
			this._sendComplete();

			// Load the next queue, if it has been defined.
			if (this.next && this.next.load) {
				this.next.load();
			}
		} else {
			this.loaded = false;
		}

		// Must iterate forwards to load in the right order.
		for (var i=0; i<this._loadQueue.length; i++) {
			if (this._currentLoads.length >= this._maxConnections) { break; }
			var loader = this._loadQueue[i];

			// Determine if we should be only loading one at a time:
			if (this.maintainScriptOrder
					&& loader instanceof createjs.TagLoader
					&& loader.getItem().type == createjs.LoadQueue.JAVASCRIPT) {
				if (this._currentlyLoadingScript) { continue; } // Later items in the queue might not be scripts.
				this._currentlyLoadingScript = true;
			}
			this._loadQueue.splice(i, 1);
  			i--;
            this._loadItem(loader);
		}
	};

	/**
	 * Begin loading an item. Events are not added to the loaders until the load starts.
	 * @method _loadItem
	 * @param {AbstractLoader} loader The loader instance to start. Currently, this will be an XHRLoader or TagLoader.
	 * @private
	 */
	p._loadItem = function(loader) {
		loader.on("progress", this._handleProgress, this);
		loader.on("complete", this._handleFileComplete, this);
		loader.on("error", this._handleFileError, this);
		this._currentLoads.push(loader);
		this._sendFileStart(loader.getItem());
		loader.load();
	};

	/**
	 * The callback that is fired when a loader encounters an error. The queue will continue loading unless {{#crossLink "LoadQueue/stopOnError:property"}}{{/crossLink}}
	 * is set to `true`.
	 * @method _handleFileError
	 * @param {Object} event The error event, containing relevant error information.
	 * @private
	 */
	p._handleFileError = function(event) {
		var loader = event.target;
		this._numItemsLoaded++;
		this._updateProgress();

		var event = new createjs.Event("error");
		event.text = "FILE_LOAD_ERROR";
		event.item = loader.getItem();
		// TODO: Propagate actual error message.

		this._sendError(event);

		if (!this.stopOnError) {
			this._removeLoadItem(loader);
			this._loadNext();
		}
	};

	/**
	 * An item has finished loading. We can assume that it is totally loaded, has been parsed for immediate use, and
	 * is available as the "result" property on the load item. The raw text result for a parsed item (such as JSON, XML,
	 * CSS, JavaScript, etc) is available as the "rawResult" event, and can also be looked up using {{#crossLink "LoadQueue/getResult"}}{{/crossLink}}.
	 * @method _handleFileComplete
	 * @param {Object} event The event object from the loader.
	 * @private
	 */
	p._handleFileComplete = function(event) {
		var loader = event.target;
		var item = loader.getItem();

		this._loadedResults[item.id] = loader.getResult();
		if (loader instanceof createjs.XHRLoader) {
			this._loadedRawResults[item.id] = loader.getResult(true);
		}

		this._removeLoadItem(loader);

		// Ensure that script loading happens in the right order.
		if (this.maintainScriptOrder && item.type == createjs.LoadQueue.JAVASCRIPT) {
			if (loader instanceof createjs.TagLoader) {
				this._currentlyLoadingScript = false;
			} else {
				this._loadedScripts[createjs.indexOf(this._scriptOrder, item)] = item;
				this._checkScriptLoadOrder(loader);
				return;
			}
		}

		delete item._loadAsJSONP;
		if (item.type == createjs.LoadQueue.MANIFEST) {
			var manifest, result = loader.getResult();
			if (result != null && (manifest = result.manifest)) {
				this.loadManifest(manifest);
			}
		}

		this._processFinishedLoad(item, loader);
	}

	p._processFinishedLoad = function(item, loader) {
		// Old handleFileTagComplete follows here.
		this._numItemsLoaded++;

		this._updateProgress();
		this._sendFileComplete(item, loader);

		this._loadNext();
	};

	/**
	 * Ensure the scripts load and dispatch in the correct order. When using XHR, scripts are stored in an array in the
	 * order they were added, but with a "null" value. When they are completed, the value is set to the load item,
	 * and then when they are processed and dispatched, the value is set to <code>true</code>. This method simply
	 * iterates the array, and ensures that any loaded items that are not preceded by a <code>null</code> value are
	 * dispatched.
	 * @method _checkScriptLoadOrder
	 * @private
	 */
	p._checkScriptLoadOrder = function () {
		var l = this._loadedScripts.length;

		for (var i=0;i<l;i++) {
			var item = this._loadedScripts[i];
			if (item === null) { break; } // This is still loading. Do not process further.
			if (item === true) { continue; } // This has completed, and been processed. Move on.

			// This item has finished, and is the next one to get dispatched.
			this._processFinishedLoad(item);
			this._loadedScripts[i] = true;
			i--; l--;
		}
	};

	/**
	 * A load item is completed or was canceled, and needs to be removed from the LoadQueue.
	 * @method _removeLoadItem
	 * @param {AbstractLoader} loader A loader instance to remove.
	 * @private
	 */
	p._removeLoadItem = function(loader) {
		var l = this._currentLoads.length;
		for (var i=0;i<l;i++) {
			if (this._currentLoads[i] == loader) {
				this._currentLoads.splice(i,1); break;
			}
		}
	};

	/**
	 * An item has dispatched progress. Propagate that progress, and update the LoadQueue overall progress.
	 * @method _handleProgress
	 * @param {Object} event The progress event from the item.
	 * @private
	 */
	p._handleProgress = function(event) {
		var loader = event.target;
		this._sendFileProgress(loader.getItem(), loader.progress);
		this._updateProgress();
	};

	/**
	 * Overall progress has changed, so determine the new progress amount and dispatch it. This changes any time an
	 * item dispatches progress or completes. Note that since we don't know the actual filesize of items before they are
	 * loaded, and even then we can only get the size of items loaded with XHR. In this case, we define a "slot" for
	 * each item (1 item in 10 would get 10%), and then append loaded progress on top of the already-loaded items.
	 *
	 * For example, if 5/10 items have loaded, and item 6 is 20% loaded, the total progress would be:<ul>
	 *      <li>5/10 of the items in the queue (50%)</li>
	 *      <li>plus 20% of item 6's slot (2%)</li>
	 *      <li>equals 52%</li></ul>
	 * @method _updateProgress
	 * @private
	 */
	p._updateProgress = function () {
		var loaded = this._numItemsLoaded / this._numItems; // Fully Loaded Progress
		var remaining = this._numItems-this._numItemsLoaded;
		if (remaining > 0) {
			var chunk = 0;
			for (var i=0, l=this._currentLoads.length; i<l; i++) {
				chunk += this._currentLoads[i].progress;
			}
			loaded += (chunk / remaining) * (remaining/this._numItems);
		}
		this._sendProgress(loaded);
	}

	/**
	 * Clean out item results, to free them from memory. Mainly, the loaded item and results are cleared from internal
	 * hashes.
	 * @method _disposeItem
	 * @param {Object} item The item that was passed in for preloading.
	 * @private
	 */
	p._disposeItem = function(item) {
		delete this._loadedResults[item.id];
		delete this._loadedRawResults[item.id];
		delete this._loadItemsById[item.id];
		delete this._loadItemsBySrc[item.src];
	};


	/**
	 * Create an HTML tag. This is in LoadQueue instead of {{#crossLink "TagLoader"}}{{/crossLink}} because no matter
	 * how we load the data, we may need to return it in a tag.
	 * @method _createTag
	 * @param {String} type The item type. Items are passed in by the developer, or deteremined by the extension.
	 * @return {HTMLImageElement|HTMLAudioElement|HTMLScriptElement|HTMLLinkElement|Object} The tag that is created.
	 * Note that tags are not appended to the HTML body.
	 * @private
	 */
	p._createTag = function(type) {
		var tag = null;
		switch (type) {
			case createjs.LoadQueue.IMAGE:
				return document.createElement("img");
			case createjs.LoadQueue.SOUND:
				tag = document.createElement("audio");
				tag.autoplay = false;
				// Note: The type property doesn't seem necessary.
				return tag;
			case createjs.LoadQueue.JSON:
			case createjs.LoadQueue.JSONP:
			case createjs.LoadQueue.JAVASCRIPT:
			case createjs.LoadQueue.MANIFEST:
				tag = document.createElement("script");
				tag.type = "text/javascript";
				return tag;
			case createjs.LoadQueue.CSS:
				if (this.useXHR) {
					tag = document.createElement("style");
				} else {
					tag = document.createElement("link");
				}
				tag.rel  = "stylesheet";
				tag.type = "text/css";
				return tag;
			case createjs.LoadQueue.SVG:
				if (this.useXHR) {
					tag = document.createElement("svg");
				} else {
					tag = document.createElement("object");
					tag.type = "image/svg+xml";
				}
				return tag;
		}
		return null;
	};

	/**
	 * Determine the type of the object using common extensions. Note that the type can be passed in with the load item
	 * if it is an unusual extension.
	 * @param {String} extension The file extension to use to determine the load type.
	 * @return {String} The determined load type (for example, <code>LoadQueue.IMAGE</code> or null if it can not be
	 * determined by the extension.
	 * @private
	 */
	p._getTypeByExtension = function(extension) {
		if (extension == null) {
			return createjs.LoadQueue.TEXT;
		}
		switch (extension.toLowerCase()) {
			case "jpeg":
			case "jpg":
			case "gif":
			case "png":
			case "webp":
			case "bmp":
				return createjs.LoadQueue.IMAGE;
			case "ogg":
			case "mp3":
			case "wav":
				return createjs.LoadQueue.SOUND;
			case "json":
				return createjs.LoadQueue.JSON;
			case "xml":
				return createjs.LoadQueue.XML;
			case "css":
				return createjs.LoadQueue.CSS;
			case "js":
				return createjs.LoadQueue.JAVASCRIPT;
			case 'svg':
				return createjs.LoadQueue.SVG;
			default:
				return createjs.LoadQueue.TEXT;
		}
	};

	/**
	 * Dispatch a fileprogress event (and onFileProgress callback). Please see the <code>LoadQueue.fileprogress</code>
	 * event for details on the event payload.
	 * @method _sendFileProgress
	 * @param {Object} item The item that is being loaded.
	 * @param {Number} progress The amount the item has been loaded (between 0 and 1).
	 * @protected
	 */
	p._sendFileProgress = function(item, progress) {
		if (this._isCanceled()) {
			this._cleanUp();
			return;
		}
		if (!this.hasEventListener("fileprogress")) { return; }

		var event = new createjs.Event("fileprogress");
		event.progress = progress;
		event.loaded = progress;
		event.total = 1;
		event.item = item;

		this.dispatchEvent(event);
	};

	/**
	 * Dispatch a fileload event. Please see the {{#crossLink "LoadQueue/fileload:event"}}{{/crossLink}} event for
	 * details on the event payload.
	 * @method _sendFileComplete
	 * @param {Object} item The item that is being loaded.
	 * @param {TagLoader | XHRLoader} loader
	 * @protected
	 */
	p._sendFileComplete = function(item, loader) {
		if (this._isCanceled()) { return; }

		var event = new createjs.Event("fileload");
		event.loader = loader;
		event.item = item;
		event.result = this._loadedResults[item.id];
		event.rawResult = this._loadedRawResults[item.id];

        // This calls a handler specified on the actual load item. Currently, the SoundJS plugin uses this.
        if (item.completeHandler) {
            item.completeHandler(event);
        }

		this.hasEventListener("fileload") && this.dispatchEvent(event)
	};

	/**
	 * Dispatch a filestart event immediately before a file starts to load. Please see the {{#crossLink "LoadQueue/filestart:event"}}{{/crossLink}}
	 * event for details on the event payload.
	 * @method _sendFileStart
	 * @param {TagLoader | XHRLoader} loader
	 * @protected
	 */
	p._sendFileStart = function(item) {
		var event = new createjs.Event("filestart");
		event.item = item;
		this.hasEventListener("filestart") && this.dispatchEvent(event);
	};

	/**
	 * REMOVED.  Use createjs.proxy instead
	 * @method proxy
	 * @param {Function} method The function to call
	 * @param {Object} scope The scope to call the method name on
	 * @static
	 * @private
	 * @deprecated In favour of the createjs.proxy method (see LoadQueue source).
	 */

	p.toString = function() {
		return "[PreloadJS LoadQueue]";
	};

	createjs.LoadQueue = LoadQueue;


// Helper methods

	// An additional module to determine the current browser, version, operating system, and other environmental variables.
	var BrowserDetect = function() {}

	BrowserDetect.init = function() {
		var agent = navigator.userAgent;
		BrowserDetect.isFirefox = (agent.indexOf("Firefox") > -1);
		BrowserDetect.isOpera = (window.opera != null);
		BrowserDetect.isChrome = (agent.indexOf("Chrome") > -1);
		BrowserDetect.isIOS = agent.indexOf("iPod") > -1 || agent.indexOf("iPhone") > -1 || agent.indexOf("iPad") > -1;
	}

	BrowserDetect.init();

	createjs.LoadQueue.BrowserDetect = BrowserDetect;

}());
/*
* TagLoader
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
 * @module PreloadJS
 */

// namespace:
this.createjs = this.createjs||{};

(function() {
	"use strict";
	/**
	 * A preloader that loads items using a tag-based approach. HTML audio and images can use this loader to load
	 * content cross-domain without security errors, whereas anything loaded with XHR has potential issues with cross-
	 * domain requests.
	 *
	 * Note for audio tags, TagLoader relies on the <code>canPlayThrough</code> event, which fires when the buffer
	 * is full enough to play the audio all the way through at the current download speed. This completely preloads most
	 * sound effects, however longer tracks like background audio will only load a portion before the event is fired.
	 * Most browsers (all excluding Chrome) will continue to preload once this is fired, so this is considered good
	 * enough for most cases.
	 * @class TagLoader
	 * @constructor
	 * @extends AbstractLoader
	 * @param {Object} item The item to load. Please see {{#crossLink "LoadQueue/loadFile"}}{{/crossLink}} for
	 * information on load items.
	 */
	var TagLoader = function (item, basePath) {
		this.init(item, basePath);
	};

	var p = TagLoader.prototype = new createjs.AbstractLoader();

// Protected

	/**
	 * The timeout that is fired if nothing is loaded after a certain delay. See the <code>LoadQueue.LOAD_TIMEOUT</code>
	 * for the timeout duration.
	 * @property _loadTimeout
	 * @type {Number}
	 * @private
	 */
	p._loadTimeout = null;

	/**
	 * A reference to a bound function, which we need in order to properly remove the event handler when the load
	 * completes.
	 * @property _tagCompleteProxy
	 * @type {Function}
	 * @private
	 */
	p._tagCompleteProxy = null;

	/**
	 * Determines if the load item is an audio tag, since we take some specific approaches to properly load audio.
	 * @property _isAudio
	 * @type {Boolean}
	 * @default false
	 */
	p._isAudio = false;

	/**
	 * The HTML tag or JavaScript object this loader uses to preload content. Note that a tag may be a custom object
	 * that matches the API of an HTML tag (load method, onload callback). For example, flash audio from SoundJS passes
	 * in a custom object to handle preloading for Flash audio and WebAudio.
	 * @property _tag
	 * @type {HTMLAudioElement | Object}
	 * @private
	 */
	p._tag = null;

	/**
	 * When loading a JSONP request this will be the parsed JSON result.
	 *
	 * @type {Object}
	 * @private
	 */
	p._jsonResult = null;

	// Overrides abstract method in AbstractLoader
	p.init = function (item, basePath) {
		this._item = item;
		this._basePath = basePath;
		this._tag = item.tag;
		this._isAudio = (window.HTMLAudioElement && item.tag instanceof HTMLAudioElement);
		this._tagCompleteProxy = createjs.proxy(this._handleLoad, this);
	};

	/**
	 * Get the loaded content. This is usually an HTML tag or other tag-style object that has been fully loaded. If the
	 * loader is not complete, this will be null.
	 * @method getResult
	 * @return {HTMLImageElement | HTMLAudioElement | Object} The loaded and parsed content.
	 */
	p.getResult = function() {
		if (this._item.type == createjs.LoadQueue.JSONP || this._item.type == createjs.LoadQueue.MANIFEST) {
			return this._jsonResult;
		} else {
			return this._tag;
		}
	};

	// Overrides abstract method in AbstractLoader
	p.cancel = function() {
		this.canceled = true;
		this._clean();
		var item = this.getItem();
	};

	// Overrides abstract method in AbstractLoader
	p.load = function() {
		var item = this._item;
		var tag = this._tag;

		// In case we don't get any events.
		clearTimeout(this._loadTimeout); // Clear out any existing timeout
		this._loadTimeout = setTimeout(createjs.proxy(this._handleTimeout, this), createjs.LoadQueue.LOAD_TIMEOUT);

		if (this._isAudio) {
			tag.src = null; // Unset the source so we can set the preload type to "auto" without kicking off a load. This is only necessary for audio tags passed in by the developer.
			tag.preload = "auto";
		}

		// Handlers for all tags
		tag.onerror = createjs.proxy(this._handleError,  this);
		// Note: We only get progress events in Chrome, but do not fully load tags in Chrome due to its behaviour, so we ignore progress.

		if (this._isAudio) {
			tag.onstalled = createjs.proxy(this._handleStalled,  this);
			// This will tell us when audio is buffered enough to play through, but not when its loaded.
			// The tag doesn't keep loading in Chrome once enough has buffered, and we have decided that behaviour is sufficient.
			tag.addEventListener("canplaythrough", this._tagCompleteProxy, false); // canplaythrough callback doesn't work in Chrome, so we use an event.
		} else {
			tag.onload = createjs.proxy(this._handleLoad,  this);
			tag.onreadystatechange = createjs.proxy(this._handleReadyStateChange,  this);
		}

		var src = this.buildPath(item.src, this._basePath, item.values);

		// Set the src after the events are all added.
		switch(item.type) {
			case createjs.LoadQueue.CSS:
				tag.href = src;
				break;
			case createjs.LoadQueue.SVG:
				tag.data = src;
				break;
			default:
				tag.src = src;
		}

		// If we're loading JSONP, we need to add our callback now.
		if (item.type == createjs.LoadQueue.JSONP
				|| item.type == createjs.LoadQueue.JSON
				|| item.type == createjs.LoadQueue.MANIFEST) {
			if (item.callback == null) {
				throw new Error('callback is required for loading JSONP requests.');
			}

			if (window[item.callback] != null) {
				throw new Error('JSONP callback "' + item.callback + '" already exists on window. You need to specify a different callback. Or re-name the current one.');
			}

			window[item.callback] = createjs.proxy(this._handleJSONPLoad, this);
		}

		// If its SVG, it needs to be on the DOM to load (we remove it before sending complete).
		// It is important that this happens AFTER setting the src/data.
		if (item.type == createjs.LoadQueue.SVG ||
			item.type == createjs.LoadQueue.JSONP ||
			item.type == createjs.LoadQueue.JSON ||
			item.type == createjs.LoadQueue.MANIFEST ||
			item.type == createjs.LoadQueue.JAVASCRIPT ||
			item.type == createjs.LoadQueue.CSS) {
				this._startTagVisibility = tag.style.visibility;
				tag.style.visibility = "hidden";
				(document.body || document.getElementsByTagName("body")[0]).appendChild(tag);
		}

		// Note: Previous versions didn't seem to work when we called load() for OGG tags in Firefox. Seems fixed in 15.0.1
		if (tag.load != null) {
			tag.load();
		}
	};

	p._handleJSONPLoad = function(data) {
		this._jsonResult = data;
	};

	/**
	 * Handle an audio timeout. Newer browsers get a callback from the tags, but older ones may require a setTimeout
	 * to handle it. The setTimeout is always running until a response is handled by the browser.
	 * @method _handleTimeout
	 * @private
	 */
	p._handleTimeout = function() {
		this._clean();
		var event = new createjs.Event("error");
		event.text = "PRELOAD_TIMEOUT";
		this._sendError(event);
	};

	/**
	 * Handle a stalled audio event. The main place we seem to get these is with HTMLAudio in Chrome when we try and
	 * playback audio that is already in a load, but not complete.
	 * @method _handleStalled
	 * @private
	 */
	p._handleStalled = function() {
		//Ignore, let the timeout take care of it. Sometimes its not really stopped.
	};

	/**
	 * Handle an error event generated by the tag.
	 * @method _handleError
	 * @private
	 */
	p._handleError = function(event) {
		this._clean();

		var newEvent = new createjs.Event("error");
		//TODO: Propagate actual event error?
		this._sendError(newEvent);
	};

	/**
	 * Handle the readyStateChange event from a tag. We sometimes need this in place of the onload event (mainly SCRIPT
	 * and LINK tags), but other cases may exist.
	 * @method _handleReadyStateChange
	 * @private
	 */
	p._handleReadyStateChange = function() {
		clearTimeout(this._loadTimeout);
		// This is strictly for tags in browsers that do not support onload.
		var tag = this.getItem().tag;

		// Complete is for old IE support.
		if (tag.readyState == "loaded" || tag.readyState == "complete") {
			this._handleLoad();
		}
	};

	/**
	 * Handle a load (complete) event. This is called by tag callbacks, but also by readyStateChange and canPlayThrough
	 * events. Once loaded, the item is dispatched to the {{#crossLink "LoadQueue"}}{{/crossLink}}.
	 * @method _handleLoad
	 * @param {Object} [event] A load event from a tag. This is sometimes called from other handlers without an event.
	 * @private
	 */
	p._handleLoad = function(event) {
		if (this._isCanceled()) { return; }

		var item = this.getItem();
		var tag = item.tag;

		if (this.loaded || this.isAudio && tag.readyState !== 4) { return; } //LM: Not sure if we still need the audio check.
		this.loaded = true;

		// Remove from the DOM
		switch (item.type) {
			case createjs.LoadQueue.SVG:
			case createjs.LoadQueue.JSONP: // Note: Removing script tags is a fool's errand.
			case createjs.LoadQueue.MANIFEST:
				// case createjs.LoadQueue.CSS:
				//LM: We may need to remove CSS tags loaded using a LINK
				tag.style.visibility = this._startTagVisibility;
				(document.body || document.getElementsByTagName("body")[0]).removeChild(tag);
			break;
			default:
		}

		this._clean();
		this._sendComplete();
	};

	/**
	 * Clean up the loader.
	 * This stops any timers and removes references to prevent errant callbacks and clean up memory.
	 * @method _clean
	 * @private
	 */
	p._clean = function() {
		clearTimeout(this._loadTimeout);

		// Delete handlers.
		var tag = this.getItem().tag;
		tag.onload = null;
		tag.removeEventListener && tag.removeEventListener("canplaythrough", this._tagCompleteProxy, false);
		tag.onstalled = null;
		tag.onprogress = null;
		tag.onerror = null;

		//TODO: Test this
		if (tag.parentNode) {
			tag.parentNode.removeChild(tag);
		}

		var item = this.getItem();
		if (item.type == createjs.LoadQueue.JSONP
			|| item.type == createjs.LoadQueue.MANIFEST) {
			window[item.callback] = null;
		}
	};

	p.toString = function() {
		return "[PreloadJS TagLoader]";
	}

	createjs.TagLoader = TagLoader;

}());
/*
 * XHRLoader
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
 * @module PreloadJS
 */

// namespace:
this.createjs = this.createjs || {};

(function () {
	"use strict";

	/**
	 * A preloader that loads items using XHR requests, usually XMLHttpRequest. However XDomainRequests will be used
	 * for cross-domain requests if possible, and older versions of IE fall back on to ActiveX objects when necessary.
	 * XHR requests load the content as text or binary data, provide progress and consistent completion events, and
	 * can be canceled during load. Note that XHR is not supported in IE 6 or earlier, and is not recommended for
	 * cross-domain loading.
	 * @class XHRLoader
	 * @constructor
	 * @param {Object} item The object that defines the file to load. Please see the {{#crossLink "LoadQueue/loadFile"}}{{/crossLink}}
	 * for an overview of supported file properties.
	 * @extends AbstractLoader
	 */
	var XHRLoader = function (item, basePath) {
		this.init(item, basePath);
	};

	var p = XHRLoader.prototype = new createjs.AbstractLoader();

	//Protected
	/**
	 * A reference to the XHR request used to load the content.
	 * @property _request
	 * @type {XMLHttpRequest | XDomainRequest | ActiveX.XMLHTTP}
	 * @private
	 */
	p._request = null;

	/**
	 * A manual load timeout that is used for browsers that do not support the onTimeout event on XHR (XHR level 1,
	 * typically IE9).
	 * @property _loadTimeout
	 * @type {Number}
	 * @private
	 */
	p._loadTimeout = null;

	/**
	 * The browser's XHR (XMLHTTPRequest) version. Supported versions are 1 and 2. There is no official way to detect
	 * the version, so we use capabilities to make a best guess.
	 * @property _xhrLevel
	 * @type {Number}
	 * @default 1
	 * @private
	 */
	p._xhrLevel = 1;

	/**
	 * The response of a loaded file. This is set because it is expensive to look up constantly. This property will be
	 * null until the file is loaded.
	 * @property _response
	 * @type {mixed}
	 * @private
	 */
	p._response = null;

	/**
	 * The response of the loaded file before it is modified. In most cases, content is converted from raw text to
	 * an HTML tag or a formatted object which is set to the <code>result</code> property, but the developer may still
	 * want to access the raw content as it was loaded.
	 * @property _rawResponse
	 * @type {String|Object}
	 * @private
	 */
	p._rawResponse = null;

	// Overrides abstract method in AbstractLoader
	p.init = function (item, basePath) {
		this._item = item;
		this._basePath = basePath;
		if (!this._createXHR(item)) {
			//TODO: Throw error?
		}
	};

	/**
	 * Look up the loaded result.
	 * @method getResult
	 * @param {Boolean} [rawResult=false] Return a raw result instead of a formatted result. This applies to content
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
	p.getResult = function (rawResult) {
		if (rawResult && this._rawResponse) {
			return this._rawResponse;
		}
		return this._response;
	};

	// Overrides abstract method in AbstractLoader
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
		this._request.onloadstart = createjs.proxy(this._handleLoadStart, this);
		this._request.onprogress = createjs.proxy(this._handleProgress, this);
		this._request.onabort = createjs.proxy(this._handleAbort, this);
		this._request.onerror = createjs.proxy(this._handleError, this);
		this._request.ontimeout = createjs.proxy(this._handleTimeout, this);
		// Set up a timeout if we don't have XHR2
		if (this._xhrLevel == 1) {
			this._loadTimeout = setTimeout(createjs.proxy(this._handleTimeout, this), createjs.LoadQueue.LOAD_TIMEOUT);
		}

		// Note: We don't get onload in all browsers (earlier FF and IE). onReadyStateChange handles these.
		this._request.onload = createjs.proxy(this._handleLoad, this);

		this._request.onreadystatechange = createjs.proxy(this._handleReadyStateChange, this);

		// Sometimes we get back 404s immediately, particularly when there is a cross origin request.  // note this does not catch in Chrome
		try {
			if (!this._item.values || this._item.method == createjs.LoadQueue.GET) {
				this._request.send();
			} else if (this._item.method == createjs.LoadQueue.POST) {
				this._request.send(this._formatQueryString(this._item.values));
			}
		} catch (error) {
			var event = new createjs.Event("error");
			event.error = error;
			this._sendError(event);
		}
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
		if  (this._request.getAllResponseHeaders instanceof Function) {
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

		var newEvent = new createjs.Event("progress");
		newEvent.loaded = event.loaded;
		newEvent.total = event.total;
		this._sendProgress(newEvent);
	};

	/**
	 * The XHR request has reported a load start.
	 * @method _handleLoadStart
	 * @param {Object} event The XHR loadStart event.
	 * @private
	 */
	p._handleLoadStart = function (event) {
		clearTimeout(this._loadTimeout);
		this._sendLoadStart();
	};

	/**
	 * The XHR request has reported an abort event.
	 * @method handleAbort
	 * @param {Object} event The XHR abort event.
	 * @private
	 */
	p._handleAbort = function (event) {
		this._clean();
		var event = new createjs.Event("error");
		event.text = "XHR_ABORTED";
		this._sendError(event);
	};

	/**
	 * The XHR request has reported an error event.
	 * @method _handleError
	 * @param {Object} event The XHR error event.
	 * @private
	 */
	p._handleError = function (event) {
		this._clean();
		var newEvent = new createjs.Event("error");
		//TODO: Propagate event error
		this._sendError(newEvent);
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

		if (!this._checkError()) {
			this._handleError();
			return;
		}

		this._response = this._getResponse();
		this._clean();
		var isComplete = this._generateTag();
		if (isComplete) {
			this._sendComplete();
		}
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
		var newEvent = new createjs.Event("error");
		newEvent.text = "PRELOAD_TIMEOUT";
		//TODO: Propagate actual event error
		this._sendError(event);
	};


// Protected
	/**
	 * Determine if there is an error in the current load. This checks the status of the request for problem codes. Note
	 * that this does not check for an actual response. Currently, it only checks for 404 or 0 error code.
	 * @method _checkError
	 * @return {Boolean} If the request status returns an error code.
	 * @private
	 */
	p._checkError = function () {
		//LM: Probably need additional handlers here, maybe 501
		var status = parseInt(this._request.status);

		switch (status) {
			case 404:   // Not Found
			case 0:     // Not Loaded
				return false;
		}
		return true;
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
		//TODO: TEST
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
		var target = document.createElement("a");
		target.href = this.buildPath(item.src, this._basePath);

		var host = document.createElement("a");
		host.href = location.href;

		var crossdomain = (target.hostname != "") &&
						 	(target.port != host.port ||
							 target.protocol != host.protocol ||
							 target.hostname != host.hostname);

		// Create the request. Fall back to whatever support we have.
		var req = null;
		if (crossdomain && window.XDomainRequest) {
			req = new XDomainRequest(); // Note: IE9 will fail if this is not actually cross-domain.
		} else if (window.XMLHttpRequest) { // Old IE versions use a different approach
			req = new XMLHttpRequest();
		} else {
			try {
				req = new ActiveXObject("Msxml2.XMLHTTP.6.0");
			} catch (e) {
				try {
					req = new ActiveXObject("Msxml2.XMLHTTP.3.0");
				} catch (e) {
					try {
						req = new ActiveXObject("Msxml2.XMLHTTP");
					} catch (e) {
						return false;
					}
				}
			}
		}

		// IE9 doesn't support overrideMimeType(), so we need to check for it.
		if (item.type == createjs.LoadQueue.TEXT && req.overrideMimeType) {
			req.overrideMimeType("text/plain; charset=x-user-defined");
		}

		// Determine the XHR level
		this._xhrLevel = (typeof req.responseType === "string") ? 2 : 1;

		var src = null;
		if (item.method == createjs.LoadQueue.GET) {
			src = this.buildPath(item.src, this._basePath, item.values);
		} else {
			src = this.buildPath(item.src, this._basePath);
		}

		// Open the request.  Set cross-domain flags if it is supported (XHR level 1 only)
		req.open(item.method || createjs.LoadQueue.GET, src, true);

		if (crossdomain && req instanceof XMLHttpRequest && this._xhrLevel == 1) {
			req.setRequestHeader("Origin", location.origin);
		}

		// To send data we need to set the Content-type header)
		 if (item.values && item.method == createjs.LoadQueue.POST) {
			req.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded');
		 }

		// Binary files are loaded differently.
		if (createjs.LoadQueue.isBinary(item.type)) {
			req.responseType = "arraybuffer";
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

		var req = this._request;
		req.onloadstart = null;
		req.onprogress = null;
		req.onabort = null;
		req.onerror = null;
		req.onload = null;
		req.ontimeout = null;
		req.onloadend = null;
		req.onreadystatechange = null;
	};

	/**
	 * Generate a tag for items that can be represented as tags. For example, IMAGE, SCRIPT, and LINK. This also handles
	 * XML and SVG objects.
	 * @method _generateTag
	 * @return {Boolean} If a tag was generated and is ready for instantiation. If it still needs processing, this
	 * method returns false.
	 * @private
	 */
	p._generateTag = function () {
		var type = this._item.type;
		var tag = this._item.tag;

		switch (type) {
			// Note: Images need to wait for onload, but do use the cache.
			case createjs.LoadQueue.IMAGE:
				tag.onload = createjs.proxy(this._handleTagReady, this);
				tag.src = this.buildPath(this._item.src, this._basePath, this._item.values);

				this._rawResponse = this._response;
				this._response = tag;
				return false; // Images need to get an onload event first

			case createjs.LoadQueue.JAVASCRIPT:
				tag = document.createElement("script");
				tag.text = this._response;

				this._rawResponse = this._response;
				this._response = tag;
				(document.body || document.getElementsByTagName("body")[0]).appendChild(tag);
				return true;

			case createjs.LoadQueue.CSS:
				// Maybe do this conditionally?
				var head = document.getElementsByTagName("head")[0]; //Note: This is unavoidable in IE678
				head.appendChild(tag);

				if (tag.styleSheet) { // IE
					tag.styleSheet.cssText = this._response;
				} else {
					var textNode = document.createTextNode(this._response);
					tag.appendChild(textNode);
				}

				this._rawResponse = this._response;
				this._response = tag;
				return true;

			case createjs.LoadQueue.XML:
				var xml = this._parseXML(this._response, "text/xml");
				this._rawResponse = this._response;
				this._response = xml;
				return true;

			case createjs.LoadQueue.SVG:
				var xml = this._parseXML(this._response, "image/svg+xml");
				this._rawResponse = this._response;
				if (xml.documentElement != null) {
					tag.appendChild(xml.documentElement);
					this._response = tag;
				} else { // For browsers that don't support SVG, just give them the XML. (IE 9-8)
					this._response = xml;
				}
				return true;

			case createjs.LoadQueue.JSON:
			case createjs.LoadQueue.MANIFEST:
				var json = {};
				try {
					json = JSON.parse(this._response);
				} catch (error) {
					json = error;
				}

				this._rawResponse = this._response;
				this._response = json;
				return true;

		}
		return true;
	};

	/**
	 * Parse XML using the DOM. This is required when preloading XML or SVG.
	 * @method _parseXML
	 * @param {String} text The raw text or XML that is loaded by XHR.
	 * @param {String} type The mime type of the XML.
	 * @return {XML} An XML document.
	 * @private
	 */
	p._parseXML = function (text, type) {
		var xml = null;
		if (window.DOMParser) {
			var parser = new DOMParser();
			xml = parser.parseFromString(text, type);  // OJR Opera throws DOMException: NOT_SUPPORTED_ERR  // potential solution https://gist.github.com/1129031
		} else { // IE
			xml = new ActiveXObject("Microsoft.XMLDOM");
			xml.async = false;
			xml.loadXML(text);
		}
		return xml;
	};

	/**
	 * A generated tag is now ready for use.
	 * @method _handleTagReady
	 * @private
	 */
	p._handleTagReady = function () {
		this._sendComplete();
	}

	p.toString = function () {
		return "[PreloadJS XHRLoader]";
	}

	createjs.XHRLoader = XHRLoader;

}());

/**
 * Include json2 here, to correctly parse json.
 * Used on browsers that don't have a native JSON object.
 *
 */
/*
 json2.js
 2012-10-08

 Public Domain.

 NO WARRANTY EXPRESSED OR IMPLIED. USE AT YOUR OWN RISK.

 See http://www.JSON.org/js.html


 This code should be minified before deployment.
 See http://javascript.crockford.com/jsmin.html

 USE YOUR OWN COPY. IT IS EXTREMELY UNWISE TO LOAD CODE FROM SERVERS YOU DO
 NOT CONTROL.
 */


// Create a JSON object only if one does not already exist. We create the
// methods in a closure to avoid creating global variables.

if (typeof JSON !== 'object') {
	JSON = {};
}

(function () {
	'use strict';

	function f(n) {
		// Format integers to have at least two digits.
		return n < 10 ? '0' + n : n;
	}

	if (typeof Date.prototype.toJSON !== 'function') {

		Date.prototype.toJSON = function (key) {

			return isFinite(this.valueOf())
					? this.getUTCFullYear() + '-' +
					f(this.getUTCMonth() + 1) + '-' +
					f(this.getUTCDate()) + 'T' +
					f(this.getUTCHours()) + ':' +
					f(this.getUTCMinutes()) + ':' +
					f(this.getUTCSeconds()) + 'Z'
					: null;
		};

		String.prototype.toJSON =
				Number.prototype.toJSON =
						Boolean.prototype.toJSON = function (key) {
							return this.valueOf();
						};
	}

	var cx = /[\u0000\u00ad\u0600-\u0604\u070f\u17b4\u17b5\u200c-\u200f\u2028-\u202f\u2060-\u206f\ufeff\ufff0-\uffff]/g,
			escapable = /[\\\"\x00-\x1f\x7f-\x9f\u00ad\u0600-\u0604\u070f\u17b4\u17b5\u200c-\u200f\u2028-\u202f\u2060-\u206f\ufeff\ufff0-\uffff]/g,
			gap,
			indent,
			meta = {    // table of character substitutions
				'\b':'\\b',
				'\t':'\\t',
				'\n':'\\n',
				'\f':'\\f',
				'\r':'\\r',
				'"':'\\"',
				'\\':'\\\\'
			},
			rep;


	function quote(string) {

// If the string contains no control characters, no quote characters, and no
// backslash characters, then we can safely slap some quotes around it.
// Otherwise we must also replace the offending characters with safe escape
// sequences.

		escapable.lastIndex = 0;
		return escapable.test(string) ? '"' + string.replace(escapable, function (a) {
			var c = meta[a];
			return typeof c === 'string'
					? c
					: '\\u' + ('0000' + a.charCodeAt(0).toString(16)).slice(-4);
		}) + '"' : '"' + string + '"';
	}


	function str(key, holder) {

// Produce a string from holder[key].

		var i, // The loop counter.
				k, // The member key.
				v, // The member value.
				length,
				mind = gap,
				partial,
				value = holder[key];

// If the value has a toJSON method, call it to obtain a replacement value.

		if (value && typeof value === 'object' &&
				typeof value.toJSON === 'function') {
			value = value.toJSON(key);
		}

// If we were called with a replacer function, then call the replacer to
// obtain a replacement value.

		if (typeof rep === 'function') {
			value = rep.call(holder, key, value);
		}

// What happens next depends on the value's type.

		switch (typeof value) {
			case 'string':
				return quote(value);

			case 'number':

// JSON numbers must be finite. Encode non-finite numbers as null.

				return isFinite(value) ? String(value) : 'null';

			case 'boolean':
			case 'null':

// If the value is a boolean or null, convert it to a string. Note:
// typeof null does not produce 'null'. The case is included here in
// the remote chance that this gets fixed someday.

				return String(value);

// If the type is 'object', we might be dealing with an object or an array or
// null.

			case 'object':

// Due to a specification blunder in ECMAScript, typeof null is 'object',
// so watch out for that case.

				if (!value) {
					return 'null';
				}

// Make an array to hold the partial results of stringifying this object value.

				gap += indent;
				partial = [];

// Is the value an array?

				if (Object.prototype.toString.apply(value) === '[object Array]') {

// The value is an array. Stringify every element. Use null as a placeholder
// for non-JSON values.

					length = value.length;
					for (i = 0; i < length; i += 1) {
						partial[i] = str(i, value) || 'null';
					}

// Join all of the elements together, separated with commas, and wrap them in
// brackets.

					v = partial.length === 0
							? '[]'
							: gap
							? '[\n' + gap + partial.join(',\n' + gap) + '\n' + mind + ']'
							: '[' + partial.join(',') + ']';
					gap = mind;
					return v;
				}

// If the replacer is an array, use it to select the members to be stringified.

				if (rep && typeof rep === 'object') {
					length = rep.length;
					for (i = 0; i < length; i += 1) {
						if (typeof rep[i] === 'string') {
							k = rep[i];
							v = str(k, value);
							if (v) {
								partial.push(quote(k) + (gap ? ': ' : ':') + v);
							}
						}
					}
				} else {

// Otherwise, iterate through all of the keys in the object.

					for (k in value) {
						if (Object.prototype.hasOwnProperty.call(value, k)) {
							v = str(k, value);
							if (v) {
								partial.push(quote(k) + (gap ? ': ' : ':') + v);
							}
						}
					}
				}

// Join all of the member texts together, separated with commas,
// and wrap them in braces.

				v = partial.length === 0
						? '{}'
						: gap
						? '{\n' + gap + partial.join(',\n' + gap) + '\n' + mind + '}'
						: '{' + partial.join(',') + '}';
				gap = mind;
				return v;
		}
	}

// If the JSON object does not yet have a stringify method, give it one.

	if (typeof JSON.stringify !== 'function') {
		JSON.stringify = function (value, replacer, space) {

// The stringify method takes a value and an optional replacer, and an optional
// space parameter, and returns a JSON text. The replacer can be a function
// that can replace values, or an array of strings that will select the keys.
// A default replacer method can be provided. Use of the space parameter can
// produce text that is more easily readable.

			var i;
			gap = '';
			indent = '';

// If the space parameter is a number, make an indent string containing that
// many spaces.

			if (typeof space === 'number') {
				for (i = 0; i < space; i += 1) {
					indent += ' ';
				}

// If the space parameter is a string, it will be used as the indent string.

			} else if (typeof space === 'string') {
				indent = space;
			}

// If there is a replacer, it must be a function or an array.
// Otherwise, throw an error.

			rep = replacer;
			if (replacer && typeof replacer !== 'function' &&
					(typeof replacer !== 'object' ||
							typeof replacer.length !== 'number')) {
				throw new Error('JSON.stringify');
			}

// Make a fake root object containing our value under the key of ''.
// Return the result of stringifying the value.

			return str('', {'':value});
		};
	}


// If the JSON object does not yet have a parse method, give it one.

	if (typeof JSON.parse !== 'function') {
		JSON.parse = function (text, reviver) {

// The parse method takes a text and an optional reviver function, and returns
// a JavaScript value if the text is a valid JSON text.

			var j;

			function walk(holder, key) {

// The walk method is used to recursively walk the resulting structure so
// that modifications can be made.

				var k, v, value = holder[key];
				if (value && typeof value === 'object') {
					for (k in value) {
						if (Object.prototype.hasOwnProperty.call(value, k)) {
							v = walk(value, k);
							if (v !== undefined) {
								value[k] = v;
							} else {
								delete value[k];
							}
						}
					}
				}
				return reviver.call(holder, key, value);
			}


// Parsing happens in four stages. In the first stage, we replace certain
// Unicode characters with escape sequences. JavaScript handles many characters
// incorrectly, either silently deleting them, or treating them as line endings.

			text = String(text);
			cx.lastIndex = 0;
			if (cx.test(text)) {
				text = text.replace(cx, function (a) {
					return '\\u' +
							('0000' + a.charCodeAt(0).toString(16)).slice(-4);
				});
			}

// In the second stage, we run the text against regular expressions that look
// for non-JSON patterns. We are especially concerned with '()' and 'new'
// because they can cause invocation, and '=' because it can cause mutation.
// But just to be safe, we want to reject all unexpected forms.

// We split the second stage into 4 regexp operations in order to work around
// crippling inefficiencies in IE's and Safari's regexp engines. First we
// replace the JSON backslash pairs with '@' (a non-JSON character). Second, we
// replace all simple value tokens with ']' characters. Third, we delete all
// open brackets that follow a colon or comma or that begin the text. Finally,
// we look to see that the remaining characters are only whitespace or ']' or
// ',' or ':' or '{' or '}'. If that is so, then the text is safe for eval.

			if (/^[\],:{}\s]*$/
					.test(text.replace(/\\(?:["\\\/bfnrt]|u[0-9a-fA-F]{4})/g, '@')
								  .replace(/"[^"\\\n\r]*"|true|false|null|-?\d+(?:\.\d*)?(?:[eE][+\-]?\d+)?/g, ']')
								  .replace(/(?:^|:|,)(?:\s*\[)+/g, ''))) {

// In the third stage we use the eval function to compile the text into a
// JavaScript structure. The '{' operator is subject to a syntactic ambiguity
// in JavaScript: it can begin a block or an object literal. We wrap the text
// in parens to eliminate the ambiguity.

				j = eval('(' + text + ')');

// In the optional fourth stage, we recursively walk the new structure, passing
// each name/value pair to a reviver function for possible transformation.

				return typeof reviver === 'function'
						? walk({'':j}, '')
						: j;
			}

// If the text is not JSON parseable, then a SyntaxError is thrown.

			throw new SyntaxError('JSON.parse');
		};
	}
}());
