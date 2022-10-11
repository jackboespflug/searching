defmodule SearchingWeb.Metrics do
  use Phoenix.Socket

  channel "segments", SearchingWeb.SegmentsChannel

  def connect(_params, socket, _connect_info) do
    {:ok, socket}
  end

  def id(_socket) do
    "metrics_socket"
  end
end
