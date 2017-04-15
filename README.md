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

Bump application version in `mix.exs` (i.e.: 0.5.1) and run as user `elixir`:

    $ cd dev/serge
    $ git pull
    $ rm -rf \_build priv/static
    $ mix deps.get
    $ cd assets
    $ yarn && elm package install -y
    $ ./node_modules/.bin/webpack -p
    $ cd ..
    $ mix do phx.digest, compile, release
    $ cp -r rel/serge/releases/0.5.1/ /apps/serge/releases/
    $ cd /apps/serge
    $ ./bin/serge upgrade 0.5.1

As user `root`:

    # cd /apps
    # ./bin/serge restart

## Production ##

Running at https://serge.cloudigisafe.com - requires a github account as the
application is using OAuth2 with currently only a Github provider.
