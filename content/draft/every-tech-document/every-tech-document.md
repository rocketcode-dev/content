# Things every technical document should have

Communicating effectively is hard. Especially when you're writing for people you've never met, can never give you feedback, and have varying levels of skill and comprehension. Many of us are technologists whom are more interested in writing code than prose. It's not a part of my job that I enjoy, but it's so important to my brand that I need to do it well. The best practices in this article will help you make your writing more usable to the public.

## Establish your purpose early

Time is a valuable asset. Sometimes people need to get their information quickly, and they need to quickly determine if a document will answer their questions. Nobody likes to scroll through pages of content to find that what they were looking for isn't there.

Help the user assess the applicability of your content quickly by telling them what the article is about and who the intended audience is.

Remember, your purpose is to inform your reader, and leave them feeling satisfied enough to come back to you later. Don't mislead them.

## Make your presentation readable



One of the big differences between writing for a screen vs for print is that there is no physical means to interact with the text. I can't put my finger on a page to mark my place or put little notes in the margin, or underline an important passage of text. Often, there are visual distractions, like animated ads, related links, or sponsored content. We need to be exceptionally conscientious about how we guide the user's eyes on the page.

Long continuous blocks of text are difficult to read, especially on a screen. Break it up. Paragraphs should be short and there should be a space between paragraphs. Keep the line lengths short.

If you can, provide features to help the user interact with your content. Some people, myself included, like to highlight the line of text they are reading. Respect that. Use the `<abbr/>` tag to expand acronyms and folding text to clarify details.

### Colour

Colour can also be a useful tool for enhancing readability and making your article generally more visually appealing. It can also cause some problems if it's misused.

Colour blindness is common in our industry. Colour can also be difficult to see in a projecter image or in a brightly-lit room. Therefore, colour cannot be the sole source of meaning. Instead, use colour as a progressive enhancement. Make things that are already readable without colour even more readable.

For example, when my site has `inline code`, it uses a monospace font, but also it changes the colour. The primary indication that this is `inline code` is the monospace font. I add a pop of colour make it more more visible.

Little pops of colour can be used all over a site to enhance readability and make it more appealing. For example, some of my article tags are colour-coded to make them easier to spot. Pull quotes have a light blue background. The colour isn't the indicator of the pull-quote, but it adds appeal and readability.

Colour can be used to emphasize, but it can also be used to de-emphasize. For decades, grey text has been used to indicate disabled features, and most programming editors show code comments in green italics. On many web sites, legalese is shown in a slightly fainter colour than content. Sometimes the best way to emphasize the important stuff is to de-emphasize the unimportant stuff.

Be careful about bold colours near text. Some colour combinations are nauseating and difficult to focus on. For example, red and blue light, because they are at opposite ends on the visible spectrum, behave differently as they pass through your eye's lenses, one has a shorter focal length than the other. Blue pixels appear slightly closer to you than the red. This is what gives pink and magenta their pop, but it also makes blue on red or anything on pink difficult to read.

Some people find certain colour combinations nauseating. Avoid using bright yellow backgrounds. Some people also find switching between light on dark and dark on light bothersome. Flashing lights can literally cause a seizure. Thus, it's best to stick with black text on a light background or white text on a dark background for most of your body text.

## On metaphors

Our industry revolves around metaphors. We spend our entire careers building things that nobody can actually see or touch, and then explain their tanguble benefits using a language that formed long before the invention of the transistor.

Metaphors are inescapable. Good metaphors add clarity and levity to your article, bad metaphors can make your document confusing or offensive.

### Avoiding offence

What is "offensive" is often debatable and many an article has been written on this topic, so I'm not going to repeat them here. And I do not consider myself an expert on race relations. I do want to make a few points specific to technology documents though:

1. There's no reason to be edgy or risqué in a technical document, so there's no reason to establish the boundary between risqué and icky. If you're anywhere near that boundary, you might as well be over it.
2. If it sounds racist, it is racist. A word sounds close to a bad word, it is the bad word. If a phrase is an obvious rewording of a problematic cliché, it's no different from saying the original cliché.
3. Plain language is inclusive language. Clichés, especially dated clichés, will confuse people who learned English as an adult.

Some words common in technology that have fallen out of favour:

* Blacklist/Whitelist -- better to use "deny list" and "allow list"
* Master -- better to use primary, main, origin/original, system of record, manager, controller, leader
* Slave -- better to use secondary, copy, duplicate, redundant node, worker, follower
* Grandfathered -- term has racist origins, so it's better to say "legacy status" or "exempt"

Because these problematic terms have been widely used in established technologies for decades, they aren't always avoidable. You're writing about what is, not what should be, but take a moment to double-check that the language hasn't changed first. Most long-standing software packages now have established synonyms, but the original word is still widely used and remains for backwards compatibility. Favour the inclusive language, and include a short explanation, e.g. "In version 9.11.0, BIND 9 added 'primary' and 'secondary' as synonyms to 'master' and 'slave'."

### Idiomatic is not inclusive

Imagine seeing a document peppered with references to American Football, 1980s Bill Murray movie quotes, and measures in miles and fahrenheit. Then another doument peppered with Cricket references, Dev Anand movie quotes, and numbers in lakh and crore.

Chances are, one of those documents is going to be confusing to you. For some readers, both will be.

