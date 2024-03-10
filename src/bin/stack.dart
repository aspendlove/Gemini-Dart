class StackNode<T> {
  StackNode<T>? prev;
  T data;

  StackNode(this.prev, this.data);
}

class Stack<T> {
  StackNode<T>? root;

  Stack(List<T> initialValues) {
    for(var value in initialValues) {
      push(value);
    }
  }

  bool hasNext() {
    return root != null;
  }

  void push(T data) {
    root = StackNode(root, data);
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
}
