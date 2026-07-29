# credo:disable-for-this-file
defmodule WAWebProtobufsE2E.EmbeddedMusic do
  @moduledoc false
  defstruct musicContentMediaID: nil,
            songID: nil,
            author: nil,
            title: nil,
            artworkDirectPath: nil,
            artworkSHA256: nil,
            artworkEncSHA256: nil,
            artistAttribution: nil,
            countryBlocklist: nil,
            isExplicit: nil,
            artworkMediaKey: nil,
            musicSongStartTimeInMS: nil,
            derivedContentStartTimeInMS: nil,
            overlapDurationInMS: nil,
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
        |> encode_musicContentMediaID(msg)
        |> encode_songID(msg)
        |> encode_author(msg)
        |> encode_title(msg)
        |> encode_artworkDirectPath(msg)
        |> encode_artworkSHA256(msg)
        |> encode_artworkEncSHA256(msg)
        |> encode_artistAttribution(msg)
        |> encode_countryBlocklist(msg)
        |> encode_isExplicit(msg)
        |> encode_artworkMediaKey(msg)
        |> encode_musicSongStartTimeInMS(msg)
        |> encode_derivedContentStartTimeInMS(msg)
        |> encode_overlapDurationInMS(msg)
        |> encode_unknown_fields(msg)
      end
    )

    []

    [
      defp encode_musicContentMediaID(acc, msg) do
        try do
          case msg.musicContentMediaID do
            nil -> acc
            _ -> [acc, "\n", Protox.Encode.encode_string(msg.musicContentMediaID)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:musicContentMediaID, "invalid field value"),
                    __STACKTRACE__
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
      defp encode_author(acc, msg) do
        try do
          case msg.author do
            nil -> acc
            _ -> [acc, "\x1A", Protox.Encode.encode_string(msg.author)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:author, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_title(acc, msg) do
        try do
          case msg.title do
            nil -> acc
            _ -> [acc, "\"", Protox.Encode.encode_string(msg.title)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:title, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_artworkDirectPath(acc, msg) do
        try do
          case msg.artworkDirectPath do
            nil -> acc
            _ -> [acc, "*", Protox.Encode.encode_string(msg.artworkDirectPath)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:artworkDirectPath, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_artworkSHA256(acc, msg) do
        try do
          case msg.artworkSHA256 do
            nil -> acc
            _ -> [acc, "2", Protox.Encode.encode_bytes(msg.artworkSHA256)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:artworkSHA256, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_artworkEncSHA256(acc, msg) do
        try do
          case msg.artworkEncSHA256 do
            nil -> acc
            _ -> [acc, ":", Protox.Encode.encode_bytes(msg.artworkEncSHA256)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:artworkEncSHA256, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_artistAttribution(acc, msg) do
        try do
          case msg.artistAttribution do
            nil -> acc
            _ -> [acc, "B", Protox.Encode.encode_string(msg.artistAttribution)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:artistAttribution, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_countryBlocklist(acc, msg) do
        try do
          case msg.countryBlocklist do
            nil -> acc
            _ -> [acc, "J", Protox.Encode.encode_bytes(msg.countryBlocklist)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:countryBlocklist, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_isExplicit(acc, msg) do
        try do
          case msg.isExplicit do
            nil -> acc
            _ -> [acc, "P", Protox.Encode.encode_bool(msg.isExplicit)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:isExplicit, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_artworkMediaKey(acc, msg) do
        try do
          case msg.artworkMediaKey do
            nil -> acc
            _ -> [acc, "Z", Protox.Encode.encode_bytes(msg.artworkMediaKey)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:artworkMediaKey, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_musicSongStartTimeInMS(acc, msg) do
        try do
          case msg.musicSongStartTimeInMS do
            nil -> acc
            _ -> [acc, "`", Protox.Encode.encode_int64(msg.musicSongStartTimeInMS)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:musicSongStartTimeInMS, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_derivedContentStartTimeInMS(acc, msg) do
        try do
          case msg.derivedContentStartTimeInMS do
            nil -> acc
            _ -> [acc, "h", Protox.Encode.encode_int64(msg.derivedContentStartTimeInMS)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:derivedContentStartTimeInMS, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_overlapDurationInMS(acc, msg) do
        try do
          case msg.overlapDurationInMS do
            nil -> acc
            _ -> [acc, "p", Protox.Encode.encode_int64(msg.overlapDurationInMS)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:overlapDurationInMS, "invalid field value"),
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
          parse_key_value(bytes, struct(WAWebProtobufsE2E.EmbeddedMusic))
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
              {[musicContentMediaID: Protox.Decode.validate_string!(delimited)], rest}

            {2, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[songID: Protox.Decode.validate_string!(delimited)], rest}

            {3, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[author: Protox.Decode.validate_string!(delimited)], rest}

            {4, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[title: Protox.Decode.validate_string!(delimited)], rest}

            {5, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[artworkDirectPath: Protox.Decode.validate_string!(delimited)], rest}

            {6, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[artworkSHA256: delimited], rest}

            {7, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[artworkEncSHA256: delimited], rest}

            {8, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[artistAttribution: Protox.Decode.validate_string!(delimited)], rest}

            {9, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[countryBlocklist: delimited], rest}

            {10, _, bytes} ->
              {value, rest} = Protox.Decode.parse_bool(bytes)
              {[isExplicit: value], rest}

            {11, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[artworkMediaKey: delimited], rest}

            {12, _, bytes} ->
              {value, rest} = Protox.Decode.parse_int64(bytes)
              {[musicSongStartTimeInMS: value], rest}

            {13, _, bytes} ->
              {value, rest} = Protox.Decode.parse_int64(bytes)
              {[derivedContentStartTimeInMS: value], rest}

            {14, _, bytes} ->
              {value, rest} = Protox.Decode.parse_int64(bytes)
              {[overlapDurationInMS: value], rest}

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
        WAWebProtobufsE2E.EmbeddedMusic,
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
        1 => {:musicContentMediaID, {:scalar, ""}, :string},
        2 => {:songID, {:scalar, ""}, :string},
        3 => {:author, {:scalar, ""}, :string},
        4 => {:title, {:scalar, ""}, :string},
        5 => {:artworkDirectPath, {:scalar, ""}, :string},
        6 => {:artworkSHA256, {:scalar, ""}, :bytes},
        7 => {:artworkEncSHA256, {:scalar, ""}, :bytes},
        8 => {:artistAttribution, {:scalar, ""}, :string},
        9 => {:countryBlocklist, {:scalar, ""}, :bytes},
        10 => {:isExplicit, {:scalar, false}, :bool},
        11 => {:artworkMediaKey, {:scalar, ""}, :bytes},
        12 => {:musicSongStartTimeInMS, {:scalar, 0}, :int64},
        13 => {:derivedContentStartTimeInMS, {:scalar, 0}, :int64},
        14 => {:overlapDurationInMS, {:scalar, 0}, :int64}
      }
    end

    @deprecated "Use fields_defs()/0 instead"
    @spec defs_by_name() :: %{
            required(atom) => {non_neg_integer, Protox.Types.kind(), Protox.Types.type()}
          }
    def defs_by_name() do
      %{
        artistAttribution: {8, {:scalar, ""}, :string},
        artworkDirectPath: {5, {:scalar, ""}, :string},
        artworkEncSHA256: {7, {:scalar, ""}, :bytes},
        artworkMediaKey: {11, {:scalar, ""}, :bytes},
        artworkSHA256: {6, {:scalar, ""}, :bytes},
        author: {3, {:scalar, ""}, :string},
        countryBlocklist: {9, {:scalar, ""}, :bytes},
        derivedContentStartTimeInMS: {13, {:scalar, 0}, :int64},
        isExplicit: {10, {:scalar, false}, :bool},
        musicContentMediaID: {1, {:scalar, ""}, :string},
        musicSongStartTimeInMS: {12, {:scalar, 0}, :int64},
        overlapDurationInMS: {14, {:scalar, 0}, :int64},
        songID: {2, {:scalar, ""}, :string},
        title: {4, {:scalar, ""}, :string}
      }
    end
  )

  (
    @spec fields_defs() :: list(Protox.Field.t())
    def fields_defs() do
      [
        %{
          __struct__: Protox.Field,
          json_name: "musicContentMediaID",
          kind: {:scalar, ""},
          label: :optional,
          name: :musicContentMediaID,
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
          json_name: "author",
          kind: {:scalar, ""},
          label: :optional,
          name: :author,
          tag: 3,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "title",
          kind: {:scalar, ""},
          label: :optional,
          name: :title,
          tag: 4,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "artworkDirectPath",
          kind: {:scalar, ""},
          label: :optional,
          name: :artworkDirectPath,
          tag: 5,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "artworkSHA256",
          kind: {:scalar, ""},
          label: :optional,
          name: :artworkSHA256,
          tag: 6,
          type: :bytes
        },
        %{
          __struct__: Protox.Field,
          json_name: "artworkEncSHA256",
          kind: {:scalar, ""},
          label: :optional,
          name: :artworkEncSHA256,
          tag: 7,
          type: :bytes
        },
        %{
          __struct__: Protox.Field,
          json_name: "artistAttribution",
          kind: {:scalar, ""},
          label: :optional,
          name: :artistAttribution,
          tag: 8,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "countryBlocklist",
          kind: {:scalar, ""},
          label: :optional,
          name: :countryBlocklist,
          tag: 9,
          type: :bytes
        },
        %{
          __struct__: Protox.Field,
          json_name: "isExplicit",
          kind: {:scalar, false},
          label: :optional,
          name: :isExplicit,
          tag: 10,
          type: :bool
        },
        %{
          __struct__: Protox.Field,
          json_name: "artworkMediaKey",
          kind: {:scalar, ""},
          label: :optional,
          name: :artworkMediaKey,
          tag: 11,
          type: :bytes
        },
        %{
          __struct__: Protox.Field,
          json_name: "musicSongStartTimeInMS",
          kind: {:scalar, 0},
          label: :optional,
          name: :musicSongStartTimeInMS,
          tag: 12,
          type: :int64
        },
        %{
          __struct__: Protox.Field,
          json_name: "derivedContentStartTimeInMS",
          kind: {:scalar, 0},
          label: :optional,
          name: :derivedContentStartTimeInMS,
          tag: 13,
          type: :int64
        },
        %{
          __struct__: Protox.Field,
          json_name: "overlapDurationInMS",
          kind: {:scalar, 0},
          label: :optional,
          name: :overlapDurationInMS,
          tag: 14,
          type: :int64
        }
      ]
    end

    [
      @spec(field_def(atom) :: {:ok, Protox.Field.t()} | {:error, :no_such_field}),
      (
        def field_def(:musicContentMediaID) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "musicContentMediaID",
             kind: {:scalar, ""},
             label: :optional,
             name: :musicContentMediaID,
             tag: 1,
             type: :string
           }}
        end

        def field_def("musicContentMediaID") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "musicContentMediaID",
             kind: {:scalar, ""},
             label: :optional,
             name: :musicContentMediaID,
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
        def field_def(:author) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "author",
             kind: {:scalar, ""},
             label: :optional,
             name: :author,
             tag: 3,
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
             tag: 3,
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
             tag: 4,
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
             tag: 4,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:artworkDirectPath) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "artworkDirectPath",
             kind: {:scalar, ""},
             label: :optional,
             name: :artworkDirectPath,
             tag: 5,
             type: :string
           }}
        end

        def field_def("artworkDirectPath") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "artworkDirectPath",
             kind: {:scalar, ""},
             label: :optional,
             name: :artworkDirectPath,
             tag: 5,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:artworkSHA256) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "artworkSHA256",
             kind: {:scalar, ""},
             label: :optional,
             name: :artworkSHA256,
             tag: 6,
             type: :bytes
           }}
        end

        def field_def("artworkSHA256") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "artworkSHA256",
             kind: {:scalar, ""},
             label: :optional,
             name: :artworkSHA256,
             tag: 6,
             type: :bytes
           }}
        end

        []
      ),
      (
        def field_def(:artworkEncSHA256) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "artworkEncSHA256",
             kind: {:scalar, ""},
             label: :optional,
             name: :artworkEncSHA256,
             tag: 7,
             type: :bytes
           }}
        end

        def field_def("artworkEncSHA256") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "artworkEncSHA256",
             kind: {:scalar, ""},
             label: :optional,
             name: :artworkEncSHA256,
             tag: 7,
             type: :bytes
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
             tag: 8,
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
             tag: 8,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:countryBlocklist) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "countryBlocklist",
             kind: {:scalar, ""},
             label: :optional,
             name: :countryBlocklist,
             tag: 9,
             type: :bytes
           }}
        end

        def field_def("countryBlocklist") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "countryBlocklist",
             kind: {:scalar, ""},
             label: :optional,
             name: :countryBlocklist,
             tag: 9,
             type: :bytes
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
             tag: 10,
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
             tag: 10,
             type: :bool
           }}
        end

        []
      ),
      (
        def field_def(:artworkMediaKey) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "artworkMediaKey",
             kind: {:scalar, ""},
             label: :optional,
             name: :artworkMediaKey,
             tag: 11,
             type: :bytes
           }}
        end

        def field_def("artworkMediaKey") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "artworkMediaKey",
             kind: {:scalar, ""},
             label: :optional,
             name: :artworkMediaKey,
             tag: 11,
             type: :bytes
           }}
        end

        []
      ),
      (
        def field_def(:musicSongStartTimeInMS) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "musicSongStartTimeInMS",
             kind: {:scalar, 0},
             label: :optional,
             name: :musicSongStartTimeInMS,
             tag: 12,
             type: :int64
           }}
        end

        def field_def("musicSongStartTimeInMS") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "musicSongStartTimeInMS",
             kind: {:scalar, 0},
             label: :optional,
             name: :musicSongStartTimeInMS,
             tag: 12,
             type: :int64
           }}
        end

        []
      ),
      (
        def field_def(:derivedContentStartTimeInMS) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "derivedContentStartTimeInMS",
             kind: {:scalar, 0},
             label: :optional,
             name: :derivedContentStartTimeInMS,
             tag: 13,
             type: :int64
           }}
        end

        def field_def("derivedContentStartTimeInMS") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "derivedContentStartTimeInMS",
             kind: {:scalar, 0},
             label: :optional,
             name: :derivedContentStartTimeInMS,
             tag: 13,
             type: :int64
           }}
        end

        []
      ),
      (
        def field_def(:overlapDurationInMS) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "overlapDurationInMS",
             kind: {:scalar, 0},
             label: :optional,
             name: :overlapDurationInMS,
             tag: 14,
             type: :int64
           }}
        end

        def field_def("overlapDurationInMS") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "overlapDurationInMS",
             kind: {:scalar, 0},
             label: :optional,
             name: :overlapDurationInMS,
             tag: 14,
             type: :int64
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
    def default(:musicContentMediaID) do
      {:ok, ""}
    end,
    def default(:songID) do
      {:ok, ""}
    end,
    def default(:author) do
      {:ok, ""}
    end,
    def default(:title) do
      {:ok, ""}
    end,
    def default(:artworkDirectPath) do
      {:ok, ""}
    end,
    def default(:artworkSHA256) do
      {:ok, ""}
    end,
    def default(:artworkEncSHA256) do
      {:ok, ""}
    end,
    def default(:artistAttribution) do
      {:ok, ""}
    end,
    def default(:countryBlocklist) do
      {:ok, ""}
    end,
    def default(:isExplicit) do
      {:ok, false}
    end,
    def default(:artworkMediaKey) do
      {:ok, ""}
    end,
    def default(:musicSongStartTimeInMS) do
      {:ok, 0}
    end,
    def default(:derivedContentStartTimeInMS) do
      {:ok, 0}
    end,
    def default(:overlapDurationInMS) do
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
        go_package: "go.mau.fi/whatsmeow/proto/waE2E",
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
end
