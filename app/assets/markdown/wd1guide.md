###### Last updated: 04/08/19

##### Lesson Plans
# Web Development 1

_Level: Beginner_

_Prerequisites: Introduction to Computer Science Recommended_

_Time: 5 x 35-45 minute sessions_

###  Overview
This course is designed to introduce students to web development through hands-on experience with HTML and CSS. They will learn the key tools needed to build a simple website, and they will be given a chance to complete a creative final project using their skills.


### Lessons
| Module                                                     | Levels                                              | Topics                                             |
|------------------------------------------------------------|--------------------                                 |----------------------------------------------------|
| 1. Page Setup                                              | 1-4 ("Humble Beginnings" - "Headliner")             | Break tags, paragraph tags, heading tags           |
| 2. Images                                                  | 5-6 ("Illustrious Imagery" - "Big and Tall")        | Image tags and size attributes                     |
| 3. Page Setup 2                                            | 7-9 ("Dangerous Divide" - "Orders Wanted")          | Div tags, unordered and ordered lists              |
| 4. Page Style                                              | 10-12 ("Stylish Intent" - "Identification, Please") | Text-align, color, classes, IDs                    |
| 5. Final Project                                           | 13 ("Wanted Poster")                                | All course topics combined                         |

### Key Terms

**Markup Language** - A language that is used to structure a document, like a webpage. This is different from a **programming language** which is used as a set of instructions for the computer to execute a specific **algorithm**. Markup languages are interpreted by internet browsers.

**HTML** - HTML stands for Hypertext Markup Language and is the **markup language** used to create web pages and applications.

**Tags** - A way of telling the computer how to display certain content. Tags take the form of `<tag>` or `</tag>`, with "tag" changing depending on what the desired outcome on the webpage is.

  - **Opening** - Tags that tell the computer everything after it is contained within the rules of that tag, which generally takes the form `<tag>`. For example, the opening tag for a paragraph is `<p>`.
  - **Closing** - Tags that tell the computer that it shouldn't apply any rules to the content after it, which generally takes the form `</tag>`. For example, the closing tag for a paragraph is `</p>`.
  - **Empty** - Tags that do not have corresponding closing tags. For example, the `<br>` tag acts as an empty tag.

**Element** - An individual part of an HTML webpage. This usually corresponds to a single **empty tag** or a single paired **opening** and **closing** tag. For example, `<h1> Heading </h1>` is an HTML element.

**Attribute** - A piece of information or data which is included within the HTML **tag** itself. For example, `<img>` tags have a mandatory attribute called `src` which is the "source" for the image.

  - **Class** - An attribute that can be given to group similar elements.
  - **ID** - An attribute that can mark one specific element to recall it later.

**CSS** - CSS stands for Cascading Style Sheets and is the web's way of formatting the various parts of a website's styling.

***

# Lesson 1
## Page Setup
_Levels 1-4 ("Humble Beginnings" - "Headliner")_
### Summary

These levels introduce students to HTML basics that will help them initially set up a website. Students will learn how to use tags and break up text content on a webpage into paragraphs and headings.

#### Materials

