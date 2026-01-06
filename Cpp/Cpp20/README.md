### 컴파일 타임 프로그래밍
- constexpr 함수는 컴파일 타임 상수를 전달하면 컴파일 타임 함수로 동작,
- 일반 변수를 전달하면, 일반 함수들처럼 런타임 함수로 동작

#### consteval
- 컴파일 타임 함수로만 동작. 컴파일 타임에만 동작하는 함수를 즉시 함수( Immediate function)
- constexpr 함수와 같이 제약이 있음
```cpp
constexpr int Add_1(int a, int b) {return a + b;}
consteval int Add_2(int a, int b) {return a + b;}

enum class MyEnum {Val = Add_1(1, 2)}; // 컴파일 타임 함수로 사용
EXPECT_TRUE(static_cast<int>(MyEnum::Val) == 3); 

enum class MyEnum {Val = Add_2(1, 2)}; // 컴파일 타임 함수로 사용
EXPECT_TRUE(static_cast<int>(MyEnum::Val) == 3); 

int a{10};
int b{20};
EXPECT_TRUE(Add_1(a, b) == 30); // 런타임 함수로 사용
EXPECT_TRUE(Add_2(a, b) == 30); // (X) 컴파일 오류. 런타임 함수로 사용할 수 없습니다.
```

#### constinit
- 전역변수, 정적 전역 변수, 정적 멤버 변수는 프로그램이 시작될 때 생성, 종료될 때 해제됨.
- but 생성되는 시점이 명확하지 않아 링크 순서에 따라 변수의 값이 달라짐
```cpp
// Test_A.cpp
int f() {return 10;}
int g_A = f(); // 전역 변수. 런타임에 f() 함수를 이용해서 초기화

// Test_B.cpp
#include <iostream>

extern int g_A;
int g_B = g_A; // (△) 비권장. 컴파일 단계에선 일단 0으로 초기화 하고, 나중에 링크 단계에서 g_A의 값으로 초기화.
               // g_A가 초기화 되었다는 보장이 없기에 링크 순서에 따라 0 또는 10이 됨.

int main() {
    std::cout << "g_A : " << g_A << std::endl;
    std::cout << "g_B : " << g_B << std::endl; // (△) 비권장. 0이 나올 수도 있고, 10이 나올 수도 있음.

    return 0;
}
```

- constinit로 전역변수, 정적 전역 변수, 정적 멤버 변수를 컴파일 타임에 초기화할 수 있음
- 생성 시점이 명호가하지 않은 문제가 해결됨 (but 이 방법 보다 함수내 정적 지역 변수를 사용하는게 good?)
- constinit은 컴파일 타임에 초기화되어야 함. const 성질 없음. 지역변수로 사용 불가
- 전역 변수, 정적 전역 변수, 정적 멤버 변수에만 사용 가능
```cpp
// Test_A.cpp
constexpr int f_11() {return 10;} // 컴파일 타임 상수
constinit int g_A_20 = f_11(); // 컴파일 타임에 초기화

// Test_B.cpp
#include <iostream>

extern constinit int g_A_20;
int g_B_20 = g_A_20; // 컴파일 타임에 초기화

int main() {
    std::cout << "g_A_20 : " << g_A_20 << std::endl;
    std::cout << "g_B_20 : " << g_B_20 << std::endl; // 항상 10

    return 0;
}
```
```cpp
// ex2
constexpr int f_11() {return 10;} // 컴파일 타임 함수 입니다.

// constinit int 로 받을 수도 있지만, s_Val_20과 s_m_Val_20에 대입하기 위해 const를 붙였습니다.
constinit const int g_Val_20 = f_11(); // constinit여서 컴파일 타임에 초기화 되어야 합니다.
    
// g_Val_20은 컴파일 타임 const 상수 입니다.
constinit static int s_Val_20 = g_Val_20; // constinit여서 컴파일 타임에 초기화 되어야 합니다.

class T_20 {
public:
    // C++17 부터 인라인 변수를 이용하여 정적 멤버 변수를 멤버 선언부에서 초기화할 수 있습니다.
    constinit static inline int s_m_Val_20 = g_Val_20; // constinit여서 컴파일 타임에 초기화 되어야 합니다.
};
```

