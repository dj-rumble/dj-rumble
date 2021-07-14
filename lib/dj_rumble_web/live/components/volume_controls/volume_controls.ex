defmodule DjRumbleWeb.Live.Components.VolumeControls do
  @moduledoc """
  Responsible for displaying the volume controls
  """

  use DjRumbleWeb, :live_component

  # @impl true
  # def mount(socket) do
  #   {:ok,
  #    socket
  #    |> assign(:volume_controls, get_initial_state())}
  # end

  @impl true
  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)}
  end

  @impl true
  def handle_event("player_signal_toggle_volume", _params, socket) do
    %{volume_controls: volume_controls} = socket.assigns

    %{is_muted: is_muted, volume_level: volume_level} = volume_controls

    volume_level =
      case !is_muted do
        true -> 0
        false -> volume_level
      end

    volume_icon = get_volume_icon(volume_level)

    params = %{
      is_muted: !is_muted,
      volume_icon: volume_icon
    }

    volume_controls = update_controls(volume_controls, params)
    socket = assign(socket, :volume_controls, volume_controls)

    send_update_controls(volume_controls)

    case is_muted do
      true ->
        {:noreply,
         socket
         |> push_event("receive_unmute_signal", %{})}

      false ->
        {:noreply,
         socket
         |> push_event("receive_mute_signal", %{})}
    end
  end

  @impl true
  def handle_event(
        "volume_level_changed",
        %{"volume" => %{"change" => volume_level}},
        socket
      ) do
    {volume_level, _} = Integer.parse(volume_level)
    %{volume_controls: volume_controls} = socket.assigns
    %{is_muted: is_muted} = volume_controls

    volume_icon = get_volume_icon(volume_level)

    socket =
      case is_muted do
        true -> push_event(socket, "receive_unmute_signal", %{})
        _ -> socket
      end

    is_muted = get_state_by_level(volume_level)

    params = %{
      is_muted: is_muted,
      volume_icon: volume_icon,
      volume_level: volume_level
    }

    volume_controls = update_controls(volume_controls, params)

    send_update_controls(volume_controls)

    {:noreply,
     socket
     |> push_event("receive_player_volume", %{level: volume_level})
     |> assign(:volume_controls, volume_controls)}
  end

  defp compute_volume(volume_controls) do
    case volume_controls.is_muted do
      true -> 0
      false -> volume_controls.volume_level
    end
  end

  def get_initial_state do
    %{
      volume_level: 100,
      is_muted: false,
      volume_icon: "speaker-4"
    }
  end

  def get_state_by_level(volume_level) do
    case volume_level do
      0 -> true
      _ -> false
    end
  end

  def get_volume_icon(volume_level) do
    case volume_level do
      l when l > 70 -> "speaker-4"
      l when l > 40 -> "speaker-3"
      l when l > 10 -> "speaker-2"
      l when l > 0 -> "speaker-1"
      l when l == 0 -> "speaker-0"
    end
  end

  def update_controls(controls, props) do
    Map.merge(controls, props)
  end

  defp send_update_controls(volume_controls) do
    send(self(), {:update_volume_controls, volume_controls})
  end
end
