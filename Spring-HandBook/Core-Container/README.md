
## IOC/DI
- IOC
  - Inversion Of Control 제어의 역전을 의미.
  - 객체의 생성, 생명주기, 관리등 객체에 대한 주도권을 프레임워크가 가진것을 의미한다.
  - IoC를 통해 Application을 구성하는 객체 간의 낮은 결합도 유지 가능
  - IoC의 역할을 담당하는 것은 Spring Container (IoC Container)

- DI
  - Dependency Injection (의존성 주입)
  - new로 객체를 생성하는 것이 아닌, 외부에서 생성된 객체를 주입받아 사용하는 것.
  - 결합성을 class로 부터 분리.
  - Application 실행 시점에 객체 간의 관계를 결정, 주입
  - DI 방법 3가지
    - 생성자 주입
    - 필드 주입
    - Setter(수정자) 주

## Spring Container
- Spring Application 내에서 자바 객체를 관리하는 공간.
- 자바 객체를 Bean이라고 부름
- 컨테이너의 역할은 의존성 주입(DI, Dependency Injection)을 통하여 Application을 구성하는 Bean들의 생명주기를 개발자 대신 관리함

- 스프링 컨테이너의 종류는 크게 2가지
  - BeanFactory
  - ApplicationContext

## BeanFactory / ApplicationContext
- BeanFactory
  - 빈을 생성하고 의존관계를 설정하는 기능을 담당하는 가장 기본적인 IoC 컨테이너, 클래스
  - DI 엔진만 있는 미니멀 컨테이너

- ApplicationContext
  - ApplicationContext는 BeanFactory를 구현하고 있어 BeanFactory의 확장된 버전이라고 생각.
  - 실무에 필요한 기능을 포함한 스프링 컨테이너
 
- BeanFactory라고 말할 때는 빈을 생성하고 관계를 설정하는 IoC의 기본 기능에 초점을 맞춘 것이고,
  ApplicationContext는 별도의 정보를 참고해서 빈의 생성, 관계 설정 등의 제어를 총괄하는 것에 초점을 맞춘 것.
<br>

## BeanDefinition
스프링은 Bean을 그냥 바로 New하지 않고 설계도 메타정보의 BeanDefinition을 먼저 만듦.
  -  Bean 이름
  -  Bean 클래스 타입
  -  Scope (Singleton / prototype / ...)
  -  Lazy 여부
  -  생성자/팩토리 메서드 정보
  -  initMethod / destoryMethod
이 BeanDefinition이 BeanFactory(DefaultListableBeanFactory)에 등록.
<br>
등록되는 경로는 크게 3가지<br>
1. @ComponentScan으로 찾은 클래스 (@Component, @Service, @Repository, @Controller 등)<br>
2. @Configuration 클래스 안의 @Bean 메서드<br>
3. XML / JavaConfig에서 수동 등록<br>
<br><br>

## Bean 생성, DI
스프링이 Bean을 실제로 쓰려고 할 때.
1. 해당 BeanName에 대한 BeanDefinition 조회<br>
2. 생성자 결정<br>
    - @Autowired 붙은 생성자
    - 생성자가 하나뿐이면 그것 사용
    - 그렇지 않으면 기본 생성자
3. 생성자 파라미터에 주입할 Bean들 먼저 생성(재귀)<br>
4. New를 통해 Bean 인스턴스 생성<br>
5. 그 후, 필드/세터 주입 처리<br>
    - @Autowired, @Value, @Qualifier 등.
<br><br>

## Bean LifeCycle Callback
1. 객체 생성 (생성자 호출)
2. 의존성 주입 롼료
3. 초기화 단계
    - @PostContruct 메서드 호출
    - InitializingBean#afterPropertiesSet() (Legacy)
    - @Bean(initMethod = "init") 지성 시 init() 호출
4. 애플리케이션 동작 중
5. 컨텍스트 종료시 (Context.close())
    - @PreDestroy 메서드 호출
    - DisposableBean#destroy() 호출
    - @Bean(destroyMethod = "close") 지정 시 close() 호출
