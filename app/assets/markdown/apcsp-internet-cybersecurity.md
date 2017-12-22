##### Activity
# Cybersecurity
Inquiry Activity

### Learning Objectives:
- [LO 6.3.1] Identify existing cybersecurity concerns and potential options to address these issues with the Internet and the systems built on it. [P1]
- [LO 7.1.2] Explain how people participate in a problem-solving process that scales. [P4]

## Preparation

Before class,find a short article or video describing a cyberattack that has been in the news recently, or use one of these:
- 2016 Election Interference: https://www.cbsnews.com/news/dhs-official-election-systems-in-21-states-were-targeted-in-russia-cyber-attacks/ 
- HBO cyber attack: http://www.newsweek.com/hbo-cyberattack-sony-hack-leak-game-thrones-645450 
- Global ransomware attack: https://www.nytimes.com/2017/06/27/technology/global-ransomware-hack-what-we-know-and-dont-know.html?mcubz=0 

## Discuss Cyber Attacks 
Discuss the cyberattack. Ask the students if they have heard of the cyberattack. Let them share what they know about it already and guide the class discussion:
- How did we find out about this attack? 
- What is the impact of this attack?
- How can we defend ourselves against this kind of attack?

## Phishing Scams

Show the students an image of a phishing email (a spam email that prompts you to login with your email and password). 

<img alt="phishing scam" src="/images/pages/teachers/resources/markdown/phishing-scam.jpg" id="phishing-scam" />

Ask the students what they would do if they received this email. Point out that although the email may seem legitimate it is in fact an example of phishing. Phishing is a form of cyber attacks in which seemingly legitimate emails are used to collect personal information from unsuspecting recipients. 

Now ask the students if they can figure out how you were able to tell that  was illegitimate. The reason is because the site is http instead of https. Hyper Text Transfer Protocol (HTTP) and Hyper Text Transfer Protocol Secure (HTTPS) are two protocols used to transfer information between devices on the Internet. The difference between the two lies in the last letter, S. The S stands for secure, referring to the encryption used to transfer information on the site. Secure Socket Layer (SSL) is the standard technology used to encrypt the data between browsers and servers on the Internet. It uses both symmatric and assymetric encryption. Symmetric encryption is when you use one key to encrypt and decrypt. Assymetric is when you use one key to encrypt (a public key) and another to decrypt (a private key). When your browser accesses a site through HTTPS, it creates a message with the site’s public key, which only the site can decrypt with its private key. This message the browser sends includes information for generating a secret symmetric key which the two machines can then use to pass information privately back and forth. This process is called a handshake. For added security, your browser will only initiate this handshake if the site has a certificate issued by a trusted certificate authority. You can use your browser to look up certificate information for any site which is served through HTTPS. When your browser warns you a site is not secure, it usually means it has an invalid or expired certificate.

Many phishing attackers create fake sites that mimic the name of the company but are http  rather than https sites. As the students have seen by now, creating a website is not very hard. Attackers can copy images from the company’s website and create something that looks nearly identical. They then can access the unencrypted information submitted by the user. 

## Distributed Denial of Service Attacks

A Distributed Denial of Service (DDoS) is a cyber attack in which a multiple devices attack an online service, overwhelming it to the point that it can no longer work. This kind of attack is often used by groups wishing to bring down websites as a form of protest.
Share the following article with the students, https://www.wired.com/story/reaper-iot-botnet-infected-million-networks/. Have a class discussion about the article and note that the acceptance of these kinds of attacks is under debate. Also be sure to discuss the impact of having multiple people participate in the attack.

## Reflection

Finally, give the students this assignment to begin in class and finish for homework. They should investigate a cyber attack on their own and write about it. Remind them to be sure that they choose trustworthy websites as a sources. Have them write a one page response to the following questions:

- What kind of attack is this?
- How was it discovered?
- Who was it targeting?
- What was the damage?
- How can it be defended against?

### Assessment Questions:
- What are some effects of cyberwarfare and cybercrime? [EK 6.3.1C]
- What is DDoS? [EK 6.3.1D]
- What is public key encryption? [EK 6.3.1L]
