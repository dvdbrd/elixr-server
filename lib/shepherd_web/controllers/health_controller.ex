defmodule ShepherdWeb.HealthController do
  use ShepherdWeb, :controller

  def check(conn, _params) do
    try do
      Shepherd.Repo.query!("SELECT 1")
      json(conn, %{status: "ok"})
    rescue
      _ ->
        conn
        |> put_status(:service_unavailable)
        |> json(%{status: "error"})
    end
  end
end
