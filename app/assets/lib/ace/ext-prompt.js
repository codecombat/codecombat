/* ***** BEGIN LICENSE BLOCK *****
 * Distributed under the BSD license:
 *
 * Copyright (c) 2010, Ajax.org B.V.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above copyright
 *       notice, this list of conditions and the following disclaimer in the
 *       documentation and/or other materials provided with the distribution.
 *     * Neither the name of Ajax.org B.V. nor the
 *       names of its contributors may be used to endorse or promote products
 *       derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL AJAX.ORG B.V. BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * ***** END LICENSE BLOCK ***** */

ace.define('ace/ext/prompt', ['require', 'exports', 'module' , 'ace/lib/lang', 'ace/lib/dom', 'ace/lib/event', 'ace/edit_session', 'ace/undomanager', 'ace/virtual_renderer', 'ace/editor', 'ace/multi_select'], function(require, exports, module) {


var lang = require("../lib/lang");
var dom = require("ace/lib/dom");
var event = require("ace/lib/event");

var EditSession = require("ace/edit_session").EditSession;
var UndoManager = require("ace/undomanager").UndoManager;
var Renderer = require("ace/virtual_renderer").VirtualRenderer;
var Editor = require("ace/editor").Editor;
var MultiSelect = require("ace/multi_select").MultiSelect;
function screenToTextCoordinates(x, y) {
    var pos = this.pixelToScreenCoordinates(x, y);
    return this.session.screenToDocumentPosition(
        Math.min(this.session.getScreenLength() - 1, Math.max(pos.row, 0)),
        Math.max(pos.column, 0)
    );
}

exports.singleLineEditor = function(el) {
    var renderer = new Renderer();
    renderer.container.style.overflow = "hidden";
    renderer.screenToTextCoordinates = screenToTextCoordinates;
    renderer.setStyle("ace_one-line");
    var editor = new Editor(renderer);
    editor.session.setUndoManager(new UndoManager());
    editor.setOptions({
        showPrintMargin: false,
        showGutter: false,
        highlightGutterLine: false,
        focusWaitTimout: 0,
        maxLines: 4
    });
    return editor;
};

});
;
                (function() {
                    ace.require(["ace/ext/prompt"], function() {});
                })();
            