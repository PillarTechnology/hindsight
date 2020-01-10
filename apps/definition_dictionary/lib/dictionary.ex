defmodule Dictionary do
  defmodule InvalidFieldError do
    defexception [:message, :field]
  end

  defmodule InvalidTypeError do
    defexception [:message]
  end

  @spec encode(list) :: {:ok, String.t()} | {:error, term}
  def encode(fields) do
    Jason.encode(fields)
  end

  @spec decode(binary | list | map) :: {:ok, Dictionary.Type.Decoder.t()} | {:error, term}
  def decode(json) when is_binary(json) do
    with {:ok, decoded_json} <- Jason.decode(json) do
      decode(decoded_json)
    end
  end

  def decode(list) when is_list(list) do
    Ok.transform(list, &decode/1)
  end

  def decode(%{"type" => type} = field) do
    with {:ok, module} <- Dictionary.Type.from_string(type) do
      struct(module)
      |> Dictionary.Type.Decoder.decode(field)
    end
  end

  @spec normalize(dictionary :: list, payload :: map) ::
          {:ok, map} | {:error, %{String.t() => term}}
  def normalize(dictionary, payload) when is_list(dictionary) and is_map(payload) do
    dictionary
    |> Enum.reduce(%{data: %{}, errors: %{}}, &normalize_field(payload, &1, &2))
    |> handle_normalization_context()
  end

  defp normalize_field(payload, %{name: name} = field, context) do
    value = Map.get(payload, name)

    case Dictionary.Type.Normalizer.normalize(field, value) do
      {:ok, new_value} -> update_in(context, [:data], &Map.put(&1, name, new_value))
      {:error, error} -> update_in(context, [:errors], &Map.put(&1, name, error))
    end
  end

  defp handle_normalization_context(%{errors: errors}) when errors != %{} do
    Ok.error(errors)
  end

  defp handle_normalization_context(%{data: data}), do: Ok.ok(data)
end