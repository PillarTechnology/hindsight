defmodule Aggregate.Feed.Flow do
  @moduledoc false
  use Flow
  use Properties, otp_app: :service_aggregate
  require Logger

  import Definition, only: [identifier: 2]
  alias Aggregate.Feed.Flow.State

  # TODO: These should be on the aggregation event
  getter(:window_limit, default: 30)
  getter(:window_unit, default: :second)

  @type init_opts :: [
          name: GenServer.name(),
          dataset_id: String.t(),
          subset_id: String.t(),
          from_specs: list(Supervisor.child_spec()),
          into_specs: list(Supervisor.child_spec()),
          reducers: list(Aggregate.Reducer.t())
        ]

  @spec start_link(init_opts) :: GenServer.on_start()
  def start_link(opts) do
    Logger.debug(fn -> "#{__MODULE__}(#{inspect(self())}): init with #{inspect(opts)}" end)
    flow_opts = Keyword.take(opts, [:name])

    dataset_id = Keyword.fetch!(opts, :dataset_id)
    subset_id = Keyword.fetch!(opts, :subset_id)
    from_specs = Keyword.fetch!(opts, :from_specs)
    into_specs = Keyword.fetch!(opts, :into_specs) |> Enum.map(fn consumer -> {consumer, []} end)
    reducers = Keyword.fetch!(opts, :reducers)

    window = Flow.Window.periodic(window_limit(), window_unit())

    stats =
      identifier(dataset_id, subset_id)
      |> Aggregate.ViewState.Stats.get()
      |> case do
        {:ok, nil} -> %{}
        {:ok, stats} -> stats
      end

    # suspect
    reducers = Enum.map(reducers, &Aggregate.Reducer.init(&1, stats))
    # suspect
    {:ok, state} = State.start_link(reducers: reducers)

    from_specs
    |> Flow.from_specs()
    |> Flow.partition(window: window, stages: 1)
    # TODO: suscpect, particularly State.get()
    |> Flow.reduce(fn -> State.get(state) end, &reduce/2)
    |> Flow.on_trigger(fn acc ->
      ## TODO: acc.to_event_fields()
      ## TODO: This function body needs to be done differently
      IO.inspect(acc, label: "acc is")
      if List.first(acc).frame_people_count == %{} do
        time = DateTime.utc_now() |> DateTime.to_iso8601()
        {[%{timestamp: time, people_count: 0}], %{}}
      else
        {average_people_count(acc), %{}}
      end

      # case State.merge(state, acc) do
      #   [] ->
      #     {[], %{}}
      #
      #   changed_reducers ->
      #     event =
      #       changed_reducers
      #       |> Enum.flat_map(&Aggregate.Reducer.to_event_fields/1)
      #       |> Map.new()
      #
      #     {[event], %{}}
      # end
    end)
    |> Flow.into_specs(into_specs, flow_opts)
  catch
    kind, reason ->
      Logger.error(fn -> "#{__MODULE__}: error - #{kind} - #{inspect(reason)}" end)
  end

  defp reduce(event, accumulator) do
    Logger.debug(fn -> "#{__MODULE__}: event #{inspect(event)}" end)

    accumulator
    |> Enum.map(fn reducer ->
      Aggregate.Reducer.reduce(reducer, event)
    end)
  end

  defp average_people_count(acc) do
    IO.inspect(acc, label: "flow.ex: average_people_count")
    first_acc = List.first(acc)
    map = first_acc.frame_people_count
    total = Map.values(map) |> Enum.reduce(0, fn x, acc -> x + acc end)
    time = DateTime.utc_now() |> DateTime.to_iso8601()
    [%{timestamp: time, people_count: total / Enum.count(map)}]
  end
end
