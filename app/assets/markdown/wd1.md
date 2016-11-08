##### Lesson Plans
# Web Development 1

### Curriculum Summary

#### Overview
In Web Development 1, students will learn the basics of web development, starting with HTML and CSS.

TODO: Explain how this guide is laid out (differently than other Course guides)
TODO: Explain how to use the project -- brainstorm leading up to the Wanted Poster. Build the universe with non-coding activities.

_**Language Note** Web Development 1 uses HTML and CSS, regardless of which programming language your class is set to._

### Scope and Sequence

| Module                                              |Transfer Goals               |
| ----------------------------------------------------|:--------------------------- |
| [1. Basic HTML Syntax](#basic-html-syntax)          | Use `<br>` and `<p>` tags to break up webpage content. |
| [2. Images & Atttributes](#images-attributes)       | Add and resize images on a webpage using the `<img>` tag. |
| [3. Organization](#organization)                    | Organize a webpage using `<div>` and list tags like `ul`, `ol` and `li`. |
| [4. CSS Syntax](#css-syntax)                        | Control the style of webpage elements using `<style>` and CSS tags. |
| [5. CSS Selectors](#css-selectors)                  | Add custom styles to a webpage using classes and IDs. |
| [6. Final Project](#final-project)                  | Demonstrate HTML/CSS knowledge by adding elements. |

### Core Vocabulary

**HTML** - 

**CSS** -

**Tags** -

**Attributes** -

**Selectors** -

##### Module 1
## Basic HTML Syntax

### Summary

**HTML**, aka **H**yper**T**ext **M**arkup **L**anguage, is a language used to craft documents for the web. This first module is about introducing HTML to students by getting them to put something on the page, and giving them a chance to see how the content they add to the document evolves with the use of tags, attributes, and styles in later modules.

### Transfer Goals

- Add content to an HTML document
- Recognize the `<` angle bracket `>` syntax for HTML tags.
- Use the `<br>` tag to add line breaks to text in an HTML page
- Recognize opening and closing syntax for HTML tags.
- Use the `<p>` tag to add paragraph groups to text in an HTML page
- Use `<h1>`, `<h2>`, `<h3>`, and `<h4>` tags to add meaningful header sections to an HTML page, along with `<p>` tags for paragraph content


### The HTML Editor

#### Instructive Activity: Ink On The Page

Web pages are made up of documents -- text on a page, just like books and magazines. They can be so much more than that, with videos, games, and other exciting interactive things -- but at the base of it all, we have HTML pages. **HTML** stands for **H**yper**T**ext **M**arkup**L**anguage, and it's one of the building blocks of the web.

HTML isn't just regular text. It has tags that perform special duties (like embedding images, or breaking up paragraphs). These tags are written into the page, but when you view it in a browser, the tags themselves don't show up -- it's the stuff inside them that you see. It's also usually seen with CSS -- which lets you change the style of the page -- colors, fonts, and cool layouts, and sometimes JavaScript -- which lets you make the page interactive.

We're going to kick off a series of lessons in which you get to take plain, boring text on a page and make it much more interesting. The first thing we need to do is stop that page from being blank, so let's start adding content!

#### Coding Time

Have students add and remove content from the sample page in the editor (Level 1 -- Humble Beginnings). Encourage them to add a lot of text (multiple lines worth), not just a few words. If students need a prompt, ask them to write a short bio for their hero, or an ad for their favorite sword.

#### Reflect

**What did you choose to write on the page?**
> I wrote a journal entry about my hero character. It would be really cool if my hero had a blog.


### The Line `<br>`eak Tag

We're going to explore our first HTML tag with `<br>`. This tag allows us to insert line breaks on a page.

#### Instructive Activity: Break It Up (10-15 mins)

How many of you hit the enter key when you wanted to put some space in between things you wrote? (look for raised hands)

Did it work? (nope!)

This is where we're going to use our first HTML tag, and see some of the behind-the-scenes work you can do with those tags. Our first tag is called *break*, and it looks like this:

`<br>`

You can put one of these in your document any time you'd like to see a line break.

#### Interact (3 mins)

Let's go ahead and look at the stuff you wrote on the page in Level 1. Add some `<br>` tags wherever you hit enter, or where you think a new line should go.

#### Explain (2 mins)

Okay, did anyone see the letters `br` mixed in with their words on the left side of the level? (if yes, make sure they closed the angle brackets).

The reason you just see the spaces instead of the stuff you typed in the tag (`<br>`) is because those angle brackets are telling the browser that the tag is meant to be read as an instruction, not displayed on the page.

We can recognize HTML `elements` by these `tags`. They will always be enclosed in `<` angle brackets `>`. Some tags, like the ones we'll look at later, have two sets of angle brackets, and some (like `<br>`) are `self-closing` and just use one set.

A good way to know if a tag should be self-closing or not: *does it put something on the page by itself?* (like a break or a horizontal line) or *does the tag tell the browser how to show something on the page?* (like text or an image)

#### Interact (3-5 mins)

Now, let's break the breaks, so we can see how things might get a little funny if we don't write our tags correctly.

Have the students "mess up" their `<br>` tags by adding spaces to them or putting other text in them. Circulate as they change what renders on the left side of the editor, and prompt students to try things like:

*starting text*
```
CodeCombat is really fun.
My hero is the coolest.
```

*adding a br tag without angle brackets*
```
CodeCombat is really fun.
br
My hero is the coolest.
```

*forgetting to close a tag*
```
CodeCombat is really fun. <br
My hero is the coolest.
```

#### Reflect (2 mins)

**What does an HTML tag look like?** The name of the element inside of angle brackets `< element >`

**If I just hit the enter key in between things on a page, what will happen?** The text will all go on the same line.


#### Coding Time (5-8 mins)

If students are struggling to complete the level, prompt them to make sure that they are correctly wrapping the `<br>` tag in angle brackets (and closing it!)



### The `<p>`aragraph Tag

Breaking apart every paragraph in HTML with `<br>` tags isn't the most effective. This module explores the built-in **paragraph** tag (`<p> </p>`) that lets us group and format paragraph text. It's also our introduction to *opening* and *closing* tags.

#### Instructive Activity: Break It Up (8-10 mins)

When you read text (in books, in magazines, on the internet), is it always broken up into single lines? Probably not -- you're probably used to reading paragraphs. Luckily, HTML has a built-in solution for that -- the `<p>` tag.

We use `<br>` to make single line breaks, but if we need a group of text to show up on the page as a paragraph, we can *wrap* it in paragraph tags.

This is our first HTML element that has an opening and a closing tag. (Draw these on the whiteboard and identify the parts -- the angle brackets around both p's, and the / that indicates the closing tag)

`<p>` <--- opening
`</p>` <--- closing

Any text that we want to go in the paragraph goes in between them, like this:

`<p>Hi, I'm a paragraph. I have two sentences.</p>`


#### Interact (3 mins)

Have the students add more text to their editor (or work off the previous level), and make sure that there are at least 2 paragraphs worth of text. Ask them to try wrapping sentences in `<p>` tags, and see what happens if they mix and match `<p>` tags with `<br>` tags (or swap out `<br>` tags for `<p>`s).

Circulate and remind students that these elements come with opening and closing tags.

#### Reflect (2 mins)

**What are some of the differences between a `<br>` tag and a `<p>` tag?**
> The `<br>` is a single line break and the `<p>` is for wrapping around a paragraph. The `<br>` is self-closing and the `<p>` has opening and closing tags.


#### Coding Time (5-8 mins)

If students are struggling to complete the level, prompt them to make sure that they are correctly opening and closing the tags.


### The `<h>`eader Tags

Building off the previous lesson on paragraph tags, we're going to introduce **header tags** now.

#### Instructive Activity: Headline News (8-10 mins)

*Prep the whiteboard with this text, taking care to use different font sizes to indicate the distinction between title text, sub headers, and regular paragraph text*

*OR Print out a newspaper article here!*

*** 
# Adventurer's Guide

## How To Get Started

### Equipment
sword   
shield  

### Skills
archery  
swordfighting  
magic

## Cool Dungeons
Kithgard
Plainswood
***

This is what it might look like WITHOUT any sytling. 

*** 
Adventurer's Guide  
How To Get Started

Equipment  
sword   
shield  

Skills  
archery  
swordfighting  
magic

Cool Dungeons  
Kithgard
Plainswood
***

Hard to read, right? It's confusing to know which one's the headline, which are names of lists, etc.

Let's think about reading the news (or a blog post, or a magazine). Is all of the text on the page the same size? (no)

Why is some of the text larger or bolder than other text? (to call attention to it)

What's usually the biggest text on the page? (the title)

HTML has `header tags` to help us identify important things on the page -- these work a lot like `<p>` tags, but the text is bigger and bolder so it pops.

There are four sizes of header tag that you might use while you're making web pages. The biggest one is `<h1>` and it's used for title text. `<h2>` is for important sub-headers, and is still pretty big. `<h3>` is a little bit smaller, and `<h4>` is a little bit smaller than that, but they're all bigger and bolder than `<p>` tags, so you know to pay attention to them.


*Next, modify the whiteboard text by writing the opening and closing header tags around each header section. Ask the students to choose which tags go where. The final should end up something like this:*

----------
# `<h1>`Adventurer's Guide`</h1>`

## `<h2>`How To Get Started`</h2>`

### `<h3>`Equipment`</h3>`  
`<p>`sword`</p>`  
`<p>`shield`</p>`

### `<h3>`Skills`</h3>`  
`<p>`archery`</p>`  
`<p>`swordfighting`</p>`  
`<p>`magic`</p>`

## `<h2>`Cool Dungeons`</h2>`  
`<p>`Kithgard`</p>`  
`<p>`Plainswood`</p>`
----------

*After this exercise, students should be ready to complete the level. While they're working on it, encourage them to see what happens if they forget to close a tag.*


#### Coding Time (5-8 mins)
If students are struggling to complete the level, prompt them to make sure that they are correctly opening and closing the tags.


##### Module 2

## Images & Attributes

### Summary

TODO: Write a summary of this module here.

### Transfer Goals

- Add an image to an HTML page using the `<img>` tag
- Understand that images need sources (URLs) in order to render on the page
- Add `height` and `width` attributes to an `<img>` tag to specify the size of an image


### The `<img>` Tag

#### Instructive Activity: Picture Perfect (10-13 mins)


Text by itself is not that exciting, and images are a great way to add some visual interest to a HTML page. We'll look at the `<img>` tag in this lesson.


Text is pretty cool, but isn't it about time we get some pictures on our pages?

HTML has a tag that lets you embed images on the page -- it's called `<img>`

There are a couple of important things to know about `<img>`

1. It's a self-closing tag just like `<br>` (because it's adding something new to the page instead of directing how something in between two tags is displayed).
2. `<img>` tags need a source (`src`) so the browser knows where the image is coming from.


*Diagram the parts of the `<img>` tag on the whiteboard, and call out important things about how the tag is structured.*

`<img src="http://www.codecombat.com/hero.jpg"/>`

We enclose the tag in `<` angle brackets `>` just like with the other elements we've seen, and you can also put the `/` just before the closing angle bracket if you want to (it's optional).

This element is named `img` so we start with that. Be careful not to spell it wrong, or you won't see a picture!

Next, we have `src="http://www.codecombat.com/hero.jpg"` which tells us where the picture is coming from. `src` is an `attribute` (we'll see some more of those later -- we can do things like change the size of our images with them!). `src` is after an equals-sign and inside of quote marks, and needs to be a valid URL that ends in an image file type (like .jpeg or .png or .gif). CodeCombat has a gallery full of images that we can use -- heroes, treasure, monsters, and more!


#### Interact (5 mins)

Have the students select images from the CodeCombat gallery (upper right side of the page, above the editor) and add them to a blank page in the editor. At first, instruct them to copy the whole `<img>` tag, but then see if they can copy the image URL only and construct the tag from scratch.

Circulate to assist; the most common issues with this tag tend to happen around spelling and the placement of the "" around the `src`.

While students are working on this, start introducing the Wanted Poster project -- indicate that they'll be making wanted posters for their classmates and themselves, so it's a good time to start choosing images that they like from the gallery and practicing adding them to a page.

#### Coding Time (5-8 mins)

If students are struggling to complete the level, check for spelling on `img` and `src`, check for a valid URL (in quote marks) to an image type file for the `src`.


### The `width` and `height` Attributes
We don't always want images to show up on a page full-size. The `height` and `width` attributes give us the flexibility to resize images for display.

#### Instructive Activity: Goldilocks and the Three IMGs (8-12 mins)

Remember the `img` tag? Who can tell me the parts of that tag? (img, src=, and the URL for the image in quote marks)

`<img src="http://www.codecombat.com/hero.jpg"/>`

Remember that `src` is an *attribute* of `img`. We're going to add a couple of other attributes that will tell our browser more about how to display this image -- `height` and `width`

`<img src="http://www.codecombat.com/hero.jpg" height="100" width="100"/>`

Adding these attributes works the same way as `src` -- type the name of the attribute and then an equals-sign, and then the value of the height or width in quotes. All of this goes inside of the tag.

*Draw a square on the whiteboard to represent the image, and write a 100 along one of the vertical sides and one of the horizontal sides of the square to indicate that it is 100 tall and 100 wide*

```
			100
	 -------------------
	|				  |
	|				  |
	|				  |
100 |				  |
	|				  |
	|				  |
	|__________________|

```

Quick note: all images need to have a `src` attribute, but `height` and `width` are optional. Later on, when we start looking at CSS, we'll also learn other ways to set the size of images on our page.

#### Interact (5-7 mins)

Have the students select images from the CodeCombat gallery (upper right side of the page, above the editor) and add them to a blank page in the editor. Each student should add at least 3 images.

Instruct them to add `height` and `width` attributes to each image.

- First image: height of 100, width of 200
- Second image: height of 200, width of 100
- Third image: height of 100, width of 100

If students finish early, have them take one or both of the size attributes off of the tag and report their findings on what they learned about using only one value.

Circulate to assist; the most common issues with this exercise tend to be spelling (it's surprisingly easy to mis-spell "height!") and closing quote-marks around attributes.


#### Coding Time (5-8 mins)
As with the first module, if students are struggling to complete the level, check for spelling on `img` and `src` (and now `height` and `width`, check for a valid URL (in quote marks) to an image type file for the `src`.


##### Module 3
## Organization


### Summary

TODO: Why do we need to organize HTML docs

### Transfer Goals

- Divide an HTML page into sections using the `<div>` tag
- Craft an unordered list using `<ul>` and `<li>` tags
- Craft an ordered list using `<ol>` and `<li>` tags


### Organizing with `<div>` Tags

The `<div>` tag helps us organize pieces of content. It's a building block that we'll be using when we start styling sections of the page, so the level that reinforces this tag has some built-in styles for visual clarity.


#### Instructive Activity: Slice and Dice (11-15 mins)

We've added a bunch of different kinds of content to our pages so far. Who wants to recap what elements we've used? (line break, paragraph, headers, images, lists)

When we're making web pages, we don't just want to add things randomly -- we want to organize our content into sections. We can do a little bit of that with some `<br>` tags and headers, but the `<div>` tag lets us groups items into those sections. Later on, when we add styles to the page (like background colors and borders), we might want to apply these styles to a whole section at once.

Wrapping things in a `<div>` tag looks like this:

```
<div>
<h2>My Latest Quest</h2>
<p>This week, I had many adventures.</p>
<p>I also bought new boots!</p>
</div>
```

The opening `<div>` tag goes before the first thing we want to group together (the `<h2>`) and the closing one goes after the last thing in the group (the second `<p>`). Now, all three of those items will be collected together in one `<div>` and we can treat them as one big rolled-up item.

#### Interact (8-10 mins)

Have the students work in small groups to create a "classified ads" page for used hero equipment, using content wrapped in divs.

Each div should contain:
- The name of the item for sale (as a header)
- The price (as a smaller header or paragraph text)
- A description of the item

There should be at least 3 items for sale on the page.

Circulate as students are working, make sure they're closing all tags and that the opening and closing `<div>` tags are outside of the div group contents.

#### Coding Time (5-8 mins)
If students are struggling to complete the level, check for opening and closing tag consistency.


### Unordered Lists (The `<ul>` and `<li>` Tags)

Unordered lists are bulleted lists. They consist of a `<ul>` group that contains a set of `<li>` (list item) tags.

#### Instructive Activity: Out of Order (10-15 mins)

*Start by writing a list of items on the whiteboard*

```
Hero Skills

swordfighting
archery
potion-making
animal training
```

Sometimes, we want to group items into a bulleted list instead of just having a line break in between those items. There are all kinds of situations that we might use these for -- to-do lists, shopping lists, descriptions of things -- and HTML gives us a tool for creating bulleted lists.

It's called `<ul>`, which stands for *unordered list*.

The `<ul>` tag is just the bucket that the list items live in. Each thing that you want to put on the list goes in another tag, called `<li>`, which stands for *list item*.

One of the things you'll want to pay attention to is making sure that all of your `<li>` tags are closed, and that they're all inside of the `<ul>` and the `</ul>`.

Let's take this set of basic hero skills on the whiteboard and turn it into an unordered list.

*Add a `<ul>` tag to the outside of the list, and wrap each item in `<li>` tags. Wrap the header in `<h2>` tags.*

```
<h2>Hero Skills</h2>
<ul>
<li>swordfighting</li>
<li>archery</li>
<li>potion-making</li>
<li>animal training</li>
</ul>
```

#### Interact (5-8 mins)

Have the students work in small groups to create hero shopping lists, using unordered lists to keep track of all of the items their hero may want to purchase for adventuring.

Each list should contain:
- A header, so we know what the list is for
- Opening and closing `<ul>` tags, so we know it's an unordered list
- At least 5 `<li>` tags with items


Circulate as students are working, make sure they're closing all tags and that the opening and closing `<ul>` tags are outside of the `<li>` items.

#### Coding Time (5-8 mins)
If students are struggling to complete the level, check for opening and closing tag consistency.


### Ordered Lists (The `<ol>` Tag)
Ordered lists are very similar in structure to ordered lists, but instead of bullet points, these lists are numbered. They consist of a `<ol>` group that contains a set of `<li>` (list item) tags.

#### Instructive Activity: One at a Time (12-18 mins)

*Start by writing a list of items on the whiteboard*

```
Adventure To-Do's

1. Pack bags
2. Venture out into the wild
3. Fight enemies
4. Find treasure
5. Take a nap
```

Bulleted lists are pretty great, but they aren't the only kind of list. Sometimes, we want to list items in order, with numbers to let us know more information about the items in a list -- leaderboards for a game, or the order of steps in a recipe, for example.

The *ordered list* is a lot like the `<ul>`, but it gets the `<ol>` tag so we know that it'll show up in the browser with numbers instead of bullet points.

Just like with unordered lists, each item you want to put on the list goes in an `<li>` tag inside of the `<ol>` tags.

One of the things you'll want to pay attention to is making sure that all of your `<li>` tags are closed, and that they're all inside of the `<ol>` and the `</ol>`.

There's a to-do list on the whiteboard with our hero's actions already in order -- let's put the correct tags in place so these numbers would show up in the browser without us having to separately write them inside of the `<li>`.

*Add a `<ol>` tag to the outside of the list, and wrap each item in `<li>` tags. Erase the numbers before each item. Wrap the header in `<h2>` tags.*

```
<h2>Adventure To-Do's</h2>
<ol>
<li>Pack bags</li>
<li>Venture out into the wild</li>
<li>Fight enemies</li>
<li>Find treasure</li>
<li>Take a nap</li>
</ol>
```

#### Interact (5-8 mins)

Have the students work in small groups to create ranking lists for the hardest monsters to beat, using ordered lists to organize the order of these items.

Each student should make a top 5 list, then each small group should compare and combine lists into one big ranking list.

Each list should contain:
- A header, so we know what the list is for
- Opening and closing `<ol>` tags, so we know it's an ordered list
- At least 5 `<li>` tags with items, in numerical order


Circulate as students are working, make sure they're closing all tags and that the opening and closing `<ol>` tags are outside of the `<li>` items.


#### Reflect (2 mins)

**What might you use a `<ul>` (unordered list) for? What might you use an `<ol>` (ordered list) for? How are they similar?**
> I would use an `<ol>` when the numbers and order are important, and I would use a `<ul>` if order wasn't that important and I wanted bullet points. They are similar because both of them are lists that contain `<li>` tags.

### Coding Time (5-8 mins)

If students are struggling to complete the level, check for opening and closing tag consistency.




##### Module 4
## CSS Syntax

### Summary

This module provides an introduction to **CSS**, or **C**ascading **S**tyle **S** heets -- a means for adding styles to a web page, Styles can include colors, fonts, borders, alignment, positioning, and more. We'll be taking an introductory pass at using the `<style>` tag and some simple style rules.

### Transfer Goals

- Add style rules to an HTML page using the `<style>` tag and CSS rules
- Apply these styles to elements on the page


### The `<style>` Tag

#### Instructive Activity: Style By The Book (13-18 mins)

TODO: Add vocabulary about properties and values here.

Time to start stylng up our pages! There are a lot of ways to make a page or a section stand out, and many of those come from style rules. You can set colors, fonts, things like underlines, positioning, and more.

Styles can be added to an HTML page with the `<style>` tag. This one is a little bit different from some of the other tags we've worked with, for a couple of reasons:
- It contains CSS rules rather than text, images, or other tags.
- You only need to define the style once on a page (usually up at the top)
- You won't see anything on the page where the style tag is, but if you have elements on the page that match the style rules, you'll see how the styles get applied

Let's look at a sample style tag, then break it down into parts:

*write the following on the whiteboard*

```
<style>
    h1 {
        color: orange;
        text-align: center;
    }

    p {
        text-align: left;
        color: blue;
    }
</style>
```

First, let's break down what these two rules mean. We have a rule for the h1, which says that all of the `<h1>` header tags on our page will have two styles on them -- they'll be orange, and they'll be centered on the page. Then we have a rule for paragraph text, which says that all of the `<p>` tags on our page will be blue and align to the left. Any time we add a `<p>` or a `<h1>` to the page, it'll have those colors and alignments set.

Next, let's take a look at how the rules are written, so we can write our own.
In between the `<style>` tags, we see:
- the element the rule applies to
- an open curly-brace `{`
- the name of the property we want to set (like color, font-size, text-align, etc.), a colon `:` and then what we want to set it to (like orange, 12px, center, etc.), and then a semicolon `;`
- as many more rules as we want
- a close curly-brace `}`

So, for example, let's say we wanted to add another rule to the set above, and put a background color of light-blue on all of our `<div>`s, we would write it like this:

```
div {
    background-color: light-blue;
}
```
The rule lives inside `{`curly braces`}`, and the way we write it is with a colon `:` in between the name and the vaue, and a semicolon `;` at the end of the rule.

#### Interact (8-10 mins)

Have the students work in small groups to add HTML elements to a page (header tags, paragraph text, images, lists, divs, etc.) and then create at least 3 style rules to style these elements.

Some suggestions:
- Make headers and paragraph text stand out more by making them different `color`s.
- Divs are a great element to add `background-color` to, because the color will be there for all of the elements inside of the div, and the div will pop on the page.
- Take a look at the hints if you're stuck -- some of the style rules only apply to text, for example, so if you set `color` on an `img`, you might not see visible results.

Circulate to assist; the most common issues with CSS tend to be punctuation-related, and it's also good to take a look at

While students are working on this, remind them that they'll be making Wanted Posters, and it's a good idea to start thinking about styles now. More style rule tips are in the editor, in the hint section.

#### Coding Time (5-8 mins)
If students are struggling to complete the level, check for punctuation and placement of CSS rules, including proper usage of properties and values (for example, some properties can only have certain values used with them.)




##### Module 5
## CSS Selectors

### Summary

Classes help us style repeated elements much more easily; rather than styling all `<div>`s or `<p>`s a certain way, we might use classes to assign style rules only to elements that belong in a group.

### Transfer Goals

- Add a class to an element on an HTML page
- Craft a style rule for members of that class
- Add an id to an element on an HTML page
- Craft a style rule for that id

### CSS Classes

#### Instructive Activity: Top of the Class (12-18 mins)

By now, we're feeling pretty comfortable with creating new HTML elements with attributes, right? Today, we're going to take a look at another attribute that we can add to elements that will help us with styling -- `class`.

Let's say that we want more than one div on our page to look the same -- maybe a bright background color for all of the blog posts on a page -- but we don't want to put a rule on `div` because we might also have some other divs on the page that aren't supposed to have that background color. We can put these special divs into a group, called a `class`, and let our browser know that they're in that class by adding a class attribute to the tag.

Like this:
```
<div class="blog">
<h1>My Latest Adventure</h1>
<p>Let me tell you this story...</p>
</div>
```

We gave the div a class of `blog` by adding `class="blog"` to the opening tag, and now we can add special rules to it.

The style rules for classes are a little bit different than for regular elements. We have to tell the browser that we're making the rule for a class, and we use a dot `.` before the name in the rule to do that:

```
.blog {
	background-color: pink;
}
```

The rest of the rule looks just like other style rules. The only special thing we're doing here is adding the dot before *blog* so the browser knows to look for all of the elements on the page that belong to the blog class, and give them a pink background.

#### Interact (10-12) mins)

Have the students work in small groups to make a page of Hero Trading Cards, with a card for each student in the group. The divs that represent the cards should have classes, and there should be style rules for those classes.

A Hero Trading Card needs:
- An image representing each hero.
- Header text (any of the header tags) for the hero's name.
- A one-line catch phrase for the hero (`<p>`)
- A background color so we know what belongs to a card and what's on the rest of the page.
- Any other styles you want to apply
- Make sure to break apart the cards (hint: we have a tag for this)

#### Coding Time (5-8 mins)
If students are struggling to complete the level, check for proper class syntax, and opening and closing tag consistency.


### CSS IDs

IDs help us style unique elements much more easily; rather than styling all `<div>`s or `<p>`s a certain way, we might use classes to assign style rules only to a single element of that type.

#### Instructive Activity: One of a Kind (12-18 mins)

Classes were really awesome for things we wanted to repeat, like the hero trading card, or blog posts, or the character sections in the level. But what if something is super special and is the only thing on the page to get that style?

That's where `id`s come in.

Like this:
```
<ul>
<li>One fish</li>
<li>Two fish</li>
<li id="red">Red fish</li>
<li id="blue">Blue fish</li>
</ul>
```


We can make those "red fish" and "blue fish" items pop by giving them special colors, but since all of the `<li>` tags aren't going to get a color, and we aren't repeating red or blue, we'll use an `id` here.

We used a dot `.` to let the browser know that we were talking about classes when we set those styles. For `id`s, we'll put a `#` (hashtag) before the name in the rule to do that:

```
#red {
    color: red;
}
#blue {
    color: blue;
}
```

The important thing to remember with `id`s is that they're for one-time use. If you want to repeat the rule again, you might want to use a `class` instead.

#### Interact (15-20 mins)

In Module 11, students worked in small groups on Hero Trading Cards. Now, have everyone work individually to re-create the trading cards from the previous lesson, but apply special styles for their own card.

Each student should be able to:
- Create a page with several Hero Trading Cards (divs, images, text styled with classes) for the classmates that were in their group
- Add an `id` of their own name to the div for their card
- Create special style rules for their card that look different from the other cards


#### Coding Time (5-8 mins)
If students are struggling to complete the level, check for proper class syntax, and opening and closing tag consistency.

##### Module 6

### Final Project

The Wanted Poster can be used as an ongoing project throughout the second half of the modules; by the time students reach Level 13 in the game, they should be equipped to complete it. I thought about introducing it sooner, but don't want students to be fatigued on it, so I broke the other parts of the course into a couple of focused smaller projects for individual or group work. The instructor can seed the idea of the poster as soon as they feel it's appropriate, and assign sections of it as reinforcement work after students complete the base levels and mini-projects during Interact times.


My suggested grouping of lessons (obviously time-dependent and will vary from class to class) is:

- *Modules 1 - 4* in one session to get text onto the page and start recognizing basic HTML markup. No project throughline just yet, because the students will likely have more classes in between these basics and the more project-aligned topics, and there will be a lot of rewriting/overwriting for muscle memory (and because there's no save mechanism).

- *Modules 7 & 10* together (this is a departure from the level order, but I couldn't find anything in the levels that would be a mis-step if they got moved), with mini-projects about the different types of lists (small group work making a shopping list to get the hang of unordered lists, and a ranking list of the hardest monsters to beat to tackle ordered lists).

- *Modules 5, 6, 8, & 9* in the same session or back-to-back (may need to split because of duration, especially with the styling exercises). Module 9 has call-backs to 5 (attributes), and one of the best reasons to wrap things in a `<div>` is for styling, so 6 and 8 will flow nicely and set the stage for classes and ids up next. Modules 5, 8, and 9 are skills-practice and don't include specific mini-projects, but Module 6 features a brief small group project (using divs to make a "classified ads" page for hero equipment), The Wanted Poster project will be mentioned here so students can think about things they'd like to include, with requirements tightening up as 11 and 12 are taught.

- *Modules 11 & 12* together or back-to-back. After these modules, students should be able to complete the Wanted Poster in Level 13, so the focus here should be on synthesizing all of the previous concepts and taking them to the next level. The Interact portion of these modules involves more time spent working individually and in small groups; while earlier levels may have had small, singular focus, students should be prepared to write large portions of an HTML page from scratch, then take that page to the next level with the lessons from these modules.

- An entire class session to complete Level 13, with the opportunity to enhance it beyond the basic requirements if students finish quickly. Additional styles would be a great way to take this poster to the next level, and students have a lot of latitude in terms of how much they can differentiate their posters with CSS.
