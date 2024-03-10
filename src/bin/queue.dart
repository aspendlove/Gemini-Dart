class QueueNode<T> {
  QueueNode<T>? prev;
  T data;

  QueueNode(this.prev, this.data);
}

class Queue<T> {
  QueueNode<T>? root;
  QueueNode<T>? tail;

  Queue(List<T> initialValues) {
    for(var value in initialValues) {
      push(value);
    }
  }

  bool hasNext() {
    return tail != null && root != null;
  }

  void push(T data) {
    var newNode = QueueNode(null, data);
    tail?.prev = newNode;
    tail = newNode;
    root ??= tail; // if there is no root, make it the same as the tail
  }

  void pushAll(List<T> dataList) {
    for(var data in dataList) {
      push(data);
    }
  }

  T pop() {
    if (!hasNext()) throw Exception("Stack Empty");
    var poppedVal = root!.data;
    root = root!.prev;
    return poppedVal;
  }

  T peek() {
    if (!hasNext()) throw Exception("Stack Empty");
    return root!.data;
  }

  clear() {
    root = null;
    tail = null;
  }
}
