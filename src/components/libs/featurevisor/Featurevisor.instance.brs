' @import /components/http/request/createRequest.brs from @dazn/kopytko-framework
' @import /components/ArrayUtils.brs from @dazn/kopytko-utils
' @import /components/functionCall.brs from @dazn/kopytko-utils
' @import /components/getProperty.brs from @dazn/kopytko-utils
' @import /components/getType.brs from @dazn/kopytko-utils
' @import /components/timers/clearInterval.brs from @dazn/kopytko-utils
' @import /components/timers/setInterval.brs from @dazn/kopytko-utils
' @import /components/libs/featurevisor/FeaturevisorBucket.brs
' @import /components/libs/featurevisor/FeaturevisorConditions.brs
' @import /components/libs/featurevisor/FeaturevisorDatafileReader.brs
' @import /components/libs/featurevisor/FeaturevisorDiagnostics.brs
' @import /components/libs/featurevisor/FeaturevisorEvaluationReason.const.brs
' @import /components/libs/featurevisor/FeaturevisorFeature.brs
' @import /components/libs/featurevisor/FeaturevisorModules.brs
' @import /components/libs/featurevisor/FeaturevisorSegments.brs

sub init()
  m._DEFAULT_BUCKET_KEY_SEPARATOR = "."

  m._arrayUtils = ArrayUtils()
  m._featurevisorEvaluationReason = FeaturevisorEvaluationReason()
  m._modulesManager = FeaturevisorModules()
  m._diagnostics = FeaturevisorDiagnostics()
  m._readerHolder = { reader: Invalid }
  m._statuses = {
    ready: false,
    refreshInProgress: false,
  }

  m._bucketKeySeparator = m._DEFAULT_BUCKET_KEY_SEPARATOR
  m._closed = false
  m._configureAndInterceptStaticContext = Invalid
  m._configureBucketKey = Invalid
  m._configureBucketValue = Invalid
  m._datafile = Invalid
  m._datafileReader = Invalid
  m._datafileUrl = ""
  m._initialFeatures = Invalid
  m._instanceContext = {}
  m._interceptContext = Invalid
  m._refreshInterval = 0
  m._stickyFeatures = Invalid
end sub

sub initialize(options = {} as Object)
  m._closed = false
  m._diagnostics = FeaturevisorDiagnostics(options)
  m._diagnostics.setTop(m.top)
  m._bucketKeySeparator = getProperty(options, ["bucketKeySeparator"], m._DEFAULT_BUCKET_KEY_SEPARATOR)
  m._configureAndInterceptStaticContext = getProperty(options, ["configureAndInterceptStaticContext"], m._configureAndInterceptStaticContext)
  m._configureBucketKey = getProperty(options, ["configureBucketKey"], m._configureBucketKey)
  m._configureBucketValue = getProperty(options, ["configureBucketValue"], m._configureBucketValue)
  m._datafileUrl = getProperty(options, ["datafileUrl"], m._datafileUrl)
  m._initialFeatures = getProperty(options, ["initialFeatures"], m._initialFeatures)
  m._interceptContext = getProperty(options, ["interceptContext"], m._interceptContext)
  m._refreshInterval = getProperty(options, ["refreshInterval"], m._refreshInterval)
  m._stickyFeatures = getProperty(options, ["sticky"], getProperty(options, ["stickyFeatures"], m._stickyFeatures))
  m._instanceContext = getProperty(options, ["context"], m._instanceContext)

  if (getType(getProperty(options, ["modules"])) = "roArray")
    for each module in options.modules
      addModule(module)
    end for
  end if

  if (NOT m._statuses.ready AND m._datafileUrl <> "")
    m._datafileReader = Invalid
    datafile = getProperty(options, ["datafile"], {
      schemaVersion: "1",
      revision: "unknown",
      attributes: [],
      segments: [],
      features: [],
    })
    setDatafile(datafile, true)

    chain = createRequest("FeaturevisorRequest", { datafileUrl: m._datafileUrl })
    chain.then(sub (datafile as Object, m as Object)
      setDatafile(datafile, true)

      m._statuses.ready = true
      m.top.ready = {}

      if (m._refreshInterval <> 0)
        startRefreshing()
      end if
    end sub, sub (error as Object, _m as Object)
      _m._diagnostics.error("datafile_fetch_error", "failed to fetch datafile", { error: error })
    end sub, m)
    chain.finally(sub (_data as Object, m as Object)
      m._statuses.refreshInProgress = false
    end sub, m)
  else if (options.datafile <> Invalid)
    m._datafileReader = Invalid
    setDatafile(options.datafile, true)

    m._statuses.ready = true
    m.top.ready = {}
  else
    m._diagnostics.error("initialization_error", "cannot initialize without `datafile` or `datafileUrl` option")
  end if

  m._diagnostics.info("sdk_initialized", "Featurevisor SDK initialized")
end sub

sub clear()
  m._bucketKeySeparator = m._DEFAULT_BUCKET_KEY_SEPARATOR
  m._configureAndInterceptStaticContext = Invalid
  m._configureBucketKey = Invalid
  m._configureBucketValue = Invalid
  m._datafile = Invalid
  m._datafileReader = Invalid
  m._datafileUrl = ""
  m._initialFeatures = Invalid
  m._modulesManager = FeaturevisorModules()
  m._readerHolder = { reader: Invalid }
  m._instanceContext = {}
  m._interceptContext = Invalid
  m._refreshInterval = 0
  m._statuses = {
    ready: false,
    refreshInProgress: false,
  }
  m._stickyFeatures = Invalid
end sub

function addModule(module as Object) as String
  if (m._closed) then return ""

  moduleId = m._modulesManager.add(module)

  if (moduleId = "")
    m._diagnostics.error("duplicate_module", "module with the same name already added", { name: getProperty(module, ["name"], "") })

    return ""
  end if

  try
    _callModule(module, "setup", _getModuleApi(moduleId, module))
  catch error
    m._modulesManager.remove(moduleId)
    m._diagnostics.clearModuleSubscriptions(moduleId)
    m._diagnostics.error("module_setup_error", "module setup failed", { name: getProperty(module, ["name"], ""), error: error.message })
    _closeModule({ id: moduleId, module: module })

    return ""
  end try

  return moduleId
end function

sub removeModule(nameOrId as String)
  if (m._closed) then return

  removed = m._modulesManager.remove(nameOrId)

  for each entry in removed
    m._diagnostics.clearModuleSubscriptions(entry.id)
    _closeModule(entry)
  end for
end sub

sub close()
  m._closed = true
  stopRefreshing()

  for each entry in m._modulesManager.getAll()
    m._diagnostics.clearModuleSubscriptions(entry.id)
    _closeModule(entry)
  end for

  clear()
