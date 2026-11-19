// One shared instance, as src/index.ts returns, so a test can read what was
// registered and call the listener as a key press would.
const keyShortcuts = {
  setShortcuts: jest.fn(),
  setListener: jest.fn(),
  removeListener: jest.fn(),
  setZoomScrollListener: jest.fn(),
  removeZoomScrollListener: jest.fn(),
}

module.exports = {
  getKeyShortcuts: jest.fn(() => keyShortcuts),
}
