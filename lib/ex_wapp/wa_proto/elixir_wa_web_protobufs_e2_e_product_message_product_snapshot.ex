# credo:disable-for-this-file
defmodule WAWebProtobufsE2E.ProductMessage.ProductSnapshot do
  @moduledoc false
  defstruct productImage: nil,
            productID: nil,
            title: nil,
            description: nil,
            currencyCode: nil,
            priceAmount1000: nil,
            retailerID: nil,
            URL: nil,
            productImageCount: nil,
            firstImageID: nil,
            salePriceAmount1000: nil,
            signedURL: nil,
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
        |> encode_productImage(msg)
        |> encode_productID(msg)
        |> encode_title(msg)
        |> encode_description(msg)
        |> encode_currencyCode(msg)
        |> encode_priceAmount1000(msg)
        |> encode_retailerID(msg)
        |> encode_URL(msg)
        |> encode_productImageCount(msg)
        |> encode_firstImageID(msg)
        |> encode_salePriceAmount1000(msg)
        |> encode_signedURL(msg)
        |> encode_unknown_fields(msg)
      end
    )

    []

    [
      defp encode_productImage(acc, msg) do
        try do
          case msg.productImage do
            nil -> acc
            _ -> [acc, "\n", Protox.Encode.encode_message(msg.productImage)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:productImage, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_productID(acc, msg) do
        try do
          case msg.productID do
            nil -> acc
            _ -> [acc, "\x12", Protox.Encode.encode_string(msg.productID)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:productID, "invalid field value"), __STACKTRACE__
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
      defp encode_description(acc, msg) do
        try do
          case msg.description do
            nil -> acc
            _ -> [acc, "\"", Protox.Encode.encode_string(msg.description)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:description, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_currencyCode(acc, msg) do
        try do
          case msg.currencyCode do
            nil -> acc
            _ -> [acc, "*", Protox.Encode.encode_string(msg.currencyCode)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:currencyCode, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_priceAmount1000(acc, msg) do
        try do
          case msg.priceAmount1000 do
            nil -> acc
            _ -> [acc, "0", Protox.Encode.encode_int64(msg.priceAmount1000)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:priceAmount1000, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_retailerID(acc, msg) do
        try do
          case msg.retailerID do
            nil -> acc
            _ -> [acc, ":", Protox.Encode.encode_string(msg.retailerID)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:retailerID, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_URL(acc, msg) do
        try do
          case msg."URL" do
            nil -> acc
            _ -> [acc, "B", Protox.Encode.encode_string(msg."URL")]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:URL, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_productImageCount(acc, msg) do
        try do
          case msg.productImageCount do
            nil -> acc
            _ -> [acc, "H", Protox.Encode.encode_uint32(msg.productImageCount)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:productImageCount, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_firstImageID(acc, msg) do
        try do
          case msg.firstImageID do
            nil -> acc
            _ -> [acc, "Z", Protox.Encode.encode_string(msg.firstImageID)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:firstImageID, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_salePriceAmount1000(acc, msg) do
        try do
          case msg.salePriceAmount1000 do
            nil -> acc
            _ -> [acc, "`", Protox.Encode.encode_int64(msg.salePriceAmount1000)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:salePriceAmount1000, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_signedURL(acc, msg) do
        try do
          case msg.signedURL do
            nil -> acc
            _ -> [acc, "j", Protox.Encode.encode_string(msg.signedURL)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:signedURL, "invalid field value"), __STACKTRACE__
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
          parse_key_value(bytes, struct(WAWebProtobufsE2E.ProductMessage.ProductSnapshot))
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

              {[
                 productImage:
                   Protox.MergeMessage.merge(
                     msg.productImage,
                     WAWebProtobufsE2E.ImageMessage.decode!(delimited)
                   )
               ], rest}

            {2, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[productID: Protox.Decode.validate_string!(delimited)], rest}

            {3, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[title: Protox.Decode.validate_string!(delimited)], rest}

            {4, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[description: Protox.Decode.validate_string!(delimited)], rest}

            {5, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[currencyCode: Protox.Decode.validate_string!(delimited)], rest}

            {6, _, bytes} ->
              {value, rest} = Protox.Decode.parse_int64(bytes)
              {[priceAmount1000: value], rest}

            {7, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[retailerID: Protox.Decode.validate_string!(delimited)], rest}

            {8, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[URL: Protox.Decode.validate_string!(delimited)], rest}

            {9, _, bytes} ->
              {value, rest} = Protox.Decode.parse_uint32(bytes)
              {[productImageCount: value], rest}

            {11, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[firstImageID: Protox.Decode.validate_string!(delimited)], rest}

            {12, _, bytes} ->
              {value, rest} = Protox.Decode.parse_int64(bytes)
              {[salePriceAmount1000: value], rest}

            {13, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[signedURL: Protox.Decode.validate_string!(delimited)], rest}

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
        WAWebProtobufsE2E.ProductMessage.ProductSnapshot,
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
        1 => {:productImage, {:scalar, nil}, {:message, WAWebProtobufsE2E.ImageMessage}},
        2 => {:productID, {:scalar, ""}, :string},
        3 => {:title, {:scalar, ""}, :string},
        4 => {:description, {:scalar, ""}, :string},
        5 => {:currencyCode, {:scalar, ""}, :string},
        6 => {:priceAmount1000, {:scalar, 0}, :int64},
        7 => {:retailerID, {:scalar, ""}, :string},
        8 => {:URL, {:scalar, ""}, :string},
        9 => {:productImageCount, {:scalar, 0}, :uint32},
        11 => {:firstImageID, {:scalar, ""}, :string},
        12 => {:salePriceAmount1000, {:scalar, 0}, :int64},
        13 => {:signedURL, {:scalar, ""}, :string}
      }
    end

    @deprecated "Use fields_defs()/0 instead"
    @spec defs_by_name() :: %{
            required(atom) => {non_neg_integer, Protox.Types.kind(), Protox.Types.type()}
          }
    def defs_by_name() do
      %{
        URL: {8, {:scalar, ""}, :string},
        currencyCode: {5, {:scalar, ""}, :string},
        description: {4, {:scalar, ""}, :string},
        firstImageID: {11, {:scalar, ""}, :string},
        priceAmount1000: {6, {:scalar, 0}, :int64},
        productID: {2, {:scalar, ""}, :string},
        productImage: {1, {:scalar, nil}, {:message, WAWebProtobufsE2E.ImageMessage}},
        productImageCount: {9, {:scalar, 0}, :uint32},
        retailerID: {7, {:scalar, ""}, :string},
        salePriceAmount1000: {12, {:scalar, 0}, :int64},
        signedURL: {13, {:scalar, ""}, :string},
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
          json_name: "productImage",
          kind: {:scalar, nil},
          label: :optional,
          name: :productImage,
          tag: 1,
          type: {:message, WAWebProtobufsE2E.ImageMessage}
        },
        %{
          __struct__: Protox.Field,
          json_name: "productID",
          kind: {:scalar, ""},
          label: :optional,
          name: :productID,
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
          json_name: "description",
          kind: {:scalar, ""},
          label: :optional,
          name: :description,
          tag: 4,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "currencyCode",
          kind: {:scalar, ""},
          label: :optional,
          name: :currencyCode,
          tag: 5,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "priceAmount1000",
          kind: {:scalar, 0},
          label: :optional,
          name: :priceAmount1000,
          tag: 6,
          type: :int64
        },
        %{
          __struct__: Protox.Field,
          json_name: "retailerID",
          kind: {:scalar, ""},
          label: :optional,
          name: :retailerID,
          tag: 7,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "URL",
          kind: {:scalar, ""},
          label: :optional,
          name: :URL,
          tag: 8,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "productImageCount",
          kind: {:scalar, 0},
          label: :optional,
          name: :productImageCount,
          tag: 9,
          type: :uint32
        },
        %{
          __struct__: Protox.Field,
          json_name: "firstImageID",
          kind: {:scalar, ""},
          label: :optional,
          name: :firstImageID,
          tag: 11,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "salePriceAmount1000",
          kind: {:scalar, 0},
          label: :optional,
          name: :salePriceAmount1000,
          tag: 12,
          type: :int64
        },
        %{
          __struct__: Protox.Field,
          json_name: "signedURL",
          kind: {:scalar, ""},
          label: :optional,
          name: :signedURL,
          tag: 13,
          type: :string
        }
      ]
    end

    [
      @spec(field_def(atom) :: {:ok, Protox.Field.t()} | {:error, :no_such_field}),
      (
        def field_def(:productImage) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "productImage",
             kind: {:scalar, nil},
             label: :optional,
             name: :productImage,
             tag: 1,
             type: {:message, WAWebProtobufsE2E.ImageMessage}
           }}
        end

        def field_def("productImage") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "productImage",
             kind: {:scalar, nil},
             label: :optional,
             name: :productImage,
             tag: 1,
             type: {:message, WAWebProtobufsE2E.ImageMessage}
           }}
        end

        []
      ),
      (
        def field_def(:productID) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "productID",
             kind: {:scalar, ""},
             label: :optional,
             name: :productID,
             tag: 2,
             type: :string
           }}
        end

        def field_def("productID") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "productID",
             kind: {:scalar, ""},
             label: :optional,
             name: :productID,
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
        def field_def(:description) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "description",
             kind: {:scalar, ""},
             label: :optional,
             name: :description,
             tag: 4,
             type: :string
           }}
        end

        def field_def("description") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "description",
             kind: {:scalar, ""},
             label: :optional,
             name: :description,
             tag: 4,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:currencyCode) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "currencyCode",
             kind: {:scalar, ""},
             label: :optional,
             name: :currencyCode,
             tag: 5,
             type: :string
           }}
        end

        def field_def("currencyCode") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "currencyCode",
             kind: {:scalar, ""},
             label: :optional,
             name: :currencyCode,
             tag: 5,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:priceAmount1000) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "priceAmount1000",
             kind: {:scalar, 0},
             label: :optional,
             name: :priceAmount1000,
             tag: 6,
             type: :int64
           }}
        end

        def field_def("priceAmount1000") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "priceAmount1000",
             kind: {:scalar, 0},
             label: :optional,
             name: :priceAmount1000,
             tag: 6,
             type: :int64
           }}
        end

        []
      ),
      (
        def field_def(:retailerID) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "retailerID",
             kind: {:scalar, ""},
             label: :optional,
             name: :retailerID,
             tag: 7,
             type: :string
           }}
        end

        def field_def("retailerID") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "retailerID",
             kind: {:scalar, ""},
             label: :optional,
             name: :retailerID,
             tag: 7,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:URL) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "URL",
             kind: {:scalar, ""},
             label: :optional,
             name: :URL,
             tag: 8,
             type: :string
           }}
        end

        def field_def("URL") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "URL",
             kind: {:scalar, ""},
             label: :optional,
             name: :URL,
             tag: 8,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:productImageCount) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "productImageCount",
             kind: {:scalar, 0},
             label: :optional,
             name: :productImageCount,
             tag: 9,
             type: :uint32
           }}
        end

        def field_def("productImageCount") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "productImageCount",
             kind: {:scalar, 0},
             label: :optional,
             name: :productImageCount,
             tag: 9,
             type: :uint32
           }}
        end

        []
      ),
      (
        def field_def(:firstImageID) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "firstImageID",
             kind: {:scalar, ""},
             label: :optional,
             name: :firstImageID,
             tag: 11,
             type: :string
           }}
        end

        def field_def("firstImageID") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "firstImageID",
             kind: {:scalar, ""},
             label: :optional,
             name: :firstImageID,
             tag: 11,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:salePriceAmount1000) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "salePriceAmount1000",
             kind: {:scalar, 0},
             label: :optional,
             name: :salePriceAmount1000,
             tag: 12,
             type: :int64
           }}
        end

        def field_def("salePriceAmount1000") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "salePriceAmount1000",
             kind: {:scalar, 0},
             label: :optional,
             name: :salePriceAmount1000,
             tag: 12,
             type: :int64
           }}
        end

        []
      ),
      (
        def field_def(:signedURL) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "signedURL",
             kind: {:scalar, ""},
             label: :optional,
             name: :signedURL,
             tag: 13,
             type: :string
           }}
        end

        def field_def("signedURL") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "signedURL",
             kind: {:scalar, ""},
             label: :optional,
             name: :signedURL,
             tag: 13,
             type: :string
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
    def default(:productImage) do
      {:ok, nil}
    end,
    def default(:productID) do
      {:ok, ""}
    end,
    def default(:title) do
      {:ok, ""}
    end,
    def default(:description) do
      {:ok, ""}
    end,
    def default(:currencyCode) do
      {:ok, ""}
    end,
    def default(:priceAmount1000) do
      {:ok, 0}
    end,
    def default(:retailerID) do
      {:ok, ""}
    end,
    def default(:URL) do
      {:ok, ""}
    end,
    def default(:productImageCount) do
      {:ok, 0}
    end,
    def default(:firstImageID) do
      {:ok, ""}
    end,
    def default(:salePriceAmount1000) do
      {:ok, 0}
    end,
    def default(:signedURL) do
      {:ok, ""}
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
