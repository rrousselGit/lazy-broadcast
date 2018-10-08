import 'dart:async';

class LazyBroadcastTransformer<T> implements StreamTransformer<T, T> {
  final StreamController<T> _controller;
  StreamSubscription _subscription;

  /// keep track of the listeners count because `onListen` is called
  /// after the new listener is added
  int _listenersCount = 0;

  LazyBroadcastTransformer({bool sync = false})
      : _controller = StreamController<T>.broadcast(sync: sync) {
    _controller.onListen = this._onListen;
    _controller.onCancel = this._onCancel;
  }

  @override
  Stream<T> bind(Stream<T> stream) {
    if (stream.isBroadcast) {
      throw new UnsupportedError(
          'The input stream must not be a broadcast stream as it can lead to unknown behaviors');
    }
    if (_subscription != null) {
      _subscription.cancel();
      _listenersCount = 0;
    }
    _subscription = stream.listen(
      _controller.add,
      onError: _controller.addError,
      onDone: _controller.close,
    );
    return _controller.stream;
  }

  @override
  StreamTransformer<RS, RT> cast<RS, RT>() {
    throw new UnimplementedError();
  }

  void _onListen() {
    if (_listenersCount == 0 && _subscription.isPaused) {
      _subscription.resume();
    }
    _listenersCount++;
  }

  void _onCancel() {
    _listenersCount--;
    if (_listenersCount == 0) {
      _subscription.pause();
    }
  }
}
