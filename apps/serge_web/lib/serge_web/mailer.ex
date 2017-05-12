defmodule Serge.Web.Mailer do
  use Bamboo.Mailer, otp_app: :serge_web

  # TODO: use this to send invite email:
  #   > Serge.Web.TeamInviteEmail.invite(t, ta) |> Serge.Web.Mailer.deliver_now
end
