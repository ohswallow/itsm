defmodule ItsmWeb.CrewLive.TableComponents do
  use ItsmWeb, :html

  import ItsmWeb.LiveUtils, only: [fetch_safe: 2]

  def crew_table(assigns) do
    assigns = assign_new(assigns, :action, fn -> [] end)

    ~H"""
    <.table id="crews" rows={@crews} row_click={@row_click}>
      <:col :let={{_id, crew}} label={gettext("Name")}>{crew.name}</:col>

      <:col :let={{_id, crew}} label={gettext("Description")}>{crew.description}</:col>

      <:col :let={{_id, crew}} label={gettext("Organization")}>
        <.common_code_label group="계열사" code={fetch_safe(crew.leader, :organization_code)} />
      </:col>

      <:col :let={{_id, crew}} label={gettext("Department")}>
        {fetch_safe(crew.leader, :department)}
      </:col>

      <:col :let={{_id, crew}} label={gettext("Leader")}>
        {fetch_safe(crew.leader, :display_name)}
      </:col>

      <%!--
         [수정된 부분]
         render_slot(@action, crew) -> render_slot(@action, {_id, crew})
         받는 쪽에서 {{_id, crew}} 패턴 매칭을 할 수 있도록 튜플로 넘겨줍니다.
      --%>
      <:col :let={{id, crew}} :if={@action != []} label="">{render_slot(@action, {id, crew})}</:col>
    </.table>
    """
  end
end
