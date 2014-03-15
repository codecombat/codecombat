(function() {
  var WebSocket = window.WebSocket || window.MozWebSocket;
  var br = window.brunch = (window.brunch || {});
  var ar = br['auto-reload'] = (br['auto-reload'] || {});
  if (!WebSocket || ar.disabled) return;

  var cacheBuster = function(url){
    var date = Math.round(Date.now() / 1000).toString();
    url = url.replace(/(\&|\\?)cacheBuster=\d*/, '');
    return url + (url.indexOf('?') >= 0 ? '&' : '?') +'cacheBuster=' + date;
  };

  var reloaders = {
    page: function(){
      window.location.reload(true);
    },

    stylesheet: function(){
      [].slice
        .call(document.querySelectorAll('link[rel="stylesheet"]'))
        .filter(function(link){
          return (link != null && link.href != null);
        })
        .forEach(function(link) {
          link.href = cacheBuster(link.href);
        });
    }
  };
  var port = ar.port || 9485;
  var host = (!br['server']) ? window.location.hostname : br['server'];
  var connection = new WebSocket('ws://' + host + ':' + port);
  connection.onmessage = function(event) {
    var message = event.data;
    if (ar.disabled) return;
    if (reloaders[message] != null) {
      reloaders[message]();
    } else {
      reloaders.page();
    }
  };
})();

