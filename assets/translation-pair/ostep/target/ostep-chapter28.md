---
title: OSTEP 28：Locks
date: 2025-05-29
tag:
- OS
- OSTEP
category: OS
---

# OSTEP 28：Locks

從並行（concurrency）的介紹中，我們看到了一個並行程式設計（concurrent programming）中最根本的問題：我們希望能夠原子性地執行一連串的指令，但因為單一處理器上會發生中斷（interrupt），或者在多核處理器上有多個執行緒（thread）同時執行，所以我們沒辦法做到這點

因此，在本章中我們會直接處理這個問題，並介紹一種叫做鎖（lock）的東西。 程式設計師會在原始程式碼中加上鎖，將它套用在臨界區（critical section）的周圍，藉此確保這類臨界區的執行效果都能像「一條原子指令」一樣

## 28.1 Locks: The Basic Idea

舉個例子，假設我們的臨界區看起來像這樣，也就是最典型的共享變數更新：

```c
balance = balance + 1;
```

當然，也可能會有其他種類的臨界區，例如替連結串列（linked list）新增元素，或是對共享資料結構做更複雜的更新，不過現在我們先從這個簡單的例子開始。 如果要使用鎖，我們會在臨界區的外圍加上這類程式碼：

```c
lock_t mutex; // some globally-allocated lock 'mutex'
...
lock(&mutex);
balance = balance + 1;
unlock(&mutex);
```

鎖就是一個變數，所以如果你要使用鎖，就必須宣告一個型態是「鎖」的變數（像上面的 `mutex`）。 這個變數（簡稱鎖）會儲存目前鎖的狀態，狀態可能是「閒置（available）」，也稱為 unlocked 或 free，代表目前沒有任何執行緒持有這把鎖； 也可能是「被佔用（acquired）」，也稱為 locked 或 held，代表有一個執行緒正在持有這把鎖並可能正處於臨界區中。 雖然我們也可以在鎖的資料結構裡儲存額外的資訊（例如目前是誰持有鎖），或是等待佇列（queue）的順序，但這些資訊對使用者來說都是不可見的

`lock()` 和 `unlock()` 這兩個函式的語意非常簡單。 當你呼叫 `lock()` 時，就是在嘗試取得那把鎖。 如果目前沒有其他執行緒持有它（鎖處於「閒置」狀態），那這個執行緒就會成功取得鎖並進入臨界區。 這個執行緒有時候會被稱為這把鎖的擁有者（owner）。 如果之後有另一個執行緒也對同一個鎖（如例子中的 `mutex`）呼叫 `lock()`，它就會阻塞不回傳，直到原本持有鎖的執行緒解鎖。 這樣就能確保同一時間只有一個執行緒能夠進入臨界區

當鎖的擁有者呼叫 `unlock()` 時，這把鎖就會再次變回「閒置」狀態。 如果此時沒有其他執行緒在等這把鎖（也就是沒有人卡在 `lock()` 裡），那它的狀態就單純地被設成閒置狀態。 如果有其他執行緒正在等待它（也就是卡在 `lock()` 裡），則其中的某個執行緒最終會察覺到這個狀態的變化，然後成功取得鎖並進入臨界區

鎖給了程式設計師一點點控制排程的能力。 一般來說，我們把執行緒看作是由程式設計師建立、但由作業系統依自己方式進行排程的實體。 而鎖則是把部分控制權交還給程式設計師，透過在某段程式碼外面加上鎖，程式設計師就能保證同一時間最多只有一個執行緒能執行該段程式碼。 換句話說，鎖可以幫助我們把傳統作業系統那種混亂、不可預測的排程行為，轉換成一種較可控的機制

## 28.2 Pthread Locks

POSIX 函式庫中使用的鎖的名稱是 **mutex**，這是因為它用來在執行緒間提供互斥（mutual exclusion）的性質。 換句話說，如果某個執行緒進入了臨界區，它就會排除其他執行緒，直到它執行完這段區域

因此當你看到下面這段 POSIX threads 程式碼時，要知道它做的事情跟我們前面討論的一樣（這裡仍使用我們先前的包裝函式，會在 lock 或 unlock 發生錯誤時直接退出）：

```c
pthread_mutex_t lock = PTHREAD_MUTEX_INITIALIZER;

Pthread_mutex_lock(&lock); // wrapper; exits on failure
balance = balance + 1;
Pthread_mutex_unlock(&lock);
```

你可能也注意到，POSIX 的版本會把鎖的變數當作參數傳給 `lock` 和 `unlock`，這是因為我們可能會用不同的鎖來保護不同的變數。 這麼做可以提升並行性（concurrency）：與其在任何臨界區都用一把「大鎖」（稱為粗粒度鎖，英文為 coarse-grained locking），更常見的做法是用多把鎖分別保護不同的資料與資料結構，這樣可以讓更多執行緒同時執行被鎖包圍的程式碼（稱為細粒度鎖，英文為 fine-grained locking）

## 28.3 Building A Lock

到目前為止，你應該已經對鎖的運作方式有一定程度的了解，至少從程式設計師的角度來看是這樣。 但如果我們想要自己實作一把鎖呢？ 這需要哪些硬體支援？ 作業系統又需要提供什麼協助？ 這些就是本章剩下部分將要探討的問題

:::info
如何實作一個 lock

我們要怎麼建構出一個「高效」的鎖呢？ 高效的鎖必須能夠以低成本提供互斥，而且最好還具備一些額外的特性（我們後面會提到）。 這需要哪些硬體支援？ 又需要哪些作業系統的幫助？

要實作出一個能正常運作的鎖，我們得仰賴老朋友：硬體，還有另一位好夥伴：作業系統。 這些年來，許多電腦架構的指令集都加入了一些特別的「硬體原語（hardware primitive）」來支援這類功能。 雖然我們不會深入探討這些指令的底層實作（那是計算機結構的範疇），但我們會學習如何「使用」這些指令來實作互斥的基本單元，像是鎖。 我們也會學習作業系統如何參與其中，來補足這整個設計，使我們得以建立出一套完整且先進的鎖函式庫
:::

## 28.4 Evaluating Locks

在開始實作鎖之前，我們應該先釐清目標，也就是要思考該如何評估一個鎖的實作效果。 要判斷一個鎖是否運作正常（甚至運作得好），我們必須先建立一些基本的評估標準

第一項標準是這個鎖是否能完成它最基本的任務，也就是提供互斥。 換句話說，這個鎖能否確實阻止多個執行緒同時進入臨界區？

