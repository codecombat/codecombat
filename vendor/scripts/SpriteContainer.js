/*
* SpriteContainer
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

// namespace:
this.createjs = this.createjs||{};

(function() {

/**
 * A SpriteContainer is a nestable display list that enables aggressively optimized rendering of bitmap content.
 * In order to accomplish these optimizations, SpriteContainer enforces a few restrictions on its content.
 *
 * Restrictions:
 *     - only Sprite, SpriteContainer, BitmapText and DOMElement are allowed to be added as children.
 *     - a spriteSheet MUST be either be passed into the constructor or defined on the first child added.
 *     - all children (with the exception of DOMElement) MUST use the same spriteSheet.
 *
 * <h4>Example</h4>
 *      var data = {
 *          images: ["sprites.jpg"],
 *          frames: {width:50, height:50},
 *          animations: {run:[0,4], jump:[5,8,"run"]}
 *      };
 *      var spriteSheet = new createjs.SpriteSheet(data);
 *      var container = new createjs.SpriteContainer(spriteSheet);
 *      container.addChild(spriteInstance, spriteInstance2);
 *      container.x = 100;
 *
 * <strong>Note:</strong> SpriteContainer is not included in the minified version of EaselJS.
 *
 * @class SpriteContainer
 * @extends Container
 * @constructor
 * @param {SpriteSheet} [spriteSheet] The spriteSheet to use for this SpriteContainer and its children.
 **/
var SpriteContainer = function(spriteSheet) {
  this.initialize(spriteSheet);
};
var p = SpriteContainer.prototype = new createjs.Container();

// public properties:

	/**
	 * The SpriteSheet that this container enforces use of.
	 * @property spriteSheet
	 * @type {SpriteSheet}
	 * @readonly
	 **/
	p.spriteSheet = null;

// constructor:

	/**
	 * @property Container_initialize
	 * @type Function
	 * @private
	 **/
	p.Container_initialize = p.initialize;

	/**
	 * Initialization method.
	 * @method initialize
	 * @param {SpriteSheet} spriteSheet Optional. The spriteSheet to use for this SpriteContainer and its children.
	 * @protected
	*/
	p.initialize = function(spriteSheet) {
		this.Container_initialize();
		this.spriteSheet = spriteSheet;
	};

// public methods:

	/**
	 * Adds a child to the top of the display list.
	 * Only children of type SpriteContainer, Sprite, Bitmap, BitmapText, or DOMElement are allowed.
	 * The child must have the same spritesheet as this container (unless it's a DOMElement).
	 * If a spritesheet hasn't been defined, this container uses this child's spritesheet.
	 *
	 * <h4>Example</h4>
	 *      container.addChild(bitmapInstance);
	 *
	 *  You can also add multiple children at once:
	 *
	 *      container.addChild(bitmapInstance, shapeInstance, textInstance);
	 *
	 * @method addChild
	 * @param {DisplayObject} child The display object to add.
	 * @return {DisplayObject} The child that was added, or the last child if multiple children were added.
	 **/
	p.addChild = function(child) {
		if (child == null) { return child; }
		if (arguments.length > 1) {
			return this.addChildAt.apply(this, Array.prototype.slice.call(arguments).concat([this.children.length]));
		} else {
			return this.addChildAt(child, this.children.length);
		}
	};

	/**
	 * Adds a child to the display list at the specified index, bumping children at equal or greater indexes up one, and
	 * setting its parent to this Container.
	 * Only children of type SpriteContainer, Sprite, Bitmap, BitmapText, or DOMElement are allowed.
	 * The child must have the same spritesheet as this container (unless it's a DOMElement).
	 * If a spritesheet hasn't been defined, this container uses this child's spritesheet.
	 * 
	 * <h4>Example</h4>
	 *      addChildAt(child1, index);
	 *
	 * You can also add multiple children, such as:
	 *
	 *      addChildAt(child1, child2, ..., index);
	 *
	 * The index must be between 0 and numChildren. For example, to add myShape under otherShape in the display list,
	 * you could use:
	 *
	 *      container.addChildAt(myShape, container.getChildIndex(otherShape));
	 *
	 * This would also bump otherShape's index up by one. Fails silently if the index is out of range.
	 *
	 * @method addChildAt
	 * @param {DisplayObject} child The display object to add.
	 * @param {Number} index The index to add the child at.
	 * @return {DisplayObject} Returns the last child that was added, or the last child if multiple children were added.
	 **/
	p.addChildAt = function(child, index) {
		var l = arguments.length;
		var indx = arguments[l-1]; // can't use the same name as the index param or it replaces arguments[1]
		if (indx < 0 || indx > this.children.length) { return arguments[l-2]; }
		if (l > 2) {
			for (var i=0; i<l-1; i++) { this.addChildAt(arguments[i], indx+i); }
			return arguments[l-2];
		}
		if (child._spritestage_compatibility >= 1) {
			// The child is compatible with SpriteStage/SpriteContainer.
		} else {
			console && console.log("Error: You can only add children of type SpriteContainer, Sprite, BitmapText, or DOMElement [" + child.toString() + "]");
			return child;
		}
		if (child._spritestage_compatibility <= 4) {
			var spriteSheet = child.spriteSheet;
			if ((!spriteSheet || !spriteSheet._images || spriteSheet._images.length > 1) || (this.spritesheet && spritesheet !== spritesheet)) {
				console && console.log("Error: A child's spriteSheet must be equal to its parent spriteSheet and only use one image. [" + child.toString() + "]");
				return child;
			}
			this.spriteSheet = spriteSheet;
		}
		if (child.parent) { child.parent.removeChild(child); }
		child.parent = this;
		this.children.splice(index, 0, child);
		return child;
	};

	/**
	 * Returns a string representation of this object.
	 * @method toString
	 * @return {String} a string representation of the instance.
	 **/
	p.toString = function() {
		return "[SpriteContainer (name="+  this.name +")]";
	};

createjs.SpriteContainer = SpriteContainer;
}());