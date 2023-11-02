/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
const Aether = require('../aether');

describe("Problem Test Suite", () => describe("Transpile problems", () => it("pass through python syntax info", function() {
  const code = `\
self.attack('Brak)\
`;
  const aether = new Aether({language: 'python'});
  aether.transpile(code);
  console.log(aether.problems.errors[0]);
  expect(aether.problems.errors.length).toEqual(1);
  return expect(aether.problems.errors[0].extra.kind).toBe("CLASSIFY");
})));
