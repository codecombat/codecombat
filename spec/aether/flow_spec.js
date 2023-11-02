/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
const Aether = require('../aether');

describe("Flow test suite", () => describe("Basic flow", function() {
  const code = `\
var four = 2 * 2;  // three: 2, 2, four = 2 * 2
this.say(four);  // one\
`;
  const nStatements = 4;  // If we improved our statement detection, this might go up
  it("should count statements and track vars", function() {
    const thisValue = {say() {}};
    const options = {
      includeFlow: true,
      includeMetrics: true
    };
    const aether = new Aether(options);
    aether.transpile(code);
    const fn = aether.createMethod(thisValue);
    for (let i = 0; i < 4; i++) {
      if (i) {
        expect(aether.flow.states.length).toEqual(i);
        expect(aether.flow.states[i - 1].statementsExecuted).toEqual(nStatements);
        expect(aether.metrics.callsExecuted).toEqual(i);
        expect(aether.metrics.statementsExecuted).toEqual(i * nStatements);
      }
      fn();
    }
    const last = aether.flow.states[3].statements;
    expect(last[0].variables.four).not.toEqual("4");
    return expect(last[last.length - 1].variables.four).toEqual("4");
  });  // could change if we serialize differently

  it("should obey includeFlow", function() {
    const thisValue = {say() {}};
    const options = {
      includeFlow: false,
      includeMetrics: true
    };
    const aether = new Aether(options);
    aether.transpile(code);
    const fn = aether.createMethod(thisValue);
    fn();
    expect(aether.flow.states).toBe(undefined);
    expect(aether.metrics.callsExecuted).toEqual(1);
    return expect(aether.metrics.statementsExecuted).toEqual(nStatements);
  });

  it("should obey includeMetrics", function() {
    const thisValue = {say() {}};
    const options = {
      includeFlow: true,
      includeMetrics: false
    };
    const aether = new Aether(options);
    aether.transpile(code);
    const fn = aether.createMethod(thisValue);
    fn();
    expect(aether.flow.states.length).toEqual(1);
    expect(aether.flow.states[0].statementsExecuted).toEqual(nStatements);
    expect(aether.metrics.callsExecuted).toBe(undefined);
    return expect(aether.metrics.statementsExecuted).toBe(undefined);
  });

  return it("should not log statements when not needed", function() {
    const thisValue = {say() {}};
    const options = {
      includeFlow: false,
      includeMetrics: false
    };
    const aether = new Aether(options);
    const pure = aether.transpile(code);
    expect(pure.search(/log(Statement|Call)/)).toEqual(-1);
    expect(pure.search(/_aetherUserInfo/)).toEqual(-1);
    return expect(pure.search(/_aether\.vars/)).toEqual(-1);
  });
}));
