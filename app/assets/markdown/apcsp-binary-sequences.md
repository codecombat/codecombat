#### Activity
# Data Encoding
 
### Learning Objectives
* [LO 2.1.2] Explain how binary sequences are used to represent digital data.
 
Different number bases, including binary, decimal, and hexadecimal can be used to encode different types of data, depending on the context in which it's used. One example of this is the "ASCII standard" for encoding text. 


### Overview for Teachers
By the end of the lesson, students will recognize how bits represent different data types (text, pictures, sound, etc) and the limitations that come with this way of storing data.

### Introduction
In this lesson, you will learn everything about binary, which is a numbering system composed solely of 1 and 0 that computers use to store information and represent data such as pictures, sounds, and videos. You will also get to know how to translate binary code into different data types. 

### Class Discussion

- Watch this code.org video [“How Computers Work: Binary & Data”](https://www.youtube.com/watch?v=USCBCmwMCDA&list=PLzdnOPI1iJNcsRwJhvksEo1tJqjIqWbN-&index=3)
- Discuss the video with your class. 
- Use the following to check their understanding of concepts like number bases and different types of data transformation:
  - What is Binary, and Why Do Computers Use It?
  - What is the difference between encoding text data and sound data?

 
### What you need:
 
- A "binary to ascii" and "ascii to binary" converting webpage.
 - http://www.binaryhexconverter.com/binary-to-ascii-text-converter
 - http://www.binaryhexconverter.com/ascii-text-to-binary-converter
- An ASCII encoded binary "secret message". 
 - Create your own with the ascii to binary converter, or use this one:
```
01000010 01100101 00100000 01110011 01110101 01110010 01100101 00100000
01110100 01101111 00100000 01100100 01110010 01101001 01101110 01101011
00100000 01111001 01101111 01110101 01110010 00100000 01001111 01110110
01100001 01101100 01110100 01101001 01101110 01100101 00100000 01100001
01101110 01100100 00100000 01110000 01101100 01100001 01111001 00100000
01000011 01101111 01100100 01100101 01000011 01101111 01101101 01100010
01100001 01110100 00100001
```
 
### Activity #1: Decode the Secret Message
 
1. Give the students the "secret message".
2. Direct the students to go to a "binary to ascii converter" in a web browser (or have them use Google to find one).
3. Each student copies the binary code into the converter to decipher its contents.
 
### Activity #2: Send a Secret Message
 
1. Pair the students up.
2. Direct each student to an "ascii to binary converter" web page.
3. Each student will type a secret message in ASCII text, then use the converter to change it into binary.
4. The students should exchange secret messages with their partner, and use a "binary to ascii converter" to decipher their partner's secret message.
	

### Discussion Questions:
- ASCII is a standard format used to represent text in binary form. Can you think of any other digital formats you use online? For images? For music?
- Why is it important to have commonly agreed upon formats for digital data?

### Challenge Questions: 
- A sequence of bits can represent many different things. The letter A, in binary is 01000001. If the same bits were used to represent a number, what number would it be?
- If you only have 8 bits, what is the highest integer you can represent in binary?
- Given the binary representation of an ASCII letter A, how would it be represented in hexadecimal?

### Discussion Topics:

Extend the exploration by discussing the following topics:


#### Overflow Errors

While using binary code, you may need to be careful of the limit of your computer’s memory capacity.

As we saw in the code.org video, a bit has a numeric value equal to the (0 or 1). Adding multiple bits in a sequence allows us to extend the value of one bit by multiplying the value of that bit ( 0 or 1) by the place value of its position. The most popular bit sequence is called a byte. It consists of 8 bits and can store number values up to 256.

But what if we want to store more than 256 in a byte? We can of course add more bits to extend the capacity, but what if we are restricted to a number of bits to use? For example, what happens when we want to stare a value of 257 in a byte that has a maximum capacity of 256? In computer science, that is what we call an overflow error. 

Within the premise of your own programming, overflow errors might not be very erosive. However, in the real world, overflow errors can be catastrophic. An example is [the 2038 computing problem](https://www.scienceabc.com/innovation/what-is-the-2038problem.html#:~:text=The%202038%20problem%20refers%20to,not%20connected%20to%20the%20internet.)
, which refers to the time encoding error that will occur in the year 2038 in 32-bit systems that will eventually overflow.


#### Analog Data 

Binary is very versatile. We can use it to store text, images, and sound. However, some of these data types are easier to store in binary than others. 

Characters that make up text are really similar to numbers in respect to how they are stored in binary using a sequence of bits, but when it comes to sound waves, things are a little different. **Sound is classified as analog data** which means that its value changes smoothly, rather than in discrete intervals, over time. Some examples of analog data include pitch and volume of music or position of a sprinter during a race.

Because values of data like this fluctuate more freely than numbers or text, programmers have devised a technique to capture its details in binary called sampling. **Sampling means measuring values of the analog signal at regular intervals called samples**. The samples are measured to figure out the exact bits required to store each sample.

Take sound as an example. Sound is represented in wave format, where each wave has an amplitude, which is the height of the wave. By measuring and storing the amplitude of a sound wave at regular intervals, we end up with a collection of values that can be stored in binary like we saw in the video.

