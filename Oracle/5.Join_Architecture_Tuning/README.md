# Join

## NL 조인 기본 메커니즘
```sql
begin
    for outer in (select 사원번호, 사원명 from 사원 where 입사일자 >= ‘19960101’)
        loop -- outer 루프
            for inner in (select 고객명, 전화번호 from 고객 where 관리사원번호 = outer.사원번호)
            loop -- inner 루프
            dbms_output.put_line(outer.사원명 || ‘:’ || inner.고객명 || ‘:’ || inner.전화번호);
        end loop
    end loop
end
```
![nl](../images/nl_join.png "nl")<br>

NL 조인은 중첩 루프문과 같은 수행 구조를 사용<br>
일반적으로 NL조인은 Outer, Inner 양쪽 테이블 모두 인덱스를 이용<br>
Outer 쪽 테이블은 사이즈가 크지 않으면 인덱스를 이용하지 않을 수 있다<br>
but, Innter 쪽 테이블은 인덱스를 사용해야 한다<br>
Inner 루프에서 데이터 검색시 인덱스를 이용하지 않으면,<br>
Outer 루프에서 읽은 건수만큼 Table Full Scan을 반복하기 때문<br>
위 그림과 같은 방식으로 Outer 테이블의 조건과 Inner 테이블의 컬럼 비교로<br>
조인 조건에 맞는 ROWID를 찾아 해당 컬럼 찾음<br>


### NL 조인 실행계획 제어, 예제
```sql
select /*+ ordered use_nl(c) index(e) index(c)*/ 
	  e.사원번호, e.사원명, e.입사일자,
      c.고객번호, c.고객명, c.전화번호, c.최종주문번호
from 사원 e, 고객 c
where c.관리사원번호  = e.사원번호   -- 1️⃣
and   e.입사일자    >= '19960101'   -- 2️⃣ 
and   e.부서코드     = 'Z123'       -- 3️⃣
and   c.최종주문금액 >= 20000        -- 4️⃣

사원_PK : 사원번호
사원_X1 : 입사일자
고객_PK : 고객번호
고객_X1 : 관리사원번호
고객_X2 : 최종주문금액

0 SELECT STATEMENT
1   NESTED LOOPS
2    TABLE ACCESS BY INDEX ROWID   사원
3     INDEX RANGE SCAN             사원_X1
4    TABLE ACCESS BY INDEX ROWID   고객
5     INDEX RANGE SCAN             고객_X1
```
![nl_join](../images/nl_join2.png "nl_join")<br>
ordered 힌트는FROM 절에 기술한 순서대로 조인하라고 옵티마이저에 지시할 때 사용<br>
use_nl은 NL 방식으로 조인하라고 지시<br>
사원 (Outer) -> 고객 (inner) 로 NL 조인하라는 뜻<br>

### NL 조인 튜닝 포인트
NL 조인의 경우 Outer에서 결정된 결과 건수에 의해 Inner테이블과의 조인시도가 결정됨<br>
Outer 테이블 조회 결과가 10만건, Innder 테이블 인덱스 Depth가 3이라면 30만개 블록을 읽어야 함<br>
Outer 테이블 조회결과로<br>
1) Outer 테이블의 랜덤 액세스 횟수 
2) Innder 테이블 인덱스 탐색 횟수
3) Innder 테이블 랜덤 액세스 횟수

가 많아짐<br>

### NL 조인 특징
1. 랜덤 액세스 위주의 조인 방식
2. 한 레코드씩 순차적으로 진행
3. 인덱스 구성 전략이 중요



## 소트 머지 조인
## 해시 조인
## 서브쿼리 조인
