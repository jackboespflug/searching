defmodule Searching.Generator do

  require Logger

  @elasticsearch "http://localhost:9200"
  @index "idx"
  @doc_type "_doc"

  def create(doc_id) do
    data = %{
      "id" => doc_id,
      "values" => %{
        "First Name" => Faker.Person.En.first_name(),
        "Last Name" => Faker.Person.En.last_name(),
        "State" => Faker.Address.En.state(),
        "Age" => :rand.uniform(100)
      }
    }

    case Elastix.Document.index(@elasticsearch, @index, @doc_type, data["id"], data) do
      {:ok, %{body: body, status_code: 201}} ->
        Logger.info("Created document: #{body["_id"]}")
        body["_id"]

      {:ok, %{body: _body, status_code: status_code}} ->
        Logger.warning("Failed to create the document: (#{status_code})")

      {:error, %HTTPoison.Error{reason: reason}} ->
        Logger.error("ERROR creating document: #{reason}")
    end
  end

  def update(doc_id) do
    data = %{
      "doc" => %{
        "values" => %{
          "Timestamp" => DateTime.utc_now()
        }
      }
    }

    # Use straight http because Elastix.Document.update\5 seems broken
    url = "#{@elasticsearch}/#{@index}/_update/#{doc_id}"
    headers = [{:"Content-Type", "application/json"}]

    case HTTPoison.post(url, Jason.encode!(data), headers) do
      {:ok, %{body: _body, status_code: 200}} ->
        Logger.info("Updated document #{doc_id}")
        Process.sleep(1000)
        update(doc_id)

      {:ok, %{body: _body, status_code: status_code}} ->
        Logger.warning("Failed to update the document #{doc_id}: (#{status_code})")

      {:error, %HTTPoison.Error{reason: reason}} ->
        Logger.error("ERROR updating document #{doc_id}: #{reason}")
    end
  end

  def delay(rate_per_minute) do
    sleep_millis = ceil(1 / (rate_per_minute / (60 * 1000)))
    Process.sleep(sleep_millis)
  end

  def generate(rate_per_minute \\ 60)

  def generate(rate_per_minute) when rate_per_minute < 1 do
    generate(60)
  end

  def generate(rate_per_minute) do
    Task.async(fn () -> bot(10, 60) end)
    delay(rate_per_minute)
    generate(rate_per_minute)
  end

  def bot(total_updates, rate) do
    doc_id = UUID.uuid1()
    created_id = create(doc_id)
    bot_update(created_id, total_updates, rate)
  end

  def bot_update(_doc_id, 0, _rate), do: nil
  def bot_update(nil, _rem, _rate), do: nil

  def bot_update(doc_id, remaining_updates, rate) do
    delay(rate)
    update(doc_id)
    bot_update(doc_id, remaining_updates-1, rate)
  end


  def display_segments(sleep_millis) do
    segments = get_segments()
    Logger.info(inspect(segments))
    Process.sleep(sleep_millis)
    display_segments(sleep_millis)
  end

  def get_segments() do
    case HTTPoison.get("#{@elasticsearch}/#{@index}/_segments") do
      {:ok, %{body: body, status_code: 200}} ->
        Map.values(get_in(Jason.decode!(body), ["indices", @index, "shards"]))
        |> Enum.flat_map(&Function.identity/1)
        |> Enum.map(fn x -> x["segments"] end)
        |> Enum.flat_map(&Function.identity/1)
        |> Enum.into(%{})
        |> Enum.map(fn {k,v} -> {k, {v["num_docs"], v["deleted_docs"]}} end)
        |> Enum.into(%{})

      {:ok, %{body: _body, status_code: status_code}} ->
        Logger.warning("Failed to get segments: (#{status_code})")

      {:error, %HTTPoison.Error{reason: reason}} ->
        Logger.error("ERROR failed to get segments: #{reason}")
    end
  end

  def get_stats() do
    case HTTPoison.get("#{@elasticsearch}/#{@index}/_stats") do
      {:ok, %{body: body, status_code: 200}} ->
        Jason.decode!(body)

      {:ok, %{body: _body, status_code: status_code}} ->
        Logger.warning("Failed to get stats: (#{status_code})")

      {:error, %HTTPoison.Error{reason: reason}} ->
        Logger.error("ERROR failed to get stats: #{reason}")
    end
  end

  def start do
    # Task.async(fn () -> bot(10, 60) end)
    Task.async(fn () -> generate(10) end)
    # Task.async(fn () -> display_segments(1000) end)
  end
end