Metahpores are guaranteed not be understood everywhere:

* Sports - no sport is popular and well-understood everywhere, and many of your own countrymen may not pay much attention sports at all,
* Literature - nobody who learned English as an adult will have studied English literature in high school, and some politically-charged works like George Orwell's _Nineteen Eighty-Four_ may have been banned or discouraged at some times in some countries,
* Biblical references - scripture has the same problem as any other politically-charged literature, and
* Pop culture - I could make a whole career on _Ghostbusters_ and Monty Python references, but nobody too young or too far away will understand it.

In fact, there really aren't very many universal metaphores out there. This is not to say "don't use metaphors". Metaphors are inescapable in our industry. Instead, think of metaphores as an expensive power-up, so make them count. Metaphores that aren't worth explaining aren't worth using.

### When a metaphor is worth using

For a metaphor to be worth using, it needs to have either a low cost or a high value.

A low-cost metaphor is one that is already well-known by your audience or that's fun and mostly meaningless

* An article directed at cybersecurity professionals can use the well-known personas Alice, Bob, and Mallory with little explanation.
* A metaphor can be fun, interesting or a good pun, to get your reader engageed. For example, An introduction to Kubernetes might explain Kubernetes being Greek for "Captain" because it directs an armada of ships (cluster of servers) full of containers.
* No meaning is lost if it's not understood.

A high-value metaphor is one that changes the user's thinking.

* The "cattle not pets" metaphor that emerged in the early 2010s made us view servers something that should be expendable and replacable, not precious and unique.

### A few side notes on grammar and readable language

#### Passive voice

Every action has an actor, so name the actor. Passive tense is not a problem if you use it judiciously, but it's easily overused.

Avoiding it is sometimes difficult though. One common crutch is to add "the user" as the subject. Saying "the user... the user ... the user..." quickly gets repetitive and awkward though. "You... you... you..." also gets repeititve and awkward but it also adds an accusatory tone.

It's ok to use these "crutches" above, but Throw in some variety. Use the imperitive tense and subject phrases. In this article, I have chosen to use the first person. I am writing to you. I don't do this often, but sometimes it also avoids the passive voice.

#### Regional language

There are many regional variations of the English language. I wrote this article in Canadian English, which is a weird combination of British spellings of American words. The dialect of English you use is not as important as the way you use it. As long as you're using plainspeak, you're unlikely to be misunderstood by someone that prefers a different dialect of English than you.

There are two exceptions to this though:

1) When there are multiple authors, they should write with one voice. That means one dialect.
2) Write code examples in American English. No exceptions. Any non-American spellings _will_ cause confusion.

#### Quoted text

Both the AP Style Guide and the Chicago Manual of Style recommend putting periods and commas within quotes, even if they are not part of the quote.

```plain text
My brother said "You need to get a haircut," but I didn't agree.
```

In technical documentation this is confusing, especially if you need to type the exact contents into code or a command. Only things that are part of the actual quote should be there.

```plain text
You may add a line break after "if [ -e ${file} ]; then", but it's not necessary
```

There's no ambiguity as to what is inside the quote when you use this style. A `monospace code style` can also be useful for quoting without worrying about quotation style.

## How to use examples

When providing an example, it's important that the user knows two things:

1) What you want them to see, and
2) Where this example came from.

The latter requires context, but context obscures the former.

Nothing is more frustrating than being told to add two lines of config text, but I have no idea where and in what file. At the same time, context can get noisy and distracting from the main point of the example.

Also very frustrating is when the example you have is so simple that you don't know how to extend it to the real world.

Many years ago, I created a [tutorial](https://github.com/appcelerator-archive/ElementsOfListView) for a scrolling list UI element on a mobile platform that was confusing many of my colleagues and customers. I decided to create a useful app around the UI rather than a simplest possible example, something I was initially criticized for, but it made the document more engaging and it showed the power of the element better.

Doing this, of course required supporting code not relevant to the tutorial that I would not want to include in a PDF file, but the complete code for each chapter is in a git branch.

A git link is not a substitute for context in your document though. That is only asking a user to cross-reference between your snippet and the entire repository. It's both distracting and disorienting. Include enough context to tell your story, but provide a git link to allow them to see the structure as a whole and, where possible, give them some code to expiriment with.

## Keep your document live

Your document is probably not a legal record. You can change it any time. Facts change, notice a spelling mistake, want to clarify a detail? Update it. It doesn't matter if you published it yesterday or three years ago. It's always ok to update the document.

Most platforms will state the date of the last update. This date will be understood by your user as the "this document is current to" date. It's one of the things I look at when assessing if a document will meet my needs. Therefore, when updating a document from years ago, read through the document in its entirety to check if any facts have changed.

## Conclusion

I always find conclusions difficult to write. Part of me wants to leave the article with a fun little bit of motivational wisdom. It's not necessary though. Anybody that has reached the end of your article is already motivated. It's better to simply wrap up what you just went through, emphasize the main points.

For example, I will conclude this article by mentioning that the main themes here are:

1) First help the reader assess this article's relevance, then help them understand the topic at hand,
2) Plain language is inclusive language,
3) Use metaphores when they help, and make them count,
4) Use whitespace and colour to enhance readability, and
5) Create useful examples.

Maybe a cute sign-off line at the end, throw in a byline at the bottom, and you're done. Happy coding, and happy writing.
