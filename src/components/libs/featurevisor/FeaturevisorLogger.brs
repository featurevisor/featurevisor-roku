' @import /components/ArrayUtils.brs from @dazn/kopytko-utils
' @import /components/getType.brs from @dazn/kopytko-utils

function FeaturevisorLogger(options = {} as Object) as Object
  prototype = {}

  prototype._LEVELS = ["fatal", "error", "warn", "info", "debug"]

  prototype._arrayUtils = ArrayUtils()
  prototype._level = "info"
  prototype._handler = Invalid

  _constructor = function (context as Object, options as Object) as Object
    if (options.doesExist("logLevel") AND getType(options.logLevel) = "roString")
      context._level = options.logLevel
    end if

    if (options.doesExist("logger") AND getType(options.logger) = "roFunction")
      context._handler = options.logger
    end if

    return context
  end function

  prototype.setLevel = sub (level as String)
    m._level = level
  end sub

  prototype.log = sub (level as String, message as String, details = {} as Object)
    levelIndex = m._arrayUtils.findIndex(m._LEVELS, m._level)
    msgLevelIndex =  m._arrayUtils.findIndex(m._LEVELS, level)

    if (levelIndex < 0 OR msgLevelIndex < 0) then return
    if (msgLevelIndex > levelIndex) then return

    if (m._handler <> Invalid AND getType(m._handler) = "roFunction")
      m._handler(level, message, details)
    else
      print "[Featurevisor] [";level;"] ";message
    end if
  end sub

  prototype.debug = sub (message as String, details = {} as Object)
    m.log("debug", message, details)
  end sub

  prototype.info = sub (message as String, details = {} as Object)
    m.log("info", message, details)
  end sub

  prototype.warn = sub (message as String, details = {} as Object)
    m.log("warn", message, details)
  end sub

  prototype.error = sub (message as String, details = {} as Object)
    m.log("error", message, details)
  end sub

  return _constructor(prototype, options)
end function
