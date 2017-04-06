defmodule Serge.Authentication do
  @moduledoc """
  The boundary for the Authentication system.
  """

  import Ecto.{Query, Changeset}, warn: false
  alias Serge.Repo

  alias Serge.Authentication.User

  @doc """
  Gets a single user.
  """
  def get_user_by_uid_or_create(uid, attrs) do
    case Repo.get_by(User, uid: uid) do
      nil ->
        create_user(attrs)
      user ->
        user
    end
  end

  @doc """
  Generates a user provider uid for OAuth2.
  """
  def make_user_provider_uid(name, id), do: "#{name}:#{id}"

  @doc """
  Gets a user by email.
  """
  def get_user_by_email!(scope \\ User, email) do
    from(u in scope, where: u.email == ^email)
    |> Repo.one!()
  end

  @doc """
  Creates a user.

  ## Examples

      iex> create_user(%{field: value})
      {:ok, %User{}}

      iex> create_user(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_user(attrs \\ %{}) do
    %User{}
    |> user_changeset(attrs)
    |> Repo.insert()
  end

  defp user_changeset(%User{} = user, attrs) do
    user
    |> cast(attrs, [:uid, :name, :email, :avatar_url])
    |> unique_constraint(:email)
    |> validate_required([:email, :uid])
    |> validate_format(:email, ~r/@/)
  end
end
