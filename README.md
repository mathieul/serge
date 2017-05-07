# Serge

To start your Phoenix app:

  * Install dependencies with `mix deps.get`
  * Create and migrate your database with `mix ecto.create && mix ecto.migrate`
  * Install Node.js dependencies with `npm install`
  * Start Phoenix endpoint with `mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](http://www.phoenixframework.org/docs/deployment).

## Learn more

  * Official website: http://www.phoenixframework.org/
  * Guides: http://phoenixframework.org/docs/overview
  * Docs: https://hexdocs.pm/phoenix
  * Mailing list: http://groups.google.com/group/phoenix-talk
  * Source: https://github.com/phoenixframework/phoenix

## Github OAuth app for development ##

    export GITHUB_REDIRECT_URI=http://localhost:4000/auth/github/callback
    export GITHUB_CLIENT_ID=18e2f95af473d367c294
    export GITHUB_CLIENT_SECRET=e3b62ba98785a95a88d6238a865ce15a72e78756

## GraphQL ##

Serge is currently using the pre-release [`elm-graphql` package](https://github.com/jamesmacaulay/elm-graphql)
(Elm files of the library checked into `web/static/elm/GraphQL`).

## Release ##

Bump application version in `mix.exs` (i.e.: 0.10.1) and run as user `elixir`:

    $ export MIX_ENV=prod
    $ cd dev/serge
    $ git pull
    $ rm -rf _build/prod/lib/serge_web/priv/static apps/serge_web/priv/static
    $ mix deps.get
    $ cd apps/serge_web/assets
    $ yarn && elm package install -y
    $ ./node_modules/.bin/webpack -d
    $ cd ../../..
    $ mix do phx.digest, compile
    $ mix release --env=prod --upgrade
    $ cp -r _build/prod/rel/combined/releases/0.10.1 /apps/serge/releases/0.10.1
    $ cd /apps/serge
    $ ./bin/combined upgrade 0.10.1
    $ ./bin/combined stop
    $ ./bin/combined migrate
    $ ./bin/combined start

## Production ##

Make sure to create Ecto databases and migrate them.
