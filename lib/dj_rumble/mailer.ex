defmodule DjRumble.Mailer do
  use Bamboo.Mailer, otp_app: :dj_rumble
end

defmodule DjRumble.Email do
  import Bamboo.Email

  def new(to, body, subject) do
    new_email(
      to: to,
      from: "djrumble@gmail.com",
      subject: subject,
      text_body: body
    )
  end
end
