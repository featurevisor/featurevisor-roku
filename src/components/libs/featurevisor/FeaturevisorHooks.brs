' @import /components/ArrayUtils.brs from @dazn/kopytko-utils

function FeaturevisorHooks() as Object
  prototype = {}

  prototype._hooks = []
  prototype._arrayUtils = ArrayUtils()

  prototype.add = sub (hook as Object)
    for each existing in m._hooks
      if (existing.name = hook.name) then return
    end for

    m._hooks.push(hook)
  end sub

  prototype.remove = sub (name as String)
    m._hooks = m._arrayUtils.filter(m._hooks, function (hook as Object, context as Object) as Boolean
      return hook.name <> context.name
    end function, { name: name })
  end sub

  prototype.getAll = function () as Object
    return m._hooks
  end function

  return prototype
end function
