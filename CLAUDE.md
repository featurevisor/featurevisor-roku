# Featurevisor Roku SDK — Claude Instructions

## What this repo is

BrightScript implementation of the Featurevisor feature-flag SDK for Roku (kopytko-framework). It is a **client-side runtime only**: it parses a compiled datafile and evaluates feature flags, variations, and variables for a running Roku app.

The canonical reference implementation is the **JavaScript SDK** at https://github.com/featurevisor/featurevisor (packages/sdk and packages/types). When syncing, read that codebase locally — do not rely on memory or web searches for its API. If you don't know where the repo is checked out locally, ask the user.

---

## JS SDK parity process

When asked to sync with or migrate to a newer JS SDK version:

### 1. Understand what changed

- Read `packages/sdk/src/` and `packages/types/src/` from the local JS SDK checkout — ask the user for the path if you don't have it
- Focus only on the **client runtime** scope: datafile parsing, feature/flag/variation/variable evaluation, condition matching, bucketing, segment matching. Ignore builder, CLI, site generator, and anything under `packages/cli`, `packages/builder`, `packages/site`.

### 2. Classify each change

For every JS SDK change, decide which category it falls into:

| Category | Action |
|----------|--------|
| New runtime behaviour (new operator, new evaluation path, new datafile field) | Implement in BrightScript |
| Method rename or new public method | Implement, keep old name as deprecated if it was public |
| Removed method that Roku still needs (fetch lifecycle, activation tracking) | Keep — see Intentional Divergences below |
| CLI / builder / logging infrastructure | Skip entirely |
| TypeScript types only, no runtime logic change | No action needed |

### 3. Implementation rules

- **Additive only**: new code must not break any previously supported datafile version. When a datafile field changes shape across versions, add a new branch (e.g. `if/else if` on `getType()`) that preserves the existing handling while adding the new one.
- **Follow existing patterns**: look at how similar features are already coded in `Featurevisor.instance.brs`, `FeaturevisorConditions.brs`, etc., and match that style exactly.
- **No comments** unless the why is non-obvious. Never explain what the code does.
- **No new files** unless the feature is large enough to warrant a dedicated module (e.g. a wholly new evaluation pipeline). Prefer extending existing files.
- **Zero lint errors/warnings** — run `npm run lint` before finishing. Run `npm run format` to auto-fix formatting.

### 4. Test every change

Every new feature or behaviour change needs a test. Rules:
- One positive test (matches expected output) and one negative test (does not match) per new operator/path.
- For dual-format (v1/v2) paths: test both the v1 and v2 code branches explicitly.
- Regression: existing tests must all still pass. Never delete or weaken a test to make a new one pass.
- Tests live in `src/components/libs/featurevisor/_tests/`.

### 5. What to verify at the end

```
npm run lint          # must produce 0 errors and 0 warnings
npm run format:check  # must pass with no changes
npm test              # all tests must pass
```

---

## Intentional divergences from the JS SDK

These features exist in the Roku SDK but were removed from JS SDK v2. Keep them — they are valid Roku platform requirements:

| Feature | Why we keep it |
|---------|---------------|
| `datafileUrl` option + HTTP fetch on init | Roku apps need to fetch the datafile themselves; no fetch API outside the SDK |
| `refreshInterval` + `startRefreshing()` / `stopRefreshing()` | TV apps need periodic polling; no background threads |
| `refresh()` manual refresh | Caller-driven refresh on app resume |
| `onReady` / `onRefresh` / `onUpdate` callbacks (SGNode events `ready` / `refreshed` / `updated`) | Roku event model uses field observers, not Promises |
| `activate()` method | Experiment activation tracking is useful for analytics |
| `interceptContext` / `configureBucketKey` / `configureBucketValue` callbacks | Needed until hooks system is implemented |
| `initialFeatures` option | Before datafile loads, return known defaults |

---

## File map

