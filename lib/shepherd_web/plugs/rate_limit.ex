defmodule ShepherdWeb.Plugs.RateLimit do
  @moduledoc """
  Rate limiting plug using Hammer.
  """

  import Plug.Conn

  def init(opts), do: opts

  def call(conn, opts) do
    if Application.get_env(:shepherd, :rate_limiting_enabled, true) do
      do_rate_limit(conn, opts)
    else
      conn
    end
  end

  defp do_rate_limit(conn, opts) do
    limit = Keyword.get(opts, :limit, 60)
    period = Keyword.get(opts, :period, 60_000)
    key = rate_limit_key(conn, opts)

    case Hammer.check_rate(key, period, limit) do
      {:allow, _count} ->
        conn

      {:deny, _limit} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(429, Jason.encode!(%{error: "Too many requests"}))
        |> halt()
    end
  end

  defp rate_limit_key(conn, opts) do
    prefix = Keyword.get(opts, :prefix, "default")
    ip = conn.remote_ip |> :inet.ntoa() |> to_string()
    "#{prefix}:#{ip}"
  end
end
