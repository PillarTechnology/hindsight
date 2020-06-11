defmodule Aggregate.Feed.Consumer do
  @moduledoc """
  Process for handling `GenStage` messages during profiling, sending a
  `aggregate_update` event.
  """
  use GenStage
  use Properties, otp_app: :service_aggregate
  require Logger

  getter(:endpoints, required: true)
  getter(:topic, required: true)

  @type init_opts :: [
          dataset_id: String.t(),
          subset_id: String.t()
        ]

  @instance Aggregate.Application.instance()

  @spec start_link(init_opts) :: GenServer.on_start()
  def start_link(opts) do
    GenStage.start_link(__MODULE__, opts)
  end

  @impl GenStage
  def init(opts) do
    Logger.debug(fn -> "#{__MODULE__}(#{inspect(self())}): init with #{inspect(opts)}" end)

    {:consumer,
     %{
       dataset_id: Keyword.fetch!(opts, :dataset_id),
       subset_id: Keyword.fetch!(opts, :subset_id)
     }}
  end

  @impl GenStage
  def handle_events(events, _from, state) do
    Elsa.create_topic(endpoints(), topic())

    Enum.map(events, fn e -> Jason.encode!(e) end)
    |> Enum.each(fn d -> Elsa.produce(endpoints(), topic(), d) end)

    {:noreply, [], state}
  end
end