end sub

sub setLogLevel(level as String)
  m._diagnostics.setLevel(level)
end sub

function activate(feature as Dynamic, context = {} as Object, options = {} as Object) as Object
  try
    evaluation = evaluateVariation(feature, context, options)
    variationValue = getProperty(evaluation, ["variation", "value"], evaluation.variationValue)

    if (variationValue = Invalid) then return Invalid

    attributesForCapturing = m._datafileReader.getAllAttributes()
    attributesForCapturingFiltered = m._arrayUtils.filter(attributesForCapturing, { capture: true })
    captureContext = {}

    finalContext = _interceptContext(context)

    for each attribute in attributesForCapturingFiltered
      if (finalContext[attribute.key] <> Invalid)
        captureContext[attribute.key] = context[attribute.key]
      end if
    end for

    m.top.activated = {
      captureContext: captureContext,
      feature: feature,
      context: finalContext,
      variationValue: variationValue,
    }

    return variationValue
  catch error
    m._diagnostics.error("evaluation_error", "activate error", { feature: feature, error: error.message })

    return Invalid
  end try
end function

function evaluateFlag(featureKey as String, context = {} as Object, options = {} as Object) as Object
  try
    previousSticky = m._stickyFeatures
    hasStickyOverride = options.__childSticky <> Invalid
    if (hasStickyOverride)
      m._stickyFeatures = options.__childSticky
    end if

    evaluateOptions = _applyBeforeModules(featureKey, context)
    result = _evaluateFlagInternal(evaluateOptions.featureKey, evaluateOptions.context)
    result = _applyAfterModules(result, evaluateOptions)

    if (hasStickyOverride)
      m._stickyFeatures = previousSticky
    end if

    return result
  catch error
    if (options.__childSticky <> Invalid)
      m._stickyFeatures = previousSticky
    end if
    m._diagnostics.error("evaluation_error", "evaluateFlag error", { featureKey: featureKey, error: error.message })

    return {
      error: error,
      featureKey: featureKey,
      reason: m._featurevisorEvaluationReason.ERROR,
    }
  end try
end function

function _evaluateFlagInternal(featureKey as String, context as Object) as Object
  try
    ' sticky
    if (getProperty(m._stickyFeatures, [featureKey, "enabled"]) <> Invalid)
      return {
        enabled: getProperty(m._stickyFeatures, [featureKey, "enabled"]),
        featureKey: featureKey,
        reason: m._featurevisorEvaluationReason.STICKY,
        sticky: getProperty(m._stickyFeatures, [featureKey]),
      }
    end if

    ' initial
    if (NOT m._statuses.ready AND getProperty(m._initialFeatures, [featureKey, "enabled"]) <> Invalid)
      return {
        enabled: getProperty(m._initialFeatures, [featureKey, "enabled"]),
        featureKey: featureKey,
        initial: getProperty(m._initialFeatures, [featureKey]),
        reason: m._featurevisorEvaluationReason.INITIAL,
      }
    end if

    feature = getFeature(featureKey)

    ' not found
    if (feature = Invalid)
      m._diagnostics.warn("feature_not_found", "feature not found", { featureKey: featureKey })

      return {
        featureKey: featureKey,
        reason: m._featurevisorEvaluationReason.FEATURE_NOT_FOUND,
      }
    end if

    ' deprecated
    if (getProperty(feature, ["deprecated"], false))
      m._diagnostics.warn("deprecated_feature", "feature is deprecated", { featureKey: featureKey })
    end if

    finalContext = _interceptContext(context)

    ' forced
    force = featurevisorFindForceFromFeature(feature, context, m._datafileReader)

    if (getProperty(force, ["enabled"]) <> Invalid)
      return {
        enabled: getProperty(force, ["enabled"]),
        featureKey: feature.key,
        reason: m._featurevisorEvaluationReason.FORCED,
      }
    end if

    ' required
    if (getProperty(feature, ["required"], []).count() > 0)
      enabledRequiredFeatures = m._arrayUtils.filter(feature.required, function (requiredFeature as Dynamic, context as Object) as Boolean
        requiredFeatureKey = ""
        requiredFeatureVariation = Invalid

        if (getType(requiredFeature) = "roString")
          requiredFeatureKey = requiredFeature
        else if (requiredFeature <> Invalid)
          requiredFeatureKey = requiredFeature.key
          requiredFeatureVariation = requiredFeature.variation
        end if

        requiredIsEnabled = isEnabled(requiredFeatureKey, context.finalContext)

        if (NOT requiredIsEnabled) then return false

        if (requiredFeatureVariation <> Invalid)
          return (getVariation(requiredFeatureKey, context.finalContext) = requiredFeatureVariation)
        end if

        return true
      end function, { finalContext: finalContext })
      requiredFeaturesAreEnabled = (enabledRequiredFeatures.count() = feature.required.count())

      if (NOT requiredFeaturesAreEnabled)
        return {
          enabled: requiredFeaturesAreEnabled,
          featureKey: feature.key,
          reason: m._featurevisorEvaluationReason.REQUIRED,
        }
      end if
    end if

    ' bucketing
    bucketValue = _getBucketValue(feature, finalContext)
    matchedTraffic = featurevisorGetMatchedTraffic(feature.traffic, finalContext, m._datafileReader)

    if (matchedTraffic <> Invalid)
      ' percentage 0 - always disabled without bucketing
      if (getProperty(matchedTraffic, ["percentage"], -1) = 0)
        return {
          bucketValue: bucketValue,
          enabled: false,
          featureKey: feature.key,
          reason: m._featurevisorEvaluationReason.RULE,
          ruleKey: matchedTraffic.key,
          traffic: matchedTraffic,
        }
      end if

      ' check if mutually exclusive
      if (getProperty(feature, ["ranges"], []).count() > 0)
        matchedRange = m._arrayUtils.find(feature.ranges, function (range as Object, context as Object) as Boolean
          return (context.bucketValue >= range[0]) AND (context.bucketValue < range[1])
        end function, { bucketValue: bucketValue })

        ' matched
        if (matchedRange <> Invalid)
          return {
            bucketValue: bucketValue,
            enabled: getProperty(matchedTraffic, ["enabled"], true),
            featureKey: feature.key,
            reason: m._featurevisorEvaluationReason.ALLOCATED,
          }
        end if

        ' no match
        return {
          bucketValue: bucketValue,
          enabled: false,
          featureKey: feature.key,
          reason: m._featurevisorEvaluationReason.OUT_OF_RANGE,
        }
      end if

      ' override from rule
      if (getProperty(matchedTraffic, ["enabled"]) <> Invalid)
        return {
          bucketValue: bucketValue,
          enabled: matchedTraffic.enabled,
          featureKey: feature.key,
          reason: m._featurevisorEvaluationReason.OVERRIDE,
          ruleKey: matchedTraffic.key,
          traffic: matchedTraffic,
        }
      end if

      ' treated as enabled because of matchefeatured traffic
      if (bucketValue <= getProperty(matchedTraffic, ["percentage"], 0))
        return {
          bucketValue: bucketValue,
          enabled: true,
          featureKey: feature.key,
          reason: m._featurevisorEvaluationReason.RULE,
          ruleKey: matchedTraffic.key,
          traffic: matchedTraffic,
        }
      end if
    end if

    ' nothing matched
    return {
      bucketValue: bucketValue,
      enabled: false,
      featureKey: featureKey,
      reason: m._featurevisorEvaluationReason.NO_MATCH,
    }
  catch error
    m._diagnostics.error("evaluation_error", "evaluateFlag error", { featureKey: featureKey, error: error.message })

    return {
      error: error,
      featureKey: featureKey,
      reason: m._featurevisorEvaluationReason.ERROR,
    }
  end try
