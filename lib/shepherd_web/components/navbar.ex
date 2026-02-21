defmodule ShepherdWeb.Navbar do
  use ShepherdWeb, :html
  import ShepherdWeb.CustomIcons

  attr :active_section, :string, default: "search"
  attr :notification_counts, :map, default: %{}

  def navbar(assigns) do
    ~H"""
    <nav
      class="fixed left-0 top-0 h-dvh flex flex-col justify-start py-4 px-2 bg-terminal border-r-2 border-green-500 w-16 md:w-40"
      style="box-shadow: 0 0 5px rgba(34, 197, 94, 0.15);"
    >
      <div class="flex flex-col space-y-3 flex-1">
        <.nav_icon
          icon="dashboard"
          section="hq"
          active={@active_section == "hq"}
          notification_count={Map.get(@notification_counts, "hq", 0)}
        />
        <.nav_icon
          icon="globe"
          section="website"
          active={@active_section == "website"}
          notification_count={Map.get(@notification_counts, "website", 0)}
        />
        <.nav_icon
          icon="code"
          section="app"
          active={@active_section == "app"}
          notification_count={Map.get(@notification_counts, "app", 0)}
        />
        <.nav_icon
          icon="megaphone"
          section="marketing"
          active={@active_section == "marketing"}
          notification_count={Map.get(@notification_counts, "marketing", 0)}
        />
        <.nav_icon
          icon="funnel"
          section="funnel"
          active={@active_section == "funnel"}
          notification_count={Map.get(@notification_counts, "funnel", 0)}
        />
        <.nav_icon
          icon="dollar"
          section="sales"
          active={@active_section == "sales"}
          notification_count={Map.get(@notification_counts, "sales", 0)}
        />
        <.nav_icon
          icon="briefcase"
          section="hr"
          active={@active_section == "hr"}
          notification_count={Map.get(@notification_counts, "hr", 0)}
        />
        <.nav_icon
          icon="customer_group"
          section="customers"
          active={@active_section == "customers"}
          notification_count={Map.get(@notification_counts, "customers", 0)}
        />
      </div>

      <div class="flex flex-col space-y-3 mt-auto">
        <.nav_icon
          icon="terminal"
          section="terminal"
          active={@active_section == "terminal"}
          notification_count={Map.get(@notification_counts, "terminal", 0)}
        />
        <.nav_icon
          icon="profile"
          section="account"
          active={@active_section == "account"}
          notification_count={Map.get(@notification_counts, "account", 0)}
        />
      </div>
    </nav>
    """
  end

  attr :icon, :string, required: true
  attr :section, :string, required: true
  attr :active, :boolean, required: true
  attr :notification_count, :integer, default: 0
  attr :class, :string, default: ""

  defp nav_icon(assigns) do
    ~H"""
    <.link
      navigate={get_section_path(@section)}
      class={[
        "relative flex items-center gap-3 px-3 py-2 border-2 uppercase text-xs",
        if(@active,
          do: "bg-green-500 bg-opacity-20 border-green-400 text-green-300",
          else:
            "bg-terminal border-green-500 border-opacity-20 text-green-500 text-opacity-60 hover:bg-green-500 hover:bg-opacity-20 hover:border-green-400 hover:text-green-300"
        ),
        @class
      ]}
      style={if(@active, do: "box-shadow: 0 0 2px rgba(34, 197, 94, 0.15);", else: "")}
      onmouseover={
        if(!@active, do: "this.style.boxShadow='0 0 2px rgba(34, 197, 94, 0.15)'", else: nil)
      }
      onmouseout={if(!@active, do: "this.style.boxShadow=''", else: nil)}
      title={String.capitalize(@section)}
    >
      <.custom_icon name={@icon} class="w-6 h-6 flex-shrink-0" />
      <span class="hidden md:inline text-sm font-medium">{String.capitalize(@section)}</span>

      <%= if @notification_count > 0 do %>
        <span
          class="absolute -top-1 -right-1 bg-red-500 text-white text-xs font-bold rounded-full min-w-[1.25rem] h-5 flex items-center justify-center px-1 border border-black"
          style="box-shadow: 0 0 4px rgba(239, 68, 68, 0.5);"
        >
          {if @notification_count > 99, do: "99+", else: @notification_count}
        </span>
      <% end %>
    </.link>
    """
  end

  defp get_section_path(section) do
    case section do
      "hq" -> "/"
      "website" -> "/website"
      "app" -> "/app"
      "marketing" -> "/marketing"
      "funnel" -> "/funnel"
      "sales" -> "/sales"
      "hr" -> "/hr"
      "customers" -> "/customers"
      "terminal" -> "/terminal"
      "account" -> "/users/settings"
      _ -> "/"
    end
  end
end
