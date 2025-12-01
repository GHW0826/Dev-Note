- 나중에 Redis 기반 캐시 서버, 세션 서버, 랭킹 서버, 간단한 메시지 브로커/스트림 처리기를 만들 때,  
  이 레포의 내용을 바로 참고할 수 있도록 구조화한다.
- 필요할 때마다 디렉토리를 추가하고, 예제 코드/실험 결과를 함께 정리할 예정.


# [Redis](https://redis-docs.ru/)
Redis는 인메모리 기반의 Key-Value 데이터 스토어

- In-Memory: 대부분의 데이터를 메모리에 올려놓고 사용 → 매우 빠른 응답 속도
- 자료구조: 단순 문자열뿐 아니라 List, Hash, Set, Sorted Set, Bitmap, HyperLogLog, Geo, Stream 등 다양한 자료구조 제공
- 활용 방법
  - 캐시 (API 응답 캐시, 세션 저장)
  - 순위/랭킹 (Sorted Set)
  - Pub/Sub 메시징
  - 스트림/이벤트 로그 처리 (Streams)
  - 분산 락, 큐, 작업 대기열 등


- [`basic/`](basic/README.md)  
  Redis 설치, `redis-cli` 사용법, 기본 명령(SET/GET/DEL/EXPIRE) 정리

- [`data-structures/`](data-structures/README.md)  
  String, List, Hash, Set, Sorted Set, Bitmap, HyperLogLog, Geo 등 자료구조별 개념과 사용 패턴

- [`transactions/`](transactions/README.md)  
  MULTI/EXEC, WATCH를 통한 트랜잭션 및 낙관적 락

- [`pubsub/`](pubsub/README.md)  
  Publish/Subscribe 모델, 채널 기반 메시지 브로드캐스트

- [`streams/`](streams/README.md)  
  Redis Streams, Consumer Group, 간단한 이벤트 스트리밍 구조

- [`persistence/`](persistence/README.md)  
  RDB 스냅샷, AOF(Append Only File), 내구성과 성능의 trade-off

- [`replication/`](replication/README.md)  
  Master-Replica 구조, 읽기 스케일아웃, 복제 원리

- [`cluster/`](cluster/README.md)  
  Redis Cluster, 샤딩(slot), 수평 확장 개념과 제약 사항

- [`lua/`](lua/README.md)  
  Lua 스크립트로 복잡한 연산을 atomic하게 처리하는 방법

- [`performance-tuning/`](performance-tuning/README.md)  
  키 설계, 메모리/TTL 전략, 모니터링/슬로우 쿼리 분석

- [`modules/`](modules/README.md)  
  Redis 모듈(예: RediSearch, RedisJSON) 개요
