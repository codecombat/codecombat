/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
// TODO: Pull this (and the copy for server tests) out into a separate library
const co = require('co');

const wrapJasmine = function(gen) {
  const arity = gen.length;
  const fn = co.wrap(gen);
  return function(done) {
    // Run the wrapped, Promise returning test function
    return fn.apply(this, arity === 0 ? [] : [done])

    // Finish the test if it doesn't include a 'done' argument
    .then(function() { if (arity === 0) { return done(); } })

    // Fail on runtime error
    .catch(err => done.fail(err));
  };
};

module.exports = {
  wrapJasmine
};
