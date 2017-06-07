Aether = require '../aether'

xdescribe "Java test suite", ->
  describe "Java Basics", ->
    aether = new Aether language: "java"
    it "05 - JAVA - return 1000", ->
      code = """
      public class MyClass{
       public static int output()
         {
            return 1000;
         }
      }
      """
      aether.className = "MyClass"
      aether.staticCall = "output"
      aether.transpile(code)
      expect(aether.run()).toEqual 1000
  
    it "05 - JAVA - variable", ->
      aether = new Aether language: "java"
      code = """
      public class MyClass
                   { 
                     public static String output()
                      {
                        int x = 10;
                        return x; 
                      }
                   }
      """
      aether.className = "MyClass"
      aether.staticCall = "output"
      aether.transpile(code)
      expect(aether.run()).toEqual 10

    it "05 - JAVA - Logical operators", ->
      aether = new Aether language: "java"
      code = """
      public class LogicalClass
       {
       public static String output()
         {
          boolean testTrue = true;
          boolean testFalse = false;
          if(testTrue && testFalse){
              return "Print not Expected";
          }else{
              return "Print Expected";
          }
          }
       }
      """
      aether.className = "LogicalClass"
      aether.staticCall = "output"
      aether.transpile(code)
      expect(aether.run()).toBe('Print Expected')

    it "05 - JAVA - Math operations", ->
      aether = new Aether language: "java"
      code = """
      public class MathClass
      {
            public static String output()
            {
                  int i1 = 10;
                  int i2 = 2;
                  int i4, i5, i6, i7, i8;
                  i4  = i1 + i2;
                  i5 = i1 - i2;
                  i6 = i1 * i2;
                  i7 = i1 / i2;
                  i8 = i1 % i2;
                  return i4+i5+i6-i7+i8;
            }
      }
      """
      aether.className = "MathClass"
      aether.staticCall = "output"
      aether.transpile(code)
      expect(aether.run()).toEqual 35

    it "05 - JAVA - String concatenation", ->
      aether = new Aether language: "java"
      code = """
      public class ConcatenationClass 
      { 
            public static String output()
            { 
            String x = "String "; 
            String y = "concatenation"; 
            x = x + y; 
            return x;
            }
      }
      """
      aether.className = "ConcatenationClass"
      aether.staticCall = "output"
      aether.transpile(code)
      expect(aether.run()).toBe('String concatenation')

    it "05 - JAVA - If-else clause", ->
      aether = new Aether language: "java"
      code = """
      public class IfClass 
       {
        public static String output()
        { 
         int a = 10; 
         if (a == 10) 
           { 
             return "correct";
           }
         else 
           { 
             return "incorrect"; 
           }
        }
       }
      """
      aether.className = "IfClass"
      aether.staticCall = "output"
      aether.transpile(code)
      expect(aether.run()).toBe('correct')

    it "05 - JAVA - For loop", ->
      aether = new Aether language: "java"
      code = """
     public class ForClass
      {
         public static String output()
         {
             int x = 0;
             for (int i = 0 ; i < 10; i++ ){
                 x = x + i;
             }
             return x;
         }
      }
      """
      aether.className = "ForClass"
      aether.staticCall = "output"
      aether.transpile(code)
      expect(aether.run()).toEqual 45

    it "05 - JAVA - While loop", ->
      aether = new Aether language: "java"
      code = """
     public class WhileClass
     {
       public static String output()
       {
           int i = 0;
           while(i < 10){
               i+= 1;
           }
            return i; 
         }
     }
      """
      aether.className = "WhileClass"
      aether.staticCall = "output"
      aether.transpile(code)
      expect(aether.run()).toEqual 10

    it "07 - JAVA - Two Dimensions array", ->
      aether = new Aether language: "java"
      code = """
      public class ArrayClass
     {
       public static String output()
       {
          int[][] i = new int[3][2];
          i[0][0] = 1;
          i[0][1] = 1;
          i[1][0] = 2;
          i[1][1] = 2;
          i[2][0] = 3;
          i[2][1] = 3;
         return i[2][1];
       }
     }
      """
      aether.className = "ArrayClass"
      aether.staticCall = "output"
      aether.transpile(code)
      expect(aether.run()).toEqual 3

    it "07 - JAVA - Ternary If", ->
      aether = new Aether language: "java"
      code = """
      public class TernaryClass
       {
         public static String output()
         {
              int i = 100;
              return i >= 100 ? "Correct" : "Incorrect"; 
         }
       }
      """
      aether.className = "TernaryClass"
      aether.staticCall = "output"
      aether.transpile(code)
      expect(aether.run()).toBe('Correct')

    it "07 - JAVA - Switch", ->
      aether = new Aether language: "java"
      code = """
      public class SwitchClass
       {
         public static String output()
         {
            int i = 10;
            switch(i)
            {
                  case 0: return "That is zero";
                  case 1: return "That is one"; break;
                  default: return "That is not zero nor one";
            }
         }
      }
      """
      aether.className = "SwitchClass"
      aether.staticCall = "output"
      aether.transpile(code)
      expect(aether.run()).toBe('That is not zero nor one')

    it "07 - JAVA - Increment and decrement outside For clause", ->
      aether = new Aether language: "java"
      code = """
      public class IncrementClass
      {
         public static int output()
         {
            int i = 10;
            i++;
            i++;
            i--;
            return i;
         }
      }
      """
      aether.className = "IncrementClass"
      aether.staticCall = "output"
      aether.transpile(code)
      expect(aether.run()).toEqual 11

    it "07 - JAVA - Assignment operators", ->
      aether = new Aether language: "java"
      code = """
      public class AssignmentClass
      {
         public static int output()
         {
            double d1 = 5;
            double d2 = 2;
            d1 += d2;
            d1 -= d2;
            d1 *= d2;
            d1 /= d2;
            d1 %= d2;
            return d1; 
         }
      }
      """
      aether.className = "AssignmentClass"
      aether.staticCall = "output"
      aether.transpile(code)
      expect(aether.run()).toEqual 1

    it "07 - JAVA - Bitwise operators", ->
      aether = new Aether language: "java"
      code = """
     public class BitwiseClass
      {
         public static int output()
         {
             int a = 60, b = 13;
             /*a = 0011 1100
             b = 0000 1100
             a&b = 0000 1100  (12)
             a|b = 0011 1101   (61)
             a^b = 0011 0001   (49)
             ~a  = 1100 0011 (-61)
            a<<2  = 1111 0000 (240)
            a>>2  = 0000 1111 (15)
            a>>>2  = 0000 1111 (15)*/
             int c = a&b;
             int d = a|b;
             int e = a^b;
             int f = ~a;
             int g  = a<<2; 
             int h = a >> 2; 
             int i = a >>> 2; 
             return c == 12 && d == 61 && e == 49 && f == -61 && g == 240 && h == 15 && i == 15;             
         }
      }
      """
      aether.className = "BitwiseClass"
      aether.staticCall = "output"
      aether.transpile(code)
      expect(aether.run()).toBe true

    it "07 - JAVA - If/else without bracers", ->
      aether = new Aether language: "java"
      code = """
      public class IfClass
      {
         public static int output()
         {
            
          int a = 10;
         if (a == 10)
            return "that´s correct";
         else
            return "that´s incorrect";
         }
      }
      """
      aether.className = "IfClass"
      aether.staticCall = "output"
      aether.transpile(code)
      expect(aether.run()).toEqual('that´s correct')

    it "07 - JAVA - Class method invocation", ->
      aether = new Aether language: "java"
      code = """
      public class SumClass
      {  
         public static int sum(int a, int b){
              return a + b;
         }   
         public static int output()
         {
             int i1 = 10;
             int i2 = 10;
             return sum(i1,i2);
         }
      }
      """
      aether.className = "SumClass"
      aether.staticCall = "output"
      aether.transpile(code)
      expect(aether.run()).toEqual 20

    it "09 - JAVA - Instance variables from main class", ->
      aether = new Aether language: "java"
      code = """
      public class VariableClass
      {
         private int a;

         public VariableClass(int a){
            this.a = a;
         }

         public int getA(){
            return this.a;
         }

         public static String output()
         {            
            VariableClass vc = new VariableClass(10);
            if (vc.getA() == 10)
               return "that´s correct";
           else
               return "that´s incorrect";
         }
      }
      """
      aether.className = "VariableClass"
      aether.staticCall = "output"
      aether.transpile(code)
      expect(aether.run()).toEqual('that´s correct')

    it "09 - Conditional yielding", ->
      aether = new Aether language: "java", yieldConditionally: true, simpleLoops: false
      dude =
        killCount: 0
        slay: ->
          @killCount += 1
          aether._shouldYield = true
        getKillCount: -> return @killCount
      code = """
        public class YieldClass
      {
         public static String output()
         {            
            while(true){
              hero.slay();
              break;
            }
            
            while(true){
                hero.slay();
                if (hero.getKillCount() >= 5)
                  break;
            }
            hero.slay();
         }
      }
      """
      aether.className = "YieldClass"
      aether.staticCall = "output"
      aether.transpile code
      f = aether.createFunction()
      gen = f.apply dude

      for i in [1..6]
        expect(gen.next().done).toEqual false
        expect(dude.killCount).toEqual i
      expect(gen.next().done).toEqual true
      expect(dude.killCount).toEqual 6