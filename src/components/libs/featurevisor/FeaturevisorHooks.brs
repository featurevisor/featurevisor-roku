function FeaturevisorHooks() as Object
  prototype = {}

  prototype._hooks = {}

  prototype.add = sub (hook as Object)
    if (m._hooks.doesExist(hook.name)) then return

    m._hooks[hook.name] = hook
  end sub

  prototype.remove = sub (name as String)
    m._hooks.delete(name)
  end sub

  prototype.getAll = function () as Object
    return m._hooks
  end function

  return prototype
end function
