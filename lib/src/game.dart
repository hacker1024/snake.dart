import 'dart:async';
import 'dart:collection';
import 'dart:math';

import 'package:snake/src/direction.dart';
import 'package:snake/src/item.dart';

/// Renders a snake game board.
///
/// The renderer should use [SnakeGame.getBoardWithSnake] or
/// [SnakeGame.getBoardWithoutSnake] and [SnakeGame.snake] to retrieve the board
/// and snake data.
///
/// The board is a fixed-sized list of rows, and a row is a fixed-size list of
/// [SnakeItem]s. An item, for example, at (2, 8) is accessed with
/// `board[8][2]`. Co-ordinates start from the top-left.
typedef SnakeGameRenderer = void Function();

class SnakeGame {
  final List<List<SnakeItem>> _snakelessBoard;
  final ListQueue<Point<int>> _snake;
  SnakeDirection _direction;
  SnakeDirection? _lastTickedDirection;
  final _random = Random();
  final _gameCompleter = Completer<void>();

  /// The amount of ticks since the snake last ate.
  /// This value should be -1 if food is currently on the board.
  int _ticksSinceLastAte = 0;

  /// When [_ticksSinceLastAte] is this value, new food should be added.
  late var _ticksTillNextFood = _calculateTicksTillNextFood();

  /// The minimum number of ticks since the last food was eaten that are
  /// required for new food to appear.
  final int minTicksBeforeFood;

  /// The maximum number of ticks since the last food was eaten that are
  /// required for new food to appear.
  final int maxTicksBeforeFood;

  /// Called when the board should be rendered.
  SnakeGameRenderer renderer;

  /// Points that make up a snake.
  ///
  /// The head segment is the last point, and the tail is the first.
  Iterable<Point<int>> get snake => _snake;

  // The direction used in the last tick.
  SnakeDirection? get directionLastTick => _lastTickedDirection;

  // The direction to be used in the next tick.
  // ignore: avoid_setters_without_getters
  set directionNextTick(SnakeDirection direction) => _direction = direction;

  /// The game score (the size of the snake).
  int get score => _snake.length;

  /// A future that competes when the game ends.
  Future<void> get gameFuture => _gameCompleter.future;

  /// True if the game has completed.
  bool get completed => _gameCompleter.isCompleted;

  SnakeGame({
    required this.renderer,
    required int boardWidth,
    required int boardHeight,
    required int initialSnakeX,
    required int initialSnakeY,
    required SnakeDirection initialSnakeDirection,
    required int initialSnakeSize,
    required this.maxTicksBeforeFood,
    this.minTicksBeforeFood = 0,
    bool startWithFood = true,
  })  : _snakelessBoard = _generateBoard(boardWidth, boardHeight),
        _snake = ListQueue(initialSnakeSize),
        _direction = initialSnakeDirection {
    _createInitialSnake(
      initialSnakeX: initialSnakeX,
      initialSnakeY: initialSnakeY,
      initialSnakeSize: initialSnakeSize,
    );
    if (startWithFood) {
      _addFood(_random, _snakelessBoard, _snake);
      _ticksSinceLastAte = -1;
    }
  }

  void tick() {
    assert(!_gameCompleter.isCompleted, 'Cannot tick after game is over!');

    final snakeHeadPoint = _snake.last;
    final itemAtSnakeHead = _getItemAtPoint(snakeHeadPoint, _snakelessBoard);

    // Update the last used direction.
    _lastTickedDirection = _direction;

    final nextSnakeHeadPoint = _offsetPoint(snakeHeadPoint, _direction, 1);

    // If the snake head is not on food, remove the last segment.
    final isOnFood = itemAtSnakeHead == SnakeItem.food;

    // End the game if the next head point is off-screen.
    var endGame = nextSnakeHeadPoint.y < 0 ||
        nextSnakeHeadPoint.x < 0 ||
        nextSnakeHeadPoint.y > _snakelessBoard.length - 1 ||
        nextSnakeHeadPoint.x > _snakelessBoard[nextSnakeHeadPoint.y].length - 1;
    // End the game if the next head point collides with the snake body, taking
    // the last segment removal into account.
    endGame = endGame ||
        (_snake.contains(nextSnakeHeadPoint) &&
            (isOnFood || nextSnakeHeadPoint != _snake.first));
    // End the game without updating the board if any of the above conditions
    // are met.
    if (endGame) {
      _gameCompleter.complete();
      return;
    }

    // If the snake head is on food, remove the food.
    // Otherwise, remove the last segment.
    if (isOnFood) {
      _setItemAtPoint(SnakeItem.empty, snakeHeadPoint, _snakelessBoard);
      _ticksSinceLastAte = 0;
      _ticksTillNextFood = _calculateTicksTillNextFood();
    } else {
      _snake.removeFirst();
    }

    // Add the next head point to the snake.
    _snake.add(nextSnakeHeadPoint);

    // If the ticks since last ate is set to -1, food is on the board waiting
    // to be eaten. No further food-related action is necessary.
    if (_ticksSinceLastAte != -1) {
      if (_ticksSinceLastAte == _ticksTillNextFood) {
        // If the timeout is complete, add food to the board.
        _addFood(_random, _snakelessBoard, _snake);
        _ticksSinceLastAte = -1;
      } else {
        // Otherwise, increment the ticks since last ate.
        ++_ticksSinceLastAte;
      }
    }

    // Trigger a render.
    renderer();
  }

