# credo:disable-for-this-file
defmodule WAStatusAttributions.StatusAttribution.Music do
  @moduledoc false
  defstruct authorName: nil,
            songID: nil,
            title: nil,
            author: nil,
            artistAttribution: nil,
            isExplicit: nil,
            __uf__: []

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
        |> encode_authorName(msg)
        |> encode_songID(msg)
        |> encode_title(msg)
        |> encode_author(msg)
        |> encode_artistAttribution(msg)
        |> encode_isExplicit(msg)
        |> encode_unknown_fields(msg)
      end
    )

    []

    [
      defp encode_authorName(acc, msg) do
        try do
          case msg.authorName do
            nil -> acc
            _ -> [acc, "\n", Protox.Encode.encode_string(msg.authorName)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:authorName, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_songID(acc, msg) do
        try do
          case msg.songID do
            nil -> acc
            _ -> [acc, "\x12", Protox.Encode.encode_string(msg.songID)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:songID, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_title(acc, msg) do
        try do
          case msg.title do
            nil -> acc
            _ -> [acc, "\x1A", Protox.Encode.encode_string(msg.title)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:title, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_author(acc, msg) do
        try do
          case msg.author do
            nil -> acc
            _ -> [acc, "\"", Protox.Encode.encode_string(msg.author)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:author, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_artistAttribution(acc, msg) do
        try do
          case msg.artistAttribution do
            nil -> acc
            _ -> [acc, "*", Protox.Encode.encode_string(msg.artistAttribution)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:artistAttribution, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_isExplicit(acc, msg) do
        try do
          case msg.isExplicit do
            nil -> acc
            _ -> [acc, "0", Protox.Encode.encode_bool(msg.isExplicit)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:isExplicit, "invalid field value"), __STACKTRACE__
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
          parse_key_value(bytes, struct(WAStatusAttributions.StatusAttribution.Music))
        end
      )
    )

    (
      @spec parse_key_value(binary, struct) :: struct
      defp parse_key_value(<<>>, msg) do
        msg
      end

      defp parse_key_value(bytes, msg) do
        {field, rest} =
          case Protox.Decode.parse_key(bytes) do
            {0, _, _} ->
              raise %Protox.IllegalTagError{}

            {1, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[authorName: Protox.Decode.validate_string!(delimited)], rest}

            {2, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[songID: Protox.Decode.validate_string!(delimited)], rest}

            {3, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[title: Protox.Decode.validate_string!(delimited)], rest}

            {4, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[author: Protox.Decode.validate_string!(delimited)], rest}

            {5, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[artistAttribution: Protox.Decode.validate_string!(delimited)], rest}

            {6, _, bytes} ->
              {value, rest} = Protox.Decode.parse_bool(bytes)
              {[isExplicit: value], rest}

            {tag, wire_type, rest} ->
              {value, rest} = Protox.Decode.parse_unknown(tag, wire_type, rest)

              {[
                 {msg.__struct__.unknown_fields_name(),
                  [value | msg.__struct__.unknown_fields(msg)]}
               ], rest}
          end

        msg_updated = struct(msg, field)
        parse_key_value(rest, msg_updated)
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
        WAStatusAttributions.StatusAttribution.Music,
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
        1 => {:authorName, {:scalar, ""}, :string},
        2 => {:songID, {:scalar, ""}, :string},
        3 => {:title, {:scalar, ""}, :string},
        4 => {:author, {:scalar, ""}, :string},
        5 => {:artistAttribution, {:scalar, ""}, :string},
        6 => {:isExplicit, {:scalar, false}, :bool}
      }
    end

    @deprecated "Use fields_defs()/0 instead"
    @spec defs_by_name() :: %{
            required(atom) => {non_neg_integer, Protox.Types.kind(), Protox.Types.type()}
          }
    def defs_by_name() do
      %{
        artistAttribution: {5, {:scalar, ""}, :string},
        author: {4, {:scalar, ""}, :string},
        authorName: {1, {:scalar, ""}, :string},
        isExplicit: {6, {:scalar, false}, :bool},
        songID: {2, {:scalar, ""}, :string},
        title: {3, {:scalar, ""}, :string}
      }
    end
  )

  (
    @spec fields_defs() :: list(Protox.Field.t())
    def fields_defs() do
      [
        %{
          __struct__: Protox.Field,
          json_name: "authorName",
          kind: {:scalar, ""},
          label: :optional,
          name: :authorName,
          tag: 1,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "songID",
          kind: {:scalar, ""},
          label: :optional,
          name: :songID,
          tag: 2,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "title",
          kind: {:scalar, ""},
          label: :optional,
          name: :title,
          tag: 3,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "author",
          kind: {:scalar, ""},
          label: :optional,
          name: :author,
          tag: 4,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "artistAttribution",
          kind: {:scalar, ""},
          label: :optional,
          name: :artistAttribution,
          tag: 5,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "isExplicit",
          kind: {:scalar, false},
          label: :optional,
          name: :isExplicit,
          tag: 6,
          type: :bool
        }
      ]
    end

    [
      @spec(field_def(atom) :: {:ok, Protox.Field.t()} | {:error, :no_such_field}),
      (
        def field_def(:authorName) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "authorName",
             kind: {:scalar, ""},
             label: :optional,
             name: :authorName,
             tag: 1,
             type: :string
           }}
        end

        def field_def("authorName") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "authorName",
             kind: {:scalar, ""},
             label: :optional,
             name: :authorName,
             tag: 1,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:songID) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "songID",
             kind: {:scalar, ""},
             label: :optional,
             name: :songID,
             tag: 2,
             type: :string
           }}
        end

        def field_def("songID") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "songID",
             kind: {:scalar, ""},
             label: :optional,
             name: :songID,
             tag: 2,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:title) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "title",
             kind: {:scalar, ""},
             label: :optional,
             name: :title,
             tag: 3,
             type: :string
           }}
        end

        def field_def("title") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "title",
             kind: {:scalar, ""},
             label: :optional,
             name: :title,
             tag: 3,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:author) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "author",
             kind: {:scalar, ""},
             label: :optional,
             name: :author,
             tag: 4,
             type: :string
           }}
        end

        def field_def("author") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "author",
             kind: {:scalar, ""},
             label: :optional,
             name: :author,
             tag: 4,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:artistAttribution) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "artistAttribution",
             kind: {:scalar, ""},
             label: :optional,
             name: :artistAttribution,
             tag: 5,
             type: :string
           }}
        end

        def field_def("artistAttribution") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "artistAttribution",
             kind: {:scalar, ""},
             label: :optional,
             name: :artistAttribution,
             tag: 5,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:isExplicit) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "isExplicit",
             kind: {:scalar, false},
             label: :optional,
             name: :isExplicit,
             tag: 6,
             type: :bool
           }}
        end

        def field_def("isExplicit") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "isExplicit",
             kind: {:scalar, false},
             label: :optional,
             name: :isExplicit,
             tag: 6,
             type: :bool
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
    @spec required_fields() :: []
    def required_fields() do
      []
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
    def default(:authorName) do
      {:ok, ""}
    end,
    def default(:songID) do
      {:ok, ""}
    end,
    def default(:title) do
      {:ok, ""}
    end,
    def default(:author) do
      {:ok, ""}
    end,
    def default(:artistAttribution) do
      {:ok, ""}
    end,
    def default(:isExplicit) do
      {:ok, false}
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
        go_package: "go.mau.fi/whatsmeow/proto/waStatusAttributions",
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
