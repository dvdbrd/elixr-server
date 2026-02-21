defmodule ShepherdWeb.DomainComponents do
  @moduledoc """
  Shared UI components used across the domain sidebar LiveViews
  (App, Marketing, Funnel, Sales, HR, Customers).
  """

  use Phoenix.Component

  @doc """
  Renders a command card with [Done], [No], and [Push] action buttons.

  The buttons fire `command_done`, `command_dismiss`, and `command_push`
  phx-click events respectively, passing `phx-value-id` from the `:id` attr.
  """
  attr :title, :string, required: true
  attr :explanation, :string, required: true
  attr :id, :string, required: true

  def command_card(assigns) do
    ~H"""
    <div class="border-2 border-green-500 bg-terminal terminal-glow">
      <div class="p-3">
        <div class="flex items-start justify-between gap-4 mb-3">
          <h3 class="text-sm font-bold flex-1">{@title}</h3>

          <div class="relative group">
            <button class="border border-green-500 px-2 py-1 text-xs hover:bg-green-900 hover:bg-opacity-20">
              [?]
            </button>

            <div class="absolute right-0 top-full mt-2 w-64 p-3 bg-terminal border-2 border-green-500 terminal-glow opacity-0 invisible group-hover:opacity-100 group-hover:visible transition-all duration-200 z-10">
              <p class="text-xs opacity-90">{@explanation}</p>
            </div>
          </div>
        </div>

        <div class="flex gap-2 justify-end">
          <button
            phx-click="command_done"
            phx-value-id={@id}
            class="border border-green-400 text-green-400 px-3 py-1 text-xs hover:bg-green-900 hover:bg-opacity-20 uppercase"
          >
            [Done]
          </button>
          <button
            phx-click="command_dismiss"
            phx-value-id={@id}
            class="border border-red-500 text-red-500 px-3 py-1 text-xs hover:bg-red-900 hover:bg-opacity-20 uppercase"
          >
            [No]
          </button>
          <button
            phx-click="command_push"
            phx-value-id={@id}
            class="border border-yellow-500 text-yellow-500 px-3 py-1 text-xs hover:bg-yellow-900 hover:bg-opacity-20 uppercase"
          >
            [Push]
          </button>
        </div>
      </div>
    </div>
    """
  end

  @doc """
  Renders a sidebar navigation link with active state styling.
  """
  attr :navigate, :string, required: true
  attr :active, :boolean, required: true
  slot :inner_block

  def sidebar_nav_link(assigns) do
    ~H"""
    <.link
      navigate={@navigate}
      class={[
        "flex items-center w-full px-3 py-2 border transition-colors",
        if(@active,
          do: "bg-green-500 bg-opacity-20 border-green-400 text-green-300",
          else: "bg-terminal border-green-500 border-opacity-30 text-green-500 opacity-60 hover:bg-green-500 hover:bg-opacity-20 hover:border-green-400 hover:text-green-300 hover:opacity-100"
        )
      ]}
    >
      {render_slot(@inner_block)}
    </.link>
    """
  end
end
