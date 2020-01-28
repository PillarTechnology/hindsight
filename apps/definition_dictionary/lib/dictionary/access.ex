defmodule Dictionary.Access do
  @spec key(term, term) :: Access.access_fun(data :: struct | map, get_value :: term())
  def key(key, default \\ nil, opts \\ []) do
    &access_fun(key, default, &1, &2, &3, opts)
  end

  defp access_fun(key, default, :get, %module{} = data, next, _opts) do
    case module.fetch(data, key) do
      {:ok, value} -> next.(value)
      :error -> next.(default)
    end
  end

  defp access_fun(key, default, :get, list, next, opts) when is_list(list) do
    Enum.map(list, &access_fun(key, default, :get, &1, next, opts))
  end

  defp access_fun(key, default, :get, data, next, _opts) do
    next.(Map.get(data, key, default))
  end

  defp access_fun(key, _default, :get_and_update, %module{} = data, next, _opts) do
    module.get_and_update(data, key, next)
  end

  defp access_fun(key, default, :get_and_update, list, next, opts) when is_list(list) do
    spread? = Keyword.get(opts, :spread, false)

    {gets, updates} =
      Enum.with_index(list)
      |> Enum.map(fn {entry, index} ->
        wrapper = fn value ->
          with {get_value, update_value} <- next.(value) do
            case is_spreadable?(update_value, spread?) do
              true ->
                {get_value, Enum.at(update_value, index)}

              false ->
                {get_value, update_value}
            end
          end
        end

        access_fun(key, default, :get_and_update, entry, wrapper, opts)
      end)
      |> Enum.reduce({[], []}, fn {get, update}, {get_acc, update_acc} ->
        {[get | get_acc], [update | update_acc]}
      end)

    {Enum.reverse(gets), Enum.reverse(updates)}
  end

  defp access_fun(key, default, :get_and_update, data, next, _opts) do
    value = Map.get(data, key, default)

    case next.(value) do
      {get, update} -> {get, Map.put(data, key, update)}
      :pop -> {value, Map.delete(data, key)}
    end
  end

  defp is_spreadable?(value, spread?) do
    is_list(value) && spread?
  end
end