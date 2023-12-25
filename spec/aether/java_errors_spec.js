/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
const Aether = require('../aether');
const lodash = require('lodash');

const language = 'java';
let aether = new Aether({language});

const checkRange = function(problem, code, start) {
  if (start) {
    expect(problem.range[0].row).toEqual(start.row);
    return expect(problem.range[0].col).toEqual(start.col);
  }
};

xdescribe(`${language} Errors Test suite`, () => describe("Syntax Errors", function() {
  it("no class", function() {
    const code = `\
hero.moveLeft()\
`;
    aether = new Aether({language});
    aether.transpile(code);
    expect(aether.problems.errors.length).toEqual(1);
    expect(aether.problems.errors[0].message).toEqual('class, interface, or enum expected');
    return checkRange(aether.problems.errors[0], code, {row: 0, col: 0});
  });

  it("not a statement", function() {
    const code = `\
public class Main {
public static void main(String[] args) {
  2+2;
}
}\
`;
    aether = new Aether({language});
    aether.transpile(code);
    expect(aether.problems.errors.length).toEqual(1);
    expect(aether.problems.errors[0].message).toEqual('not a statement');
    return checkRange(aether.problems.errors[0], code, {row: 3, col: 4});
  });


  it("no semicolon", function() {
    const code = `\
public class Main {
public static void main(String[] args) {
  hero.moveLeft()
}
}\
`;
    aether = new Aether({language});
    aether.transpile(code);
    expect(aether.problems.errors.length).toEqual(1);
    expect(aether.problems.errors[0].message).toEqual("';' expected");
    return checkRange(aether.problems.errors[0], code, {row: 3, col: 19});
  });

  it("space instead of peroid in call", function() {
    const code = `\
public class Main {
public static void main(String[] args) {
  hero moveLeft()
}
}\
`;
    aether = new Aether({language});
    aether.transpile(code);
    expect(aether.problems.errors.length).toEqual(1);
    expect(aether.problems.errors[0].message).toEqual("';' expected");
    return checkRange(aether.problems.errors[0], code, {row: 3, col: 5});
  });

  it("unclosed comment", function() {
    const code = `\
public class Main {
public static void main(String[] args) {
  /*
}
}\
`;
    aether = new Aether({language});
    aether.transpile(code);
    expect(aether.problems.errors.length).toEqual(1);
    expect(aether.problems.errors[0].message).toEqual("reached end of file while parsing");
    return checkRange(aether.problems.errors[0], code, {row: 3, col: 5});
  });

  it("unclosed if", function() {
    const code = `\
public class Main {
public static void main(String[] args) {
  hero.moveLeft();
  if ( true ) {
    hero.moveRight();
}
}\
`;
    aether = new Aether({language});
    aether.transpile(code);
    expect(aether.problems.errors.length).toEqual(1);
    expect(aether.problems.errors[0].message).toEqual("reached end of file while parsing");
    return checkRange(aether.problems.errors[0], code, {row: 6, col: 1});
  });

  it("dangeling type", function() {
    const code = `\
public class Main {
public static void main(String[] args) {
  hero.moveLeft();
  int;
}
}\
`;
    aether = new Aether({language});
    aether.transpile(code);
    expect(aether.problems.errors.length).toEqual(1);
    expect(aether.problems.errors[0].message).toEqual("not a statement");
    return checkRange(aether.problems.errors[0], code, {row: 4, col: 5});
  });

  return it("no method", function() {
    const code = `\
public class Main {
moveLeft()
}\
`;
    aether = new Aether({language});
    aether.transpile(code);
    expect(aether.problems.errors.length).toEqual(1);
    expect(aether.problems.errors[0].message).toEqual("invalid method declaration; return type required");
    return checkRange(aether.problems.errors[0], code, {row: 3, col: 3});
  });
}));