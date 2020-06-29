###### Last updated: 09/14/2016

##### **课程计划**
# 计算机科学 2

### 课程概要
●        建议先修：计算机科学导论

●        4 x 45-60分钟编码课

#### 概述
学习了简单的程序结构和语法之后，学生们应该已经摩拳擦掌准备接触更进阶的内容了。条件结构、函数和事件将是接下来的内容，太棒了！计算机科学2会让学生从随便倒弄代码的阶段进入到真正编写软件和应用的阶段！

计算机科学2中，学生将继续熟悉基本语法、参数、字符串、变量、循环等基础知识，此外还会学到另外一些概念。If语句能够让学生基于战场上的不同状况采取不同的动作。函数能让学生将程序组织成可以重复利用的代码片段。能够写出基本函数之后，学生就能开始编写代码来处理事件了。这将是游戏开发、web开发和app开发中经常会用到的基本编码模式。


 *本课程为Python语言设计，不过也能够轻松适用于JavaScript。*

### 内容及学习顺序

| **模块**                                                     | **首关**       | **授课目标**                         |
| :----------------------------------------------------------- | :------------- | :----------------------------------- |
| [5.   条件结构 (if)](https://cn.codecombat.com/teachers/resources/cs2#conditionals-if-) | 平原森林保卫战 | 在执行之前判别表达式                 |
| [6.   条件结构 (else)](https://cn.codecombat.com/teachers/resources/cs2#conditionals-else-) | 背靠背         | 执行默认代码                         |
| [7.   嵌套条件结构](https://cn.codecombat.com/teachers/resources/cs2#nested-conditionals) | 跃火林中       | 将一个条件结构放到另一个条件结构之内 |
| [8.   函数](https://cn.codecombat.com/teachers/resources/cs2#functions) | 乡村漫游者     | 将具体代码留给以后                   |
| [9.   事件](https://cn.codecombat.com/teachers/resources/cs2#events) | 边地好伙伴     | 监听事件并执行代码                   |
| [10.   复习 – 多人竞技场](https://cn.codecombat.com/teachers/resources/cs2#review-multiplayer-arena) | 力量峰值       | 设计和实现算法                       |

### 核心词汇表
**对象 –** 执行动作的角色或事物。对象是Python的基本组成要素，是执行动作的角色或事物。hero是一个对象，能够执行移动动作。在hero.moveRight()中，对象就是hero。在课程2中，学生还将使用pet对象来执行动作。

**函数 –** 对象执行的动作。函数是对象可以做的动作。moveRight()是一个函数。函数名后总需要跟括号。

**参数 –** 函数需要的额外信息。参数是函数后括号内的内容，告诉函数动作方面的更多信息。hero.attack(enemy)中，enemy是参数。

**循环 –** 需要重复的代码。循环是重复执行代码的方式，一种编写循环结构的方式是使用关键字while，后面跟判别真假(True/False)的表达式。

**变量 –** 暂时存放数据的容器。变量将数据存储起来，便于日后使用。变量的创建需要起变量名，然后告诉它存放什么值。

**条件结构 –** 现代编程的一种基本组成要素。条件结构会判别条件，基于表达式的不同值来决定执行不同动作。玩家无法确认是否会有敌人攻击，也无法确认有没有可以抓取的宝石，这就需要判别这些东西是否存在。能力是否就绪、敌人是否存在都需要判别条件，确定执行不同动作。

**事件** – 表示发生了某事的对象。学生可以编写代码，来对事件作出反应：当这类事件发生了，执行这个函数。这叫作事件处理机制，它是很有用的编程方式，是对无限while循环的有益补充。


#### 较早完成课程2的学生可以额外进行如下活动:
●        帮助其他人

●        在“力量峰值”多人竞技场中完善策略

●        编写全部流程

●        编写对整个游戏的回顾评述

●        为最喜欢的关卡编写通关指南

●        设计一个新关卡



##### **模块5**
## 条件结构 (If)

### 概要

课程2引入了更加进阶的编程概念，因此关卡的通过不会像之前那么容易。留意关卡指示，确保知道关卡目标；留意代码中嵌入的注释（以#开头），确保知道代码里面有什么需要补充。

### 授课目标
●        构造条件结构

●        选择恰当的表达式

●        表达式求值

### 标准
**CCSS.Math.Practice.MP1** 理解问题寻求解答。

**CCSS.Math.Practice.MP2** 抽象和定量思想。

**CCSS.Math.Practice.MP4** 数学建模。

**CCSS.Math.Practice.MP7** 寻找和利用结构。

### 教学活动：条件结构（10分钟）
#### 讲解（2分钟）
条件结构基于游戏状态选择要执行的代码。首先需要求出表达式的值是真True还是假False，然后只在表达式为真True时执行后面的代码。注意到，其语法很类似于循环，后面需要有冒号和四格缩进。

`if`是关键字，`==` 部分是表达式：

``` python
if enemy == “Kratt”:
    attack(enemy)  # 这是动作
```

条件结构的关键字是`if`。条件结构本身只会执行一次，如果想要多次进行判别，你可以将它放到循环结构中，过程中要注意缩进。


``` python
while true:
    if enemy == “Kratt”:
        attack(enemy)
```

#### 互动（5分钟）
使用Python语法，将课堂规则改写为条件结构。

确定一些学校和课堂规则，将它们写在黑板上，例如：

●        举手才能问问题

●        如果迟到是会留校的

●        老师拍手两次时停止讲话

用如果（if）开头的句子，重写这些规则：

●        **如果**有问题，那么就要举手

●        **如果**迟到了，那么就要留校

●        **如果**老师拍手两次，那么就要停止讲话

然后使用Python语法重写：

``` python
if student.hasQuestion():
    student.raise(hand)
```
``` python
if student.arrivalTime > class.startTime:
    teacher.giveDetention(student)
```
``` python
if teacher.claps == 2:
    class.volume = 0
```

标出条件结构中的各部分：*关键字、表达式、动作*。

#### 讲解（1分钟）
代码是要将平时说的语言编码为计算机能够理解的语言。你总可以通过以上三步，将自己的想法改写成计算机语言。有了编程语言的语法之后，你就会知道这些代码应该是什么样子。

#### 思考（2分钟）
**我们为什么需要条件结构?** (并非所有动作都总是会发生) 

**If**和冒号之间的部分是什么? (表达式) 

**表达式很重要的一点是什么?**(其值要么为真，要么为假)




### 代码编写时间（30-45分钟）
让学生按自己的节奏进行游戏，在纸上或是电子文档中，记录每一关的日志。我们推荐如下格式，你可以将其打印出来作为模板：[学习日志 [PDF]](http://files.codecombat.com/docs/resources/ProgressJournal.pdf)

```
关卡 #: _____  关卡名: ____________________________________
目标: __________________________________________________________
我做了什么:

我学到了什么:

挑战在哪里:


```

在课堂上巡视，为学生提供帮助，让学生注意到指示和提示。学生需要使用(x,y)坐标来明确位置。将鼠标指针放到目标位置上就可以得到确切坐标了。学生还需要在执行动作前进行条件判别，通过条件结构来确定是否执行动作。



### 书面思考题（5分钟）
**If是什么意思？If后面应该写些什么？**

>If does the code only if it’s true. You can see if all kinds of things are true, like if your weapon is ready or if the enemy is close. Sometimes you need == or >, but sometimes you only need the ().

**如果要你设计一个CodeCombat关卡，它会是怎样的？**

>会有很多食人魔，你需要攻击他们，但不能攻击人类。你还需要通过建造障碍物和火焰陷阱来保护村子。
>
>


##### **模块6**
## 条件结构 (Else)
### 概要

这些关卡都需要同时考虑两件事。学生需要确定什么情况下执行哪个动作。这个阶段适合秘诀技巧讨论，让学生有机会在课上分享他们的发现或是窍门。

### 授课目标
●        构造一个`if-else`条件结构

●        确定不同条件下执行的不同动作

●        定义`else`，在`if`不成立时执行

### 标准
**CCSS.Math.Practice.MP1** 理解问题寻求解答。

**CCSS.Math.Practice.MP2** 抽象和定量思想。

**CCSS.Math.Practice.MP7** 寻找和利用结构。 

**CCSS.Math.Practice.MP8** 寻找并表达重复性思想的规则性。

### 教学活动：条件结构 (Else)（10分钟）

#### 讲解（2分钟）
我们已经熟悉表达式为真`true`时执行动作的条件结构，但如果表达式为假`false`怎么办呢？这就需要用到`else`了。`else`是“否则”、“如果不”、“相反”的意思。

注意到，`else` 需要同`if`有相同数目的缩进，而且也和`if`一样后面需要跟冒号`:`。

下面的例子中，`if` 和 `else` 是关键字，`==` 是表达式内容：

``` python
if today == weekday:
    goToSchool() # 动作
else:  # 关键字
    watchCartoons() # 动作
```


#### 互动（6分钟）
回顾上一课的课堂规则内容，看是不是需要else语句，例如：

``` python
if student.hasQuestion():
    student.raise(hand)
else:
    student.payAttention()
```

``` python
if student.arrivalTime > class.startTime:
    teacher.giveDetention(student)
else:
    teacher.markPresent(student)
```

``` python
if teacher.claps == 2:
    class.volume = 0
#  这里不需要else，因为老师不拍手的情况下不需要执行任何动作
```

标出条件结构中的各部分：*关键字*(`if`与 `else`)*、表达式、动作*。

#### 思考（2分钟）
**Else是什么意思？**(如果不、否则)

**为什么else后不需要另一个表达式？** (表达式已经隐含在前面了，也就是前面if的表达式不成立时)

**Else是否总要有？** (不，有没有要看具体情况)

### 代码编写时间（30-45分钟）
让学生按自己的节奏进行游戏，在纸上或是电子文档中，记录每一关的日志。我们推荐如下格式，你可以将其打印出来作为模板：[学习日志 [PDF]](http://files.codecombat.com/docs/resources/ProgressJournal.pdf)

```
关卡 #: _____  关卡名: ____________________________________
目标: __________________________________________________________
我做了什么:

我学到了什么:

挑战在哪里:


```

在课堂上巡视，为学生提供帮助，让学生注意到指示和提示。这些关卡的关键在于确定什么事情需要发生，以及什么情况下发生。学生们需要在各种条件下选择最佳动作，需要学会在这个过程中享受多种可能性所带来的乐趣。

### 书面思考题（5分钟）
**现在你有没有比一开始了解了更多代码？现在你比一开始多拥有了什么额外的能力？**

>一开始，我只能到处走动。现在我可以攻击敌人并看到谁最近。我还可以将鼠标放到屏幕上，确定目的地的坐标。我可以使用if和else来做两件不同的事。我可以使用循环来让代码重复执行。

**有什么建议给刚开始玩游戏的人？**

>阅读指示，首先确定要做什么，然后再操心代码的事。while True和if后面需要记得冒号:，之后还需要四格缩进。大多数时候，关卡都会用蓝字告诉你做什么，你照做就行了。你可以使用宝石来买东西。

**卡住时你怎么做？**

>我问旁边的人有没有过这一关。如果我比较超前，我会再考虑一下直到对方追上我的进度，然后我们再一起研究。我也可以去问老师。有时答案就在帮助或是蓝字中。

##### **模块7**
## 嵌套条件结构
### 概要

严肃的编程现在开始。学生们需要记住如何构造条件结构及表达式，不熟的话要多看代码编辑器下的提示。这些关卡有三个或以上的动作要控制，需要复合思维及规划。代码最多会有三层缩进，确保空格数量正确对于代码运行是至关重要的。

### 授课目标
●        构造嵌套条件结构

●        阅读并理解嵌套条件结构

●        处理好缩进

### 标准
**CCSS.Math.Practice.MP1** 理解问题寻求解答。

**CCSS.Math.Practice.MP2** 抽象和定量思想。

**CCSS.Math.Practice.MP6** 致力于精准度。

 **CCSS.Math.Practice.MP7** 寻找和利用结构。

### 教学活动：嵌套条件结构（10分钟）

#### 讲解（3分钟）
一开始，我们用条件结构判别一个表达式，确定是否采取某一动作。之后，我们考虑两个动作，确定执行哪一个。不过有些时候，要做的事情会多于两个，这就需要将一个条件结构嵌套在另一个条件结构中。

下面例子中：第一个条件结构判断的是，`if 是不是周末`；第二个条件结构（即嵌套条件结构）判断的是，`if 有没有足球比赛`。

``` python
if it’s a weekend:
    if I have a soccer game:
        Wake up at 6
    else:
        Sleep in
else:
    Wake up at 7
```

缩进现在就非常重要了。一层循环或条件结构中需要四格缩进，这要包括之内的其他条件结构，因此内部的条件结构需要总共缩进八格。

#### 活动（5分钟）
让学生将自己的起床、入睡或休息时间规则写成嵌套条件结构的形式。做至少三个不同的动作，这是使用嵌套条件结构所必须的。

学生完成之后，让其与同伴交换，相互阅读和讨论所写内容，检查语法和缩进。

邀请自愿者，与全班分享其成果。

#### 思考（2分钟）
**我们为什么需要嵌套条件结构?** (因为可能的情况和要执行的动作有时会多于两种) 

**为什么第二个条件结构需要额外缩进四格?** (这样才能体现它在第一个条件结构之内) 

**某个动作缩进八格意味着什么?** (它是否执行取决于两个表达式的真假判断)

### 代码编写时间（30-45分钟）
让学生按自己的节奏进行游戏，在纸上或是电子文档中，记录每一关的日志。我们推荐如下格式，你可以将其打印出来作为模板：[学习日志 [PDF]](http://files.codecombat.com/docs/resources/ProgressJournal.pdf)

```
关卡 #: _____  关卡名: ____________________________________
目标: __________________________________________________________
我做了什么:

我学到了什么:

挑战在哪里:


```

在课堂上巡视，为学生提供帮助。确保学生们在开始编写代码之前，阅读了初始代码中的注释。目标比较复杂，将目标分解并理解每一个子目标是很重要的。鼓励学生之间的协同合作和相互帮助。

### 书面思考题（5分钟）
**给我讲讲劈斩cleave。**

>劈斩会击溃周围的大量敌人，代码是`hero.cleave()`。后面要记得`()`，不过括号后不需要参数，不需要`cleave(enemy)`，因为攻击目标是周围所有人。劈斩有一段冷却时间，因此使用之前要检查它是否准备就绪，如果没有就绪就只能使用普通攻击。

**讨论：你的英雄是好人还是坏人？**

>我的英雄可以说是好人，也可以说是坏人。从保护村民上来讲他是好人，但从偷取宝石来讲他是坏人，而且杀敌也是杀戮。要是保护村民不需要通过杀戮和偷盗来实现就好了。

### 书面查核点：条件结构

**什么是条件结构？条件结构有哪些不同的方式？举例说明。**

>条件结构也就是包含if的结构，如果某条件为真就做某动作。如果在条件为假时还需要做别的动作，那就要使用else。如果还有第三个动作可以做，那就要用elif，如：如果(if)下雨就穿夹克，否则的话如果(elif)下雪就戴帽子，否则(else)就穿T恤。此外，if还可以嵌套在其他if之内，这时需要记得缩进数量不能错。

**什么是elif？它是elf(精灵)吗？**

>Elif表示else if（否则如果），用它可以在三个动作中做选择，而不是两个动作中做选择。它和elf(精灵)很像，因为它很巧妙。

**讲讲缩进。**

>while True、if、else、elif内，代码都需要四格缩进。如果if内还有另一个if，那就需要八格缩进。数清楚空格数量是非常重要的，否则计算机就不知道该做什么。这里务必要小心。


##### **模块8**
## 函数
### 概要
这些关卡为学生提供了某种捷径。之前循环让学生能够更快地执行更多代码，这里函数也一样，它能让学生反复使用相同代码。语法仍然至关重要，注意冒号和缩进。开始编写代码之前，记得让学生阅读并理解关卡的指示说明。

### 授课目标
●        辨认函数

●        定义函数

●        调用函数

### 标准
**CCSS.Math.Practice.MP1** 理解问题寻求解答。

**CCSS.Math.Practice.MP2** 抽象和定量思想。

**CCSS.Math.Practice.MP7** 寻找和利用结构。

### 教学活动：函数（10分钟）
#### 讲解
其实之前你已经用过函数了！例如`hero.cleave()`中，`cleave()`就是函数。之前你用的都是内建函数，后面你将可以编写你自己的函数。编写函数首先需要使用`def`来定义函数。

``` python
def getReady():
    hero.wash(face)
    hero.brush(teeth)
    hero.putOn(armor)
```

然后是调用函数。

``` python
getReady()
```

**定义和调用之间有什么区别？** (定义需要在前面使用`def`，后面使用冒号`:`，中间还需要一些缩进的代码。它们都有括号。)

程序员使用函数让代码更易读易写。这就像是篮球中的整套动作：你知道如何投篮、带球、传球，你将各部分组合到一起，然后给它取个名字（out-over-up带传射）。

``` python
def out-over-up():
    p1.dribble()
    p1.pass(p2)
    p2.shoot()
```

教练想要这一串动作被执行时，只需要喊 “Out-over-up!”就行了。

### 互动（5分钟）
**Simon Says.**

课上使用Python语法，在黑板上编写你自己的函数，然后用Simon Says游戏方式和学生互动。以下是一些例子：

``` python
def pogo():
    student.handsOn(hips)
    student.jump()
```

``` python
def popcorn():
    if student.sittingDown():
        student.standUp()
    else:
        student.sitDown()
```

然后通过调用函数来玩Simon Says游戏，例如：
- Simon says raise your hand! （举手）
- Simon says popcorn!
- Pogo! (Simon什么都没说)

### 思考（2分钟）
**为什么函数能让编码更简单？** (因为复杂的步骤不需要每次都写出来，只需要写出函数名就行了) 

**为什么说给函数取个好名字很重要？** (这样以后就不会忘了它是做什么的) 

**关键字`def`表示的是什么？** (define，定义)

### 代码编写时间（30-45分钟）
让学生按自己的节奏进行游戏，在纸上或是电子文档中，记录每一关的日志。我们推荐如下格式，你可以将其打印出来作为模板：[学习日志 [PDF]](http://files.codecombat.com/docs/resources/ProgressJournal.pdf)

```
关卡 #: _____  关卡名: ____________________________________
目标: __________________________________________________________
我做了什么:

我学到了什么:

挑战在哪里:


```

在课堂上巡视，为学生提供帮助，让学生注意到指示和提示。这些关卡都需要编写好的代码。给学生的帮助代码中间经常会写有`pass`，这是为了让示例代码中不显示错误。学生填入了自己的代码后，`pass `就需要删掉。在帮助学生调试代码之前，先看看是不是`pass `的问题。

### 书面思考题（5分钟）

**为什么说函数很有用？什么时候没必要使用函数？**

>有了函数，相同代码就不需要写一遍又一遍，函数能让代码更易读。如果函数中只有一行代码，那就没必要使用函数了，每次直接写出那一行会更省事。


##### **模块9**
## 事件
### 概要
**事件**是表示发生了某事的对象。学生可以编写代码，来对事件作出反应：当这类事件发生了，执行这个函数。这叫作事件处理机制，它是很有用的编程方式，是对无限while循环的有益补充。

### 授课目标
●        监听事件并执行代码

●        使用事件处理来控制宠物

●        将直接执行和事件处理混在一起编写代码

### 教学活动：总统老师（12分钟）
#### 讲解（2分钟）
之前，你学习了从上到下一次性执行的代码：*首先做这个，然后做这个，再做那个*…你还学习了while循环的编写，你可以说：*这个一直做下去*。现在你要学习使用事件处理：**当***这个发生**时**，执行那个*。它和if语句有点像，只是事件可以在任何时候发生，不需要只发生在判别条件时。

#### 互动（8分钟）
给班上讲，你在等白宫的一通重要电话，电话会通知你是否被选为下一任美国总统。你要用while循环和if语句来编写接电话的程序，暂时还没用到事件：

``` python
while True:
    if phone.isRinging:
        teacher.answer(phone)
```

这很无聊，只等电话什么都没做。你打算在等待过程中批改学生作业：

``` python
while True:
    paper = teacher.findNextPaper()
    teacher.grade(paper)
    if phone.isRinging:
        teacher.answer(phone)
```

每份作业需要五分钟批改。问学生们，如果按照以上程序执行，白宫打来电话会怎么样。（白宫打来电话的时候，你可能正在批改作业。你只会每五分钟查看电话是否响起，这就很可能错过了当选总统的电话。）

下面用事件处理来重写程序，你会**监听**事件，当事件发生时你会通过运行一个函数来**处理**事件：

``` python
def answerPhone():
    teacher.answer(phone)

phone.on("ring", answerPhone)
```

给学生们解释，以上程序的意思是一旦(`on`)电话`phone`响起`ring`，就运行`answerPhone`函数。之后就是在等待中批改作业，只需要加一个while循环就行了。事件发生时，你的批改就会被打断，这样你就能够接到电话成为总统了：

``` python
def answerPhone():
    teacher.answer(phone)

phone.on("ring", answerPhone)
while True:
    paper = teacher.findNextPaper()
    teacher.grade(paper)
```

给学生们解释，`phone.on("ring",answerPhone)`会让代码开始监听电话响`"ring"`这一事件。注意到，函数后面**不使用括号**：是`answerPhone`而非`answerPhone()`。这是因为，这里只是告诉代码要运行的函数的函数名，而**不是立刻运行**。（括号会让函数立刻运行。）

让学生们举更多事件和处理函数的例子，并将它们写到黑板上，例如下面这样：

``` python
student.on("wake", goBackToSleep)
dog.on("hear", obeyMaster)
goal.on("touchBall", increaseScore)
bigRedButton.on("press", initiateSelfDestruct)
```


#### 思考（2分钟）
**事件处理用于什么?** (在某件事发生时运行一个函数) 

**事件名是什么类型的数据?** (事件名是字符串)

 **监听事件时，使用的函数后面为什么不加括号?** (括号会让函数立刻运行，你不希望这样，你要的是事件发生后才运行)

### 代码编写时间（30-45分钟）
让学生按自己的节奏进行游戏，在纸上或是电子文档中，记录每一关的日志。我们推荐如下格式，你可以将其打印出来作为模板：[学习日志 [PDF]](http://files.codecombat.com/docs/resources/ProgressJournal.pdf)

```
关卡 #: _____   关卡名: ____________________________________
目标: __________________________________________________________
我做了什么:

我学到了什么:

挑战在哪里:


```

在课堂上巡视，为学生提供帮助，让学生注意到指示和提示。确保学生们在开始监听事件之前编写出处理事件的函数。事件发生时的执行顺序可能有点难于把握（学生可能不知道是默认程序在运行还是事件处理函数在运行），让学生看看白色高亮显示的代码执行，这样他们就能知道每次在运行哪一行代码。


### 书面思考题（5分钟）
根据学生笔记中的内容，选择合适的问题。

**给我讲讲猫。**

>我有一只宠物猫，它是一只美洲狮。有一个函数会喵喵叫。猫会等到你跟它讲话时才喵喵叫。我认为它还应该帮助你抵御敌人，你需要通过命令让它做别的事情，例如扑击和撕咬。

**事件在游戏开发中非常有用，举出三种游戏中可能会发生的事件。**

>在“我的世界”中，爬行者爆炸时会触发“爆炸”事件。象棋中会有“将军”事件。“宝石迷阵”中，会有"combo"事件。



##### **模块10**

## 复习 – 多人竞技场
### 概要

竞技场关卡是完成这部分内容的一个奖励。在之前关卡中掉队或是书面思考题没完成的学生，可以利用这个时间来完成。已经成功提交课业的学生，可以进入力量峰值竞技场，在到时间前尝试多种解决方案。

更多细节参阅[竞技场关卡指南](https://cn.codecombat.com/teachers/resources/arenas)。


#### 授课目标

●        设计算法来解决问题

●        在Python中实现算法

●        调试Python程序

#### 标准

**CCSS.Math.Practice.MP1** 理解问题寻求解答。

**CCSS.Math.Practice.MP2** 抽象和定量思想。

**CCSS.Math.Practice.MP3**合理论证并评价他人思路。

**CCSS.Math.Practice.MP5** 高屋建瓴地使用恰当工具。

**CCSS.Math.Practice.MP6** 致力于精准度。

### Opening Discussion (5 minutes): _Introduction to Arenas_

#### Explain

Tell students that they're going to put all their learning together today in a special activity called an Arena. Explain and demonstrate how the Arena works, making sure to cover the following points:

- They'll be writing an artificial intelligence program to beat a complicated level in a race against an opponent. They'll test and revise their program over and over the get the best time they can. Encourage them to submit code, observe the output, and look for places where revisions could help a goal to be achieved more quickly, help a player to stay alive longer, etc. Then they should make the changes and submit again, as many times as they like.
- First, they should click to select the Red (Human) or Blue (Ogre) team. (We suggest randomly assigning half of the students to each team.)
- The first time they play, they should choose "Warm-Up" to play against the computer. They should keep revising and improving their program until it is good enough to beat the computer.
- Once they beat the computer, they can choose "Easy" to play against their classmates.

#### Review the Engineering Cycle

Remind students that engineering is all about solving problems, and the first rule of engineering is that no one gets it right the first time. That’s where the Engineering Cycle comes in:

DECOMPOSE: Understand and break apart the problem. What is the goal of the level? What smaller goals do you see along the way?  
PLAN: Choose one part of the problem to solve first. What do you need the computer to do? Plan a solution in plain English or pseudocode. Use a flowchart or storyboard to stay organized.   
IMPLEMENT: Write the solution to each part of your problem in code. 
TEST: Run your code! Does it solve the problem the way you intended? If not, redesign. Does it work without errors? If not, trace through it to find and fix the bug(s), then test again. Once it works, move on to the planning and implementing the next part! 

Provide each student with a copy of the [Engineering Cycle Worksheet](http://files.codecombat.com/docs/resources/EngineeringCycleWorksheet.pdf) that they can use to plan their program once they navigate to the level. 


#### Discuss
Use one or more of the following discussion questions to help prepare students for success:

**What steps will you follow to plan and create your program?**

Sample Responses:
> I'll use the Engineering Cycle. I'll decompose the problem by finding the big goal and breaking it into smaller subgoals. I'll choose one subgoal to start with and plan out an algorithm to solve it. Then I'll write my algorithm in code, and start testing and debugging until it works the way I want it to. 

**What will you do if your program doesn't beat the computer the first time?**

Sample Response:
> If it doesn't work, I'll rerun it and watch to see where it goes wrong, then I'll try to find a way to improve that part and resubmit the code. If it still doesn't work, I'll try it again!

### Coding Time (40-50 mins)

Have students navigate to the last level, **Power Peak**. They should take a few minutes to complete the Engineering Cycle Worksheet, then complete the level at their own pace.  Circulate and assist as they work.


#### Good to Know

- Some students may be uncomfortable with competition, especially given that the rankings are visible to the class. Consider using Pair Programming - competition is often more comfortable when you have a partner.
- Students will only compete against the AI and other students in the same CodeCombat class (not strangers).
- Once students have beaten one of the AIs, they will be put into the class rankings.
- Red teams only fight against blue teams, and there will be top rankings for each.
- Once students have submitted code, other students can click the “Fight” link next to any student in the ranking to challenge that student!
- If you leave your teacher account on the arena ladder page, it will simulate more matches between your students.

#### Look Out For:
- The Arena is more open-ended than the regular levels. If students are unsure of how to get started, remind them that programming is an iterative process and guide them toward decomposing the problem into simpler pieces, planning a solution for just one part of the level at a time.
- If a student is frustrated at losing, encourage them to analyze the winning player's strategy. What can they learn from it, and how can they use it to improve the next iteration of their own code?

### Closure (5 minutes)

Use one or more of the following questions to prompt reflection on the lesson. You can facilitate a short discussion, or have students submit written responses on Exit Tickets.

**In CodeCombat, you have to plan all your hero's actions in advance, then let the hero carry them out all at once. This is  different from most video games, where you directly control the hero and make decisions as you go. How do you feel about the difference? For example, which is more fun? Which is harder? How does your strategy change? How do you handle mistakes?**

Sample Responses:
> CodeCombat is harder because I have to think so many steps ahead! It's a fun kind of hard!

> In this game, I get to look through the whole level first and plan out how I want to beat it. Then I get to design a way to make my plan work. It feels different than making it up as I go along in regular video games.

**What did you do when your code didn't beat your opponent? How did you decide what changes to make?**

Sample Response:

> I reran the code and watched to see if I could take any shortcuts. Then I changed the code and ran it again to see if it helped.

> I looked for ways to stay alive longer. I called more friends to help and picked up more potion. Adding those things to my program helped me make it to the end.
