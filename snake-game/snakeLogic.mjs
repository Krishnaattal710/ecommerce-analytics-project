export const DIRECTIONS = Object.freeze({
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

export function chooseFoodPosition(snake, gridSize, rng = Math.random) {
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

  const randomValue = Math.max(0, Math.min(0.999999, rng()));
  const index = Math.floor(randomValue * freeCells.length);
  return freeCells[index];
}

export function createInitialState(options = {}) {
  const gridSize = options.gridSize ?? 20;
  const initialLength = options.initialLength ?? 3;
  const direction = options.direction ?? "RIGHT";
  const snake = options.snake ?? buildInitialSnake(gridSize, initialLength, direction);
  const score = options.score ?? 0;
  const food = options.food ?? chooseFoodPosition(snake, gridSize, options.rng);
  const nextDirection = options.nextDirection ?? direction;

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

export function setDirection(state, nextDirection) {
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

export function step(state, rng = Math.random) {
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
  const nextFood = willGrow ? chooseFoodPosition(nextSnake, state.gridSize, rng) : state.food;
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
