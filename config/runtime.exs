import Config

# config/runtime.exs is executed for all environments, including
# during releases. It is executed after compilation and before the
# system starts, so it is typically used to load production configuration
# and secrets from environment variables or elsewhere. Do not define
# any compile-time configuration in here, as it won't be applied.
# The block below contains prod specific runtime configuration.

# ## Using releases
#
# If you use `mix release`, you need to explicitly enable the server
# by passing the PHX_SERVER=true when you start it:
#
#     PHX_SERVER=true bin/shepherd start
#
# Alternatively, you can use `mix phx.gen.release` to generate a `bin/server`
# script that automatically sets the env var above.
if System.get_env("PHX_SERVER") do
  config :shepherd, ShepherdWeb.Endpoint, server: true
end

if config_env() == :prod do
  database_url =
    System.get_env("DATABASE_URL") ||
      raise """
      environment variable DATABASE_URL is missing.
      For example: ecto://USER:PASS@HOST/DATABASE
      """

  maybe_ipv6 = if System.get_env("ECTO_IPV6") in ~w(true 1), do: [:inet6], else: []

  ssl_enabled = System.get_env("DATABASE_SSL") != "false"

  ssl_opts =
    if ssl_enabled do
      if System.get_env("DATABASE_SSL_VERIFY") == "none" do
        [verify: :verify_none]
      else
        [verify: :verify_peer, cacerts: :public_key.cacerts_get()]
      end
    else
      []
    end

  config :shepherd, Shepherd.Repo,
    ssl: ssl_enabled,
    ssl_opts: ssl_opts,
    url: database_url,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "2"),
    socket_options: maybe_ipv6

  # The secret key base is used to sign/encrypt cookies and other secrets.
  # A default value is used in config/dev.exs and config/test.exs but you
  # want to use a different value for prod and you most likely don't want
  # to check this value into version control, so we use an environment
  # variable instead.
  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  host = System.get_env("PHX_HOST") || raise "environment variable PHX_HOST is missing"
  port = String.to_integer(System.get_env("PORT") || "4000")

  config :shepherd, :dns_cluster_query, System.get_env("DNS_CLUSTER_QUERY")

  config :shepherd, ShepherdWeb.Endpoint,
    url: [host: host, port: 443, scheme: "https"],
    http: [
      # Enable IPv6 and bind on all interfaces.
      # Set it to  {0, 0, 0, 0, 0, 0, 0, 1} for local network only access.
      # See the documentation on https://hexdocs.pm/bandit/Bandit.html#t:options/0
      # for details about using IPv6 vs IPv4 and loopback vs public addresses.
      ip: {0, 0, 0, 0, 0, 0, 0, 0},
      port: port
    ],
    secret_key_base: secret_key_base,
    force_ssl: [hsts: true, rewrite_on: [:x_forwarded_proto]]

  # ## SSL Support
  #
  # To get SSL working, you will need to add the `https` key
  # to your endpoint configuration:
  #
  #     config :shepherd, ShepherdWeb.Endpoint,
  #       https: [
  #         ...,
  #         port: 443,
  #         cipher_suite: :strong,
  #         keyfile: System.get_env("SOME_APP_SSL_KEY_PATH"),
  #         certfile: System.get_env("SOME_APP_SSL_CERT_PATH")
  #       ]
  #
  # The `cipher_suite` is set to `:strong` to support only the
  # latest and more secure SSL ciphers. This means old browsers
  # and clients may not be supported. You can set it to
  # `:compatible` for wider support.
  #
  # `:keyfile` and `:certfile` expect an absolute path to the key
  # and cert in disk or a relative path inside priv, for example
  # "priv/ssl/server.key". For all supported SSL configuration
  # options, see https://hexdocs.pm/plug/Plug.SSL.html#configure/1
  #
  # We also recommend setting `force_ssl` in your config/prod.exs,
  # ensuring no data is ever sent via http, always redirecting to https:
  #
  #     config :shepherd, ShepherdWeb.Endpoint,
  #       force_ssl: [hsts: true]
  #
  # Check `Plug.SSL` for all available options in `force_ssl`.

  # Configure the mailer for production
  mailgun_api_key =
    System.get_env("MAILGUN_API_KEY") ||
      raise "environment variable MAILGUN_API_KEY is missing for production email delivery"

  mailgun_domain =
    System.get_env("MAILGUN_DOMAIN") ||
      raise "environment variable MAILGUN_DOMAIN is missing for production email delivery"

  config :shepherd, Shepherd.Mailer,
    adapter: Swoosh.Adapters.Mailgun,
    api_key: mailgun_api_key,
    domain: mailgun_domain
end

# Configure Anthropic API for all environments
config :shepherd, :anthropic,
  api_key: System.get_env("ANTHROPIC_API_KEY"),
  model: System.get_env("ANTHROPIC_MODEL") || "claude-3-5-sonnet-20241022",
  max_tokens: String.to_integer(System.get_env("ANTHROPIC_MAX_TOKENS") || "4096")

# Configure Oban for background jobs
config :shepherd, Oban,
  repo: Shepherd.Repo,
  queues: [default: 10],
  plugins: [
    # Prune completed jobs after 24 hours
    {Oban.Plugins.Pruner, max_age: 86_400},
    {Oban.Plugins.Cron,
     crontab: [
       {"0 * * * *", Shepherd.Workers.ExpirationWorker},
       {"30 * * * *", Shepherd.Workers.MetricsAggregationWorker}
     ]}
  ]
