# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Itsm.Repo.insert!(%Itsm.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.
alias Itsm.Repo
alias Itsm.Service.Category

alias Itsm.Accounts.User
alias Itsm.Team.Crew
alias Itsm.Team.Member

# alias Itsm.Service.Approval
# alias Itsm.Service.Request

mike =
  %User{}
  |> User.registration_changeset(%{
    email: "mike@sample.com",
    display_name: "mike",
    employee_number: "2853861",
    organization_code: "B0",
    organization: "KB국민은행",
    password: "123412341234",
    department: "인프라시스템부",
    department_code: "883310",
    role: "admin"
  })
  |> Repo.insert!()

nicole =
  %User{}
  |> User.registration_changeset(%{
    email: "nicole@sample.com",
    display_name: "nicole",
    employee_number: "2853862",
    organization_code: "B0",
    organization: "KB국민은행",
    password: "123412341234",
    department: "인프라시스템부",
    department_code: "883310",
    role: "auditor"
  })
  |> Repo.insert!()

alex =
  %User{}
  |> User.registration_changeset(%{
    email: "alex@sample.com",
    display_name: "alex",
    employee_number: "2853863",
    organization_code: "B0",
    organization: "KB국민은행",
    password: "123412341234",
    department: "인프라시스템부",
    department_code: "883310",
    role: "general"
  })
  |> Repo.insert!()

jase =
  %User{}
  |> User.registration_changeset(%{
    email: "jase@sample.com",
    display_name: "jase",
    employee_number: "2853864",
    organization_code: "B0",
    organization: "KB국민은행",
    password: "123412341234",
    department: "인프라시스템부",
    department_code: "883310",
    role: "general"
  })
  |> Repo.insert!()

mary =
  %User{}
  |> User.registration_changeset(%{
    email: "mary@sample.com",
    display_name: "mary",
    organization_code: "B0",
    employee_number: "2853865",
    organization: "KB국민은행",
    password: "123412341234",
    department: "인프라시스템부",
    department_code: "883310",
    role: "general"
  })
  |> Repo.insert!()

ca =
  %User{}
  |> User.registration_changeset(%{
    email: "ca@sample.com",
    display_name: "ca",
    organization_code: "C0",
    employee_number: "2853866",
    organization: "KB국민카드",
    password: "123412341234",
    department: "정보보호부",
    department_code: "813219",
    role: "general"
  })
  |> Repo.insert!()

cq =
  %User{}
  |> User.registration_changeset(%{
    email: "cq@sample.com",
    display_name: "ca",
    organization_code: "B0",
    organization: "KB국민은행",
    employee_number: "2853867",
    password: "123412341234",
    department: "정보보호부",
    department_code: "813211",
    role: "general"
  })
  |> Repo.insert!()

cr =
  %User{}
  |> User.registration_changeset(%{
    email: "cr@sample.com",
    display_name: "ca",
    organization_code: "C0",
    organization: "KB국민카드",
    employee_number: "2853867",
    password: "123412341234",
    department: "정보보호부",
    department_code: "813219",
    role: "general"
  })
  |> Repo.insert!()

aaaaa =
  %Crew{}
  |> Crew.changeset(%{
    name: "AAAAA",
    description: "K리전 공동존 가상머신 처리팀",
    leader_id: alex.id
  })
  |> Repo.insert!()

bbbbb =
  %Crew{}
  |> Crew.changeset(%{
    name: "BBBBB",
    description: "K리전 은행존 가상머신 처리팀",
    leader_id: mary.id
  })
  |> Repo.insert!()

%Member{
  crew_id: aaaaa.id,
  user_id: alex.id
}
|> Repo.insert!()

%Member{
  crew_id: aaaaa.id,
  user_id: jase.id
}
|> Repo.insert!()

%Member{
  crew_id: aaaaa.id,
  user_id: mike.id
}
|> Repo.insert!()

%Member{
  crew_id: bbbbb.id,
  user_id: mary.id
}
|> Repo.insert!()

%Member{
  crew_id: bbbbb.id,
  user_id: nicole.id
}
|> Repo.insert!()

%Category{
  name: "가상 머신 신청",
  description: "
  K리전 공동존 가상 머신 신규 구성
  ",
  group: "K_리전_공통",
  active: true,
  request_name: "common_k_create_vm",
  affiliate: "FG",
  duration: 80,
  category: "서버",
  assignee_crew_id: aaaaa.id
}
|> Repo.insert!()

