defmodule RecordHelper do
  require Record
  import Record, only: [defrecord: 2, extract: 2]

  defmacro load_record(record, path) do
    fields = for {k, _} <- extract(record, from_lib: path), do: k
    elixir_name =
      record
      |> Atom.to_string
      |> Macro.camelize
      |> (fn(s) -> "Elixir." <> s end).()
      |> String.to_atom

    quote do
      defmodule unquote(elixir_name) do
        defstruct unquote(fields)

        # Load top layer of erlang record into the struct
        # TODO: unpack all layers
        def from_erlang(r) do
          [_name|fields_vals] = Tuple.to_list(r)
          zipped = List.zip([[:__struct__|unquote(fields)],
            [unquote(elixir_name)|fields_vals]])
          Map.new(zipped)
        end

        # Packs the level-1 elixir struct back into erlang tuple
        def to_erlang(s) do
          vals_in_order = (for f <- unquote(fields), do: Map.get(s, f))
          List.to_tuple([unquote(record)|vals_in_order])
        end

      end
    end
  end
end
