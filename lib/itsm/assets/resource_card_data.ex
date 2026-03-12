defprotocol Itsm.Assets.ResourceCardData do
  @doc """
  각 인스턴스 struct를 resource_card 컴포넌트가 이해하는   %{name, badge, details} 형태로 변환한다.
  """
  def to_card_item(instance)
end
