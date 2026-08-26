defmodule Itsm.Workb do
  @moduledoc """
  데이터를 받아 Wobb API로 쪽지 전송
  """
  require Logger

  defstruct [:recipient, :title, :body]

  alias Finch.Response

  @config Application.compile_env(:itsm, __MODULE__, [])
  @url @config[:url]
  @srv_code @config[:srv_code]
  @sender @config[:sender]
  @sender_alias @config[:sender_alias]

  @headers [{"Content-Type", "application/x-www-form-urlencoded; charset=utf-8"}]

  @response_code %{
    "0" => "정상처리됨",
    "32" => "파라미터유효성검증오류",
    "33" => "서버코드가없습니다.",
    "34" => "수신직원번호가없습니다.",
    "35" => "발신직원번호가없습니다.",
    "36" => "쪽지제목이없습니다.",
    "37" => "쪽지본문이없습니다.",
    "38" => "등록된시스템정보가없습니다.",
    "48" => "등록된발신자정보중에IP가없습니다.",
    "64" => "기타예외메시지출력"
  }

  # Workb에 쪽지를 여러개를 보낼때(List형 Map)
  def send_message(rows) when is_list(rows) do
    Enum.each(rows, &send_message/1)
  end

  # Workb 타입으로 쪽지전송시
  def send_message(row = %__MODULE__{}) do
    row
    |> build_body()
    |> make_request()
    |> handle_response(row)
  end

  # Map 타입으로 메세지 전송시 Workb 구조체로 변경
  def send_message(row) when is_map(row) do
    struct(__MODULE__, row) |> send_message()
  end

  defp build_body(row = %__MODULE__{}) do
    %{
      "SRV_CODE" => @srv_code,
      "SAVEOPTION" => "1",
      "SEND" => @sender,
      "RECIPIENT" => row.recipient,
      "TITLE" => row.title,
      "BODY" => row.body,
      "SENDER_ALIAS" => @sender_alias
    }
    |> URI.encode_query()
  end

  defp make_request(body) do
    Finch.build(:post, @url, @headers, body) |> Finch.request(Itsm.Finch)
  end

  # Workb에서 정상적으로 응답 메세지 제공시 응답코드 추출
  defp handle_response({:ok, %Response{status: 200, body: body}}, row = %__MODULE__{}) do
    body
    |> String.trim()
    |> String.split(";")
    |> List.first()
    |> handle_response(row)
  end

  # Workb 응답코드 0일때는 정상
  defp handle_response("0", _row), do: :ok

  # Work 응답코드 오류 코드일때는 오류메세지 출력
  defp handle_response(error_code, row = %__MODULE__{}) do
    """
    알림 API 응답 에러
    - 응답코드: #{inspect(error_code)}
    - 오류내용: #{Map.get(@response_code, error_code, "서버에서 잘못된 응답코드 보냄")}
    - 수신번호: #{row.recipient}
    - 발신번호: #{@sender}
    - 제목: #{row.title}
    - 내용: #{row.body}
    """
    |> Logger.error()

    :error
  end
end
