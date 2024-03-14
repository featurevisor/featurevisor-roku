' @import /components/getProperty.brs from @dazn/kopytko-utils
' @import /components/getType.brs from @dazn/kopytko-utils

function FeaturevisorSDK() as Object
  prototype = {}

  prototype._featurevisorInstance = Invalid
  prototype._isReady = false
  prototype._onActivation = { callback: Invalid, context: Invalid }
  prototype._onReady = { callback: Invalid, context: Invalid }
  prototype._onRefresh = { callback: Invalid, context: Invalid }
  prototype._onUpdate = { callback: Invalid, context: Invalid }

  prototype.createInstance = function (options as Object, featurevisorInstance = Invalid as Object) as Object
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

    if (getType(getProperty(options, ["onUpdate", "callback"])) = "roFunction")
      m.onUpdate(options.onUpdate.callback, options.onUpdate.context)
    else if (getType(m._onUpdate.callback) = "roFunction")
      m.onUpdate(m._onUpdate.callback, m._onUpdate.context)
    end if

    featurevisorInstance.callFunc("initialize", options)

    return featurevisorInstance
  end function

  prototype.activate = function (feature as Dynamic, context = {} as Object) as Object
    if (m._featurevisorInstance = Invalid) then return Invalid

    return m._featurevisorInstance.callFunc("activate", feature, context)
  end function

  prototype.clear = sub (options = {} as Object)
    if (m._featurevisorInstance = Invalid) then return

    m._isReady = false

    m._featurevisorInstance.unobserveFieldScoped("activated")
    m._featurevisorInstance.unobserveFieldScoped("ready")
    m._featurevisorInstance.unobserveFieldScoped("refreshed")
    m._featurevisorInstance.unobserveFieldScoped("updated")

    if (getProperty(options, "clearCallbackDefinitions", false))
      m._onActivation = { callback: Invalid, context: Invalid }
      m._onReady = { callback: Invalid, context: Invalid }
      m._onRefresh = { callback: Invalid, context: Invalid }
      m._onUpdate = { callback: Invalid, context: Invalid }
    end if

    m._featurevisorInstance.callFunc("clear")
  end sub

  prototype.evaluateFlag = function (featureKey as String, context = {} as Object) as Object
    if (m._featurevisorInstance = Invalid) then return Invalid

    return m._featurevisorInstance.callFunc("evaluateFlag", featureKey, context)
  end function

  prototype.evaluateVariable = function (feature as Dynamic, variableKey as String, context = {} as Object) as Object
    if (m._featurevisorInstance = Invalid) then return Invalid

    return m._featurevisorInstance.callFunc("evaluateVariable", feature, variableKey, context)
  end function

  prototype.evaluateVariation = function (feature as Dynamic, context = {} as Object) as Object
    if (m._featurevisorInstance = Invalid) then return Invalid

    return m._featurevisorInstance.callFunc("evaluateVariation", feature, context)
  end function

  prototype.getFeature = function (feature as Dynamic) as Object
    if (m._featurevisorInstance = Invalid) then return Invalid

    return m._featurevisorInstance.callFunc("getFeature", feature)
  end function

  prototype.getRevision = function () as String
    if (m._featurevisorInstance = Invalid) then return ""

    return m._featurevisorInstance.callFunc("getRevision")
  end function

  prototype.getVariable = function (feature as Dynamic, variableKey as String, context = {} as Object) as Dynamic
    if (m._featurevisorInstance = Invalid) then return Invalid

    return m._featurevisorInstance.callFunc("getVariable", feature, variableKey, context)
  end function

  prototype.getVariableArray = function (feature as Dynamic, variableKey as String, context = {} as Object) as Dynamic
    if (m._featurevisorInstance = Invalid) then return Invalid

    return m._featurevisorInstance.callFunc("getVariableArray", feature, variableKey, context)
  end function

  prototype.getVariableBoolean = function (feature as Dynamic, variableKey as String, context = {} as Object) as Dynamic
    if (m._featurevisorInstance = Invalid) then return Invalid

    return m._featurevisorInstance.callFunc("getVariableBoolean", feature, variableKey, context)
  end function

  prototype.getVariableDouble = function (feature as Dynamic, variableKey as String, context = {} as Object) as Dynamic
    if (m._featurevisorInstance = Invalid) then return Invalid

    return m._featurevisorInstance.callFunc("getVariableDouble", feature, variableKey, context)
  end function

  prototype.getVariableInteger = function (feature as Dynamic, variableKey as String, context = {} as Object) as Dynamic
    if (m._featurevisorInstance = Invalid) then return Invalid

    return m._featurevisorInstance.callFunc("getVariableInteger", feature, variableKey, context)
  end function

  prototype.getVariableJSON = function (feature as Dynamic, variableKey as String, context = {} as Object) as Dynamic
    if (m._featurevisorInstance = Invalid) then return Invalid

    return m._featurevisorInstance.callFunc("getVariableJSON", feature, variableKey, context)
  end function

  prototype.getVariableObject = function (feature as Dynamic, variableKey as String, context = {} as Object) as Dynamic
    if (m._featurevisorInstance = Invalid) then return Invalid

    return m._featurevisorInstance.callFunc("getVariableObject", feature, variableKey, context)
  end function

  prototype.getVariableString = function (feature as Dynamic, variableKey as String, context = {} as Object) as Dynamic
    if (m._featurevisorInstance = Invalid) then return Invalid

    return m._featurevisorInstance.callFunc("getVariableString", feature, variableKey, context)
  end function

  prototype.getVariation = function (feature as Dynamic, context = {} as Object) as Dynamic
    if (m._featurevisorInstance = Invalid) then return Invalid

    return m._featurevisorInstance.callFunc("getVariation", feature, context)
  end function

  prototype.isEnabled = function (featureKey as String, context = {} as Object) as Boolean
    if (m._featurevisorInstance = Invalid) then return false

    return m._featurevisorInstance.callFunc("isEnabled", featureKey, context)
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

  prototype.setDatafile = sub (datafile as Dynamic)
    if (m._featurevisorInstance = Invalid) then return

    m._featurevisorInstance.callFunc("setDatafile", datafile)
  end sub

  prototype.setStickyFeatures = sub (stickyFeatures as Object)
    if (m._featurevisorInstance = Invalid) then return

    m._featurevisorInstance.callFunc("setStickyFeatures", stickyFeatures)
  end sub

  prototype.startRefreshing = sub ()
    if (m._featurevisorInstance = Invalid) then return

    m._featurevisorInstance.callFunc("startRefreshing")
  end sub

  prototype.stopRefreshing = sub ()
    if (m._featurevisorInstance = Invalid) then return

    m._featurevisorInstance.callFunc("stopRefreshing")
  end sub

  m["$$FeaturevisorSDK"] = prototype

  return prototype
end function

sub Featurevisor_onActivation(event as Object)
  Featurevisor_callback("$$FeaturevisorSDK_onActivation", m["$$FeaturevisorSDK"]._onActivation, event.getData())
end sub

sub Featurevisor_onReady(_event as Object)
  m["$$FeaturevisorSDK"]._isReady = true
  Featurevisor_callback("$$FeaturevisorSDK_onReady", m["$$FeaturevisorSDK"]._onReady)
end sub

sub Featurevisor_onRefresh(_event as Object)
  Featurevisor_callback("$$FeaturevisorSDK_onRefresh", m["$$FeaturevisorSDK"]._onRefresh)
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
