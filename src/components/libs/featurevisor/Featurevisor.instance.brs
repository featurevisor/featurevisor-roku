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
' @import /components/libs/featurevisor/FeaturevisorEvaluationReason.const.brs
' @import /components/libs/featurevisor/FeaturevisorFeature.brs
' @import /components/libs/featurevisor/FeaturevisorSegments.brs

sub init()
  m._DEFAULT_BUCKET_KEY_SEPARATOR = "."

  m._arrayUtils = ArrayUtils()
  m._featurevisorEvaluationReason = FeaturevisorEvaluationReason()
  m._statuses = {
    ready: false,
    refreshInProgress: false,
  }

  m._bucketKeySeparator = m._DEFAULT_BUCKET_KEY_SEPARATOR
  m._configureAndInterceptStaticContext = Invalid
  m._configureBucketKey = Invalid
  m._configureBucketValue = Invalid
  m._datafileReader = Invalid
  m._datafileUrl = ""
  m._initialFeatures = Invalid
  m._interceptContext = Invalid
  m._refreshInterval = 0
  m._stickyFeatures = Invalid
end sub

sub initialize(options = {} as Object)
  m._bucketKeySeparator = getProperty(options, ["bucketKeySeparator"], m._DEFAULT_BUCKET_KEY_SEPARATOR)
  m._configureAndInterceptStaticContext = getProperty(options, ["configureAndInterceptStaticContext"], m._configureAndInterceptStaticContext)
  m._configureBucketKey = getProperty(options, ["configureBucketKey"], m._configureBucketKey)
  m._configureBucketValue = getProperty(options, ["configureBucketValue"], m._configureBucketValue)
  m._datafileUrl = getProperty(options, ["datafileUrl"], m._datafileUrl)
  m._initialFeatures = getProperty(options, ["initialFeatures"], m._initialFeatures)
  m._interceptContext = getProperty(options, ["interceptContext"], m._interceptContext)
  m._refreshInterval = getProperty(options, ["refreshInterval"], m._refreshInterval)
  m._stickyFeatures = getProperty(options, ["stickyFeatures"], m._stickyFeatures)

  if (NOT m._statuses.ready AND m._datafileUrl <> "")
    m._datafileReader = Invalid
    datafile = getProperty(options, ["datafile"], {
      schemaVersion: "1",
      revision: "unknown",
      attributes: [],
      segments: [],
      features: [],
    })
    setDatafile(datafile)

    chain = createRequest("FeaturevisorRequest", { datafileUrl: m._datafileUrl })
    chain.then(sub (datafile as Object, m as Object)
      setDatafile(datafile)

      m._statuses.ready = true
      m.top.ready = {}

      if (m._refreshInterval <> 0)
        startRefreshing()
      end if
    end sub, sub (error as Object, _m as Object)
      print "Featurevisor - failed to reffetchresh datafile: ";error
    end sub, m)
    chain.finally(sub (_data as Object, m as Object)
      m._statuses.refreshInProgress = false
    end sub, m)
  else if (options.datafile <> Invalid)
    m._datafileReader = Invalid
    setDatafile(options.datafile)

    m._statuses.ready = true
    m.top.ready = {}
  else
    print "Featurevisor instance cannot be initialized without `datafile` or `datafileUrl` option";error
  end if
end sub

sub clear()
  m._bucketKeySeparator = m._DEFAULT_BUCKET_KEY_SEPARATOR
  m._configureAndInterceptStaticContext = Invalid
  m._configureBucketKey = Invalid
  m._configureBucketValue = Invalid
  m._datafileReader = Invalid
  m._datafileUrl = ""
  m._initialFeatures = Invalid
  m._interceptContext = Invalid
  m._refreshInterval = 0
  m._statuses = {
    ready: false,
    refreshInProgress: false,
  }
  m._stickyFeatures = Invalid
end sub

function activate(feature as Dynamic, context = {} as Object) as Object
  try
    evaluation = evaluateVariation(feature, context)
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
    print "Featurevisor - activate - featureKey: ";featureKey
    _printError("Featurevisor - activate - error", error)

    return Invalid
  end try
end function

function evaluateFlag(featureKey as String, context = {} as Object) as Object
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
      return {
        featureKey: featureKey,
        reason: m._featurevisorEvaluationReason.NOT_FOUND,
      }
    end if

    ' deprecated
    if (getProperty(feature, ["deprecated"], false))
      print "Featurevisor - feature is deprecated"
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
    _printError("Featurevisor - evaluateFlag - error", error)

    return {
      error: error,
      featureKey: featureKey,
      reason: m._featurevisorEvaluationReason.ERROR,
    }
  end try
end function

