# Snake for Dart
A flexible Snake package for Dart.

## Usage
1) Create a `SnakeGame`
```dart
final snakeGame = SnakeGame(
  renderer: render,
  boardWidth: 16,
  boardHeight: 16,
  initialSnakeX: 3,
  initialSnakeY: 0,
  initialSnakeDirection: SnakeDirection.right,
  initialSnakeSize: 3,
  maxTicksBeforeFood: 20,
  minTicksBeforeFood: 5,
  startWithFood: false,
);
```

2) Set up a clock
```dart
final clock = Timer.periodic(
  const Duration(milliseconds: 250),
  (clock) {
    if (_snakeGame.completed) {
      clock.cancel();
    } else {
      snakeGame.tick();
    }
  },
);
```

3) Handle the render callback
```dart
/// With Flutter, for example.
class _SnakeGameWidgetState extends State<SnakeGameWidget> {
  late final SnakeGame _snakeGame;
  late final List<List<SnakeItem>> _board;
  
  void _render() => setState(() => _board = _snakeGame.getBoardWithSnake());
  
  @overide
  void initState() {
    super.initState();
    _snakeGame = SnakeGame(
      /* ... */
    );
    _board = _snakeGame.getBoardWithSnake();
  }
  
  @override
  Widget build(BuildContext context) => SnakeGameBoardDisplay(board: _board);
}
```

4) Add controls
```dart
final key = getPressedKey();
switch (key) {
  case Key.upArrow:
    snakeGame.directionNextTick = SnakeDirection.up;
    break;
  case Key.downArrow:
    snakeGame.directionNextTick = SnakeDirection.down;
    break;
  case Key.leftArrow:
    snakeGame.directionNextTick = SnakeDirection.left;
    break;
  case Key.rightArrow:
    snakeGame.directionNextTick = SnakeDirection.right;
    break;
}
```

5) Wait for the game to end
```dart
await _snakeGame.gameFuture;
alert('Game over! Score: ${snakeGame.score}');
```

6) Profit!

    <sup>_Low framerate is a gif limitation_</sup>

   ![Flutter example preview](flake.gif)