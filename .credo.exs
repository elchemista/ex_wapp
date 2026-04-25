%{
  configs: [
    %{
      name: "default",
      files: %{
        included: ["mix.exs", "config/", "lib/", "test/"],
        excluded: [~r"/_build/", ~r"/deps/"]
      },
      strict: false,
      color: true,
      checks: [
        {Credo.Check.Warning.StructFieldAmount, max_fields: 40}
      ]
    }
  ]
}
