defmodule DjRumble.Mailer do
  @moduledoc """
  Responsible for configuring the Mailer module
  """
  use Bamboo.Mailer, otp_app: :dj_rumble
end

defmodule DjRumble.Email do
  @moduledoc """
  Responsible for sending emails
  """
  import Bamboo.Email

  def new(to, body, subject) do
    new_email(
      to: to,
      from: System.get_env("FROM_EMAIL"),
      subject: subject,
      text_body: body
    )
  end
end
