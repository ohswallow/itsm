defmodule Itsm.PubSub.Helper do
  import Phoenix.LiveView, only: [connected?: 1]

  @doc """
  주어진 도메인(domain)과 옵션(opts)을 기반으로 대상 PubSub 토픽에 현재 프로세스를 구독합니다.

  첫 번째 인자로 `socket`이 전달될 경우, LiveView가 연결된(`connected?`) 상태일 때만 `assigns.current_user` 정보를 추출하여 구독을 진행하고, 파이프라인 체이닝을 위해 `socket`을 그대로 반환합니다. `nil`이 전달될 경우 현재 프로세스(self)에서 즉시 구독 로직을 실행합니다.

  ## 옵션 (Options)
    * `:id` - 단일 항목(상세 내역) 구독을 위한 리소스 ID (예: 게시글 ID).
    * `:only` - 구독할 토픽의 범위 설정. `:all`(기본값), `:list`, `:detail` 중 하나를 선택합니다.
    * `:is_admin` - `true`일 경우, 계열사(affiliate)과 무관하게 `admin` 전용 토픽을 구독합니다.
    * `:affiliate` - 강제로 지정할 계열사 코드. 지정하지 않을 경우 `socket.assigns.current_user`의 계열사을 따릅니다.

  ## 구독 규칙 (Topic Rules)
    * `affiliate` 값이 `"CM"`, `"FG"`, 혹은 `nil`인 경우 `"common"` 공통 계열사으로 자동 치환됩니다.
    * 관리자(`is_admin`)가 아닐 때, 자신의 계열사가 `"common"`이 아니라면 자신의 고유 계열사 토픽과 `"common"` 토픽을 **동시에 구독**합니다.
    * **List 토픽:** `:only`가 `:all` 또는 `:list`일 때 `{affiliate}:{domain}` 형태의 토픽을 구독합니다.
    * **Detail 토픽:** `:id`가 존재하고 `:only`가 `:all` 또는 `:detail`일 때 `{affiliate}:{domain}:{id}` 형태의 토픽을 구독합니다.
  """
  @spec subscribe(Phoenix.LiveView.Socket.t() | nil, atom() | String.t(), keyword()) ::
          Phoenix.LiveView.Socket.t() | :ok | {:error, term()} | nil
  def subscribe(socket_or_nil, domain, opts \\ [])

  def subscribe(%Phoenix.LiveView.Socket{} = socket, domain, opts) do
    if connected?(socket) do
      current_user = socket.assigns.current_user
      affiliate = Keyword.get(opts, :affiliate, find_affiliate(current_user))

      subscribe(nil, domain, Keyword.put(opts, :affiliate, affiliate))
    end

    socket
  end

  def subscribe(nil, domain, opts) do
    id = Keyword.get(opts, :id)
    only = Keyword.get(opts, :only, :all)
    is_admin = Keyword.get(opts, :is_admin)

    affiliate =
      opts
      |> Keyword.get(:affiliate)
      |> then(&if &1 in ["CM", "FG", nil], do: "common", else: &1)

    if only in [:all, :list] do
      if is_admin do
        Phoenix.PubSub.subscribe(Itsm.PubSub, "admin:#{get_topic(domain)}")
      else
        Phoenix.PubSub.subscribe(Itsm.PubSub, "#{affiliate}:#{get_topic(domain)}")

        if affiliate != "common",
          do: Phoenix.PubSub.subscribe(Itsm.PubSub, "common:#{get_topic(domain)}")
      end
    end

    if id && only in [:all, :detail] do
      if is_admin do
        Phoenix.PubSub.subscribe(Itsm.PubSub, "admin:#{get_topic(domain)}:#{id}")
      else
        Phoenix.PubSub.subscribe(Itsm.PubSub, "#{affiliate}:#{get_topic(domain)}:#{id}")

        if affiliate != "common",
          do: Phoenix.PubSub.subscribe(Itsm.PubSub, "common:#{get_topic(domain)}:#{id}")
      end
    end
  end

  @doc """
  주어진 도메인(domain)과 옵션(opts)을 바탕으로, 해당 계열사(affiliate) 토픽과 `admin` 토픽에 동시에 메시지를 브로드캐스트합니다.

  `Phoenix.PubSub.broadcast_from/4`를 사용하므로, **메시지를 전송하는 현재 프로세스(`self()`)를 제외한** 다른 모든 프로세스(구독자)들에게 `{:pubsub, message}` 형태의 튜플로 메시지가 배달됩니다.

  ## 옵션 (Options)
    * `:id` - 단일 항목(상세 내역) 토픽에 브로드캐스트하기 위한 리소스 ID.
    * `:only` - 브로드캐스트할 토픽의 범위 설정. `:all`(기본값), `:list`, `:detail` 중 하나를 선택합니다.
    * `:affiliate` - 메시지를 전송할 대상 계열사 코드. 지정하지 않을 경우 `extract_affiliate(message)`를 통해 메시지 본문에서 계열사를 자동으로 추출합니다.

  ## 브로드캐스트 및 라우팅 규칙 (Routing Rules)
    * `affiliate` 값이 `"CM"`, `"FG"`, 혹은 `nil`인 경우 `"common"` 공통 계열사 토픽으로 자동 치환되어 전송됩니다.
    * 메시지는 해당 계열사 토픽뿐만 아니라, **`admin` 전용 토픽에도 항상 함께 발송(Dual Broadcast)**됩니다. 따라서 관리자는 계열사와 무관하게 모든 메시지를 수신할 수 있습니다.
    * **List 토픽 전송:** `:only`가 `:all` 또는 `:list`일 때 `{affiliate}:{domain}` 및 `admin:{domain}` 토픽으로 발송됩니다.
    * **Detail 토픽 전송:** `:id`가 존재하고 `:only`가 `:all` 또는 `:detail`일 때 `{affiliate}:{domain}:{id}` 및 `admin:{domain}:{id}` 토픽으로 발송됩니다.
  """
  @spec broadcast(atom() | String.t(), term(), keyword()) :: :ok | {:error, term()} | nil
  def broadcast(domain, message, opts \\ []) do
    id = Keyword.get(opts, :id)
    only = Keyword.get(opts, :only, :all)

    affiliate =
      opts
      |> Keyword.get(:affiliate, extract_affiliate(message))
      |> then(&if &1 in ["CM", "FG", nil], do: "common", else: &1)

    if only in [:all, :list] do
      topic = "#{get_topic(domain)}"

      Phoenix.PubSub.broadcast_from(
        Itsm.PubSub,
        self(),
        "#{affiliate}:#{topic}",
        {:pubsub, message}
      )

      Phoenix.PubSub.broadcast_from(Itsm.PubSub, self(), "admin:#{topic}", {:pubsub, message})
    end

    if id && only in [:all, :detail] do
      topic = "#{get_topic(domain)}:#{id}"

      Phoenix.PubSub.broadcast_from(
        Itsm.PubSub,
        self(),
        "#{affiliate}:#{topic}",
        {:pubsub, message}
      )

      Phoenix.PubSub.broadcast_from(Itsm.PubSub, self(), "admin:#{topic}", {:pubsub, message})
    end
  end

  defp get_topic(%{__struct__: module}), do: extract_domain(module)

  defp get_topic(module) when is_atom(module) do
    if module |> to_string() |> String.starts_with?("Elixir."),
      do: extract_domain(module),
      else: module
  end

  defp get_topic(anything_else), do: anything_else

  defp extract_domain(input) do
    input
    |> Module.split()
    |> List.last()
    |> Macro.underscore()
  end

  defp extract_affiliate({_user, _event, data}), do: find_affiliate(data)
  defp extract_affiliate({_event, data}), do: find_affiliate(data)
  defp extract_affiliate(data), do: find_affiliate(data)

  defp find_affiliate({data, _extra}) when is_map(data), do: find_affiliate(data)

  defp find_affiliate(%{affiliate: affiliate}), do: affiliate
  defp find_affiliate(%{organization_code: organization_code}), do: organization_code
  defp find_affiliate(%{organization: organization_code}), do: organization_code
  defp find_affiliate(%{category: %{affiliate: affiliate}}), do: affiliate

  defp find_affiliate(_), do: nil
end
