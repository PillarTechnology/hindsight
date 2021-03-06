defmodule Delete do
  @moduledoc false
  use Definition, schema: Delete.V1

  @type uuid :: String.t()

  @type t :: %__MODULE__{
          version: integer,
          id: uuid,
          dataset_id: String.t(),
          subset_id: String.t()
        }

  defstruct version: 1,
            id: nil,
            dataset_id: nil,
            subset_id: nil
end

defmodule Delete.V1 do
  use Definition.Schema

  @impl true
  def s do
    schema(%Delete{
      version: version(1),
      id: id(),
      dataset_id: required_string(),
      subset_id: required_string()
    })
  end
end
