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
  - [`featureVisorFacade.onActivation`](#featurevisorfacadeonactivation)
  - [`featureVisorFacade.onReady`](#featurevisorfacadeonready)
  - [`featureVisorFacade.onRefresh`](#featurevisorfacadeonrefresh)
  - [`featureVisorFacade.onUpdate`](#featurevisorfacadeonupdate)
  - [`featureVisorFacade.isEnabled`](#featurevisorfacadeisenabled)
  - [`featureVisorFacade.getVariation`](#featurevisorfacadegetvariation)
  - [`featureVisorFacade.getVariable`](#featurevisorfacadegetvariable)
  - [`featureVisorFacade.activate`](#featurevisorfacadeactivate)
  - [`featureVisorFacade.clear`](#featurevisorfacadeclear)
  - [`featureVisorFacade.getRevision`](#featurevisorfacadegetrevision)
  - [`featureVisorFacade.isReady`](#featurevisorfacadeisready)
  - [`featureVisorFacade.refresh`](#featurevisorfacaderefresh)
  - [`featureVisorFacade.setDatafile`](#featurevisorfacadesetdatafile)
  - [`featureVisorFacade.setStickyFeatures`](#featurevisorfacadesetstickyfeatures)
  - [`featureVisorFacade.startRefreshing`](#featurevisorfacadestartrefreshing)
  - [`featureVisorFacade.stopRefreshing`](#featurevisorfacadestoprefreshing)

## Installation

```bash
npm i -P @featurevisor/roku
```

## Usage

Initialize the SDK (creates `FeatureVisorAgent` node).
For example, in the new `MyFeatureVisorNode` created:

```brightscript
' @import /components/libs/featureVisor/FeatureVisor.facade.brs from @featurevisor/roku

sub init()
  m._featureVisor = FeatureVisorFacade()
  m._featureVisorAgent = m._featureVisor.initialize({
    datafileUrl: "<featurevisor-datafile-url>",
  })
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
' @import /components/libs/featureVisor/FeatureVisor.facade.brs from @featurevisor/roku

sub init()
  featureVisorAgent = FeatureVisorFacade().initialize({
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
' @import /components/libs/featureVisor/FeatureVisor.facade.brs from @featurevisor/roku

sub init()
  featureVisorAgent = FeatureVisorFacade().initialize({
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
' @import /components/libs/featureVisor/FeatureVisor.facade.brs from @featurevisor/roku

sub init()
  featureVisorAgent = FeatureVisorFacade().initialize({
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
' @import /components/libs/featureVisor/FeatureVisor.facade.brs from @featurevisor/roku

sub init()
  defaultContext = {
    platform: "roku",
    locale: "en_US",
    country: "US",
    timezone: "America/New_York",
  }
  featureVisorAgent = FeatureVisorFacade().initialize({
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
' @import /components/libs/featureVisor/FeatureVisor.facade.brs from @featurevisor/roku

sub init()
  featureVisorAgent = FeatureVisorFacade().initialize({
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
' @import /components/libs/featureVisor/FeatureVisor.facade.brs from @featurevisor/roku

sub init()
  featureVisorAgent = FeatureVisorFacade().initialize({
    onReady: {
      callback: sub ()
        ' agent has been initialized and it is ready
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
' @import /components/libs/featureVisor/FeatureVisor.facade.brs from @featurevisor/roku

sub init()
  featureVisorAgent = FeatureVisorFacade().initialize({
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
' @import /components/libs/featureVisor/FeatureVisor.facade.brs from @featurevisor/roku

sub init()
  featureVisorAgent = FeatureVisorFacade().initialize({
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
' @import /components/libs/featureVisor/FeatureVisor.facade.brs from @featurevisor/roku

sub init()
  featureVisorAgent = FeatureVisorFacade().initialize({
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
' @import /components/libs/featureVisor/FeatureVisor.facade.brs from @featurevisor/roku

sub init()
  featureVisorAgent = FeatureVisorFacade().initialize({
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

### `featureVisorFacade.onActivation`

> `featureVisorFacade.onActivation(func as Function, context = Invalid as Object)`

### `featureVisorFacade.onReady`

> `featureVisorFacade.onReady(func as Function, context = Invalid as Object)`

### `featureVisorFacade.onRefresh`

> `featureVisorFacade.onRefresh(func as Function, context = Invalid as Object)`

### `featureVisorFacade.onUpdate`

> `featureVisorFacade.onUpdate(func as Function, context = Invalid as Object)`

These methods should be called once the SDK instance is created:

### `featureVisorFacade.isEnabled`

> `featureVisorFacade.isEnabled(featureKey as String, context = {} as Object) as Boolean`

### `featureVisorFacade.getVariation`

> `featureVisorFacade.getVariation(feature as Dynamic, context = {} as Object) as Dynamic`

### `featureVisorFacade.getVariable`

> `featureVisorFacade.getVariable(feature as Dynamic, variableKey as String, context = {} as Object) as Object`

Also supports additional type specific methods:

- `featureVisorFacade.getVariableBoolean(feature as Dynamic, variableKey as String, context = {} as Object) as Boolean`
- `featureVisorFacade.getVariableString(feature as Dynamic, variableKey as String, context = {} as Object) as Dynamic`
- `featureVisorFacade.getVariableInteger(feature as Dynamic, variableKey as String, context = {} as Object) as Integer`
- `featureVisorFacade.getVariableDouble(feature as Dynamic, variableKey as String, context = {} as Object) as Float`
- `featureVisorFacade.getVariableArray(feature as Dynamic, variableKey as String, context = {} as Object) as Object`
- `featureVisorFacade.getVariableObject(feature as Dynamic, variableKey as String, context = {} as Object) as Object`
- `featureVisorFacade.getVariableJSON(feature as Dynamic, variableKey as String, context = {} as Object) as Dynamic`

### `featureVisorFacade.activate`

> `featureVisorFacade.activate(feature as Dynamic, context = {} as Object) as Object`

Same as `getVariation`, but also calls the `onActivation` callback.

This is a convenience method meant to be called when you know the User has been exposed to your Feature, and you also want to track the activation.

### `featureVisorFacade.clear`

> `featureVisorFacade.clear()`

### `featureVisorFacade.getRevision`

> `featureVisorFacade.getRevision() as String`

### `featureVisorFacade.isReady`

> `featureVisorFacade.isReady() as Boolean`

Check if the instance is ready to be used.

### `featureVisorFacade.refresh`

> `featureVisorFacade.refresh()`

Manually refresh datafile.

### `featureVisorFacade.setDatafile`

> `featureVisorFacade.setDatafile(datafile as Object)`

### `featureVisorFacade.setStickyFeatures`

> `featureVisorFacade.setStickyFeatures(stickyFeatures as Object)`

### `featureVisorFacade.startRefreshing`

> `featureVisorFacade.startRefreshing()`

Start refreshing if refreshInterval was provided

### `featureVisorFacade.stopRefreshing`

> `featureVisorFacade.stopRefreshing()`

Cancel refreshing

## License <!-- omit in toc -->

MIT © Błażej Chełkowski
