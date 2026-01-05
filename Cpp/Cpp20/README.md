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