第二項標準是公平性（fairness）。 每個競爭（contending）這把鎖的執行緒是否都有公平的機會可以在鎖被釋放後成功取得它？ 換句話說：會不會有某個執行緒一直競爭鎖卻永遠搶不到它，最後發生「飢餓（starvation）」的情況？

最後一項標準是效能，也就是使用鎖所帶來的額外時間成本，這裡有幾種不同的情境值得考慮：

- 第一種是沒有競爭的情況：如果只有一個執行緒執行，它不斷地取得並釋放鎖，這樣的操作成本有多高？
- 第二種是多個執行緒在單一 CPU 上競爭同一把鎖，這時會不會造成效能瓶頸？
- 最後一種情況是多顆 CPU，各自有執行緒在競爭同一把鎖，這樣的情況下鎖的效能表現又會如何？

藉由比較這些不同的情境，我們就能更清楚地理解各種鎖的技術在實務上的效能影響（下文將進一步探討）

## 28.5 Controlling Interrupts

最早用來實作互斥的解法之一，是在臨界區中關閉中斷。 這種做法是為單核系統設計的，程式碼可能會像這樣：

```c
void lock() {
    DisableInterrupts();
}

void unlock() {
    EnableInterrupts();
}
```

假設我們的系統只有一個 CPU，這種做法的用意是：藉由某些特殊的硬體指令，在進入臨界區前關閉中斷，這樣可以確保該段程式碼在執行時不會被打斷，看起來就像是原子地在執行。 執行完畢後，再重新啟用中斷，程式就可以照常繼續進行

這種做法的最大優點就是簡單易懂，你幾乎不需要費什麼腦就能理解它為什麼有效。 只要中斷被關閉，執行緒就可以確信自己執行的程式碼會順利跑完，不會被別的執行緒打斷

然而，這種方法的缺點也不少。 第一，這種方法必須讓任何執行緒都能執行這個特權操作（開關中斷），這等於是要信任所有使用這個功能的程式都不會濫用它。 你應該知道，只要我們必須「信任任意程式」，基本上就準備出事了。 比如，一個貪婪的程式如果一開始就呼叫 `lock()`，它就能壟斷整個 CPU。 更糟的是，一個寫壞或惡意的程式呼叫 `lock()` 後會直接進入無窮迴圈，此時作業系統將完全失去對系統的控制權，唯一的解法是「重開機」。 所以，如果把關閉中斷當作一般的同步方法來使用，那就代表我們太信任應用程式了

第二，這種方法不適用於多核處理器（multiprocessor）系統。 如果有多個執行緒分別在不同的 CPU 上執行，即使其中某個執行緒關閉了中斷，也無法阻止其他處理器上的執行緒進入同一個臨界區。 如今多核處理器系統早已普及，所以我們需要一種更好的同步方法

第三，如果中斷被關閉太久，可能會導致我們遺漏掉某些中斷，這會造成嚴重的系統問題。 想像一下，如果 CPU 錯過了硬碟裝置發出的「讀取完成」訊號，作業系統該怎麼知道它要喚醒等待此讀取的程式？

總結來說，關閉中斷這種方法，現在只在極少數特定情境下才會被拿來當作互斥的工具。 比方說，作業系統在存取自己的資料結構時，有時會暫時關閉中斷，以保證原子性，或避免複雜的中斷處理問題。 這種情境是合理的，因為在作業系統內部，我們不必再擔心信任問題，作業系統本來就只能信任自己執行特權操作

## 28.6 A Failed Attempt: Just Using Loads/Stores

為了擺脫基於關閉中斷的同步方式，我們必須依靠 CPU 的硬體支援與指令集來建立真正的鎖。 在這裡，我們會先嘗試用一個單一的 `flag` 變數來實作一把簡單的鎖。 雖然這個實作會失敗，但它能幫助我們掌握實作鎖所需要的基本概念，並讓我們了解為什麼光靠一個變數搭配普通的讀寫操作是遠遠不夠的

這個最初的嘗試（見 Figure 28.1）想法非常單純：用一個簡單的 `flag` 變數來表示鎖是否被某個執行緒所持有。 第一個進入臨界區的執行緒會呼叫 `lock()`，它先檢查 `flag` 是否為 `1`（這個例子中一開始不是），然後將 `flag` 設為 `1`，表示該執行緒成功取得了鎖。 執行完臨界區之後，該執行緒會呼叫 `unlock()` 將 `flag` 清為 `0`，表示鎖已被釋放

<center-panel natural title="（Figure 28.1: First Attempt: A Simple Flag）">

```c
typedef struct __lock_t { int flag; } lock_t;

void init(lock_t *mutex) {
  // 0 -> lock is available, 1 -> held
  mutex->flag = 0;
}

void lock(lock_t *mutex) {
  while (mutex->flag == 1) // TEST the flag
    ;                     // spin-wait (do nothing)
  mutex->flag = 1;          // now SET it!
}

void unlock(lock_t *mutex) {
  mutex->flag = 0;
}
```

</center-panel>

如果在第一個執行緒還在臨界區裡時，另一個執行緒呼叫了 `lock()`，它會在 while 迴圈中「忙等（spin-wait）」，直到第一個執行緒呼叫 `unlock()` 並清除 `flag`。 一旦 `flag` 被清除，這個等待中的執行緒就會跳出迴圈，將 `flag` 設為 `1`，然後進入臨界區。 不幸的是，這段程式碼存在兩個問題：正確性問題與效能問題

正確性上的問題在你習慣並行程式設計的思維之後會很容易看出來。 請想像如下交錯執行的情境（見 Figure 28.2），假設一開始 `flag = 0`：

![（Figure 28.2: Trace: No Mutual Exclusion）](image/28-2.png)

從這種交錯中你可以看出，只要中斷發生得剛剛好（或說剛剛不好），我們就能輕易出現這種情況：兩個執行緒都設了 `flag = 1`，然後都進入了臨界區。 因此我們顯然無法保證互斥性，連最基本的目標都沒達成

效能上的問題（我們之後還會進一步討論）則是：當某個鎖已經被持有時，其他執行緒會不斷地檢查 `flag` 的值，這種方式叫作「忙等（spin-waiting）」，忙等會浪費大量的時間在等待別的執行緒釋放鎖。 尤其是在單核系統上更是浪費，因為等待中的執行緒所等的那個執行緒根本沒機會執行（除非發生 context switch）。 因此，當我們繼續發展更進階的解法時，也必須同時思考如何避免這種效能浪費的情況

## 28.7 Building Working Spin Locks with Test-And-Set

