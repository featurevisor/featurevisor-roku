' @import /components/getProperty.brs from @dazn/kopytko-utils
' @import /components/getType.brs from @dazn/kopytko-utils

function FeaturevisorSDK() as Object
  prototype = {}

  prototype._featurevisorInstance = Invalid
  prototype._isReady = false
  prototype._onActivation = { callback: Invalid, context: Invalid }
  prototype._onContextChanged = { callback: Invalid, context: Invalid }
  prototype._onDatafileChanged = { callback: Invalid, context: Invalid }
  prototype._onError = { callback: Invalid, context: Invalid }
  prototype._onReady = { callback: Invalid, context: Invalid }
  prototype._onRefresh = { callback: Invalid, context: Invalid }
  prototype._onStickyChanged = { callback: Invalid, context: Invalid }
  prototype._onUpdate = { callback: Invalid, context: Invalid }

  prototype.createFeaturevisor = function (options as Object, featurevisorInstance = Invalid as Object) as Object
    m.clear()

    if (featurevisorInstance = Invalid)
      featurevisorInstance = CreateObject("roSGNode", "FeaturevisorInstance")
    end if

    m._featurevisorInstance = featurevisorInstance

    if (getType(getProperty(options, ["onActivation", "callback"])) = "roFunction")
      m.onActivation(options.onActivation.callback, options.onActivation.context)
    else if (getType(m._onActivation.callback) = "roFunction")
      m.onActivation(m._onActivation.callback, m._onActivation.context)
    end if

    if (getType(getProperty(options, ["onContextChanged", "callback"])) = "roFunction")
      m.onContextChanged(options.onContextChanged.callback, options.onContextChanged.context)
    else if (getType(m._onContextChanged.callback) = "roFunction")
      m.onContextChanged(m._onContextChanged.callback, m._onContextChanged.context)
    end if

    if (getType(getProperty(options, ["onDatafileChanged", "callback"])) = "roFunction")
      m.onDatafileChanged(options.onDatafileChanged.callback, options.onDatafileChanged.context)
    else if (getType(m._onDatafileChanged.callback) = "roFunction")
      m.onDatafileChanged(m._onDatafileChanged.callback, m._onDatafileChanged.context)
    end if

    if (getType(getProperty(options, ["onError", "callback"])) = "roFunction")
      m.onError(options.onError.callback, options.onError.context)
    else if (getType(m._onError.callback) = "roFunction")
      m.onError(m._onError.callback, m._onError.context)
    end if

    if (getType(getProperty(options, ["onReady", "callback"])) = "roFunction")
      m.onReady(options.onReady.callback, options.onReady.context)
    else if (getType(m._onReady.callback) = "roFunction")
      m.onReady(m._onReady.callback, m._onReady.context)
    end if

    if (getType(getProperty(options, ["onRefresh", "callback"])) = "roFunction")
      m.onRefresh(options.onRefresh.callback, options.onRefresh.context)
    else if (getType(m._onRefresh.callback) = "roFunction")
      m.onRefresh(m._onRefresh.callback, m._onRefresh.context)
    end if

    if (getType(getProperty(options, ["onStickyChanged", "callback"])) = "roFunction")
      m.onStickyChanged(options.onStickyChanged.callback, options.onStickyChanged.context)
    else if (getType(m._onStickyChanged.callback) = "roFunction")
      m.onStickyChanged(m._onStickyChanged.callback, m._onStickyChanged.context)
    end if

    if (getType(getProperty(options, ["onUpdate", "callback"])) = "roFunction")
      m.onUpdate(options.onUpdate.callback, options.onUpdate.context)
    else if (getType(m._onUpdate.callback) = "roFunction")
      m.onUpdate(m._onUpdate.callback, m._onUpdate.context)
    end if

    featurevisorInstance.callFunc("initialize", options)

    return featurevisorInstance
  end function

  ' @deprecated Use createFeaturevisor instead
  prototype.createInstance = function (options as Object, featurevisorInstance = Invalid as Object) as Object
    return m.createFeaturevisor(options, featurevisorInstance)
  end function

  prototype.activate = function (feature as Dynamic, context = {} as Object, options = {} as Object) as Object
    if (m._featurevisorInstance = Invalid) then return Invalid

    return m._featurevisorInstance.callFunc("activate", feature, context, options)
  end function

  prototype.addModule = function (module as Object) as String
    if (m._featurevisorInstance = Invalid) then return ""

    return m._featurevisorInstance.callFunc("addModule", module)
  end function

  prototype.removeModule = sub (nameOrId as String)
    if (m._featurevisorInstance = Invalid) then return

    m._featurevisorInstance.callFunc("removeModule", nameOrId)
  end sub

  prototype.clear = sub (options = {} as Object)
    if (m._featurevisorInstance = Invalid) then return

    m._isReady = false

    m._featurevisorInstance.unobserveFieldScoped("activated")
    m._featurevisorInstance.unobserveFieldScoped("contextChange")
    m._featurevisorInstance.unobserveFieldScoped("datafileChange")
    m._featurevisorInstance.unobserveFieldScoped("errored")
    m._featurevisorInstance.unobserveFieldScoped("ready")
    m._featurevisorInstance.unobserveFieldScoped("refreshed")
    m._featurevisorInstance.unobserveFieldScoped("stickyChange")
    m._featurevisorInstance.unobserveFieldScoped("updated")

    if (getProperty(options, "clearCallbackDefinitions", false))
      m._onActivation = { callback: Invalid, context: Invalid }
      m._onContextChanged = { callback: Invalid, context: Invalid }
      m._onDatafileChanged = { callback: Invalid, context: Invalid }
      m._onError = { callback: Invalid, context: Invalid }
      m._onReady = { callback: Invalid, context: Invalid }
      m._onRefresh = { callback: Invalid, context: Invalid }
      m._onStickyChanged = { callback: Invalid, context: Invalid }
      m._onUpdate = { callback: Invalid, context: Invalid }
    end if

    m._featurevisorInstance.callFunc("clear")
  end sub

  prototype.close = sub ()
    if (m._featurevisorInstance = Invalid) then return

    m.clear()
  end sub

  prototype.evaluateFlag = function (featureKey as String, context = {} as Object, options = {} as Object) as Object
    if (m._featurevisorInstance = Invalid) then return Invalid

    return m._featurevisorInstance.callFunc("evaluateFlag", featureKey, context, options)
  end function

  prototype.evaluateVariable = function (feature as Dynamic, variableKey as String, context = {} as Object, options = {} as Object) as Object
    if (m._featurevisorInstance = Invalid) then return Invalid

    return m._featurevisorInstance.callFunc("evaluateVariable", feature, variableKey, context, options)
  end function

  prototype.evaluateVariation = function (feature as Dynamic, context = {} as Object, options = {} as Object) as Object
    if (m._featurevisorInstance = Invalid) then return Invalid

    return m._featurevisorInstance.callFunc("evaluateVariation", feature, context, options)
  end function

  prototype.getFeature = function (feature as Dynamic) as Object
    if (m._featurevisorInstance = Invalid) then return Invalid

    return m._featurevisorInstance.callFunc("getFeature", feature)
  end function

  prototype.getRevision = function () as String
    if (m._featurevisorInstance = Invalid) then return ""

    return m._featurevisorInstance.callFunc("getRevision")
  end function

  prototype.getSchemaVersion = function () as String
    if (m._featurevisorInstance = Invalid) then return ""

    return m._featurevisorInstance.callFunc("getSchemaVersion")
  end function

  prototype.getSegment = function (segmentKey as String) as Object
    if (m._featurevisorInstance = Invalid) then return Invalid

    return m._featurevisorInstance.callFunc("getSegment", segmentKey)
  end function

  prototype.getFeatureKeys = function () as Object
    if (m._featurevisorInstance = Invalid) then return []

    return m._featurevisorInstance.callFunc("getFeatureKeys")
  end function

  prototype.getVariableKeys = function (featureKey as String) as Object
    if (m._featurevisorInstance = Invalid) then return []

    return m._featurevisorInstance.callFunc("getVariableKeys", featureKey)
  end function

  prototype.hasVariations = function (featureKey as String) as Boolean
    if (m._featurevisorInstance = Invalid) then return false

    return m._featurevisorInstance.callFunc("hasVariations", featureKey)
  end function

  prototype.getVariable = function (feature as Dynamic, variableKey as String, context = {} as Object, options = {} as Object) as Dynamic
    if (m._featurevisorInstance = Invalid) then return Invalid

    return m._featurevisorInstance.callFunc("getVariable", feature, variableKey, context, options)
  end function

  prototype.getVariableArray = function (feature as Dynamic, variableKey as String, context = {} as Object, options = {} as Object) as Dynamic
    if (m._featurevisorInstance = Invalid) then return Invalid

    return m._featurevisorInstance.callFunc("getVariableArray", feature, variableKey, context, options)
  end function

  prototype.getVariableBoolean = function (feature as Dynamic, variableKey as String, context = {} as Object, options = {} as Object) as Dynamic
    if (m._featurevisorInstance = Invalid) then return Invalid

    return m._featurevisorInstance.callFunc("getVariableBoolean", feature, variableKey, context, options)
  end function

  prototype.getVariableDouble = function (feature as Dynamic, variableKey as String, context = {} as Object, options = {} as Object) as Dynamic
    if (m._featurevisorInstance = Invalid) then return Invalid

    return m._featurevisorInstance.callFunc("getVariableDouble", feature, variableKey, context, options)
  end function

  prototype.getVariableInteger = function (feature as Dynamic, variableKey as String, context = {} as Object, options = {} as Object) as Dynamic
    if (m._featurevisorInstance = Invalid) then return Invalid

    return m._featurevisorInstance.callFunc("getVariableInteger", feature, variableKey, context, options)
  end function

  prototype.getVariableJSON = function (feature as Dynamic, variableKey as String, context = {} as Object, options = {} as Object) as Dynamic
    if (m._featurevisorInstance = Invalid) then return Invalid

    return m._featurevisorInstance.callFunc("getVariableJSON", feature, variableKey, context, options)
  end function

  prototype.getVariableObject = function (feature as Dynamic, variableKey as String, context = {} as Object, options = {} as Object) as Dynamic
    if (m._featurevisorInstance = Invalid) then return Invalid

    return m._featurevisorInstance.callFunc("getVariableObject", feature, variableKey, context, options)
  end function

  prototype.getVariableString = function (feature as Dynamic, variableKey as String, context = {} as Object, options = {} as Object) as Dynamic
    if (m._featurevisorInstance = Invalid) then return Invalid

    return m._featurevisorInstance.callFunc("getVariableString", feature, variableKey, context, options)
  end function

  prototype.getVariation = function (feature as Dynamic, context = {} as Object, options = {} as Object) as Dynamic
    if (m._featurevisorInstance = Invalid) then return Invalid

    return m._featurevisorInstance.callFunc("getVariation", feature, context, options)
  end function

  prototype.isEnabled = function (featureKey as String, context = {} as Object, options = {} as Object) as Boolean
    if (m._featurevisorInstance = Invalid) then return false

    return m._featurevisorInstance.callFunc("isEnabled", featureKey, context, options)
  end function

  prototype.isReady = function () as Boolean
    return m._isReady
  end function

  prototype.onActivation = sub (func as Function, context = Invalid as Object)
    m._onActivation = { callback: func, context: context }

    if (m._featurevisorInstance <> Invalid)
      m._featurevisorInstance.unobserveFieldScoped("activated")
      m._featurevisorInstance.observeFieldScoped("activated", "Featurevisor_onActivation")
    end if
  end sub

  prototype.onContextChanged = sub (func as Function, context = Invalid as Object)
    m._onContextChanged = { callback: func, context: context }

    if (m._featurevisorInstance <> Invalid)
      m._featurevisorInstance.unobserveFieldScoped("contextChange")
      m._featurevisorInstance.observeFieldScoped("contextChange", "Featurevisor_onContextChanged")
    end if
  end sub

  prototype.onDatafileChanged = sub (func as Function, context = Invalid as Object)
    m._onDatafileChanged = { callback: func, context: context }

    if (m._featurevisorInstance <> Invalid)
      m._featurevisorInstance.unobserveFieldScoped("datafileChange")
      m._featurevisorInstance.observeFieldScoped("datafileChange", "Featurevisor_onDatafileChanged")
    end if
  end sub

  prototype.onError = sub (func as Function, context = Invalid as Object)
    m._onError = { callback: func, context: context }

    if (m._featurevisorInstance <> Invalid)
      m._featurevisorInstance.unobserveFieldScoped("errored")
      m._featurevisorInstance.observeFieldScoped("errored", "Featurevisor_onError")
    end if
  end sub

  prototype.onReady = sub (func as Function, context = Invalid as Object)
    m._onReady = { callback: func, context: context }

    if (m._featurevisorInstance <> Invalid)
      m._featurevisorInstance.unobserveFieldScoped("ready")
      m._featurevisorInstance.observeFieldScoped("ready", "Featurevisor_onReady")
    end if
  end sub

  prototype.onRefresh = sub (func as Function, context = Invalid as Object)
    m._onRefresh = { callback: func, context: context }

    if (m._featurevisorInstance <> Invalid)
      m._featurevisorInstance.unobserveFieldScoped("refreshed")
      m._featurevisorInstance.observeFieldScoped("refreshed", "Featurevisor_onRefresh")
    end if
  end sub

  prototype.onStickyChanged = sub (func as Function, context = Invalid as Object)
    m._onStickyChanged = { callback: func, context: context }

    if (m._featurevisorInstance <> Invalid)
      m._featurevisorInstance.unobserveFieldScoped("stickyChange")
      m._featurevisorInstance.observeFieldScoped("stickyChange", "Featurevisor_onStickyChanged")
    end if
  end sub

  prototype.onUpdate = sub (func as Function, context = Invalid as Object)
    m._onUpdate = { callback: func, context: context }

    if (m._featurevisorInstance <> Invalid)
      m._featurevisorInstance.unobserveFieldScoped("updated")
      m._featurevisorInstance.observeFieldScoped("updated", "Featurevisor_onUpdate")
    end if
  end sub

  prototype.refresh = sub ()
    if (m._featurevisorInstance = Invalid) then return

    m._featurevisorInstance.callFunc("refresh")
  end sub

  prototype.setDatafile = sub (datafile as Dynamic, replace = false as Boolean)
    if (m._featurevisorInstance = Invalid) then return

    m._featurevisorInstance.callFunc("setDatafile", datafile, replace)
  end sub

  prototype.getAllEvaluations = function (context = {} as Object, featureKeys = [] as Object, options = {} as Object) as Object
    if (m._featurevisorInstance = Invalid) then return {}

    return m._featurevisorInstance.callFunc("getAllEvaluations", context, featureKeys, options)
  end function

  prototype.getContext = function (context = {} as Object) as Object
    if (m._featurevisorInstance = Invalid) then return {}

    return m._featurevisorInstance.callFunc("getContext", context)
  end function

  prototype.setContext = sub (context as Object, replace = false as Boolean)
    if (m._featurevisorInstance = Invalid) then return

    m._featurevisorInstance.callFunc("setContext", context, replace)
  end sub

  prototype.setSticky = sub (stickyFeatures as Object, replace = false as Boolean)
    if (m._featurevisorInstance = Invalid) then return

    m._featurevisorInstance.callFunc("setSticky", stickyFeatures, replace)
  end sub

  prototype.spawn = function (context = {} as Object, options = {} as Object) as Object
    if (m._featurevisorInstance = Invalid) then return Invalid

    childContext = m._featurevisorInstance.callFunc("getContext", context)

    return Featurevisor_createChildInstance(m._featurevisorInstance, childContext, getProperty(options, ["sticky"], {}))
  end function

  ' @deprecated Use setSticky instead
  prototype.setStickyFeatures = sub (stickyFeatures as Object)
    if (m._featurevisorInstance = Invalid) then return

    m._featurevisorInstance.callFunc("setStickyFeatures", stickyFeatures)
  end sub

  prototype.startRefreshing = sub ()
    if (m._featurevisorInstance = Invalid) then return

    m._featurevisorInstance.callFunc("startRefreshing")
  end sub

  prototype.setLogLevel = sub (level as String)
    if (m._featurevisorInstance = Invalid) then return

    m._featurevisorInstance.callFunc("setLogLevel", level)
  end sub

  prototype.stopRefreshing = sub ()
    if (m._featurevisorInstance = Invalid) then return

    m._featurevisorInstance.callFunc("stopRefreshing")
  end sub

  m["$$FeaturevisorSDK"] = prototype

  return prototype
