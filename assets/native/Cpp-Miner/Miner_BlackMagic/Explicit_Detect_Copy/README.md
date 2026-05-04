---
title: 礦坑系列：用「explicit」來偵測隱式轉換所引起的複製
date: 2022-05-22
tag: C++ Miner-BlackMagic
category: C++ Miner
---

# 礦坑系列：用「explicit」來偵測隱式轉換所引起的複製

- source：[C++ Weekly - Ep 241 - Using explicit to Find Expensive Accidental Copies](https://www.youtube.com/watch?v=5wJ-jKK_Zy0)
- source：[C++ Weekly - Ep - 198 - Surprise Uses For explicit Constructors](https://www.youtube.com/watch?v=Q4SXFkTzD28)

## 用「explicit」來偵測隱式轉換所引起的複製

有時候我們會有小物件，像是 string view，此時使用 copy 來傳遞參數也是個很好的選擇，因為他的大小只有 2 個 pointer 的大小，在現代的 x64 calling convention 架構下這可以僅用 2 個暫存器來完成傳遞，比把參數 push 進 stack 或藉由 pointer/reference 來存取某段位址等等的更有效率

因此 copy 常常是個更好的選擇，至於該如何有效的利用複製，寫出 cache friendly 的 code 可以再去看看 Jserv 老師的課程

不過有時候某些型態的物件的 copy 成本很高，所以我們不會希望他在每個地方都被複製一次，造成效能上的損失，這時我們可以使用 `explicit` 來檢查我們是否有不小心造成物件的複製

先看一下 `explicit` 用在建構子上的狀況：

```cpp
struct S {
  explicit S(int) {}
};

void fn(const S &){};

int main()
{
  // fn(10);    // error, prohibit implicit call constructor by integer
  fn(static_cast<S>(10));    // ok
  fn(S{ 10 });    // ok
}
```

上例中我們在 `S(int)` 前用了 `explicit` 修飾，因為沒有可用的轉型能把 `10` 轉為 `S`，因此 `fn(10)` 被擋掉了，除非我們顯式的做了轉型，把 `10` 作為 `S` 傳入，否則不會過編譯

這可以幫助我們去檢查不小心造成的複製，例如下面這個例子：

```cpp
#include <iostream>
#include <string>

void fn(const std::string &s)
{
  std::cout << static_cast<const void *>(s.c_str()) << '\n';
};

int main()
{
  std::string s = "123";
  std::cout << static_cast<const void *>(s.c_str()) << '\n';
  fn(s);    // same
  fn(s.c_str());    // different, the address is the address of the copy object
}
```

輸出：

```cpp
0xa1155ffc00
0xa1155ffc00
0xa1155ffc30
```

藉由上例你可以發現 `fn(s.c_str())` 會導致複製產生，這是因為 `std::string` 內有一個吃 `const char*` 參數的建構子可以被 implicit 呼叫：

```cpp
// mingw-gcc 11.2.0
basic_string(const _CharT* __s, const _Alloc& __a = _Alloc())
: _M_dataplus(_M_local_data(), __a)
{
const _CharT* __end = __s ? __s + traits_type::length(__s)
  // We just need a non-null pointer here to get an exception:
  : reinterpret_cast<const _CharT*>(__alignof__(_CharT));
_M_construct(__s, __end, random_access_iterator_tag());
 }
```

這種複製有時候是我們不會注意到的，此時我們可以藉由在對應的複製建構子前面加上 `explicit` 來看是否有複製產生：

```cpp
struct S {
  S() = default;
  explicit S(const S &){};
};

void fn(S) {}

int main()
{
  S s;
  // fn(s);    // error
  fn(S(s));    // okay
}
```

可以看見我們需要顯式的呼叫 copy 才可以，否則會被擋下來

這在 `S` 的複製成本很高時有用，不過可能會在 code 的可讀性上帶來一定程度的影響，因此我自己覺得最好的辦法還是把 copy 的最佳化寫好，並且最好是用 implicit safe 的設計，但不管如何，這還是個很有用的工具，在你需要一次性的檢查到底哪裡有複製時很有用

另外，對於只有一個引數的建構子來說，加上 explicit 是個很好的習慣，這可以幫助你避免很多意外的隱式轉換，這大概也是 C++ 有那麼多奇怪的 cast 的原因之一

想像一下如果 `>>` 的 bool conversion 不是 explicit 會發生什麼事：

```cpp
#include <iostream>

int main()
{
  int i{};
  std::cout >> i;    // 註：是 `>>` 沒錯，沒打錯
}
```

那麼這件事會自動發生：

```cpp
#include <iostream>

int main()
{
  int i{};
  static_cast<bool>(std::cout) >> i;
}
```

這是個合法的行為，但幾乎是個災難ㄏㄏ，尤其當你手殘把 `<<` 打成 `>>` 的時候，要找這個小 bug 大概會找到中風，但因為這個 conversion 是 explicit 的，所以一切安好 ：D

### 小缺點

雖然前面講了那麼多，但在建構子前加上 `explicit` 可能會有些壞處：

```cpp
#include <iostream>

struct S {
  S() = default;
  explicit S(const S &) { std::puts("copy"); }
};

S foo()
{
  S a;
  return a;    // error
}

int main(int argc, char *argv[])
{
  S a = foo();
}
```

上面這個例子由於 `explicit`，它破壞了 NRVO 最佳化，因此會想要去用 move，但我們沒有寫，所以無法通過編譯

此時<span class = "yellow">黑魔法</span>來了，我們把移動建構子加上：

```cpp
#include <iostream>

struct S {
  S() = default;
  explicit S(const S &) { std::puts("copy"); }
  S(S &&) { std::puts("move"); }
};

S foo()
{
  S a;
  return a;
}

int main(int argc, char *argv[])
{
  S a = foo();
}
```

結果你會發現他不去呼叫移動，NRVO 回來了，我第一次看到的時候真的覺得太神奇了，不過 NRVO 畢竟不保證發動，但最少仍會有移動，所以這樣是 OK 的，由此可見還是要<span class = "yellow">遵守 Rule of three/five</span>

<center-panel natural>

（感謝社團內的 <em>Actual Wizard</em> wreien 提供例子）

</center-panel>
