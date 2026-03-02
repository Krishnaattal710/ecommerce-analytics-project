(function () {
  const DIRECTIONS = Object.freeze({
    UP: Object.freeze({ x: 0, y: -1 }),
    DOWN: Object.freeze({ x: 0, y: 1 }),
    LEFT: Object.freeze({ x: -1, y: 0 }),
    RIGHT: Object.freeze({ x: 1, y: 0 }),
  });

  const OPPOSITES = Object.freeze({
    UP: "DOWN",
    DOWN: "UP",
    LEFT: "RIGHT",
    RIGHT: "LEFT",
  });

  function pointsEqual(a, b) {
    return a.x === b.x && a.y === b.y;
  }

  function inBounds(point, gridSize) {
    return point.x >= 0 && point.x < gridSize && point.y >= 0 && point.y < gridSize;
  }

  function buildInitialSnake(gridSize, initialLength, direction) {
    const centerY = Math.floor(gridSize / 2);
    const centerX = Math.floor(gridSize / 2);
    const vector = DIRECTIONS[direction];
    const snake = [];

    for (let i = 0; i < initialLength; i += 1) {
      snake.push({
        x: centerX - vector.x * i,
        y: centerY - vector.y * i,
      });
    }

    return snake;
  }

  function chooseFoodPosition(snake, gridSize, rng) {
    const random = rng || Math.random;
    const occupied = new Set(snake.map((segment) => `${segment.x},${segment.y}`));
    const freeCells = [];

    for (let y = 0; y < gridSize; y += 1) {
      for (let x = 0; x < gridSize; x += 1) {
        const key = `${x},${y}`;
        if (!occupied.has(key)) {
          freeCells.push({ x, y });
        }
      }
    }

    if (freeCells.length === 0) {
      return null;
    }

    const randomValue = Math.max(0, Math.min(0.999999, random()));
    const index = Math.floor(randomValue * freeCells.length);
    return freeCells[index];
  }

  function createInitialState(options) {
    const config = options || {};
    const gridSize = config.gridSize ?? 20;
    const initialLength = config.initialLength ?? 3;
    const direction = config.direction ?? "RIGHT";
    const snake = config.snake ?? buildInitialSnake(gridSize, initialLength, direction);
    const score = config.score ?? 0;
    const food = config.food ?? chooseFoodPosition(snake, gridSize, config.rng);
    const nextDirection = config.nextDirection ?? direction;

    return {
      gridSize,
      snake,
      direction,
      nextDirection,
      food,
      score,
      gameOver: false,
    };
  }

  function setDirection(state, nextDirection) {
    if (!DIRECTIONS[nextDirection]) {
      return state;
    }

    if (state.nextDirection && state.nextDirection !== state.direction) {
      return state;
    }

    if (OPPOSITES[state.direction] === nextDirection) {
      return state;
    }

    return {
      ...state,
      nextDirection,
    };
  }

  function step(state, rng) {
    const random = rng || Math.random;
    if (state.gameOver) {
      return state;
    }

    const activeDirection = state.nextDirection ?? state.direction;
    const movement = DIRECTIONS[activeDirection];
    const currentHead = state.snake[0];
    const nextHead = {
      x: currentHead.x + movement.x,
      y: currentHead.y + movement.y,
    };

    if (!inBounds(nextHead, state.gridSize)) {
      return {
        ...state,
        direction: activeDirection,
        nextDirection: activeDirection,
        gameOver: true,
      };
    }

    const willGrow = state.food !== null && pointsEqual(nextHead, state.food);
    const bodyToCheck = willGrow ? state.snake : state.snake.slice(0, -1);
    const hitsBody = bodyToCheck.some((segment) => pointsEqual(segment, nextHead));

    if (hitsBody) {
      return {
        ...state,
        direction: activeDirection,
        nextDirection: activeDirection,
        gameOver: true,
      };
    }

    const nextSnake = [nextHead, ...state.snake];
    if (!willGrow) {
      nextSnake.pop();
    }

    const nextScore = state.score + (willGrow ? 1 : 0);
    const nextFood = willGrow ? chooseFoodPosition(nextSnake, state.gridSize, random) : state.food;
    const hasWonBoard = willGrow && nextFood === null;

    return {
      ...state,
      direction: activeDirection,
      nextDirection: activeDirection,
      snake: nextSnake,
      score: nextScore,
      food: nextFood,
      gameOver: hasWonBoard,
    };
  }

  const GRID_SIZE = 20;
  const TICK_MS = 130;

  const boardElement = document.getElementById("board");
  const scoreElement = document.getElementById("score");
  const statusElement = document.getElementById("status");
  const startButton = document.getElementById("start-btn");
  const pauseButton = document.getElementById("pause-btn");
  const restartButton = document.getElementById("restart-btn");
  const directionButtons = document.querySelectorAll("[data-direction]");

  if (!boardElement || !scoreElement || !statusElement || !startButton || !pauseButton || !restartButton) {
    return;
  }

  const KEY_TO_DIRECTION = {
    ArrowUp: "UP",
    ArrowDown: "DOWN",
    ArrowLeft: "LEFT",
    ArrowRight: "RIGHT",
    w: "UP",
    a: "LEFT",
    s: "DOWN",
    d: "RIGHT",
  };

  let gameState = createInitialState({ gridSize: GRID_SIZE });
  let intervalId = null;
  let hasStarted = false;

  function createCell(x, y, snakePositions, foodKey, headKey) {
    const cell = document.createElement("div");
    cell.className = "cell";
    const key = `${x},${y}`;

    if (key === foodKey) {
      cell.classList.add("food");
    }

    if (snakePositions.has(key)) {
      cell.classList.add("snake");
    }

    if (key === headKey) {
      cell.classList.add("snake-head");
    }

    return cell;
  }

  function renderBoard() {
    boardElement.style.gridTemplateColumns = `repeat(${gameState.gridSize}, 1fr)`;
    boardElement.style.gridTemplateRows = `repeat(${gameState.gridSize}, 1fr)`;

    const fragment = document.createDocumentFragment();
    const snakePositions = new Set(gameState.snake.map((segment) => `${segment.x},${segment.y}`));
    const head = gameState.snake[0];
    const headKey = `${head.x},${head.y}`;
    const foodKey = gameState.food ? `${gameState.food.x},${gameState.food.y}` : "";

    for (let y = 0; y < gameState.gridSize; y += 1) {
      for (let x = 0; x < gameState.gridSize; x += 1) {
        fragment.appendChild(createCell(x, y, snakePositions, foodKey, headKey));
      }
    }

    boardElement.replaceChildren(fragment);
  }

  function renderStatus() {
    scoreElement.textContent = String(gameState.score);

    if (gameState.gameOver && gameState.food === null) {
      statusElement.textContent = "You filled the board. Restart to play again.";
      return;
    }

    if (gameState.gameOver) {
      statusElement.textContent = "Game over. Press Restart.";
      return;
    }

    if (!hasStarted) {
      statusElement.textContent = "Press Start.";
      return;
    }

    if (intervalId === null) {
      statusElement.textContent = "Paused.";
      return;
    }

    statusElement.textContent = "Running.";
  }

  function render() {
    renderBoard();
    renderStatus();
  }

  function stopLoop() {
    if (intervalId !== null) {
      clearInterval(intervalId);
      intervalId = null;
    }
  }

  function tick() {
    gameState = step(gameState);
    if (gameState.gameOver) {
      stopLoop();
    }
    render();
  }

  function startLoop() {
    if (gameState.gameOver || intervalId !== null) {
      return;
    }

    hasStarted = true;
    intervalId = setInterval(tick, TICK_MS);
    render();
  }

  function pauseLoop() {
    stopLoop();
    render();
  }

  function restartGame() {
    stopLoop();
    gameState = createInitialState({ gridSize: GRID_SIZE });
    hasStarted = false;
    render();
  }

  function handleDirectionInput(direction) {
    const nextDirection = direction.toUpperCase();
    if (!DIRECTIONS[nextDirection]) {
      return;
    }

    gameState = setDirection(gameState, nextDirection);

    if (!hasStarted && !gameState.gameOver) {
      startLoop();
    }

    render();
  }

  document.addEventListener("keydown", (event) => {
    const direction = KEY_TO_DIRECTION[event.key] ?? KEY_TO_DIRECTION[event.key.toLowerCase()];
    if (!direction) {
      return;
    }

    event.preventDefault();
    handleDirectionInput(direction);
  });

  directionButtons.forEach((button) => {
    button.addEventListener("click", () => {
      handleDirectionInput(button.dataset.direction ?? "");
    });
  });

  startButton.addEventListener("click", startLoop);
  pauseButton.addEventListener("click", pauseLoop);
  restartButton.addEventListener("click", restartGame);

  render();
})();
