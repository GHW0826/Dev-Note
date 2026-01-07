# Application Load Balancer (ALB)
- Layer 7에서 동작 (Application 계층에서 동작), HTTP/HTTPS, WebSocket을 지원한다. 
- 고급 라우팅 기능: Path-Based Routing(경로 기반 라우팅), Host-Based Routing(호스트 기반 라우팅) , URL 쿼리 문자열에 따른 라우팅
- Docker 컨테이너화된 애플리케이션과의 통합을 용이하게 한다.
- 고정 IP 주소(Elastic IP)를 사용할 수 없다.  IP 주소는 변동되므로 클라이언트에서 ELB의 DNS Name을 이용하여 접근해야 함
- 고정 IP 주소를 사용할 수 있는 NLB를 앞에 놓아 고정 IP 주소가 있는 것처럼 사용할 수는 있음,
- Sticky Session 사용 가능.
- HTTPS 리스너를 설정하려면 로드밸런서에 SSL 서버 인증서를 배포해야 함
- 다양한 라우팅 알고리즘 제공
 - 라운드 로빈 : 요청을 순차적으로 균등하게 분배
 - 최소 미해결 요청 (LOR) : 미해결 요청이 가장 적은 대상에 트래픽을 분산시킴, RequestCount, TargetResponseTime 지표를 기반으로 응답시간을 결정
 - 가중치 기반 랜덤 : 가중치를 기반으로 요청을 무작위로 균등하게 라우팅, 자동 목표 가중치 이상 현상 완화 지원, 슬로우 스타트 모드에서는 사용 불가

### Host(호스트), Path(경로) Based Routing 기능
#### [호스트(Host) 기반]
- 클라이언트가 요청한 접속 URL의 FQDN(완전 도메인 이름)에 따라 라우팅 할 수 있는 기능.
- ex) 클라이언트의 접속 URL이 "http://www1.example.com"일 경우 웹 서버 1에 접속, "http://www2.example.com"일 경우 웹 서버 2에 접속.

#### [경로(Path) 기반]
- 경로 기반 라우팅이란, 클라이언트가 요청한 접속 URL의 경로에 따라 라우팅할 수 있는 기능.
- ex) 클라이언트의 접속 URL이 "http://www.example.com/web1/"일 경우 웹 서버 1에 접속, "http://www.example.com/web2/"일 경우 웹 서버 2에 접속.

#### [URL Query 문자열 기반]
- 클라이언트가 요청한 접속 URL의 쿼리 문자열에 따라 라우팅할 수 있는 기능. URL 쿼리 문자열은 브라우저가 웹 서버에 전송하는 데이터를 URL에 표현한 것.
- ex) URL이 "http://www.example.com/web?lang=kr"일 경우 "lang=kr"가 URL 쿼리 문자열에 해당.
- 클라이언트의 접속 URL이 "http://www.example.com/web?lang=kr"일 경우 한국어 사이트로 접속, "http://www.example.com/web?lang=en"일 경우 영어 사이트로 접속.

### [Sticky Session] 기능: 세션 정보가 저장된 쪽으로 지속적 연결
- Cookie의 유효시간 동안에 클라이언트가 동일한 백엔드 인스턴스(서버)에 접근할 수 있도록 하는 기능.
- 클라이언트는 같은 인스턴스에 연결된 상태를 유지하게 되며, 세션 상태를 인스턴스별로 저장해야 하는 애플리케이션에 유용.
- ex)
```
아마존 쇼핑사이트가 2개의 백엔드 서버와 로드밸런서로 운영 중이다.
유저가 장바구니에 상품을 저장시켰다. (한쪽의 백엔드 서버를 이용) (redis 등 다른 수단은 있음 그냥 예시)
근데 갑자기 로드밸런스가 다른 백엔드 서버로 트래픽을 이동시키면 상태(세션) 정보가 사라지기 때문에 장바구니에 있던 상품들은 사라지게 될 것.
이걸 방지하는 것이 Sticky Session.
```

###  [Listener Rules, 리스너 규칙]
- (ALB에서만 사용 가능) Listener Rules는 수신한 요청을 어떻게 처리할지에 대한 규칙을 설정한 기능.
- 위에서 설명한 호스트/경로 기반 라우팅은 Listener Rules을 통해서 라우팅 한다.
- 요청의 경로(Path) 또는 호스트 이름(Host)을 기준으로 규칙/조건을 설정하여, 특정 URL로 들어오는 요청을 다른 타깃 그룹으로 라우팅 가능.
- 헤더 또는 쿼리 문자열의 내용에 따라 요청을 다르게 처리할 수도 있다.
- HTTP로 들어오는 요청을 HTTPS로 리다이렉트 할 수 있다.



### AWS Web Aplication Firewall(WAF) 연동
- AWS WAF는 AWS의 웹 애플리케이션 방화벽 서비스로, 웹서버로 유입되는 트래픽을 검사하여 공격을 차단하고 내부 리소스를 보호하는 역할을 하는 서비스.
- AWS WAF는 ALB, Cloudfront, API Gateway에 적용 가능

