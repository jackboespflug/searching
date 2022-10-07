defmodule Searching.Generator do

  @elasticsearch "http://localhost:9200"
  @index "idx"
  @doc_type "_doc"

  def create(doc_id) do
    data = %{
      id: doc_id,
      values: %{
        "First Name": Faker.Person.En.first_name(),
        "Last Name": Faker.Person.last_name(),
        "State": Faker.Address.En.state(),
        "Age": :rand.uniform(100)
      }
    }
    {:ok, %HTTPoison.Response{body: body}} = Elastix.Document.index(@elasticsearch, @index, @doc_type, Map.get(data, :id), data)
    IO.puts("Created document: #{Map.get(body, "_id")}")
  end

  def update(doc_id) do
    data = %{
      doc: %{
        values: %{
          "Timestamp": DateTime.utc_now()
        }
      }
    }

    # Elastix.Document.update\5 seems broken, so using straight http
    {:ok, _res} = HTTPoison.post(
        "#{@elasticsearch}/#{@index}/_update/#{doc_id}",
        Jason.encode!(data),
        [{:"Content-Type", "application/json"}])

    IO.puts("Updated document #{doc_id}")
  end

  def delay(rate_per_minute) do
    Process.sleep(ceil(1 / (rate_per_minute / (60 * 1000))))
  end

  def generate(rate_per_minute \\ 60)

  def generate(rate_per_minute) when rate_per_minute < 1 do
    generate(60)
  end

  def generate(rate_per_minute) do
    # create(UUID.uuid1())
    Task.async(fn () -> bot(10, 60) end)
    delay(rate_per_minute)
    generate(rate_per_minute)
  end

  def bot(total_updates, rate) do
    doc_id = UUID.uuid1()
    create(doc_id)
    bot_update(doc_id, total_updates, rate)
  end

  def bot_update(_doc_id, 0, _rate), do: nil

  def bot_update(doc_id, remaining_updates, rate) do
    delay(rate)
    update(doc_id)
    bot_update(doc_id, remaining_updates-1, rate)
  end


  def display_segments(millis) do
    display_segments()
    Process.sleep(millis)
    display_segments(millis)
  end

  def display_segments() do

    {:ok, %{body: body, status_code: 200}} =
      HTTPoison.get("#{@elasticsearch}/#{@index}/_segments")

    segments = Map.values(get_in(Jason.decode!(body), ["indices", @index, "shards"]))
      |> Enum.flat_map(&Function.identity/1)
      |> Enum.map(fn map -> Map.get(map, "segments") end)
      |> Enum.flat_map(&Function.identity/1)
      |> Enum.into(%{})
      |> Enum.map(fn {k,v} -> {k, {Map.get(v, "num_docs"), Map.get(v, "deleted_docs")}} end)
      |> Enum.into(%{})

    IO.inspect(segments)
  end

  def start do
    # Task.async(fn () -> bot(10, 60) end)
    Task.async(fn () -> generate(60) end)
    Task.async(fn () -> display_segments(1000) end)
  end
end
