---
title: TiddlyWiki user authentication with NGINX auth_requests and Django
date: 2020-11-25
layout: post
excerpt: "I chose TiddlyWiki for its great user interface, despite some other deficiencies that made it a less than ideal choice for the project, like only supporting HTTP basic authentication. Using public-notes over the past couple months, the basic auth flow stands out as a real pain point in an otherwise smooth experience."
updated: 2021-03-20
tags:
- tiddlywiki
- django
- nginx
- public-notes
---

In September I started work on
public-notes.muumu.us (since taken down),
a project to create a personal knowledge base and publish it on the internet. I
chose [TiddlyWiki](https://tiddlywiki.com/ "TiddlyWiki") for the project for
reasons I outlined in an earlier post, [*Building an internet-facing TiddlyWiki
for my public second brain*]({% post_url 2020-09-06-building-a-public-tiddlywiki
%} "Building an internet-facing TiddlyWiki for my public second brain -
muumu.us"). TiddlyWiki's non-hierarchical approach to note taking is unique and
I find its ergonomics mesh much better with my thought process than a
traditional wiki or something like Evernote. It is one of a very few pieces of
software that feels completely effortless to use.

So I chose TiddlyWiki for its great user interface, despite some other
deficiencies that made it a less than ideal choice for the project, like only
supporting HTTP basic authentication. Using public-notes over the past couple
months, the basic auth flow stands out as a real pain point in an otherwise
smooth experience. I use Firefox for a browser and Bitwarden as a password
manager, on both desktop and mobile, and the user experience for getting through
basic auth is frustrating. The basic auth window steals the focus and prevents
you from clicking back into the browser, like you'd need to do to grab your
password from the Bitwarden plugin, so you need to remember to copy the password
*before* navigating to the site --- and since you're not already on the site,
Bitwarden won't autosuggest it and you'll have to search for it. If you forget
to perform that ritual you will have to cancel out of the basic auth window,
perform the rite, and try an incantation of hard refreshes and new private
windows to get the authentication box to reappear. On mobile this whole
performance is painful enough that I stopped using it altogether.

There has to be a better way to do this. You will find
[twproxy](https://github.com/stevenleeg/twproxy "stevenleeg/twproxy - GitHub")
suggested as a solution on the TiddlyWiki Google Group. It's a Ruby/Sinatra
application that proxies requests to TiddlyWiki and adds authentication. It
sounded like a good solution, but I ran into a problem described [in an issue on
the project's GitHub](https://github.com/stevenleeg/twproxy/issues/6 "TW
returning 403 on attempted save") where the TiddlyWiki would only render for an
instant before throwing a `Sync error while processing '$:/StoryList'`. I spent
an hour or so starting to fix it one Saturday, but fixing that one bug revealed
another and I started falling down a rabbit hole of trying to fix outdated
dependencies. I lost motivation when I saw there was already a pull request on
the project that purported to fix the issue, open and untouched for three
months. For what it's worth, I couldn't get that PR's branch working either, and
there are no tests.

Ultimately, twproxy didn't seem like the right approach to me anyway. I already
have NGINX set up as a reverse proxy on TiddlyWiki --- why do I need another
proxy in front of that? After some Googling I found that, using the
*auth_request* module, NGINX can verify each request against an external
authentication server before passing it upstream. The article [Authentication
Based on Subrequest
Result](https://docs.nginx.com/nginx/admin-guide/security-controls/configuring-subrequest-authentication/
"Authentication Based on Subrequest Result - NGINX Plus Admin Guide") from the
NGINX Plus Admin Guide explains it well:

> NGINX and NGINX Plus can authenticate each request to your website with an
> external server or service. To perform authentication, NGINX makes an HTTP
> subrequest to an external server where the subrequest is verified. If the
> subrequest returns a `2xx` response code, the access is allowed, if it returns
> `401` or `403`, the access is denied. Such type of authentication allows
> implementing various authentication schemes, such as multifactor
> authentication, or allows implementing LDAP or OAuth authentication.

That sounded like a good solution, but I still needed to find an authentication
service to handle verifying the requests. All the existing solutions I found
seemed like overkill for my single-user, non-enterprise use case. I didn't want
to set up a Keycloak or a FreeIPA server --- I could write something myself more
quickly, that was easier to deploy and understand.

So that's what I did. I made
[is_authenticated](https://github.com/kylerjohnston/is_authenticated
"kylerjohnston/is_authenticated - GitHub") --- a *very* simple Django app that
returns a `200` if a user is authenticated and a `401` if they're not. It relies
entirely on Django's built in user management capabilities. The *only* real code
I wrote is this little function:

```python
def is_authenticated(request):
    if request.user.is_authenticated:
        return HttpResponse('Signed in')
    else:
        return HttpResponse('Not signed in!', status=401)
```

Then I just had to configure NGINX and `auth_request` to use the service. The
authentication service has two endpoints: `/auth/`, the main application,
returns `200` if the user is authenticated and `401` if not; `/accounts/login/`
is the user log in page. I added location blocks to proxy requests on those
endpoints to the authentication service.

```
location = /auth/ {
    internal;
    proxy_pass   http://127.0.0.1:8000;
    proxy_pass_request_body off;
    proxy_set_header Content-Length "";
}

location = /accounts/login/ {
    proxy_pass  http://127.0.0.1:8000;
}
```

The `internal` keyword tells NGINX this endpoint is not accessible to external
requests --- a user trying to navigate to https://tiddlywiki.example.com/auth/
will get a `404`; only our NGINX proxy can send requests there.

I also drop the request body because the authentication service doesn't need
that data. 

Then I updated the location block for TiddlyWiki to use the `auth_request`
module --- I have TiddlyWiki running on port `8080` on the same host.

```
location / {
    error_page 401 = @error401;
    auth_request    /auth/;
    proxy_pass http://127.0.0.1:8080;
    proxy_set_header Host $host;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
}
```

I only added two lines here: `auth_request /auth/;` tells NGINX that for each
request to this location it should send a subrequest to `/auth/` to verify
if the user is authenticated.

The `error_page` keyword sets a URI to be presented in the case of an error. In
this case, I'm setting NGINX to direct requests to the named location
`@error401` in the event that a request to this location returns a `401`
response --- i.e., if the user is not authenticated. Let's define the
`@error401` location:

```
location @error401 {
    return 302 https://$host/accounts/login/;
}
```

This means in the event of a `401`, we will redirect users to the log in page.

And that's it. I've had it running for a couple weeks now and the user
experience is much nicer than basic auth. My password manager works!
