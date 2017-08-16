var Spade = function Spade() {
	this.stack = [];
	this.playback = [];
	this.speed = 1;
}
Spade.prototype = {
	track: function(_elem) {
		this.target = _elem;

		var spade = this;

		var el = document.createElement("div");

		keyHook = null;
		if(_elem.textInput && _elem.textInput.getElement) {
			keyHook = _elem.textInput.getElement();
		} else {
			keyHook = _elem;
		}
		keyHook.addEventListener("keydown", function(_event) {spade.createEvent(spade.target)});
		//Maybe this is needed depending on Firefox/other browsers? Duplicate non-diff events get compiled down.
		keyHook.addEventListener("keyup", function(_event) {spade.createEvent(spade.target)});
		_elem.addEventListener("mouseup", function(_event) {spade.createEvent(spade.target)});
	},
	createEvent: function(_target) {
		if(_target.getValue) {
			this.stack.push({
				"startPos":_target.selection.getCursor(),
				"endPos":_target.selection.getSelectionAnchor(),
				"content":_target.getValue(),
				"timestamp":(new Date()).getTime()
			});
		} else {
			this.stack.push({
				"startPos":_target.selectionStart,
				"endPos":_target.selectionEnd,
				"content":_target.value,
				"timestamp":(new Date()).getTime()
			});
		}
	},
	compile: function() {
		var compiledStack = [];
		if(this.stack.length > 0) {
			var startTime = this.stack[0].timestamp;
			var sum = 0;
			var sum2 = 0;
			for(var i = 0; i < this.stack.length; i++) {
				var c = this.stack[i];
				var adjustedTimestamp = c.timestamp - startTime;

				var tString = "";	//The changed string.
				var fIndex = null;	//The first index of changes.
				var eIndex = null;	//The last index of changes.
				var dCount = 0;		//Amount of character changes.
				if(i >= 1) {
					var p = this.stack[i - 1];
					var isOkay = false;
					for(var key in p) {
						if(key != "timestamp") {
							if(typeof p[key] === "string") {
								if(p[key] !== c[key]) {
									isOkay = true;
								}
							} else {
								for(var key2 in p[key]) {
									if(c[key][key2] !== undefined) {
										if(p[key][key2] !== c[key][key2]) {
											isOkay = true;
										}
									} else {
										console.warn("Warning: c[key][key2] doesn't exist, but p[key][key2] does.");
										isOkay = true;
									}
								}
							}
						}
					}
					if(!isOkay) {
						sum2++;
						continue;
					}
					sum++;
					if(p.content != c.content) {
						//Check from the start to the end, which characters are different.
						for(var j = 0; j < Math.max(p.content.length, c.content.length); j++) {
							if(p.content.charAt(j) === c.content.charAt(j)) {
								if(fIndex != null) {
									tString += c.content.charAt(j);
									dCount++;
								}
							} else {
								tString += c.content.charAt(j);
								if(fIndex === null) {
									fIndex = j;
								}
								dCount++;
							}
						}
						//Check from the end to the start, which characters are different.
						for(var j = 0; j < Math.min(p.content.length, c.content.length) - fIndex; j++) {
							if(p.content.charAt(p.content.length - 1 - j) !== c.content.charAt(c.content.length - 1 - j)) {
								if(eIndex == null) {
									eIndex = j;
									break;	
								}
							}
						}
						//This accounts for the fact when changing from "aa" to "aaa" (for example).
						if(eIndex === null) {
							eIndex = Math.min(p.content.length, c.content.length) - fIndex;
						}
						tString = tString.substring(0, tString.length - eIndex);
					}
				} else {
					tString = c.content;
					fIndex = 0;
					eIndex = tString.length;
				}
				compiledStack.push({
					"timestamp":adjustedTimestamp,
					"difContent":tString,
					"difFIndex":fIndex,
					"difEIndex":eIndex,
					"selFIndex":c.startPos,
					"selEIndex":c.endPos
				});
			}
		} else {
			//Just return the empty array.
		}
		return compiledStack;
	},
	renderTime: function(_stack, _elem, _t) {
		if(_stack.length === 0) {
			console.warn("SPADE: No events to play.");
			return
		}
		var tTime = _stack[_stack.length - 1].timestamp;
		//var destinedIndex = Math.floor(_stack.length * _t);
		var result = _stack[0].difContent;
		for(var i = 1; i < _stack.length; i++) {
			if(_t * tTime < _stack[i].timestamp) {
				break;
			}
			var tEvent = _stack[i];
			var oVal = result;
			if(tEvent.difFIndex !== null && tEvent.difEIndex !== null) {
				result = oVal.substring(0, tEvent.difFIndex) + tEvent.difContent + oVal.substring(oVal.length - tEvent.difEIndex, oVal.length);
			}
		}
		var returnObject = {
			result: result
		};
		if(tEvent) {
			returnObject["selFIndex"] = tEvent.selFIndex;
			returnObject["selEIndex"] = tEvent.selEIndex;		}
		return returnObject
	},
	play: function(_stack, _elem, _t) {
		_t = _t || 0;
		if(_stack.length === 0) {
			console.warn("SPADE: No events to play.")
			return
		}
		if(_elem.setValue) {
			_elem.setValue(this.renderTime(_stack, _elem, _t).result);
		} else {
			_elem.value = this.renderTime(_stack, _elem, _t).result
		}
		_stack = _stack.slice();
		_stack.shift();
		var curTime, dTime;
		var tTime = _stack[_stack.length - 1].timestamp;
		var elapsedTime = _t * tTime;
		this.elapsedTime = elapsedTime;
		var prevTime = (new Date()).getTime();
		this.playback = playbackInterval = setInterval(function() {
			//console.log(this);
			curTime = (new Date()).getTime();
			dTime = curTime - prevTime;
			dTime *= this.speed;	//Multiply for faster/slower playback speeds.
			elapsedTime += dTime;
			var tArray = _stack.filter(function(_event) {
				return ((_event.timestamp) >= (elapsedTime - dTime)) && ((_event.timestamp) < (elapsedTime));
			});
			this.elapsedTime = elapsedTime;
			for(var i = 0; i < tArray.length; i++) {
				var tEvent = tArray[i];
				var oVal = null;
				if(_elem.getValue) {
					oVal = _elem.getValue();
				} else {
					oVal = _elem.value;
				}
				if(tEvent.difFIndex !== null && tEvent.difEIndex !== null) {
					if(_elem.setValue) {
						_elem.setValue(oVal.substring(0, tEvent.difFIndex) + tEvent.difContent + oVal.substring(oVal.length - tEvent.difEIndex, oVal.length));
					} else {
						_elem.value = oVal.substring(0, tEvent.difFIndex) + tEvent.difContent + oVal.substring(oVal.length - tEvent.difEIndex, oVal.length)
					}
				}

				if(_elem.selection && _elem.selection.moveCursorToPosition) {
					_elem.selection.moveCursorToPosition(tEvent.selFIndex);
					_elem.selection.setSelectionAnchor(tEvent.selEIndex.row, tEvent.selEIndex.column);
				} else {
					//Likewise
					_elem.focus();
					_elem.setSelectionRange(tEvent.selFIndex, tEvent.selEIndex);
				}
			}
			if(_stack[_stack.length - 1] === undefined || elapsedTime > _stack[_stack.length - 1].timestamp) {
				clearInterval(playbackInterval);
			}
			prevTime = curTime;
		}.bind(this), 10);
	},
	debugPlay: function(_stack) {
		var area = document.createElement('textarea');
		area.zIndex = 9999;
		area.style.width = "512px";
		area.style.height = "512px";
		area.style.position = "absolute";
		area.style.left = "100px";
		area.style.top = "100px";
		document.body.appendChild(area);
		this.play(_stack, area);
	},
	condense: function(_stack) {
		var compressedArray = [];
		for(var i = 0; i < _stack.length; i++) {
			var u = _stack[i];
			compressedArray.push([
				u.timestamp,
				u.difContent,
				u.difFIndex,
				u.difEIndex,
				u.selFIndex.row,
				u.selFIndex.column,
				u.selEIndex.row,
				u.selEIndex.column
			]);
		}
		return compressedArray;
	},
	expand: function(_array) {
		var uncompressedArray = [];
		for(var i = 0 ; i < _array.length; i++) {
			var c = _array[i];
			uncompressedArray.push({
				"timestamp":c[0],
				"difContent":c[1],
				"difFIndex":c[2],
				"difEIndex":c[3],
				"selFIndex":{
					"row":c[4],
					"column":c[5]
				},
				"selEIndex":{
					"row":c[6],
					"column":c[7]
				},
			});
		}
		return uncompressedArray;
	}
}
