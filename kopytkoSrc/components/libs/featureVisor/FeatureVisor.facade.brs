' @import /components/getProperty.brs from @dazn/kopytko-utils
' @import /components/getType.brs from @dazn/kopytko-utils

function FeatureVisorFacade() as Object
  prototype = {}

  prototype._featureVisorAgent = Invalid
  prototype._isReady = false
  prototype._onActivation = { callback: Invalid, context: Invalid }
  prototype._onReady = { callback: Invalid, context: Invalid }
  prototype._onRefresh = { callback: Invalid, context: Invalid }
  prototype._onUpdate = { callback: Invalid, context: Invalid }

  prototype.initialize = function (options as Object, featureVisorAgent = Invalid as Object) as Object
    m.clear()

    if (featureVisorAgent = Invalid)
      featureVisorAgent = CreateObject("roSGNode", "FeatureVisorAgent")
    end if

    m._featureVisorAgent = featureVisorAgent

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

    featureVisorAgent.callFunc("initialize", options)

    return featureVisorAgent
  end function

  prototype.activate = function (feature as Dynamic, context = {} as Object) as Object
    if (m._featureVisorAgent = Invalid) then return Invalid

    return m._featureVisorAgent.callFunc("activate", feature, context)
  end function

  prototype.clear = sub (options = {} as Object)
    if (m._featureVisorAgent = Invalid) then return

    m._isReady = false

    m._featureVisorAgent.unobserveFieldScoped("activated")
    m._featureVisorAgent.unobserveFieldScoped("ready")
    m._featureVisorAgent.unobserveFieldScoped("refreshed")
    m._featureVisorAgent.unobserveFieldScoped("updated")

    if (getProperty(options, "clearCallbackDefinitions", false))
      m._onActivation = { callback: Invalid, context: Invalid }
      m._onReady = { callback: Invalid, context: Invalid }
      m._onRefresh = { callback: Invalid, context: Invalid }
      m._onUpdate = { callback: Invalid, context: Invalid }
    end if

    m._featureVisorAgent.callFunc("clear")
  end sub

  prototype.evaluateFlag = function (featureKey as String, context = {} as Object) as Object
    if (m._featureVisorAgent = Invalid) then return Invalid

    return m._featureVisorAgent.callFunc("evaluateFlag", featureKey, context)
  end function

  prototype.evaluateVariable = function (feature as Dynamic, variableKey as String, context = {} as Object) as Object
    if (m._featureVisorAgent = Invalid) then return Invalid

    return m._featureVisorAgent.callFunc("evaluateVariable", feature, variableKey, context)
  end function

  prototype.evaluateVariation = function (feature as Dynamic, context = {} as Object) as Object
    if (m._featureVisorAgent = Invalid) then return Invalid

    return m._featureVisorAgent.callFunc("evaluateVariation", feature, context)
  end function

  prototype.getFeature = function (feature as Dynamic) as Object
    if (m._featureVisorAgent = Invalid) then return Invalid

    return m._featureVisorAgent.callFunc("getFeature", feature)
  end function

  prototype.getRevision = function () as String
    if (m._featureVisorAgent = Invalid) then return ""

    return m._featureVisorAgent.callFunc("getRevision")
  end function

  prototype.getVariable = function (feature as Dynamic, variableKey as String, context = {} as Object) as Object
    if (m._featureVisorAgent = Invalid) then return Invalid

    return m._featureVisorAgent.callFunc("getVariable", feature, variableKey, context)
  end function

  prototype.getVariableArray = function (feature as Dynamic, variableKey as String, context = {} as Object) as Object
    if (m._featureVisorAgent = Invalid) then return Invalid

    return m._featureVisorAgent.callFunc("getVariableArray", feature, variableKey, context)
  end function

  prototype.getVariableBoolean = function (feature as Dynamic, variableKey as String, context = {} as Object) as Boolean
    if (m._featureVisorAgent = Invalid) then return false

    return m._featureVisorAgent.callFunc("getVariableBoolean", feature, variableKey, context)
  end function

  prototype.getVariableDouble = function (feature as Dynamic, variableKey as String, context = {} as Object) as Float
    if (m._featureVisorAgent = Invalid) then return 0

    return m._featureVisorAgent.callFunc("getVariableDouble", feature, variableKey, context)
  end function

  prototype.getVariableInteger = function (feature as Dynamic, variableKey as String, context = {} as Object) as Integer
    if (m._featureVisorAgent = Invalid) then return 0

    return m._featureVisorAgent.callFunc("getVariableInteger", feature, variableKey, context)
  end function

  prototype.getVariableJSON = function (feature as Dynamic, variableKey as String, context = {} as Object) as Dynamic
    if (m._featureVisorAgent = Invalid) then return Invalid

    return m._featureVisorAgent.callFunc("getVariableJSON", feature, variableKey, context)
  end function

  prototype.getVariableObject = function (feature as Dynamic, variableKey as String, context = {} as Object) as Object
    if (m._featureVisorAgent = Invalid) then return Invalid

    return m._featureVisorAgent.callFunc("getVariableObject", feature, variableKey, context)
  end function

  prototype.getVariableString = function (feature as Dynamic, variableKey as String, context = {} as Object) as Dynamic
    if (m._featureVisorAgent = Invalid) then return Invalid

    return m._featureVisorAgent.callFunc("getVariableString", feature, variableKey, context)
  end function

  prototype.getVariation = function (feature as Dynamic, context = {} as Object) as Dynamic
    if (m._featureVisorAgent = Invalid) then return Invalid

    return m._featureVisorAgent.callFunc("getVariation", feature, context)
  end function

  prototype.isEnabled = function (featureKey as String, context = {} as Object) as Boolean
    if (m._featureVisorAgent = Invalid) then return false

    return m._featureVisorAgent.callFunc("isEnabled", featureKey, context)
  end function

  prototype.isReady = function () as Boolean
    return m._isReady
  end function

  prototype.onActivation = sub (func as Function, context = Invalid as Object)
    m._onActivation = { callback: func, context: context }

    if (m._featureVisorAgent <> Invalid)
      m._featureVisorAgent.unobserveFieldScoped("activated")
      m._featureVisorAgent.observeFieldScoped("activated", "FeatureVisor_onActivation")
    end if
  end sub

  prototype.onReady = sub (func as Function, context = Invalid as Object)
    m._onReady = { callback: func, context: context }

    if (m._featureVisorAgent <> Invalid)
      m._featureVisorAgent.unobserveFieldScoped("ready")
      m._featureVisorAgent.observeFieldScoped("ready", "FeatureVisor_onReady")
    end if
  end sub

  prototype.onRefresh = sub (func as Function, context = Invalid as Object)
    m._onRefresh = { callback: func, context: context }

    if (m._featureVisorAgent <> Invalid)
      m._featureVisorAgent.unobserveFieldScoped("refreshed")
      m._featureVisorAgent.observeFieldScoped("refreshed", "FeatureVisor_onRefresh")
    end if
  end sub

  prototype.onUpdate = sub (func as Function, context = Invalid as Object)
    m._onUpdate = { callback: func, context: context }

    if (m._featureVisorAgent <> Invalid)
      m._featureVisorAgent.unobserveFieldScoped("updated")
      m._featureVisorAgent.observeFieldScoped("updated", "FeatureVisor_onUpdate")
    end if
  end sub

  prototype.refresh = sub ()
    if (m._featureVisorAgent = Invalid) then return

    m._featureVisorAgent.callFunc("refresh")
  end sub

  prototype.setDatafile = sub (datafile as Dynamic)
    if (m._featureVisorAgent = Invalid) then return

    m._featureVisorAgent.callFunc("setDatafile", datafile)
  end sub

  prototype.setStickyFeatures = sub (stickyFeatures as Object)
    if (m._featureVisorAgent = Invalid) then return

    m._featureVisorAgent.callFunc("setStickyFeatures", stickyFeatures)
  end sub

  prototype.startRefreshing = sub ()
    if (m._featureVisorAgent = Invalid) then return

    m._featureVisorAgent.callFunc("startRefreshing")
  end sub

  prototype.stopRefreshing = sub ()
    if (m._featureVisorAgent = Invalid) then return

    m._featureVisorAgent.callFunc("stopRefreshing")
  end sub

  m["$$FeatureVisorFacade"] = prototype

  return prototype
end function

sub FeatureVisor_onActivation(event as Object)
  FeatureVisor_callback("$$FeatureVisorFacade_onActivation", m["$$FeatureVisorFacade"]._onActivation, event.getData())
end sub

sub FeatureVisor_onReady(_event as Object)
  m["$$FeatureVisorFacade"]._isReady = true
  FeatureVisor_callback("$$FeatureVisorFacade_onReady", m["$$FeatureVisorFacade"]._onReady)
end sub

sub FeatureVisor_onRefresh(_event as Object)
  FeatureVisor_callback("$$FeatureVisorFacade_onRefresh", m["$$FeatureVisorFacade"]._onRefresh)
end sub

sub FeatureVisor_onUpdate(_event as Object)
  FeatureVisor_callback("$$FeatureVisorFacade_onUpdate", m["$$FeatureVisorFacade"]._onUpdate)
end sub

sub FeatureVisor_callback(key as String, callbackData as Object, data = Invalid as Object)
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