Optional Materials:
- [Progress Journal](http://files.codecombat.com/docs/resources/ProgressJournal.pdf)
- [HTML Syntax Guide](http://files.codecombat.com.s3.amazonaws.com/docs/resources/WD1-HTMLCheatsheet.pdf)

#### Learning Objectives

- Analyze the setup of a webpage.
- Use correct terminology to refer to HTML basics.
- Distinguish between programming languages and markup languages.

#### Standards

- **CSTA: 1A-CS-01** Select and operate appropriate software to perform a variety of tasks and recognize that users have different needs and preferences for the technology they use.

### Opening Activity (15 minutes): _Webpage Analysis_

#### Explain

Explain to students that they are entering a Web Development course and that it will be quite different from what they are used to in the Computer Science or Game Development course. There are no heroes in this course, and they will not be using **programming languages** in this course specifically. Explain the difference between **programming languages** and **markup languages**.

Pull up a website that is likely familiar to your class. It could be the school website, a Google Classroom, or even the CodeCombat homepage.  Scroll through the webpage and make a list on the board of what students think the parts of the website are. These could include things like buttons, a home logo, or menus. Students may also point things out that are more specific to a certain website, like the existence of a feed on a social media website. Write these down as well.

Once you have made a full list of the parts of a website, introduce students to **HTML** and **tags** (see definitions in the Key Terms section on Page 1). Explain that all the parts of a webpage that they listed are outlined using these kinds of tags.

Then introduce three specific tags: paragraph, header, and break tags. You can find information about these tags in the [HTML Syntax Guide](http://files.codecombat.com.s3.amazonaws.com/docs/resources/WD1-HTMLCheatsheet.pdf). Differentiate between **opening**, **closing**, and **empty** tags.


#### Interact

Break students into small groups of 3-4 people. Have them discuss in their groups and identify at least three places each on the webpage that you all analyzed together where paragraph, header, and break tags may have been used.

#### Discuss

Use the following discussion question to prompt a brief reflection on the activity:

**Why do you think it is important to have different kinds of tags in HTML?**

Sample Response:
> You need to be able to tell the computer/browser what the setup of your webpage looks like and what different parts will be included.

### Coding Time (10-20 minutes)

Tell students they will be playing levels 1 - 4 ("Humble Beginnings - Headliner") today. Allow students to move through these levels at their own pace. Circulate and assist as they work, calling attention to the Hints button in the top right corner of each level as needed.

_We recommend stopping students after Level 4 and using the next lesson plan to introduce the next set of concepts before beginning Level 5._

##### Look Out For:
- Some students may be confused about the difference between these Web Development levels and the levels from the Intro to CS and Game Development courses. Re-explain the difference between learning programming and learning how to build a website.
- Students may have issues with the syntax of HTML. If you notice large parts of the class struggling, bring the class together and walk through a code example in front of the whole class. Have them identify the very specific syntax requirements for writing HTML.


### Closure (5 minutes)

Use one or more of the following questions to prompt reflection on the lesson. You can facilitate a short discussion, or have students submit written responses on Exit Tickets.

**Explain why we use HTML to design the page setup of website.**

Sample Response:
>The computer/browser needs to be able to tell where certain things go on the page when you navigate to a website. We use HTML to tell it where those things should go, like where paragraphs and headings should be placed in relation to one another.

**What is the difference between a paragraph tag and a header tag?**

Sample Response:
>Anything inside of the paragraph tag will show up as normal text, and anything in the header tags will show up larger depending on the number of the header.

**What is the difference between a programming language and a markup language?**

Sample Response:
>A programming language can be used to write programs that run specific algorithms whereas a markup language is used to define elements in a document.

### Differentiation

##### Additional Supports:
- Show students how to find and interpret the hints, HTML reference cards, error messages, and starter code provided within each level.
- If you would like students to take notes as they work, a printable template is available here: [Progress Journal](http://files.codecombat.com/docs/resources/ProgressJournal.pdf)
- If students struggle to follow correct syntax, provide a copy of the printable [HTML Syntax Guide](http://files.codecombat.com.s3.amazonaws.com/docs/resources/WD1-HTMLCheatsheet.pdf)

##### Extension Activities:

- Have students wireframe a portfolio website for their work in their Computer Science class. The website should have a home page, an about page, and a page where students display links to their projects. Have them draw out what they want each page to look like on paper.


##### Lesson 2
## Images _(Levels 5-6)_
### Summary

In these two levels, students are introduced to adding images to their websites. They will learn about tag **attributes** that are required in order to add an image to a website.

#### Materials

Optional Materials:
- [Progress Journal](http://files.codecombat.com/docs/resources/ProgressJournal.pdf)
- [HTML Syntax Guide](http://files.codecombat.com.s3.amazonaws.com/docs/resources/WD1-HTMLCheatsheet.pdf)


#### Learning Objectives

- Explain why attributes are used in HTML.
- Modify attributes to change images on a webpage.

#### Standards

- **CSTA: 1A-AP-15** Using correct terminology, describe steps taken and choices made during the iterative process of program development.

### Opening Activity (20 minutes): _Tag and Attribute Deep Dive_

#### Explain

Introduce **attributes** by showing students how to [inspect the HTML](https://www.lifewire.com/get-inspect-element-tool-for-browser-756549) on a given website. You could do this with the school website or any other website that students would be familiar with. Find an image tag on the website and ask students to guess what they think the `src` **attribute** means.

Explain that `src` is an **attribute** that tells the webpage where the source of the image that will be included is. This could be another website or a file on a computer. This is a required attribute for the image tag because otherwise, the webpage will not be able to display any image in its place.

#### Interact

Split students into groups of three or four students. Assign each group two of the following attributes to research:
  - href
  - src
  - width / height
  - alt
  - style
  - lang
  - title

Have each group spend 10 minutes researching their attribute and what kinds of tags they would use those attributes with. They should then, as a group, write the following information on a post-it note for each attribute:
  - attribute name
  - attribute description
  - tags it is used with

Compile the post-its in a visible place in the classroom, and allow students some time to read through them on their own. Inform them that they will not have to have any of these memorized, but the list will be helpful when they are moving through the levels of the game and/or making their own websites later.

#### Discuss

Use the following discussion question to prompt reflection on the activity:

**Give an example of a time you would want to use an attribute.**

Sample Response:
> I would use an attribute when I want to change the image that I have on my webpage. To do this, I would set the src attribute to the URL of an image that I want.

### Coding Time (10-15 minutes)

Tell students they will be playing levels 5 - 6 today. Allow students to move through these levels at their own pace. Circulate and assist as they work, calling attention to the Hints button in the top right corner of each level as needed.

_We recommend stopping students after Level 6 and using the next lesson plan to introduce the next set of concepts before beginning Level 7._

##### Look Out For:
- Students struggling with the Image Gallery feature. If multiple students are having issues with this feature, you can do a group demonstration of selecting an image and copying/pasting its source into the level.

### Closure (5 minutes)

Use one or more of the following questions to prompt reflection on the lesson. You can facilitate a short discussion, or have students submit written responses on Exit Tickets.

**Explain the difference between a tag and an attribute.**

Sample Response:
>A tag tells the webpage what type of content will show up in what order on a webpage. Attributes specify different properties of the tag element.

**Explain how to inspect the HTML elements of a webpage.**
>In Google Chrome, you can left click on an element and inspect it. Then, you will be able to see the Developer Tools and look at the different HTML elements that make up the webpage.

### Differentiation

##### Additional Supports:
- Show students how to find the hints, methods reference cards, error messages, and sample code provided within each level.
- If you would like students to take notes as they work, a printable template is available here: [Progress Journal](http://files.codecombat.com/docs/resources/ProgressJournal.pdf)
- If students struggle to follow correct syntax, provide a copy of the printable [HTML Syntax Guide](http://files.codecombat.com.s3.amazonaws.com/docs/resources/WD1-HTMLCheatsheet.pdf)

##### Extension Activities:

- Have students continue outlining their portfolio website (from previous Extension Activity) and label the elements with what types of HTML tags and attributes they might need.

##### Lesson 3
## Page Setup 2 _(Levels 7 - 9)_
### Summary

In this section, students learn about how to use headers, `div` tags, and lists to emphasize and break up content on their webpages.


#### Materials
- printed copies of a webpage of your choice
- scissors (one set for every group of 3 students)

Optional Materials:
- [Progress Journal](http://files.codecombat.com/docs/resources/ProgressJournal.pdf)
- [HTML Syntax Guide](http://files.codecombat.com.s3.amazonaws.com/docs/resources/WD1-HTMLCheatsheet.pdf)


#### Learning Objectives

- Organize content on a website using different types of tags.

#### Standards

- **CSTA: 1A-AP-15** Using correct terminology, describe steps taken and choices made during the iterative process of program development.

### Opening Activity (15 minutes):

#### Explain

Tell students that there are multiple ways to display and break up content on a webpage. They already learned about headers and paragraphs, and now they'll be learning about some new tags: divs and lists.

#### Interact

Break students into small groups. Each group should be given a print out of the webpage. Have them cut the website into the sections that they think work best together. Have groups pair up and explain to one another why they made the decisions they did about which sections belong together.

#### Discuss

Use one or more of the following discussion questions to prompt reflection on the activity:

**Did you have the same sections as the other group? Why or why not?**

Sample Response:
> We made different decisions about the sections because there are multiple possibilities for how you could design and split up a webpage.

#### Explain
Introduce `div` tags, ordered lists, and unordered lists. (You can find descriptions in the [HTML Syntax Guide](http://files.codecombat.com.s3.amazonaws.com/docs/resources/WD1-HTMLCheatsheet.pdf) under the "Organization" heading.) Tell students that they'll be using these to make decisions about organizing their own projects.


### Coding Time (10-15 minutes)

Tell students they will be playing levels 7-9 today. Allow students to move through these levels at their own pace. Circulate and assist as they work, calling attention to the Hints button in the top right corner of each level as needed.

_We recommend stopping students after Level 9 and using the next lesson plan to introduce the next set of concepts before beginning Level 10._

##### Look Out For:
- Students may have trouble remembering to put in closing tags and using proper indentation. Their projects will still work if they do not indent, but you should encourage them to use proper indentation for readability.


### Closure (5 minutes)

Use one or more of the following questions to prompt reflection on the lesson. You can facilitate a short discussion, or have students submit written responses on Exit Tickets.

**Has learning about HTML made you look at the webpages you use differently? If so, what do you notice?**

Sample Response:
> Now when I look at the webpages I use regularly, I notice the different headers and places where they might be grouping things into `divs`.


### Differentiation

##### Additional Supports:
- Show students how to find and interpret the hints, HTML reference cards, error messages, and starter code provided within each level.
- If you would like students to take notes as they work, a printable template is available here: [Progress Journal](http://files.codecombat.com/docs/resources/ProgressJournal.pdf)
- If students struggle to follow correct syntax, provide a copy of the printable [HTML Syntax Guide](http://files.codecombat.com.s3.amazonaws.com/docs/resources/WD1-HTMLCheatsheet.pdf)

##### Extension Activities:

- Show students how to use a regular text editor (NotePad on PCs, TextEdit on Macs) to write HTML code. Have them save their work with a .html extension and open it in the browser.

##### Lesson 4
## Page Style _(Levels 10 - 12)_
### Summary

So far, students have only used HTML to format basic webpages. Now, they'll learn how to add some style to their webpages. Tell them that this is where they can get really creative and think about things like color, size, font, and all the other components that make webpages look unique.

#### Materials
- [CSS Syntax Guide](http://files.codecombat.com.s3.amazonaws.com/docs/resources/WD1-CSSCheatsheet.pdf)

Optional Materials:
- [Progress Journal](http://files.codecombat.com/docs/resources/ProgressJournal.pdf)
- [HTML Syntax Guide](http://files.codecombat.com.s3.amazonaws.com/docs/resources/WD1-HTMLCheatsheet.pdf)


#### Learning Objectives

- Add creative design to web development projects.


### Opening Discussion (5 minutes):

#### Explain

Explain that students will now be adding style to their webpages. Have students contribute some ideas about what "style" might mean. Likely, they'll think of things like background color, text color, font, and size.

Tell students that the style of webpages is based on Cascading Style Sheets or CSS. This language is paired with HTML to indicate which HTML elements to style in which ways. Hand out the CSS Syntax Guide and go through the components together, having different students read aloud the main explanations.

### Coding Time (10-15 mins)

Tell students they will be playing levels 10-12 today. Allow students to move through these levels at their own pace. Circulate and assist as they work, calling attention to the Hints button in the top right corner of each level as needed.


##### Look Out For:
- Students may struggle with the difference between IDs and classes. Explain that IDs call out one specific thing, where multiple elements can fall into the same class.

### Closure (5 minutes)

Use the following question to encourage reflection on the lesson. You can facilitate a short discussion, or have students submit written responses on Exit Tickets.

**What do you notice about the differences between HTML and CSS?**

Sample Responses:
> CSS and HTML have different syntax. Also, in CSS you need to refer to an HTML element or elements.


##### Lesson 5
## Final Project _(Levels 13)_
### Summary

Tell students that they will have the opportunity to design a creative project in this last level. They should use the tools that they've learned in both HTML and CSS.

#### Materials

Optional Materials:
- [Progress Journal](http://files.codecombat.com/docs/resources/ProgressJournal.pdf)
- [HTML Syntax Guide](http://files.codecombat.com.s3.amazonaws.com/docs/resources/WD1-HTMLCheatsheet.pdf)
- [CSS Syntax Guide](http://files.codecombat.com.s3.amazonaws.com/docs/resources/WD1-CSSCheatsheet.pdf)


#### Learning Objectives

- Design a creative project using HTML and CSS.


### Opening Discussion (5 minutes):

#### Explain

Explain that they have an opportunity to make a creative project and should try to make something they want to share with their friends and family. Remind students of the tools that they have using the HTML Syntax Guide, the CSS Syntax Guide, and the post-it wall of tags/attributes that you created in Lesson 2.

### Coding Time (30-45 mins)

Tell students they will be playing level 13 for the day, creating their own webpage. Circle around and encourage students to get creative with their design and add on elements that they think would be interesting.


### Closure (5 minutes)

Use the following question to encourage reflection on the course. You can facilitate a short discussion, or have students submit written responses on Exit Tickets.

**What was the biggest difference between using Python/JavaScript in Intro to Computer Science and using HTML/CSS in Web Development 1?**

Sample Responses:
> In Intro to Computer Science, we were creating programs that ran and solved specific problems. In Web Development 1, we were using markup languages and style sheets to create web pages that didn't change.
