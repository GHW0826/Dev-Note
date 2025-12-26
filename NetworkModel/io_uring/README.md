io_uring은 Ready(준비)가 아니라 Completion(완료) 기반 비동기 I/O 모델.
epoll: 읽을 수 있음/쓸 수 있음을 알려주고, 유저가 read/write를 직접 호출해서 완료시킴
io_uring: 유저가 이 작업(예: recv, send, accept)이벤트를 제출하고, 커널이 처리한 뒤 끝남을 완료 큐로 돌려줌
즉, io_uring은 IOCP와 철학이 더 가깝고(완료 기반), Linux에서 그걸 고성능으로 만들려고 유저/커널이 공유하는 링 버퍼(SQ/CQ)를 둔 구조.
<br>

io_uring의 동작 원리 (Ring Architecture)<br>
io_uring은 두 개의 원형 큐(Ring Queue)를 사용하여 통신. <br>
SQ (Submission Queue - 제출 큐): <br>
애플리케이션이 커널에게 시킬 작업(예: 소켓 읽기, 파일 쓰기)을 이 큐에 넣음. (Producer: 앱 / Consumer: 커널), 할 일을 넣는 곳, (SQE = Submission Queue Entry) <br>
CQ (Completion Queue - 완료 큐): <br>
커널이 작업을 완료하면 그 결과(성공/실패, 읽은 바이트 수)를 이 큐에 넣습니다. (Producer: 커널 / Consumer: 앱), 끝난 일 결과가 나오는 곳, (CQE = Completion Queue Entry) <br>
이 둘이 mmap으로 유저 공간과 커널이 공유 메모리로 연결되어 있어서, 호출 오버헤드를 줄이는 방향으로 설계됨 <br>
<br>

동작 흐름:
1. 앱이 SQ에 "소켓 A에서 데이터 읽어줘"라는 요청(SQE)을 적습니다.
2. 앱이 io_uring_enter 시스템 콜을 한 번 호출하여 커널을 깨웁니다. (옵션에 따라 이 과정도 생략 가능)
3. 커널은 SQ에서 요청을 꺼내 비동기로 처리합니다. (DMA 등을 통해 데이터 복사 없이 처리)
4. 처리가 끝나면 커널은 CQ에 결과(CQE)를 적습니다.
5. 앱은 CQ를 확인하여 완료된 작업을 처리합니다.