;
jade = (function(exports){
/*!
 * Jade - runtime
 * Copyright(c) 2010 TJ Holowaychuk <tj@vision-media.ca>
 * MIT Licensed
 */

/**
 * Lame Array.isArray() polyfill for now.
 */

if (!Array.isArray) {
  Array.isArray = function(arr){
    return '[object Array]' == Object.prototype.toString.call(arr);
  };
}

/**
 * Lame Object.keys() polyfill for now.
 */

if (!Object.keys) {
  Object.keys = function(obj){
    var arr = [];
    for (var key in obj) {
      if (obj.hasOwnProperty(key)) {
        arr.push(key);
      }
    }
    return arr;
  }
}

/**
 * Merge two attribute objects giving precedence
 * to values in object `b`. Classes are special-cased
 * allowing for arrays and merging/joining appropriately
 * resulting in a string.
 *
 * @param {Object} a
 * @param {Object} b
 * @return {Object} a
 * @api private
 */

exports.merge = function merge(a, b) {
  var ac = a['class'];
  var bc = b['class'];

  if (ac || bc) {
    ac = ac || [];
    bc = bc || [];
    if (!Array.isArray(ac)) ac = [ac];
    if (!Array.isArray(bc)) bc = [bc];
    ac = ac.filter(nulls);
    bc = bc.filter(nulls);
    a['class'] = ac.concat(bc).join(' ');
  }

  for (var key in b) {
    if (key != 'class') {
      a[key] = b[key];
    }
  }

  return a;
};

/**
 * Filter null `val`s.
 *
 * @param {Mixed} val
 * @return {Mixed}
 * @api private
 */

function nulls(val) {
  return val != null;
}

/**
 * Render the given attributes object.
 *
 * @param {Object} obj
 * @param {Object} escaped
 * @return {String}
 * @api private
 */

exports.attrs = function attrs(obj, escaped){
  var buf = []
    , terse = obj.terse;

  delete obj.terse;
  var keys = Object.keys(obj)
    , len = keys.length;

  if (len) {
    buf.push('');
    for (var i = 0; i < len; ++i) {
      var key = keys[i]
        , val = obj[key];

      if ('boolean' == typeof val || null == val) {
        if (val) {
          terse
            ? buf.push(key)
            : buf.push(key + '="' + key + '"');
        }
      } else if (0 == key.indexOf('data') && 'string' != typeof val) {
        buf.push(key + "='" + JSON.stringify(val) + "'");
      } else if ('class' == key && Array.isArray(val)) {
        buf.push(key + '="' + exports.escape(val.join(' ')) + '"');
      } else if (escaped && escaped[key]) {
        buf.push(key + '="' + exports.escape(val) + '"');
      } else {
        buf.push(key + '="' + val + '"');
      }
    }
  }

  return buf.join(' ');
};

/**
 * Escape the given string of `html`.
 *
 * @param {String} html
 * @return {String}
 * @api private
 */

exports.escape = function escape(html){
  return String(html)
    .replace(/&(?!(\w+|\#\d+);)/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
};

/**
 * Re-throw the given `err` in context to the
 * the jade in `filename` at the given `lineno`.
 *
 * @param {Error} err
 * @param {String} filename
 * @param {String} lineno
 * @api private
 */

exports.rethrow = function rethrow(err, filename, lineno){
  if (!filename) throw err;

  var context = 3
    , str = require('fs').readFileSync(filename, 'utf8')
    , lines = str.split('\n')
    , start = Math.max(lineno - context, 0)
    , end = Math.min(lines.length, lineno + context);

  // Error context
  var context = lines.slice(start, end).map(function(line, i){
    var curr = i + start + 1;
    return (curr == lineno ? '  > ' : '    ')
      + curr
      + '| '
      + line;
  }).join('\n');

  // Alter exception message
  err.path = filename;
  err.message = (filename || 'Jade') + ':' + lineno
    + '\n' + context + '\n\n' + err.message;
  throw err;
};

  return exports;

})({});

;var TreemaNode,
  __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; },
  __slice = [].slice;

TreemaNode = (function() {
  var defaults;

  TreemaNode.prototype.schema = {};

  TreemaNode.prototype.$el = null;

  TreemaNode.prototype.data = null;

  TreemaNode.prototype.options = null;

  TreemaNode.prototype.parent = null;

  TreemaNode.prototype.nodeTemplate = '<div class="treema-row treema-clearfix"><div class="treema-value"></div></div>';

  TreemaNode.prototype.childrenTemplate = '<div class="treema-children"></div>';

  TreemaNode.prototype.addChildTemplate = '<div class="treema-add-child" tabindex="9009">+</div>';

  TreemaNode.prototype.tempErrorTemplate = '<span class="treema-temp-error"></span>';

  TreemaNode.prototype.toggleTemplate = '<span class="treema-toggle-hit-area"><span class="treema-toggle"></span></span>';

  TreemaNode.prototype.keyTemplate = '<span class="treema-key"></span>';

  TreemaNode.prototype.errorTemplate = '<div class="treema-error"></div>';

  TreemaNode.prototype.newPropertyTemplate = '<input class="treema-new-prop" />';

  TreemaNode.prototype.collection = false;

  TreemaNode.prototype.ordered = false;

  TreemaNode.prototype.keyed = false;

  TreemaNode.prototype.editable = true;

  TreemaNode.prototype.directlyEditable = true;

  TreemaNode.prototype.skipTab = false;

  TreemaNode.prototype.valueClass = null;

  TreemaNode.prototype.removeOnEmptyDelete = true;

  TreemaNode.prototype.keyForParent = null;

  TreemaNode.prototype.childrenTreemas = null;

  TreemaNode.prototype.justCreated = true;

  TreemaNode.prototype.removed = false;

  TreemaNode.prototype.workingSchema = null;

  TreemaNode.prototype.isValid = function() {
    var errors;
    errors = this.getErrors();
    return errors.length === 0;
  };

  TreemaNode.prototype.getErrors = function() {
    var e, errors, moreErrors, my_path, root, _i, _len;
    if (!this.tv4) {
      return [];
    }
    if (this.isRoot()) {
      if (this.cachedErrors) {
        return this.cachedErrors;
      }
      this.cachedErrors = this.tv4.validateMultiple(this.data, this.schema)['errors'];
      return this.cachedErrors;
    }
    root = this.getRoot();
    errors = root.getErrors();
    my_path = this.getPath();
    errors = (function() {
      var _i, _len, _results;
      _results = [];
      for (_i = 0, _len = errors.length; _i < _len; _i++) {
        e = errors[_i];
        if (e.dataPath.slice(0, +my_path.length + 1 || 9e9) === my_path) {
          _results.push(e);
        }
      }
      return _results;
    })();
    for (_i = 0, _len = errors.length; _i < _len; _i++) {
      e = errors[_i];
      e.dataPath = e.dataPath.slice(0, +my_path.length + 1 || 9e9);
    }
    if (this.workingSchema) {
      moreErrors = this.tv4.validateMultiple(this.data, this.workingSchema).errors;
      errors = errors.concat(moreErrors);
    }
    return errors;
  };

  TreemaNode.prototype.setUpValidator = function() {
    var root, _ref;
    if (!this.parent) {
      this.tv4 = (_ref = window['tv4']) != null ? _ref.freshApi() : void 0;
      this.tv4.addSchema('#', this.schema);
      if (this.schema.id) {
        return this.tv4.addSchema(this.schema.id, this.schema);
      }
    } else {
      root = this.getRoot();
      return this.tv4 = root.tv4;
    }
  };

  TreemaNode.prototype.saveChanges = function() {
    return console.error('"saveChanges" has not been overridden.');
  };

  TreemaNode.prototype.getDefaultValue = function() {
    return null;
  };

  TreemaNode.prototype.buildValueForDisplay = function() {
    return console.error('"buildValueForDisplay" has not been overridden.');
  };

  TreemaNode.prototype.buildValueForEditing = function() {
    if (!this.editable) {
      return;
    }
    return console.error('"buildValueForEditing" has not been overridden.');
  };

  TreemaNode.prototype.getChildren = function() {
    return console.error('"getChildren" has not been overridden.');
  };

  TreemaNode.prototype.getChildSchema = function() {
    return console.error('"getChildSchema" has not been overridden.');
  };

  TreemaNode.prototype.canAddChild = function() {
    return this.collection && this.editable && !this.settings.readOnly;
  };

  TreemaNode.prototype.canAddProperty = function() {
    return true;
  };

  TreemaNode.prototype.addingNewProperty = function() {
    return false;
  };

  TreemaNode.prototype.addNewChild = function() {
    return false;
  };

  TreemaNode.prototype.buildValueForDisplaySimply = function(valEl, text) {
    if (text.length > 200) {
      text = text.slice(0, 200) + '...';
    }
    return valEl.append($("<div></div>").addClass('treema-shortened').text(text));
  };

  TreemaNode.prototype.buildValueForEditingSimply = function(valEl, value, inputType) {
    var input;
    if (inputType == null) {
      inputType = null;
    }
    input = $('<input />');
    if (inputType) {
      input.attr('type', inputType);
    }
    if (value !== null) {
      input.val(value);
    }
    valEl.append(input);
    input.focus().select();
    input.blur(this.onEditInputBlur);
    return input;
  };

  TreemaNode.prototype.onEditInputBlur = function(e) {
    var closest, input, shouldRemove;
    shouldRemove = this.shouldTryToRemoveFromParent();
    closest = $(e.relatedTarget).closest('.treema-node')[0];
    if (closest === this.$el[0]) {
      shouldRemove = false;
    }
    this.markAsChanged();
    this.saveChanges(this.getValEl());
    input = this.getValEl().find('input, textarea, select');
    if (this.isValid()) {
      if (this.isEditing()) {
        this.display();
      }
    } else {
      input.focus().select();
    }
    if (shouldRemove) {
      this.remove();
    } else {
      this.flushChanges();
    }
    return this.broadcastChanges();
  };

  TreemaNode.prototype.shouldTryToRemoveFromParent = function() {
    var input, inputs, val, _i, _len;
    return false;
    val = this.getValEl();
    if (val.find('select').length) {
      return;
    }
    inputs = val.find('input, textarea');
    for (_i = 0, _len = inputs.length; _i < _len; _i++) {
      input = inputs[_i];
      input = $(input);
      if (input.attr('type') === 'checkbox' || input.val()) {
        return false;
      }
    }
    return true;
  };

  TreemaNode.prototype.limitChoices = function(options) {
    var _this = this;
    this["enum"] = options;
    this.buildValueForEditing = function(valEl) {
      var index, input, option, _i, _len, _ref;
      input = $('<select></select>');
      _ref = _this["enum"];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        option = _ref[_i];
        input.append($('<option></option>').text(option));
      }
      index = _this["enum"].indexOf(_this.data);
      if (index >= 0) {
        input.prop('selectedIndex', index);
      }
      valEl.append(input);
      input.focus();
      input.blur(_this.onEditInputBlur);
      return input;
    };
    return this.saveChanges = function(valEl) {
      var index;
      index = valEl.find('select').prop('selectedIndex');
      _this.data = _this["enum"][index];
      TreemaNode.changedTreemas.push(_this);
      return _this.broadcastChanges();
    };
  };

  TreemaNode.pluginName = "treema";

  defaults = {
    schema: {},
    callbacks: {}
  };

  function TreemaNode($el, options, parent) {
    this.$el = $el;
    this.parent = parent;
    this.onSelectType = __bind(this.onSelectType, this);
    this.onSelectSchema = __bind(this.onSelectSchema, this);
    this.orderDataFromUI = __bind(this.orderDataFromUI, this);
    this.onMouseLeave = __bind(this.onMouseLeave, this);
    this.onMouseEnter = __bind(this.onMouseEnter, this);
    this.onEditInputBlur = __bind(this.onEditInputBlur, this);
    this.$el = this.$el || $('<div></div>');
    this.settings = $.extend({}, defaults, options);
    this.schema = this.settings.schema;
    if (!(this.schema.id || this.parent)) {
      this.schema.id = '__base__';
    }
    this.data = options.data;
    this.patches = [];
    this.callbacks = this.settings.callbacks;
    this._defaults = defaults;
    this._name = TreemaNode.pluginName;
    this.setUpValidator();
    this.populateData();
    this.previousState = this.copyData();
  }

  TreemaNode.prototype.build = function() {
    var schema, valEl, _ref;
    this.$el.addClass('treema-node').addClass('treema-clearfix');
    this.$el.empty().append($(this.nodeTemplate));
    this.$el.data('instance', this);
    if (!this.parent) {
      this.$el.addClass('treema-root');
    }
    if (!this.parent) {
      this.$el.attr('tabindex', 9001);
    }
    if (!this.parent) {
      this.justCreated = false;
    }
    if (this.collection) {
      this.$el.append($(this.childrenTemplate)).addClass('treema-closed');
    }
    valEl = this.getValEl();
    if (this.valueClass) {
      valEl.addClass(this.valueClass);
    }
    if (this.directlyEditable) {
      valEl.addClass('treema-display');
    }
    this.buildValueForDisplay(valEl);
    if (this.collection && !this.parent) {
      this.open();
    }
    if (!this.parent) {
      this.setUpGlobalEvents();
    }
    if (this.parent) {
      this.setUpLocalEvents();
    }
    if (this.collection) {
      this.updateMyAddButton();
    }
    this.createTypeSelector();
    if (((_ref = this.workingSchemas) != null ? _ref.length : void 0) > 1) {
      this.createSchemaSelector();
    }
    schema = this.workingSchema || this.schema;
    if (schema["enum"]) {
      this.limitChoices(schema["enum"]);
    }
    return this.$el;
  };

  TreemaNode.prototype.populateData = function() {
    if (this.data !== void 0) {
      return;
    }
    this.data = this.schema["default"];
    if (this.data !== void 0) {
      return;
    }
    return this.data = this.getDefaultValue();
  };

  TreemaNode.prototype.setWorkingSchema = function(workingSchema, workingSchemas) {
    this.workingSchema = workingSchema;
    this.workingSchemas = workingSchemas;
  };

  TreemaNode.prototype.createSchemaSelector = function() {
    var button, div, i, label, option, schema, select, _i, _len, _ref;
    div = $('<div></div>').addClass('treema-schema-select-container');
    select = $('<select></select>').addClass('treema-schema-select');
    button = $('<button></button>').addClass('treema-schema-select-button').text('...');
    _ref = this.workingSchemas;
    for (i = _i = 0, _len = _ref.length; _i < _len; i = ++_i) {
      schema = _ref[i];
      label = this.makeWorkingSchemaLabel(schema);
      option = $('<option></option>').attr('value', i).text(label);
      if (schema === this.workingSchema) {
        option.attr('selected', true);
      }
      select.append(option);
    }
    div.append(button).append(select);
    select.change(this.onSelectSchema);
    return this.$el.find('> .treema-row').prepend(div);
  };

  TreemaNode.prototype.makeWorkingSchemaLabel = function(schema) {
    if (schema.title != null) {
      return schema.title;
    }
    if (schema.type != null) {
      return schema.type;
    }
    return '???';
  };

  TreemaNode.prototype.getTypes = function() {
    var schema, types;
    schema = this.workingSchema || this.schema;
    types = schema.type || ["string", "number", "integer", "boolean", "null", "array", "object"];
    if (!$.isArray(types)) {
      types = [types];
    }
    return types;
  };

  TreemaNode.prototype.createTypeSelector = function() {
    var button, currentType, div, option, schema, select, type, types, _i, _len;
    types = this.getTypes();
    if (!(types.length > 1)) {
      return;
    }
    schema = this.workingSchema || this.schema;
    if (schema["enum"]) {
      return;
    }
    div = $('<div></div>').addClass('treema-type-select-container');
    select = $('<select></select>').addClass('treema-type-select');
    button = $('<button></button>').addClass('treema-type-select-button');
    currentType = $.type(this.data);
    if (this.valueClass === 'treema-integer') {
      currentType = 'integer';
    }
    for (_i = 0, _len = types.length; _i < _len; _i++) {
      type = types[_i];
      option = $('<option></option>').attr('value', type).text(type);
      if (type === currentType) {
        option.attr('selected', true);
        button.text(this.typeToLetter(type));
      }
      select.append(option);
    }
    div.append(button).append(select);
    select.change(this.onSelectType);
    return this.$el.find('> .treema-row').prepend(div);
  };

  TreemaNode.prototype.typeToLetter = function(type) {
    return {
      'boolean': 'B',
      'array': 'A',
      'object': 'O',
      'string': 'S',
      'number': 'F',
      'integer': 'I',
      'null': 'N'
    }[type];
  };

  TreemaNode.prototype.setUpGlobalEvents = function() {
    var _this = this;
    this.$el.unbind();
    this.$el.dblclick(function(e) {
      var _ref;
      return (_ref = $(e.target).closest('.treema-node').data('instance')) != null ? _ref.onDoubleClick(e) : void 0;
    });
    this.$el.click(function(e) {
      var _ref;
      if ((_ref = $(e.target).closest('.treema-node').data('instance')) != null) {
        _ref.onClick(e);
      }
      return _this.broadcastChanges(e);
    });
    this.keysPreviouslyDown = {};
    this.$el.keydown(function(e) {
      var closest, lastSelected, _ref;
      e.heldDown = _this.keysPreviouslyDown[e.which] || false;
      closest = $(e.target).closest('.treema-node').data('instance');
      lastSelected = _this.getLastSelectedTreema();
      if ((_ref = lastSelected || closest) != null) {
        _ref.onKeyDown(e);
      }
      _this.broadcastChanges(e);
      _this.keysPreviouslyDown[e.which] = true;
      if (e.ctrlKey || e.metaKey) {
        return _this.manageCopyAndPaste(e);
      }
    });
    return this.$el.keyup(function(e) {
      return delete _this.keysPreviouslyDown[e.which];
    });
  };

  TreemaNode.prototype.manageCopyAndPaste = function(e) {
    var target, x, y, _ref, _ref1, _ref2, _ref3,
      _this = this;
    target = (_ref = this.getLastSelectedTreema()) != null ? _ref : this;
    if (e.which === 86 && $(e.target).hasClass('treema-clipboard')) {
      if (e.shiftKey && $(e.target).hasClass('treema-clipboard')) {
        _ref1 = [window.scrollX, window.scrollY], x = _ref1[0], y = _ref1[1];
        return setTimeout((function() {
          var newData, result;
          _this.keepFocus(x, y);
          if (!(newData = _this.$clipboard.val())) {
            return;
          }
          try {
            newData = JSON.parse(newData);
          } catch (_error) {
            e = _error;
            return;
          }
          result = target.tv4.validateMultiple(newData, target.schema);
          if (result.valid) {
            return target.set('/', newData);
          } else {
            return console.log("not pasting", newData, "because it's not valid:", result);
          }
        }), 10);
      } else {
        return e.preventDefault();
      }
    } else if (e.shiftKey) {
      return this.$clipboardContainer.find('.treema-clipboard').focus().select();
    } else if (!(((_ref2 = window.getSelection()) != null ? _ref2.toString() : void 0) || ((_ref3 = document.selection) != null ? _ref3.createRange().text : void 0))) {
      return setTimeout((function() {
        if (_this.$clipboardContainer == null) {
          _this.$clipboardContainer = $('<div class="treema-clipboard-container"></div>').appendTo(_this.$el);
        }
        _this.$clipboardContainer.empty().show();
        return _this.$clipboard = $('<textarea class="treema-clipboard"></textarea>').val(JSON.stringify(target.data)).appendTo(_this.$clipboardContainer).focus().select();
      }), 0);
    }
  };

  TreemaNode.prototype.broadcastChanges = function(e) {
    var changes, t, _base;
    if (this.callbacks.select && TreemaNode.didSelect) {
      TreemaNode.didSelect = false;
      this.callbacks.select(e, this.getSelectedTreemas());
    }
    if (TreemaNode.changedTreemas.length) {
      changes = (function() {
        var _i, _len, _ref, _results;
        _ref = TreemaNode.changedTreemas;
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          t = _ref[_i];
          if (!t.removed) {
            _results.push(t);
          }
        }
        return _results;
      })();
      if (typeof (_base = this.callbacks).change === "function") {
        _base.change(e, jQuery.unique(changes));
      }
      return TreemaNode.changedTreemas = [];
    }
  };

  TreemaNode.prototype.markAsChanged = function() {
    return TreemaNode.changedTreemas.push(this);
  };

  TreemaNode.prototype.setUpLocalEvents = function() {
    var row;
    row = this.$el.find('> .treema-row');
    if (this.callbacks.mouseenter != null) {
      row.mouseenter(this.onMouseEnter);
    }
    if (this.callbacks.mouseleave != null) {
      return row.mouseleave(this.onMouseLeave);
    }
  };

  TreemaNode.prototype.onMouseEnter = function(e) {
    return this.callbacks.mouseenter(e, this);
  };

  TreemaNode.prototype.onMouseLeave = function(e) {
    return this.callbacks.mouseleave(e, this);
  };

  TreemaNode.prototype.onClick = function(e) {
    var clickedToggle, clickedValue, usedModKey, _ref;
    if ((_ref = e.target.nodeName) === 'INPUT' || _ref === 'TEXTAREA') {
      return;
    }
    clickedValue = $(e.target).closest('.treema-value').length;
    clickedToggle = $(e.target).hasClass('treema-toggle') || $(e.target).hasClass('treema-toggle-hit-area');
    usedModKey = e.shiftKey || e.ctrlKey || e.metaKey;
    if (!(clickedValue && !this.collection)) {
      this.keepFocus();
    }
    if (this.isDisplaying() && clickedValue && this.canEdit() && !usedModKey) {
      return this.toggleEdit();
    }
    if (!usedModKey && (clickedToggle || (clickedValue && this.collection))) {
      if (!clickedToggle) {
        this.deselectAll();
        this.select();
      }
      return this.toggleOpen();
    }
    if ($(e.target).closest('.treema-add-child').length && this.collection) {
      return this.addNewChild();
    }
    if (this.isRoot() || this.isEditing()) {
      return;
    }
    if (e.shiftKey) {
      return this.shiftSelect();
    }
    if (e.ctrlKey || e.metaKey) {
      return this.toggleSelect();
    }
    return this.select();
  };

  TreemaNode.prototype.onDoubleClick = function(e) {
    var clickedKey, _base, _base1, _base2;
    if (!this.collection) {
      return typeof (_base = this.callbacks).dblclick === "function" ? _base.dblclick(e, this) : void 0;
    }
    clickedKey = $(e.target).hasClass('treema-key');
    if (!clickedKey) {
      return typeof (_base1 = this.callbacks).dblclick === "function" ? _base1.dblclick(e, this) : void 0;
    }
    if (this.isClosed()) {
      this.open();
    }
    this.addNewChild();
    return typeof (_base2 = this.callbacks).dblclick === "function" ? _base2.dblclick(e, this) : void 0;
  };

  TreemaNode.prototype.onKeyDown = function(e) {
    if (e.which === 27) {
      this.onEscapePressed(e);
    }
    if (e.which === 9) {
      this.onTabPressed(e);
    }
    if (e.which === 37) {
      this.onLeftArrowPressed(e);
    }
    if (e.which === 38) {
      this.onUpArrowPressed(e);
    }
    if (e.which === 39) {
      this.onRightArrowPressed(e);
    }
    if (e.which === 40) {
      this.onDownArrowPressed(e);
    }
    if (e.which === 13) {
      this.onEnterPressed(e);
    }
    if (e.which === 78) {
      this.onNPressed(e);
    }
    if (e.which === 32) {
      this.onSpacePressed(e);
    }
    if (e.which === 84) {
      this.onTPressed(e);
    }
    if (e.which === 70) {
      this.onFPressed(e);
    }
    if (e.which === 8 && !e.heldDown) {
      return this.onDeletePressed(e);
    }
  };

  TreemaNode.prototype.onLeftArrowPressed = function(e) {
    if (this.inputFocused()) {
      return;
    }
    this.navigateOut();
    return e.preventDefault();
  };

  TreemaNode.prototype.onRightArrowPressed = function(e) {
    if (this.inputFocused()) {
      return;
    }
    this.navigateIn();
    return e.preventDefault();
  };

  TreemaNode.prototype.onUpArrowPressed = function(e) {
    if (this.inputFocused()) {
      return;
    }
    this.navigateSelection(-1);
    return e.preventDefault();
  };

  TreemaNode.prototype.onDownArrowPressed = function(e) {
    if (this.inputFocused()) {
      return;
    }
    this.navigateSelection(1);
    return e.preventDefault();
  };

  TreemaNode.prototype.inputFocused = function() {
    var _ref;
    if ((_ref = document.activeElement.nodeName) === 'INPUT' || _ref === 'TEXTAREA' || _ref === 'SELECT') {
      return true;
    }
  };

  TreemaNode.prototype.onSpacePressed = function() {};

  TreemaNode.prototype.onTPressed = function() {};

  TreemaNode.prototype.onFPressed = function() {};

  TreemaNode.prototype.onDeletePressed = function(e) {
    var editing;
    editing = this.editingIsHappening();
    if (editing && !$(e.target).val() && this.removeOnEmptyDelete) {
      this.display();
      this.select();
      this.removeSelectedNodes();
      e.preventDefault();
    }
    if (editing) {
      return;
    }
    e.preventDefault();
    return this.removeSelectedNodes();
  };

  TreemaNode.prototype.onEscapePressed = function() {
    if (!this.isEditing()) {
      return;
    }
    if (this.justCreated) {
      return this.remove();
    }
    if (this.isEditing()) {
      this.display();
    }
    if (!this.isRoot()) {
      this.select();
    }
    return this.keepFocus();
  };

  TreemaNode.prototype.onEnterPressed = function(e) {
    var offset;
    offset = e.shiftKey ? -1 : 1;
    if (offset === 1 && $(e.target).hasClass('treema-add-child')) {
      return this.addNewChild();
    }
    return this.traverseWhileEditing(offset, true);
  };

  TreemaNode.prototype.onTabPressed = function(e) {
    var offset;
    offset = e.shiftKey ? -1 : 1;
    if (this.hasMoreInputs(offset)) {
      return;
    }
    e.preventDefault();
    return this.traverseWhileEditing(offset, false);
  };

  TreemaNode.prototype.hasMoreInputs = function(offset) {
    var input, inputs, passedFocusedEl, _i, _len;
    inputs = this.getInputs().toArray();
    if (offset < 0) {
      inputs = inputs.reverse();
    }
    passedFocusedEl = false;
    for (_i = 0, _len = inputs.length; _i < _len; _i++) {
      input = inputs[_i];
      if (input === document.activeElement) {
        passedFocusedEl = true;
        continue;
      }
      if (!passedFocusedEl) {
        continue;
      }
      return true;
    }
    return false;
  };

  TreemaNode.prototype.onNPressed = function(e) {
    var selected, success, target;
    if (this.editingIsHappening()) {
      return;
    }
    selected = this.getLastSelectedTreema();
    target = (selected != null ? selected.collection : void 0) ? selected : selected != null ? selected.parent : void 0;
    if (!target) {
      return;
    }
    success = target.addNewChild();
    if (success) {
      this.deselectAll();
    }
    return e.preventDefault();
  };

  TreemaNode.prototype.traverseWhileEditing = function(offset, aggressive) {
    var ctx, editing, selected, shouldRemove, targetEl, _ref;
    shouldRemove = false;
    selected = this.getLastSelectedTreema();
    editing = this.isEditing();
    if (!editing && (selected != null ? selected.canEdit() : void 0)) {
      return selected.edit();
    }
    if (editing) {
      shouldRemove = this.shouldTryToRemoveFromParent();
      this.saveChanges(this.getValEl());
      if (!shouldRemove) {
        this.flushChanges();
      }
      if (!(aggressive || this.isValid())) {
        this.refreshErrors();
        return;
      }
      if (shouldRemove && ((_ref = $(this.$el[0].nextSibling)) != null ? _ref.hasClass('treema-add-child') : void 0) && offset === 1) {
        offset = 2;
      }
      this.endExistingEdits();
      this.select();
    }
    ctx = this.traversalContext(offset);
    if (!ctx) {
      return this.getRoot().addChild();
    }
    if (!ctx.origin) {
      targetEl = offset > 0 ? ctx.first : ctx.last;
      this.selectOrActivateElement(targetEl);
    }
    selected = $(ctx.origin).data('instance');
    if (offset > 0 && aggressive && selected.collection && selected.isClosed()) {
      return selected.open();
    }
    targetEl = offset > 0 ? ctx.next : ctx.prev;
    if (!targetEl) {
      targetEl = offset > 0 ? ctx.first : ctx.last;
    }
    this.selectOrActivateElement(targetEl);
    if (shouldRemove) {
      return this.remove();
    } else {
      return this.refreshErrors();
    }
  };

  TreemaNode.prototype.selectOrActivateElement = function(el) {
    var treema;
    el = $(el);
    treema = el.data('instance');
    if (treema) {
      if (treema.canEdit()) {
        return treema.edit();
      } else {
        return treema.select();
      }
    }
    this.deselectAll();
    return el.focus();
  };

  TreemaNode.prototype.navigateSelection = function(offset) {
    var ctx, targetTreema;
    ctx = this.navigationContext();
    if (!ctx) {
      return;
    }
    if (!ctx.origin) {
      targetTreema = offset > 0 ? ctx.first : ctx.last;
      return targetTreema.select();
    }
    targetTreema = offset > 0 ? ctx.next : ctx.prev;
    if (!targetTreema) {
      targetTreema = offset > 0 ? ctx.first : ctx.last;
    }
    return targetTreema != null ? targetTreema.select() : void 0;
  };

  TreemaNode.prototype.navigateOut = function() {
    var selected;
    selected = this.getLastSelectedTreema();
    if (!selected) {
      return;
    }
    if (selected.isOpen()) {
      return selected.close();
    }
    if ((!selected.parent) || selected.parent.isRoot()) {
      return;
    }
    return selected.parent.select();
  };

  TreemaNode.prototype.navigateIn = function() {
    var treema, _i, _len, _ref, _results;
    _ref = this.getSelectedTreemas();
    _results = [];
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      treema = _ref[_i];
      if (!treema.collection) {
        continue;
      }
      if (treema.isClosed()) {
        _results.push(treema.open());
      } else {
        _results.push(void 0);
      }
    }
    return _results;
  };

  TreemaNode.prototype.traversalContext = function(offset) {
    var list, origin, _ref;
    list = this.getNavigableElements(offset);
    origin = (_ref = this.getLastSelectedTreema()) != null ? _ref.$el[0] : void 0;
    if (!origin) {
      origin = this.getRootEl().find('.treema-add-child:focus')[0];
    }
    if (!origin) {
      origin = this.getRootEl().find('.treema-new-prop')[0];
    }
    return this.wrapContext(list, origin, offset);
  };

  TreemaNode.prototype.navigationContext = function() {
    var list, origin;
    list = this.getVisibleTreemas();
    origin = this.getLastSelectedTreema();
    return this.wrapContext(list, origin);
  };

  TreemaNode.prototype.wrapContext = function(list, origin, offset) {
    var c, originIndex;
    if (offset == null) {
      offset = 1;
    }
    if (!list.length) {
      return;
    }
    c = {
      first: list[0],
      last: list[list.length - 1],
      origin: origin
    };
    if (origin) {
      offset = Math.abs(offset);
      originIndex = list.indexOf(origin);
      c.next = list[originIndex + offset];
      c.prev = list[originIndex - offset];
    }
    return c;
  };

  TreemaNode.prototype.canEdit = function() {
    var _ref;
    if (this.schema.readOnly || ((_ref = this.parent) != null ? _ref.schema.readOnly : void 0)) {
      return false;
    }
    if (this.settings.readOnly) {
      return false;
    }
    if (!this.editable) {
      return false;
    }
    if (!this.directlyEditable) {
      return false;
    }
    if (this.collection && this.isOpen()) {
      return false;
    }
    return true;
  };

  TreemaNode.prototype.display = function() {
    return this.toggleEdit('treema-display');
  };

  TreemaNode.prototype.edit = function(options) {
    if (options == null) {
      options = {};
    }
    this.toggleEdit('treema-edit');
    if ((options.offset != null) && options.offset < 0) {
      return this.focusLastInput();
    }
  };

  TreemaNode.prototype.toggleEdit = function(toClass) {
    var valEl;
    if (toClass == null) {
      toClass = null;
    }
    if (!this.editable) {
      return;
    }
    valEl = this.getValEl();
    if (toClass && valEl.hasClass(toClass)) {
      return;
    }
    toClass = toClass || (valEl.hasClass('treema-display') ? 'treema-edit' : 'treema-display');
    if (toClass === 'treema-edit') {
      this.endExistingEdits();
    }
    valEl.removeClass('treema-display').removeClass('treema-edit').addClass(toClass);
    valEl.empty();
    if (this.isDisplaying()) {
      this.buildValueForDisplay(valEl);
    }
    if (this.isEditing()) {
      this.buildValueForEditing(valEl);
      return this.deselectAll();
    }
  };

  TreemaNode.prototype.endExistingEdits = function() {
    var editing, elem, treema, _i, _len, _results;
    editing = this.getRootEl().find('.treema-edit').closest('.treema-node');
    _results = [];
    for (_i = 0, _len = editing.length; _i < _len; _i++) {
      elem = editing[_i];
      treema = $(elem).data('instance');
      treema.saveChanges(treema.getValEl());
      treema.display();
      _results.push(this.markAsChanged());
    }
    return _results;
  };

  TreemaNode.prototype.flushChanges = function() {
    var parent, _results;
    if (this.parent && this.justCreated) {
      this.parent.integrateChildTreema(this);
    }
    this.getRoot().cachedErrors = null;
    this.justCreated = false;
    this.markAsChanged();
    if (!this.parent) {
      return this.refreshErrors();
    }
    this.parent.data[this.keyForParent] = this.data;
    this.parent.refreshErrors();
    parent = this.parent;
    _results = [];
    while (parent) {
      parent.buildValueForDisplay(parent.getValEl().empty());
      _results.push(parent = parent.parent);
    }
    return _results;
  };

  TreemaNode.prototype.focusLastInput = function() {
    var inputs, last;
    inputs = this.getInputs();
    last = inputs[inputs.length - 1];
    return $(last).focus().select();
  };

  TreemaNode.prototype.removeSelectedNodes = function() {
    var nextSibling, prevSibling, selected, toSelect, treema, _i, _len;
    selected = this.getSelectedTreemas();
    toSelect = null;
    if (selected.length === 1) {
      nextSibling = selected[0].$el.next('.treema-node').data('instance');
      prevSibling = selected[0].$el.prev('.treema-node').data('instance');
      toSelect = nextSibling || prevSibling || selected[0].parent;
    }
    for (_i = 0, _len = selected.length; _i < _len; _i++) {
      treema = selected[_i];
      treema.remove();
    }
    if (toSelect && !this.getSelectedTreemas().length) {
      return toSelect.select();
    }
  };

  TreemaNode.prototype.remove = function() {
    var readOnly, required, root, tempError, _ref, _ref1;
    required = this.parent && (this.parent.schema.required != null) && (_ref = this.keyForParent, __indexOf.call(this.parent.schema.required, _ref) >= 0);
    if (required) {
      tempError = this.createTemporaryError('required');
      this.$el.prepend(tempError);
      return false;
    }
    readOnly = this.schema.readOnly || ((_ref1 = this.parent) != null ? _ref1.schema.readOnly : void 0);
    if (readOnly) {
      tempError = this.createTemporaryError('read only');
      this.$el.prepend(tempError);
      return false;
    }
    root = this.getRootEl();
    this.$el.remove();
    this.removed = true;
    if (document.activeElement === $('body')[0]) {
      this.keepFocus();
    }
    if (this.parent == null) {
      return true;
    }
    delete this.parent.childrenTreemas[this.keyForParent];
    delete this.parent.data[this.keyForParent];
    if (this.parent.ordered) {
      this.parent.orderDataFromUI();
    }
    this.parent.refreshErrors();
    this.parent.updateMyAddButton();
    this.parent.markAsChanged();
    this.parent.buildValueForDisplay(this.parent.getValEl().empty());
    this.broadcastChanges();
    return true;
  };

  TreemaNode.prototype.toggleOpen = function() {
    if (this.isClosed()) {
      this.open();
    } else {
      this.close();
    }
    return this;
  };

  TreemaNode.prototype.open = function(depth) {
    var child, childIndex, childNode, childrenContainer, key, schema, treema, value, _i, _len, _ref, _ref1, _ref2, _ref3, _results;
    if (depth == null) {
      depth = 1;
    }
    if (this.isClosed()) {
      childrenContainer = this.$el.find('.treema-children').detach();
      childrenContainer.empty();
      this.childrenTreemas = {};
      _ref = this.getChildren();
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        _ref1 = _ref[_i], key = _ref1[0], value = _ref1[1], schema = _ref1[2];
        if (schema.format === 'hidden') {
          continue;
        }
        treema = TreemaNode.make(null, {
          schema: schema,
          data: value
        }, this, key);
        this.integrateChildTreema(treema);
        childNode = this.createChildNode(treema);
        childrenContainer.append(childNode);
      }
      this.$el.append(childrenContainer).removeClass('treema-closed').addClass('treema-open');
      childrenContainer.append($(this.addChildTemplate));
      if (this.ordered && childrenContainer.sortable && !this.settings.noSortable) {
        if (typeof childrenContainer.sortable === "function") {
          childrenContainer.sortable({
            deactivate: this.orderDataFromUI
          });
        }
      }
      this.refreshErrors();
    }
    depth -= 1;
    if (depth) {
      _ref3 = (_ref2 = this.childrenTreemas) != null ? _ref2 : {};
      _results = [];
      for (childIndex in _ref3) {
        child = _ref3[childIndex];
        _results.push(child.open(depth));
      }
      return _results;
    }
  };

  TreemaNode.prototype.orderDataFromUI = function() {
    var child, children, index, treema, _i, _len;
    children = this.$el.find('> .treema-children > .treema-node');
    index = 0;
    this.childrenTreemas = {};
    this.data = $.isArray(this.data) ? [] : {};
    for (_i = 0, _len = children.length; _i < _len; _i++) {
      child = children[_i];
      treema = $(child).data('instance');
      if (!treema) {
        continue;
      }
      treema.keyForParent = index;
      this.childrenTreemas[index] = treema;
      this.data[index] = treema.data;
      index += 1;
    }
    return this.flushChanges();
  };

  TreemaNode.prototype.close = function(saveChildData) {
    var key, treema, _ref;
    if (saveChildData == null) {
      saveChildData = true;
    }
    if (!this.isOpen()) {
      return;
    }
    if (saveChildData) {
      _ref = this.childrenTreemas;
      for (key in _ref) {
        treema = _ref[key];
        this.data[key] = treema.data;
      }
    }
    this.$el.find('.treema-children').empty();
    this.$el.addClass('treema-closed').removeClass('treema-open');
    this.childrenTreemas = null;
    this.refreshErrors();
    return this.buildValueForDisplay(this.getValEl().empty());
  };

  TreemaNode.prototype.select = function() {
    var excludeSelf, numSelected;
    numSelected = this.getSelectedTreemas().length;
    excludeSelf = numSelected === 1;
    this.deselectAll(excludeSelf);
    this.toggleSelect();
    this.keepFocus();
    return TreemaNode.didSelect = true;
  };

  TreemaNode.prototype.deselectAll = function(excludeSelf) {
    var treema, _i, _len, _ref;
    if (excludeSelf == null) {
      excludeSelf = false;
    }
    _ref = this.getSelectedTreemas();
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      treema = _ref[_i];
      if (excludeSelf && treema === this) {
        continue;
      }
      treema.$el.removeClass('treema-selected');
    }
    this.clearLastSelected();
    return TreemaNode.didSelect = true;
  };

  TreemaNode.prototype.toggleSelect = function() {
    this.clearLastSelected();
    if (!this.isRoot()) {
      this.$el.toggleClass('treema-selected');
    }
    if (this.isSelected()) {
      this.$el.addClass('treema-last-selected');
    }
    return TreemaNode.didSelect = true;
  };

  TreemaNode.prototype.clearLastSelected = function() {
    return this.getRootEl().find('.treema-last-selected').removeClass('treema-last-selected');
  };

  TreemaNode.prototype.shiftSelect = function() {
    var allNodes, lastSelected, node, started, _i, _len;
    lastSelected = this.getRootEl().find('.treema-last-selected');
    if (!lastSelected.length) {
      this.select();
    }
    this.deselectAll();
    allNodes = this.getRootEl().find('.treema-node');
    started = false;
    for (_i = 0, _len = allNodes.length; _i < _len; _i++) {
      node = allNodes[_i];
      node = $(node).data('instance');
      if (!started) {
        if (node === this || node.wasSelectedLast()) {
          started = true;
        }
        if (started) {
          node.$el.addClass('treema-selected');
        }
        continue;
      }
      if (started && (node === this || node.wasSelectedLast())) {
        break;
      }
      node.$el.addClass('treema-selected');
    }
    this.$el.addClass('treema-selected');
    lastSelected.addClass('treema-selected');
    lastSelected.removeClass('treema-last-selected');
    this.$el.addClass('treema-last-selected');
    return TreemaNode.didSelect = true;
  };

  TreemaNode.prototype.buildWorkingSchemas = function(originalSchema) {
    var allOf, anyOf, baseSchema, oneOf, s, schema, singularSchema, singularSchemas, workingSchemas, _i, _j, _len, _len1;
    baseSchema = this.resolveReference($.extend(true, {}, originalSchema || {}));
    allOf = baseSchema.allOf;
    anyOf = baseSchema.anyOf;
    oneOf = baseSchema.oneOf;
    if (baseSchema.allOf != null) {
      delete baseSchema.allOf;
    }
    if (baseSchema.anyOf != null) {
      delete baseSchema.anyOf;
    }
    if (baseSchema.oneOf != null) {
      delete baseSchema.oneOf;
    }
    if (allOf != null) {
      for (_i = 0, _len = allOf.length; _i < _len; _i++) {
        schema = allOf[_i];
        $.extend(null, baseSchema, this.resolveReference(schema));
      }
    }
    workingSchemas = [];
    singularSchemas = [];
    if (anyOf != null) {
      singularSchemas = singularSchemas.concat(anyOf);
    }
    if (oneOf != null) {
      singularSchemas = singularSchemas.concat(oneOf);
    }
    for (_j = 0, _len1 = singularSchemas.length; _j < _len1; _j++) {
      singularSchema = singularSchemas[_j];
      singularSchema = this.resolveReference(singularSchema);
      s = $.extend(true, {}, baseSchema);
      s = $.extend(true, s, singularSchema);
      workingSchemas.push(s);
    }
    if (workingSchemas.length === 0) {
      workingSchemas = [baseSchema];
    }
    return workingSchemas;
  };

  TreemaNode.prototype.resolveReference = function(schema, scrubTitle) {
    var resolved;
    if (scrubTitle == null) {
      scrubTitle = false;
    }
    if (schema.$ref == null) {
      return schema;
    }
    resolved = this.tv4.getSchema(schema.$ref);
    if (!resolved) {
      console.warn('could not resolve reference', schema.$ref, tv4.getMissingUris());
    }
    if (resolved == null) {
      resolved = {};
    }
    if (scrubTitle && (resolved.title != null)) {
      delete resolved.title;
    }
    return resolved;
  };

  TreemaNode.prototype.chooseWorkingSchema = function(workingSchemas, data) {
    var result, root, schema, _i, _len;
    if (workingSchemas.length === 1) {
      return workingSchemas[0];
    }
    root = this.getRoot();
    for (_i = 0, _len = workingSchemas.length; _i < _len; _i++) {
      schema = workingSchemas[_i];
      result = tv4.validateMultiple(data, schema, false, root.schema);
      if (result.valid) {
        return schema;
      }
    }
    return workingSchemas[0];
  };

  TreemaNode.prototype.onSelectSchema = function(e) {
    var NodeClass, defaultType, index, workingSchema;
    index = parseInt($(e.target).val());
    workingSchema = this.workingSchemas[index];
    defaultType = "null";
    if (workingSchema["default"] != null) {
      defaultType = $.type(workingSchema["default"]);
    }
    if (workingSchema.type != null) {
      defaultType = workingSchema.type;
    }
    if ($.isArray(defaultType)) {
      defaultType = defaultType[0];
    }
    NodeClass = TreemaNode.getNodeClassForSchema(workingSchema, defaultType, this.settings.nodeClasses);
    this.workingSchema = workingSchema;
    return this.replaceNode(NodeClass);
  };

  TreemaNode.prototype.onSelectType = function(e) {
    var NodeClass, newType;
    newType = $(e.target).val();
    NodeClass = TreemaNode.getNodeClassForSchema(this.workingSchema, newType, this.settings.nodeClasses);
    return this.replaceNode(NodeClass);
  };

  TreemaNode.prototype.replaceNode = function(NodeClass) {
    var newNode, oldData, settings;
    settings = $.extend(true, {}, this.settings);
    oldData = this.data;
    if (settings.data) {
      delete settings.data;
    }
    newNode = new NodeClass(null, settings, this.parent);
    newNode.data = newNode.getDefaultValue();
    if (this.workingSchema["default"] != null) {
      newNode.data = this.workingSchema["default"];
    }
    if ($.type(oldData) === 'string' && $.type(newNode.data) === 'number') {
      newNode.data = parseFloat(oldData) || 0;
    }
    if ($.type(oldData) === 'number' && $.type(newNode.data) === 'string') {
      newNode.data = oldData.toString();
    }
    if ($.type(oldData) === 'number' && $.type(newNode.data) === 'number') {
      newNode.data = oldData;
      if (newNode.valueClass === 'treema-integer') {
        newNode.data = parseInt(newNode.data);
      }
    }
    newNode.tv4 = this.tv4;
    if (this.keyForParent != null) {
      newNode.keyForParent = this.keyForParent;
    }
    newNode.setWorkingSchema(this.workingSchema, this.workingSchemas);
    this.parent.createChildNode(newNode);
    this.$el.replaceWith(newNode.$el);
    return newNode.flushChanges();
  };

  TreemaNode.prototype.integrateChildTreema = function(treema) {
    treema.justCreated = false;
    this.childrenTreemas[treema.keyForParent] = treema;
    treema.populateData();
    this.data[treema.keyForParent] = treema.data;
    return treema;
  };

  TreemaNode.prototype.createChildNode = function(treema) {
    var childNode, defnEl, keyEl, name, required, row, suffix, _ref;
    childNode = treema.build();
    row = childNode.find('.treema-row');
    if (this.collection && this.keyed) {
      name = treema.schema.title || treema.keyForParent;
      required = this.schema.required || [];
      suffix = ': ';
      if (_ref = treema.keyForParent, __indexOf.call(required, _ref) >= 0) {
        suffix = '*' + suffix;
      }
      keyEl = $(this.keyTemplate).text(name + suffix);
      row.prepend(keyEl);
      defnEl = $('<span></span>').addClass('treema-description').text(treema.schema.description || '');
      row.append(defnEl);
    }
    if (treema.collection) {
      childNode.prepend($(this.toggleTemplate));
    }
    return childNode;
  };

  TreemaNode.prototype.refreshErrors = function() {
    this.clearErrors();
    return this.showErrors();
  };

  TreemaNode.prototype.showErrors = function() {
    var childErrors, deepestTreema, e, error, erroredTreemas, errors, message, messages, ownErrors, path, subpath, treema, _i, _j, _k, _len, _len1, _len2, _ref, _results;
    if (this.justCreated) {
      return;
    }
    errors = this.getErrors();
    erroredTreemas = [];
    for (_i = 0, _len = errors.length; _i < _len; _i++) {
      error = errors[_i];
      path = error.dataPath.slice(1);
      path = path ? path.split('/') : [];
      deepestTreema = this;
      for (_j = 0, _len1 = path.length; _j < _len1; _j++) {
        subpath = path[_j];
        if (!deepestTreema.childrenTreemas) {
          error.forChild = true;
          break;
        }
        if (deepestTreema.ordered) {
          subpath = parseInt(subpath);
        }
        deepestTreema = deepestTreema.childrenTreemas[subpath];
        if (!deepestTreema) {
          console.error('could not find treema down path', path, this, "so couldn't show error", error);
          return;
        }
      }
      if (!(deepestTreema._errors && __indexOf.call(erroredTreemas, deepestTreema) >= 0)) {
        deepestTreema._errors = [];
      }
      deepestTreema._errors.push(error);
      erroredTreemas.push(deepestTreema);
    }
    _ref = $.unique(erroredTreemas);
    _results = [];
    for (_k = 0, _len2 = _ref.length; _k < _len2; _k++) {
      treema = _ref[_k];
      childErrors = (function() {
        var _l, _len3, _ref1, _results1;
        _ref1 = treema._errors;
        _results1 = [];
        for (_l = 0, _len3 = _ref1.length; _l < _len3; _l++) {
          e = _ref1[_l];
          if (e.forChild) {
            _results1.push(e);
          }
        }
        return _results1;
      })();
      ownErrors = (function() {
        var _l, _len3, _ref1, _results1;
        _ref1 = treema._errors;
        _results1 = [];
        for (_l = 0, _len3 = _ref1.length; _l < _len3; _l++) {
          e = _ref1[_l];
          if (!e.forChild) {
            _results1.push(e);
          }
        }
        return _results1;
      })();
      messages = (function() {
        var _l, _len3, _results1;
        _results1 = [];
        for (_l = 0, _len3 = ownErrors.length; _l < _len3; _l++) {
          e = ownErrors[_l];
          _results1.push(e.message);
        }
        return _results1;
      })();
      if (childErrors.length > 0) {
        message = "[" + childErrors.length + "] error";
        if (childErrors.length > 1) {
          message = message + 's';
        }
        messages.push(message);
      }
      _results.push(treema.showError(messages.join('<br />')));
    }
    return _results;
  };

  TreemaNode.prototype.showError = function(message) {
    this.$el.prepend($(this.errorTemplate));
    this.$el.find('> .treema-error').html(message).show();
    return this.$el.addClass('treema-has-error');
  };

  TreemaNode.prototype.clearErrors = function() {
    this.$el.find('.treema-error').remove();
    this.$el.find('.treema-has-error').removeClass('treema-has-error');
    return this.$el.removeClass('treema-has-error');
  };

  TreemaNode.prototype.createTemporaryError = function(message, attachFunction) {
    if (attachFunction == null) {
      attachFunction = null;
    }
    if (!attachFunction) {
      attachFunction = this.$el.prepend;
    }
    this.clearTemporaryErrors();
    return $(this.tempErrorTemplate).text(message).delay(3000).fadeOut(1000, function() {
      return $(this).remove();
    });
  };

  TreemaNode.prototype.clearTemporaryErrors = function() {
    return this.getRootEl().find('.treema-temp-error').remove();
  };

  TreemaNode.prototype.get = function(path) {
    var data, seg, _i, _len;
    if (path == null) {
      path = '/';
    }
    path = this.normalizePath(path);
    if (path.length === 0) {
      return this.data;
    }
    if (this.childrenTreemas != null) {
      return this.digDeeper(path, 'get', void 0, []);
    }
    data = this.data;
    for (_i = 0, _len = path.length; _i < _len; _i++) {
      seg = path[_i];
      data = data[this.normalizeKey(seg, data)];
      if (data === void 0) {
        break;
      }
    }
    return data;
  };

  TreemaNode.prototype.set = function(path, newData) {
    var data, i, result, seg, _i, _len;
    path = this.normalizePath(path);
    if (path.length === 0) {
      this.data = newData;
      this.refreshDisplay();
      return true;
    }
    if (this.childrenTreemas != null) {
      result = this.digDeeper(path, 'set', false, [newData]);
      if (result === false && path.length === 1 && $.isPlainObject(this.data)) {
        this.data[path[0]] = newData;
        return true;
      }
      return result;
    }
    data = this.data;
    for (i = _i = 0, _len = path.length; _i < _len; i = ++_i) {
      seg = path[i];
      seg = this.normalizeKey(seg, data);
      if (path.length === i + 1) {
        data[seg] = newData;
        this.refreshDisplay();
        return true;
      } else {
        data = data[seg];
        if (data === void 0) {
          return false;
        }
      }
    }
  };

  TreemaNode.prototype["delete"] = function(path) {
    var data, i, seg, _i, _len;
    path = this.normalizePath(path);
    if (path.length === 0) {
      return this.remove();
    }
    if (this.childrenTreemas != null) {
      return this.digDeeper(path, 'delete', false, []);
    }
    data = this.data;
    for (i = _i = 0, _len = path.length; _i < _len; i = ++_i) {
      seg = path[i];
      seg = this.normalizeKey(seg, data);
      if (path.length === i + 1) {
        if ($.isArray(data)) {
          data.splice(seg, 1);
        } else {
          delete data[seg];
        }
        this.refreshDisplay();
        return true;
      } else {
        data = data[seg];
        if (data === void 0) {
          return false;
        }
      }
    }
  };

  TreemaNode.prototype.insert = function(path, newData) {
    var data, i, seg, _i, _len;
    path = this.normalizePath(path);
    if (path.length === 0) {
      if (!$.isArray(this.data)) {
        return false;
      }
      this.data.push(newData);
      this.refreshDisplay();
      this.flushChanges();
      return true;
    }
    if (this.childrenTreemas != null) {
      return this.digDeeper(path, 'insert', false, [newData]);
    }
    data = this.data;
    for (i = _i = 0, _len = path.length; _i < _len; i = ++_i) {
      seg = path[i];
      seg = this.normalizeKey(seg, data);
      data = data[seg];
      if (data === void 0) {
        return false;
      }
    }
    if (!$.isArray(data)) {
      return false;
    }
    data.push(newData);
    this.refreshDisplay();
    return true;
  };

  TreemaNode.prototype.normalizeKey = function(key, collection) {
    var i, parts, value, _i, _len;
    if ($.isArray(collection)) {
      if (__indexOf.call(key, '=') >= 0) {
        parts = key.split('=');
        for (i = _i = 0, _len = collection.length; _i < _len; i = ++_i) {
          value = collection[i];
          if (value[parts[0]] === parts[1]) {
            return i;
          }
        }
      } else {
        return parseInt(key);
      }
    }
    return key;
  };

  TreemaNode.prototype.normalizePath = function(path) {
    var s;
    if ($.type(path) === 'string') {
      path = path.split('/');
      path = (function() {
        var _i, _len, _results;
        _results = [];
        for (_i = 0, _len = path.length; _i < _len; _i++) {
          s = path[_i];
          if (s.length) {
            _results.push(s);
          }
        }
        return _results;
      })();
    }
    return path;
  };

  TreemaNode.prototype.digDeeper = function(path, func, def, args) {
    var childTreema, seg;
    seg = this.normalizeKey(path[0], this.data);
    childTreema = this.childrenTreemas[seg];
    if (childTreema === void 0) {
      return def;
    }
    return childTreema[func].apply(childTreema, [path.slice(1)].concat(__slice.call(args)));
  };

  TreemaNode.prototype.refreshDisplay = function() {
    var valEl;
    if (this.isDisplaying()) {
      valEl = this.getValEl();
      valEl.empty();
      this.buildValueForDisplay(valEl);
    } else {
      this.display();
    }
    if (this.collection && this.isOpen()) {
      this.close(false);
      this.open();
    }
    this.flushChanges();
    return this.broadcastChanges();
  };

  TreemaNode.prototype.getValEl = function() {
    return this.$el.find('> .treema-row .treema-value');
  };

  TreemaNode.prototype.getRootEl = function() {
    return this.$el.closest('.treema-root');
  };

  TreemaNode.prototype.getRoot = function() {
    var node;
    node = this;
    while (node.parent != null) {
      node = node.parent;
    }
    return node;
  };

  TreemaNode.prototype.getInputs = function() {
    return this.getValEl().find('input, textarea');
  };

  TreemaNode.prototype.getSelectedTreemas = function() {
    var el, _i, _len, _ref, _results;
    _ref = this.getRootEl().find('.treema-selected');
    _results = [];
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      el = _ref[_i];
      _results.push($(el).data('instance'));
    }
    return _results;
  };

  TreemaNode.prototype.getLastSelectedTreema = function() {
    return this.getRootEl().find('.treema-last-selected').data('instance');
  };

  TreemaNode.prototype.getAddButtonEl = function() {
    return this.$el.find('> .treema-children > .treema-add-child');
  };

  TreemaNode.prototype.getVisibleTreemas = function() {
    var el, _i, _len, _ref, _results;
    _ref = this.getRootEl().find('.treema-node');
    _results = [];
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      el = _ref[_i];
      _results.push($(el).data('instance'));
    }
    return _results;
  };

  TreemaNode.prototype.getNavigableElements = function() {
    return this.getRootEl().find('.treema-node, .treema-add-child:visible').toArray();
  };

  TreemaNode.prototype.getPath = function() {
    var pathPieces, pointer;
    pathPieces = [];
    pointer = this;
    while (pointer && (pointer.keyForParent != null)) {
      pathPieces.push(pointer.keyForParent + '');
      pointer = pointer.parent;
    }
    pathPieces.reverse();
    return '/' + pathPieces.join('/');
  };

  TreemaNode.prototype.isRoot = function() {
    return !this.parent;
  };

  TreemaNode.prototype.isEditing = function() {
    return this.getValEl().hasClass('treema-edit');
  };

  TreemaNode.prototype.isDisplaying = function() {
    return this.getValEl().hasClass('treema-display');
  };

  TreemaNode.prototype.isOpen = function() {
    return this.$el.hasClass('treema-open');
  };

  TreemaNode.prototype.isClosed = function() {
    return this.$el.hasClass('treema-closed');
  };

  TreemaNode.prototype.isSelected = function() {
    return this.$el.hasClass('treema-selected');
  };

  TreemaNode.prototype.wasSelectedLast = function() {
    return this.$el.hasClass('treema-last-selected');
  };

  TreemaNode.prototype.editingIsHappening = function() {
    return this.getRootEl().find('.treema-edit').length;
  };

  TreemaNode.prototype.rootSelected = function() {
    return $(document.activeElement).hasClass('treema-root');
  };

  TreemaNode.prototype.keepFocus = function(x, y) {
    var _ref;
    if (!((x != null) && (y != null))) {
      _ref = [window.scrollX, window.scrollY], x = _ref[0], y = _ref[1];
    }
    this.getRootEl().focus();
    return window.scrollTo(x, y);
  };

  TreemaNode.prototype.copyData = function() {
    return $.extend(null, {}, {
      'd': this.data
    })['d'];
  };

  TreemaNode.prototype.updateMyAddButton = function() {
    this.$el.removeClass('treema-full');
    if (!this.canAddChild()) {
      return this.$el.addClass('treema-full');
    }
  };

  TreemaNode.nodeMap = {};

  TreemaNode.setNodeSubclass = function(key, NodeClass) {
    return this.nodeMap[key] = NodeClass;
  };

  TreemaNode.getNodeClassForSchema = function(schema, def, localClasses) {
    var NodeClass, type;
    if (def == null) {
      def = 'string';
    }
    if (localClasses == null) {
      localClasses = null;
    }
    NodeClass = null;
    localClasses = localClasses || {};
    if (schema.format) {
      NodeClass = localClasses[schema.format] || this.nodeMap[schema.format];
    }
    if (NodeClass) {
      return NodeClass;
    }
    type = schema.type || def;
    if ($.isArray(type)) {
      type = def;
    }
    NodeClass = localClasses[type] || this.nodeMap[type];
    if (NodeClass) {
      return NodeClass;
    }
    return this.nodeMap['any'];
  };

  TreemaNode.make = function(element, options, parent, keyForParent) {
    var NodeClass, combinedOps, d, data, localClasses, newNode, schemaTypes, type, workingSchema, workingSchemas;
    if (options.data === void 0 && (options.schema["default"] != null)) {
      d = options.schema["default"];
      options.data = $.extend(true, {}, {
        'x': d
      })['x'];
    }
    workingSchemas = [];
    workingSchema = null;
    type = null;
    if (options.schema["default"] !== void 0) {
      type = $.type(options.schema["default"]);
    }
    if (options.data != null) {
      type = $.type(options.data);
    }
    if (type === 'number' && options.data % 1) {
      type = 'integer';
    }
    if (type == null) {
      schemaTypes = options.schema.type;
      if ($.isArray(schemaTypes)) {
        schemaTypes = schemaTypes[0];
      }
      if (schemaTypes == null) {
        schemaTypes = 'string';
      }
      type = schemaTypes;
    }
    localClasses = parent ? parent.settings.nodeClasses : options.nodeClasses;
    if (parent) {
      workingSchemas = parent.buildWorkingSchemas(options.schema);
      data = options.data;
      if (data === void 0) {
        data = options.schema["default"];
      }
      workingSchema = parent.chooseWorkingSchema(workingSchemas, data);
      NodeClass = this.getNodeClassForSchema(workingSchema, type, localClasses);
    } else {
      NodeClass = this.getNodeClassForSchema(options.schema, type, localClasses);
    }
    if (options.data === void 0) {
      type = options.schema.type;
      if (type == null) {
        type = workingSchema != null ? workingSchema.type : void 0;
      }
      if (type == null) {
        type = 'string';
      }
      if ($.isArray(type)) {
        type = type[0];
      }
      options.data = {
        'string': '',
        'number': 0,
        'null': null,
        'object': {},
        'integer': 0,
        'boolean': false,
        'array': []
      }[type];
    }
    combinedOps = {};
    if (parent) {
      $.extend(combinedOps, parent.settings);
    }
    $.extend(combinedOps, options);
    newNode = new NodeClass(element, combinedOps, parent);
    if (parent != null) {
      newNode.tv4 = parent.tv4;
    }
    if (keyForParent != null) {
      newNode.keyForParent = keyForParent;
    }
    if (parent) {
      newNode.setWorkingSchema(workingSchema, workingSchemas);
    }
    return newNode;
  };

  TreemaNode.extend = function(child) {
    var ctor;
    ctor = function() {};
    ctor.prototype = this.prototype;
    child.prototype = new ctor();
    child.prototype.constructor = child;
    child.__super__ = this.prototype;
    child.prototype["super"] = function(method) {
      return this.constructor.__super__[method];
    };
    return child;
  };

  TreemaNode.didSelect = false;

  TreemaNode.changedTreemas = [];

  return TreemaNode;

})();
;var __init,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; },
  __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  __slice = [].slice;

