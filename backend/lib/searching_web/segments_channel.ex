defmodule SearchingWeb.SegmentsChannel do
  use Phoenix.Channel

  def join("segments", _payload, socket) do
    :timer.send_interval(1_000, :ping)
    {:ok, Searching.Runner.status(), socket}
  end

  def handle_in("start_test", _payload, socket) do
    Searching.Runner.start()
    {:reply, {:ok, %{}}, socket}
  end

  def handle_in("stop_test", _payload, socket) do
    Searching.Runner.stop()
    {:reply, {:ok, %{}}, socket}
  end

  def handle_info(:ping, socket) do
    push(socket, "update_status", Searching.Runner.status())
    push(socket, "update_stats", Searching.Generator.display_segments())
    {:noreply, socket}
  end
end
