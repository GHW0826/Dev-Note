
[Doc1](https://docs.aws.amazon.com/ko_kr/vpc/latest/tgw/what-is-transit-gateway.html)
[Doc2](https://aws.amazon.com/ko/transit-gateway/)

# Transit Gateway
- Transit Gateway는 여러 VPC와 온프레미스 네트워크를 중앙 집중식으로 연결하고 관리할 수 있게 해주는 서비스
- VPC Peering과 마찬가지로 서로 다른 VPC간에 통신이 가능하게 하는 서비스
- VPC Peering은 1 대 1 VPC 연결만 지원하여 직접적으로 연결되어있지 않은 VPC에 바로 접근할 수 없음
- Transit Gateway는 중앙 허브를 통해 여러 VPC간 연결 정책을 중앙에서 관리할 수 있고, VPN을 통해 VPC와 온프레미스 네트워크를 연결할 수 있음.

### 특징
- 중앙 허브와 VPN을 통해 VPC와 온프레미스 네트워크를 연결할 수 있다.
- 복잡한 피어링 관계를 제거하여 네트워크를 간소화 시킬 수 있다.
- 클라우드 라우터 역할을 해 새로운 연결을 한 번만 추가하면 됨.
- 다른 리전간의 Transit Gateway와 피어링 연결이 가능.

### Transit Gateway 사용 이유
- VPC Peering을 사용해 같은 리전에 있는 VPC와 다른 리전에 있는 VPC를 연결하고 VPN을 통해 온프레미스 네트워크와 연결, 관리는 규모가 클수록 까다로움.
- 온프레미스 네트워크와 연결하기 위해 VGW(Virtual Private Gateway)를 구성해야 하며 VPC를 한개만 추가하는 것만으로도 수많은 Peering Connection이 추가될 수도 있음.
- Transit Gateway를 사용하면 중앙허브를 통해 위 인프라를 더욱더 관리하기 쉽고 확장성있는 구조로 변경할 수 있음.
- VPC를 Transit Gateway에 연결해주기만하면 Transit Gateway에 연결된 모든 다른 VPC와 통신이 가능하게 .
- 또한 CGW(Customer Gateway)와 Transit Gateway를 연결하게 되면 Transit Gateway에 연결된 VPC는 VPN을 통해 온프레미스 네트워크와도 통신이 가능.
- 연결해야하는 VPC 개수가 많으며, 온프레미스와의 VPN연결 까지 관리해야한다면 Transit Gateway를 사용하는 것이 관리적인 측면에서 훨씬 유리.


### 구성
- Attachment
  - VPC, VPN와 Transit Gateway와의 논리적인 연결을 의미
  - VPC와 TGW가 Attachment가 되어 있어야 네트워크간 라우팅이 가능
- Association
  - TGW에서는 연결 라우팅 테이블과 전파 라우팅 테이블 총 2가지 라우팅 테이블이 존재
  - 연결 라우팅 테이블에 Attachment된 VPC들은 자동으로 전파 라우트 테이블에 반영 됨.
  - 하나의 TGW 라우팅 테이블은 여러 Attachment를 가질 수 있
- Propagation
  - 전파 라우팅 테이블은 Association에서 전파한 라우팅 정보를 전파하는 테이블 (실질직인라우팅기능)
  - VPC가 Attachment되었다면 AWS-API를 통해, 온프레미스라면 BGP를 통해 전파.
 
### Transit Gateway의 통신 과정
1. VPC는 VPC의 로컬 라우팅 테이블을 통해 요청을 Transit Gateway로 라우팅합니다. (이때 각 VPC는 TransitGateway에 부착 Attachment되어 있어야함)
2. Attachment된 VPC들은 연결 라우팅 테이블에 등록되어 전파 라우팅 테이블로 라우팅정보를 전파
3. Transit Gateway는 전파 라우팅 테이블에 등록된 경로를 통해 알맞은 위치로 요청을 보냄

### Transit Gateway Routing Table
- TGW에서는 VPC와 다른 별도의 라우팅 테이블을 가짐.
- 대상 서브넷과 서브넷과 연결되는 VPC를 지정해주면 요청을 라우팅.
- 전파된 경로가 아닌 직접 정적경로를 지정해 TGW의 트레픽을 조정 가능하며, active와 blackhole을 설정해 차단여부도 설정 할 수 있음


### 장점 / 단점
- 장점
  - 확장성: VPC가 늘어도 연결/라우팅 관리가 선형적으로 증가(허브에 붙이면 끝)
  - 중앙 통제: 라우팅 정책/분리(Prod/Dev/Shared/OnPrem)를 TGW RT로 강하게 만들 수 있음
  - 하이브리드 통합: VPN/DX 기반 온프레미스 연동의 표준 허브로 쓰기 좋음 
- 단점
  - 비용: attachment 시간당 비용 + 처리 데이터(GB)당 비용이 발생 
  - 설계 난이도: TGW RT(Association/Propagation) 설계를 못 하면 “전체 망 오픈” 같은 사고가 남
  - 중앙 장애 영향: 허브 장애/오작동 시 영향 범위가 커질 수 있어, 분리/테스트/가시성이 중요


### 대표 사용 패턴 (실전에서 많이 쓰는 6가지)
#### 패턴 A) Multi-VPC Hub-and-Spoke (기본)
- 여러 VPC를 TGW에 붙여 VPC 간 통신을 중앙에서 관리
- Shared Services VPC(예: AD, 모니터링, 공통 API) 운영에 적합 
- https://docs.aws.amazon.com/vpc/latest/tgw/how-transit-gateways-work.html?utm_source=chatgpt.com

#### 패턴 B) Multi-Account 네트워크 통합
- 계정이 여러 개면 TGW를 중앙 네트워크 계정에 두고 공유(보통 AWS RAM 활용)
- 팀/프로덕트 단위 VPC를 “스포크”로 붙이는 방식이 일반적 
- https://aws.amazon.com/ko/documentation-overview/transit-gateway/?utm_source=chatgpt.com

#### 패턴 C) 중앙집중 Egress(인터넷 출구 통제)
- 모든 스포크 VPC의 0.0.0.0/0을 TGW로 보내고,
- Shared/Egress VPC에서 NAT/보안 장비를 통해 인터넷으로 나가게 구성
- 장점: 로깅/보안/비용통제(Endpoint 활용) 중앙화

#### 패턴 D) Inspection VPC (방화벽/보안검사)
- TGW ↔ Inspection VPC(방화벽)로 트래픽을 강제로 경유시켜 검사
- 이때 Appliance mode가 중요해지는 경우가 많다(상태기반 장비는 흐름의 AZ 일관성이 필요) 
- https://docs.aws.amazon.com/network-firewall/latest/developerguide/vpc-config-tgw-multi-az.html?utm_source=chatgpt.com

#### 패턴 E) 하이브리드 (On-Prem ↔ AWS)
- On-Prem → (VPN 또는 DX) → TGW → 여러 VPC
- 온프레미스 대역과 VPC 대역 중복 방지가 필수 
- https://aws.amazon.com/ko/blogs/architecture/overview-of-data-transfer-costs-for-common-architectures/?utm_source=chatgpt.com

#### 패턴 F) Inter-Region 연결 (DR/멀티리전)
- 리전 A TGW ↔ 리전 B TGW를 TGW Peering 으로 연결해 리전 간 라우팅
- https://docs.aws.amazon.com/solutions/latest/network-orchestration-aws-transit-gateway/transit-gateway-inter-region-peering.html?utm_source=chatgpt.com


