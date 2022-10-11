defmodule Searching.Runner do
  use GenServer

  ### API

  def start_link(init_arg) do
    GenServer.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  def start() do
    GenServer.cast(__MODULE__, {:start})
  end

  def stop() do
    GenServer.cast(__MODULE__, {:stop})
  end

  def status() do
    GenServer.call(__MODULE__, {:status})
  end

  ### CALLBACKS

  def init(_init_arg) do
    {:ok, %{running: false}}
  end

  def handle_cast({:start}, %{running: false} = state) do
    task = Task.async(fn -> Searching.Generator.generate(60) end)
    {:noreply, state |> Map.put(:running, true) |> Map.put(:task, task)}
  end

  def handle_cast({:start}, state) do
    {:noreply, state}
  end

  def handle_cast({:stop}, %{running: true} = state) do
    Task.shutdown(Map.get(state, :task))
    {:noreply, Map.put(state, :running, false)}
  end

  def handle_cast({:stop}, state) do
    {:noreply, state}
  end

  def handle_call({:status}, _from, state) do
    {:reply, %{running: Map.get(state, :running)}, state}
  end
end
