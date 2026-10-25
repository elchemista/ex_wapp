defmodule ExWapp.QR.Renderer do
  @moduledoc """
  Contract for rendering a WhatsApp pairing payload with a host-owned QR library.

  `ExWapp.pair/1` returns the raw payload; applications can render it using any
  library or send it to a browser renderer. ExWapp has no QR package dependency.

  To use the manual `ExWapp.Live` runner, supply `qr_renderer: MyApp.QRRenderer`
  or set `config :ex_wapp, :qr_renderer, MyApp.QRRenderer`. Its `:qr_options`
  option is passed unchanged to `render/2`. The renderer returns SVG, PNG, or
  other file contents as binary/iodata; the runner writes them to `:qr_path`.
  Choose a path extension matching the format returned by the renderer.

  For example, if your application chooses the `qr_code` package:

      defmodule MyApp.QRRenderer do
        @behaviour ExWapp.QR.Renderer

        @impl true
        def render(payload, opts) do
          payload
          |> QRCode.create(Keyword.get(opts, :error_correction, :high))
          |> QRCode.render(Keyword.get(opts, :format, :svg))
        end
      end

  Return `{:error, reason}` when rendering fails. The runner returns that error
  and releases its QR subscription rather than waiting for an invisible code.
  """

  @callback render(payload :: String.t(), opts :: keyword()) ::
              {:ok, iodata()} | {:error, term()}
end