#### constexpr 함수 제약 완화
- C++20에서는 가상 함수, dynamic_cast, typeid(), 초기화되지 않은 지역 변수, try-catch(), 공용체 멤버 변수 활성 전환, asm등 사용 가능.

- 가상 함수를 오버라이딩한 Func 함수를 컴파일 타임 상수로 사용. 이를 Base*를 통해 가상 함수 호출시, 런타임에 동작
```cpp
class Base {
public:
    virtual int Func() const {return 0;}
};
class Derived_20 : public Base {
public:
    constexpr virtual int Func() const override {return 1;} // C++17 이하에서는 컴파일 오류가 발생했습니다.
};

constexpr Derived_20 a_20;
enum class MyEnum_11 {Val = a_20.Func()}; // 컴파일 타임 상수

const Base* ptr = &a_20;
EXPECT_TRUE(ptr->Func() == 1); // 부모 개체의 포인터로 런타임에 가상 함수를 호출할 수 있습니다.
// static_assert(ptr->Func()); // (X) 컴파일 오류. 컴파일 타임 상수가 아닙니다.
```
- dynamic_cast, typeid() 사용
```cpp
class Base {
public:
    virtual int Func() const {return 0;}
};
class Derived_20 : public Base {
public:
    constexpr virtual int Func() const override {return 1;} 
};
    
constexpr int Func_20() {

    Derived_20 d;

    Base* base = &d;
    Derived_20* derived_20 = dynamic_cast<Derived_20*>(base); // dynamic_cast를 사용할 수 있습니다.
    typeid(base); // typeid를 사용할 수 있습니다.
    
    return 1;
}
```
- 초기화되지 않은 지역 변수 정의, try-catch(), asm(인라인 어셈블리) 허용
```cpp
constexpr void Func_20() {
    int a; // 초기화되지 않은 지역 변수

    try {} // try-catch
    catch (...) {}
}
```
- 공용체 멤버 변수 활성 전환 허용
```cpp
union MyUnion {
    int i;
    float f;
};

constexpr int Func_20() {
 #if 202002L <= __cplusplus // C++20~     
    MyUnion myUnion{};

    myUnion.i = 3;
 
    // (X) ~C++20 컴파일 오류. change of the active member of a union from 'MyUnion::i' to 'MyUnion::f'
    // (O) C++2O~       
    myUnion.f = 1.2f; // 멤버 변수 활성 전환을 허용합니다.
#endif         
    return 1;
}

static_assert(Func_20()); 
```



### 범위 기반 for()에서 초기식
- 기존의 범위 기반 for()에서는 초기식을 제공하지 않았음
- C++20 부터는 범위 기반 for()에서 초기식을 사용가능

```cpp
int sum{0};

// 초기식을 이용하여 v_20 값을 초기화 합니다.
for (std::vector<int> v_20{1, 2, 3}; int val : v_20) { 
    sum += val;
}

EXPECT_TRUE(sum == 1 + 2 + 3);
```


### using enum
- 범위 있는 열거형 덕에 이름 충돌은 회피되지만, 매번 열거형의 이름을 함께 명시하다 보니 코드가 지저분해짐
- C++20 부터는 using enum이 추가되어 범위 있는 열거형의 이름 없이 열거자를 유효 범위내에서 사용할 수 있음

```cpp
enum class Week {
    Sunday, Monday, Tuesday, Wednesday, 
    Thursday, Friday, Saturday
};
Week week{Week::Sunday}; 

bool isFreeDay{false};
switch(week) {
case Week::Sunday: isFreeDay = true; break;
case Week::Monday: break;
case Week::Tuesday: break;
case Week::Wednesday: break;
case Week::Thursday: break;
case Week::Friday: break;
case Week::Saturday: break;
}

///////////////

enum class Week {
    Sunday, Monday, Tuesday, Wednesday, 
    Thursday, Friday, Saturday
};
Week week{Week::Sunday}; 
bool isFreeDay{false};
switch(week) {
using enum Week; // (C++20~) 유효 범위 내에서 Week 열거자를 사용가능
case Sunday: isFreeDay = true; break;
case Monday: break;
case Tuesday: break;
case Wednesday: break;
case Thursday: break;
case Friday: break;
case Saturday: break;
}

```
