## [Annotation](MakeAnnotation/)

### [Spring](Spring/)

- `@Component` : Spring IoC 컨테이너가 클래스를 자동으로 감지해서 Bean으로 등록. 패키지 스캔(Component Scan) 대상에 포함되어 있으면 빈으로 올라옴.
- `@Autowired` :
- `@Transactional` :
- `@RestController` : 

### [Lombok](Lombok/)

- `@Getter/@Setter` : @Getter/@Setter를 붙이면 해당 필드의 getter,setter 메서드를 자동 생성, 클래스에 붙이면 모든 non-static 필드에 getter,setter를 생성.
- `@Data` : 필드 기반으로 `@getter/@setter`, `@toString`, `@equals/@hashCode`, `@RequiredArgsConstructor` 등을 한 번에 생성해주는 어노테이션
- `@ToString` : 클래스의 toString() 메서드를 자동 생성. 설정을 통해 상위 클래스의 출력 포함 여부와 필드 접근 방식을 제어 가능.
- `@NoArgsConstructor` : 파라미터가 없는 기본 생성자를 자동 생성.
- `@RequiredArgsConstructor` : 초기화되지 않은 final 필드와 @NonNull 필드를 위한 필수 파라미터 생성자를 자동 생성.
- `@AllArgsConstructor` : 클래스의 모든 필드에 대해 하나의 파라미터를 갖는 전체 필드 생성자를 자동 생성

### [JPA](JPA/)
- Class-Level
  - `@Entity` : JPA에서 이 클래스를 테이블과 매핑되는 엔티티로 인식하도록 표시하는 어노테이션
  - `@MappedSuperclass` : 
  - `@Embeddable` : 
  - `@IdClass` : 
  - `@Cacheable` :
  - `@EntityListeners` :
  - `@NamedQuery` : 

- Field-Level
  - `@SequenceGenerator` :
  - `@JoinTable` : @OneToMany, @ManyToMany 같은 컬렉션/맵 관계를 직접 FK로 매핑하는 게 아니라 매핑 중간 테이블 하나를 만들어서 관리
  - `@OneToOne` : 엔티티 간 1:1 관계를 나타내며, FK를 가진 쪽이 “Owner”, mappedBy를 가진 쪽이 “Inverse”. FK를 가지는 Owner 쪽은 @JoinColumn을 사용하고, 반대편은 mappedBy만 쓰는 것이 올바른 1:1 매핑 구조.
  - `@OneToMany` : @OneToMany는 1:N 관계를 표현하며, 컬렉션(List/Set 등) 필드에서 사용. FK(외래키)는 반대편(N쪽) 엔티티가 가지고, 그 필드를 mappedBy로 지정해야 올바른 양방향 매핑이 됨.
  - `@ManyToOne` : @ManyToOne은 N:1 관계(여러 개가 하나를 참조)를 나타내며, FK(외래키)는 항상 Many(자식) 쪽에 존재.
  - `@ManyToMany` : @ManyToMany는 두 엔티티가 서로 다대다(M:N) 관계를 표현하며, 중간 조인 테이블을 통해 매핑. 한쪽은 Owner(조인 테이블을 생성/관리), 다른 한쪽은 mappedBy를 사용해 Inverse(읽기 전용) 역할을 함.