function evaluateVariable(featureV as Dynamic, variableKey as String, context = {} as Object) as Object
  try
    if (getType(featureV) = "roString")
      featureKey = featureV
    else
      featureKey = featureV.key
    end if

    flag = evaluateFlag(featureKey, context)

    if (flag.enabled = false)
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
      return {
        featureKey: featureKey,
        reason: m._featurevisorEvaluationReason.NOT_FOUND,
        variableKey: variableKey,
      }
    end if

    variableSchema = Invalid
    if (getType(feature.variablesSchema) = "roArray")
      variableSchema = m._arrayUtils.find(feature.variablesSchema, { key: variableKey })
    end if

    ' variable schema not found
    if (variableSchema = Invalid)
      return {
        featureKey: featureKey,
        reason: m._featurevisorEvaluationReason.NOT_FOUND,
        variableKey: variableKey,
      }
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
      if (getProperty(matched.matchedTraffic, ["variables", variableKey]) <> Invalid)
        return {
          bucketValue: bucketValue,
          featureKey: featureKey,
          reason: m._featurevisorEvaluationReason.RULE,
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
      else if (matched.matchedAllocation <> Invalid AND matched.matchedAllocation.variation <> Invalid)
        variationValue = matched.matchedAllocation.variation
      end if

      if (variationValue <> Invalid AND getType(feature.variations) = "roArray")
        variation = m._arrayUtils.find(feature.variations, { value: variationValue })

        if (variation <> Invalid AND variation.variables <> Invalid)
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

    ' fall back to default
    return {
      bucketValue: bucketValue,
      featureKey: featureKey,
      reason: m._featurevisorEvaluationReason.DEFAULTED,
      variableKey: variableKey,
      variableSchema: variableSchema,
      variableValue: variableSchema.defaultValue,
    }
  catch error
    _printError("Featurevisor - evaluateVariable - error", error)

    return {
      error: error,
      featureKey: featureKey,
      reason: m._featurevisorEvaluationReason.ERROR,
      variableKey: variableKey,
    }
  end try
end function

function evaluateVariation(featureV as Dynamic, context = {} as Object) as Object
  try
    if (getType(featureV) = "roString")
      featureKey = featureV
    else
      featureKey = featureV.key
    end if

    flag = evaluateFlag(featureKey, context)

    if (flag.enabled <> Invalid AND NOT flag.enabled)
      return {
        featureKey: featureKey,
        reason: m._featurevisorEvaluationReason.DISABLED,
      }
    end if

    ' sticky
    if (getProperty(m._stickyFeatures, [featureKey, "variation"]) <> Invalid)
      variationValue = m._stickyFeatures[featureKey].variation
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
      return {
        featureKey: featureKey,
        reason: m._featurevisorEvaluationReason.NOT_FOUND,
      }
    end if

    ' no variations
    if (feature.variations = Invalid OR feature.variations.count() = 0)
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
    _printError("Featurevisor - evaluateVariation - error", error)

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
  return m._datafileReader.getRevision()
end function

function getVariable(feature as Dynamic, variableKey as String, context = {} as Object) as Dynamic
  try
    evaluation = evaluateVariable(feature, variableKey, context)

    if (evaluation.variableValue <> Invalid)
      if (getType(evaluation.variableValue) = "roString" AND getProperty(evaluation, ["variableSchema", "type"], "") = "json")
        return ParseJson(evaluation.variableValue)
      end if

      return evaluation.variableValue
    end if

    return Invalid
  catch error
    print "Featurevisor - getVariable - featureKey: ";featureKey
    _printError("Featurevisor - getVariable - error", error)

    return Invalid
  end try
end function

function getVariableArray(feature as Dynamic, variableKey as String, context = {} as Object) as Dynamic
  variableValue = getVariable(feature, variableKey, context)

  return _getValueByType(variableValue, "array")
end function

function getVariableBoolean(feature as Dynamic, variableKey as String, context = {} as Object) as Dynamic
  variableValue = getVariable(feature, variableKey, context)

  return _getValueByType(variableValue, "boolean")
end function

function getVariableDouble(feature as Dynamic, variableKey as String, context = {} as Object) as Dynamic
  variableValue = getVariable(feature, variableKey, context)

  return _getValueByType(variableValue, "double")
end function

function getVariableInteger(feature as Dynamic, variableKey as String, context = {} as Object) as Dynamic
  variableValue = getVariable(feature, variableKey, context)

  return _getValueByType(variableValue, "integer")
end function

function getVariableJSON(feature as Dynamic, variableKey as String, context = {} as Object) as Dynamic
  variableValue = getVariable(feature, variableKey, context)

  return _getValueByType(variableValue, "json")
end function

function getVariableObject(feature as Dynamic, variableKey as String, context = {} as Object) as Dynamic
  variableValue = getVariable(feature, variableKey, context)

  return _getValueByType(variableValue, "object")
end function

function getVariableString(feature as Dynamic, variableKey as String, context = {} as Object) as Dynamic
  variableValue = getVariable(feature, variableKey, context)

  return _getValueByType(variableValue, "string")
end function

function getVariation(feature as Dynamic, context = {} as Object) as Dynamic
  try
    evaluation = evaluateVariation(feature, context)

    if (evaluation.variationValue <> Invalid) then return evaluation.variationValue
    if (evaluation.variation <> Invalid) then return evaluation.variation.value

    return Invalid
  catch error
    print "Featurevisor - getVariation - featureKey: ";featureKey
    _printError("Featurevisor - getVariation - error", error)

    return Invalid
  end try
end function

function isEnabled(featureKey as String, context = {} as Object) as Boolean
  try
    evaluation = getProperty(evaluateFlag(featureKey, context), ["enabled"], false)

    if (getType(evaluation) = "roBoolean") then return evaluation

    return false
  catch error
    print "Featurevisor - isEnabled - featureKey: ";featureKey
    _printError("Featurevisor - isEnabled - error", error)

    return false
  end try
end function

sub refresh()
  if (m._statuses.refreshInProgress)
    print "Featurevisor - refresh in progress, skipping"
  end if

  if (m._datafileUrl = Invalid)
    print "Featurevisor - cannot refresh since `datafileUrl` is not provided"
  end if

  m._statuses.refreshInProgress = true

  chain = createRequest("FeaturevisorRequest", { datafileUrl: m._datafileUrl })
  chain.then(function (datafile as Object)
    previousRevisionNumber = getRevision()
    setDatafile(datafile)

    return {
      previousRevisionNumber: previousRevisionNumber,
      datafile: datafile,
    }
  end function, sub (error as Object)
    print "Featurevisor - failed to refresh datafile: ";error
  end sub).then(sub (data as Object, m as Object)
    m.top.refreshed = {}

    if (data.previousRevisionNumber <> data.datafile.revision)
      m.top.updated = {}
    end if
  end sub, Invalid, m)
  chain.finally(sub (_data as Object, m as Object)
    m._statuses.refreshInProgress = false
  end sub, m)
end sub

sub setDatafile(datafile as Dynamic)
  try
    datafileScoped = datafile
    if (getType(datafileScoped) = "roString")
      datafileScoped = ParseJson(datafileScoped)
    end if

    m._datafileReader = FeaturevisorDatafileReader(datafileScoped)
  catch error
    _printError("Featurevisor - could not parse datafile", error)
  end try
end sub

sub setStickyFeatures(stickyFeatures as Object)
  m._stickyFeatures = stickyFeatures
end sub

sub startRefreshing()
  if (m._datafileUrl = Invalid)
    print "Featurevisor - cannot start refreshing since `datafileUrl` is not provided"

    return
  end if

  if (m._intervalId <> Invalid)
    print "Featurevisor - refreshing has already started"

    return
  end if

  if (m._refreshInterval = Invalid OR m._refreshInterval <= 0)
    print "Featurevisor - no `refreshInterval` option provided"

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
      if (getType(value) = "roString") then return value.toInt()

      return Invalid
    else if (fieldType = "double")
      if (getType(value) = "roFloat" OR getType(value) = "Double") then return value
      if (getType(value) = "roString") then return value.toFloat()

      return Invalid
    else if (fieldType = "boolean")
      if (getType(value) = "roBoolean") then return value
      if (getType(value) = "roString" AND LCase(value) = "true") then return true
      if (getType(value) = "roString" AND LCase(value) = "false") then return false

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
    print "Featurevisor - couldn't get value by it's type"
  end try
end function

function _getBucketValue(feature as Object, finalContext as Object) as Integer
  bucketKey = _getBucketKey(feature, finalContext)
  bucketValue = featurevisorGetBucketedNumber(bucketKey)

  return _configureBucketValue(feature, finalContext, bucketValue)
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
    print "Featurevisor - invalid bucketBy - featureKey: ";featureKey
    print "Featurevisor - invalid bucketBy - bucketBy: ";feature.bucketBy

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

  return _configureBucketKey(feature, context, bucketKey.join(m._bucketKeySeparator))
end function

function _configureBucketKey(feature as Dynamic, context as Object, bucketKey as String) as String
  return _callFunction(m._configureBucketKey, [feature, context, bucketKey], bucketKey)
end function

function _configureBucketValue(feature as Dynamic, context as Object, bucketValue as Integer) as Integer
  return _callFunction(m._configureBucketValue, [feature, context, bucketValue], bucketValue)
end function

function _interceptContext(context as Object) as Object
  return _callFunction(m._interceptContext, [context], context)
end function

function _callFunction(func as Dynamic, args = [] as Object, defaultValue = Invalid as Dynamic) as Dynamic
  if (func = Invalid OR getType(func) <> "roFunction") then return defaultValue

  if (m._configureAndInterceptStaticContext <> Invalid)
    return functionCall(func, args, m._configureAndInterceptStaticContext)
  end if

  return functionCall(func, args)
end function

sub _printError(message as String, error as Object)
  print message;" - error.message: ";error.message
  for each backtrace in error.backtrace
    print message;" - error.backtrace: ";backtrace
  end for
end sub

