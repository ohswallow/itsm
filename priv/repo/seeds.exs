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
alias Itsm.Crews.Crew
alias Itsm.Crews.CrewsUsers
alias Itsm.Common.CommonCode
alias Itsm.Boards.Board
alias Itsm.Accounts.Role
alias Itsm.Accounts.Permission

Process.put(:current_user_id, "seeds")

role_admin =
  %Role{
    name: "admin",
    description: "관리자 권한"
  }
  |> Repo.insert!()

role_auditor =
  %Role{
    name: "auditor",
    description: "수정 권한"
  }
  |> Repo.insert!()

role_general =
  %Role{
    name: "general",
    description: "일반 권한"
  }
  |> Repo.insert!()

jjh =
  %User{}
  |> User.registration_changeset(%{
    email: "T002297@kbonecloud.com",
    display_name: "전종호",
    employee_number: "T002297",
    organization_code: "B0",
    organization: "KB국민은행",
    password: "123412341234",
    department: "인프라시스템부",
    department_code: "883310",
    roles: [role_admin]
  })
  |> Repo.insert!()

yjj =
  %User{}
  |> User.registration_changeset(%{
    email: "T008359@kbonecloud.com",
    display_name: "윤정준",
    employee_number: "T008359",
    organization_code: "B0",
    organization: "KB국민은행",
    password: "123412341234",
    department: "인프라시스템부",
    department_code: "883310",
    roles: [role_admin]
  })
  |> Repo.insert!()

ohs =
  %User{}
  |> User.registration_changeset(%{
    email: "2853861@kbonecloud.com",
    display_name: "오현식",
    employee_number: "2853861",
    organization_code: "B0",
    organization: "KB국민은행",
    password: "123412341234",
    department: "인프라시스템부",
    department_code: "883310",
    roles: [role_admin]
  })
  |> Repo.insert!()

kyj =
  %User{}
  |> User.registration_changeset(%{
    email: "1655201@kbonecloud.com",
    display_name: "김영준",
    employee_number: "1655201",
    organization_code: "B0",
    organization: "KB국민은행",
    password: "123412341234",
    department: "인프라시스템부",
    department_code: "883310",
    roles: [role_admin]
  })
  |> Repo.insert!()

kky =
  %User{}
  |> User.registration_changeset(%{
    email: "T007227@kbonecloud.com",
    display_name: "김강영",
    employee_number: "T007227",
    organization_code: "B0",
    organization: "KB국민은행",
    password: "123412341234",
    department: "인프라시스템부",
    department_code: "883310",
    roles: [role_admin]
  })
  |> Repo.insert!()

mike =
  %User{}
  |> User.registration_changeset(%{
    email: "mike@kbonecloud.com",
    display_name: "mike",
    employee_number: "enmike",
    organization_code: "B0",
    organization: "KB국민은행",
    password: "123412341234",
    department: "인프라시스템부",
    department_code: "883310",
    roles: [role_admin]
  })
  |> Repo.insert!()

nicole =
  %User{}
  |> User.registration_changeset(%{
    email: "nicole@sample.com",
    display_name: "nicole",
    employee_number: "ennicole",
    organization_code: "B0",
    organization: "KB국민은행",
    password: "123412341234",
    department: "인프라시스템부",
    department_code: "883310",
    roles: [role_auditor]
  })
  |> Repo.insert!()

alex =
  %User{}
  |> User.registration_changeset(%{
    email: "alex@sample.com",
    display_name: "alex",
    employee_number: "enalex",
    organization_code: "B0",
    organization: "KB국민은행",
    password: "123412341234",
    department: "인프라시스템부",
    department_code: "883310",
    roles: [role_general]
  })
  |> Repo.insert!()

