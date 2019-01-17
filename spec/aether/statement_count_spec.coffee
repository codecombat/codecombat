Aether = require '../aether'

cs = (desc, lang, count, code) ->
  it "#{lang}: #{desc}", ->
    aether = new Aether
      language: lang
    aether.transpile code
    expect(aether.getStatementCount()).toEqual count

describe "Statement Counting", ->
  describe "Python", ->
    cs "Simple", "python", 3, """
      one()
      two()
      three()
    """
    cs "Mathy", "python", 2, """
        if self.a() > something.b and self.c():
          x = somethingElse()
    """
    cs "while loop", "python", 3, """
      while True:
        self.moveLeft();
        self.moveRight();
    """
    cs "for sum", "python", 3, """
      for i in xrange(1,10):
        self.say(i) 
    """
    cs "function", "python", 3, """
      def x(a):
        return a+2

      x(2)
    """

  describe "Javascript", ->
    cs "Simple", "javascript", 3, """
      one();
      two();
      three();
    """
    cs "Mathy", "javascript", 2, """
      if ( this.a() > something.b && this.c() )
        var x = somethingElse();
    """
    cs "while loop", "javascript", 3, """
      while ( true ) {
        self.moveLeft();
        self.moveRight();
      }
    """
    cs "for sum", "javascript", 3, """
      for ( var i = 0; i < 10; ++i ) this.say(i);
    """
    cs "function", "javascript", 3, """
      function x(a) {
        return x + 2;
      }
      x(2);
    """

  describe "Lua", ->
    cs "Simple", "lua", 3, """
      one()
      two()
      three()
    """
    cs "Mathy", "lua", 2, """
      if (self:a() > something.b) and self.c() then
        x = somethingElse()
      end
    """
    cs "for sum", "lua", 2, """
      for i = 1,10 do this.say(i) end
    """


