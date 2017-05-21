defmodule Serge.Factory do
  use ExMachina.Ecto, repo: Serge.Repo

  alias Serge.DateHelpers, as: DH

  def user_factory do
    %Serge.Authentication.User{
      email: sequence(:email, &"email-#{&1}@example.com"),
    }
  end

  def task_factory do
    %Serge.Tasking.Task{
      user:         build(:user),
      label:        sequence("Do that thing #"),
      scheduled_on: DH.tomorrow,
      rank:         sequence(:rank, fn n -> n end),
    }
  end

  def team_factory do
    %Serge.Scrumming.Team{
      owner: build(:user),
      name:  sequence("Team #"),
    }
  end

  def team_access_factory do
    %Serge.Scrumming.TeamAccess{
      kind:        :read_write,
      token:       "abcd",
      expires_at:  DH.days_from_now(-1, as_time: true),
      user:        build(:user),
      team:        build(:team),
      accepted_at: DH.days_from_now(-2, as_time: true)
    }
  end

  def story_factory do
    %Serge.Scrumming.Story{
      creator:      build(:user),
      team:         build(:team)
    }
  end
end
