// dump me into the console of a codecombat page or the dev server
// and I will migrate various playing data from firebase to mongodb.

var d = {};
d.sessionsToDo = [];
LevelSession = require('models/LevelSession');
d.codeLoading = {};
d.tasks = 0;

function go() {
  if(d.sessionsToDo.length) {
    doOne();
  }
  else {
    fetchMore();
  }
}

function doOne() {
  var session = d.sessionsToDo.pop();
  var host = 'https://codecombat.firebaseio.com/play/level/';
  host += session.levelID + '/' + session._id;
//  console.log('DOING:', session.levelID + '/' + session._id);
  var fireRef = new Firebase(host);
  fireRef.once('value', function(snapshot) {
    window.snapshot = snapshot;
    d.patch = {};
    patchIt(session._id, snapshot);
  });
}

function patchIt(sessionID, snapshot) {
  var val = snapshot.val();
  if(!val) {
    console.log('miss');
    task = {
      ref: snapshot.ref(),
      sessionID: sessionID,
      patch: { code: { 0:0 }}
    }
    d.missed = true;
    return finishTask(task);
  }
  window.val = val;
  d.patch = {};
  if(val.chat) {
    d.patch.chat = [];
    for(var i in val.chat) { d.patch.chat.push(val.chat[i]); }
    delete val.chat;
  }
  if(val.players) {
    d.patch.players = val.players;
    delete val.players;
  }
  if(val.scripts) {
    delete val.scripts;
  }
  for(var thangName in val) {
    var thang = val[thangName];
    for(var spellName in thang) {
//      console.log('Load code from', snapshot.ref().toString(), 'for', thangName, spellName);
      var aceEl = $('<div></div>');
      $('body').append(aceEl);
      var aceEditor = ace.edit(aceEl[0]);
      firepad = Firepad.fromACE(snapshot.ref().child(thangName+'/'+spellName), aceEditor);
      var task = {
        aceEl: aceEl,
        aceEditor: aceEditor,
        spellName: spellName,
        thangName: thangName,
        firepad: firepad,
        patch: d.patch,
        sessionID: sessionID,
        ref: snapshot.ref()
      };
      d.tasks += 1;
      firepad.on('ready', (function(task) { return function() { codeLoaded(task); } })(task));
    }
  }
//  console.log('Made', d.tasks, 'tasks');
  if (!d.tasks) {
    task = {
      patch: d.patch,
      sessionID: sessionID,
      ref: snapshot.ref()
    };
    finishTask(task);
  }
//  d.patch.code = val;
}

function codeLoaded(task) {
//  console.log('------------------\nLoaded code:\n', task.aceEditor.getValue());
  if(!task.patch.code) task.patch.code = {};
  if(!task.patch.code[task.thangName]) task.patch.code[task.thangName] = {};
  task.patch.code[task.thangName][task.spellName] = task.aceEditor.getValue();
  
  // cleanup this task
  task.aceEditor.destroy();
  task.firepad.dispose();
  task.aceEl.remove();
  
  d.tasks -= 1;
  if(d.tasks === 0) {
    finishTask(task);
//    console.log('We got it all', task.patch);
  }
}

function finishTask(task) {
  var session = new LevelSession({_id:task.sessionID});
  window.session = session;
  
  task.ref.remove();
  session.save(task.patch, {patch:true});
//  session.once('sync', function() { console.log('saved'); } );
  session.once('sync', function() { setTimeout(go, 1); } )
}


function fetchMore() {
  console.log('\n\nFETCHING MORE TO DO');
  $.ajax({
    url:'/admin/sessions_to_do?level=munchkin-masher',
    success: function(res) {
      d.sessionsToDo = res;
      setTimeout(go, 1);
    }
  });
}

go();