jase =
  %User{}
  |> User.registration_changeset(%{
    email: "jase@sample.com",
    display_name: "jase",
    employee_number: "enjase",
    organization_code: "B0",
    organization: "KB국민은행",
    password: "123412341234",
    department: "인프라시스템부",
    department_code: "883310",
    roles: [role_general]
  })
  |> Repo.insert!()

mary =
  %User{}
  |> User.registration_changeset(%{
    email: "mary@sample.com",
    display_name: "mary",
    organization_code: "B0",
    employee_number: "enmary",
    organization: "KB국민은행",
    password: "123412341234",
    department: "인프라시스템부",
    department_code: "883310",
    roles: [role_general]
  })
  |> Repo.insert!()

%User{}
|> User.registration_changeset(%{
  email: "ca@sample.com",
  display_name: "ca",
  organization_code: "C0",
  employee_number: "enca",
  organization: "KB국민카드",
  password: "123412341234",
  department: "정보보호부",
  department_code: "813219",
  roles: [role_general]
})
|> Repo.insert!()

%User{}
|> User.registration_changeset(%{
  email: "cq@sample.com",
  display_name: "cq",
  organization_code: "B0",
  organization: "KB국민은행",
  employee_number: "encq",
  password: "123412341234",
  department: "정보보호부",
  department_code: "813211",
  roles: [role_general]
})
|> Repo.insert!()

%User{}
|> User.registration_changeset(%{
  email: "cr@sample.com",
  display_name: "cr",
  organization_code: "C0",
  organization: "KB국민카드",
  employee_number: "encr",
  password: "123412341234",
  department: "정보보호부",
  department_code: "813219",
  roles: [role_general]
})
|> Repo.insert!()

aaaaa =
  %Crew{
    name: "AAAAA",
    description: "K리전 공동존 가상머신 처리팀"
  }
  |> Crew.leader_changeset(alex)
  |> Repo.insert!()

bbbbb =
  %Crew{
    name: "BBBBB",
    description: "K리전 은행존 가상머신 처리팀"
  }
  |> Crew.leader_changeset(mary)
  |> Repo.insert!()

%CrewsUsers{
  crew_id: aaaaa.id,
  user_id: alex.id
}
|> Repo.insert!()

%CrewsUsers{
  crew_id: aaaaa.id,
  user_id: jase.id
}
|> Repo.insert!()

%CrewsUsers{
  crew_id: aaaaa.id,
  user_id: jjh.id
}
|> Repo.insert!()

%CrewsUsers{
  crew_id: bbbbb.id,
  user_id: mary.id
}
|> Repo.insert!()

%CrewsUsers{
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
  request_name: "common-k-create-vm",
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
  request_name: "bank-k-resize-vm",
  affiliate: "B0",
  duration: 70,
  category: "서버",
  assignee_crew_id: bbbbb.id
}
|> Repo.insert!()

%CommonCode{sort_order: 0, group_code: "운영_구분", code: "운영", label: "운영", description: "운영 환경입니다."}
|> Repo.insert!()

%CommonCode{
  sort_order: 1,
  group_code: "운영_구분",
  code: "스테이징",
  label: "스테이징",
  description: "스테이징 환경입니다."
}
|> Repo.insert!()

%CommonCode{sort_order: 2, group_code: "운영_구분", code: "개발", label: "개발", description: "개발 환경입니다."}
|> Repo.insert!()

%CommonCode{sort_order: 3, group_code: "운영_구분", code: "DR", label: "DR", description: "DR 환경입니다."}
|> Repo.insert!()

%CommonCode{sort_order: 0, group_code: "장소", code: "본사", label: "본사", description: "본사 입니다."}
|> Repo.insert!()

%CommonCode{
  sort_order: 1,
  group_code: "장소",
  code: "여의도IT센터",
  label: "여의도IT센터",
  description: "여의도IT센터 입니다."
}
|> Repo.insert!()

%CommonCode{
  sort_order: 2,
  group_code: "장소",
  code: "김포IT센터",
  label: "김포IT센터",
  description: "김포IT센터 입니다."
}
|> Repo.insert!()

