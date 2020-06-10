defmodule Aggregate.Event.Handler do
  @moduledoc """
  Callbacks for handling events from `Brook`.
  """
  use Brook.Event.Handler
  require Logger

  import Events, only: [aggregate_start: 0, aggregate_update: 0]
  import Definition, only: [identifier: 1]

  def handle_event(%Brook.Event{
        type: aggregate_start(),
        data: %Aggregate{destination: %Kafka.Topic{}} = aggregate
      }) do
    Logger.debug(fn ->
      "#{__MODULE__}: Received event #{aggregate_start()}: #{inspect(aggregate)}"
    end)

    Aggregate.Feed.Supervisor.start_child(aggregate)
    :discard
    # identifier(aggregate)
    # |> Aggregate.ViewState.Extractions.persist(aggregate_update)
  end

  def handle_event(%Brook.Event{type: aggregate_update(), data: %Aggregate.Update{} = update}) do
    Logger.debug(fn ->
      "#{__MODULE__}: Received event #{aggregate_update()}: #{inspect(update)}"
    end)

    identifier(update)
    |> Aggregate.ViewState.Stats.persist(update.stats)
  end
end
