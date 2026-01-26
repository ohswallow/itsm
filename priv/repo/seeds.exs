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
    role: :admin
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
    role: :auditor
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
    role: :general
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
    role: :general
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
    role: :general
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
    role: :general
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
    role: :general
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
    role: :general
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
  group: "K_리전_공동존",
  active: true,
  request_name: "common_k_create_vm",
  affiliate: :FG,
  duration: 80,
  assignee_crew_id: aaaaa.id
}
|> Repo.insert!()

%Category{
  name: "가상 머신 스펙 변경",
  description: "
  K리전 은행존 가상머신 vCore/Memory Scale up/down 조정 신청
  ",
  group: "K_리전_은행존",
  active: true,
  request_name: "bank_k_resize_vm",
  affiliate: :B0,
  duration: 70,
  assignee_crew_id: bbbbb.id
}
|> Repo.insert!()
