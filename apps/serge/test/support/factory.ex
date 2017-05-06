defmodule Serge.Factory do
  use ExMachina.Ecto, repo: Serge.Repo

  def user_factory do
    %Serge.Authentication.User{
      email: sequence(:email, &"email-#{&1}@example.com"),
    }
  end

  def task_factory do
    %Serge.Tasking.Task{
      user:         build(:user),
      label:        sequence("Do that thing #"),
      scheduled_on: Serge.DateHelpers.tomorrow,
      rank:         sequence(:rank, fn n -> n end),
    }
  end

  def team_factory do
    %Serge.Scrumming.Team{
      owner: build(:user),
      name:  sequence("Team #"),
    }
  end
end
