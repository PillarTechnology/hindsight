defmodule Aggregate.Feed do
  @moduledoc """
  Supervises dataset profiling `Flow`s.
  """
  use Supervisor
  require Logger

  @type init_opts :: [
          name: GenServer.name(),
          aggregate: Aggregate.t()
        ]

  @spec start_link(init_opts) :: GenServer.on_start()
  def start_link(opts) do
    server_opts = Keyword.take(opts, [:name])
    Supervisor.start_link(__MODULE__, opts, server_opts)
  end

  @impl true
  def init(opts) do
    aggregate = Keyword.fetch!(opts, :aggregate)

    Logger.debug(fn ->
      "#{__MODULE__}: Starting feed for #{inspect(aggregate)}"
    end)

    children = [
      {
        Aggregate.Feed.Flow,
        dataset_id: aggregate.dataset_id,
        subset_id: aggregate.subset_id,
        from_specs: [
          {Aggregate.Feed.Producer, aggregate: aggregate}
        ],
        into_specs: [
          {Aggregate.Feed.Consumer,
           dataset_id: aggregate.dataset_id, subset_id: aggregate.subset_id}
        ],
        reducers: aggregate.reducers
      }
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
