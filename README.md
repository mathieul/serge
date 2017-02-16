# Serge

To start your Phoenix app:

  * Install dependencies with `mix deps.get`
  * Create and migrate your database with `mix ecto.create && mix ecto.migrate`
  * Install Node.js dependencies with `npm install`
  * Start Phoenix endpoint with `mix phoenix.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](http://www.phoenixframework.org/docs/deployment).

## Learn more

  * Official website: http://www.phoenixframework.org/
  * Guides: http://phoenixframework.org/docs/overview
  * Docs: https://hexdocs.pm/phoenix
  * Mailing list: http://groups.google.com/group/phoenix-talk
  * Source: https://github.com/phoenixframework/phoenix

## OAuth

export GITHUB_REDIRECT_URI=http://localhost:4000/auth/github/callback
export GITHUB_CLIENT_ID=18e2f95af473d367c294
export GITHUB_CLIENT_SECRET=e3b62ba98785a95a88d6238a865ce15a72e78756


## Queries &amp; Mutations

    mutation ($label: String!, $rank: Int!, $userId: ID!) {
      createTask(label: $label, rank: $rank, userId: $userId) {
        id
        label
        rank
        user {
          id
          name
        }
      }
    }

with:

    {
      "label": "allo la terre???",
      "rank": 1,
      "userId": 2
    }
