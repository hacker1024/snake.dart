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

## License
```
MIT License

Copyright (c) 2021 hacker1024

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```