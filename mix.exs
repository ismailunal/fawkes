defmodule Fawkes.MixProject do
  use Mix.Project

  @version "0.1.0"

  def project do
    [
      app: :fawkes,
      version: @version,
      elixir: "~> 1.8",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package(),
      name: "Fawkes",
      source_url: "https://github.com/keathley/fawkes",
      docs: docs()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:slack, "~> 0.20"},
      {:gen_stage, "~> 1.0"},
      {:ex_doc, "~> 0.19", only: [:dev, :test]},
      {:redix, "~> 0.10"},
    ]
  end

  def description do
    """
    Fawkes is a system for building chatbots.
    """
  end

  def package do
    [
      name: "fawkes",
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/keathley/fawkes"}
    ]
  end

  def docs do
    [
      source_ref: "v#{@version}",
      source_url: "https://github.com/keathley/fawkes",
      main: "Fawkes",
      groups_for_modules: [
        "Events": [
          Fawkes.Event.Message,
          Fawkes.Event.ReactionAdded,
          Fawkes.Event.ReactionRemoved,
          Fawkes.Event.TopicChanged,
          Fawkes.Event.ChannelJoined,
          Fawkes.Event.ChannelLeft,
        ]
      ]
    ]
  end
end