%Category{
  name: "가상 머신 스펙 증설",
  description: "
  K리전 은행존 가상머신 vCore/Memory Scale up 신청
  ",
  group: "K_리전_은행",
  active: true,
  request_name: "bank_k_resize_vm",
  affiliate: "B0",
  duration: 70,
  category: "서버",
  assignee_crew_id: bbbbb.id
}
|> Repo.insert!()

defmodule Itsm.Repo.Seeds.InsertCommonCodes do
  use Ecto.Migration
  import Ecto.Query

  @field_group_map %{
    "env" => "운영_구분",
    "location" => "장소",
    "category" => "카테고리",
    "affiliate" => "계열사",
    "region_type" => "지역_유형",
    "infra_type" => "인프라_유형",
    "reason" => "사유",
    "os_image" => "운영체제",
    "os_version" => "운영체제_버전",
    "linux" => "리눅스",
    "windows" => "윈도우",
    "role" => "역할"
  }

  def run do
    Repo.transaction(fn ->
      try do
        IO.puts("Common codes seeding started...")

        # init_reset_data!()

        init_insert_data!()

        IO.puts("Common codes seeding finished successfully.")
      rescue
        e ->
          IO.puts("Seeding failed: #{inspect(e)}")
          Repo.rollback(:seeding_failed)
      end
    end)
  end

  defp init_insert_data! do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    env = [
      %{code: "운영", label: "운영", description: "운영 환경입니다."},
      %{code: "스테이징", label: "스테이징", description: "스테이징 환경입니다."},
      %{code: "개발", label: "개발", description: "개발 환경입니다."},
      %{code: "DR", label: "DR", description: "DR 환경입니다."}
    ]

    location = [
      %{code: "본사", label: "본사", description: "본사 입니다."},
      %{code: "여의도IT센터", label: "여의도IT센터", description: "여의도IT센터 입니다."},
      %{code: "김포IT센터", label: "김포IT센터", description: "김포IT센터 입니다."},
      %{code: "영업점", label: "영업점", description: "영업점 입니다."}
    ]

    category = [
      %{code: "서버", label: "서버", description: "서버 자산입니다."},
      %{code: "네트워크", label: "네트워크", description: "네트워크 자산입니다."},
      %{code: "스토리지", label: "스토리지", description: "스토리지 자산입니다."},
      %{code: "어플라이언스", label: "어플라이언스", description: "어플라이언스 자산입니다."}
    ]

    affiliate = [
      %{code: "CM", label: "KB공통", description: "KB공통 계열사입니다."},
      %{code: "A0", label: "KB자산운용", description: "KB자산운용 계열사입니다."},
      %{code: "B0", label: "KB국민은행", description: "KB국민은행 계열사입니다."},
      %{code: "C0", label: "KB국민카드", description: "KB국민카드 계열사입니다."},
      %{code: "D0", label: "KB데이타시스템즈", description: "KB데이타시스템즈 계열사입니다."},
      %{code: "FG", label: "KB금융지주", description: "KB금융지주 계열사입니다."},
      %{code: "I0", label: "KB신용정보", description: "KB신용정보 계열사입니다."},
      %{code: "L0", label: "KB캐피탈", description: "KB캐피탈 계열사입니다."},
      %{code: "M0", label: "KB저축은행", description: "KB저축은행 계열사입니다."},
      %{code: "N4", label: "KB라이프생명", description: "KB라이프생명 계열사입니다."},
      %{code: "N1", label: "KB손해보험", description: "KB손해보험 계열사입니다."},
      %{code: "S2", label: "KB증권", description: "KB증권 계열사입니다."},
      %{code: "T0", label: "KB부동산신탁", description: "KB부동산신탁 계열사입니다."},
      %{code: "V0", label: "KB인베스트먼트", description: "KB인베스트먼트 계열사입니다."}
    ]

    region_type = [
      %{code: "P_리전", label: "P_리전", description: "P_리전 입니다."},
      %{code: "K_리전_공통", label: "K_리전_공통", description: "K_리전_공통 입니다."},
      %{code: "K_리전_은행", label: "K_리전_은행", description: "K_리전_은행 입니다."},
      %{code: "레거시", label: "레거시", description: "레거시 입니다."}
    ]

    infra_type = [
      %{code: "bare_metal", label: "베어메탈", description: "일반 x86/Unix 물리 장비"},
      %{code: "hypervisor", label: "하이퍼바이저", description: "VMware ESXi 등 가상화를 제공하는 물리 호스트"},
      %{code: "private_cloud", label: "프라이빗 클라우드", description: "사내 하이퍼바이저 위에서 구동되는 가상 머신(VM)"},
      %{code: "public_cloud", label: "퍼블릭 클라우드", description: "AWS, Azure 등 외부 클라우드 자원"},
      %{code: "mainframe", label: "메인프레임", description: "코어뱅킹용 메인프레임 시스템"}
    ]

    reason = [
      %{code: "휴가", label: "휴가", description: "휴가로 인한 대결입니다."},
      %{code: "출장", label: "출장", description: "출장으로 인한 대결입니다."},
      %{code: "파견", label: "파견", description: "파견으로 인한 대결입니다."},
      %{code: "교육", label: "교육", description: "교육으로 인한 대결입니다."},
      %{code: "기타", label: "기타", description: "기타 사유로 인한 대결입니다."}
    ]

    os_image = [
      %{code: "리눅스", label: "리눅스", description: "리눅스 이미지입니다."},
      %{code: "윈도우", label: "윈도우", description: "윈도우 이미지입니다."}
    ]

    os_version = [
      %{code: "RHEL 9.6 (보안)", label: "RHEL 9.6 (보안)", description: "RHEL 9.6 보안 버전입니다."},
      %{code: "RHEL 9.6 (일반)", label: "RHEL 9.6 (일반)", description: "RHEL 9.6 일반 버전입니다."},
      %{
        code: "Windows Server 2022",
        label: "Windows Server 2022",
        description: "Windows Server 2022 버전입니다."
      },
      %{
        code: "Windows Server 2025",
        label: "Windows Server 2025",
        description: "Windows Server 2025 버전입니다."
      }
    ]

    linux = [
      %{code: "RHEL 9.6 (보안)", label: "RHEL 9.6 (보안)", description: "RHEL 9.6 보안 버전입니다."},
      %{code: "RHEL 9.6 (일반)", label: "RHEL 9.6 (일반)", description: "RHEL 9.6 일반 버전입니다."}
    ]

    windows = [
      %{
        code: "Windows Server 2022",
        label: "Windows Server 2022",
        description: "Windows Server 2022 버전입니다."
      },
      %{
        code: "Windows Server 2025",
        label: "Windows Server 2025",
        description: "Windows Server 2025 버전입니다."
      }
    ]

    role = [
      %{code: "관리자", label: "관리자", description: "관리자 권한입니다."},
      %{code: "일반 사용자", label: "일반 사용자", description: "일반 사용자 권한입니다."},
      %{code: "감사자", label: "감사자", description: "감사자 권한입니다."}
    ]

    prepare_items = fn data, group_code ->
      data
      |> Enum.with_index()
      |> Enum.map(fn {item, index} ->
        %{
          id: Ecto.UUID.autogenerate() |> Ecto.UUID.dump!(),
          group_code: group_code,
          code: item.code,
          label: item.label,
          description: item.description,
          sort_order: index,
          is_active: true,
          inserted_at: now,
          updated_at: now
        }
      end)
    end

    full_list =
      prepare_items.(env, @field_group_map["env"]) ++
        prepare_items.(location, @field_group_map["location"]) ++
        prepare_items.(category, @field_group_map["category"]) ++
        prepare_items.(affiliate, @field_group_map["affiliate"]) ++
        prepare_items.(region_type, @field_group_map["region_type"]) ++
        prepare_items.(infra_type, @field_group_map["infra_type"]) ++
        prepare_items.(reason, @field_group_map["reason"]) ++
        prepare_items.(os_image, @field_group_map["os_image"]) ++
        prepare_items.(linux, @field_group_map["linux"]) ++
        prepare_items.(windows, @field_group_map["windows"]) ++
        prepare_items.(os_version, @field_group_map["os_version"]) ++
        prepare_items.(role, @field_group_map["role"])

    Repo.insert_all("common_codes", full_list, on_conflict: :nothing)
    |> elem(0)
  end

  defp init_reset_data! do
    Repo.delete_all(
      from(c in "common_codes", where: c.group_code in ^Map.values(@field_group_map))
    )
    |> elem(0)
  end
end

Itsm.Repo.Seeds.InsertCommonCodes.run()