end function

function evaluateVariable(featureV as Dynamic, variableKey as String, context = {} as Object, options = {} as Object) as Object
  previousSticky = m._stickyFeatures
  hasStickyOverride = options.__childSticky <> Invalid

  try
    if (hasStickyOverride)
      m._stickyFeatures = options.__childSticky
    end if

    if (getType(featureV) = "roString")
      featureKey = featureV
    else
      featureKey = featureV.key
    end if

    evaluateOptions = _applyBeforeModules(featureKey, context)
    result = _evaluateVariableInternal(evaluateOptions.featureKey, variableKey, evaluateOptions.context)

    if (options.defaultVariableValue <> Invalid AND result.variableValue = Invalid)
      result.variableValue = options.defaultVariableValue
    end if

    result = _applyAfterModules(result, evaluateOptions)
  catch error
    m._diagnostics.error("evaluation_error", "evaluateVariable error", { variableKey: variableKey, error: error.message })
    result = {
      error: error,
      reason: m._featurevisorEvaluationReason.ERROR,
    }
  end try

  if (hasStickyOverride)
    m._stickyFeatures = previousSticky
  end if

  return result
end function

function _evaluateVariableInternal(featureV as Dynamic, variableKey as String, context as Object) as Object
  try
    if (getType(featureV) = "roString")
      featureKey = featureV
    else
      featureKey = featureV.key
    end if

    flag = evaluateFlag(featureKey, context)

    if (flag.enabled = false)
      feature = getFeature(featureKey)
      variableSchema = Invalid

      if (feature <> Invalid)
        if (getType(feature.variablesSchema) = "roAssociativeArray")
          variableSchema = feature.variablesSchema[variableKey]
        else if (getType(feature.variablesSchema) = "roArray")
          variableSchema = m._arrayUtils.find(feature.variablesSchema, { key: variableKey })
        end if
      end if

      if (variableSchema <> Invalid AND variableSchema.disabledValue <> Invalid)
        return {
          enabled: false,
          featureKey: featureKey,
          reason: m._featurevisorEvaluationReason.VARIABLE_DISABLED,
          variableKey: variableKey,
          variableSchema: variableSchema,
          variableValue: variableSchema.disabledValue,
        }
      else if (variableSchema <> Invalid AND getProperty(variableSchema, ["useDefaultWhenDisabled"], false))
        return {
          enabled: false,
          featureKey: featureKey,
          reason: m._featurevisorEvaluationReason.VARIABLE_DEFAULT,
          variableKey: variableKey,
          variableSchema: variableSchema,
          variableValue: variableSchema.defaultValue,
        }
      end if

      return {
        featureKey: featureKey,
        reason: m._featurevisorEvaluationReason.DISABLED,
      }
    end if

    ' sticky
    if (getProperty(m._stickyFeatures, [featureKey, "variables", variableKey]) <> Invalid)
      return {
        featureKey: featureKey,
        reason: m._featurevisorEvaluationReason.STICKY,
        variableKey: variableKey,
        variableValue: getProperty(m._stickyFeatures, [featureKey, "variables", variableKey]),
      }
    end if

    ' initial
    if (NOT m._statuses.ready AND getProperty(m._initialFeatures, [featureKey, "variables", variableKey]) <> Invalid)
      return {
        featureKey: featureKey,
        reason: m._featurevisorEvaluationReason.INITIAL,
        variableKey: variableKey,
        variableValue: getProperty(m._initialFeatures, [featureKey, "variables", variableKey]),
      }
    end if

    feature = getFeature(featureKey)

    ' not found
    if (feature = Invalid)
      m._diagnostics.warn("feature_not_found", "feature not found", { featureKey: featureKey, variableKey: variableKey })

      return {
        featureKey: featureKey,
        reason: m._featurevisorEvaluationReason.FEATURE_NOT_FOUND,
        variableKey: variableKey,
      }
    end if

    variableSchema = Invalid
    if (getType(feature.variablesSchema) = "roAssociativeArray")
      variableSchema = feature.variablesSchema[variableKey]
    else if (getType(feature.variablesSchema) = "roArray")
      variableSchema = m._arrayUtils.find(feature.variablesSchema, { key: variableKey })
    end if

    ' variable schema not found
    if (variableSchema = Invalid)
      m._diagnostics.warn("variable_not_found", "variable schema not found", { featureKey: featureKey, variableKey: variableKey })

      return {
        featureKey: featureKey,
        reason: m._featurevisorEvaluationReason.VARIABLE_NOT_FOUND,
        variableKey: variableKey,
      }
    end if

    ' variable deprecated
    if (getProperty(variableSchema, ["deprecated"], false))
      m._diagnostics.warn("deprecated_variable", "variable is deprecated", { featureKey: featureKey, variableKey: variableKey })
    end if

    finalContext = _interceptContext(context)

    ' forced
    force = featurevisorFindForceFromFeature(feature, context, m._datafileReader)

    if (getProperty(force, ["variables", variableKey]) <> Invalid)
      return {
        featureKey: featureKey,
        reason: m._featurevisorEvaluationReason.FORCED,
        variableKey: variableKey,
        variableSchema: variableSchema,
        variableValue: force.variables[variableKey],
      }
    end if

    ' bucketing
    bucketValue = _getBucketValue(feature, finalContext)
    matched = featurevisorGetMatchedTrafficAndAllocation(feature.traffic, finalContext, bucketValue, m._datafileReader)

    if (matched.matchedTraffic <> Invalid)
      ' override from rule
      ' v2: variableOverrides[variableKey] = [{conditions?, segments?, value}]
      if (getType(getProperty(matched.matchedTraffic, ["variableOverrides"])) = "roAssociativeArray" AND matched.matchedTraffic.variableOverrides[variableKey] <> Invalid)
        ruleOverride = m._arrayUtils.find(matched.matchedTraffic.variableOverrides[variableKey], function (override as Object, context as Object) as Boolean
          if (override.conditions <> Invalid)
            if (getType(override.conditions) = "roString")
              return featurevisorAllConditionsAreMatched(ParseJson(override.conditions), context.finalContext)
            end if

            return featurevisorAllConditionsAreMatched(override.conditions, context.finalContext)
          end if

          if (override.segments <> Invalid)
            parsed = featurevisorParseFromStringifiedSegments(override.segments)

            return featurevisorAllGroupSegmentsAreMatched(parsed, context.finalContext, context.datafileReader)
          end if

          return false
        end function, { datafileReader: m._datafileReader, finalContext: finalContext })

        if (ruleOverride <> Invalid)
          return {
            bucketValue: bucketValue,
            featureKey: featureKey,
            reason: m._featurevisorEvaluationReason.VARIABLE_OVERRIDE_RULE,
            ruleKey: matched.matchedTraffic.key,
            variableKey: variableKey,
            variableSchema: variableSchema,
            variableValue: ruleOverride.value,
          }
        end if
      else if (getProperty(matched.matchedTraffic, ["variables", variableKey]) <> Invalid)
        ' v1: variables is a flat dict {variableKey: value}
        return {
          bucketValue: bucketValue,
          featureKey: featureKey,
          reason: m._featurevisorEvaluationReason.VARIABLE_OVERRIDE_RULE,
          ruleKey: matched.matchedTraffic.key,
          variableKey: variableKey,
          variableSchema: variableSchema,
          variableValue: matched.matchedTraffic.variables[variableKey],
        }
      end if

      ' regular allocation
      variationValue = Invalid
      if (getProperty(force, ["variation"]) <> Invalid)
        variationValue = force.variation
      else if (matched.matchedTraffic.variation <> Invalid)
        variationValue = matched.matchedTraffic.variation
      else if (matched.matchedAllocation <> Invalid AND matched.matchedAllocation.variation <> Invalid)
        variationValue = matched.matchedAllocation.variation
      end if

      if (variationValue <> Invalid AND getType(feature.variations) = "roArray")
        variation = m._arrayUtils.find(feature.variations, { value: variationValue })

        if (variation <> Invalid)
          ' v2: variableOverrides[variableKey] = [{conditions?, segments?, value}]
          if (getType(getProperty(variation, ["variableOverrides"])) = "roAssociativeArray" AND variation.variableOverrides[variableKey] <> Invalid)
            varOverride = m._arrayUtils.find(variation.variableOverrides[variableKey], function (override as Object, context as Object) as Boolean
              if (override.conditions <> Invalid)
                if (getType(override.conditions) = "roString")
                  return featurevisorAllConditionsAreMatched(ParseJson(override.conditions), context.finalContext)
                end if

                return featurevisorAllConditionsAreMatched(override.conditions, context.finalContext)
              end if

              if (override.segments <> Invalid)
                parsed = featurevisorParseFromStringifiedSegments(override.segments)

                return featurevisorAllGroupSegmentsAreMatched(parsed, context.finalContext, context.datafileReader)
              end if

              return false
            end function, { datafileReader: m._datafileReader, finalContext: finalContext })

            if (varOverride <> Invalid)
              return {
                bucketValue: bucketValue,
                featureKey: featureKey,
                reason: m._featurevisorEvaluationReason.VARIABLE_OVERRIDE_VARIATION,
                ruleKey: matched.matchedTraffic.key,
                variableKey: variableKey,
                variableSchema: variableSchema,
                variableValue: varOverride.value,
              }
            end if
          else if (variation.variables <> Invalid)
            if (getType(variation.variables) = "roAssociativeArray")
              ' v2: variation.variables is an object {variableKey: value}
              if (variation.variables[variableKey] <> Invalid)
                return {
                  bucketValue: bucketValue,
                  featureKey: featureKey,
                  reason: m._featurevisorEvaluationReason.ALLOCATED,
                  ruleKey: matched.matchedTraffic.key,
                  variableKey: variableKey,
                  variableSchema: variableSchema,
                  variableValue: variation.variables[variableKey],
                }
              end if
            else if (getType(variation.variables) = "roArray")
              ' v1: variation.variables is an array of {key, value, overrides}
              variableFromVariation = m._arrayUtils.find(variation.variables, { key: variableKey })

              if (variableFromVariation <> Invalid)
                if (variableFromVariation.overrides <> Invalid)
                  override = m._arrayUtils.find(variableFromVariation.overrides, function (override as Object, context as Object) as Boolean
                    if (override.conditions <> Invalid)
                      if (getType(override.conditions) = "roString")
                        return featurevisorAllConditionsAreMatched(ParseJson(override.conditions), context.finalContext)
                      end if

                      return featurevisorAllConditionsAreMatched(override.conditions, context.finalContext)
                    end if

                    if (override.segments <> Invalid)
                      parsed = featurevisorParseFromStringifiedSegments(override.segments)

                      return featurevisorAllGroupSegmentsAreMatched(parsed, context.finalContext, context.datafileReader)
                    end if

                    return false
                  end function, { datafileReader: m._datafileReader, finalContext: finalContext })

                  if (override <> Invalid)
                    return {
                      bucketValue: bucketValue,
                      featureKey: featureKey,
                      reason: m._featurevisorEvaluationReason.OVERRIDE,
                      ruleKey: matched.matchedTraffic.key,
                      variableKey: variableKey,
                      variableSchema: variableSchema,
                      variableValue: override.value,
                    }
                  end if
                end if

                if (variableFromVariation.value <> Invalid)
                  return {
                    bucketValue: bucketValue,
                    featureKey: featureKey,
                    reason: m._featurevisorEvaluationReason.ALLOCATED,
                    ruleKey: matched.matchedTraffic.key,
                    variableKey: variableKey,
                    variableSchema: variableSchema,
                    variableValue: variableFromVariation.value,
                  }
                end if
              end if
            end if
          end if
        end if
      end if
    end if

    ' fall back to default
    return {
      bucketValue: bucketValue,
      featureKey: featureKey,
      reason: m._featurevisorEvaluationReason.VARIABLE_DEFAULT,
      variableKey: variableKey,
      variableSchema: variableSchema,
      variableValue: variableSchema.defaultValue,
    }
  catch error
    m._diagnostics.error("evaluation_error", "evaluateVariable error", { featureKey: featureKey, variableKey: variableKey, error: error.message })

    return {
      error: error,
      featureKey: featureKey,
      reason: m._featurevisorEvaluationReason.ERROR,
      variableKey: variableKey,
    }
  end try
