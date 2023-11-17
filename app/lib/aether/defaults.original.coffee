execution = require './execution'

module.exports = defaults =
  thisValue: null  # TODO: don't use this. Aether doesn't use it at compile time and CodeCombat uses it just at runtime, and it makes cloning original options weird/unintuitive/slow.
  globals: []
  language: "javascript"
  functionName: null  # In case we need it for error messages
  functionParameters: []  # Or something like ["target"]
  yieldAutomatically: false  # Horrible name... we could have it auto-insert yields after every statement
  yieldConditionally: false  # Also bad name, but what it would do is make it yield whenever this._aetherShouldYield is true (and clear it)
  executionCosts: {}  # execution  # We don't use this yet
  noSerializationInFlow: false
  noVariablesInFlow: false
  skipDuplicateUserInfoInFlow: false
  includeFlow: true
  includeMetrics: true
  includeStyle: true
  protectBuiltins: true
  protectAPI: false
  debug: false