%CommonCode{sort_order: 3, group_code: "장소", code: "지점", label: "지점", description: "지점 입니다."}
|> Repo.insert!()

%CommonCode{sort_order: 4, group_code: "장소", code: "영업점", label: "영업점", description: "영업점 입니다."}
|> Repo.insert!()

%CommonCode{sort_order: 0, group_code: "카테고리", code: "서버", label: "서버", description: "서버 자산입니다."}
|> Repo.insert!()

%CommonCode{
  sort_order: 1,
  group_code: "카테고리",
  code: "네트워크",
  label: "네트워크",
  description: "네트워크 자산입니다."
}
|> Repo.insert!()

%CommonCode{
  sort_order: 2,
  group_code: "카테고리",
  code: "스토리지",
  label: "스토리지",
  description: "스토리지 자산입니다."
}
|> Repo.insert!()

%CommonCode{
  sort_order: 3,
  group_code: "카테고리",
  code: "하이퍼바이저",
  label: "하이퍼바이저",
  description: "하이퍼바이저 자산입니다."
}
|> Repo.insert!()

%CommonCode{
  sort_order: 4,
  group_code: "카테고리",
  code: "어플라이언스",
  label: "어플라이언스",
  description: "어플라이언스 자산입니다."
}
|> Repo.insert!()

%CommonCode{
  sort_order: 0,
  group_code: "계열사",
  code: "CM",
  label: "KB공통",
  description: "KB공통 계열사입니다."
}
|> Repo.insert!()

%CommonCode{
  sort_order: 1,
  group_code: "계열사",
  code: "A0",
  label: "KB자산운용",
  description: "KB자산운용 계열사입니다."
}
|> Repo.insert!()

%CommonCode{
  sort_order: 2,
  group_code: "계열사",
  code: "B0",
  label: "KB국민은행",
  description: "KB국민은행 계열사입니다."
}
|> Repo.insert!()

%CommonCode{
  sort_order: 3,
  group_code: "계열사",
  code: "C0",
  label: "KB국민카드",
  description: "KB국민카드 계열사입니다."
}
|> Repo.insert!()

%CommonCode{
  sort_order: 4,
  group_code: "계열사",
  code: "D0",
  label: "KB데이타시스템즈",
  description: "KB데이타시스템즈 계열사입니다."
}
|> Repo.insert!()

%CommonCode{
  sort_order: 5,
  group_code: "계열사",
  code: "FG",
  label: "KB금융지주",
  description: "KB금융지주 계열사입니다."
}
|> Repo.insert!()

%CommonCode{
  sort_order: 6,
  group_code: "계열사",
  code: "I0",
  label: "KB신용정보",
  description: "KB신용정보 계열사입니다."
}
|> Repo.insert!()

%CommonCode{
  sort_order: 7,
  group_code: "계열사",
  code: "L0",
  label: "KB캐피탈",
  description: "KB캐피탈 계열사입니다."
}
|> Repo.insert!()

%CommonCode{
  sort_order: 8,
  group_code: "계열사",
  code: "M0",
  label: "KB저축은행",
  description: "KB저축은행 계열사입니다."
}
|> Repo.insert!()

%CommonCode{
  sort_order: 9,
  group_code: "계열사",
  code: "N4",
  label: "KB라이프생명",
  description: "KB라이프생명 계열사입니다."
}
|> Repo.insert!()

%CommonCode{
  sort_order: 10,
  group_code: "계열사",
  code: "N1",
  label: "KB손해보험",
  description: "KB손해보험 계열사입니다."
}
|> Repo.insert!()

%CommonCode{
  sort_order: 11,
  group_code: "계열사",
  code: "S2",
  label: "KB증권",
  description: "KB증권 계열사입니다."
}
|> Repo.insert!()