end function

function evaluateVariation(featureV as Dynamic, context = {} as Object, options = {} as Object) as Object
  previousSticky = m._stickyFeatures
  hasStickyOverride = options.__childSticky <> Invalid

  try
    if (hasStickyOverride)
      m._stickyFeatures = options.__childSticky
    end if

    if (getType(featureV) = "roString")
      featureKey = featureV
    else
      featureKey = featureV.key
    end if

    evaluateOptions = _applyBeforeModules(featureKey, context)
    result = _evaluateVariationInternal(evaluateOptions.featureKey, evaluateOptions.context)

    if (options.defaultVariationValue <> Invalid AND result.variationValue = Invalid AND result.variation = Invalid)
      result.variationValue = options.defaultVariationValue
    end if

    result = _applyAfterModules(result, evaluateOptions)
  catch error
    m._diagnostics.error("evaluation_error", "evaluateVariation error", { error: error.message })
    result = {
      error: error,
      reason: m._featurevisorEvaluationReason.ERROR,
    }
  end try

  if (hasStickyOverride)
    m._stickyFeatures = previousSticky
  end if

  return result
end function

function _evaluateVariationInternal(featureV as Dynamic, context as Object) as Object
  try
    if (getType(featureV) = "roString")
      featureKey = featureV
    else
      featureKey = featureV.key
    end if

    flag = evaluateFlag(featureKey, context)

    if (flag.enabled <> Invalid AND NOT flag.enabled)
      feature = getFeature(featureKey)

      if (feature <> Invalid AND feature.disabledVariationValue <> Invalid)
        return {
          enabled: false,
          featureKey: featureKey,
          reason: m._featurevisorEvaluationReason.VARIATION_DISABLED,
          variationValue: feature.disabledVariationValue,
        }
      end if

      return {
        featureKey: featureKey,
        reason: m._featurevisorEvaluationReason.DISABLED,
      }
    end if

    ' sticky
    if (getProperty(m._stickyFeatures, [featureKey, "variation"]) <> Invalid)
      return {
        featureKey: featureKey,
        reason: m._featurevisorEvaluationReason.STICKY,
        variationValue: getProperty(m._stickyFeatures, [featureKey, "variation"]),
      }
    end if

    ' initial
    if (NOT m._statuses.ready AND getProperty(m._initialFeatures, [featureKey, "variation"]) <> Invalid)
      return {
        featureKey: featureKey,
        reason: m._featurevisorEvaluationReason.INITIAL,
        variationValue: getProperty(m._initialFeatures, [featureKey, "variation"]),
      }
    end if

    feature = getFeature(featureKey)

    ' not found
    if (feature = Invalid)
      m._diagnostics.warn("feature_not_found", "feature not found", { featureKey: featureKey })

      return {
        featureKey: featureKey,
        reason: m._featurevisorEvaluationReason.FEATURE_NOT_FOUND,
      }
    end if

    ' no variations
    if (feature.variations = Invalid OR feature.variations.count() = 0)
      m._diagnostics.warn("no_variations", "no variations", { featureKey: featureKey })

      return {
        featureKey: featureKey,
        reason: m._featurevisorEvaluationReason.NO_VARIATIONS,
      }
    end if

    finalContext = _interceptContext(context)

    ' forced
    force = featurevisorFindForceFromFeature(feature, context, m._datafileReader)

    if (force <> Invalid AND force.variation <> Invalid)
      variation = m._arrayUtils.find(feature.variations, { value: force.variation })

      if (variation <> Invalid)
        return {
          featureKey: featureKey,
          reason: m._featurevisorEvaluationReason.FORCED,
          variation: variation,
        }
      end if
    end if

    ' bucketing
    bucketValue = _getBucketValue(feature, finalContext)
    matched = featurevisorGetMatchedTrafficAndAllocation(feature.traffic, finalContext, bucketValue, m._datafileReader)

    if (matched.matchedTraffic <> Invalid)
      ' override from rule
      if (matched.matchedTraffic.variation <> Invalid)
        variation = m._arrayUtils.find(feature.variations, { value: matched.matchedTraffic.variation })

        if (variation <> Invalid)
          return {
            bucketValue: bucketValue,
            featureKey: featureKey,
            reason: m._featurevisorEvaluationReason.RULE,
            ruleKey: matched.matchedTraffic.key,
            variation: variation,
          }
        end if
      end if

      ' regular allocation
      if (getProperty(matched, ["matchedAllocation", "variation"]) <> Invalid)
        variation = m._arrayUtils.find(feature.variations, { value: matched.matchedAllocation.variation })

        if (variation <> Invalid)
          return {
            bucketValue: bucketValue,
            featureKey: featureKey,
            reason: m._featurevisorEvaluationReason.ALLOCATED,
            variation: variation,
          }
        end if
      end if
    end if

    ' nothing matched
    return {
      bucketValue: bucketValue,
      featureKey: featureKey,
      reason: m._featurevisorEvaluationReason.NO_MATCH,
    }
  catch error
    m._diagnostics.error("evaluation_error", "evaluateVariation error", { featureKey: featureKey, error: error.message })

    return {
      error: error,
      featureKey: featureKey,
      reason: m._featurevisorEvaluationReason.ERROR,
    }
  end try
