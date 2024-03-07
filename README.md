# @featurevisor/roku <!-- omit in toc -->

BrightScript SDK for Roku.

Visit [https://featurevisor.com/docs/sdks/](https://featurevisor.com/docs/sdks/) for more information.

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
  - [`featurevisorSDK.onActivation`](#featurevisorsdkonactivation)
  - [`featurevisorSDK.onReady`](#featurevisorsdkonready)
  - [`featurevisorSDK.onRefresh`](#featurevisorsdkonrefresh)
  - [`featurevisorSDK.onUpdate`](#featurevisorsdkonupdate)
  - [`featurevisorSDK.isEnabled`](#featurevisorsdkisenabled)
  - [`featurevisorSDK.getVariation`](#featurevisorsdkgetvariation)
  - [`featurevisorSDK.getVariable`](#featurevisorsdkgetvariable)
  - [`featurevisorSDK.activate`](#featurevisorsdkactivate)
  - [`featurevisorSDK.clear`](#featurevisorsdkclear)
  - [`featurevisorSDK.getRevision`](#featurevisorsdkgetrevision)
  - [`featurevisorSDK.isReady`](#featurevisorsdkisready)
  - [`featurevisorSDK.refresh`](#featurevisorsdkrefresh)
  - [`featurevisorSDK.setDatafile`](#featurevisorsdksetdatafile)
  - [`featurevisorSDK.setStickyFeatures`](#featurevisorsdksetstickyfeatures)
  - [`featurevisorSDK.startRefreshing`](#featurevisorsdkstartrefreshing)
  - [`featurevisorSDK.stopRefreshing`](#featurevisorsdkstoprefreshing)

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
  m.featurevisorSDK = FeaturevisorSDK()
  f = m.featurevisorSDK.createInstance({
    datafileUrl: "<featurevisor-datafile-url>",
  })
end sub
```

You can also pass an existing instance to SDK, to not create a new instance, but to use an existing one to use FeaturevisorSDK methods that are invoked on it.

```brightscript
' @import /components/libs/featurevisor/FeaturevisorSDK.brs from @featurevisor/roku

sub init()
  m.featurevisorSDK = FeaturevisorSDK()
  f = m.featurevisorSDK.createInstance({
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
  m.featurevisorSDK = FeaturevisorSDK()
  f = m.featurevisorSDK.createInstance({
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
  m.featurevisorSDK = FeaturevisorSDK()
  f = m.featurevisorSDK.createInstance({
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
  m.featurevisorSDK = FeaturevisorSDK()
  f = m.featurevisorSDK.createInstance({
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
  m.featurevisorSDK = FeaturevisorSDK()
  f = m.featurevisorSDK.createInstance({
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
  m.featurevisorSDK = FeaturevisorSDK()
  f = m.featurevisorSDK.createInstance({
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
  m.featurevisorSDK = FeaturevisorSDK()
  f = m.featurevisorSDK.createInstance({
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
  m.featurevisorSDK = FeaturevisorSDK()
  f = m.featurevisorSDK.createInstance({
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
  m.featurevisorSDK = FeaturevisorSDK()
  f = m.featurevisorSDK.createInstance({
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
  m.featurevisorSDK = FeaturevisorSDK()
  f = m.featurevisorSDK.createInstance({
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
  m.featurevisorSDK = FeaturevisorSDK()
  f = m.featurevisorSDK.createInstance({
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

Other methods that could be called before initialization:

### `featurevisorSDK.onActivation`

> `featurevisorSDK.onActivation(func as Function, context = Invalid as Object)`

### `featurevisorSDK.onReady`

> `featurevisorSDK.onReady(func as Function, context = Invalid as Object)`

### `featurevisorSDK.onRefresh`

> `featurevisorSDK.onRefresh(func as Function, context = Invalid as Object)`

### `featurevisorSDK.onUpdate`

> `featurevisorSDK.onUpdate(func as Function, context = Invalid as Object)`

These methods should be called once the SDK instance is created:

### `featurevisorSDK.isEnabled`

> `featurevisorSDK.isEnabled(featureKey as String, context = {} as Object) as Boolean`

### `featurevisorSDK.getVariation`

> `featurevisorSDK.getVariation(feature as Dynamic, context = {} as Object) as Dynamic`

### `featurevisorSDK.getVariable`

> `featurevisorSDK.getVariable(feature as Dynamic, variableKey as String, context = {} as Object) as Object`

Also supports additional type specific methods:

- `featurevisorSDK.getVariableBoolean(feature as Dynamic, variableKey as String, context = {} as Object) as Boolean`
- `featurevisorSDK.getVariableString(feature as Dynamic, variableKey as String, context = {} as Object) as Dynamic`
- `featurevisorSDK.getVariableInteger(feature as Dynamic, variableKey as String, context = {} as Object) as Integer`
- `featurevisorSDK.getVariableDouble(feature as Dynamic, variableKey as String, context = {} as Object) as Float`
- `featurevisorSDK.getVariableArray(feature as Dynamic, variableKey as String, context = {} as Object) as Object`
- `featurevisorSDK.getVariableObject(feature as Dynamic, variableKey as String, context = {} as Object) as Object`
- `featurevisorSDK.getVariableJSON(feature as Dynamic, variableKey as String, context = {} as Object) as Dynamic`

### `featurevisorSDK.activate`

> `featurevisorSDK.activate(feature as Dynamic, context = {} as Object) as Object`

Same as `getVariation`, but also calls the `onActivation` callback.

This is a convenience method meant to be called when you know the User has been exposed to your Feature, and you also want to track the activation.

### `featurevisorSDK.clear`

> `featurevisorSDK.clear()`

### `featurevisorSDK.getRevision`

> `featurevisorSDK.getRevision() as String`

### `featurevisorSDK.isReady`

> `featurevisorSDK.isReady() as Boolean`

Check if the instance is ready to be used.

### `featurevisorSDK.refresh`

> `featurevisorSDK.refresh()`

Manually refresh datafile.

### `featurevisorSDK.setDatafile`

> `featurevisorSDK.setDatafile(datafile as Object)`

### `featurevisorSDK.setStickyFeatures`

> `featurevisorSDK.setStickyFeatures(stickyFeatures as Object)`

### `featurevisorSDK.startRefreshing`

> `featurevisorSDK.startRefreshing()`

Start refreshing if refreshInterval was provided

### `featurevisorSDK.stopRefreshing`

> `featurevisorSDK.stopRefreshing()`

Cancel refreshing

## License <!-- omit in toc -->

MIT © Błażej Chełkowski