%CommonCode{
  sort_order: 12,
  group_code: "계열사",
  code: "T0",
  label: "KB부동산신탁",
  description: "KB부동산신탁 계열사입니다."
}
|> Repo.insert!()

%CommonCode{
  sort_order: 13,
  group_code: "계열사",
  code: "V0",
  label: "KB인베스트먼트",
  description: "KB인베스트먼트 계열사입니다."
}
|> Repo.insert!()

%CommonCode{
  sort_order: 0,
  group_code: "지역_유형",
  code: "P_리전",
  label: "P_리전",
  description: "P_리전 입니다."
}
|> Repo.insert!()

%CommonCode{
  sort_order: 1,
  group_code: "지역_유형",
  code: "K_리전_공통",
  label: "K_리전_공통",
  description: "K_리전_공통 입니다."
}
|> Repo.insert!()

%CommonCode{
  sort_order: 2,
  group_code: "지역_유형",
  code: "K_리전_은행",
  label: "K_리전_은행",
  description: "K_리전_은행 입니다."
}
|> Repo.insert!()

%CommonCode{
  sort_order: 3,
  group_code: "지역_유형",
  code: "레거시",
  label: "레거시",
  description: "레거시 입니다."
}
|> Repo.insert!()

%CommonCode{
  sort_order: 0,
  group_code: "인프라_유형",
  code: "온프레미스",
  label: "온프레미스",
  description: "온프레미스 입니다."
}
|> Repo.insert!()

%CommonCode{
  sort_order: 1,
  group_code: "인프라_유형",
  code: "AWS",
  label: "AWS",
  description: "AWS 입니다."
}
|> Repo.insert!()

%CommonCode{
  sort_order: 2,
  group_code: "인프라_유형",
  code: "Azure",
  label: "Azure",
  description: "Azure 입니다."
}
|> Repo.insert!()

%CommonCode{
  sort_order: 3,
  group_code: "인프라_유형",
  code: "bare_metal",
  label: "베어메탈",
  description: "일반 x86/Unix 물리 장비"
}
|> Repo.insert!()

%CommonCode{
  sort_order: 4,
  group_code: "인프라_유형",
  code: "hypervisor",
  label: "하이퍼바이저",
  description: "VMware ESXi 등 가상화를 제공하는 물리 호스트"
}
|> Repo.insert!()

%CommonCode{
  sort_order: 5,
  group_code: "인프라_유형",
  code: "private_cloud",
  label: "프라이빗 클라우드",
  description: "사내 하이퍼바이저 위에서 구동되는 가상 머신(VM)"
}
|> Repo.insert!()

%CommonCode{
  sort_order: 6,
  group_code: "인프라_유형",
  code: "public_cloud",
  label: "퍼블릭 클라우드",
  description: "AWS, Azure 등 외부 클라우드 자원"
}
|> Repo.insert!()

%CommonCode{
  sort_order: 7,
  group_code: "인프라_유형",
  code: "mainframe",
  label: "메인프레임",
  description: "코어뱅킹용 메인프레임 시스템"
}
|> Repo.insert!()

%CommonCode{
  sort_order: 0,
  group_code: "사유",
  code: "휴가",
  label: "휴가",
  description: "휴가로 인한 대결입니다."
}
|> Repo.insert!()

%CommonCode{
  sort_order: 1,
  group_code: "사유",
  code: "출장",
  label: "출장",
  description: "출장으로 인한 대결입니다."
}
|> Repo.insert!()

%CommonCode{
  sort_order: 2,
  group_code: "사유",
  code: "파견",
  label: "파견",
  description: "파견으로 인한 대결입니다."
}
|> Repo.insert!()

%CommonCode{
  sort_order: 3,
  group_code: "사유",
  code: "교육",
  label: "교육",
  description: "교육으로 인한 대결입니다."
}
|> Repo.insert!()

%CommonCode{
  sort_order: 4,
  group_code: "사유",
  code: "기타",
  label: "기타",
  description: "기타 사유로 인한 대결입니다."
}
|> Repo.insert!()

