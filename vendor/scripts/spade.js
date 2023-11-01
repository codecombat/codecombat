var Spade = function Spade() {
  this.stack = [];
  this.playback = [];
  this.speed = 1;
  this.target = null;
}

var isObject = function isObject(item) {
  return typeof item === 'object' && !Array.isArray(item);
}

Spade.prototype = {
  track: function(elem) {
    this.target = elem;

    let keyHook = null;
    if(elem.textInput && elem.textInput.getElement) {
      keyHook = elem.textInput.getElement();
    } else {
      keyHook = elem;
    }

    keyHook.addEventListener("keydown", this.createEvent.bind(this));
    //Maybe this is needed depending on Firefox/other browsers? Duplicate non-diff events get compiled down.
    keyHook.addEventListener("keyup", this.createEvent.bind(this));
    elem.addEventListener("mouseup", this.createEvent.bind(this));
  },
  createEvent: function() {
    if (this.target.getValue) {
      this.stack.push({
        "startPos": this.target.selection.getCursor(),
        "endPos": this.target.selection.getSelectionAnchor(),
        "content": this.target.getValue(),
        "timestamp": (new Date()).getTime(),
      });
    } else {
      this.stack.push({
        "startPos": this.target.selectionStart,
        "endPos": this.target.selectionEnd,
        "content": this.target.value,
        "timestamp": (new Date()).getTime(),
      });
    }
  },
  createUIEvent: function(eventName, eventOptions) {
    if(this.stack.length === 0) {
      this.createEvent();
    }
    if(eventName === "code-reset" || eventName == "saving-spade") {
      this.createEvent();
    }
    this.stack.push({
      eventName: eventName,
      eventOptions: eventOptions,
      timestamp: (new Date()).getTime(),
    });
  },
  compile: function() {
    let compiledStack = [];
    if (this.stack.length === 0) {
      return compiledStack;
    }
    let startTime = this.stack[0].timestamp;
    let sum = 0;
    let sum2 = 0;

    let filteredStack = this.stack.filter(elem => !elem.eventName);
    let uiEvents = this.stack.filter(elem => elem.eventName);

    for(let i = 0; i < filteredStack.length; i++) {
      let c = filteredStack[i];
      let adjustedTimestamp = c.timestamp - startTime;

      let tString = "";	//The changed string.
      let fIndex = null;	//The first index of changes.
      let eIndex = null;	//The last index of changes.
      let dCount = 0;		//Amount of character changes.
      if (i >= 1) {
        let p = filteredStack[i - 1];
        let isOkay = false;
        for (let key in p) {
          if (key != "timestamp") {
            if (typeof p[key] === "string") {
              if (p[key] !== c[key]) {
                isOkay = true;
              }
            } else {
              for (let key2 in p[key]) {
                if (c[key][key2] !== undefined) {
                  if (p[key][key2] !== c[key][key2]) {
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
        if (!isOkay) {
          sum2++;
          continue;
        }
        sum++;
        if (p.content != c.content) {
          //Check from the start to the end, which characters are different.
          for (let j = 0; j < Math.max(p.content.length, c.content.length); j++) {
            if (p.content.charAt(j) === c.content.charAt(j)) {
              if (fIndex != null) {
                tString += c.content.charAt(j);
                dCount++;
              }
            } else {
              tString += c.content.charAt(j);
              if (fIndex === null) {
                fIndex = j;
              }
              dCount++;
            }
          }
          //Check from the end to the start, which characters are different.
          for (let j = 0; j < Math.min(p.content.length, c.content.length) - fIndex; j++) {
            if (p.content.charAt(p.content.length - 1 - j) !== c.content.charAt(c.content.length - 1 - j)) {
              if (eIndex == null) {
                eIndex = j;
                break;
              }
            }
          }
          //This accounts for the fact when changing from "aa" to "aaa" (for example).
          if (eIndex === null) {
            eIndex = Math.min(p.content.length, c.content.length) - fIndex;
          }
          tString = tString.substring(0, tString.length - eIndex);
        }
      } else {
        tString = c.content;
        fIndex = 0;
        eIndex = tString.length;
      }

      while (uiEvents.length) {
        const uiAdjustedTime = uiEvents[0].timestamp - startTime;
        if (uiAdjustedTime < adjustedTimestamp) {
          const uiEvent = uiEvents.shift();
          uiEvent.timestamp = uiAdjustedTime;
          compiledStack.push(uiEvent);
        } else {
          break;
        }
      }

      compiledStack.push({
        "timestamp": adjustedTimestamp,
        "difContent": tString,
        "difFIndex": fIndex,
        "difEIndex": eIndex,
        "selFIndex": c.startPos,
        "selEIndex": c.endPos
      });
    }

    while (uiEvents.length) {
      const uiAdjustedTime = uiEvents[0].timestamp - startTime;
      const uiEvent = uiEvents.shift();
      uiEvent.timestamp = uiAdjustedTime;
      compiledStack.push(uiEvent);
    }
    return compiledStack;
  },
  renderTime: function(stack, elem, timeScale) {
    if(stack.length === 0) {
      console.warn("SPADE: No events to play.");
      return
    }
    let tTime = stack[stack.length - 1].timestamp;
    //let destinedIndex = Math.floor(stack.length * timeScale);
    let result;
    for(let i = 0; i < stack.length; i++) {
      if(stack[i].difContent) {
        result = stack[i].difContent;
        break;
      }
    }
    let tEvent;
    for(let i = 1; i < stack.length; i++) {
      tEvent = stack[i];
      if (tEvent.eventName) {
        continue;
      }
      if(timeScale * tTime < tEvent.timestamp) {
        break;
      }
      let oVal = result;
      if(tEvent.difFIndex !== null && tEvent.difEIndex !== null) {
        result = oVal.substring(0, tEvent.difFIndex) + tEvent.difContent + oVal.substring(oVal.length - tEvent.difEIndex, oVal.length);
      }
    }
    let returnObject = {
      result: result
    };
    if(tEvent) {
      returnObject["selFIndex"] = tEvent.selFIndex;
      returnObject["selEIndex"] = tEvent.selEIndex;
    }
    return returnObject
  },
  renderToElem(stack, elem, timeScale) {
    timeScale = timeScale || 0;
    let result = this.renderTime(stack, elem, timeScale);
    if(result) {
      if(elem.setValue) {
        elem.setValue(result.result);
        if(elem.selection && elem.selection.moveCursorToPosition && result.selFIndex) {
          elem.selection.moveCursorToPosition(result.selFIndex);
          elem.selection.setSelectionAnchor(result.selEIndex.row, result.selEIndex.column);
        }
      } else {
        elem.value = result.result
      }
    }
  },
  play: function(stack, elem, timeScale, eventCallback) {
    if(stack.length === 0) {
      console.warn("SPADE: No events to play.")
      return
    }

    timeScale = timeScale || 0;
    this.renderToElem(stack, elem, timeScale);

    stack = stack.slice();
    stack.shift();
    let curTime, dTime;
    let tTime;
    if(stack.length >= 1) {
      tTime = stack[stack.length - 1].timestamp;
    } else {
      tTime = 0;
    }
    let elapsedTime = timeScale * tTime;
    this.elapsedTime = elapsedTime;
    let prevTime = (new Date()).getTime();

    let playbackInterval
    this.playback = playbackInterval = setInterval(function() {
      curTime = (new Date()).getTime();
      dTime = curTime - prevTime;
      dTime *= this.speed;	//Multiply for faster/slower playback speeds.
      elapsedTime += dTime;
      let tArray = stack.filter(function(_event) {
        return ((_event.timestamp) >= (elapsedTime - dTime)) && ((_event.timestamp) < (elapsedTime));
      });
      this.elapsedTime = elapsedTime;
      for(let i = 0; i < tArray.length; i++) {
        let tEvent = tArray[i];
        let oVal = null;
        if(elem.getValue) {
          oVal = elem.getValue();
        } else {
          oVal = elem.value;
        }
        if(tEvent.eventName) {
          if(eventCallback) {
            eventCallback(tEvent);
            // const eventDiv = document.createElement('div');
            // eventDiv.innerText = tEvent.eventName;
            // eventBox.appendChild(eventDiv);
          }
          continue;
        }
        if(tEvent.difFIndex !== null && tEvent.difEIndex !== null) {
          if(elem.setValue) {
            elem.setValue(oVal.substring(0, tEvent.difFIndex) + tEvent.difContent + oVal.substring(oVal.length - tEvent.difEIndex, oVal.length));
          } else {
            elem.value = oVal.substring(0, tEvent.difFIndex) + tEvent.difContent + oVal.substring(oVal.length - tEvent.difEIndex, oVal.length)
          }
        }

        if(elem.selection && elem.selection.moveCursorToPosition) {
          elem.selection.moveCursorToPosition(tEvent.selFIndex);
          elem.selection.setSelectionAnchor(tEvent.selEIndex.row, tEvent.selEIndex.column);
        } else {
          elem.focus();

          let startIndex = 0;
          let targetRow = tEvent.selFIndex.row;
          let rows = elem.value.split("\n");
          while(targetRow > 0) {
            let row = rows.shift();
            if (row === undefined) break;
            startIndex += row.length;
            startIndex++;
            targetRow--;
          }
          startIndex += tEvent.selFIndex.column;

          let endIndex = 0;
          targetRow = tEvent.selEIndex.row;
          rows = elem.value.split("\n");
          while(targetRow > 0) {
            let row = rows.shift();
            if (row === undefined) break;
            endIndex += row.length;
            endIndex++;
            targetRow--;
          }
          endIndex += tEvent.selEIndex.column;

          if(startIndex > endIndex) {
            elem.setSelectionRange(endIndex, startIndex);
          } else {
            elem.setSelectionRange(startIndex, endIndex);
          }
        }
      }
      if(stack[stack.length - 1] === undefined || elapsedTime > stack[stack.length - 1].timestamp) {
        clearInterval(playbackInterval);
      }
      prevTime = curTime;
    }.bind(this), 10);
  },
  debugPlay: function(stack) {
    let area = document.createElement('textarea');
    area.zIndex = 9999;
    area.style.width = "256px";
    area.style.height = "512px";
    area.style.position = "absolute";
    area.style.left = "100px";
    area.style.top = "100px";
    document.body.appendChild(area);

    let eventBox = document.createElement('div');
    eventBox.zIndex = 9999;
    eventBox.style.width = "256px";
    eventBox.style.height = "512px";
    eventBox.style.position = "absolute";
    eventBox.style.left = "356px";
    eventBox.style.top = "100px";
    eventBox.style.border = "1px solid red";
    eventBox.style.backgroundColor = "rgb(255,255,255)";
    document.body.appendChild(eventBox);

    this.play(stack, area, 0, eventBox);
  },
  condense: function(stack) {
    let compressedArray = [];
    for(let i = 0; i < stack.length; i++) {
      let unit = stack[i];
      if (unit.eventName) {
        compressedArray.push(unit);
      } else {
        compressedArray.push([
          unit.timestamp,
          unit.difContent,
          unit.difFIndex,
          unit.difEIndex,
          unit.selFIndex.row,
          unit.selFIndex.column,
          unit.selEIndex.row,
          unit.selEIndex.column,
        ]);
      }
    }
    return compressedArray;
  },
  expand: function(array) {
    let uncompressedArray = [];
    for(let i = 0 ; i < array.length; i++) {
      let unit = array[i];
      if(isObject(unit)) {
        uncompressedArray.push(unit);
      } else {
        uncompressedArray.push({
          "timestamp": unit[0],
          "difContent": unit[1],
          "difFIndex": unit[2],
          "difEIndex": unit[3],
          "selFIndex":{
            "row": unit[4],
            "column": unit[5],
          },
          "selEIndex":{
            "row": unit[6],
            "column": unit[7],
          },
        });
      }
    }
    return uncompressedArray;
  }
}