end function

function Featurevisor_createChildInstance(featurevisorInstance as Object, context as Object, sticky as Object) as Object
  child = {}

  child._context = context
  child._featurevisorInstance = featurevisorInstance
  child._onContextChanged = { callback: Invalid, context: Invalid }
  child._onStickyChanged = { callback: Invalid, context: Invalid }
  child._sticky = sticky

  child.close = sub ()
    m._onContextChanged = { callback: Invalid, context: Invalid }
    m._onStickyChanged = { callback: Invalid, context: Invalid }
  end sub

  child.getAllEvaluations = function (context = {} as Object, featureKeys = [] as Object, options = {} as Object) as Object
    return m._featurevisorInstance.callFunc("getAllEvaluations", m._mergeContext(context), featureKeys, m._childOptions(options))
  end function

  child.getContext = function (context = {} as Object) as Object
    return m._featurevisorInstance.callFunc("getContext", m._mergeContext(context))
  end function

  child.getVariable = function (feature as Dynamic, variableKey as String, context = {} as Object, options = {} as Object) as Dynamic
    return m._featurevisorInstance.callFunc("getVariable", feature, variableKey, m._mergeContext(context), m._childOptions(options))
  end function

  child.getVariableArray = function (feature as Dynamic, variableKey as String, context = {} as Object, options = {} as Object) as Dynamic
    return m._featurevisorInstance.callFunc("getVariableArray", feature, variableKey, m._mergeContext(context), m._childOptions(options))
  end function

  child.getVariableBoolean = function (feature as Dynamic, variableKey as String, context = {} as Object, options = {} as Object) as Dynamic
    return m._featurevisorInstance.callFunc("getVariableBoolean", feature, variableKey, m._mergeContext(context), m._childOptions(options))
  end function

  child.getVariableDouble = function (feature as Dynamic, variableKey as String, context = {} as Object, options = {} as Object) as Dynamic
    return m._featurevisorInstance.callFunc("getVariableDouble", feature, variableKey, m._mergeContext(context), m._childOptions(options))
  end function

  child.getVariableInteger = function (feature as Dynamic, variableKey as String, context = {} as Object, options = {} as Object) as Dynamic
    return m._featurevisorInstance.callFunc("getVariableInteger", feature, variableKey, m._mergeContext(context), m._childOptions(options))
  end function

  child.getVariableJSON = function (feature as Dynamic, variableKey as String, context = {} as Object, options = {} as Object) as Dynamic
    return m._featurevisorInstance.callFunc("getVariableJSON", feature, variableKey, m._mergeContext(context), m._childOptions(options))
  end function

  child.getVariableObject = function (feature as Dynamic, variableKey as String, context = {} as Object, options = {} as Object) as Dynamic
    return m._featurevisorInstance.callFunc("getVariableObject", feature, variableKey, m._mergeContext(context), m._childOptions(options))
  end function

  child.getVariableString = function (feature as Dynamic, variableKey as String, context = {} as Object, options = {} as Object) as Dynamic
    return m._featurevisorInstance.callFunc("getVariableString", feature, variableKey, m._mergeContext(context), m._childOptions(options))
  end function

  child.getVariation = function (feature as Dynamic, context = {} as Object, options = {} as Object) as Dynamic
    return m._featurevisorInstance.callFunc("getVariation", feature, m._mergeContext(context), m._childOptions(options))
  end function

  child.isEnabled = function (featureKey as String, context = {} as Object, options = {} as Object) as Boolean
    return m._featurevisorInstance.callFunc("isEnabled", featureKey, m._mergeContext(context), m._childOptions(options))
  end function

  child.onContextChanged = sub (func as Function, context = Invalid as Object)
    m._onContextChanged = { callback: func, context: context }
  end sub

  child.onStickyChanged = sub (func as Function, context = Invalid as Object)
    m._onStickyChanged = { callback: func, context: context }
  end sub

  child.setContext = sub (context as Object, replace = false as Boolean)
    if (replace)
      m._context = context
    else
      m._context = m._mergeContext(context)
    end if

    Featurevisor_callback("$$FeaturevisorChild_onContextChanged", m._onContextChanged, { context: m._context, replaced: replace })
  end sub

  child.setSticky = sub (sticky as Object, replace = false as Boolean)
    featureKeys = {}
    for each key in m._sticky
      featureKeys[key] = true
    end for
    for each key in sticky
      featureKeys[key] = true
    end for

    features = []
    for each key in featureKeys
      features.push(key)
    end for

    if (replace)
      m._sticky = sticky
    else
      merged = {}
      for each key in m._sticky
        merged[key] = m._sticky[key]
      end for
      for each key in sticky
        merged[key] = sticky[key]
      end for
      m._sticky = merged
    end if

    Featurevisor_callback("$$FeaturevisorChild_onStickyChanged", m._onStickyChanged, { features: features, replaced: replace })
  end sub

  child._childOptions = function (options as Object) as Object
    scoped = {}
    for each key in options
      scoped[key] = options[key]
    end for
    scoped["__childSticky"] = m._sticky

    return scoped
  end function

  child._mergeContext = function (context as Object) as Object
    merged = {}
    for each key in m._context
      merged[key] = m._context[key]
    end for
    for each key in context
      merged[key] = context[key]
    end for

    return merged
  end function

  return child
