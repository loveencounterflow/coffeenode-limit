

- [CoffeeNode Limit](#coffeenode-limit)
	- [Rationale](#rationale)

> **Table of Contents**  *generated with [DocToc](http://doctoc.herokuapp.com/)*


# CoffeeNode Limit

<!-- =================================================================================================== -->
## Rationale

We often want to restrict access to the ressources a web application publishes; for example,
you want subscribers to have unlimited access, guest users to enjoy a realistic peek into your offerings
without handing over the full power of your application and the data therein, and at the same time deter
any automated downloads. One part of the equation that can make this happen is User Authentication; the other
is identifying anonymous visitors and selectively throttle or block their access, based on automatically
collected behavior details and / or manual black- and whitelisting.


* A limiter should be completely agnostic as to the task it is limiting—it should help to generally put
	limits to ressource usage, not, say, be built to specifically limit HTTP requests (a drop-in middleware
	could do that–one that uses a generic limiter).

* Because of its genericity, a limiter should work with arbitrary ID tokens that represent clients—these
	could be any piece of data (an internal user ID, an IP address, a session ID) that is fit to identify
	a client in the sense of the application.

* Since a limiter should be able to base *its* behavior on the past behavior of a given client *and* on the
	client's ranking (say, customer vs. guest vs. rogue), it must either entertain a suitable datastructure
	to keep such group affiliation and usage data (or else be fed (some of) these details when called).

* Whether or not a limiter should take care of data persistence is an open question; ideally, server restart
	or redirection to another server process should not impact limiter behavior (this consideration would
	appear to favor Redis-like data persistence plans).

* A limiter should distinguish between and be configurable for at least three behavioral patterns: full
	access, deferred (throttled) access, and denial of service (the last two with timeouts and permanent).

[CoffeeNode Limit](https://github.com/loveencounterflow/coffeenode-limit) is an sttempt to bring all of
the above points to the backend. It currently works with a slightly patched version of
[node-rate-limiter](https://github.com/jhurliman/node-rate-limiter).



