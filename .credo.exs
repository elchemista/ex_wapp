%{
  configs: [
    %{
      name: "default",
      files: %{
        included: ["mix.exs", "config/", "lib/"],
        excluded: [~r"/_build/", ~r"/deps/", ~r"/lib/ex_wapp/wa_proto/"]
      },
      strict: false,
      color: true,
      checks: [
        {Credo.Check.Warning.StructFieldAmount, max_fields: 41}
      ]
    }
  ]
}