<br><br>

## @ComponentScan, @Configuration, @Bean 처리 과정
- @ComponentScan 처리과정
```java
@Configuration
@ComponentScan(basePackages = "com.example.app")
public class AppConfig {
}
```
1. 스프링은 @ComponentScan이 붙은@Configuration 클래스를 먼저 BeanDefinition으로 등록
2. ComponentScanAnnotationParser 같은 내부 컴포넌트가 basePackages 경로를 스캔
3. 클래스패스 상에서.class 파일들을 흝으면서
    - @Component
    - @Service
    - @Repository
    - @Controller
    - @Configuration
      등 메타 어노테이션을 찾음.
4. 찾은 클래스마다 BeanDefinition 생성 후 BeanFactory에 등록
    - Bean 이름은 기본적으로 클래스명에서 앞글자 소문자 (ex. OrderServie -> orderserice)
    - 필요 시 @Component("customName") 으로 이름 지정 가
  - @ComponentScan은 어떤 클래스를 Bean으로 쓸 것이닞 자동 탐색 후 BeanDefinition을 등록하는 단계
<br>

- @Configuration 처리 과정 (CGLIB Proxy)
```java
@Configuration
public class AppConfig {

    @Bean
    public MemberService memberService() {
        return new MemberServiceImpl(memberRepository());
    }

    @Bean
    public MemberRepository memberRepository() {
        return new MemoryMemberRepository();
    }
}
```
@Configuration 클래스는 자기 자신도 Bean, but 순수 Java 객체로 쓰지 않고 스프링이 CGLIB로 프록시 클래스를 만들어서 등록.<br>
memberService()를 호출할 때마다 new MemberServiceImpl(memberRepository())를 직접 호출하면 memberRepository()가 매번 새로 만들어질 수 있음<br>
스프링은 싱글톤 보장을 위해 아래처럼 동작.
1. @Configuration 클래스를 상속한 CGLIB 서브클래스를 만듦 (아래 느낌)
```java
public class AppConfig$$EnhancerBySpringCGLIB extends AppConfig {
    private MemberRepository memberRepositorySingleton;

    @Override
    public MemberRepository memberRepository() {
        if (memberRepositorySingleton == null) {
            memberRepositorySingleton = super.memberRepository();
        }
        return memberRepositorySingleton;
    }

    @Override
    public MemberService memberService() {
        // 여기서도 super.memberService() 대신
        // 이미 캐싱된 memberRepositorySingleton 사용되도록 제어
    }
}
```
2. 스프링 컨테이너는 AppConfig 원본 대신 이 프록시 클래스를 Bean으로 등록
3. 그래서 memberRepository()를 여러 번 호출해도 같은 Bean 인스턴스를 반환하게 됨

@Configuration은
@Bean 메서드 호출을 가로채서 이미 컨테이너에 등록된 Bean이면 그걸 반환하고, 없으면 새로 만들어 등록 후 그걸 반환<br>
이 프록시 구조로 @Configuration 클래스는 항상 CGLIB Proxy로 등록되는 게 기

<br>

## Bean 생성 → 의존성 주입 → 라이프사이클 전체 흐름
스프링 부팅 (SpringApplication.run(..)) 순서

1. ApplicatioNContext 생성
2. Bean 정의 읽기 및 등록
    - @ComponentScan, @Configuratin, @Bean 등으로부터 BeanDefinition 생성
3. BeanFactoryPostProcessor / ConfigurationClassPostProcessor 실행
    - @Configuration 분석, @Bean 메서드 스캔, 추가 BeanDefinition 등록
4. Bean 인스턴스 생성 + 의존성 주입 (DI)
    - 생성자 주입, 필드 주입, setter 주입
5. 라이프사이클 콜백 호출
    - @PostConstruct, @InitializingBean#afterPropertiesSet, initMethod 등
6. AOP 프록시 적용
    - @Transactional, @Async 등 -> 실제 Bean 대신 Proxy 등록
7.애플리케이션 준비 완료
