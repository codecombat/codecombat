require('bower_components/ace-builds/src-noconflict/ace.js');

module.exports = window.ace
# delete window.ace # We can't do this because ace needs itself to be in window to do ace.require
