defmodule ShepherdWeb.HealthController do
  use ShepherdWeb, :controller

  def check(conn, _params) do
    case Ecto.Adapters.SQL.query(Shepherd.Repo, "SELECT 1") do
      {:ok, _} ->
        json(conn, %{status: "ok", timestamp: DateTime.utc_now()})
      {:error, _} ->
        conn
        |> put_status(:service_unavailable)
        |> json(%{status: "error", message: "database unavailable"})
    end
  end
end
