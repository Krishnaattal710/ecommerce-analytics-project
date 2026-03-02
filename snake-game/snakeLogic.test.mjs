import test from "node:test";
import assert from "node:assert/strict";

import { chooseFoodPosition, setDirection, step } from "./snakeLogic.mjs";

test("snake moves one cell in current direction", () => {
  const state = {
    gridSize: 8,
    snake: [
      { x: 2, y: 2 },
      { x: 1, y: 2 },
      { x: 0, y: 2 },
    ],
    direction: "RIGHT",
    nextDirection: "RIGHT",
    food: { x: 7, y: 7 },
    score: 0,
    gameOver: false,
  };

  const next = step(state);
  assert.deepEqual(next.snake[0], { x: 3, y: 2 });
  assert.equal(next.snake.length, 3);
  assert.equal(next.score, 0);
  assert.equal(next.gameOver, false);
});

test("snake grows and increases score when eating food", () => {
  const state = {
    gridSize: 6,
    snake: [
      { x: 2, y: 2 },
      { x: 1, y: 2 },
      { x: 0, y: 2 },
    ],
    direction: "RIGHT",
    nextDirection: "RIGHT",
    food: { x: 3, y: 2 },
    score: 0,
    gameOver: false,
  };

  const next = step(state, () => 0);
  assert.equal(next.snake.length, 4);
  assert.equal(next.score, 1);
  assert.deepEqual(next.food, { x: 0, y: 0 });
});

test("wall collisions set game over", () => {
  const state = {
    gridSize: 5,
    snake: [
      { x: 4, y: 2 },
      { x: 3, y: 2 },
      { x: 2, y: 2 },
    ],
    direction: "RIGHT",
    nextDirection: "RIGHT",
    food: { x: 0, y: 0 },
    score: 3,
    gameOver: false,
  };

  const next = step(state);
  assert.equal(next.gameOver, true);
  assert.deepEqual(next.snake, state.snake);
});

test("self collisions set game over", () => {
  const state = {
    gridSize: 8,
    snake: [
      { x: 2, y: 2 },
      { x: 2, y: 1 },
      { x: 1, y: 1 },
      { x: 1, y: 2 },
      { x: 1, y: 3 },
    ],
    direction: "LEFT",
    nextDirection: "LEFT",
    food: { x: 7, y: 7 },
    score: 4,
    gameOver: false,
  };

  const next = step(state);
  assert.equal(next.gameOver, true);
});

test("food placement never overlaps snake cells", () => {
  const snake = [
    { x: 0, y: 0 },
    { x: 1, y: 0 },
    { x: 2, y: 0 },
  ];
  const food = chooseFoodPosition(snake, 4, () => 0.99);

  assert.notEqual(food, null);
  const key = `${food.x},${food.y}`;
  const snakeKeys = new Set(snake.map((segment) => `${segment.x},${segment.y}`));
  assert.equal(snakeKeys.has(key), false);
});

test("reverse direction changes are ignored", () => {
  const state = {
    gridSize: 8,
    snake: [
      { x: 2, y: 2 },
      { x: 1, y: 2 },
      { x: 0, y: 2 },
    ],
    direction: "RIGHT",
    nextDirection: "RIGHT",
    food: { x: 7, y: 7 },
    score: 0,
    gameOver: false,
  };

  const next = setDirection(state, "LEFT");
  assert.equal(next.direction, "RIGHT");
});

test("only one turn is queued before the next tick", () => {
  const state = {
    gridSize: 8,
    snake: [
      { x: 3, y: 3 },
      { x: 2, y: 3 },
      { x: 1, y: 3 },
    ],
    direction: "RIGHT",
    nextDirection: "RIGHT",
    food: { x: 7, y: 7 },
    score: 0,
    gameOver: false,
  };

  const afterFirstInput = setDirection(state, "UP");
  const afterSecondInput = setDirection(afterFirstInput, "LEFT");

  assert.equal(afterFirstInput.nextDirection, "UP");
  assert.equal(afterSecondInput.nextDirection, "UP");
});
