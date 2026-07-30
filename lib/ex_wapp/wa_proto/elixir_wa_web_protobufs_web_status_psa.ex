# credo:disable-for-this-file
defmodule WAWebProtobufsWeb.StatusPSA do
  @moduledoc false
  defstruct campaignID: nil, campaignExpirationTimestamp: nil, __uf__: []

  (
    (
      @spec encode(struct) :: {:ok, iodata} | {:error, any}
      def encode(msg) do
        try do
          {:ok, encode!(msg)}
        rescue
          e in [Protox.EncodingError, Protox.RequiredFieldsError] -> {:error, e}
        end
      end

      @spec encode!(struct) :: iodata | no_return
      def encode!(msg) do
        []
        |> encode_campaignID(msg)
        |> encode_campaignExpirationTimestamp(msg)
        |> encode_unknown_fields(msg)
      end
    )

    []

    [
      defp encode_campaignID(acc, msg) do
        try do
          case msg.campaignID do
            nil -> raise Protox.RequiredFieldsError.new([:campaignID])
            _ -> [acc, "\xE0\x02", Protox.Encode.encode_uint64(msg.campaignID)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:campaignID, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_campaignExpirationTimestamp(acc, msg) do
        try do
          case msg.campaignExpirationTimestamp do
            nil -> acc
            _ -> [acc, "\xE8\x02", Protox.Encode.encode_uint64(msg.campaignExpirationTimestamp)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:campaignExpirationTimestamp, "invalid field value"),
                    __STACKTRACE__
        end
      end
    ]

    defp encode_unknown_fields(acc, msg) do
      Enum.reduce(msg.__struct__.unknown_fields(msg), acc, fn {tag, wire_type, bytes}, acc ->
        case wire_type do
          0 ->
            [acc, Protox.Encode.make_key_bytes(tag, :int32), bytes]

          1 ->
            [acc, Protox.Encode.make_key_bytes(tag, :double), bytes]

          2 ->
            len_bytes = bytes |> byte_size() |> Protox.Varint.encode()
            [acc, Protox.Encode.make_key_bytes(tag, :packed), len_bytes, bytes]

          5 ->
            [acc, Protox.Encode.make_key_bytes(tag, :float), bytes]
        end
      end)
    end
  )

  (
    (
      @spec decode(binary) :: {:ok, struct} | {:error, any}
      def decode(bytes) do
        try do
          {:ok, decode!(bytes)}
        rescue
          e in [Protox.DecodingError, Protox.IllegalTagError, Protox.RequiredFieldsError] ->
            {:error, e}
        end
      end

      (
        @spec decode!(binary) :: struct | no_return
        def decode!(bytes) do
          {msg, set_fields} = parse_key_value([], bytes, struct(WAWebProtobufsWeb.StatusPSA))

          case [:campaignID] -- set_fields do
            [] -> msg
            missing_fields -> raise Protox.RequiredFieldsError.new(missing_fields)
          end
        end
      )
    )

    (
      @spec parse_key_value([atom], binary, struct) :: {struct, [atom]}
      defp parse_key_value(set_fields, <<>>, msg) do
        {msg, set_fields}
      end

      defp parse_key_value(set_fields, bytes, msg) do
        {new_set_fields, field, rest} =
          case Protox.Decode.parse_key(bytes) do
            {0, _, _} ->
              raise %Protox.IllegalTagError{}

            {44, _, bytes} ->
              {value, rest} = Protox.Decode.parse_uint64(bytes)
              {[:campaignID | set_fields], [campaignID: value], rest}

            {45, _, bytes} ->
              {value, rest} = Protox.Decode.parse_uint64(bytes)

              {[:campaignExpirationTimestamp | set_fields], [campaignExpirationTimestamp: value],
               rest}

            {tag, wire_type, rest} ->
              {value, rest} = Protox.Decode.parse_unknown(tag, wire_type, rest)

              {set_fields,
               [
                 {msg.__struct__.unknown_fields_name(),
                  [value | msg.__struct__.unknown_fields(msg)]}
               ], rest}
          end

        msg_updated = struct(msg, field)
        parse_key_value(new_set_fields, rest, msg_updated)
      end
    )

    []
  )

  (
    @spec json_decode(iodata(), keyword()) :: {:ok, struct()} | {:error, any()}
    def json_decode(input, opts \\ []) do
      try do
        {:ok, json_decode!(input, opts)}
      rescue
        e in Protox.JsonDecodingError -> {:error, e}
      end
    end

    @spec json_decode!(iodata(), keyword()) :: struct() | no_return()
    def json_decode!(input, opts \\ []) do
      {json_library_wrapper, json_library} = Protox.JsonLibrary.get_library(opts, :decode)

      Protox.JsonDecode.decode!(
        input,
        WAWebProtobufsWeb.StatusPSA,
        &json_library_wrapper.decode!(json_library, &1)
      )
    end

    @spec json_encode(struct(), keyword()) :: {:ok, iodata()} | {:error, any()}
    def json_encode(msg, opts \\ []) do
      try do
        {:ok, json_encode!(msg, opts)}
      rescue
        e in Protox.JsonEncodingError -> {:error, e}
      end
    end

    @spec json_encode!(struct(), keyword()) :: iodata() | no_return()
    def json_encode!(msg, opts \\ []) do
      {json_library_wrapper, json_library} = Protox.JsonLibrary.get_library(opts, :encode)
      Protox.JsonEncode.encode!(msg, &json_library_wrapper.encode!(json_library, &1))
    end
  )

  (
    @deprecated "Use fields_defs()/0 instead"
    @spec defs() :: %{
            required(non_neg_integer) => {atom, Protox.Types.kind(), Protox.Types.type()}
          }
    def defs() do
      %{
        44 => {:campaignID, {:scalar, 0}, :uint64},
        45 => {:campaignExpirationTimestamp, {:scalar, 0}, :uint64}
      }
    end

    @deprecated "Use fields_defs()/0 instead"
    @spec defs_by_name() :: %{
            required(atom) => {non_neg_integer, Protox.Types.kind(), Protox.Types.type()}
          }
    def defs_by_name() do
      %{
        campaignExpirationTimestamp: {45, {:scalar, 0}, :uint64},
        campaignID: {44, {:scalar, 0}, :uint64}
      }
    end
  )

  (
    @spec fields_defs() :: list(Protox.Field.t())
    def fields_defs() do
      [
        %{
          __struct__: Protox.Field,
          json_name: "campaignID",
          kind: {:scalar, 0},
          label: :required,
          name: :campaignID,
          tag: 44,
          type: :uint64
        },
        %{
          __struct__: Protox.Field,
          json_name: "campaignExpirationTimestamp",
          kind: {:scalar, 0},
          label: :optional,
          name: :campaignExpirationTimestamp,
          tag: 45,
          type: :uint64
        }
      ]
    end

    [
      @spec(field_def(atom) :: {:ok, Protox.Field.t()} | {:error, :no_such_field}),
      (
        def field_def(:campaignID) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "campaignID",
             kind: {:scalar, 0},
             label: :required,
             name: :campaignID,
             tag: 44,
             type: :uint64
           }}
        end

        def field_def("campaignID") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "campaignID",
             kind: {:scalar, 0},
             label: :required,
             name: :campaignID,
             tag: 44,
             type: :uint64
           }}
        end

        []
      ),
      (
        def field_def(:campaignExpirationTimestamp) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "campaignExpirationTimestamp",
             kind: {:scalar, 0},
             label: :optional,
             name: :campaignExpirationTimestamp,
             tag: 45,
             type: :uint64
           }}
        end

        def field_def("campaignExpirationTimestamp") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "campaignExpirationTimestamp",
             kind: {:scalar, 0},
             label: :optional,
             name: :campaignExpirationTimestamp,
             tag: 45,
             type: :uint64
           }}
        end

        []
      ),
      def field_def(_) do
        {:error, :no_such_field}
      end
    ]
  )

  (
    @spec unknown_fields(struct) :: [{non_neg_integer, Protox.Types.tag(), binary}]
    def unknown_fields(msg) do
      msg.__uf__
    end

    @spec unknown_fields_name() :: :__uf__
    def unknown_fields_name() do
      :__uf__
    end

    @spec clear_unknown_fields(struct) :: struct
    def clear_unknown_fields(msg) do
      struct!(msg, [{unknown_fields_name(), []}])
    end
  )

  (
    @spec required_fields() :: [:campaignID]
    def required_fields() do
      [:campaignID]
    end
  )

  (
    @spec syntax() :: atom()
    def syntax() do
      :proto2
    end
  )

  [
    @spec(default(atom) :: {:ok, boolean | integer | String.t() | float} | {:error, atom}),
    def default(:campaignID) do
      {:ok, 0}
    end,
    def default(:campaignExpirationTimestamp) do
      {:ok, 0}
    end,
    def default(_) do
      {:error, :no_such_field}
    end
  ]

  (
    @spec file_options() :: struct()
    def file_options() do
      file_options = %{
        __struct__: Protox.Google.Protobuf.FileOptions,
        __uf__: [],
        cc_enable_arenas: nil,
        cc_generic_services: nil,
        csharp_namespace: nil,
        deprecated: nil,
        go_package: "go.mau.fi/whatsmeow/proto/waWeb",
        java_generate_equals_and_hash: nil,
        java_generic_services: nil,
        java_multiple_files: nil,
        java_outer_classname: nil,
        java_package: nil,
        java_string_check_utf8: nil,
        objc_class_prefix: nil,
        optimize_for: nil,
        php_class_prefix: nil,
        php_generic_services: nil,
        php_metadata_namespace: nil,
        php_namespace: nil,
        py_generic_services: nil,
        ruby_package: nil,
        swift_prefix: nil,
        uninterpreted_option: []
      }

      case function_exported?(Google.Protobuf.FileOptions, :decode!, 1) do
        true ->
          bytes =
            file_options |> Protox.Google.Protobuf.FileOptions.encode!() |> :binary.list_to_bin()

          apply(Google.Protobuf.FileOptions, :decode!, [bytes])

        false ->
          file_options
      end
    end
  )

  @type t :: %__MODULE__{}
end