由於「關閉中斷」在多核處理器系統上無效，而像前面提到的單純使用 load/store 的方法又無法正確地實作鎖，於是系統設計者開始設計硬體級別的同步原語來支援鎖的實作。 最早的多核處理器系統，例如 1960 年代初的 Burroughs B5000 <sup>[[M82]](#8)</sup>，就已經提供了這類支援。 如今，即便是單核系統也都具備這類同步原語

最簡單也最基本的硬體同步指令叫作 test-and-set（有時也叫 atomic exchange）。 它的行為可以用以下這段 C 程式碼來模擬：

```c
int TestAndSet(int *old_ptr, int new) {
  int old = *old_ptr; // fetch old value at old_ptr
  *old_ptr = new; // store 'new' into old_ptr
  return old; // return the old value
}
```

這個指令會回傳舊值，同時將指定記憶體位址的值設為新值，而且整個操作是原子的。 它之所以被稱為「test-and-set」，是因為它能夠同時「檢查（test）」舊值並「設定（set）」新值。 事實證明，這個稍強一點的指令已足以打造一把簡單的自旋鎖了，見圖 28.3：

<center-panel natural title="（Figure 28.3: A Simple Spin Lock Using Test-and-set）">

```c
typedef struct __lock_t {
    int flag;
} lock_t;

void init(lock_t *lock) {
    // 0: lock is available, 1: lock is held
    lock->flag = 0;
}

void lock(lock_t *lock) {
    while (TestAndSet(&lock->flag, 1) == 1)
        ;                   // spin-wait (do nothing)
}

void unlock(lock_t *lock) {
    lock->flag = 0;
}
```

</center-panel>

讓我們來確認為什麼這把鎖能運作。 先想像第一種情況：某個執行緒呼叫 `lock()` 時沒有其他執行緒持有鎖，因此 `flag` 為 `0`，此時呼叫 `TestAndSet(flag, 1)` 會回傳 `flag` 的舊值 `0`。 因此該執行緒測試到 `0` 後不會卡在 while 迴圈，並成功取得鎖，同時它也已原子性地把該值設成了 `1`，表示鎖現在已被持有。 而當執行緒離開臨界區時，便會呼叫 `unlock()` 把 `flag` 重新設為 `0`

第二種情況：已經有一個執行緒持有鎖（`flag` 等於 1），此時另一個執行緒也會呼叫 `lock()`，進而呼叫 `TestAndSet(flag, 1)`，但這次 `TestAndSet()` 回傳的是舊值 `1`，同時也會再次把它設成 `1`。 只要別的執行緒還持有鎖，`TestAndSet()` 就會一直回傳 `1`，因此該執行緒就會一直忙等，直到鎖被釋放。 當其他執行緒把 `flag` 設回 `0` 時，且這個執行緒再次呼叫 `TestAndSet()` 時，函式會回傳 `0` 並原子性地把 `flag` 設為 `1`，於是它就成功取得了鎖並進入了臨界區

透過把「測試舊值」與「設新值」合併成一個原子操作，我們便能確保同一時間只有一個執行緒能取得鎖，這就是打造「互斥原語（mutual exclusion primitive）」的方法

你現在應該也能明白為什麼這種鎖通常被稱為自旋鎖（spinlock），它是最簡單的一種鎖，會透過忙等持續消耗 CPU 週期，直到鎖可用為止。 要讓它在單核系統上正確運作，必須配合搶佔式（preempt）排程器，也就是能透過計時器中斷定期切換執行緒的排程器。 如果沒有搶佔機制，自旋鎖在單核上就沒有意義，因為忙等的執行緒會永遠佔住 CPU

:::tip
本文將 spinning 翻為了「忙等」，因為將它翻為「自旋」會有失 spinning 的原意，但 spinlock 的常見翻譯為「自旋鎖」，因此這邊保留了自旋鎖一詞。 有時口語上也會將「忙等」直接稱為「自旋」，閱讀時請記得他們兩個指的是同一件事（spinning）
:::

:::info
把並行視為惡意排程器來思考

從這個例子你應該能體會理解並行程式的思考方式，你該做的是假裝自己是一個惡意排程器，專門在最糟糕的時刻中斷執行緒，好讓這些脆弱的同步原語全部失敗，雖然這些中斷序列在現實中未必常見，但只要存在可能性，就足以證明某個方法無法保證正確，有時候，用惡意的角度來思考是很有幫助的
:::

:::info
Dekker 與 Peterson 的演算法

1960 年代，Dijkstra 把並行問題丟給他的朋友們，其中一位數學家 Theodorus Jozef Dekker 提出了第一個解法 <sup>[[D68]](#3)</sup>，與剛剛需要特殊硬體指令，或是需要作業系統支援的方案不同，Dekker 演算法只用了 load 與 store 這兩個指令（假設彼此具備原子性，這在早期硬體上成立）

Dekker 的方法後來被 Peterson <sup>[[P81]](#11)</sup> 改進，同樣地，它僅用 load 與 store，就能確保兩個執行緒不會同時進入臨界區，下面是 Peterson 的兩執行緒演算法，看看你能否讀懂 `flag` 與 `turn` 變數各自負責什麼：

```c
int flag[2];
int turn;

void init() {
    // indicate you intend to hold the lock w/ 'flag'
    flag[0] = flag[1] = 0;
    // whose turn is it? (thread 0 or 1)
    turn = 0;
}

void lock() {
    // 'self' is the執行緒ID of caller
    flag[self] = 1;
    // make it other thread's turn
    turn = 1 - self;
    while ((flag[1-self] == 1) && (turn == 1 - self))
        ; // spin-wait while it's not your turn
}

void unlock() {
    // simply undo your intent
    flag[self] = 0;
}
```

出於某些原因，當時一度流行研究不依賴特殊硬體的鎖，讓理論學者有大量課題可做。 然而，人們很快意識到只要假設一點硬體支援就能簡化許多事情，而這種支援從最早的多核處理器系統便已存在，於是這條研究路線就逐漸失去了實用價值。 此外，由於現代硬體採用了較鬆散的記憶體一致性模型，像上述這些演算法在現代系統上也已無法保證正確，更加削弱了其用途
:::

## 28.8 Evaluating Spin Locks

基於我們實作的基本自旋鎖，現在可以依照先前說過的幾個面向來評估它的效果。 鎖最重要的面向是正確性：它是否能提供互斥？ 這裡的答案是肯定的：自旋鎖一次僅允許一個執行緒進入臨界區，因而能保證正確性

下一個面向是公平性。 自旋鎖對等待中的執行緒是否公平？ 能否保證處於等待狀態的執行緒終究能進入臨界區？ 很遺憾，答案是否定的：自旋鎖不保證任何公平性。 在競爭情況下，正在忙等的執行緒可能永遠得不到鎖。 因此目前為止討論的簡單自旋鎖並不公平，且可能導致 starvation

最後一個面向是效能。 使用自旋鎖的成本為何？ 若要更細緻地分析，我們建議思考幾種不同情境。 第一種情境是多個 threads 在單核處理器上爭奪同一把鎖。 第二種情境則是假設執行緒分散在多顆 CPU 上

對自旋鎖而言，在單核情境下的效能開銷可能相當可觀。 想像持鎖的執行緒在臨界區內被排程器搶佔。 排程器接下來可能會輪流執行其餘 $N − 1$ 個執行緒，而每個執行緒都會嘗試取得鎖。 在這種情況下，每個執行緒都會在自己的時間片段（time slice）期間忙等，之後才讓出 CPU，導致 CPU 週期被大量浪費

然而，在多核環境下（且執行緒數量大致等於 CPU 數量時）自旋鎖的表現還算不錯。 直觀的理由是：假設執行緒 A 在 CPU 1，執行緒 B 在 CPU 2，兩者同時競爭同一把鎖。 若執行緒 A 取得了鎖，而執行緒 B 隨後嘗試取得鎖，B 會在 CPU 2 上忙等。 由於臨界區通常很短，鎖很快就會被釋放，B 也就能立即取得鎖並進入臨界區。 在這種情況下，忙等僅會消耗少量週期，因此算是有效的做法

## 28.9 Compare-And-Swap

另一種某些系統提供的硬體原語叫做 compare-and-swap 指令（在 SPARC 上的名稱），在 x86 則稱為 compare-and-exchange。 圖 28.4 給出了這條單一指令的 C 風格虛擬碼：

<center-panel natural title="（Figure 28.4: Compare-and-swap）">

```c
int CompareAndSwap(int *ptr, int expected, int new) {
    int original = *ptr;
    if (original == expected)
        *ptr = new;
    return original;
}
```

</center-panel>

compare-and-swap 的基本概念是：先檢查由 `ptr` 指向的記憶體的值是否等於 `expected`。 若相等，就把 `new` 寫入該位址； 若不相等，則什麼也不做。 無論哪種情況，都會回傳該位置的舊值，讓呼叫 compare-and-swap 的程式碼能得知操作是否成功

有了 compare-and-swap，我們可以用與 test-and-set 類似的方式實作鎖。 例如，只要把前面的 `lock()` 換成下面這段即可：

```c
void lock(lock_t *lock) {
    while (CompareAndSwap(&lock->flag, 0, 1) == 1)
        ; // spin
}
```

其餘程式碼和前面的 test-and-set 範例完全相同。 這段實作的運作方式也幾乎一樣：先檢查 `flag` 是否為 `0`，若是，就以原子方式將其設為 `1` 以取得鎖。 當鎖已被持有時，其他嘗試取得鎖的執行緒會持續忙等直到鎖被釋放。 若你想知道如何撰寫一段可從 C 調用、且真正執行於 x86 的 compare-and-swap，參考文獻 <sup>[[S05]](#13)</sup> 中的程式碼片段會很有幫助

最後，你或許已經感受到 compare-and-swap 比 test-and-set 更為強大。 日後當我們簡要探討 lock-free 同步等主題 <sup>[[H91]](#5)</sup> 時，將會利用到這種指令的威力。 不過，如果僅用它來建構一個簡單的自旋鎖，其行為與前面分析過的自旋鎖完全相同

## 28.10 Load-Linked and Store-Conditional

某些平台提供一組能協同運作的指令，用來建構臨界區。 例如在 MIPS 架構 <sup>[[H93]](#4)</sup> 中，你可以結合 load-linked 與 store-conditional 指令來實作鎖與其他並行結構。 這兩道指令的 C 虛擬碼列在圖 28.5 中，Alpha、PowerPC 與 ARM 也提供了類似的指令 <sup>[[W09]](#15)</sup>

<center-panel natural title="（Figure 28.5: Load-linked And Store-conditional）">

```c
int LoadLinked(int *ptr) {
  return *ptr;
}

int StoreConditional(int *ptr, int value) {
  if (no update to *ptr since LL to this addr) {
    *ptr = value;
    return 1; // success!
  } else {
    return 0; // failed to update
  }
}
```

</center-panel>

load-linked 的行為與一般的 load 指令類似，僅是從記憶體抓取一個值並放進暫存器。 關鍵差別在 store-conditional：只有當這段期間內沒有其他針對同一位址的 store 發生，store-conditional 才會成功（並更新剛剛 load-linked 的位址）。 若成功，store-conditional 會回傳 `1` 並把 `ptr` 指向的值改成 `value`； 若失敗，`ptr` 的值保持不變且回傳 `0`

試著自我挑戰：用 load-linked 與 store-conditional 來實作鎖。 完成後再看看下面的程式碼，這是其中一種簡單解答，見圖 28.6：

<center-panel natural title="（Figure 28.6: Using LL/SC To Build A Lock）">

```c
void lock(lock_t *lock) {
  while (1) {
    while (LoadLinked(&lock->flag) == 1)
      ; // spin until it's zero

    if (StoreConditional(&lock->flag, 1) == 1)
      return; // if set-to-1 was success: done
              // otherwise: try again
  }
}

void unlock(lock_t *lock) {
  lock->flag = 0;
}
```

</center-panel>

這裡 `lock()` 是關鍵。 先讓執行緒忙等 `flag` 變成 `0`（表示鎖未被持有）。 一旦條件符合，執行緒便以 store-conditional 嘗試取得鎖。 若成功，它會原子地把 `flag` 設為 `1`，隨即進入臨界區

舉個 store-conditional 失敗的例子。 執行緒 A 呼叫 `lock()` 並嘗試執行 load-linked，但因其未持有鎖而得到了 `0`。 假設它尚未執行 store-conditional 就被排程器中斷，接著執行緒 B 進來同樣執行 load-linked 也得到了 `0`。 此時兩個執行緒都完成了 load-linked 並準備執行 store-conditional。 由於這對指令的特性，只有一個執行緒能成功把 `flag` 改成 `1` 並取得鎖。 另一個執行緒的 store-conditional 會因為 `flag` 已被改動而失敗，只能重新嘗試取得鎖

幾年前在課堂上，學生 David Capel 提出了更精簡的寫法，適合喜歡布林運算短路的人，確實更短：

```c
void lock(lock_t *lock) {
    while (LoadLinked(&lock->flag) ||
          !StoreConditional(&lock->flag, 1))
        ; // spin
}
```

## 28.11 Fetch-And-Add

最後要介紹的一個硬體原語稱為 fetch-and-add 指令，它會以原子方式遞增某個位址的值，同時回傳該位址先前的舊值。 下面是 fetch-and-add 指令的 C 虛擬碼：

```c
int FetchAndAdd(int *ptr) {
  int old = *ptr;
  *ptr = old + 1;
  return old;
}
```

在本範例中，我們將利用 fetch-and-add 來實作一種更有意思的「排號自旋鎖（ticket lock）」，這種鎖最早由 Mellor-Crummey 和 Scott 提出 <sup>[[MS91]](#10)</sup>。 其 `lock` 與 `unlock` 程式碼如圖 28.7 所示

<center-panel natural title="（Figure 28.7: Ticket Locks）">

```c
typedef struct __lock_t {
  int ticket;
  int turn;
} lock_t;

void lock_init(lock_t *lock) {
  lock->ticket = 0;
  lock->turn = 0;
}

void lock(lock_t *lock) {
  int myturn = FetchAndAdd(&lock->ticket);
  while (lock->turn != myturn)
    ; // spin
}

void unlock(lock_t *lock) {
  lock->turn = lock->turn + 1;
}
```

</center-panel>

這種做法使用了兩個變數 `ticket` 與 `turn` 來構成了鎖。 運作流程很簡單：當某個執行緒想取得鎖時，先對 `ticket` 執行一次原子的 fetch-and-add，並將得到的回傳值作為該執行緒的號碼牌，存進 `myturn`。 接著系統會透過全域共享的 `lock->turn` 來判斷目前輪到哪個執行緒執行，當某個執行緒發現 `myturn == turn` 時，就代表輪到它進入臨界區了。 而釋放鎖時只需要把 `turn` 加一，讓下一個等待中的執行緒（若存在）可以進入臨界區

注意，這個方案與我們之前的例子有個重要差異：它保證所有執行緒都能取得進展。 一旦執行緒拿到自己的號碼牌，就能確定未來某個時刻一定輪到它（前面的執行緒離開臨界區並釋放鎖之後）。 之前的自旋鎖沒有這種保證，例如使用 test-and-set 的執行緒可能會無限忙等，而其他執行緒卻可以持續地取得並釋放鎖

:::info
程式碼越少越好（Lauer 定律）

程式設計師常常以自己寫了多少程式碼為榮，這種心態其實本末倒置。 真正該引以為傲的應該是：在完成同一件事情時，你寫的程式碼有多精簡。 簡短且易懂的程式碼永遠更好，因為它較易於維護，也較不容易藏有漏洞

正如 Hugh Lauer 在談到 Pilot 作業系統的建置時所說：「如果同樣的人多花一倍時間，他們可以用一半的程式碼做出同樣優秀的系統」<sup>[[L81]](#6)</sup>。 我們把這稱為 Lauer 定律，值得牢記。 所以下次當你想炫耀自己為了完成作業寫了多少行程式碼時，先想一想。 更好的做法是回去把程式碼重寫得更清晰、更精簡
:::

## 28.12 Too Much Spinning: What Now?

硬體類型的鎖非常簡單（只需要幾行程式碼），且確實能運作，這兩點對於任何系統或程式碼來說都是極佳的特性

然而在某些情況下，這種做法可能會相當沒效率。 假設在單核處理器上執行兩條執行緒。 現在想像執行緒 0 正在臨界區內持有鎖，卻不巧被中斷。 於是第二條執行緒（執行緒 1）嘗試取得鎖，卻發現鎖已被佔用，於是開始持續忙等。 最終定時器中斷觸發，執行緒 0 再度執行並釋放了鎖，之後等到執行緒 1 下一次獲得 CPU 時，它才終於不必再忙等那麼久就能取得鎖了

因此只要執行緒落入這種忙等的情況，它就會浪費整個時間片段，期間它做的事僅僅是不斷檢查一個暫時不會改變的值。 當有 $N$ 條執行緒爭奪同一把鎖時問題更糟，有 $N − 1$ 個時間片段可能就這樣被浪費在純忙等與等待單一執行緒釋放鎖

於是出現了下一個問題：如何避免無謂的忙等？ 我們要怎麼設計一種鎖，讓它不會在 CPU 上無謂地忙等浪費時間？

僅靠硬體支援無法解決這個問題，我們還需要作業系統的協助，接下來就來看看該怎麼辦

## 28.13 A Simple Approach: Just Yield, Baby

硬體支援已經讓我們走了很長一段路：鎖可以正常運作，甚至（像排號自旋鎖那樣）能在取得鎖時保持公平性。 不過我們仍舊面臨一個問題：如果在臨界區內發生 context switch，而持鎖的執行緒被中斷，其他執行緒就會開始無止境地忙等，等待那個被打斷且持有鎖的執行緒再度執行

我們的第一個例子是個簡單的方法：當你即將開始忙等時，不如把 CPU 讓給其他執行緒。 用 Al Davis 的話來說就是「just yield, baby！」<sup>[[D91]](#1)</sup>。 圖 28.8 展示了這種做法：

<center-panel natural title="（Figure 28.8: Lock With Test-and-set And Yield）">

```c
void init() {
  flag = 0;
}

void lock() {
  while (TestAndSet(&flag, 1) == 1)
    yield(); // give up the CPU
}

void unlock() {
  flag = 0;
}
```

</center-panel>

在這種做法中，我們假設作業系統提供了一個系統呼叫 `yield()`，當執行緒想放棄 CPU 並讓其他執行緒執行時就可以呼叫它。 一條執行緒可能處於三種狀態：「running」、「ready」或「blocked」。 `yield` 這個系統呼叫的功能很單純，就是把呼叫者從 running 狀態移到 ready 狀態，並讓另一條執行緒變成 running

想想兩條執行緒共用一顆 CPU 的例子。 在這種情況下，基於「讓出（yield）」的做法相當有效。 若某條執行緒呼叫 `lock()` 時發現鎖被佔用，它就會直接利用 `yield()` 來讓出 CPU，因此另一條執行緒便能繼續執行並離開臨界區。 在這樣單純的情境下，這種讓出的策略是個不錯的方法

現在來看另一種情況：有很多執行緒（假設 100 條）反覆競爭同一把鎖。 在此情境下，若其中一條執行緒取得鎖後在釋放前就被搶佔，其他 99 條執行緒會各自呼叫 `lock()`，發現鎖被佔用，然後讓出 CPU。 若排程器採用輪轉（round-robin）策略，那麼這 99 條執行緒會輪番執行「執行一小段然後讓出」的模式，直到持鎖的那條執行緒再次獲得 CPU 為止

雖然這種做法比起單純忙等來得好一些，但代價還是不小，因為那 99 個時間片段仍可能會被浪費掉，而且記得 context switch 的成本相當可觀。 更糟的是，這種方法並沒有解決 starvation 問題。 某條執行緒可能會陷入無窮無盡的讓出迴圈，而其他執行緒則不斷進入並離開臨界區

顯然，我們需要一種能直接解決 starvation 的辦法

## 28.14 Using Queues: Sleeping Instead Of Spinning

問題的根源在於先前的某些做法（排號自旋鎖除外）太過聽天由命，需要由排程器決定下一個要執行的執行緒。 如果排程器選得不好，執行中的執行緒要麼得一直忙等著鎖（第一種做法），要麼得立刻讓出 CPU（第二種做法），無論哪一種，都可能造成浪費，且無法避免 starvation

因此，我們必須明確控制鎖的擁有者將它釋放後該由哪個執行緒來接手此鎖。 為了做到這點，需要額外的作業系統支援，還要用一個佇列（queue）追蹤哪些執行緒正在等著取得此鎖

為了簡化，我們採用 Solaris 提供的兩個呼叫：`park()` 把呼叫的執行緒掛起睡眠，`unpark(threadID)` 依 `threadID` 喚醒指定的執行緒。 利用這兩個函式，我們可以實作一把鎖：若執行緒嘗試取得已被持有的鎖，就讓它睡。 當鎖變為可用的時，再喚醒它。 圖 28.9 的程式碼示範了這些原語的一種用法

<center-panel natural title="（Figure 28.9: Lock With Queues, Test-and-set, Yield, And Wakeup）">

```c
typedef struct __lock_t {
  int flag;
  int guard;
  queue_t *q;
} lock_t;

void lock_init(lock_t *m) {
  m->flag = 0;
  m->guard = 0;
  queue_init(m->q);
}

void lock(lock_t *m) {
  while (TestAndSet(&m->guard, 1) == 1)
    ; //acquire guard lock by spinning

  if (m->flag == 0) {
    m->flag = 1; // lock is acquired
    m->guard = 0;
  }
  else {
    queue_add(m->q, gettid());
    m->guard = 0;
    park();
  }
}

void unlock(lock_t *m) {
  while (TestAndSet(&m->guard, 1) == 1)
    ; //acquire guard lock by spinning

  if (queue_empty(m->q))
    m->flag = 0; // let go of lock; no one wants it
  else
    unpark(queue_remove(m->q)); // hold lock
                                // (for next thread!)
  m->guard = 0;
}
```

</center-panel>

這個範例裡做了幾件有趣的事。 第一，我們把舊的 test-and-set 概念與 wait queue 結合，打造出了更有效率的鎖。 第二，我們用 queue 來控制下一個取得鎖的執行緒，從而避免了 starvation

你可以注意到 `guard` 的本質上是用來保護 `flag` 與 `queue` 的一把自旋鎖，這代表我們並沒有完全消除忙等。 執行緒在取得或釋放鎖時如果被中斷，其他 threads 仍得忙等等它回來，不過忙等時間非常短（因為只花在 lock 與 unlock 的少量指令，而非用戶定義的臨界區），因此此方法仍屬合理

:::tip
這邊鎖被分成了兩層：

- `flag`：表示「真正的鎖」目前是不是被持有
  - `0` 代表鎖是空的，沒人持有
  - `1` 代表鎖已被持有
- `guard`：這不是使用者真正想拿的鎖，而是一個很短暫的內部保護鎖
  - 它用來保護 `flag` 和等待佇列 `q`，避免多個執行緒同時修改這些共享資料
  - 用 `TestAndSet()` 忙等取得
- `q`：等待這把鎖的執行緒佇列。 拿不到鎖的執行緒會把自己加進去，然後睡眠

所以執行緒先靠 `guard` 進入「管理區」，檢查 `flag`，如果 `flag == 0`，表示真正的鎖沒人拿，就直接拿走； 如果 `flag == 1`，表示有人拿著，那就把自己排進 `q`，然後 `park()` 進睡眠

因此他上面說「忙等時間非常短」的意思，以下面這個例子來說：

```c
  while (TestAndSet(&m->guard, 1) == 1)
    ; //acquire guard lock by spinning
```

如果 T1 拿到了 guard lock 後馬上被搶佔（preempt），那剩下的所有 threads 仍然會需要一直忙等，浪費整個時間片段，這與原先的情況是一樣的，你一樣有 $N − 1$ 個時間片段可能就這樣在忙等單一執行緒釋放鎖

但這邊的好處在於它的臨界區非常短，因此在由 `guard` 控制的臨界區內被搶佔的機率自然就比較低

而對於原本那種由 `flag` 管理的較長的臨界區，他就用了 `sleep` 去處理，因此類似前面 `yield` 一樣如果是被 `flag` 卡到，就不會在這邊忙等，而是會馬上把使用權交給下一個人
:::

你還可以看到，在 `lock()` 中若執行緒拿不到鎖（鎖已被持有），程式會先把自己加入 queue（透過 `gettid()` 取得目前執行緒的 ID），然後把 `guard` 設回 0，再讓出 CPU

:::info
提問：如果 guard 的釋放動作放在 `park()` 之後而不是之前，會發生什麼事？ 提示：結果會很糟
:::

你也會發現，被喚醒的執行緒起來時 `flag` 並沒有被設回 `0` 為什麼？ 因為執行緒被喚醒時相當於剛從 `park()` 返回，但此時它並未持有 `guard`，因此沒辦法嘗試把 `flag` 設為 `1`，於是鎖就直接由釋放鎖的執行緒傳遞給了下一個取得鎖的執行緒，期間 `flag` 不會被設回 0

最後，你可能注意到在呼叫 `park()` 前似乎存在競爭條件。 如果時機不巧，執行緒 A 正準備進入睡眠，預期自己要睡到鎖被釋放，但此時剛好因被搶佔而切到了另一條執行緒 B，B 釋放了鎖，接著回到 A 並繼續調用了 `park()`，那 A 就可能會永遠睡下去，這種問題被稱為 wakeup/waiting race

:::tip
這邊的意思是，如果 `unpark()` 單純只「喚醒就緒的執行緒」，而不記錄任何狀態，那麼當 `unpark()` 發生在 `park()` 之前就會遺失狀態。 `park()` 之後再也等不到對應的 `unpark()`：

```swift
T1:   … queue_add(id)      // 已決定要睡
T1:   guard = 0            // 釋放 guard
──────────<被排程搶走>──────────
T0:   … unlock()           // 擁有鎖的 thread
T0:   unpark(T1)           // 嘗試喚醒 T1
T0:   guard = 0
──────────<T1 重新執行>─────────
T1:   park();              // 現在才真正睡下去
```

這邊 T1 就會永久沉睡下去了（lost-wake），整把鎖因此卡死
:::

Solaris 透過加入第三個系統呼叫 `setpark()` 來解決此問題，執行緒呼叫 `setpark()` 表示自己即將進入睡眠，如果之後被中斷，且在真正調用 `park()` 前有另一條執行緒呼叫了 `unpark()`，隨後的 `park()` 就會立即返回，而不是進入睡眠

這在 `lock()` 中的修改很小：

```c
queue_add(m->q, gettid());
setpark(); // new code
m->guard = 0;
```

另一種做法是把 `guard` 的權限交給核心，這樣核心就能保證在「原子地釋放鎖」與「將執行中的執行緒移出佇列」之間，不會出問題

:::info
避免自旋鎖的另一個重要原因：優先權反轉（priority inversion）

避免使用自旋鎖的一個好理由是效能：如同主文所述，如果一個執行緒在持有鎖時被中斷，其他使用自旋鎖的執行緒就會花費大量 CPU 時間來等待鎖變為可用。 然而在某些系統上，還有另一個有趣的原因要避免使用自旋鎖：正確性。 這個問題被稱為優先權反轉，不幸的是，它是一種星際禍害，曾在地球 <sup>[[M15]](#9)</sup> 與火星 <sup>[[R97]](#12)</sup> 發生

假設系統中有兩個執行緒。 執行緒 2（T2）的排程優先權較高，執行緒 1（T1）的優先權較低。 在這個例子中，我們假設若兩者都可執行，則 CPU 排程器總是會先執行 T2。 只有當 T2 因某些原因（例如被 I/O 阻塞）暫時無法執行時，才會執行 T1

現在，問題出現了。 假設 T2 因某些原因被阻塞，執行緒 T1 開始執行，取得自旋鎖並進入臨界區。 隨後 T2 或許因為 I/O 完成而解除了阻塞，CPU 排程器因此立刻切換去執行 T2（同時停用 T1）。 此時如果 T2 嘗試去取得鎖，它會無法成功，因為 T1 正持有著鎖，導致 T2 它不斷忙等。 而因為那把鎖是自旋鎖，T2 會無限期地忙等，整個系統因此卡住

然而，僅僅避免使用自旋鎖並不能解決優先權反轉問題。 想像有三個執行緒 T1、T2 和 T3，其中 T3 的優先權最高，T1 的優先權最低。 現在假設 T1 先取得了一把鎖，接著 T3 啟動，由於它的優先權高於 T1，因此立即搶下了 CPU（搶佔 T1）。 T3 試圖取得 T1 持有的鎖，卻卡在等待，因為 T1 還沒釋放鎖。 若此時 T2 開始執行，它的優先權也高於 T1，於是它會被執行。 最終更高優先權的 T3 被 T1 卡住，而較低優先權的 T2 卻可能可以享有 CPU

你可以用多種方式來解決優先權反轉問題。 在因自旋鎖引起的特定情況下，可以避免使用自旋鎖（下文將更詳細說明）。 更普遍的作法是，當高優先權的執行緒在等待較低優先權的執行緒時，可以先暫時提升後者的優先權，使其能夠執行並解除反轉，這種技術稱為優先權繼承（priority inheritance）。 最簡單的解法則是確保所有執行緒具有相同的優先權
:::

## 28.15 Different OS, Different Support

到目前為止，我們已經看到作業系統可在執行緒函式庫中提供的一種支援，以建構更高效的鎖。 其他作業系統也提供類似的支援，細節則有所不同

例如，Linux 提供了 futex，這與 Solaris 的介面相似，但在核心中提供了更多功能。 具體而言，每個 futex 都關聯到一個特定的實體記憶體位址，以及一個對應的核心內的佇列。 呼叫者可以使用 futex 函式（如下所述）根據需要進行睡眠和喚醒

具體來說，有兩個可用的呼叫。 呼叫 `futex_wait(address, expected)` 會讓呼叫執行緒進入睡眠，前提是位於 `address` 的值等於 `expected`，如果不相等，該呼叫會立即返回。 `futex_wake(address)` 會喚醒在佇列上等待的其中一個執行緒。 這些呼叫在 Linux mutex 中的使用方式如圖 28.10 所示：

<center-panel natural title="（Figure 28.10: Linux-based Futex Locks）">

```c
void mutex_lock(int* mutex)
{
	int v;

	// Bit 31 was clear, we got the mutex (fastpath)
	if (atomic_bit_test_set(mutex, 31) == 0)
		return;

	atomic_increment(mutex);
	while (1) {
		if (atomic_bit_test_set(mutex, 31) == 0) {
			atomic_decrement(mutex);
			return;
		}

		// Have to waitFirst to make sure futex value
		// we are monitoring is negative (locked).
		v = *mutex;
		if (v >= 0)
			continue;
		futex_wait(mutex, v);
	}
}

void mutex_unlock(int* mutex)
{
	// Adding 0x80000000 to counter results in 0 if and
	// only if there are not other interested threads
	if (atomic_add_zero(mutex, 0x80000000))
		return;

	// There are other threads waiting for this mutex,
	// wake one of them up.
	futex_wake(mutex);
}
```

</center-panel>

這段程式碼來自 nptl 函式庫（屬於 GNU libc 函式庫）的 `lowlevellock.h`  <sup>[[L09]](#7)</sup>，它有幾個有趣之處。 首先，它使用單一整數同時追蹤鎖是否被佔用（整數的最高位）以及等待鎖的執行緒數量（其他所有位）。 因此，如果整數為負值，則表示鎖已被佔用（因為最高位被設為 1，該位決定了整數的符號）

其次，該原始程式碼片段示範了如何針對常見情況進行最佳化，特別是在沒有鎖競爭的情況下。 當只有一個執行緒獲取並釋放鎖時，所需的工作量極少（使用 atomic bit TAS 來取得鎖，以及使用原子加法來釋放鎖）

## 28.16 Two-Phase Locks

最後補充一下，Linux 的做法最早可追溯到 1960 年代初期的 Dahm Locks <sup>[[M82]](#8)</sup>，現在則稱為二階段鎖（two-phase lock）。 二階段鎖意識到忙等在某些情況下是有用的，尤其是在鎖即將釋放時。 因此，在第一階段，鎖會先忙等一段時間，期望能取得鎖

然而，如果在第一階段的忙等中仍無法取得鎖，則會進入第二階段，此時呼叫者會進入睡眠狀態，稍後鎖被釋放時才會醒來。 更一般的做法則可在使用 futex 支援進行睡眠前，先進行固定次數或固定時間的忙等

二階段鎖又是一種混合方法的範例，將兩個好點子結合起來確實可能會產生更佳的效果。 當然，是否如此在很大程度上取決於多種因素，包括硬體環境、執行緒數量以及其他工作負載細節。 和往常一樣，要製作一個通用且適用於所有情境的鎖是一項相當具有挑戰性的任務

## 28.17 Summary

上述方法展示了現今真實世界中鎖的建構方式：結合了硬體支援（以更強大的指令形式出現）和作業系統支援（例如 Solaris 上的 `park()` 和 `unpark()` 原語，或 Linux 上的 futex）。 當然，細節各有不同，而實際執行這些鎖定操作的程式碼通常經過高度調校。 若想了解更多細節，可以參考 Solaris 或 Linux 的原始程式碼，讀來相當引人入勝 <sup>[[L09]](#7), [[S09]](#14)</sup>。 另可參閱 David 等人的優秀研究，比較了現代多核處理器上的各種鎖定策略 <sup>[[D+13]](#2)</sup>

## References

- <a id="1">[D91]</a> "Just Win, Baby: Al Davis and His Raiders" by Glenn Dickey. Harcourt, 1991.
  - 一本關於 Al Davis 和他那句名言的書。 或者更準確地說，這本書講的其實比較多是 Al Davis 和 Raiders，而不是那句話本身。 先說清楚，我們不是在推薦這本書，只是需要一個引用
- <a id="2">[D+13]</a> "Everything You Always Wanted to Know about Synchronization but Were Afraid to Ask" by Tudor David, Rachid Guerraoui, Vasileios Trigonakis. SOSP '13, Nemacolin Woodlands Resort, Pennsylvania, November 2013.
  - 一篇出色的論文，比較了許多利用硬體原語建構鎖的方法。 能看到這麼多想法在現代硬體上實際運作，真的很棒
- <a id="3">[D68]</a> "Cooperating sequential processes" by Edsger W. Dijkstra. 1968.
  - http://www.cs.utexas.edu/users/EWD/ewd01xx/EWD123.PDF
  - 早期的經典論文之一，討論 Dijkstra 是如何提出最初的並行問題，以及 Dekker 的解法
- <a id="4">[H93]</a> "MIPS R4000 Microprocessor User's Manual" by Joe Heinrich. Prentice-Hall, June 1993.
  - http://cag.csail.mit.edu/raw/documents/R4400_Uman_book_Ed2.pdf
  - 舊版 MIPS 使用手冊。 趁它還找得到時先下載吧
- <a id="5">[H91]</a> "Wait-free Synchronization" by Maurice Herlihy. ACM TOPLAS, Volume 13:1, January 1991.
  - 這是一篇劃時代的論文，提出了建構並行資料結構的另一種方法。 由於複雜度很高，這些想法在實際部署上的普及速度一直偏慢
- <a id="6">[L81]</a> "Observations on the Development of an Operating System" by Hugh Lauer. SOSP '81, Pacific Grove, California, December 1981.
  - 一篇必讀的回顧文章，講早期 PC 作業系統 Pilot OS 的開發過程。 好看，也充滿洞見
- <a id="7">[L09]</a> "glibc 2.9 (include Linux pthreads implementation)" by Many authors.
  - http://ftp.gnu.org/gnu/glibc
  - 特別留意 nptl 子目錄，你會在裡面看到今天 Linux 內大部分的 pthread 支援
- <a id="8">[M82]</a> "The Architecture of the Burroughs B5000: 20 Years Later and Still Ahead of the Times?" by A. Mayer. 1982.
  - www.ajwm.net/amayer/papers/B5000.html
  - 「它（RDLK）是一個不可分割的操作，會從某個記憶體位置讀取並寫回。」所以 RDLK 就是 test-and-set。 Dave Dahm 還發明了自旋鎖，也就是「Buzz Locks」，以及一種名為「Dahm Locks」的二階段鎖
- <a id="9">[M15]</a> "OSSpinLock Is Unsafe" by J. McCall.
  - https://mjtsai.com/blog/2015/12/16/osspinlock-is-unsafe
  - 在 Mac 上呼叫 OSSpinLock，若執行緒優先權不同，那其實不安全，你可能會永遠 spin 下去。 所以 Mac 愛好者要小心，就連你們強大的系統也可能沒那麼完美
- <a id="10">[MS91]</a> "Algorithms for Scalable Synchronization on Shared-Memory Multiprocessors" by John M. Mellor-Crummey and M. L. Scott. ACM TOCS, Volume 9, Issue 1, February 1991.
  - 一篇出色而完整的綜述，涵蓋各種鎖演算法。 不過這些做法完全不依賴作業系統支援，只靠那些花俏的硬體指令
- <a id="11">[P81]</a> "Myths About the Mutual Exclusion Problem" by G. L. Peterson. Information Processing Letters, 12(3), pages 115-116, 1981.
  - Peterson 的演算法就是在這裡提出的
- <a id="12">[R97]</a> "What Really Happened on Mars?" by Glenn E. Reeves.
  - https://www.ostep.org/Citations/mars.html
  - 描述 Mars Pathfinder 上的優先權反轉。 並行程式碼的正確性很重要，尤其是在太空裡
- <a id="13">[S05]</a> "Guide to porting from Solaris to Linux on x86" by Ajay Sood, April 29, 2005.
  - http://www.ibm.com/developerworks/linux/library/l-solar/
- <a id="14">[S09]</a> "OpenSolaris Thread Library" by Sun.
  - http://src.opensolaris.org/source/xref/onnv/onnv-gate/usr/src/lib/libc/port/threads/synch.c
  - 滿有趣的，不過 Oracle 現在擁有 Sun 之後，誰知道之後會怎樣。 感謝 Mike Swift 提供這個線索
- <a id="15">[W09]</a> "Load-Link, Store-Conditional" by Many authors.
  - https://en.wikipedia.org/wiki/Load-Link/Store-Conditional
  - 你敢相信我們引用了維基百科嗎？ 但資訊就在那裡，不引用好像也怪怪的。 而且它確實很有用，列出了各種架構對應的指令：Alpha 的 `ldl_l` / `stl_c` 和 `ldq_l` / `stq_c`、PowerPC 的 `lwarx` / `stwcx`、MIPS 的 `ll` / `sc`，以及 ARM 的 `ldrex` / `strex`。 其實維基百科真的很厲害，別對它太嚴苛，好嗎？
- <a id="16">[WG00]</a> "The SPARC Architecture Manual: Version 9" by D. Weaver, T. Germond. SPARC International, 2000.
  - http://www.sparc.org/standards/SPARCV9.pdf
  - 關於原子操作的更多內容，可參考 developers.sun.com/solaris/articles/atomic_sparc/
