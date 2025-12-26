
### 동작원리
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
