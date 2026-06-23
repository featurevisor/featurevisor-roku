function FeaturevisorHooks() as Object
  prototype = {}

  prototype._hooks = {}

  prototype.add = function (hook as Object) as String
    if (m._hooks.doesExist(hook.name)) then return ""

    m._hooks[hook.name] = hook

    return hook.name
  end function

  prototype.remove = sub (name as String)
    m._hooks.delete(name)
  end sub

  prototype.getAll = function () as Object
    return m._hooks
  end function

  return prototype
end function
