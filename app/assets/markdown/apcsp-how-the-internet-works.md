##### Activity
# How the Internet Works
Inquiry Activity
 
### AP Computer Science Principles: Learning Objectives:

- [LO 6.1.1] Explain the abstractions in the Internet and how the Internet functions. [P3]
- [LO 6.2.1] Explain characteristics of the Internet and the systems built on it. [P5]
- [LO 6.2.2] Explain how the characteristics of the Internet influence the systems built on it. [P4]
 
## How does the Internet Work? 
 
Begin by giving students 3-5 minutes to write down how they think the internet works. Have two or three students share their thoughts. For now, don’t focus on letting them know if they are right or wrong - instead allow them to simply share their differing views with the class.

## Internet Protocol (IP) Address

Ask the students who has heard of an IP address before. Feel free to let students quickly discuss what they think an IP address is. Share the following definition by either writing it on the board or projecting a slide of it:

An Internet Protocol (IP) address is a unique identifying address for each device on the Internet. 

Ask the students to think of some analogies to an IP address. Appropriate responses would include a mailing address, a phone number, a Social Security number, and an email address.

Have the students use a device (computer, tablet, or smartphone) and visit the site https://whatismyipaddress.com/ . Get a few students to share their IP addresses with the class. Note that each IP address has the same format, #.#.#.#., in which each # is a number in the range of 0 - 255. 

Additionally, many students in the class may have similar IP addresses, particularly for the first half. If this is the case, ask the students why they think it is so. Lead the discussion towards the naming scheme of IP addresses. The beginning part of the IP address identifies the network that the device is connected to. The ending part of the address identifies the actual device. This hierarchy is what allows sites such as https://whatismyipaddress.com/ to identify where a device is from its IP address. 

Based on the format of the IP addresses, ask the class how many possible IP addresses there are. They should find that there are over 4 billion possible addresses (by computing 256 * 256 * 256 * 256, or 256 ^ 4). Ask the students if they think this is enough addresses to accommodate everyone’s device in the world.

In fact, because of the rise of mobile devices and the number of IP addresses reserved for particular organizations, there is a shortage of IP addresses. To accommodate this, a new protocol, called IPv6 has been established to handle many more devices.

IP addresses are assigned to devices by Dynamic Host Configuration Protocol (DHCP). The DHCP server maintains a set of IP addresses that it leases out to devices for a limited amount of time. Each device on the network is given its own IP address. When an IP address is not being used, it is put back into the pool to be allocated again. 

An analogy for DHCP assigning IP addresses is getting numbers in line at a deli. Each customer gets his or her own number, and while it is possible to get the same number repeatedly, it is not guaranteed.

## Domain Name Servers

An additional component of the Internet is the Domain Name Server (DNS). A DNS translates the URLs of websites, or domain names, to IP addresses. The DNS is necessary because devices access websites based on IP addresses, but humans access them via domain names.

An analogy for DNS is a phone book. Most people don’t memorize each other’s phone numbers, but they can look up a person’s name to get their phone number. This is similar to typing in a URL, which is then translated to an IP address that the device can navigate to.

Tell the students to navigate to a common webpage such as www.nytimes.com. Have them click multiple links on the site and take note of the URL after each click. Ask the students what they notice about the URLs. They should see that the URLs all start with nytimes.com. This is referred to as the domain name. 

Domain names are a part of the DNS naming hierarchy. One level of hierarchy includes the suffixes, such as .com, .edu, and .org. Another level includes the name of the site, such as facebook, nytimes, and codecombat. Periods separate each part of the name, allowing the DNS to perform the lookup and navigate to the correct site.

## Data Transmission

The Internet moves computerized information from one place to another. An analogy for the Internet is the United States Postal Service. Information is passed between devices, with no regard of what the information is or why it is being sent. Because of the standard protocols and servers, the Internet can be used to transmit many different kinds of information. In addition, applications can be created that simply have to communicate with the Internet in order to run on the network.

Information is transmitted on the Internet via packet switching. Instead of sending information all at once, the information is broken into smaller pieces, called packets. Each packet is then sent separately to the destination where they are all reassembled. How this is done is standardized with the transmission control protocol, or TCP.

At the end of the lesson, have the students write how the Internet works in a way that children can understand. Instruct them to explain the abstractions of the Internet in their writing. They can then revisit their writing from the beginning of class and compare their thoughts at the beginning of class to the reality of how the Internet works. 
 
### Discussion Questions:
- What problems might arise if two devices were assigned the same IP address on a network?
- What do you think will happen when we run out of valid IP addresses?
- Why do we need DHCP?
- Why do we need DNS?
- Why are IP addresses and domain names hierarchical?
- Why do you think packet switching is useful?
- What connections are there between the abstractions of the Internet and the abstractions in programming? 
- Compare and contrast data compression and packet switching.
- Describe how packet switching can help keep data more secure.

### Assessment Questions:
- Define the internet [EK 6.1.1A]
- How is an internet-connected device identified by another device? [EK 6.1.1E, EK 6.1.1G]
- How are domain names and IP addresses organized? [EK 6.2.1B, EK 6.2.1C]
- What makes the internet fault-tolerant? [EK 6.2.2B]
- What are some protocols which underpin the internet? [EK 6.1.1E, EK 6.2.2G]
