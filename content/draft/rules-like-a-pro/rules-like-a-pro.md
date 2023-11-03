# "Learn the rules like a pro, so you can break them like an artist"

Countless variations of this famous Pablo Picasso quote have appeared in various places. Sometimes the "rules" are really just bad habits passed from generation to generation, occasionally they are disrupted by a changing landscape, but usally they emerge from years, decades, or even centuries of experience. It's hard to know the difference. Usually there's a rule that applies to your situation, sometimes there isn't. Again, it's hard to know the difference. Mastering the rules is a lifelong endeavor.

In programming, "the rules" are not constraints but enablers. I have a problem to solve, someone else has solved the problem and it's been widely accepted in the industry. Using that solution is a "rule". That rule may have solved problems you didn't even know existed. It can provide tooling to save hours or weeks of development effort. It can make your applications interopable with apps you don't even know exist.

In technology, "the rules" can take many forms:

* an accepted standard protocol,
* a tool or technology that is widely used for a certain task,
* a coding standard, or
* an established Best Practice.

## Why do people skip the rules?

Often when a programmer skips a rule, it's because of one of two problems:

1. They don't understand the rules, or
2. They think it's too much unnecessary effort.

In both cases, it's easiest to think like that if you don't understand the rules. For example, if you were not familiar with Helm, you may think "Is it really necessary? It's too much effort to learn and build something that is simple to do with deployments and I am pretty good at scripting anyway." Let's face it. We're developers. We love to build. We love to see our own ideas come to life. It's why we're here.

Normally when I see a new tech, it looks overwhelming at first, until I start using it. In my experience, time spent learning a standard tool often pays off in the first project I use it. Maybe my first project with this technology won't look great, but it'll be better than anything I could have hand-coded in the same time. The reason is simple: any tool or technology that rises to ubiquity is there because of the collective experience of tens of thousands of technologists around the world.

## Example: the secure enclave

It was data from a simple web form, could be from a browser or a client app, didn't matter, but a portion of this data was sensitive and could only be processed in a secure enclave. The application layer needed to work with the less-sensitive data, have zero knowledge of the sensitive data, and call out to the secure enclave to process it.

The solution was to acquire a certificate from a service in the secure enclave, use some JavaScript library to encrypt the sensitive data, attach the encrypted blob to the form data, and send that to the API service. The API service would, in turn, pass the encrypted blob to the secure enclave for processing. The secure blob would be end-to-end encrypted from the browser or client app all the way to the secure enclave, but the API would know this blob is related to the rest of the payload.

It looked like an elegant solution to a common problem until we examine the implications more thorougly.

### The problems

What happens if you need to change more than just a key, for example, if at some time in the future, a cipher gets compromised. Nearly all the ciphers we use today will be compromised in a few years from now as million-qubit quantum becomes available.

You have a lot of data, though encrypted, flowing through less-secure applications which probably have different security audit processes. Where is that encrypted blob being stored? Will the app need to recall it at a later day? It may be secure now, but will it remain secure after the cipher has been compromised? If it isn't, will it be updated? Are there backups? Are these backups secure? Are there analytics services. Are there any circumstances where the analytics services will capture and distribute that blob? Do you know? Would you know if analytics services were changed in the future?

You're also asking the users to manage encryption themselves, use a client library to encrypt the data and then add it to an object. It's not a great experience for your API's users.

### A better alternative

This key and cipher problem is already handled by TLS. The TLS handshake already negotiates both the cipher suite and the keys. It's been thouroughly and continuously vetted by security experts around the world, every client and browser in the world is going to support it.

The best way to protect data in your back-end services is to never have it there in the first place. To your backend services, an encrypted blob looks exactly the same as a random string, so why not send a random string instead?

The idea is to use a TLS-secured protocol like HTTPS to upload the secure data directly to the secure enclave and get a token back, then send the token to the API server. The API server can use the token to reference data stored in the secure enclave without actually having to handle the data itself.

Now instead of deconstructing the standard protocol to get around a problem, we have used the standard to solve the problem, and because we followed "the rules", this design will be easier to maintain in the future and to protect against future issues.




## Conclusion

I've been putting "the rules" in quotes for a reason. There is no central authority over "the rules" in software engineering, data security, infrastructure design, but many sources of recommendations.

[IETF](https://www.ietf.org) makes recommendations for internet protocols, [w3c](https://www.w3.org) makes recommendations for web applications, bloggers like me share their experiences, 