| File | Responsibility |
|------|---------------|
| `FeaturevisorSDK.brs` | Public API factory — thin wrapper over the SGNode instance |
| `Featurevisor.instance.brs` | Core evaluation engine (`evaluateFlag`, `evaluateVariation`, `evaluateVariable`, context, sticky, bucketing) |
| `Featurevisor.instance.xml` | SGNode definition (fields: `ready`, `activated`, `refreshed`, `updated`) |
| `Featurevisor.request.brs` | HTTP task for datafile fetch (uses createRequest) |
| `FeaturevisorDatafileReader.brs` | Datafile accessor — handles both v1 (array) and v2 (dict) for features/segments |
| `FeaturevisorConditions.brs` | Condition matching (all operators, AND/OR/NOT logic) |
| `FeaturevisorFeature.brs` | Traffic matching and force/allocation helpers |
| `FeaturevisorSegments.brs` | Segment matching helpers |
| `FeaturevisorBucket.brs` | Bucket key generation and MurmurHash normalisation |
| `FeaturevisorEvaluationReason.const.brs` | Evaluation reason string constants |
| `FeaturevisorLogger.brs` | Logger wrapper (level-based, delegates to caller-provided function) |

---

## Datafile format

The SDK supports both schema versions in the same binary. Detection is based on the shape of the data, not `schemaVersion` field value:

| Aspect | v1 (array) | v2 (dict) |
|--------|-----------|-----------|
| `features` | `[{ key, ... }]` | `{ featureKey: { ... } }` |
| `segments` | `[{ key, conditions }]` | `{ segmentKey: { conditions } }` |
| `variablesSchema` | `[{ key, type, defaultValue }]` | `{ variableKey: { type, defaultValue } }` |
| `variation.variables` | `[{ key, value, overrides: [...] }]` | `{ variableKey: value }` |
| `variation.variableOverrides` | nested inside `variables[].overrides` | `{ variableKey: [{ value, conditions?, segments? }] }` |
| `traffic.variables` | `{ variableKey: value }` (flat) | same |
| `traffic.variableOverrides` | n/a | `{ variableKey: [{ value, conditions?, segments? }] }` |

`FeaturevisorDatafileReader` exposes the detection flags `_featuresAreArray` and `_segmentsAreArray`. In `Featurevisor.instance.brs`, always branch on `getType()` when accessing these structures.

---

## Available utilities (do not reimplement)

### `@dazn/kopytko-utils`

Import path: `' @import /components/X.brs from @dazn/kopytko-utils`

| Utility | What it does |
|---------|-------------|
| `ArrayUtils()` | Returns object with: `find(arr, predicate, scopedData)`, `findIndex`, `filter`, `map`, `contains`, `reject`, `pick`, `slice`, `sortBy` |
| `getProperty(source, path, default)` | Safe deep-get by dot string or array path; returns `default` (Invalid by default) if any key missing |
| `getType(value)` | Returns BrightScript type name via `Type(Box(value), 3)` — use this instead of raw `Type()` |
| `functionCall(func, args, context)` | Calls a function reference with up to 4 args in a given context — used for user callbacks |
| `setInterval(callback, intervalSeconds, context)` → id | Repeating timer; returns string id |
| `clearInterval(id)` | Cancels a setInterval timer |
| `setTimeout(callback, delaySeconds, context)` → id | One-shot timer |
| `clearTimeout(id)` | Cancels a setTimeout |

**`ArrayUtils` predicate shorthand**: pass an AssociativeArray `{ key: value }` instead of a function to match on that field:
```brs
' finds first item where item.key = "foo"
found = arrayUtils.find(arr, { key: "foo" })
```

### `@dazn/kopytko-framework`

Import: `' @import /components/http/request/createRequest.brs from @dazn/kopytko-framework`

`createRequest(taskName, data)` — creates an SGNode HTTP task and returns a Promise chain. Used in `Featurevisor.request.brs` for datafile fetching.

### `murmurhash-roku`

Import: `' @import /components/libs/murmurhash.brs from murmurhash-roku`

```brs
MurmurHash().v3(key, seed&)  ' returns LongInteger (32-bit hash)
```

Used in `FeaturevisorBucket.brs` to hash the bucket key. Seed is `1&`.

### `compare-versions-roku`

Import: `' @import /components/libs/compareVersions.brs from compare-versions-roku`

```brs
compareVersions(v1 as String, v2 as String) as Integer
' returns 1 (v1 > v2), -1 (v1 < v2), 0 (equal)
```

Used for all `semverX` condition operators.

---

## Test framework (`@dazn/kopytko-unit-testing-framework`)

