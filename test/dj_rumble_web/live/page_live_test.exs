defmodule DjRumbleWeb.PageLiveTest do
  use DjRumbleWeb.ConnCase

  import Phoenix.LiveViewTest

  test "disconnected and connected render", %{conn: conn} do
    {:ok, page_live, disconnected_html} = live(conn, "/")
    assert disconnected_html =~ "Dj Rooms"
    assert render(page_live) =~ "Dj Rooms"
  end
end
