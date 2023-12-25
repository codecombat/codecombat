/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS205: Consider reworking code to avoid use of IIFEs
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
const Aether = require('../aether');

/*
TODO: Fix tests in the describe below.
*/
xdescribe("Global Scope Exploit Suite", function() {
  // This one should now be handled by strict mode, so this is undefined
  it('should intercept "this"', function() {
    const code = "G=100;var globals=(function(){return this;})();return globals.G;";
    const aether = new Aether();
    aether.transpile(code);
    aether.run();
    expect(aether.problems.errors.length).toEqual(1);
    return expect(aether.problems.errors[0].message).toMatch(/ReferenceError: G is not defined/);
  });

  xit('should disallow using eval', function() {
    const code = "eval('var x = 2; ++x;');";
    const aether = new Aether();
    aether.transpile(code);
    const func = aether.createFunction();
    return expect(func).toThrow();
  });

  it('should disallow using eval without identifier', function() {
    const code = "0['ev'+'al']('var x = 2; ++x;');";
    const aether = new Aether();
    aether.transpile(code);
    const func = aether.createFunction();
    return expect(func).toThrow();
  });

  xit('should disallow using Function', function() {
    const code = "Function('')";
    const aether = new Aether();
    aether.transpile(code);
    const func = aether.createFunction();
    return expect(func).toThrow();
  });

  it('should disallow Function.__proto__.constructor', function() {
    const code = "(function(){}).__proto__.constructor('')";
    const aether = new Aether();
    aether.transpile(code);
    const func = aether.createFunction();
    return expect(func).toThrow();
  });

  it('should protect builtins', function() {
    const code = "(function(){}).__proto__.constructor = 100;";
    const aether = new Aether();
    aether.transpile(code);
    aether.run();
    return expect((function() {}).__proto__.constructor).not.toEqual(100);
  });

  it('should sandbox nested aether functions', function() {
    const c1 = "arguments[0]();";
    const c2 = "(function(){}).__proto__.constructor('');";

    const aether = new Aether();
    aether.transpile(c1);
    const f1 = aether.createFunction();

    aether.transpile(c2);
    const f2 = aether.createFunction();

    return expect(() => f1(f2)).toThrow();
  });

  it('shouldn\'t remove sandbox in nested aether functions', function() {
    const c1 = "arguments[0]();(function(){}).__proto__.constructor('');";
    const c2 = "";

    const aether = new Aether();
    aether.transpile(c1);
    const f1 = aether.createFunction();

    aether.transpile(c2);
    const f2 = aether.createFunction();

    return expect(() => f1(f2)).toThrow();
  });

  it('should sandbox generators', function() {
    const code = "(function(){}).__proto__.constructor();";
    const aether = new Aether({
      yieldAutomatically: true});

    aether.transpile(code);
    const func = aether.sandboxGenerator(aether.createFunction()());

    try {
      return (() => {
        const result = [];
        while (true) {
          result.push(func.next());
        }
        return result;
      })();
    } catch (e) {
      // If we change the error message or whatever make sure we change it here too
      return expect(e.message).toEqual('[Sandbox] Function::constructor is disabled. If you are a developer, please make sure you have a reference to your builtins.');
    }
  });

  it('should not break on invalid code', function() {
    const code = `\
var friend = {health: 10};
if (friend.health < 5) {
    this.castRegen(friend);
    this.say("Healing " + friend.id + ".");
}
if (this.health < 50) {\
`;
    const aether = new Aether();
    aether.transpile(code);
    const fn = aether.createFunction();
    return fn();
  });

  it('should protect builtin prototypes', function() {
    const codeOne = `\
Array.prototype.diff = function(a) {
  return this.filter(function(i) { return a.indexOf(i) < 0; });
};
var sweet = ["frogs", "toads"];
var salty = ["toads"];
return sweet.diff(salty);\
`;
    const codeTwo = `\
var a = ["just", "three", "properties"];
var x = 0;
for (var key in a)
  ++x;
return x;\
`;
    let aether = new Aether();
    aether.transpile(codeOne);
    let fn = aether.createFunction();
    let ret = fn();
    expect(ret.length).toEqual(1);

    aether = new Aether();
    aether.transpile(codeTwo);
    fn = aether.createFunction();
    ret = fn();
    expect(ret).toEqual(3);
    expect(Array.prototype.diff).toBeUndefined();
    return delete Array.prototype.diff;
  });  // Needed, or test never returns.

  it('should disallow callee hacking', function() {
    const safe = ["secret"];
    const music = [];
    const inner = {addMusic(song) { return music.push(song); }};
    const outer = {entertain() { return inner.sing(); }};
    outer.entertain.burninate = () => safe.pop();
    const code = `\
this.addMusic("trololo");
var caller = arguments.callee.caller;
this.addMusic("trololo")
var callerDepth = 0;
while (caller.caller && callerDepth++ < 10) {
  this.addMusic(''+caller);
  caller = caller.caller;
  if (caller.burninate)
    caller.burninate();
}
this.addMusic("trololo");\
`;
    const aether = new Aether({functionName: 'sing'});
    aether.transpile(code);
    inner.sing = aether.createMethod(inner);
    expect(() => outer.entertain()).toThrow();
    expect(safe.length).toEqual(1);
    expect(music.length).toEqual(1);
    return expect(music[0]).toEqual('trololo');
  });

  return xit('should disallow prepareStackTrace hacking', function() {
    // https://github.com/codecombat/aether/issues/81
    const code = `\
var getStackframes = function () {
  var capture;
  Error.prepareStackTrace = function(e, t) {
    return t;
  };
  try {
    capture.error();
  } catch (e) {
    capture = e.stack;
  }
  return capture;
};

var boop = [];
getStackframes().forEach(function(x) {
  if(x.getFunctionName() != 'module.exports.Aether.run')
    return;
  boop.push(x.getFunctionName());
  boop.push(x.getFunction());
});

return boop;\
`;
    const aether = new Aether;
    aether.transpile(code);
    const ret = aether.run();
    expect(ret).toEqual(null);
    return expect(aether.problems.errors).not.toEqual([]);
});
});