end function

function getFeature(feature as Dynamic) as Object
  if (getType(feature) = "roString")
    return m._datafileReader.getFeature(feature)
  end if

  return feature
end function

function getRevision() as String
  if (m._datafileReader = Invalid) then return ""

  return m._datafileReader.getRevision()
end function

function getSchemaVersion() as String
  if (m._datafileReader = Invalid) then return ""

  return m._datafileReader.getSchemaVersion()
end function

function getSegment(segmentKey as String) as Object
  if (m._datafileReader = Invalid) then return Invalid

  return m._datafileReader.getSegment(segmentKey)
end function

function getFeatureKeys() as Object
  if (m._datafileReader = Invalid) then return []

  return m._datafileReader.getFeatureKeys()
end function

function getVariableKeys(featureKey as String) as Object
  if (m._datafileReader = Invalid) then return []

  return m._datafileReader.getVariableKeys(featureKey)
end function

function hasVariations(featureKey as String) as Boolean
  if (m._datafileReader = Invalid) then return false

  return m._datafileReader.hasVariations(featureKey)
end function

function getVariable(feature as Dynamic, variableKey as String, context = {} as Object, options = {} as Object) as Dynamic
  try
    evaluation = evaluateVariable(feature, variableKey, context, options)

    if (evaluation.variableValue <> Invalid)
      if (getType(evaluation.variableValue) = "roString" AND getProperty(evaluation, ["variableSchema", "type"], "") = "json")
        return ParseJson(evaluation.variableValue)
      end if

      return evaluation.variableValue
    end if

    return Invalid
  catch error
    m._diagnostics.error("evaluation_error", "getVariable error", { feature: feature, error: error.message })

    return Invalid
  end try