%CommonCode{
  sort_order: 0,
  group_code: "운영체제",
  code: "리눅스",
  label: "리눅스",
  description: "리눅스 이미지입니다."
}
|> Repo.insert!()

%CommonCode{
  sort_order: 1,
  group_code: "운영체제",
  code: "윈도우",
  label: "윈도우",
  description: "윈도우 이미지입니다."
}
|> Repo.insert!()

%CommonCode{
  sort_order: 0,
  group_code: "리눅스",
  code: "RHEL 9.6 (보안)",
  label: "RHEL 9.6 (보안)",
  description: "RHEL 9.6 보안 버전입니다."
}
|> Repo.insert!()

%CommonCode{
  sort_order: 1,
  group_code: "리눅스",
  code: "RHEL 9.6 (일반)",
  label: "RHEL 9.6 (일반)",
  description: "RHEL 9.6 일반 버전입니다."
}
|> Repo.insert!()

%CommonCode{
  sort_order: 0,
  group_code: "윈도우",
  code: "Windows Server 2022",
  label: "Windows Server 2022",
  description: "Windows Server 2022 버전입니다."
}
|> Repo.insert!()

%CommonCode{
  sort_order: 1,
  group_code: "윈도우",
  code: "Windows Server 2025",
  label: "Windows Server 2025",
  description: "Windows Server 2025 버전입니다."
}
|> Repo.insert!()

%CommonCode{sort_order: 0, group_code: "역할", code: "관리자", label: "관리자", description: "관리자 권한입니다."}
|> Repo.insert!()

%CommonCode{
  sort_order: 1,
  group_code: "역할",
  code: "일반 사용자",
  label: "일반 사용자",
  description: "일반 사용자 권한입니다."
}
|> Repo.insert!()

%CommonCode{sort_order: 2, group_code: "역할", code: "감사자", label: "감사자", description: "감사자 권한입니다."}
|> Repo.insert!()

%CommonCode{
  sort_order: 1,
  group_code: "부서",
  code: "883310",
  label: "인프라시스템부",
  description: "인프라시스템부 부서입니다."
}
|> Repo.insert!()

%CommonCode{
  sort_order: 2,
  group_code: "부서",
  code: "813219",
  label: "정보보호부",
  description: "정보보호부 부서입니다."
}
|> Repo.insert!()

%CommonCode{
  sort_order: 3,
  group_code: "부서",
  code: "813211",
  label: "정보보호부",
  description: "정보보호부 부서입니다."
}
|> Repo.insert!()

notice_board =
  %CommonCode{
    sort_order: 1,
    group_code: "게시판",
    code: "공지사항",
    label: "공지사항",
    description: "공지사항 게시판입니다."
  }
  |> Repo.insert!()

qna_board =
  %CommonCode{
    sort_order: 2,
    group_code: "게시판",
    code: "QNA",
    label: "QNA",
    description: "QNA 게시판입니다."
  }
  |> Repo.insert!()

faq_board =
  %CommonCode{
    sort_order: 3,
    group_code: "게시판",
    code: "FAQ",
    label: "FAQ",
    description: "FAQ 게시판입니다."
  }
  |> Repo.insert!()

free_board =
  %CommonCode{
    sort_order: 3,
    group_code: "게시판",
    code: "자유게시판",
    label: "자유게시판",
    description: "자유게시판 입니다."
  }
  |> Repo.insert!()

%Board{
  name: notice_board.label,
  slug: notice_board.code,
  description: notice_board.description,
  metadata: %{
    "fields" => [
      %{
        "name" => "is_pinned",
        "is_hidden" => true,
        "type" => "checkbox",
        "label" => "전체 공지 (상단 고정)"
      },
      %{"name" => "expire_at", "is_hidden" => false, "type" => "date", "label" => "공지 종료일"},
      %{
        "name" => "notice_type",
        "is_hidden" => true,
        "type" => "select",
        "label" => "공지 유형",
        "options" => ["일반", "긴급", "이벤트"]
      }
    ],
    "required" => ["notice_type"]
  }
}
|> Repo.insert!()