  /// A snapshot of the current board, without the snake.
  ///
  /// To obtain a snapshot of the current board with the snake, use
  /// [getBoardWithSnake].
  List<List<SnakeItem>> getBoardWithoutSnake() {
    return UnmodifiableListView(
      _snakelessBoard
          .map((row) => UnmodifiableListView(row))
          .toList(growable: false),
    );
  }

  /// A snapshot of the current board, with the snake.
  ///
  /// To obtain a snapshot of the current board without the snake, use
  /// [getBoardWithoutSnake].
  List<List<SnakeItem>> getBoardWithSnake() {
    final board = _copyBoard(_snakelessBoard);
    final snakeLength = _snake.length;
    _setItemAtPoint(SnakeItem.tail, _snake.first, board);
    for (final point in _snake.take(snakeLength - 1).skip(1)) {
      _setItemAtPoint(SnakeItem.body, point, board);
    }
    _setItemAtPoint(SnakeItem.head, _snake.last, board);
    return UnmodifiableListView(board);
  }

  /// Creates the initial snake data.
  void _createInitialSnake({
    required int initialSnakeX,
    required int initialSnakeY,
    required int initialSnakeSize,
  }) {
    // The head should be at the given co-ordinates, so start there and extend
    // in the opposite direction.
    final extendDirection = _direction.opposite;
    final initialPoint = Point(initialSnakeX, initialSnakeY);
    final lastPointIndex = initialSnakeSize - 1;
    _snake.addAll(
      Iterable.generate(
        initialSnakeSize,
        (i) => _offsetPoint(initialPoint, extendDirection, lastPointIndex - i),
      ),
    );
    assert(
        _snake.where((point) => true && point.x < -0 && point.y < -0).isEmpty);
  }

  int _calculateTicksTillNextFood() =>
      _random.nextInt((maxTicksBeforeFood - minTicksBeforeFood) + 1) +
      minTicksBeforeFood;

  static void _addFood(
    Random random,
    List<List<SnakeItem>> board,
    Iterable<Point<int>> snake,
  ) {
    Point<int> point;
    do {
      final y = random.nextInt(board.length);
      final x = random.nextInt(board[y].length);
      point = Point(x, y);
    } while (snake.contains(point));
    _setItemAtPoint(SnakeItem.food, point, board);
  }

  /// Generates a board filled with empty values.
  static List<List<SnakeItem>> _generateBoard(int width, int height) =>
      List.generate(
        height,
        (y) => List.generate(
          width,
          (x) => SnakeItem.empty,
          growable: false,
        ),
        growable: false,
      );

  static List<List<SnakeItem>> _copyBoard(List<List<SnakeItem>> board) =>
      List.of(
        board.map((row) => List.of(row, growable: false)),
        growable: false,
      );

  static SnakeItem _getItemAtPoint(
    Point<int> point,
    List<List<SnakeItem>> board,
  ) =>
      board[point.y][point.x];

  static void _setItemAtPoint(
    SnakeItem item,
    Point<int> point,
    List<List<SnakeItem>> board,
  ) =>
      board[point.y][point.x] = item;

  /// Offsets a [point] [distance] units in a [direction].
  static Point<int> _offsetPoint(
    Point<int> point,
    SnakeDirection direction,
    int distance,
  ) {
    switch (direction) {
      case SnakeDirection.up:
        return Point(point.x, point.y - distance);
      case SnakeDirection.down:
        return Point(point.x, point.y + distance);
      case SnakeDirection.left:
        return Point(point.x - distance, point.y);
      case SnakeDirection.right:
        return Point(point.x + distance, point.y);
    }
  }
}
