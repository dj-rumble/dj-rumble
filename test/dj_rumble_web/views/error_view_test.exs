defmodule DjRumbleWeb.ErrorViewTest do
  use DjRumbleWeb.ConnCase, async: true

  # Bring render/3 and render_to_string/3 for testing custom views
  import Phoenix.View

  test "renders 404.html" do
    assert render_to_string(DjRumbleWeb.ErrorView, "404.html", []) =~ "The page you were looking for doesn't exist or the link you clicked may be broken."
  end

  test "renders 500.html" do
    assert render_to_string(DjRumbleWeb.ErrorView, "500.html", []) =~ "Our spaghetti code is not working properly. Time to paw through your logs and get down and dirty in your stack trace. We'll redirect you to the homepage in a few seconds."
  end
end