(__init = function() {
  var AnyNode, ArrayNode, BooleanNode, IntegerNode, NullNode, NumberNode, ObjectNode, StringNode, _ref, _ref1, _ref2, _ref3, _ref4, _ref5, _ref6;
  TreemaNode.setNodeSubclass('string', StringNode = (function(_super) {
    __extends(StringNode, _super);

    function StringNode() {
      _ref = StringNode.__super__.constructor.apply(this, arguments);
      return _ref;
    }

    StringNode.prototype.valueClass = 'treema-string';

    StringNode.prototype.getDefaultValue = function() {
      return '';
    };

    StringNode.inputTypes = ['color', 'date', 'datetime', 'datetime-local', 'email', 'month', 'range', 'search', 'tel', 'text', 'time', 'url', 'week'];

    StringNode.prototype.buildValueForDisplay = function(valEl) {
      return this.buildValueForDisplaySimply(valEl, "\"" + this.data + "\"");
    };

    StringNode.prototype.buildValueForEditing = function(valEl) {
      var input, _ref1;
      input = this.buildValueForEditingSimply(valEl, this.data);
      if (this.schema.maxLength) {
        input.attr('maxlength', this.schema.maxLength);
      }
      if (_ref1 = this.schema.format, __indexOf.call(StringNode.inputTypes, _ref1) >= 0) {
        return input.attr('type', this.schema.format);
      }
    };

    StringNode.prototype.saveChanges = function(valEl) {
      return this.data = $('input', valEl).val();
    };

    return StringNode;

  })(TreemaNode));
  TreemaNode.setNodeSubclass('number', NumberNode = (function(_super) {
    __extends(NumberNode, _super);

    function NumberNode() {
      _ref1 = NumberNode.__super__.constructor.apply(this, arguments);
      return _ref1;
    }

    NumberNode.prototype.valueClass = 'treema-number';

    NumberNode.prototype.getDefaultValue = function() {
      return 0;
    };

    NumberNode.prototype.buildValueForDisplay = function(valEl) {
      return this.buildValueForDisplaySimply(valEl, JSON.stringify(this.data));
    };

    NumberNode.prototype.buildValueForEditing = function(valEl) {
      var input;
      input = this.buildValueForEditingSimply(valEl, JSON.stringify(this.data), 'number');
      if (this.schema.maximum) {
        input.attr('max', this.schema.maximum);
      }
      if (this.schema.minimum) {
        return input.attr('min', this.schema.minimum);
      }
    };

    NumberNode.prototype.saveChanges = function(valEl) {
      return this.data = parseFloat($('input', valEl).val());
    };

    return NumberNode;

  })(TreemaNode));
  TreemaNode.setNodeSubclass('integer', IntegerNode = (function(_super) {
    __extends(IntegerNode, _super);

    function IntegerNode() {
      _ref2 = IntegerNode.__super__.constructor.apply(this, arguments);
      return _ref2;
    }

    IntegerNode.prototype.valueClass = 'treema-integer';

    IntegerNode.prototype.getDefaultValue = function() {
      return 0;
    };

    IntegerNode.prototype.buildValueForDisplay = function(valEl) {
      return this.buildValueForDisplaySimply(valEl, JSON.stringify(this.data));
    };

    IntegerNode.prototype.buildValueForEditing = function(valEl) {
      var input;
      input = this.buildValueForEditingSimply(valEl, JSON.stringify(this.data), 'number');
      if (this.schema.maximum) {
        input.attr('max', this.schema.maximum);
      }
      if (this.schema.minimum) {
        return input.attr('min', this.schema.minimum);
      }
    };

    IntegerNode.prototype.saveChanges = function(valEl) {
      return this.data = parseInt($('input', valEl).val());
    };

    return IntegerNode;

  })(TreemaNode));
  TreemaNode.setNodeSubclass('null', NullNode = NullNode = (function(_super) {
    __extends(NullNode, _super);

    function NullNode() {
      _ref3 = NullNode.__super__.constructor.apply(this, arguments);
      return _ref3;
    }

    NullNode.prototype.valueClass = 'treema-null';

    NullNode.prototype.editable = false;

    NullNode.prototype.buildValueForDisplay = function(valEl) {
      return this.buildValueForDisplaySimply(valEl, 'null');
    };

    return NullNode;

  })(TreemaNode));
  TreemaNode.setNodeSubclass('boolean', BooleanNode = (function(_super) {
    __extends(BooleanNode, _super);

    function BooleanNode() {
      _ref4 = BooleanNode.__super__.constructor.apply(this, arguments);
      return _ref4;
    }

    BooleanNode.prototype.valueClass = 'treema-boolean';

    BooleanNode.prototype.getDefaultValue = function() {
      return false;
    };

    BooleanNode.prototype.buildValueForDisplay = function(valEl) {
      return this.buildValueForDisplaySimply(valEl, JSON.stringify(this.data));
    };

    BooleanNode.prototype.buildValueForEditing = function(valEl) {
      var input;
      input = this.buildValueForEditingSimply(valEl, JSON.stringify(this.data));
      $('<span></span>').text(JSON.stringify(this.data)).insertBefore(input);
      return input.focus();
    };

    BooleanNode.prototype.toggleValue = function(newValue) {
      var valEl;
      if (newValue == null) {
        newValue = null;
      }
      this.data = !this.data;
      if (newValue != null) {
        this.data = newValue;
      }
      valEl = this.getValEl().empty();
      if (this.isDisplaying()) {
        return this.buildValueForDisplay(valEl);
      } else {
        return this.buildValueForEditing(valEl);
      }
    };

    BooleanNode.prototype.onSpacePressed = function() {
      return this.toggleValue();
    };

    BooleanNode.prototype.onFPressed = function() {
      return this.toggleValue(false);
    };

    BooleanNode.prototype.onTPressed = function() {
      return this.toggleValue(true);
    };

    BooleanNode.prototype.saveChanges = function() {};

    BooleanNode.prototype.onClick = function(e) {
      var value;
      value = $(e.target).closest('.treema-value');
      if (!value.length) {
        return BooleanNode.__super__.onClick.call(this, e);
      }
      return this.toggleValue();
    };

    return BooleanNode;

  })(TreemaNode));
  TreemaNode.setNodeSubclass('array', ArrayNode = (function(_super) {
    __extends(ArrayNode, _super);

    function ArrayNode() {
      _ref5 = ArrayNode.__super__.constructor.apply(this, arguments);
      return _ref5;
    }

    ArrayNode.prototype.valueClass = 'treema-array';

    ArrayNode.prototype.getDefaultValue = function() {
      return [];
    };

    ArrayNode.prototype.collection = true;

    ArrayNode.prototype.ordered = true;

    ArrayNode.prototype.directlyEditable = false;

    ArrayNode.prototype.sort = false;

    ArrayNode.prototype.getChildren = function() {
      var key, value, _i, _len, _ref6, _results;
      _ref6 = this.data;
      _results = [];
      for (key = _i = 0, _len = _ref6.length; _i < _len; key = ++_i) {
        value = _ref6[key];
        _results.push([key, value, this.getChildSchema(key)]);
      }
      return _results;
    };

    ArrayNode.prototype.getChildSchema = function(index) {
      var schema;
      schema = this.workingSchema || this.schema;
      if (!((schema.items != null) || (schema.additionalItems != null))) {
        return {};
      }
      if ($.isPlainObject(schema.items)) {
        return this.resolveReference(schema.items, true);
      }
      if (index < schema.length) {
        return this.resolveReference(schema[index], true);
      }
      if ($.isPlainObject(schema.additionalItems)) {
        return this.resolveReference(schema.additionalItems, true);
      }
      return {};
    };

    ArrayNode.prototype.buildValueForDisplay = function(valEl) {
      var child, empty, helperTreema, index, text, val, _i, _len, _ref6;
      text = [];
      if (!this.data) {
        return;
      }
      _ref6 = this.data.slice(0, 3);
      for (index = _i = 0, _len = _ref6.length; _i < _len; index = ++_i) {
        child = _ref6[index];
        helperTreema = TreemaNode.make(null, {
          schema: this.getChildSchema(index),
          data: child
        }, this);
        val = $('<div></div>');
        helperTreema.buildValueForDisplay(val);
        text.push(val.text());
      }
      if (this.data.length > 3) {
        text.push('...');
      }
      empty = this.schema.title != null ? "(empty " + this.schema.title + ")" : '(empty)';
      text = text.length ? text.join(' | ') : empty;
      return this.buildValueForDisplaySimply(valEl, text);
    };

    ArrayNode.prototype.buildValueForEditing = function(valEl) {
      return this.buildValueForEditingSimply(valEl, JSON.stringify(this.data));
    };

    ArrayNode.prototype.canAddChild = function() {
      if (this.settings.readOnly || this.schema.readOnly) {
        return false;
      }
      if (this.schema.additionalItems === false && this.data.length >= this.schema.items.length) {
        return false;
      }
      if ((this.schema.maxItems != null) && this.data.length >= this.schema.maxItems) {
        return false;
      }
      return true;
    };

    ArrayNode.prototype.addNewChild = function() {
      var childNode, newTreema, new_index, schema;
      if (!this.canAddChild()) {
        return;
      }
      if (this.isClosed()) {
        this.open();
      }
      new_index = Object.keys(this.childrenTreemas).length;
      schema = this.getChildSchema(new_index);
      newTreema = TreemaNode.make(void 0, {
        schema: schema
      }, this, new_index);
      newTreema.justCreated = true;
      newTreema.tv4 = this.tv4;
      childNode = this.createChildNode(newTreema);
      this.getAddButtonEl().before(childNode);
      if (newTreema.canEdit()) {
        newTreema.edit();
      } else {
        newTreema.select();
        this.integrateChildTreema(newTreema);
        newTreema.flushChanges();
      }
      return newTreema;
    };

    ArrayNode.prototype.open = function() {
      var shouldShorten, valEl;
      if (this.sort) {
        this.data.sort(this.sortFunction);
      }
      ArrayNode.__super__.open.apply(this, arguments);
      shouldShorten = this.buildValueForDisplay === ArrayNode.prototype.buildValueForDisplay;
      shouldShorten = false;
      if (shouldShorten) {
        valEl = this.getValEl().empty();
        if (shouldShorten) {
          return this.buildValueForDisplaySimply(valEl, '[...]');
        }
      }
    };

    ArrayNode.prototype.close = function() {
      var valEl;
      ArrayNode.__super__.close.apply(this, arguments);
      valEl = this.getValEl().empty();
      return this.buildValueForDisplay(valEl);
    };

    ArrayNode.prototype.sortFunction = function(a, b) {
      if (a > b) {
        return 1;
      }
      if (a < b) {
        return -1;
      }
      return 0;
    };

    return ArrayNode;

  })(TreemaNode));
  window.TreemaArrayNode = ArrayNode;
  TreemaNode.setNodeSubclass('object', ObjectNode = (function(_super) {
    __extends(ObjectNode, _super);

    function ObjectNode() {
      this.cleanupAddNewChild = __bind(this.cleanupAddNewChild, this);
      _ref6 = ObjectNode.__super__.constructor.apply(this, arguments);
      return _ref6;
    }

    ObjectNode.prototype.valueClass = 'treema-object';

    ObjectNode.prototype.getDefaultValue = function() {
      var childKey, childSchema, d, _ref7, _ref8;
      d = {};
      if (!((_ref7 = this.schema) != null ? _ref7.properties : void 0)) {
        return d;
      }
      _ref8 = this.schema.properties;
      for (childKey in _ref8) {
        childSchema = _ref8[childKey];
        if (childSchema["default"]) {
          d[childKey] = childSchema["default"];
        }
      }
      return d;
    };

    ObjectNode.prototype.collection = true;

    ObjectNode.prototype.keyed = true;

    ObjectNode.prototype.directlyEditable = false;

    ObjectNode.prototype.getChildren = function() {
      var children, key, keysAccountedFor, value, _ref7;
      children = [];
      keysAccountedFor = [];
      if (this.schema.properties) {
        for (key in this.schema.properties) {
          if (typeof this.data[key] === 'undefined') {
            continue;
          }
          keysAccountedFor.push(key);
          children.push([key, this.data[key], this.getChildSchema(key)]);
        }
      }
      _ref7 = this.data;
      for (key in _ref7) {
        value = _ref7[key];
        if (__indexOf.call(keysAccountedFor, key) >= 0) {
          continue;
        }
        children.push([key, value, this.getChildSchema(key)]);
      }
      return children;
    };

    ObjectNode.prototype.getChildSchema = function(key_or_title) {
      var child_schema, key, re, schema, _ref7, _ref8;
      schema = this.workingSchema || this.schema;
      _ref7 = schema.properties;
      for (key in _ref7) {
        child_schema = _ref7[key];
        if (key === key_or_title || child_schema.title === key_or_title) {
          return this.resolveReference(child_schema, true);
        }
      }
      _ref8 = schema.patternProperties;
      for (key in _ref8) {
        child_schema = _ref8[key];
        re = new RegExp(key);
        if (key.match(re)) {
          return this.resolveReference(child_schema, true);
        }
      }
      if ($.isPlainObject(schema.additionalProperties)) {
        return this.resolveReference(schema.additionalProperties, true);
      }
      return {};
    };

    ObjectNode.prototype.buildValueForDisplay = function(valEl) {
      var displayValue, empty, i, key, name, schema, text, value, valueString, _ref7;
      text = [];
      if (!this.data) {
        return;
      }
      displayValue = this.data[this.schema.displayProperty];
      if (displayValue) {
        text = displayValue;
        return this.buildValueForDisplaySimply(valEl, text);
      }
      i = 0;
      schema = this.workingSchema || this.schema;
      _ref7 = this.data;
      for (key in _ref7) {
        value = _ref7[key];
        if (i === 3) {
          text.push('...');
          break;
        }
        i += 1;
        name = this.getChildSchema(key).title || key;
        if ($.isPlainObject(value) || $.isArray(value)) {
          text.push("" + name);
          continue;
        }
        valueString = value;
        if ($.type(value) !== 'string') {
          valueString = JSON.stringify(value);
        }
        if (valueString.length > 20) {
          valueString = valueString.slice(0, 21) + ' ...';
        }
        text.push("" + name + "=" + valueString);
      }
      empty = this.schema.title != null ? "(empty " + this.schema.title + ")" : '(empty)';
      text = text.length ? text.join(', ') : empty;
      return this.buildValueForDisplaySimply(valEl, text);
    };

    ObjectNode.prototype.buildValueForEditing = function(valEl) {
      return this.buildValueForEditingSimply(valEl, JSON.stringify(this.data));
    };

    ObjectNode.prototype.populateData = function() {
      var helperTreema, key, _i, _len, _ref7, _results;
      ObjectNode.__super__.populateData.call(this);
      if (!this.schema.required) {
        return;
      }
      _ref7 = this.schema.required;
      _results = [];
      for (_i = 0, _len = _ref7.length; _i < _len; _i++) {
        key = _ref7[_i];
        if (this.data[key] != null) {
          continue;
        }
        helperTreema = TreemaNode.make(null, {
          schema: this.getChildSchema(key)
        }, this);
        helperTreema.populateData();
        _results.push(this.data[key] = helperTreema.data);
      }
      return _results;
    };

    ObjectNode.prototype.open = function() {
      var shouldShorten, valEl;
      ObjectNode.__super__.open.apply(this, arguments);
      shouldShorten = this.buildValueForDisplay === ObjectNode.prototype.buildValueForDisplay;
      shouldShorten = false;
      if (shouldShorten) {
        valEl = this.getValEl().empty();
        if (shouldShorten) {
          return this.buildValueForDisplaySimply(valEl, '{...}');
        }
      }
    };

    ObjectNode.prototype.close = function() {
      var valEl;
      ObjectNode.__super__.close.apply(this, arguments);
      valEl = this.getValEl().empty();
      return this.buildValueForDisplay(valEl);
    };

    ObjectNode.prototype.addNewChild = function() {
      var keyInput, properties,
        _this = this;
      if (!this.canAddChild()) {
        return;
      }
      if (!this.isRoot()) {
        this.open();
      }
      this.deselectAll();
      properties = this.childPropertiesAvailable();
      keyInput = $(this.newPropertyTemplate);
      keyInput.keydown(function(e) {
        return _this.originalTargetValue = $(e.target).val();
      });
      if (typeof keyInput.autocomplete === "function") {
        keyInput.autocomplete({
          source: properties,
          minLength: 0,
          delay: 0,
          autoFocus: true
        });
      }
      this.getAddButtonEl().before(keyInput);
      keyInput.focus();
      keyInput.autocomplete('search');
      return true;
    };

    ObjectNode.prototype.canAddChild = function() {
      if (this.settings.readOnly || this.schema.readOnly) {
        return false;
      }
      if ((this.schema.maxProperties != null) && Object.keys(this.data).length >= this.schema.maxProperties) {
        return false;
      }
      if (this.schema.additionalProperties !== false) {
        return true;
      }
      if (this.schema.patternProperties != null) {
        return true;
      }
      if (this.childPropertiesAvailable().length) {
        return true;
      }
      return false;
    };

    ObjectNode.prototype.childPropertiesAvailable = function() {
      var childSchema, properties, property, schema, _ref7;
      schema = this.workingSchema || this.schema;
      if (!schema.properties) {
        return [];
      }
      properties = [];
      _ref7 = schema.properties;
      for (property in _ref7) {
        childSchema = _ref7[property];
        if (this.data[property] != null) {
          continue;
        }
        if (childSchema.format === 'hidden') {
          continue;
        }
        if (childSchema.readOnly) {
          continue;
        }
        properties.push(childSchema.title || property);
      }
      return properties.sort();
    };

    ObjectNode.prototype.onDeletePressed = function(e) {
      if (!this.addingNewProperty()) {
        return ObjectNode.__super__.onDeletePressed.call(this, e);
      }
      if (!$(e.target).val()) {
        this.cleanupAddNewChild();
        e.preventDefault();
        return this.$el.find('.treema-add-child').focus();
      }
    };

    ObjectNode.prototype.onEscapePressed = function() {
      return this.cleanupAddNewChild();
    };

    ObjectNode.prototype.onTabPressed = function(e) {
      if (!this.addingNewProperty()) {
        return ObjectNode.__super__.onTabPressed.call(this, e);
      }
      e.preventDefault();
      return this.tryToAddNewChild(e, false);
    };

    ObjectNode.prototype.onEnterPressed = function(e) {
      if (!this.addingNewProperty()) {
        return ObjectNode.__super__.onEnterPressed.call(this, e);
      }
      return this.tryToAddNewChild(e, true);
    };

    ObjectNode.prototype.tryToAddNewChild = function(e, aggressive) {
      var key, keyInput, offset, treema;
      if ((!this.originalTargetValue) && (!aggressive)) {
        offset = e.shiftKey ? -1 : 1;
        this.cleanupAddNewChild();
        this.$el.find('.treema-add-child').focus();
        this.traverseWhileEditing(offset);
        return;
      }
      keyInput = $(e.target);
      key = this.getPropertyKey($(e.target));
      if (key.length && !this.canAddProperty(key)) {
        this.clearTemporaryErrors();
        this.showBadPropertyError(keyInput);
        return;
      }
      if (this.childrenTreemas[key] != null) {
        this.cleanupAddNewChild();
        treema = this.childrenTreemas[key];
        if (treema.canEdit()) {
          return treema.toggleEdit();
        } else {
          return treema.select();
        }
      }
      this.cleanupAddNewChild();
      return this.addNewChildForKey(key);
    };

    ObjectNode.prototype.getPropertyKey = function(keyInput) {
      var child_key, child_schema, key, _ref7;
      key = keyInput.val();
      if (this.schema.properties) {
        _ref7 = this.schema.properties;
        for (child_key in _ref7) {
          child_schema = _ref7[child_key];
          if (child_schema.title === key) {
            key = child_key;
          }
        }
      }
      return key;
    };

    ObjectNode.prototype.canAddProperty = function(key) {
      var pattern;
      if (this.schema.additionalProperties !== false) {
        return true;
      }
      if (this.schema.properties[key] != null) {
        return true;
      }
      if (this.schema.patternProperties != null) {
        if ((function() {
          var _results;
          _results = [];
          for (pattern in this.schema.patternProperties) {
            _results.push(RegExp(pattern).test(key));
          }
          return _results;
        }).call(this)) {
          return true;
        }
      }
      return false;
    };

    ObjectNode.prototype.showBadPropertyError = function(keyInput) {
      var tempError;
      keyInput.focus();
      tempError = this.createTemporaryError('Invalid property name.');
      tempError.insertAfter(keyInput);
    };

    ObjectNode.prototype.addNewChildForKey = function(key) {
      var child, childNode, children, newTreema, schema;
      schema = this.getChildSchema(key);
      newTreema = TreemaNode.make(null, {
        schema: schema
      }, this, key);
      childNode = this.createChildNode(newTreema);
      this.findObjectInsertionPoint(key).before(childNode);
      if (newTreema.canEdit()) {
        newTreema.edit();
      } else {
        this.integrateChildTreema(newTreema);
        children = newTreema.getChildren();
        if (children.length) {
          newTreema.open();
          child = newTreema.childrenTreemas[children[0][0]];
          child.select();
        } else {
          newTreema.addNewChild();
        }
      }
      return this.updateMyAddButton();
    };

    ObjectNode.prototype.findObjectInsertionPoint = function(key) {
      var afterKeys, allChildren, allProps, child, _i, _len, _ref7, _ref8;
      if (!((_ref7 = this.schema.properties) != null ? _ref7[key] : void 0)) {
        return this.getAddButtonEl();
      }
      allProps = Object.keys(this.schema.properties);
      afterKeys = allProps.slice(allProps.indexOf(key) + 1);
      allChildren = this.$el.find('> .treema-children > .treema-node');
      for (_i = 0, _len = allChildren.length; _i < _len; _i++) {
        child = allChildren[_i];
        if (_ref8 = $(child).data('instance').keyForParent, __indexOf.call(afterKeys, _ref8) >= 0) {
          return $(child);
        }
      }
      return this.getAddButtonEl();
    };

    ObjectNode.prototype.cleanupAddNewChild = function() {
      this.$el.find('.treema-new-prop').remove();
      return this.clearTemporaryErrors();
    };

    ObjectNode.prototype.addingNewProperty = function() {
      return document.activeElement === this.$el.find('.treema-new-prop')[0];
    };

    return ObjectNode;

  })(TreemaNode));
  window.TreemaObjectNode = ObjectNode;
  return TreemaNode.setNodeSubclass('any', AnyNode = (function(_super) {
    __extends(AnyNode, _super);

    AnyNode.prototype.helper = null;

    function AnyNode() {
      var splat;
      splat = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      AnyNode.__super__.constructor.apply(this, splat);
      this.updateShadowMethods();
    }

    AnyNode.prototype.buildValueForEditing = function(valEl) {
      return this.buildValueForEditingSimply(valEl, JSON.stringify(this.data));
    };

    AnyNode.prototype.saveChanges = function(valEl) {
      var e;
      this.data = $('input', valEl).val();
      if (this.data[0] === "'" && this.data[this.data.length - 1] !== "'") {
        this.data = this.data.slice(1);
      } else if (this.data[0] === '"' && this.data[this.data.length - 1] !== '"') {
        this.data = this.data.slice(1);
      } else if (this.data.trim() === '[') {
        this.data = [];
      } else if (this.data.trim() === '{') {
        this.data = {};
      } else {
        try {
          this.data = JSON.parse(this.data);
        } catch (_error) {
          e = _error;
          console.log('could not parse data', this.data);
        }
      }
      this.updateShadowMethods();
      return this.rebuild();
    };

    AnyNode.prototype.updateShadowMethods = function() {
      var NodeClass, prop, _i, _len, _ref7, _results;
      NodeClass = TreemaNode.getNodeClassForSchema({
        type: $.type(this.data)
      });
      this.helper = new NodeClass(this.schema, {
        data: this.data,
        options: this.options
      }, this.parent);
      this.helper.tv4 = this.tv4;
      _ref7 = ['collection', 'ordered', 'keyed', 'getChildSchema', 'getChildren', 'getChildSchema', 'buildValueForDisplay', 'addNewChild', 'childPropertiesAvailable'];
      _results = [];
      for (_i = 0, _len = _ref7.length; _i < _len; _i++) {
        prop = _ref7[_i];
        _results.push(this[prop] = this.helper[prop]);
      }
      return _results;
    };

    AnyNode.prototype.rebuild = function() {
      var newNode, oldEl;
      oldEl = this.$el;
      if (this.parent) {
        newNode = this.parent.createChildNode(this);
      } else {
        newNode = this.build();
      }
      return this.$el = newNode;
    };

    AnyNode.prototype.onClick = function(e) {
      var clickedValue, usedModKey, _ref7;
      if ((_ref7 = e.target.nodeName) === 'INPUT' || _ref7 === 'TEXTAREA') {
        return;
      }
      clickedValue = $(e.target).closest('.treema-value').length;
      usedModKey = e.shiftKey || e.ctrlKey || e.metaKey;
      if (clickedValue && !usedModKey) {
        return this.toggleEdit();
      }
      return AnyNode.__super__.onClick.call(this, e);
    };

    return AnyNode;

  })(TreemaNode));
})();
;var __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  __slice = [].slice;

