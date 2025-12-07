## 소트 연산

### 소트 수행 과정
![disk_sort](../images/disk_sort.jpg "disk_sort")<br>
소트는 기본적으로 PGA에 할당한 Sort Area에서 이뤄짐<br>
메모리 공간인 Sort Area가 다 차면, 디스크 Temp 테이블스페이스를 활용<br>
Sort Area에서 작업을 완료할 수 있는지에 따라 소트를 2가지 유형으로 나눔
1. 메모리 소트(In-Memory Sort):<br>
전체 데이터의 정렬 작업을 메모리 내에서 완료하는 것을 말함(Internal Sort)
2. 디스크 소트(To-Disk Sort):<br>
할당받은 Sort Area내에서 정렬을 완료하지 못해 디스크 공간까지 사용하는 경우(External Sort)<br>

소트할 대상 집합을 SGA 버퍼캐시를 통해 읽어들이고, 일차적으로 Sort Area에서 정렬을 시도<br>
Sort Area 내에서 데이터 정렬을 마무리하면 최적이지만, 양이 많을 때는 정렬된 중간집합을 Temp 테이블스페이스에 임시 세그먼트를 만들어 저장<br>
Sort Area가 찰 때마다 Temp 영역에 저장해 둔 중간 단계의 집합을 Sort Run이라고 부름<br>
정렬된 최종 결과집합을 얻으려면 이를 다시 Merge 해야 함<br>
각 Sort Run 내에서는 이미 정렬된 상태이므로 Merge 과정은 어렵지 않음<br>
<br>
소트 연산은 메모리 집약적이고 CPU 집약적<br>
처리할 데이터량이 많을 때는 디스크 I/O까지 발생하므로 쿼리 성능을 좌우하는 매우 중요한 요소<br>
디스크 소트가 발생하는 순간 SQL 수행 성능은 나빠질 수밖에 없음<br>
많은 서버 리소스를 사용하고 디스크 I/O가 발생하는 것도 문제지만<br>
부분범위 처리를 불가능하게 함으로써 앱 성능을 저하시키는 주요인이 됨<br>
될 수 있으면 소트가 발생하지 않도록 SQL을 작성해야 하고, 소트가 불가피하다면<br>
메모리내에서 수행을 완료할 수 있도록 해야 함<br>

### 소트 오퍼레이션

#### 1) Sort Aggregate
#### 2) Sort Order By
#### 3) Sort Group By
#### 4) Sort Unique