end function

function getVariableArray(feature as Dynamic, variableKey as String, context = {} as Object, options = {} as Object) as Dynamic
  variableValue = getVariable(feature, variableKey, context, options)

  return _getValueByType(variableValue, "array")
end function

function getVariableBoolean(feature as Dynamic, variableKey as String, context = {} as Object, options = {} as Object) as Dynamic
  variableValue = getVariable(feature, variableKey, context, options)

  return _getValueByType(variableValue, "boolean")
end function

function getVariableDouble(feature as Dynamic, variableKey as String, context = {} as Object, options = {} as Object) as Dynamic
  variableValue = getVariable(feature, variableKey, context, options)

  return _getValueByType(variableValue, "double")
end function

function getVariableInteger(feature as Dynamic, variableKey as String, context = {} as Object, options = {} as Object) as Dynamic
  variableValue = getVariable(feature, variableKey, context, options)

  return _getValueByType(variableValue, "integer")
end function

function getVariableJSON(feature as Dynamic, variableKey as String, context = {} as Object, options = {} as Object) as Dynamic
  variableValue = getVariable(feature, variableKey, context, options)

  return _getValueByType(variableValue, "json")
end function

function getVariableObject(feature as Dynamic, variableKey as String, context = {} as Object, options = {} as Object) as Dynamic
  variableValue = getVariable(feature, variableKey, context, options)

  return _getValueByType(variableValue, "object")
end function

function getVariableString(feature as Dynamic, variableKey as String, context = {} as Object, options = {} as Object) as Dynamic
  variableValue = getVariable(feature, variableKey, context, options)

  return _getValueByType(variableValue, "string")
end function

function getVariation(feature as Dynamic, context = {} as Object, options = {} as Object) as Dynamic
  try
    evaluation = evaluateVariation(feature, context, options)
    result = Invalid

    if (evaluation.variationValue <> Invalid)
      result = evaluation.variationValue
    else if (evaluation.variation <> Invalid)
      result = evaluation.variation.value
    end if

    return result
  catch error
    m._diagnostics.error("evaluation_error", "getVariation error", { feature: feature, error: error.message })

    return Invalid
  end try
end function

function isEnabled(featureKey as String, context = {} as Object, options = {} as Object) as Boolean
  try
    evaluation = getProperty(evaluateFlag(featureKey, context, options), ["enabled"], false)

    if (getType(evaluation) = "roBoolean") then return evaluation

    return false
  catch error
    m._diagnostics.error("evaluation_error", "isEnabled error", { featureKey: featureKey, error: error.message })

    return false
  end try
end function

sub refresh()
  if (m._statuses.refreshInProgress)
    m._diagnostics.warn("refresh_in_progress", "refresh already in progress, skipping")

    return
  end if

  if (m._datafileUrl = Invalid OR m._datafileUrl = "")
    m._diagnostics.warn("refresh_not_configured", "cannot refresh since `datafileUrl` is not provided")

    return
  end if

  m._statuses.refreshInProgress = true

  chain = createRequest("FeaturevisorRequest", { datafileUrl: m._datafileUrl })
  chain = chain.then(function (datafile as Object)
    previousRevisionNumber = getRevision()
    setDatafile(datafile, true)

    return {
      previousRevisionNumber: previousRevisionNumber,
      datafile: datafile,
    }
  end function, sub (error as Object)
    m._diagnostics.error("datafile_fetch_error", "failed to refresh datafile", { error: error })
  end sub)
  chain = chain.then(sub (data as Object, m as Object)
    if (data = Invalid) then return

    m.top.refreshed = {}

    if (data.previousRevisionNumber <> data.datafile.revision)
      m.top.updated = {}
    end if
  end sub, Invalid, m)
  chain.finally(sub (_data as Object, m as Object)
    m._statuses.refreshInProgress = false
  end sub, m)
end sub

sub setDatafile(datafile as Dynamic, replace = false as Boolean)
  if (m._closed) then return

  try
    datafileScoped = datafile
    if (getType(datafileScoped) = "roString")
      datafileScoped = ParseJson(datafileScoped)
    end if

    if (_datafileMergeIsPossible(m._datafile, datafileScoped) AND NOT replace)
      datafileScoped = _mergeDatafile(m._datafile, datafileScoped)
    end if

    previousRevision = ""
    previousFeatureKeys = []
    oldReader = m._datafileReader
    if (oldReader <> Invalid)
      previousRevision = oldReader.getRevision()
      previousFeatureKeys = oldReader.getFeatureKeys()
    end if

    newReader = FeaturevisorDatafileReader(datafileScoped)
    m._datafile = datafileScoped
    m._datafileReader = newReader
    m._readerHolder.reader = newReader

    newRevision = newReader.getRevision()
    newFeatureKeys = newReader.getFeatureKeys()

    addedFeatures = m._arrayUtils.filter(newFeatureKeys, function (featureKey as String, context as Object) as Boolean
      return NOT m._arrayUtils.contains(context.previousFeatureKeys, function (existing as String, innerContext as Object) as Boolean
        return existing = innerContext.featureKey
      end function, { featureKey: featureKey })
    end function, { previousFeatureKeys: previousFeatureKeys })

    removedFeatures = m._arrayUtils.filter(previousFeatureKeys, function (featureKey as String, context as Object) as Boolean
      return NOT m._arrayUtils.contains(context.newFeatureKeys, function (existing as String, innerContext as Object) as Boolean
        return existing = innerContext.featureKey
      end function, { featureKey: featureKey })
    end function, { newFeatureKeys: newFeatureKeys })

    changedFeatures = m._arrayUtils.filter(newFeatureKeys, function (featureKey as String, context as Object) as Boolean
      if (context.oldReader = Invalid) then return false

      existsInPrevious = m._arrayUtils.contains(context.previousFeatureKeys, function (existing as String, innerContext as Object) as Boolean
        return existing = innerContext.featureKey
      end function, { featureKey: featureKey })
      if (NOT existsInPrevious) then return false

      newFeature = context.newReader.getFeature(featureKey)
      oldFeature = context.oldReader.getFeature(featureKey)
      if (newFeature = Invalid OR oldFeature = Invalid) then return false

      newHash = getProperty(newFeature, ["hash"], Invalid)
      oldHash = getProperty(oldFeature, ["hash"], Invalid)
      if (newHash = Invalid OR oldHash = Invalid) then return false

      return newHash <> oldHash
    end function, { previousFeatureKeys: previousFeatureKeys, newReader: newReader, oldReader: oldReader })

    allChangedFeatures = []
    for each featureKey in addedFeatures
      allChangedFeatures.push(featureKey)
    end for
    for each featureKey in removedFeatures
      allChangedFeatures.push(featureKey)
    end for
    for each featureKey in changedFeatures
      allChangedFeatures.push(featureKey)
    end for

    m.top.datafileChange = {
      features: allChangedFeatures,
      previousRevision: previousRevision,
      replaced: replace,
      revision: newRevision,
      revisionChanged: previousRevision <> newRevision,
    }

    m._diagnostics.info("datafile_set", "datafile set", {
      features: allChangedFeatures,
      previousRevision: previousRevision,
      replaced: replace,
      revision: newRevision,
      revisionChanged: previousRevision <> newRevision,
    })
  catch error
    m._diagnostics.error("invalid_datafile", "could not parse datafile", { error: error.message })
  end try
