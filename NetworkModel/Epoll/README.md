
### 동작원리
select, poll은 관찰해야 할 파일 디스크립터(FD) 목록을 매번 커널에 복사해서 넘겨주고, 커널은 전체 리스트를 순회하며 상태 변화를 체크해야 함.<br>
연결된 클라이언트가 많아질수록(예: 10만 개), 성능이 급격히 저하되는 구조

epoll의 핵심 동작 원리:
이벤트 등록 분리: 관찰할 소켓(FD)들을 커널 공간(epoll 인스턴스)에 미리 등록해 둡니다.[3] (epoll_ctl)
이벤트 기반 (Event-driven): 커널은 등록된 소켓 중 데이터가 들어오는 등의 '이벤트'가 발생한 소켓만 별도의 Ready List에 모아둡니다.
빠른 알림: 애플리케이션이 "이벤트 발생한 거 있어?"라고 물어보면(epoll_wait), 커널은 Ready List에 있는 소켓 정보만 쏙 뽑아서 반환합니다.
즉, **"전체를 뒤지는 것"이 아니라 "변화가 생긴 것만 가져오는 방식"**이므로 접속자가 100명이든 10만 명이든 성능 저하가 거의 없음.



epoll은 내부적으로 크게 두 가지 케이스로 정리
1. Interest List (관심 목록)
- fd의 읽기 가능/쓰기 가능/종료등의 관찰을 epoll_ctl(ADD/MOD/DEL)로 등록
<br>
2. Ready List (준비된 목록)
실제로 이벤트가 발생하면 커널이 ready list에 넣음
유저는 epoll_wait()로 ready list에서 이벤트들을 한 번에 받음
그래서 매번 select()처럼 전체 fd를 스캔하지 않고, 발생한 것만 받는 구조가 가능


### API
1. epoll_create1(flags)
- epoll 인스턴스(커널 객체) 생성
- 보통 EPOLL_CLOEXEC 같이 준다 (exec 계열에서 fd 누수 방지)
<br>

2.  epoll_ctl(epfd, op, fd, &ev)
- 관심 목록 제어
- op: <br>
EPOLL_CTL_ADD : 등록
EPOLL_CTL_MOD : 이벤트 마스크 변경(예: out 큐 생기면 EPOLLOUT 추가)
EPOLL_CTL_DEL : 제거
<br>

3. epoll_wait(epfd, events, maxevents, timeout)
- ready list에서 이벤트를 가져옴
- 반환: 이벤트 개수
- timeout = -1이면 무한 대기
<br>

4. 소켓 I/O: accept4, read/recv, write/send
- epoll은 이벤트 통지만 하고 실제 데이터 I/O는 여전히 read/write로 함
- non-blocking은 사실상 필수 전제 (EAGAIN 루프 패턴)


### 레벨 트리거
레벨 트리거(LT) vs 엣지 트리거(ET)

- 서버 품질에 중요
<br>

1. LT (Level Trigger)
- 조건이 만족되는 동안 계속 이벤트가 옴
예) 소켓 수신 버퍼에 데이터가 남아있으면 EPOLLIN이 계속 옴
- 구현이 쉬움, 실수 적음
- 단점: 이벤트가 더 자주 올 수 있음(불필요 wakeup)
<br>

2. ET (Edge Trigger)
- 상태가 “없음 → 있음”으로 바뀌는 순간에만 이벤트가 옴
예) 데이터가 들어온 “그 순간”만 EPOLLIN
반드시 읽을 수 있을 때까지(read until EAGAIN) 루프를 제대로 해야 함
안 그러면 데이터가 남아도 다음 이벤트가 안 와서 “멈춘 것처럼” 보임

- 장점: 이벤트 수가 줄어 효율적
- 단점: 구현 실수하면 바로 장애

실전에서는: 처음엔 LT로 안정성 확보 병목이 명확해지면 ET + 배치 처리 + 고정 버퍼로 튜닝
<br>

### 확인 필요
(A) non-blocking + “EAGAIN까지 루프”
accept()도 루프, read()도 루프, write()도 루프
이유: epoll 이벤트는 “한 번 알림”이고, 실제로 몇 개가 준비됐는지(몇 연결, 몇 바이트)는 유저가 소진해야 함.
<br>

(B) EPOLLOUT은 “필요할 때만 켜라”
대부분의 시간에 소켓은 “쓸 수 있음” 상태라 EPOLLOUT은 계속 울릴 수 있음
그래서 보낼 데이터(out 큐)가 있을 때만 EPOLLOUT 켜고, 다 보내면 꺼.
<br>

(C) 종료 감지는 EPOLLRDHUP가 유용
상대가 FIN 보냈을 때(half close) 감지가 쉬움
read()==0도 함께 처리
<br>

(D) 이벤트 구조에 포인터를 담는 패턴
ev.data.fd 대신 ev.data.ptr = session* 같이 세션 포인터를 넣음
→ fd로 map lookup 줄이고, 캐시 효율 개선
<br>


5) 서버 루프 구조

머릿속 구조는 이거 하나면 됨.
listenFd 만들고 non-blocking
epoll_create1()
listenFd를 EPOLLIN으로 epoll에 등록

무한루프:
epoll_wait()
이벤트마다:
listenFd면 accept4()를 EAGAIN까지 뽑고 클라 fd 등록

클라 fd면:
EPOLLIN이면 read() EAGAIN까지 → 패킷 파싱 → 처리 큐/바로 처리
EPOLLOUT이면 out큐 flush
에러/종료면 close + 정리
<br>
<br>

epoll 모델이 Ready 기반이라서 생기는 특징
epoll은 커널이 완료를 만들어 주지 않는다는 점이 중요해.
IOCP: “I/O 완료(몇 바이트 완료)”가 Completion Queue로 옴
epoll: “읽을 준비 됐다/쓸 준비 됐다”만 알려줌 → 실제 read/write는 직접, 그리고 부분 처리(EAGAIN)까지 책임

그래서 epoll 서버는 보통:
단일 스레드 이벤트 루프 + 워커 스레드(업무 처리) 분리
또는 멀티 리액터(reactor) + 샤딩(fd 분배)
<br>

- 확장 아키텍처 옵션
옵션 1) Single Reactor (가장 단순/안정)
epoll_wait + accept + read/write 모두 한 스레드
처리 로직이 무겁다면 큐로 워커에 넘김
장점: 락 적고 디버깅 쉬움
단점: 한 코어 중심이 될 수 있음
<br>

옵션 2) Multi Reactor (N개 epoll 스레드로 분산)
accept는 한 곳에서 받고, 연결을 라운드로빈으로 epoll 스레드에 넘김
장점: 멀티코어 확장
단점: fd “소유권”과 cross-thread 전달 설계 필요(eventfd/pipe 등)
<br>

옵션 3) Reactor + Worker Pool (게임/금융 서버에서 흔함)
네트워크 스레드는 I/O만, 파싱 후 “Job Queue”에 넣고 워커가 처리
장점: 네트워크 레이턴시 안정
단점: 작업 순서/동기화 설계가 핵심(세션별 직렬화 등)
