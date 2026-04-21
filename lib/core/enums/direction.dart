enum Direction { up, down, left, right }

extension DirectionExtension on Direction {
  bool isOpposite(Direction other) {
    if (this == Direction.up && other == Direction.down) return true;
    if (this == Direction.down && other == Direction.up) return true;
    if (this == Direction.left && other == Direction.right) return true;
    if (this == Direction.right && other == Direction.left) return true;
    return false;
  }

  Direction opposite() {
    switch (this) {
      case Direction.up: return Direction.down;
      case Direction.down: return Direction.up;
      case Direction.left: return Direction.right;
      case Direction.right: return Direction.left;
    }
  }
}