end function

sub Featurevisor_onActivation(event as Object)
  Featurevisor_callback("$$FeaturevisorSDK_onActivation", m["$$FeaturevisorSDK"]._onActivation, event.getData())
end sub

sub Featurevisor_onContextChanged(event as Object)
  Featurevisor_callback("$$FeaturevisorSDK_onContextChanged", m["$$FeaturevisorSDK"]._onContextChanged, event.getData())
end sub

sub Featurevisor_onDatafileChanged(event as Object)
  Featurevisor_callback("$$FeaturevisorSDK_onDatafileChanged", m["$$FeaturevisorSDK"]._onDatafileChanged, event.getData())
end sub

sub Featurevisor_onError(event as Object)
  Featurevisor_callback("$$FeaturevisorSDK_onError", m["$$FeaturevisorSDK"]._onError, event.getData())
end sub

sub Featurevisor_onReady(_event as Object)
  m["$$FeaturevisorSDK"]._isReady = true
  Featurevisor_callback("$$FeaturevisorSDK_onReady", m["$$FeaturevisorSDK"]._onReady)
end sub

sub Featurevisor_onRefresh(_event as Object)
  Featurevisor_callback("$$FeaturevisorSDK_onRefresh", m["$$FeaturevisorSDK"]._onRefresh)
end sub

sub Featurevisor_onStickyChanged(event as Object)
  Featurevisor_callback("$$FeaturevisorSDK_onStickyChanged", m["$$FeaturevisorSDK"]._onStickyChanged, event.getData())
end sub

sub Featurevisor_onUpdate(_event as Object)
  Featurevisor_callback("$$FeaturevisorSDK_onUpdate", m["$$FeaturevisorSDK"]._onUpdate)
end sub

sub Featurevisor_callback(key as String, callbackData as Object, data = Invalid as Object)
  if (getType(callbackData.callback) <> "roFunction") then return

  if (callbackData.context <> Invalid)
    callbackData.context[key] = callbackData.callback

    if (data <> Invalid)
      callbackData.context[key](data)
    else
      callbackData.context[key]()
    end if

    callbackData.context.delete(key)

    return
  end if

  m[key] = callbackData.callback

  if (data <> Invalid)
    m[key](data)
  else
    m[key]()
  end if

  m.delete(key)
end sub
