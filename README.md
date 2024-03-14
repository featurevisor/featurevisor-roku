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
  - [`datafile`](#datafile)
  - [`datafileUrl`](#datafileurl)
  - [`initialFeatures`](#initialfeatures)
  - [`interceptContext`](#interceptcontext)
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
  - [`f.onActivation`](#fonactivation)
  - [`f.onReady`](#fonready)
  - [`f.onRefresh`](#fonrefresh)
  - [`f.onUpdate`](#fonupdate)
  - [`f.clear`](#fclear)
  - [`f.getRevision`](#fgetrevision)
  - [`f.isReady`](#fisready)
  - [`f.refresh`](#frefresh)
  - [`f.setDatafile`](#fsetdatafile)
  - [`f.setStickyFeatures`](#fsetstickyfeatures)
  - [`f.startRefreshing`](#fstartrefreshing)
  - [`f.stopRefreshing`](#fstoprefreshing)

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

### `f.setStickyFeatures`

Set sticky features.

> `f.setStickyFeatures(stickyFeatures as Object)`

### `f.startRefreshing`

Resume or start refreshing if refreshInterval was provided.

> `f.startRefreshing()`

### `f.stopRefreshing`

Stop refreshing.

> `f.stopRefreshing()`

## License <!-- omit in toc -->

MIT © Błażej Chełkowski
