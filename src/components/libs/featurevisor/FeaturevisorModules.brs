' @import /components/ArrayUtils.brs from @dazn/kopytko-utils
' @import /components/getProperty.brs from @dazn/kopytko-utils

function FeaturevisorModules() as Object
  prototype = {}

  prototype._arrayUtils = ArrayUtils()
  prototype._counter = 0
  prototype._entries = []

  prototype.add = function (module as Object) as String
    moduleName = getProperty(module, ["name"], "")

    if (moduleName <> "")
      if (m._arrayUtils.find(m._entries, { id: moduleName }) <> Invalid) then return ""

      moduleId = moduleName
    else
      m._counter++
      moduleId = "$$module_" + m._counter.toStr()
    end if

    m._entries.push({ id: moduleId, module: module })

    return moduleId
  end function

  prototype.remove = function (nameOrId as String) as Object
    removed = m._arrayUtils.filter(m._entries, { id: nameOrId })
    m._entries = m._arrayUtils.reject(m._entries, { id: nameOrId })

    return removed
  end function

  prototype.getAll = function () as Object
    return m._entries
  end function

  return prototype
end function
