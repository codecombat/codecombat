# API

* Routes
  * [POST /api/users](#post-apiusers)
  * [GET /api/users/:handle](#get-apiusershandle)
  * [POST /api/users/:handle/o-auth-identities](#post-apiusershandleo-auth-identities)
  * [PUT /api/users/:handle/subscription](#put-apiusershandlesubscription)
  * [GET /auth/login-o-auth](#get-authlogin-o-auth)
* Resources
  * [Users](#users)
  
## Basics
* Examples are in JavaScript on a Node/Express server with [request](https://github.com/request/request) installed.
* Request and responses are in JSON.
* API responses are the base resource being created/referenced. So, for example, all routes starting with `/api/users` return [User](#users) resources.

## Client Setup
We currently do not have a way for you to create or setup your own API Client or OAuth Provider information. Please contact us directly to get started.

## Client Authentication

API routes must be called with Basic HTTP Authentication. Provide your username and password with each request.

```javascript
url = 'https://codecombat.com/api/users'
json = { name: 'A username' }
auth = { name: CLIENT_ID, pass: CLIENT_SECRET }
request.get({ url, json, auth }, (err, res) => console.log(res.statusCode, res.body))
```

## User Authentication

To authenticate a user on CodeCombat through your service, you will need to use OAuth 2. CodeCombat will act as the client, and your service will act as the provider. Your service will need to provide a trusted lookup URL where we can send the tokens given to us by users and receive user information. The process from user account creation to log in will look like this:

1. **Create the user** using [POST /api/users](#post-apiusers).
1. **Link the CodeCombat user to an OAuth identity** using [POST /api/users/:handle/o-auth-identities](#post-apiusershandleo-auth-identities).
1. **Log the user in** by redirecting them to [/auth/login-o-auth](#get-authlogin-o-auth).

# Routes

## `POST /api/users`
Creates a [user](#users).

#### Params
* `email`: String.
* `name`: String.

#### Example
```javascript
url = 'https://codecombat.com/api/users'
json = { email: 'an@email.com', name: 'Some Username' }
request.post({ url, json, auth })
```

## `GET /api/users/:handle`
Returns a [user](#users) with a given ID. `:handle` should be the user's `_id` or `slug` properties.

## `POST /api/users/:handle/o-auth-identities`
Adds an OAuth2 identity to the user, so that they can be logged in with that identity. This endpoint:

1. Uses your OAuth2 token url to exchange the given code for a token, if no token is provided.
1. Uses the token to lookup the user on your service, and expects a JSON object in response with an `id` property.
1. Saves that user `id` to the user as a new OAuthIdentity.

#### Params
* `provider`: String. Your OAuth Provider ID. Required.
* `accessToken`: String. Will be passed through your lookup URL to get the user ID. Required if no `code`.
* `code`: String. Will be passed to the OAuth token endpoint to get a token. Required if no `accessToken`.

#### Example

In this example, your lookup URL is `https://oauth.provider/user?t=<%= accessToken %>'` and returns `{ id: 'abcd' }`

```javascript
url = `https://codecombat.com/api/users/${userID}/o-auth-identities`
OAUTH_PROVIDER_ID = 'xyz'
json = { provider: OAUTH_PROVIDER_ID, accessToken: '1234' }
request.post({ url, json, auth}, (err, res) => {
  console.log(res.body.oAuthIdentities) // [ { provider: 'xyx', id: 'abcd' } ]
})
```

## `PUT /api/users/:handle/subscription`
Grants a user premium access up to a certain time.

#### Params
* `ends`: String. Must be ISO 8601 formatted UTC time, such as '2012-04-23T18:25:43.511Z'. JavaScript Date's `toISOString` returns this format.

#### Example

```javascript
url = `https://codecombat.com/api/users/${userID}/subscription`
json = { ends: new Date('2017-01-01').toISOString() }
request.put({ url, json, auth }, (err, res) => {
  console.log(res.body.subscription) // { ends: '2017-01-01T00:00:00.000Z', active: true }
})
```

## `GET /auth/login-o-auth`
Logs a [user](#users) in.

#### Params
* `provider`: String. Your OAuth Provider ID.
* `accessToken`: String. Will be passed through your lookup URL to get the user ID. Required if no `code`.
* `code`: String. Will be passed through your token URL to get a token. Required if no `accessToken`.

#### Returns
A redirect to the home page and cookie-setting headers.

#### Example

In this example, your lookup URL is `https://oauth.provider/user?t=<%= accessToken %>'` and returns `{ id: 'abcd' }`

```javascript
url = `https://codecombat.com/auth/login-o-auth?provider=${OAUTH_PROVIDER_ID}&accessToken=1234`
res.redirect(url)
// User is sent to CodeCombat and assuming everything checks out, 
// is logged in and redirected to the home page.
```

# Resources

## Users

#### Properties
This is a subset of all the User properties.

* `_id`: String.
* `email`: String.
* `name`: String.
* `slug`: String. Kebab-cased version of `name`. This property is kept unique among CodeCombat users.
* `stats`: Object.
  * `gamesCompleted`: Number.
  * `concepts`: Object with number values. Keys are concepts as listed in [schemas.coffee](https://github.com/codecombat/codecombat/blob/master/app/schemas/schemas.coffee).
* `oAuthIdentities`: Array of Objects.
  * `provider`: String.
  * `id`: String.
* `subscription`: Object.
  * `ends`: ISO Date String.
  * `active`: Boolean
