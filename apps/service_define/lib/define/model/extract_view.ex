defmodule Define.Model.ExtractView do
  @moduledoc """
  Representation of an Extract event.
  """
  use Definition, schema: Define.Model.ExtractView.V1
  alias Define.Model.ModuleFunctionArgsView

  @type t :: %__MODULE__{
          version: integer,
          dictionary: [ModuleFunctionArgsView.t()],
          decoder: ModuleFunctionArgsView.t(),
          source: ModuleFunctionArgsView.t(),
          destination: ModuleFunctionArgsView.t()
        }

  @derive Jason.Encoder
  defstruct version: 1,
            dictionary: [],
            decoder: %ModuleFunctionArgsView{},
            source: %ModuleFunctionArgsView{},
            destination: %ModuleFunctionArgsView{}
end

defmodule Define.Model.ExtractView.V1 do
  @moduledoc false
  use Definition.Schema
  alias Define.Model.ModuleFunctionArgsView

  @impl true
  def s do
    schema(%Define.Model.ExtractView{
      version: version(1),
      dictionary: spec(is_list()),
      decoder: of_struct(ModuleFunctionArgsView),
      source: of_struct(ModuleFunctionArgsView),
      destination: of_struct(ModuleFunctionArgsView)
    })
  end
end
