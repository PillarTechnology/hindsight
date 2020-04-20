defmodule Define.Model.LoadView do
  @moduledoc """
  Representation of an Load event.
  """
  use Definition, schema: Define.Model.LoadView.V1
  alias Define.Model.ModuleFunctionArgsView

  @type t :: %__MODULE__{
          version: integer,
          source: ModuleFunctionArgsView.t(),
          destination: ModuleFunctionArgsView.t()
        }

  @derive Jason.Encoder
  defstruct version: 1,
            source: %ModuleFunctionArgsView{},
            destination: %ModuleFunctionArgsView{}
end

defmodule Define.Model.LoadView.V1 do
  @moduledoc false
  use Definition.Schema
  alias Define.Model.ModuleFunctionArgsView

  @impl true
  def s do
    schema(%Define.Model.LoadView{
      version: version(1),
      source: of_struct(ModuleFunctionArgsView),
      destination: of_struct(ModuleFunctionArgsView)
    })
  end
end
