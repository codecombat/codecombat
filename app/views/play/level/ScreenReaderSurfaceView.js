/*
 * decaffeinate suggestions:
 * DS002: Fix invalid constructor
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS103: Rewrite code to no longer use __guard__, or convert again using --optional-chaining
 * DS104: Avoid inline assignments
 * DS204: Change includes calls to have a more natural evaluation order
 * DS205: Consider reworking code to avoid use of IIFEs
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let ScreenReaderSurfaceView;
require('app/styles/play/level/screen-reader-surface-view.sass');
const CocoView = require('views/core/CocoView');
const template = require('app/templates/play/level/screen-reader-surface');
const utils = require('core/utils');

module.exports = (ScreenReaderSurfaceView = (function() {
  ScreenReaderSurfaceView = class ScreenReaderSurfaceView extends CocoView {
    static initClass() {
      this.prototype.id = 'screen-reader-surface-view';
      this.prototype.template = template;
      this.prototype.cursorFollowsHero = true;

      this.prototype.subscriptions = {
        'tome:change-config': 'onChangeTomeConfig',
        'surface:update-screen-reader-map': 'onUpdateScreenReaderMap',
        'camera:zoom-updated': 'onUpdateScreenReaderMap'
      };
    }

    constructor(options) {
      super(options);
      this.onKeyEvent = this.onKeyEvent.bind(this);
    }

    afterInsert() {
      super.afterInsert();
      $(window).on('keydown', this.onKeyEvent);
      $(window).on('keyup', this.onKeyEvent);
      this.onChangeTomeConfig();
      return this.updateScale();
    }

    destroy() {
      $(window).off('keydown', this.onKeyEvent);
      $(window).off('keyup', this.onKeyEvent);
      return super.destroy();
    }

    onChangeTomeConfig(e) {
      // TODO: because this view is only present in PlayLevelView, we still also have the below class toggle line in other places this could be changed outside of PlayLevelView; should refactor
      $('body').toggleClass('screen-reader-mode', __guard__(me.get('aceConfig'), x => x.screenReaderMode));
      if (__guard__(me.get('aceConfig'), x1 => x1.screenReaderMode) && !this.grid) {
        // Need to run the code for this to show up properly
        return Backbone.Mediator.publish('tome:manual-cast', { realTime: false });
      }
    }

    onUpdateScreenReaderMap(e) {
      // Called whenver we need to instantiate/update the map and what's in it
      if (e != null ? e.grid : undefined) {
        this.grid = e.grid;
        this.gridChars = this.grid.toSimpleMovementChars(true, false);
        this.gridNames = this.grid.toSimpleMovementNames();
      }
      this.updateCells(this.cursorFollowsHero);
      return this.updateScale(e);
    }

    onKeyEvent(e) {
      let needle;
      const event = _.pick(e, 'type', 'key', 'keyCode', 'ctrlKey', 'metaKey', 'shiftKey');
      if (!this.cursor) { return; }
      if (event.type !== 'keydown') { return; }
      if (/^arrow/i.test(event.key)) {
        return this.handleArrowKey(event.key);
      }
      if (event.key === ' ') {  // space
        return this.announceCursor(true);
      }
      if ((needle = event.key.toLowerCase(), ['h', '@'].includes(needle))) {
        this.moveToHero();
        this.cursorFollowsHero = true;
        return this.announceCursor();
      }
    }

    handleArrowKey(key) {
      // Move cursor in the specified direction, if valid
      let newCol, pan, sound;
      const adjacent = this.adjacentCells(this.cursor);
      const newCursor = (() => { switch (key.toLowerCase()) {
        case 'arrowleft':  return adjacent.left;
        case 'arrowright': return adjacent.right;
        case 'arrowup':    return adjacent.up;
        case 'arrowdown':  return adjacent.down;
      } })();
      if (newCursor) {
        this.setCursor(newCursor);
        this.announceCursor();
        newCol = newCursor.col;
        sound = 'game-menu-switch-tab';  // temporary sfx we already have
        this.cursorFollowsHero = false;
      } else {
        // There's nothing there, so the hero can't move there--don't move the highlight cursor
        newCol = this.cursor.col;
        sound = 'menu-button-click';  // temporary sfx we already have, need something more different from success sound
      }
      if (this.gridNames[0].length > 1) {
        pan = Math.max(-1, Math.min(1, -1 + ((2 * newCol) / (this.gridNames[0].length - 1))));
      } else {
        pan = 0;  // One column, can't pan left/right
      }
      return this.playSound(sound, 1, 0, null, pan);
    }

    setCursor(newCursor) {
      if (this.cursor != null) {
        this.cursor.$cell.removeClass('cursor');
      }
      newCursor.$cell.addClass('cursor');
      return this.cursor = newCursor;
    }

    moveToHero() {
      for (let r = 0; r < this.gridChars.length; r++) {
        var row = this.gridChars[r];
        var cells = this.mapCells[r];
        for (var c = 0; c < row.length; c++) {
          var char = row[c];
          var $cell = cells[c];
          if (char === '@') {
            this.cursor.$cell.removeClass('cursor');
            this.cursor = {row: r, col: c, $cell};
            $cell.addClass('cursor');
            return this.cursor;
          }
        }
      }
    }

    adjacentCells(cell) {
      // Find the visitable cells next to this cell
      const result = {};
      const object = {
        left:  [-1,  0],
        right: [ 1,  0],
        up:    [ 0, -1],  // y is inverted for the screen
        down:  [ 0,  1]
      };
      for (var dirName in object) {
        var dirVec = object[dirName];
        var $cell = __guard__(this.mapCells[cell.row + dirVec[1]], x => x[cell.col + dirVec[0]]);
        if ($cell != null ? $cell.previousChar.trim() : undefined) {
          // There's something there (a movable area and/or an object)
          result[dirName] = {row: cell.row + dirVec[1], col: cell.col + dirVec[0], $cell};
        }
      }
      return result;
    }

    formatCellContents(cell) {
      return this.gridNames[cell.row][cell.col].replace(/,? ?Dot,? ?/g, '');
    }

    announceCursor(full) {
      // Say what's at the current cursor, if a screen reader is active. Full: includes extra detail on what's around this cell.
      let cell;
      if (full == null) { full = false; }
      let update = this.formatCellContents(this.cursor);
      if (full) {
        let contents, dirName;
        if (!update) { update = 'Empty'; }
        const contentful = [];
        const contentless = [];
        const object = this.adjacentCells(this.cursor);
        for (dirName in object) {
          cell = object[dirName];
          contents = this.formatCellContents(cell);
          (contents ? contentful : contentless).push({dirName, cell, contents});
        }
        for ({dirName, cell, contents} of Array.from(contentful)) {
          update += `. ${dirName} has ${contents}`;
        }
        if (contentless.length) {
          update += `. Can ${contentful.length ? 'also ' : ''}move ${((() => {
            const result = [];
            for (cell of Array.from(contentless)) {               result.push(cell.dirName);
            }
            return result;
          })()).join(', ')}.`;
        }
      }
      return this.$el.find('.map-screen-reader-live-updates').text(update);
    }

    updateCells(followHero) {
      // Create/remove/update .map-cell divs to visually correspond to the current state of the level map grid
      let $cell, $row, cells, r;
      if (followHero == null) { followHero = false; }
      if (!this.gridChars) { return; }
      if (this.mapRows == null) { this.mapRows = []; }
      if (this.mapCells == null) { this.mapCells = []; }
      const $mapGrid = this.$el.find('.map-grid');
      for (r = 0; r < this.gridChars.length; r++) {
        var c;
        var row = this.gridChars[r];
        $row = this.mapRows[r];
        cells = this.mapCells[r];
        if (!$row) {
          $mapGrid.append($row = $('<div class="map-row"></div>'));
          this.mapRows.push($row);
          this.mapCells.push(cells = []);
        }
        for (c = 0; c < row.length; c++) {
          var char = row[c];
          $cell = cells[c];
          var name = this.gridNames[r][c] || 'Blank';
          if (!$cell) {
            $row.append($cell = $("<div class='map-cell'></div>"));
            cells.push($cell);
            $cell.append($(`<span aria-hidden='true'>${char}</span>`));
            $cell.append($(`<span class='sr-only'>${name}</span>`));
          } else {
            if ($cell.previousChar !== char) {
              utils.replaceText($cell.find('span[aria-hidden="true"]'), char);
            }
            if ($cell.previousName !== name) {
              utils.replaceText($cell.find('span.sr-only'), name);
            }
          }
          if ((char === '@') && (followHero || !this.cursor)) {
            this.setCursor({row: r, col: c, $cell});
          }
          $cell.previousChar = char;
          $cell.previousName = name;
        }
        if (c < (cells.length - 1)) {
          // Grid has shrunk width; remove extra cells
          for ($cell of Array.from(cells.splice(c + 1))) { $cell.remove(); }
        }
      }
      if (r < (this.mapRows.length - 1)) {
        // Grid has shrunk height; remove extra rows and their cells
        for ($row of Array.from(this.mapRows.splice(r + 1))) { $row.remove(); }
        return (() => {
          const result = [];
          for (cells of Array.from(this.mapCells.splice(r + 1))) {
            result.push((() => {
              const result1 = [];
              for ($cell of Array.from(cells)) {                 result1.push($cell.remove());
              }
              return result1;
            })());
          }
          return result;
        })();
      }
    }

    updateScale(e) {
      // Scale the map to match how the visual surface is scaled

      // Determine whether we need to update
      if (e != null ? e.camera : undefined) { this.camera = e.camera; }
      if (e != null ? e.bounds : undefined) { this.simpleMovementBounds = e.bounds; }
      const availableWidth  = this.$el.parent().innerWidth();
      const availableHeight = this.$el.parent().innerHeight();
      if ((availableWidth === this.lastAvailableWidth) && (availableHeight === this.lastAvailableHeight) && _.isEqual(this.simpleMovementBounds, this.lastSimpleMovementBounds) && _.isEqual(this.lastCameraWorldViewport, this.camera.worldViewport)) { return; }
      if (!this.camera || !this.simpleMovementBounds) { return; }
      this.lastAvailableWidth  = availableWidth;
      this.lastAvailableHeight = availableHeight;
      this.lastSimpleMovementBounds = this.simpleMovementBounds;
      this.lastCameraWorldViewport = this.camera.worldViewport;

      // Calculate the new size and offset
      const wv = this.camera.worldViewport;
      const gridWorldWidthWithPadding  = this.simpleMovementBounds.width  + this.grid.resolution;
      const gridWorldHeightWithPadding = this.simpleMovementBounds.height + this.grid.resolution;
      const gridWorldOffsetX = this.simpleMovementBounds.left   - wv.x               - (this.grid.resolution / 2);
      const gridWorldOffsetY = this.simpleMovementBounds.bottom - (wv.y - wv.height) - (this.grid.resolution / 2);
      const screenWidth  = (availableWidth  * gridWorldWidthWithPadding)  / wv.width;
      const screenHeight = (availableHeight * gridWorldHeightWithPadding) / wv.height;
      const screenOffsetX = (gridWorldOffsetX / wv.width)  * availableWidth;
      const screenOffsetY = (gridWorldOffsetY / wv.height) * availableHeight;
      this.$el.css('width',  Math.round(screenWidth) + 'px');
      this.$el.css('height', Math.round(screenHeight) + 'px');
      this.$el.css('left',   Math.round(screenOffsetX) + 'px');
      return this.$el.css('top',    Math.round(availableHeight - screenHeight - screenOffsetY) + 'px');
    }
  };
  ScreenReaderSurfaceView.initClass();
  return ScreenReaderSurfaceView;
})());

function __guard__(value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined;
}