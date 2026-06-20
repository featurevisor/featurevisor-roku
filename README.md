[![Featurevisor](./assets/banner-bordered.png)](https://featurevisor.com)

<div align="center">
  <h3><strong>Feature management for developers</strong></h3>
</div>

<div align="center">
  <small>Manage your feature flags and experiments declaratively from the comfort of your Git workflow.</small>
</div>

<br />

<div align="center">
  <!-- NPM version -->
  <a href="https://npmjs.org/package/@featurevisor/roku">
    <img src="https://img.shields.io/npm/v/@featurevisor/roku.svg"
      alt="NPM version" />
  </a>
  <!-- License -->
  <a href="./LICENSE">
    <img src="https://img.shields.io/npm/l/@featurevisor/sdk.svg?style=flat-square"
      alt="License" />
  </a>
</div>

<div align="center">
  <h3>
    <a href="https://featurevisor.com">
      Website
    </a>
    <span> | </span>
    <a href="https://featurevisor.com/docs/sdks/roku">
      Documentation
    </a>
    <span> | </span>
    <a href="https://github.com/featurevisor/featurevisor-roku/issues">
      Issues
    </a>
    <span> | </span>
    <a href="https://featurevisor.com/docs/contributing">
      Contributing
    </a>
    <span> | </span>
    <a href="https://github.com/featurevisor/featurevisor-roku/blob/main/CHANGELOG.md">
      Changelog
    </a>
  </h3>
</div>

---

# @featurevisor/roku <!-- omit in toc -->

BrightScript SDK for Roku is meant to be used with [kopytko-framework](https://github.com/getndazn/kopytko-framework).

However, if you don't use it, you can simply copy all SDK files and their dependencies to your project (a version will be prepared in the future if anyone is interested).

Visit [https://featurevisor.com/docs/sdks/roku](https://featurevisor.com/docs/sdks/roku) for more information.

- [Installation](#installation)
- [Usage](#usage)
- [Options](#options)
  - [`bucketKeySeparator`](#bucketkeyseparator)
  - [`configureAndInterceptStaticContext`](#configureandinterceptstaticcontext)
  - [`configureBucketKey`](#configurebucketkey)
  - [`configureBucketValue`](#configurebucketvalue)
  - [`context`](#context)
  - [`datafile`](#datafile)
  - [`datafileUrl`](#datafileurl)
  - [`initialFeatures`](#initialfeatures)
  - [`interceptContext`](#interceptcontext)
  - [`logLevel`](#loglevel)
  - [`logger`](#logger)
  - [`onActivation`](#onactivation)
  - [`onReady`](#onready)
  - [`onRefresh`](#onrefresh)
  - [`onUpdate`](#onupdate)
  - [`refreshInterval`](#refreshinterval)
  - [`stickyFeatures`](#stickyfeatures)
- [API](#api)
  - [`f.isEnabled`](#fisenabled)
  - [`f.getVariation`](#fgetvariation)
  - [`f.getVariable`](#fgetvariable)
  - [`f.activate`](#factivate)
  - [`f.getAllEvaluations`](#fgetallevaluations)
  - [`f.evaluateFlag`](#fevaluateflag)
  - [`f.evaluateVariation`](#fevaluatevariation)
  - [`f.evaluateVariable`](#fevaluatevariable)
  - [`f.getFeature`](#fgetfeature)
  - [`f.getContext`](#fgetcontext)
  - [`f.setContext`](#fsetcontext)
  - [`f.onActivation`](#fonactivation)
  - [`f.onReady`](#fonready)
  - [`f.onRefresh`](#fonrefresh)
  - [`f.onUpdate`](#fonupdate)
  - [`f.clear`](#fclear)
  - [`f.getRevision`](#fgetrevision)
  - [`f.isReady`](#fisready)
  - [`f.refresh`](#frefresh)
  - [`f.setDatafile`](#fsetdatafile)
  - [`f.setSticky`](#fsetsticky)
  - [`f.setStickyFeatures`](#fsetstickyfeatures) *(deprecated)*
  - [`f.startRefreshing`](#fstartrefreshing)
  - [`f.stopRefreshing`](#fstoprefreshing)
- [Evaluation object](#evaluation-object)

## Installation

```bash
npm i -P @featurevisor/roku
```

## Usage

Initialize the SDK (creates `FeaturevisorInstance` node).
For example, in the new `MyFeaturevisorNode` created:

```brightscript
' @import /components/libs/featurevisor/FeaturevisorSDK.brs from @featurevisor/roku

sub init()
  f = FeaturevisorSDK()
  f.createInstance({
    datafileUrl: "<featurevisor-datafile-url>",
  })
end sub
```

You can also pass an existing instance to SDK, to not create a new instance, but to use an existing one to use FeaturevisorSDK methods that are invoked on it.

```brightscript
' @import /components/libs/featurevisor/FeaturevisorSDK.brs from @featurevisor/roku

sub init()
  f = FeaturevisorSDK()
  f.createInstance({
    ' options from an existing instance are kept but could be overridden
  }, existingInstance)
end sub
```

## Options

Options you can pass when creating Featurevisor SDK instance:

### `bucketKeySeparator`

- Type: `string`
- Required: no
- Defaults to: `.`

### `configureAndInterceptStaticContext`

- Type: `associativeArray`
- Required: no

The context for `configureBucketKey`, `configureBucketValue`, and `interceptContext` functions,
this object will be accessible via `m` in those functions.

### `configureBucketKey`

- Type: `function`
- Required: no

Use it to take over bucketing key generation process.

```brightscript
' @import /components/libs/featurevisor/FeaturevisorSDK.brs from @featurevisor/roku

sub init()
  f = FeaturevisorSDK()
  f.createInstance({
    configureBucketKey: function (feature as Dynamic, context as Object, bucketKey as String) as String
      return bucketKey
    end function,
  })
end sub
```

### `configureBucketValue`

- Type: `function`
- Required: no

Use it to take over bucketing process.

```brightscript
' @import /components/libs/featurevisor/FeaturevisorSDK.brs from @featurevisor/roku

sub init()
  f = FeaturevisorSDK()
  f.createInstance({
    configureBucketValue: function (feature as Dynamic, context as Object, bucketValue as String) as Integer
      return bucketValue ' 0 to 100000
    end function,
  })
end sub
```

### `context`

- Type: `associativeArray`
- Required: no

Set a persistent instance-level context that is automatically merged with per-call context in all evaluation functions. Per-call context values take precedence over instance context values.

```brightscript
' @import /components/libs/featurevisor/FeaturevisorSDK.brs from @featurevisor/roku

sub init()
  f = FeaturevisorSDK()
  f.createInstance({
    datafileUrl: "<featurevisor-datafile-url>",
    context: {
      userId: "user-123",
      country: "nl",
    },
  })
end sub
```

### `datafile`

- Type: `associativeArray`
- Required: either `datafile` or `datafileUrl` is required

Use it to pass the datafile object directly.

### `datafileUrl`

- Type: `string`
- Required: either `datafile` or `datafileUrl` is required

Use it to pass the URL to fetch the datafile from.

### `initialFeatures`

- Type: `associativeArray`
- Required: no

Pass set of initial features with their variation and (optional) variables that you want the SDK to return until the datafile is fetched and parsed:

```brightscript
' @import /components/libs/featurevisor/FeaturevisorSDK.brs from @featurevisor/roku

sub init()
  f = FeaturevisorSDK()
  f.createInstance({
    initialFeatures: {
      myFeatureKey: {
        enabled: true,

        ' optional
        variation: "treatment",
        variables: {
          myVariableKey: "my-variable-value",
        },
      },
    },
  })
end sub
```

### `interceptContext`

- Type: `function`
- Required: no

Intercept given context before they are used to bucket the user:

```brightscript
' @import /components/libs/featurevisor/FeaturevisorSDK.brs from @featurevisor/roku

sub init()
  defaultContext = {
    platform: "roku",
    locale: "en_US",
    country: "US",
    timezone: "America/New_York",
  }
  f = FeaturevisorSDK()
  f.createInstance({
    configureAndInterceptStaticContext: defaultContext,
    interceptContext: function (context as Object) as Object
      joinedContext = {}
      joinedContext.append(m)
      joinedContext.append(context)

      return joinedContext
    end function,
  })
end sub
```

### `logLevel`

- Type: `string`
- Required: no
- Default: `"info"`
- Allowed values: `"debug"` | `"info"` | `"warn"` | `"error"` | `"fatal"`

Controls the minimum severity of log messages printed by the SDK.

```brightscript
f.createInstance({
  datafileUrl: "<featurevisor-datafile-url>",
  logLevel: "debug",
})
```

### `logger`

- Type: `function`
- Required: no

Custom log handler. Receives `level` (string), `message` (string), and `details` (associativeArray). When provided, replaces the default `print`-based output.

```brightscript
f.createInstance({
  datafileUrl: "<featurevisor-datafile-url>",
  logger: function (level as String, message as String, details as Object)
    print "[MyApp] [";level;"] ";message
  end function,
})
```

### `onActivation`

- Type: `associativeArray`
- Required: no
- Structure: `{ callback: function, context?: associativeArray }`

Capture activated features along with their evaluated variation:

```brightscript
' @import /components/libs/featurevisor/FeaturevisorSDK.brs from @featurevisor/roku

sub init()
  f = FeaturevisorSDK()
  f.createInstance({
    onActivation: {
      callback: sub (data as Object)
        ' feature has been activated
      end sub,
      context: {}, ' optional context for the callback
    },
  })
end sub
```

`data` Object fields:

- `captureContext`
- `feature`
- `context`
- `variationValue`

`captureContext` will only contain attributes that are marked as `capture: true` in the Attributes' YAML files.

### `onReady`

- Type: `associativeArray`
- Required: no
- Structure: `{ callback: function, context?: associativeArray }`

Triggered maximum once when the SDK is ready to be used.

```brightscript
' @import /components/libs/featurevisor/FeaturevisorSDK.brs from @featurevisor/roku

sub init()
  f = FeaturevisorSDK()
  f.createInstance({
    onReady: {
      callback: sub ()
        ' agent has been createInstanced and it is ready
      end sub,
      context: {}, ' optional context for the callback
    },
  })
end sub
```

### `onRefresh`

- Type: `associativeArray`
- Required: no
- Structure: `{ callback: function, context?: associativeArray }`

Triggered every time the datafile is refreshed.

Works only when `datafileUrl` and `refreshInterval` are set.

```brightscript
' @import /components/libs/featurevisor/FeaturevisorSDK.brs from @featurevisor/roku

sub init()
  f = FeaturevisorSDK()
  f.createInstance({
    onRefresh: {
      callback: sub ()
        ' datafile has been refreshed
      end sub,
      context: {}, ' optional context for the callback
    },
  })
end sub
```

### `onUpdate`

- Type: `associativeArray`
- Required: no
- Structure: `{ callback: function, context?: associativeArray }`

Triggered every time the datafile is refreshed, and the newly fetched datafile is detected to have different content than last fetched one.

Works only when `datafileUrl` and `refreshInterval` are set.

```brightscript
' @import /components/libs/featurevisor/FeaturevisorSDK.brs from @featurevisor/roku

sub init()
  f = FeaturevisorSDK()
  f.createInstance({
    onUpdate: {
      callback: sub ()
        ' datafile has been updated (the revision has changed)
      end sub,
      context: {}, ' optional context for the callback
    },
  })
end sub
```

### `refreshInterval`

- Type: `integer` (in seconds)
- Required: no

Set the interval grater than zero to refresh the datafile.

```brightscript
' @import /components/libs/featurevisor/FeaturevisorSDK.brs from @featurevisor/roku

sub init()
  f = FeaturevisorSDK()
  f.createInstance({
    datafileUrl: "<featurevisor-datafile-url>",
    refreshInterval: 60 * 5, ' every 5 minutes
  })
end sub
```

### `stickyFeatures`

- Type: `associativeArray`
- Required: no

If set, the SDK will skip evaluating the datafile and return variation and variable results from this object instead.

If a feature key is not present in this object, the SDK will continue to evaluate the datafile.

```brightscript
' @import /components/libs/featurevisor/FeaturevisorSDK.brs from @featurevisor/roku

sub init()
  f = FeaturevisorSDK()
  f.createInstance({
    stickyFeatures: {
      myFeatureKey: {
        enabled: true,

        ' optional
        variation: "treatment",
        variables: {
          myVariableKey: "my-variable-value",
        },
      },
    },
  })
end sub
```

## API

### `f.isEnabled`

Check if a feature is enabled or not.

> `f.isEnabled(featureKey as String, context = {} as Object) as Boolean`

### `f.getVariation`

Get feature variation.

> `f.getVariation(feature as Dynamic, context = {} as Object) as Dynamic`

### `f.getVariable`

Get feature variable.

> `f.getVariable(feature as Dynamic, variableKey as String, context = {} as Object) as Dynamic`

Also supports additional type specific methods, returns the value of the desired type, or Invalid if the value does not exist or it does not have a desired type:

- `f.getVariableBoolean(feature as Dynamic, variableKey as String, context = {} as Object) as Dynamic`
- `f.getVariableString(feature as Dynamic, variableKey as String, context = {} as Object) as Dynamic`
- `f.getVariableInteger(feature as Dynamic, variableKey as String, context = {} as Object) as Dynamic`
- `f.getVariableDouble(feature as Dynamic, variableKey as String, context = {} as Object) as Dynamic`
- `f.getVariableArray(feature as Dynamic, variableKey as String, context = {} as Object) as Dynamic`
- `f.getVariableObject(feature as Dynamic, variableKey as String, context = {} as Object) as Dynamic`
- `f.getVariableJSON(feature as Dynamic, variableKey as String, context = {} as Object) as Dynamic`

### `f.activate`

Same as `getVariation`, but also calls the `onActivation` callback.

This is a convenience method meant to be called when you know the User has been exposed to your Feature, and you also want to track the activation.

> `f.activate(feature as Dynamic, context = {} as Object) as Object`

### `f.getAllEvaluations`

Evaluate all features (or a specified subset) at once and return an associativeArray keyed by feature key.

> `f.getAllEvaluations(context = {} as Object, featureKeys = [] as Object) as Object`

Each entry contains:
- `enabled` (Boolean) — whether the feature is enabled
- `variation` (Dynamic) — variation value, if the feature has variations
- `variables` (associativeArray) — map of all variable values, if the feature has variables

```brightscript
evaluations = f.getAllEvaluations({ userId: "user-123" })
' evaluations = {
'   myFeature: { enabled: true, variation: "control", variables: { color: "blue" } },
'   anotherFeature: { enabled: false },
' }
```

Pass a list of feature keys to evaluate only a subset:

```brightscript
evaluations = f.getAllEvaluations({ userId: "user-123" }, ["myFeature", "anotherFeature"])
```

### `f.evaluateFlag`

Returns the full evaluation object for a feature flag, including the reason why the result was produced. Useful for debugging or when you need more than just the boolean result.

> `f.evaluateFlag(featureKey as String, context = {} as Object) as Object`

```brightscript
evaluation = f.evaluateFlag("myFeature", { userId: "user-123" })
' evaluation.enabled => true/false
' evaluation.reason  => "allocated", "forced", "sticky", etc.
```

### `f.evaluateVariation`

Returns the full evaluation object for a feature variation.

> `f.evaluateVariation(feature as Dynamic, context = {} as Object) as Object`

```brightscript
evaluation = f.evaluateVariation("myFeature", { userId: "user-123" })
' evaluation.variationValue => "control" / "treatment" / Invalid
' evaluation.reason         => "allocated", "forced", "no_match", etc.
```

### `f.evaluateVariable`

Returns the full evaluation object for a feature variable.

> `f.evaluateVariable(feature as Dynamic, variableKey as String, context = {} as Object) as Object`

```brightscript
evaluation = f.evaluateVariable("myFeature", "color", { userId: "user-123" })
' evaluation.variableValue  => "blue"
' evaluation.reason         => "allocated", "defaulted", "variable_not_found", etc.
```

### `f.getFeature`

Returns the raw feature definition object from the datafile, or `Invalid` if the feature is not found.

> `f.getFeature(feature as Dynamic) as Object`

### `f.getContext`

Returns the merged context (instance-level context + per-call context).

> `f.getContext(context = {} as Object) as Object`

```brightscript
mergedContext = f.getContext({ sessionId: "session-456" })
```

### `f.setContext`

Sets or merges the instance-level context. This context is automatically merged into every evaluation call.

> `f.setContext(context as Object, replace = false as Boolean)`

- `replace = false` (default): merges `context` into the existing instance context
- `replace = true`: replaces the instance context entirely

```brightscript
f.setContext({ userId: "user-123", country: "nl" })

' Later, replace entirely
f.setContext({ userId: "user-456" }, true)
```

### `f.onActivation`

Adds on activation callback which will be called after an feature activation.

> `f.onActivation(func as Function, context = Invalid as Object)`

### `f.onReady`

Adds on ready callback which will be called after an instance is ready (datafile is saved).

**It should be called before `createInstance`**

> `f.onReady(func as Function, context = Invalid as Object)`

### `f.onRefresh`

Adds on refresh callback which will be called after a successful datafile refresh. But the file doesn't need to change.

> `f.onRefresh(func as Function, context = Invalid as Object)`

### `f.onUpdate`

Adds on update callback which will be called after a successful datafile refresh when it has been changed compared to the previous one.

> `f.onUpdate(func as Function, context = Invalid as Object)`

### `f.clear`

Stop refreshing and clear the whole instance. It needs to be initialized once again.

> `f.clear()`

### `f.getRevision`

Get the datafile revision.

> `f.getRevision() as String`

### `f.isReady`

Check if the instance is ready to be used (the datafile is set).

> `f.isReady() as Boolean`

### `f.refresh`

Manually refresh datafile.

> `f.refresh()`

### `f.setDatafile`

Set datafile manually.

> `f.setDatafile(datafile as Object)`

### `f.setSticky`

Set or merge sticky features. When `replace` is `false` (default), the provided features are merged with the existing ones. When `replace` is `true`, the entire sticky map is replaced.

> `f.setSticky(stickyFeatures as Object, replace = false as Boolean)`

```brightscript
' Merge sticky features
f.setSticky({
  myFeature: { enabled: true, variation: "control" },
})

' Replace all sticky features at once
f.setSticky({
  myFeature: { enabled: false },
}, true)
```

### `f.setStickyFeatures`

> **Deprecated** — use `f.setSticky` instead.

Set sticky features, replacing the entire map.

> `f.setStickyFeatures(stickyFeatures as Object)`

### `f.startRefreshing`

Resume or start refreshing if refreshInterval was provided.

> `f.startRefreshing()`

### `f.stopRefreshing`

Stop refreshing.

> `f.stopRefreshing()`

## Evaluation object

The `evaluateFlag`, `evaluateVariation`, and `evaluateVariable` methods return an associativeArray with the following shape:

| Field           | Type            | Description                                            |
| --------------- | --------------- | ------------------------------------------------------ |
| `featureKey`    | String          | The evaluated feature key                              |
| `reason`        | String          | Why this result was produced (see table below)         |
| `enabled`       | Boolean         | Whether the feature is enabled (flag evaluations)      |
| `variation`     | associativeArray | Matched variation object (variation evaluations)      |
| `variationValue`| Dynamic         | The variation's value                                  |
| `variableKey`   | String          | The evaluated variable key (variable evaluations)      |
| `variableValue` | Dynamic         | The resolved variable value                            |
| `variableSchema`| associativeArray | The variable schema definition                        |
| `bucketValue`   | Integer         | The bucket value used (0–100000)                       |
| `ruleKey`       | String          | The matched traffic rule key                           |
| `error`         | associativeArray | Error details if `reason` is `"error"`                |

### Evaluation reasons

| Reason                       | Description                                                        |
| ---------------------------- | ------------------------------------------------------------------ |
| `"allocated"`                | Regular bucketing allocation matched                               |
| `"defaulted"`                | Variable default value used (e.g. `useDefaultWhenDisabled: true`)  |
| `"disabled"`                 | Feature is disabled                                                |
| `"error"`                    | An unexpected error occurred during evaluation                     |
| `"forced"`                   | Matched a forced rule                                              |
| `"initial"`                  | Instance not yet ready; using `initialFeatures` value              |
| `"no_match"`                 | No traffic rule matched                                            |
| `"no_variations"`            | Feature has no variations defined                                  |
| `"not_found"`                | Feature not found in the datafile                                  |
| `"variable_not_found"`       | Variable key not found in the feature's schema                     |
| `"out_of_range"`             | Feature is in a mutually-exclusive group but bucket is out of range|
| `"override"`                 | Variable overridden by a condition inside a variation (v1 format)  |
| `"required"`                 | A required feature is not enabled                                  |
| `"rule"`                     | Matched a traffic rule                                             |
| `"sticky"`                   | Using a sticky feature override                                    |
| `"variable_disabled"`        | Feature is disabled; variable `disabledValue` is returned          |
| `"variable_override_rule"`   | Variable overridden directly by a traffic rule                     |
| `"variable_override_variation"` | Variable overridden by a condition inside a variation           |
| `"variation_disabled"`       | Feature is disabled; `disabledVariationValue` is returned          |

## License <!-- omit in toc -->

MIT © Błażej Chełkowski
