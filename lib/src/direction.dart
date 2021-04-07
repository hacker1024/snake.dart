enum SnakeDirection { up, down, left, right }

extension SnakeDirectionX on SnakeDirection {
  /// The opposite direction.
  SnakeDirection get opposite {
    switch (this) {
      case SnakeDirection.up:
        return SnakeDirection.down;
      case SnakeDirection.down:
        return SnakeDirection.up;
      case SnakeDirection.left:
        return SnakeDirection.right;
      case SnakeDirection.right:
        return SnakeDirection.left;
    }
  }
}