end sub

function _datafileMergeIsPossible(storedDatafile as Dynamic, incomingDatafile as Dynamic) as Boolean
  if (storedDatafile = Invalid OR incomingDatafile = Invalid) then return false
  if (getType(getProperty(storedDatafile, ["features"])) = "roArray" OR getType(getProperty(storedDatafile, ["segments"])) = "roArray") then return false
  if (getType(getProperty(incomingDatafile, ["features"])) = "roArray" OR getType(getProperty(incomingDatafile, ["segments"])) = "roArray") then return false

  return true
end function

function _mergeDatafile(storedDatafile as Object, incomingDatafile as Object) as Object
  merged = {
    schemaVersion: incomingDatafile.schemaVersion,
    revision: incomingDatafile.revision,
    attributes: getProperty(incomingDatafile, ["attributes"], getProperty(storedDatafile, ["attributes"], [])),
    segments: {},
    features: {},
  }

  if (incomingDatafile.featurevisorVersion <> Invalid)
    merged.featurevisorVersion = incomingDatafile.featurevisorVersion
  end if

  for each key in getProperty(storedDatafile, ["segments"], {})
    merged.segments[key] = storedDatafile.segments[key]
  end for
  for each key in getProperty(incomingDatafile, ["segments"], {})
    merged.segments[key] = incomingDatafile.segments[key]
  end for
  for each key in getProperty(storedDatafile, ["features"], {})
    merged.features[key] = storedDatafile.features[key]
  end for
  for each key in getProperty(incomingDatafile, ["features"], {})
    merged.features[key] = incomingDatafile.features[key]
  end for

  return merged
end function

sub setContext(context as Object, replace = false as Boolean)
  if (m._closed) then return

  if (replace)
    m._instanceContext = context
  else
    if (m._instanceContext = Invalid)
      m._instanceContext = {}
    end if

    for each key in context
      m._instanceContext[key] = context[key]
    end for
  end if

  m.top.contextChange = {
    context: m._instanceContext,
    replaced: replace,
  }

  m._diagnostics.debug("context_set", "context set", { replaced: replace })
end sub

function getContext(context = {} as Object) as Object
  merged = {}

  if (m._instanceContext <> Invalid)
    for each key in m._instanceContext
      merged[key] = m._instanceContext[key]
    end for
  end if

  for each key in context
    merged[key] = context[key]
  end for

  return merged
end function

function getAllEvaluations(context = {} as Object, featureKeys = [] as Object, options = {} as Object) as Object
  result = {}

  keys = featureKeys
  if (keys.count() = 0 AND m._datafileReader <> Invalid)
    keys = m._datafileReader.getFeatureKeys()
  end if

  for each featureKey in keys
    evaluatedFeature = {
      enabled: isEnabled(featureKey, context, options),
    }

    feature = getFeature(featureKey)

    if (feature <> Invalid AND feature.variations <> Invalid AND feature.variations.count() > 0)
      variation = getVariation(featureKey, context, options)

      if (variation <> Invalid)
        evaluatedFeature.variation = variation
      end if
    end if

    variableKeys = []

    if (feature <> Invalid AND feature.variablesSchema <> Invalid)
      if (getType(feature.variablesSchema) = "roAssociativeArray")
        for each key in feature.variablesSchema
          variableKeys.push(key)
        end for
      else if (getType(feature.variablesSchema) = "roArray")
        for each schema in feature.variablesSchema
          variableKeys.push(schema.key)
        end for
      end if
    end if

    if (variableKeys.count() > 0)
      evaluatedFeature.variables = {}

      for each variableKey in variableKeys
        evaluatedFeature.variables[variableKey] = getVariable(featureKey, variableKey, context, options)
      end for
    end if

    result[featureKey] = evaluatedFeature
  end for

  return result
end function

sub setSticky(stickyFeatures as Object, replace = false as Boolean)
  if (m._closed) then return

  featureKeys = {}
  if (m._stickyFeatures <> Invalid)
    for each key in m._stickyFeatures
      featureKeys[key] = true
    end for
  end if
  for each key in stickyFeatures
    featureKeys[key] = true
  end for

  features = []
  for each key in featureKeys
    features.push(key)
  end for

  if (replace)
    m._stickyFeatures = stickyFeatures
  else
    if (m._stickyFeatures = Invalid)
      m._stickyFeatures = {}
    end if

    for each key in stickyFeatures
      m._stickyFeatures[key] = stickyFeatures[key]
    end for
  end if

  m.top.stickyChange = { features: features, replaced: replace }

  m._diagnostics.info("sticky_set", "sticky features set", { features: features, replaced: replace })
end sub

' @deprecated Use setSticky instead
sub setStickyFeatures(stickyFeatures as Object)
  setSticky(stickyFeatures, true)
end sub

sub startRefreshing()
  if (m._datafileUrl = Invalid)
    m._diagnostics.warn("refresh_not_configured", "cannot start refreshing since `datafileUrl` is not provided")

    return
  end if

  if (m._intervalId <> Invalid)
    m._diagnostics.warn("refresh_already_started", "refreshing has already started")

    return
  end if

  if (m._refreshInterval = Invalid OR m._refreshInterval <= 0)
    m._diagnostics.warn("refresh_not_configured", "no `refreshInterval` option provided")

    return
  end if

  m._intervalId = setInterval(refresh, m._refreshInterval)
end sub

sub stopRefreshing()
  clearInterval(m._intervalId)

  m._intervalId = Invalid
end sub

