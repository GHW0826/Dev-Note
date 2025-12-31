
[man](https://wariua.github.io/man-pages-ko/epoll_create1%282%29/)


# epoll 동작 원리
## 1. select / poll 의 한계
### 동작 방식
- 관찰할 **파일 디스크립터(FD) 목록을 매번 커널로 복사**
- 커널은 **전체 FD 리스트를 순회**하며 상태 변화 체크
- 이벤트 발생 여부와 무관하게 항상 **O(N)** 비용 발생
### 문제점
- 연결 수가 증가할수록 성능 급격히 저하
  - 예: 10만 FD → 매 호출마다 10만 개 스캔
- FD 복사 비용 + 커널 스캔 비용
- 대규모 동시 접속 서버에 부적합

## 2. epoll 원리
### 핵심 요약
- 관심 목록(Interest List) 과 준비 목록(Ready List) 분리
- 전체를 확인하는 구조가 아니라 이벤트가 발생한 FD만 처리

### 동작 흐름
1. 애플리케이션이 관찰할 FD를 epoll 인스턴스(커널 객체) 에 미리 등록
2. 커널은 상태 변화가 발생한 FD만 Ready List에 추가
3. `epoll_wait()` 호출 시 Ready List에 있는 이벤트만 반환

> 접속자가 100명이든 10만 명이든, 이벤트 수 기준으로 동작

## 3. epoll 내부 구조
### Interest List (관심 목록)
- `epoll_ctl(ADD / MOD / DEL)` 로 관리
- 어떤 FD를, 어떤 이벤트(읽기/쓰기/종료 등)로 감시할지 등록
### Ready List (준비된 목록)
- 실제로 이벤트가 발생한 FD만 들어가는 리스트
- `epoll_wait()` 는 이 Ready List에서 이벤트를 꺼내 반환



### API
### epoll_create1
```c
int epfd = epoll_create1(EPOLL_CLOEXEC);
```
- epoll 인스턴스(커널 객체) 생성
- EPOLL_CLOEXEC: exec() 시 FD 누수 방지


```c
epoll_ctl(epfd, EPOLL_CTL_ADD, fd, &ev);
epoll_ctl(epfd, EPOLL_CTL_MOD, fd, &ev);
epoll_ctl(epfd, EPOLL_CTL_DEL, fd, nullptr);
```
- EPOLL_CTL_ADD	: 감시 대상 등록
- EPOLL_CTL_MOD	: 이벤트 마스크 변경
- EPOLL_CTL_DEL :	감시 대상 제거

```c
int n = epoll_wait(epfd, events, maxevents, timeout);
```
- Ready List에서 이벤트를 가져옴
- 반환값: 이벤트 개수
- timeout = -1 → 무한 대기
- timeout = 0 → 폴링(즉시 리턴)

### epoll은 이벤트 통지만 함.
- epoll은 I/O를 대신 수행하지 않음
- 실제 데이터 처리는 accept / recv / send
- epoll 준비만 알려줌
- 따라서 non-blocking + EAGAIN 루프 패턴이 사실상 필수

### epoll이 감시하는 커널 상태 (소켓 기준)
#### EPOLLIN (읽기 가능)
- TCP 수신 버퍼에 데이터 존재
- FIN 수신 → read() == 0
- 리스너 소켓의 경우: accept 가능한 연결 존재
#### EPOLLOUT (쓰기 가능)
- TCP 송신 버퍼에 여유 공간 존재
- send가 진행될 가능성이 있는 상태

### Level Trigger (LT) vs Edge Trigger (ET)
- 핵심은 커널의 버퍼/큐 상태(level)를 기준으로 알려주냐 vs 상태 변화(edge)만 알려주냐 차이
- LT : 상태(Level) 가 유지되는 동안 계속 알림. 이벤트 한 번 받고 accept()를 1번만 해도 또 남아있으면 계속 깨워줌
- ET : 상태 변화(Edge) 가 발생한 순간만 알림. 이벤트 한 번 오면 accept를 EAGAIN까지 전부 소진해야 함 (안 그러면 다음 이벤트가 안 올 수 있음)

### Level Trigger (LT)
- 조건이 참이면 계속 이벤트 발생
- 예: 수신 버퍼에 데이터가 남아 있으면 EPOLLIN이 계속 발생
- 구현이 쉬움
- 일부만 처리해도 다시 이벤트가 옴
- 불필요한 wakeup이 많아질 수 있음
- recv() 는 한 번만 호출해도 동작은 가능
- 성능을 위해 EAGAIN까지 읽는 루프 권장
- EPOLLOUT 은 보낼 데이터가 있을 때만 등록

### Edge Trigger (ET)
- 상태가 없음 → 있음 으로 바뀌는 순간만 이벤트 발생
- 한 번 깨워줬을 때 끝까지 처리해야 함
- 반드시 non-blocking
- 반드시 EAGAIN까지 drain 루프
- wakeup 횟수 감소 → 고성능
- 구현 난이도 높음
- 실수 시 이벤트를 놓쳐 멈춘 것처럼 보임

#### 중요한 차이: 조금만 처리하고 나와도 되는가?
상황	LT (Level)	ET (Edge)
recv를 10바이트만 읽고 나옴 (아직 90바이트 남음)	다음 epoll_wait에서도 계속 EPOLLIN로 깨움	다음엔 안 깨울 수 있음 (변화가 없으니)
accept를 1개만 하고 나옴 (큐에 10개 남음)	다음에도 계속 리스너 EPOLLIN	다음엔 안 깨울 수 있음
send를 일부만 하고 나옴(아직 pending 있음)	EPOLLOUT가 켜져 있으면 계속 깨움	버퍼 여유 변화가 다시 생길 때만 깨움
=> ET는 한 번에 끝까지가 본질.
<br>


### 확장 아키텍처 옵션
#### Single Reactor (가장 단순/안정)
- epoll_wait + accept + read/write 모두 한 스레드
- 처리 로직이 무겁다면 큐로 워커에 넘김
- 장점: 락 적고 디버깅 쉬움
- 단점: 한 코어 중심이 될 수 있음

#### Multi Reactor (N개 epoll 스레드로 분산)
- accept는 한 곳에서 받고, 연결을 라운드로빈으로 epoll 스레드에 넘김
- 장점: 멀티코어 확장
- 단점: fd “소유권”과 cross-thread 전달 설계 필요(eventfd/pipe 등)

#### Reactor + Worker Pool (게임/금융 서버에서 흔함)
- 네트워크 스레드는 I/O만, 파싱 후 “Job Queue”에 넣고 워커가 처리
- 장점: 네트워크 레이턴시 안정
- 단점: 작업 순서/동기화 설계가 핵심(세션별 직렬화 등)

### Code Example
```cpp
// Create Listener socker
int create_listen_socket(uint16_t port)
{
    int fd = socket(AF_INET, SOCK_STREAM, 0);
    if (fd < 0) return -1;

    int opt = 1;
    setsockopt(fd, SOL_SOCKET, SO_REUSEADDR, &opt, sizeof(opt));

#ifdef SO_REUSEPORT
    setsockopt(fd, SOL_SOCKET, SO_REUSEPORT, &opt, sizeof(opt));
#endif

    sockaddr_in addr{};
    addr.sin_family = AF_INET;
    addr.sin_addr.s_addr = htonl(INADDR_ANY);
    addr.sin_port = htons(port);

    if (bind(fd, (sockaddr*)&addr, sizeof(addr)) < 0) {
      close(fd);
      return -1;
    }
    if (listen(fd, SOMAXCONN) < 0) {
      close(fd);
      return -1;
    }

    int flags = fcntl(fd, F_GETFL, 0);
    if (fcntl(fd, F_SETFL, flags | O_NONBLOCK) < 0) {
      close(fd);
      return -1;
    }

    return fd;
}


// SO_REUSEADDR
// 서버 재시작할 때 흔히 만나는 bind: Address already in use 완화용
// 특히 이전 연결들이 TIME_WAIT 상태로 남아있는 동안 같은 포트에 다시 bind가 막히는 상황을 줄여줌
setsockopt(fd, SOL_SOCKET, SO_REUSEADDR, &opt, sizeof(opt));

// SO_REUSEPORT
// 동일 (IP, Port)에 여러 프로세스/스레드가 각각 bind+listen 가능하게 해줌
// 커널이 들어오는 연결을 여러 리스너에 분산해줌(로드밸런싱 비슷)
// 커널 버전/설정/해시 정책에 따라 분산 특성이 달라질 수 있음
// 이미 단일 accept 스레드 + 워커 이벤트루프 구조라면 굳이 필요 없을 때도 많음
setsockopt(fd, SOL_SOCKET, SO_REUSEPORT, &opt, sizeof(opt));

// epoll은 리스너 FD가 지금 읽을 수 있다/쓸 수 있다를 알려주는데, 그 상태에서도:
// accept(), recv(), send()는 타이밍에 따라 바로 다음 호출이 블록될 수 있음
// 그래서 이벤트 루프가 멈추지 않으려면 non-blocking + EAGAIN 처리가 기본 패턴
// Listener 소켓의 옵션을 load
int flags = fcntl(fd, F_GETFL, 0);
// 이후 해당 소켓에 논블락 옵션을 추가.
fcntl(fd, F_SETFL, flags | O_NONBLOCK);


// epoll 인스턴스를 만듦
// 반환되는 epfd가 이후 모든 epoll 호출의 핸들이 됨
// EPOLL_CLOEXEC는 exec 시 fd 누수 방지(서버에서는 보통 켜둠)
int epfd = epoll_create1(EPOLL_CLOEXEC);

// epoll_ctl() — FD 등록/수정/삭제
// EPOLL_CTL_ADD : 감시 대상 추가
// EPOLL_CTL_MOD : 이벤트 마스크 수정(예: EPOLLOUT 추가/제거)
// EPOLL_CTL_DEL : 감시에서 제거
struct epoll_event ev{};
ev.events = EPOLLIN;      // 읽기 가능(accept 가능/recv 가능)
ev.data.fd = listen_fd;
epoll_ctl(epfd, EPOLL_CTL_ADD, listen_fd, &ev);

// events 플래그 자주 쓰는 것들
//   EPOLLIN : 읽기 가능
//     리스너: accept 가능한 연결이 생김
//     클라 소켓: recv 가능한 데이터가 있음(또는 FIN으로 0바이트 읽힘)
//   EPOLLOUT : 쓰기 가능(버퍼 여유가 있어 send가 “진행될 가능성”이 큼)
//   EPOLLRDHUP : 상대가 half-close(쓰기 종료) 했을 때 감지(실전에서 유용)
//   EPOLLHUP / EPOLLERR : 끊김/에러 (대개 항상 체크)
//   EPOLLET : Edge Trigger(엣지 트리거)
//     이벤트가 상태 변화에서만 옴
//     반드시 논블로킹 + while 루프 EAGAIN까지 drain 패턴 필요


// epoll_wait() — 이벤트 받기
epoll_event events[1024];
int n = epoll_wait(epfd, events, 1024, timeout_ms);

// 준비된 이벤트를 최대 maxevents개까지 받아옴
// 반환값 n만큼 events[i]를 처리
//   timeout_ms:
//     -1 무한 대기
//     0 폴링(즉시 리턴)

```
