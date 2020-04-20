defmodule Define.Model.AppView do
  @moduledoc """
  Top level representation of UI state
  """
  use Definition, schema: Define.Model.AppView.V1
  alias Define.Model.DataDefinitionView

  @type t :: %__MODULE__{
          version: integer,
          data_definitions: [DataDefinitionView.t()]
        }

  @derive Jason.Encoder
  defstruct version: 1,
            data_definitions: []
end

defmodule Define.Model.AppView.V1 do
  @moduledoc false
  use Definition.Schema
  alias Define.Model.DataDefinitionView

  @impl true
  def s do
    schema(%Define.Model.AppView{
      version: version(1),
      data_definitions: spec(is_list())
    })
  end
end
