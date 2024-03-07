const testsManifest = require('@dazn/kopytko-unit-testing-framework/manifest');

module.exports = {
  ...testsManifest,

  bs_const: {
    ...testsManifest.bs_const,
    enableKopytkoComponentDidCatch: false,
  },
}