function _getValueByType(value as Dynamic, fieldType as String) as Dynamic
  try
    if (value = Invalid) then return Invalid

    if (fieldType = "string")
      if (getType(value) = "roString") then return value

      return Invalid
    else if (fieldType = "integer")
      if (getType(value) = "roInt" OR getType(value) = "LongInteger") then return value
      if ((getType(value) = "roFloat" OR getType(value) = "Double") AND value = Int(value)) then return Int(value)

      return Invalid
    else if (fieldType = "double")
      if (getType(value) = "roInt" OR getType(value) = "LongInteger" OR getType(value) = "roFloat" OR getType(value) = "Double") then return value

      return Invalid
    else if (fieldType = "boolean")
      if (getType(value) = "roBoolean") then return value

      return Invalid
    else if (fieldType = "array")
      if (getType(value) = "roArray") then return value

      return Invalid
    else if (fieldType = "object")
      if (getType(value) = "roAssociativeArray") then return value

      return Invalid
    else
      return value
    end if
  catch _error
    m._diagnostics.error("evaluation_error", "could not get value by type")
  end try
end function

function _callModule(module as Object, key as String, arg1 = Invalid as Dynamic, arg2 = Invalid as Dynamic) as Dynamic
  func = module[key]

  if (func = Invalid OR getType(func) <> "roFunction") then return Invalid

  if (module.context <> Invalid)
    module.context["$$module"] = func
    if (arg2 <> Invalid)
      result = module.context["$$module"](arg1, arg2)
    else
      result = module.context["$$module"](arg1)
    end if
    module.context.delete("$$module")
  else
    m["$$module"] = func
    if (arg2 <> Invalid)
      result = m["$$module"](arg1, arg2)
    else
      result = m["$$module"](arg1)
    end if
    m.delete("$$module")
  end if

  return result
end function

sub _closeModule(entry as Object)
  try
    _callModule(entry.module, "close")
  catch error
    m._diagnostics.error("module_close_error", "module close failed", { name: getProperty(entry.module, ["name"], ""), error: error.message })
  end try
end sub

function _getModuleApi(moduleId as String, module as Object) as Object
  return {
    _diagnostics: m._diagnostics,
    _moduleId: moduleId,
    _moduleName: getProperty(module, ["name"], ""),
    _readerHolder: m._readerHolder,
    getRevision: function () as String
      if (m._readerHolder.reader = Invalid) then return ""

      return m._readerHolder.reader.getRevision()
    end function,
    onDiagnostic: function (handler as Function, options = {} as Object) as Object
      subscriptionId = m._diagnostics.subscribe(m._moduleId, handler, getProperty(options, ["context"]), getProperty(options, ["logLevel"], "info"))
      return {
        _diagnostics: m._diagnostics,
        _subscriptionId: subscriptionId,
        unsubscribe: sub ()
          m._diagnostics.unsubscribe(m._subscriptionId)
        end sub,
      }
    end function,
    reportDiagnostic: sub (diagnostic as Object)
      scoped = {}
      for each key in diagnostic
        scoped[key] = diagnostic[key]
      end for

      if (m._moduleName <> "")
        scoped.module = m._moduleName
      end if
      scoped["_sourceModuleId"] = m._moduleId

      m._diagnostics.report(scoped)
    end sub,
  }
end function

function _applyBeforeModules(featureKey as String, context as Object) as Object
  evaluateOptions = { featureKey: featureKey, context: context }

  for each entry in m._modulesManager.getAll()
    result = _callModule(entry.module, "before", evaluateOptions)
    if (result <> Invalid) then evaluateOptions = result
  end for

  return evaluateOptions
end function

function _applyAfterModules(result as Object, evaluateOptions as Object) as Object
  for each entry in m._modulesManager.getAll()
    updated = _callModule(entry.module, "after", result, evaluateOptions)
    if (updated <> Invalid) then result = updated
  end for

  return result
end function

function _getBucketValue(feature as Object, finalContext as Object) as Integer
  bucketKey = _getBucketKey(feature, finalContext)
  bucketValue = featurevisorGetBucketedNumber(bucketKey)
  bucketValue = _configureBucketValue(feature, finalContext, bucketValue)

  for each entry in m._modulesManager.getAll()
    updated = _callModule(entry.module, "bucketValue", { feature: feature, featureKey: getProperty(feature, ["key"], ""), bucketBy: feature.bucketBy, context: finalContext, bucketValue: bucketValue })
    if (updated <> Invalid) then bucketValue = updated
  end for

  return bucketValue
end function

function _getBucketKey(feature as Object, context as Object) as String
  featureKey = getProperty(feature, "key", "")

  if (feature = Invalid OR featureKey = "") then return ""

  attributeKeys = []
  bucketType = ""

  if (getType(feature.bucketBy) = "roString")
    attributeKeys = [feature.bucketBy]
    bucketType = "plain"
  else if (getType(feature.bucketBy) = "roArray")
    attributeKeys = feature.bucketBy
    bucketType = "and"
  else if (getType(feature.bucketBy) = "roAssociativeArray" AND getType(feature.bucketBy["or"]) = "roArray")
    attributeKeys = feature.bucketBy["or"]
    bucketType = "or"
  else
    m._diagnostics.error("invalid_bucket_by", "invalid bucketBy", { featureKey: featureKey, bucketBy: feature.bucketBy })

    return ""
  end if

  bucketKey = []

  for each attributeKey in attributeKeys
    attributeValue = context[attributeKey]

    if (attributeValue <> Invalid)
      if (bucketType = "plain" OR bucketType = "and")
        bucketKey.push(attributeValue)
      else if (bucketKey.count() = 0)
        bucketKey.push(attributeValue)
      end if
    end if
  end for

  bucketKey.push(featureKey)

  bucketKeyResult = _configureBucketKey(feature, context, bucketKey.join(m._bucketKeySeparator))

  for each entry in m._modulesManager.getAll()
    updated = _callModule(entry.module, "bucketKey", { feature: feature, featureKey: featureKey, bucketBy: feature.bucketBy, context: context, bucketKey: bucketKeyResult })
    if (updated <> Invalid) then bucketKeyResult = updated
  end for

  return bucketKeyResult
end function

function _configureBucketKey(feature as Dynamic, context as Object, bucketKey as String) as String
  return _callFunction(m._configureBucketKey, [feature, context, bucketKey], bucketKey)
end function

function _configureBucketValue(feature as Dynamic, context as Object, bucketValue as Integer) as Integer
  return _callFunction(m._configureBucketValue, [feature, context, bucketValue], bucketValue)
end function

function _interceptContext(context as Object) as Object
  merged = {}

  if (m._instanceContext <> Invalid)
    for each key in m._instanceContext
      merged[key] = m._instanceContext[key]
    end for
  end if

  for each key in context
    merged[key] = context[key]
  end for

  return _callFunction(m._interceptContext, [merged], merged)
end function

function _callFunction(func as Dynamic, args = [] as Object, defaultValue = Invalid as Dynamic) as Dynamic
  if (func = Invalid OR getType(func) <> "roFunction") then return defaultValue

  if (m._configureAndInterceptStaticContext <> Invalid)
    return functionCall(func, args, m._configureAndInterceptStaticContext)
  end if

  return functionCall(func, args)
end function
