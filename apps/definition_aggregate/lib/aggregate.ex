defmodule Aggregate do
  @moduledoc """
    Object representing the aggregation of a datastream. Use `new/1` to create a new instance

  ## Init options

  * `id` - ID of this instance
  """
  use Definition, schema: Aggregate.V1

  @type uuid :: String.t()

  @type t :: %Aggregate{
          version: integer,
          id: uuid,
          dataset_id: String.t(),
          subset_id: String.t(),
          source: Source.t(),
          decoder: Decoder.t(),
          destination: Destination.t(),
          reducers: List.t()
        }

  defstruct version: 1,
            id: nil,
            dataset_id: nil,
            subset_id: nil,
            source: nil,
            decoder: nil,
            destination: nil,
            reducers: nil

  @impl Definition
  def on_new(aggregate), do: Ok.ok(aggregate)
end

defmodule Aggregate.V1 do
  @moduledoc false
  use Definition.Schema

  @impl true
  def s do
    schema(%Aggregate{
      version: version(1),
      id: id(),
      dataset_id: required_string(),
      subset_id: required_string(),
      source: impl_of(Source),
      decoder: impl_of(Decoder),
      destination: impl_of(Destination),
      reducers: of_struct(List.Impl)
    })
  end
end