%Board{
  name: qna_board.label,
  slug: qna_board.code,
  description: qna_board.description,
  metadata: %{
    "fields" => [
      %{"name" => "is_secret", "is_hidden" => true, "type" => "checkbox", "label" => "비밀글 설정"},
      %{
        "name" => "password",
        "is_hidden" => true,
        "type" => "password",
        "label" => "비밀번호 (비회원용)"
      },
      %{
        "name" => "status",
        "is_hidden" => false,
        "type" => "text",
        "label" => "처리 상태",
        "default" => "pending"
      }
    ],
    "required" => ["is_secret"]
  }
}
|> Repo.insert!()

%Board{
  name: faq_board.label,
  slug: faq_board.code,
  description: faq_board.description,
  metadata: %{
    "fields" => [
      %{
        "name" => "category",
        "is_hidden" => false,
        "type" => "select",
        "label" => "분류",
        "options" => ["계정", "결제", "이용방법", "기타"]
      },
      %{
        "name" => "keywords",
        "is_hidden" => false,
        "type" => "text",
        "label" => "검색 태그 (쉼표 구분)"
      },
      %{
        "name" => "priority",
        "is_hidden" => true,
        "type" => "integer",
        "label" => "노출 순서",
        "default" => 0
      }
    ],
    "required" => ["category"]
  }
}
|> Repo.insert!()

%Board{
  name: free_board.label,
  slug: free_board.code,
  description: free_board.description,
  metadata: %{
    "fields" => [
      %{"name" => "tags", "is_hidden" => false, "type" => "text", "label" => "태그"},
      %{
        "name" => "allow_comment",
        "is_hidden" => true,
        "type" => "checkbox",
        "label" => "댓글 허용",
        "default" => true
      },
      %{"name" => "source_url", "is_hidden" => false, "type" => "text", "label" => "출처 URL"}
    ],
    "required" => []
  }
}
|> Repo.insert!()

%Itsm.Assets.Asset{
  name: "ITSM_클라우드",
  description: "ITSM_클라우드",
  affiliate: "B0",
  category: "서버",
  region_type: "K_리전_은행",
  infra_type: "AWS",
  env: "운영",
  location: "여의도IT센터",
  is_dmz_zone: true,
  metadata: %{
    "os_type" => "리눅스",
    "hostname" => "nitapo03",
    "cpu_cores" => 4,
    "memory_gb" => 16,
    "ip_address" => "10.138.7.13",
    "os_version" => "0.0.0",
    "subnet_mask" => "",
    "kernel_version" => "test1"
  },
  mapping_value: "국민은행_nitapo03_10.138.17.13",
  is_shadow: false,
  status: "temp_create",
  service_crew_id: aaaaa.id,
  system_crew_id: aaaaa.id
}
|> Repo.insert!()

menu = Itsm.Permissions.get_permission_path()

general_permission = Enum.map(menu, &%{role_id: role_general.id, action: "#{&1}:*"})

permissions =
  [
    %{role_id: role_admin.id, action: "*:*"},
    %{role_id: role_auditor.id, action: "/main:index"},
    %{role_id: role_auditor.id, action: "/approvals:index"},
    %{role_id: role_auditor.id, action: "/approvals/*/approve:approve"},
    %{role_id: role_auditor.id, action: "/approvals/*/reject:reject"},
    %{role_id: role_auditor.id, action: "/approvals/*/feedback:feedback"}
  ]
  |> Enum.concat(general_permission)

Enum.each(permissions, fn attrs ->
  %Permission{}
  |> Permission.changeset(attrs)
  |> Repo.insert!()
end)
