defmodule Subastas.Mixfile do
  use Mix.Project

  def project do
    [app: :subastas,
     version: "0.0.1",
     elixir: "~> 1.0",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps]
  end

  # Configuration for the OTP application
  #
  # Type `mix help compile.app` for more information
  def application do
    mod = {Main, []}
    if Mix.env == :test do
      mod = []
    end
    [applications: [:logger],
     env: [node: :"seba@192.168.5.104", port: 3001, mode: :primary],
     mod: mod]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type `mix help deps` for more examples and options
  defp deps do
    [{:elli, github: "knutin/elli"},
     {:json,   "~> 0.3.0"}]
  end
end