(function() {
  var AceNode, DatabaseSearchTreemaNode, LongStringNode, Point2DNode, Point3DNode, debounce, _ref, _ref1, _ref2, _ref3, _ref4;
  TreemaNode.setNodeSubclass('point2d', Point2DNode = (function(_super) {
    __extends(Point2DNode, _super);

    function Point2DNode() {
      _ref = Point2DNode.__super__.constructor.apply(this, arguments);
      return _ref;
    }

    Point2DNode.prototype.valueClass = 'treema-point2d';

    Point2DNode.prototype.getDefaultValue = function() {
      return {
        x: 0,
        y: 0
      };
    };

    Point2DNode.prototype.buildValueForDisplay = function(valEl) {
      return this.buildValueForDisplaySimply(valEl, "(" + this.data.x + ", " + this.data.y + ")");
    };

    Point2DNode.prototype.buildValueForEditing = function(valEl) {
      var xInput, yInput;
      xInput = $('<input />').val(this.data.x).attr('placeholder', 'x');
      yInput = $('<input />').val(this.data.y).attr('placeholder', 'y');
      valEl.append('(').append(xInput).append(', ').append(yInput).append(')');
      return valEl.find('input:first').focus().select();
    };

    Point2DNode.prototype.saveChanges = function(valEl) {
      this.data.x = parseFloat(valEl.find('input:first').val());
      return this.data.y = parseFloat(valEl.find('input:last').val());
    };

    return Point2DNode;

  })(TreemaNode));
  TreemaNode.setNodeSubclass('point3d', Point3DNode = (function(_super) {
    __extends(Point3DNode, _super);

    function Point3DNode() {
      _ref1 = Point3DNode.__super__.constructor.apply(this, arguments);
      return _ref1;
    }

    Point3DNode.prototype.valueClass = 'treema-point3d';

    Point3DNode.prototype.getDefaultValue = function() {
      return {
        x: 0,
        y: 0,
        z: 0
      };
    };

    Point3DNode.prototype.buildValueForDisplay = function(valEl) {
      return this.buildValueForDisplaySimply(valEl, "(" + this.data.x + ", " + this.data.y + ", " + this.data.z + ")");
    };

    Point3DNode.prototype.buildValueForEditing = function(valEl) {
      var xInput, yInput, zInput;
      xInput = $('<input />').val(this.data.x).attr('placeholder', 'x');
      yInput = $('<input />').val(this.data.y).attr('placeholder', 'y');
      zInput = $('<input />').val(this.data.z).attr('placeholder', 'z');
      valEl.append('(').append(xInput).append(', ').append(yInput).append(', ').append(zInput).append(')');
      return valEl.find('input:first').focus().select();
    };

    Point3DNode.prototype.saveChanges = function() {
      var inputs;
      inputs = this.getInputs();
      this.data.x = parseFloat($(inputs[0]).val());
      this.data.y = parseFloat($(inputs[1]).val());
      return this.data.z = parseFloat($(inputs[2]).val());
    };

    return Point3DNode;

  })(TreemaNode));
  DatabaseSearchTreemaNode = (function(_super) {
    __extends(DatabaseSearchTreemaNode, _super);

    function DatabaseSearchTreemaNode() {
      this.searchCallback = __bind(this.searchCallback, this);
      this.search = __bind(this.search, this);
      _ref2 = DatabaseSearchTreemaNode.__super__.constructor.apply(this, arguments);
      return _ref2;
    }

    DatabaseSearchTreemaNode.prototype.valueClass = 'treema-search';

    DatabaseSearchTreemaNode.prototype.searchValueTemplate = '<input placeholder="Search" /><div class="treema-search-results"></div>';

    DatabaseSearchTreemaNode.prototype.url = null;

    DatabaseSearchTreemaNode.prototype.lastTerm = null;

    DatabaseSearchTreemaNode.prototype.buildValueForDisplay = function(valEl) {
      var val;
      val = this.data ? this.formatDocument(this.data) : 'None';
      return this.buildValueForDisplaySimply(valEl, val);
    };

    DatabaseSearchTreemaNode.prototype.formatDocument = function(doc) {
      if ($.isString(doc)) {
        return doc;
      }
      return JSON.stringify(doc);
    };

    DatabaseSearchTreemaNode.prototype.buildValueForEditing = function(valEl) {
      var input;
      valEl.html(this.searchValueTemplate);
      input = valEl.find('input');
      input.focus().keyup(this.search);
      if (this.data) {
        return input.attr('placeholder', this.formatDocument(this.data));
      }
    };

    DatabaseSearchTreemaNode.prototype.search = function() {
      var term;
      term = this.getValEl().find('input').val();
      if (term === this.lastTerm) {
        return;
      }
      if (this.lastTerm && !term) {
        this.getSearchResultsEl().empty();
      }
      if (!term) {
        return;
      }
      this.lastTerm = term;
      this.getSearchResultsEl().empty().append('Searching');
      return $.ajax(this.url + '?term=' + term, {
        dataType: 'json',
        success: this.searchCallback
      });
    };

    DatabaseSearchTreemaNode.prototype.searchCallback = function(results) {
      var container, first, i, result, row, text, _i, _len;
      container = this.getSearchResultsEl().detach().empty();
      first = true;
      for (i = _i = 0, _len = results.length; _i < _len; i = ++_i) {
        result = results[i];
        row = $('<div></div>').addClass('treema-search-result-row');
        text = this.formatDocument(result);
        if (text == null) {
          continue;
        }
        if (first) {
          row.addClass('treema-search-selected');
        }
        first = false;
        row.text(text);
        row.data('value', result);
        container.append(row);
      }
      if (!results.length) {
        container.append($('<div>No results</div>'));
      }
      return this.getValEl().append(container);
    };

    DatabaseSearchTreemaNode.prototype.getSearchResultsEl = function() {
      return this.getValEl().find('.treema-search-results');
    };

    DatabaseSearchTreemaNode.prototype.getSelectedResultEl = function() {
      return this.getValEl().find('.treema-search-selected');
    };

    DatabaseSearchTreemaNode.prototype.saveChanges = function() {
      var selected;
      selected = this.getSelectedResultEl();
      if (!selected.length) {
        return;
      }
      return this.data = selected.data('value');
    };

    DatabaseSearchTreemaNode.prototype.onDownArrowPressed = function(e) {
      this.navigateSearch(1);
      return e.preventDefault();
    };

    DatabaseSearchTreemaNode.prototype.onUpArrowPressed = function(e) {
      e.preventDefault();
      return this.navigateSearch(-1);
    };

    DatabaseSearchTreemaNode.prototype.navigateSearch = function(offset) {
      var func, next, selected;
      selected = this.getSelectedResultEl();
      func = offset > 0 ? 'next' : 'prev';
      next = selected[func]('.treema-search-result-row');
      if (!next.length) {
        return;
      }
      selected.removeClass('treema-search-selected');
      return next.addClass('treema-search-selected');
    };

    DatabaseSearchTreemaNode.prototype.onClick = function(e) {
      var newSelection;
      newSelection = $(e.target).closest('.treema-search-result-row');
      if (!newSelection.length) {
        return DatabaseSearchTreemaNode.__super__.onClick.call(this, e);
      }
      this.getSelectedResultEl().removeClass('treema-search-selected');
      newSelection.addClass('treema-search-selected');
      this.saveChanges();
      return this.display();
    };

    DatabaseSearchTreemaNode.prototype.shouldTryToRemoveFromParent = function() {
      var selected;
      if (this.data != null) {
        return;
      }
      selected = this.getSelectedResultEl();
      return !selected.length;
    };

    return DatabaseSearchTreemaNode;

  })(TreemaNode);
  debounce = function(func, threshold, execAsap) {
    var timeout;
    timeout = null;
    return function() {
      var args, delayed, obj;
      args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      obj = this;
      delayed = function() {
        if (!execAsap) {
          func.apply(obj, args);
        }
        return timeout = null;
      };
      if (timeout) {
        clearTimeout(timeout);
      } else if (execAsap) {
        func.apply(obj, args);
      }
      return timeout = setTimeout(delayed, threshold || 100);
    };
  };
  DatabaseSearchTreemaNode.prototype.search = debounce(DatabaseSearchTreemaNode.prototype.search, 200);
  window.DatabaseSearchTreemaNode = DatabaseSearchTreemaNode;
  TreemaNode.setNodeSubclass('ace', AceNode = (function(_super) {
    __extends(AceNode, _super);

    function AceNode() {
      _ref3 = AceNode.__super__.constructor.apply(this, arguments);
      return _ref3;
    }

    AceNode.prototype.valueClass = 'treema-ace treema-multiline';

    AceNode.prototype.getDefaultValue = function() {
      return '';
    };

    AceNode.prototype.buildValueForDisplay = function(valEl) {
      var pre, _ref4;
      if ((_ref4 = this.editor) != null) {
        _ref4.destroy();
      }
      pre = $('<pre></pre>').text(this.data);
      return valEl.append(pre);
    };

    AceNode.prototype.buildValueForEditing = function(valEl) {
      var d;
      d = $('<div></div>').text(this.data);
      valEl.append(d);
      this.editor = ace.edit(d[0]);
      this.editor.setReadOnly(false);
      if (this.schema.aceMode != null) {
        this.editor.getSession().setMode(this.schema.aceMode);
      }
      if (this.schema.aceTabSize != null) {
        this.editor.getSession().setTabSize(this.schema.aceTabSize);
      }
      if (this.schema.aceTheme != null) {
        this.editor.setTheme(this.schema.aceTheme);
      }
      return valEl.find('textarea').focus();
    };

    AceNode.prototype.saveChanges = function() {
      return this.data = this.editor.getValue();
    };

    AceNode.prototype.onTabPressed = function() {};

    AceNode.prototype.onEnterPressed = function() {};

    return AceNode;

  })(TreemaNode));
  return TreemaNode.setNodeSubclass('long-string', LongStringNode = (function(_super) {
    __extends(LongStringNode, _super);

    function LongStringNode() {
      _ref4 = LongStringNode.__super__.constructor.apply(this, arguments);
      return _ref4;
    }

    LongStringNode.prototype.valueClass = 'treema-long-string treema-multiline';

    LongStringNode.prototype.getDefaultValue = function() {
      return '';
    };

    LongStringNode.prototype.buildValueForDisplay = function(valEl) {
      var text;
      text = this.data;
      text = text.replace(/\n/g, '<br />');
      return valEl.append($("<div></div>").html(text));
    };

    LongStringNode.prototype.buildValueForEditing = function(valEl) {
      var input;
      input = $('<textarea />');
      if (this.data !== null) {
        input.val(this.data);
      }
      valEl.append(input);
      input.focus().select();
      input.blur(this.onEditInputBlur);
      return input;
    };

    LongStringNode.prototype.saveChanges = function(valEl) {
      var input;
      input = valEl.find('textarea');
      return this.data = input.val();
    };

    return LongStringNode;

  })(TreemaNode));
})();
;(function($) {
  return $.fn[TreemaNode.pluginName] = function(options) {
    var element;
    if (this.length === 0) {
      return null;
    }
    element = $(this[0]);
    return TreemaNode.make(element, options);
  };
})(jQuery);
;
//@ sourceMappingURL=treema.js.map