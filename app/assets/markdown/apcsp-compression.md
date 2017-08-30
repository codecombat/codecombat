##### Activity
# Lossy and Lossless compression

Data - There are trade-offs when representing information as digital data.	

### Learning Objectives
- (LO) 3.3.1 Analyze how data representation, storage, security, and transmission of data involve computational manipulation of information. [P4]

**Information for the instructor**

Many decisions need to be made when storing or transmitting data digitally. These can affect the amount of storage space used, bandwidth needed, and security of the digital materials.

This activity will demonstrate Lossy and Lossless compression techniques and how they can affect data. 

Both Lossless and Lossy compression techniques will reduce the size of the data, reducing the space needed to store it or the bandwidth needed to transmit the data.

When using Lossless compression, all the original data is still available and the original data can be completely restored to its original condition. This is a preferred method for data that has specific information that cannot be lost, such as text files and spreadsheets.

When using Lossy compression, the file size is reduced by removing information from the original. These files cannot be fully restored to their original condition. This is a preferred method for data where the information loss will not be harmful, such as in image, sound, and video files.

## Lossy compression

This is a close up of a map of Backwoods Forest, held by one of CodeCombat’s heroes, Anya.

[image needed]

The details of the map can be clearly seen.  This image is not compressed at all and takes up  194KB or storage space. This also means it takes that much bandwidth to transmit.

Here is the same image, but after is has been compressed 90%. Now it only takes 20KB of storage space and bandwidth.

[image needed]

Look at how the details have become blurred. This is one of the costs of Lossy compression. 




## Lossless compression

**Lossless compression**
How much wood could a woodchuck chuck
 
If a woodchuck could chuck wood? 

As much wood as a woodchuck could chuck, 

If a woodchuck could chuck wood.
How much  could a   
If a  could  ? 
As much  as a  could , 
If a  could  .


144 characters total
By using  and to replace “wood” and “chuck” we reduce the total characters to 88 characters, which is about 39% compression.
Because we know what the symbols represent, we can reconstruct the original tongue-twister with no loss of data.

**Lossy Compression**

Peter Piper picked a peck of pickled peppers.
Did Peter Piper pick a peck of pickled peppers?
If Peter Piper Picked a peck of pickled peppers,
Where's the peck of pickled peppers Peter Piper picked?



Ptr Ppr pckd a pck of pckld ppprs.
Dd Ptr Ppr pck a pck of pckld ppprs?
If Ptr Ppr Pckd a pck of pckld ppprs,
Whr's th pck of pckld ppprs Ptr Ppr pckd?
195 characters
By removing all vowels except those that start words, we reduce this to 148 characters for a compression rate of 24.1%

Ask your students if they think Lossless would be more efficient? 
Break your students into groups and have them give it a try.

Peter Piper picked a peck of pickled peppers.
Did Peter Piper pick a peck of pickled peppers?
If Peter Piper picked a peck of pickled peppers,
Where's the peck of pickled peppers Peter Piper picked?

Give them a few minutes to write this in a compressed format by replacing common groups of letters with words. 
Peter, Piper, pickled, and peppers are all common.
However, Peter & Piper only appear together, so one symbol could replace both words.
The same is true for pickled peppers.

Could it be compressed even more? Pick and peck are also common words (though pick is often part of picked). 


### Video Analysis 
1. Have students find a high-resolution (4K) YouTube video and click settings to change the resolution from 2160p to 1080p then to 480p and finally to 144p. 
2. Have them switch back and forth from 2160p to 144p.
3. Ask them to analyze the differences in video quality. 
4. Ask them to analyze the storage needs for the video at 2160p vs 144p.

Here are four high quality videos for use if your class is still broken into teams:
- Amazing 4K Video of Colorful Liquid in Space
- Hubble The Final Frontier - Official Final Film
- NASA | 4K Video: Thermonuclear Art – The Sun In Ultra HD 4K
- 4k Hawaii Drone Footage

Ask them to analyze if streaming music is compressed using lossy or lossless compression.


### Discussion Questions:
- When would you use Lossy compression?
- When would you use Lossless compression?
- What are the trade-offs when representing information digitally?
- Why is compression when transmitting data important? 
- Can students think of any examples where you, as students, use compression in your lives?

*Hopefully the students will realize they use this when they text.*
- Brt = be right there
- Lol = laughing out loud
- Smh = shaking my head
