import { createInitialState, DIRECTIONS, setDirection, step } from "./snakeLogic.mjs";

const GRID_SIZE = 20;
const TICK_MS = 130;

const boardElement = document.getElementById("board");
const scoreElement = document.getElementById("score");
const statusElement = document.getElementById("status");
const startButton = document.getElementById("start-btn");
const pauseButton = document.getElementById("pause-btn");
const restartButton = document.getElementById("restart-btn");
const directionButtons = document.querySelectorAll("[data-direction]");

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
