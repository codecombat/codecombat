Aether = require '../aether'
lodash = require 'lodash'

language = 'java'
aether = new Aether language: language

checkRange = (problem, code, start) ->
  if start
    expect(problem.range[0].row).toEqual(start.row)
    expect(problem.range[0].col).toEqual(start.col)

xdescribe "#{language} Errors Test suite", ->
  describe "Syntax Errors", ->
    it "no class", ->
      code = """
      hero.moveLeft()
      """
      aether = new Aether language: language
      aether.transpile code
      expect(aether.problems.errors.length).toEqual(1)
      expect(aether.problems.errors[0].message).toEqual('class, interface, or enum expected')
      checkRange(aether.problems.errors[0], code, {row: 0, col: 0})

    it "not a statement", ->
      code = """
      public class Main {
        public static void main(String[] args) {
          2+2;
        }
      }
      """
      aether = new Aether language: language
      aether.transpile code
      expect(aether.problems.errors.length).toEqual(1)
      expect(aether.problems.errors[0].message).toEqual('not a statement')
      checkRange(aether.problems.errors[0], code, {row: 3, col: 4})


    it "no semicolon", ->
      code = """
      public class Main {
        public static void main(String[] args) {
          hero.moveLeft()
        }
      }
      """
      aether = new Aether language: language
      aether.transpile code
      expect(aether.problems.errors.length).toEqual(1)
      expect(aether.problems.errors[0].message).toEqual("';' expected")
      checkRange(aether.problems.errors[0], code, {row: 3, col: 19})

    it "space instead of peroid in call", ->
      code = """
      public class Main {
        public static void main(String[] args) {
          hero moveLeft()
        }
      }
      """
      aether = new Aether language: language
      aether.transpile code
      expect(aether.problems.errors.length).toEqual(1)
      expect(aether.problems.errors[0].message).toEqual("';' expected")
      checkRange(aether.problems.errors[0], code, {row: 3, col: 5})

    it "unclosed comment", ->
      code = """
      public class Main {
        public static void main(String[] args) {
          /*
        }
      }
      """
      aether = new Aether language: language
      aether.transpile code
      expect(aether.problems.errors.length).toEqual(1)
      expect(aether.problems.errors[0].message).toEqual("reached end of file while parsing")
      checkRange(aether.problems.errors[0], code, {row: 3, col: 5})

    it "unclosed if", ->
      code = """
      public class Main {
        public static void main(String[] args) {
          hero.moveLeft();
          if ( true ) {
            hero.moveRight();
        }
      }
      """
      aether = new Aether language: language
      aether.transpile code
      expect(aether.problems.errors.length).toEqual(1)
      expect(aether.problems.errors[0].message).toEqual("reached end of file while parsing")
      checkRange(aether.problems.errors[0], code, {row: 6, col: 1})

    it "dangeling type", ->
      code = """
      public class Main {
        public static void main(String[] args) {
          hero.moveLeft();
          int;
        }
      }
      """
      aether = new Aether language: language
      aether.transpile code
      expect(aether.problems.errors.length).toEqual(1)
      expect(aether.problems.errors[0].message).toEqual("not a statement")
      checkRange(aether.problems.errors[0], code, {row: 4, col: 5})

    it "no method", ->
      code = """
      public class Main {
        moveLeft()
      }
      """
      aether = new Aether language: language
      aether.transpile code
      expect(aether.problems.errors.length).toEqual(1)
      expect(aether.problems.errors[0].message).toEqual("invalid method declaration; return type required")
      checkRange(aether.problems.errors[0], code, {row: 3, col: 3})