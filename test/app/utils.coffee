# TODO: Pull this (and the copy for server tests) out into a separate library
co = require 'co'

wrapJasmine = (gen) ->
  arity = gen.length
  fn = co.wrap(gen)
  return (done) ->
    # Run the wrapped, Promise returning test function
    fn.apply(@, if arity is 0 then [] else [done])

    # Finish the test if it doesn't include a 'done' argument
    .then -> done() if arity is 0

    # Fail on runtime error
    .catch (err) -> done.fail(err)

module.exports = {
  wrapJasmine
}