Test files live alongside source in `_tests/` and follow the naming `FeaturevisorX.test.brs`.

### Test structure

```brs
function TestSuite__FeaturevisorX() as Object
  ts = KopytkoTestSuite()
  ts.name = "FeaturevisorX"

  beforeEach(sub (_ts as Object) : ... : end sub)
  afterEach(sub (_ts as Object) : ... : end sub)

  it("description", function (_ts as Object) as String
    ' returns expect(...).toBeX() — empty string = pass, non-empty = failure message
    return expect(result).toBe(expected)
  end function)

  ' Return array to make multiple assertions in one test
  it("multiple assertions", function (_ts as Object) as Object
    return [
      expect(a).toBeTrue(),
      expect(b).toBe("value"),
    ]
  end function)

  ' Parameterised tests — ${fieldName} interpolated into test name
  itEach(paramsList, "should ${operator} correctly", function (_ts as Object, params as Object) as String
    return expect(featurevisorAllConditionsAreMatched(params.conditions, params.match)).toBeTrue()
  end function)

  return ts
end function
```

### Available matchers

```brs
expect(value).toBe(expected)          ' strict equality (primitives only)
expect(value).toEqual(expected)       ' deep equality (objects/arrays)
expect(value).toBeTrue()
expect(value).toBeFalse()
expect(value).toBeInvalid()
expect(value).toBeValid()
expect(value).toContain(item)
expect(value).toHaveKey(key)
expect(value).toHaveLength(n)
expect(value).toHaveBeenCalled()
expect(value).toHaveBeenCalledWith(args)
expect(value).not.toBe(...)           ' negation
```

### Mocking

```brs
' @mock /components/path/to/file.brs from package
mockFunction("functionName").returnValue(someValue)
mockFunction("functionName").returnValues([v1, v2])  ' returns v1 on first call, v2 on second
```

---

## Evaluation reasons reference

Keep in sync with `FeaturevisorEvaluationReason.const.brs`:

| Constant | Value | When used |
|----------|-------|-----------|
| `ALLOCATED` | `"allocated"` | Bucket value falls within allocation range |
| `DEFAULTED` | `"defaulted"` | Variable falls back to `defaultValue` (or `useDefaultWhenDisabled`) |
| `DISABLED` | `"disabled"` | Feature is disabled |
| `ERROR` | `"error"` | Caught exception |
| `FORCED` | `"forced"` | Force rule matched |
| `INITIAL` | `"initial"` | Roku-specific: returned from `initialFeatures` before datafile loads |
| `NO_MATCH` | `"no_match"` | No traffic rule segment matched |
| `NO_VARIATIONS` | `"no_variations"` | Feature has no variations |
| `NOT_FOUND` | `"not_found"` | Feature not in datafile |
| `OUT_OF_RANGE` | `"out_of_range"` | Bucket value outside all mutex-group ranges |
| `OVERRIDE` | `"override"` | Traffic rule has explicit `enabled` override |
| `REQUIRED` | `"required"` | A required feature is not enabled |
| `RULE` | `"rule"` | Traffic rule matched and bucket value within percentage |
| `STICKY` | `"sticky"` | Value comes from `stickyFeatures` |
| `VARIABLE_DISABLED` | `"variable_disabled"` | Variable has `disabledValue` and feature is disabled |
| `VARIABLE_NOT_FOUND` | `"variable_not_found"` | Variable key not in feature's `variablesSchema` |
| `VARIABLE_OVERRIDE_RULE` | `"variable_override_rule"` | Variable value from traffic rule override |
| `VARIABLE_OVERRIDE_VARIATION` | `"variable_override_variation"` | Variable value from variation override |
| `VARIATION_DISABLED` | `"variation_disabled"` | Feature has `disabledVariationValue` and is disabled |

---

## Lint and format

```bash
npm run lint          # check — must produce 0 errors, 0 warnings
npm run lint:fix      # auto-fix what's possible
npm run format        # reformat all .brs files in-place
npm run format:check  # check without writing
npm test              # run all unit tests
```

The linter is `kopytko-linter` and the formatter is `kopytko-formatter`. Both enforce BrightScript-specific conventions. Diagnostic codes 1013 and 1140 are suppressed in `bsconfig.json` (these are expected false positives for the import annotation syntax).
