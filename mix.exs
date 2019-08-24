defmodule GpsReader.MixProject do
  use Mix.Project

  def project do
    [
      app: :gps_reader,
      version: "0.1.0",
      elixir: "~> 1.10-dev",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {GpsReader.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:circuits_uart, "~> 1.3"}
    ]
  end
end
