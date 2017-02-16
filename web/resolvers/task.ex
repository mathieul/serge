defmodule Serge.Resolvers.Task do

  alias Serge.Task
  alias Serge.Repo

  def find(_parent, %{ id: id }, _info) do
    case Repo.get(Task, id) do
      nil  -> { :error, "Task id #{id} not found" }
      task -> { :ok, task }
    end
  end

  def all(_parent, _args, _info) do
    { :ok, Repo.all(Task) }
  end

  def create(_parent, attributes, _info) do
    IO.inspect attributes
    changeset = Task.changeset(%Task{}, attributes)
    case Repo.insert(changeset) do
      {:ok, task} -> {:ok, task}
      {:error, changeset} -> {:error, changeset.errors}
    end
  end
end
