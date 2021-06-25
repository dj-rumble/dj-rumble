ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(DjRumble.Repo, :manual)
Faker.start()

defmodule DjRumble.TestCase do
  @moduledoc """
  This module defines miscelaneous helpers for tests

  You may define functions here to be used as helpers in your tests.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      import DjRumble.AccountsFixtures

      defp is_pid_alive(pid) do
        is_pid(pid) and Process.alive?(pid)
      end

      defp player_process_mock do
        receive do
          _ -> nil
        after
          5000 -> :timeout
        end

        player_process_mock()
      end

      defp spawn_players(n) do
        Enum.map(1..n, fn _ ->
          pid = spawn(fn -> player_process_mock() end)
          # Enables messages tracing going through pid
          :erlang.trace(pid, true, [:receive])
          assert is_pid_alive(pid)
          user = user_fixture()
          {pid, user}
        end)
      end
    end
  end
end
