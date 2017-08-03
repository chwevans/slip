#Code.append_path "_build/prod/lib/relex/ebin"
#if Code.ensure_loaded?(Relex.Release) do
#  defmodule Slip.Release do
#    use Relex.Release
#
#    def name, do: "slip"
#    def applications, do: [:slip]
#    def lib_dirs, do: ["deps", :code.lib_dir()]
#  end
#end

defmodule Slip.Mixfile do
  use Mix.Project

  def project do
    [ 
      app: :slip,
      version: "1.0.0",
      elixir: ">= 0.14.1",
      deps: deps,
      #release: Slip.Release,
      exlager_level: :debug,
      exlager_truncation_size: 8096,
    ]
  end

  # Configuration for the OTP application
  def application do
    [
      applications: [
        :exlager,
        :cowboy,
      ],
      mod: {Slip, []},
      env: [
        action_modules: [],
        web_port: 4000,
        authentication_function: {Slip.Web, :authenticate},
        authorization_function: {Slip.Web, :authorize},
      ],
    ]
  end

  defp deps do
    [
      {:cowboy, github: "extend/cowboy"},
      {:exlager, github: "khia/exlager"},
      {:exjsx, git: "git@github.com:talentdeficit/exjsx.git"},
    ]
  end
end
