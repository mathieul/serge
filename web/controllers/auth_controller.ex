defmodule Serge.AuthController do
  use Serge.Web, :controller
  alias Serge.User

  @doc """
  This action is reached via `/auth/:provider` and redirects to the OAuth2 provider
  based on the chosen strategy.
  """
  def index(conn, %{"provider" => provider}) do
    redirect conn, external: authorize_url!(provider)
  end

  def delete(conn, _params) do
    conn
    |> put_flash(:info, "You have been logged out!")
    |> configure_session(drop: true)
    |> redirect(to: "/")
  end

  @doc """
  This action is reached via `/auth/:provider/callback` is the the callback URL that
  the OAuth2 provider will redirect the user back to with a `code` that will
  be used to request an access token. The access token will then be used to
  access protected resources on behalf of the user.
  """
  def callback(conn, %{"provider" => provider, "code" => code}) do
    # Exchange an auth code for an access token
    client = get_token!(provider, code)

    # Request the user's data with the access token
    user = get_user!(provider, client)

    # Store the user in the session under `:current_user` and redirect to /.
    # In most cases, we'd probably just store the user's ID that can be used
    # to fetch from the database. In this case, since this example app has no
    # database, I'm just storing the user map.
    #
    # If you need to make additional resource requests, you may want to store
    # the access token as well.
    conn
    |> put_session(:current_user, user)
    |> put_session(:access_token, client.token.access_token)
    |> redirect(to: "/")
  end

  defp authorize_url!("github"), do: GitHub.authorize_url!
  defp authorize_url!(_), do: raise "No matching provider available"

  defp get_token!("github", code), do: GitHub.get_token!(code: code)
  defp get_token!(_, _), do: raise "No matching provider available"

  defp get_user!(provider, client) do
    params = params_for(provider, client)
    case Repo.get_by(User, uid: params.uid) do
      nil ->
        User.changeset(%User{}, params) |> Repo.insert!
      user ->
        user
    end
  end

  defp params_for("github", client) do
    %{body: payload} = OAuth2.Client.get!(client, "/user")
    %{
      uid: User.provider_uid("github", payload["id"]),
      name: payload["name"],
      avatar_url: payload["avatar_url"],
      email: payload["email"]
    }
  end
end
