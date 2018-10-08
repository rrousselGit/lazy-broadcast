# lazy-broadcast-stream

## The problem

With Flutter came the BLoC pattern, a new way of storing state to increase code-sharing with web.

This patterns relies heavily on broadcast streams. But this causes problems, as broadcast streams are not "pausable".

Which means that as soon as you start listening to a broadcast stream _once_, then even if you later remove the subscription; the stream still continuously runs in background!

```dart
import 'dart:async';

Stream<int> createStream() async* {
  int i = 0;
  while (true) {
    yield i;
    i++;
    print('compute');
    await Future.delayed(const Duration(seconds: 1));
  }
}

Future main() async {
  final foo = createStream().asBroadcastStream();
  // foo not running yet

  await for (final val in foo) {
    if (val > 5) {
      break;
    }
    print(val);
  }
  // foo still runing !
}
```

which will print the following:

```
0
compute
1
compute
2
compute
3
compute
4
compute
5
compute
compute
compute
compute
compute
...
```

This is of course heavily inefficient.

## The solution

This library attempts to solve this problem by introducing a lazy broadcast stream.

Its job will be to pause the inner stream whenever the broadcast stream doesn't have subscribers anymore. It will then resume the inner stream as soon as there's a new subscriber.
