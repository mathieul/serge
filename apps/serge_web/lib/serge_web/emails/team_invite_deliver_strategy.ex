defmodule Serge.Web.TeamInviteDeliverStrategy do
  @behaviour Bamboo.DeliverLaterStrategy

  def deliver_later(adapter, email, config) do
    Task.async(fn ->
      adapter.deliver(email, config)
    end)
  end
end