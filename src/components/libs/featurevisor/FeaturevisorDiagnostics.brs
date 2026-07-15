' @import /components/ArrayUtils.brs from @dazn/kopytko-utils
' @import /components/getProperty.brs from @dazn/kopytko-utils
' @import /components/getType.brs from @dazn/kopytko-utils

function FeaturevisorDiagnostics(options = {} as Object) as Object
  prototype = {}

  prototype._LEVELS = ["fatal", "error", "warn", "info", "debug"]

  prototype._arrayUtils = ArrayUtils()
  prototype._level = "info"
  prototype._onDiagnostic = Invalid
  prototype._onDiagnosticContext = Invalid
  prototype._subscriptionCounter = 0
  prototype._subscriptions = []
  prototype._top = Invalid

  _constructor = function (context as Object, options as Object) as Object
    if (options.doesExist("logLevel") AND getType(options.logLevel) = "roString")
      context._level = options.logLevel
    end if

    if (getType(getProperty(options, ["onDiagnostic"])) = "roFunction")
      context._onDiagnostic = options.onDiagnostic
    else if (getType(getProperty(options, ["onDiagnostic", "callback"])) = "roFunction")
      context._onDiagnostic = options.onDiagnostic.callback
      context._onDiagnosticContext = options.onDiagnostic.context
    end if

    return context
  end function

  prototype.setTop = sub (top as Object)
    m._top = top
  end sub

  prototype.setLevel = sub (level as String)
    m._level = level
  end sub

  prototype.subscribe = function (moduleId as String, handler as Function, handlerContext = Invalid as Dynamic, logLevel = "info" as String) as String
    m._subscriptionCounter++
    subscriptionId = "$$subscription_" + m._subscriptionCounter.toStr()
    m._subscriptions.push({
      handler: handler,
      handlerContext: handlerContext,
      id: subscriptionId,
      logLevel: logLevel,
      moduleId: moduleId,
    })

    return subscriptionId
  end function

  prototype.unsubscribe = sub (subscriptionId as String)
    m._subscriptions = m._arrayUtils.reject(m._subscriptions, { id: subscriptionId })
  end sub

  prototype.clearModuleSubscriptions = sub (moduleId as String)
    m._subscriptions = m._arrayUtils.reject(m._subscriptions, { moduleId: moduleId })
  end sub

  prototype.report = sub (diagnostic as Object)
    if (diagnostic.details = Invalid) then diagnostic.details = {}

    sourceModuleId = getProperty(diagnostic, ["_sourceModuleId"], "")
    diagnostic.delete("_sourceModuleId")

    for each subscription in m._subscriptions
      if (subscription.moduleId <> sourceModuleId AND m._levelPasses(subscription.logLevel, diagnostic.level))
        m._invokeHandler(subscription, diagnostic)
      end if
    end for

    if (m._levelPasses(m._level, diagnostic.level))
      if (m._onDiagnostic <> Invalid)
        m._invokeHandler({ handler: m._onDiagnostic, handlerContext: m._onDiagnosticContext }, diagnostic)
      else
        print "[Featurevisor] [";diagnostic.level;"] [";diagnostic.code;"] ";diagnostic.message
      end if
    end if

    if (diagnostic.level = "error" AND m._top <> Invalid)
      m._top.errored = { diagnostic: diagnostic }
    end if
  end sub

  prototype.debug = sub (code as String, message as String, details = {} as Object)
    m.report({ code: code, details: details, level: "debug", message: message })
  end sub

  prototype.info = sub (code as String, message as String, details = {} as Object)
    m.report({ code: code, details: details, level: "info", message: message })
  end sub

  prototype.warn = sub (code as String, message as String, details = {} as Object)
    m.report({ code: code, details: details, level: "warn", message: message })
  end sub

  prototype.error = sub (code as String, message as String, details = {} as Object)
    m.report({ code: code, details: details, level: "error", message: message })
  end sub

  prototype._levelPasses = function (configuredLevel as String, diagnosticLevel as String) as Boolean
    configuredIndex = m._arrayUtils.findIndex(m._LEVELS, configuredLevel)
    diagnosticIndex = m._arrayUtils.findIndex(m._LEVELS, diagnosticLevel)

    if (configuredIndex < 0 OR diagnosticIndex < 0) then return false

    return diagnosticIndex <= configuredIndex
  end function

  prototype._invokeHandler = sub (subscription as Object, diagnostic as Object)
    try
      if (subscription.handlerContext <> Invalid)
        subscription.handlerContext["$$diagnosticHandler"] = subscription.handler
        subscription.handlerContext["$$diagnosticHandler"](diagnostic)
        subscription.handlerContext.delete("$$diagnosticHandler")
      else
        m["$$diagnosticHandler"] = subscription.handler
        m["$$diagnosticHandler"](diagnostic)
        m.delete("$$diagnosticHandler")
      end if
    catch _error
      print "[Featurevisor] [error] diagnostic subscription handler failed"
    end try
  end sub

  return _constructor(prototype, options)
end function
