NimbleCSV.define(Extract.Decode.Csv.Parser, [])

defmodule Extract.Decode.Csv do
  use Definition, schema: Extract.Decode.Csv.V1

  @type t :: %__MODULE__{
          version: integer,
          headers: list,
          skip_first_line: boolean
        }

  @derive Jason.Encoder
  defstruct version: 1,
            headers: nil,
            skip_first_line: false

  defimpl Extract.Step, for: __MODULE__ do
    import Extract.Context

    def execute(step, context) do
      source = fn opts ->
        get_stream(context, opts)
        |> Stream.transform(%{skip: step.skip_first_line}, fn
          message, %{skip: false} = acc ->
            {[Extract.Message.update_data(message, &parse(&1, step.headers))], acc}

          _message, %{skip: true} = acc ->
            {[], %{acc | skip: false}}
        end)
      end

      context
      |> set_source(source)
      |> Ok.ok()
    end

    defp parse(data, headers) do
      Extract.Decode.Csv.Parser.parse_string(data, skip_headers: false)
      |> List.flatten()
      |> zip(headers)
      |> Map.new()
    end

    defp zip(b, a) do
      Enum.zip(a, b)
    end
  end
end

defmodule Extract.Decode.Csv.V1 do
  use Definition.Schema

  @impl true
  def s do
    schema(%Extract.Decode.Csv{
      version: version(1),
      headers: spec(is_list() and not_nil?()),
      skip_first_line: spec(is_boolean() and not_nil?())
    })
  end
end
