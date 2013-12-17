parser = require '../toolkit-parser'
SchemaValidator = require('jsonschema').Validator

class Validation
  constructor: (@req, @resource) ->

  isValid: () =>
    return false if @resource.uriParameters? and not @validateUriParams()
    method = @getMethod()
    if method?
      false unless @validateSchema method
      return false if method.queryParameters? and not @validateQueryParams method
      return false if method.headers? and not @validateHeaders method
      return false if @isForm() and not @validateFormParams method
    true

  isForm: () =>
    @req.headers['content-type'] in ['application/x-www-form-urlencoded', 'multipart/form-data']

  isJson: () =>
    @req.headers['content-type'] == 'application/json' or @req.headers['content-type'].endsWith '+json'

  validateSchema: (@method) =>
    if method.body? and @isJson()
      contentType =  method.body[@req.headers['content-type']]
      if contentType? and contentType.schema?
        schemaValidator = new SchemaValidator()
        return not (schemaValidator.validate @req.body, JSON.parse contentType.schema).errors.length
    true

  getMethod: () =>
    for method in @resource.methods
      if method.method == @req.route.method
        return method
    return null

  validateUriParams: () =>
    console.log "validate uri params"
    console.log @req.path

    for key, ramlUriParameter of @resource.uriParameters
      reqUriParam = @req.route.params[key]
      if not @validate reqUriParam, ramlUriParameter
        return false
    true

  validateFormParams: (@method) =>
    for key, ramlFormParameter of method.body.formParameters
      reqFormParam = @req.body[key]
      if not @validate reqFormParam, ramlFormParameter
        console.log 'return false'
        return false
    true

  validateQueryParams: (@method) =>
    for key, ramlQueryParameter of method.queryParameters
      reqQueryParam = @req.query[key]
      if not @validate reqQueryParam, ramlQueryParameter
        return false
    true

  validateHeaders: (@method) =>
    for key, ramlHeader of method.headers
      reqHeader = @req.headers[key]
      if not @validate reqHeader, ramlHeader
        return false
    true

  validate: (@reqParam, @ramlParam) =>
    (@validateRequired reqParam, ramlParam) and (@validateType reqParam, ramlParam)

  validateRequired: (@reqParam, @ramlParam) =>
    not ramlParam.required or reqParam?

  validateType: (@reqParam, @ramlParam) =>
    if 'string' == ramlParam.type
      @validateString reqParam, ramlParam
    else if 'number' == ramlParam.type
      @validateNumber reqParam, ramlParam
    else if 'integer' == ramlParam.type
      @validateInt reqParam, ramlParam
    else if 'boolean' == ramlParam.type
      @validateBoolean reqParam
    else
      true

  validateString: (@reqParam, @ramlParam) =>
    if ramlParam.pattern? and reqParam.match(ramlParam.pattern)
      return false
    if ramlParam.minLength? and reqParam.length < ramlParam.minLength
      return false
    if ramlParam.maxLength? and reqParam.length > ramlParam.maxLength
      return false
    if ramlParam.enumeration? and not ramlParam.enumeration in ramlParam.enumeration
      return false
    true

  validateNumber: (@reqParam, @ramlParam) =>
    try number = parseFloat reqParam
    catch e then false
    if ramlParam.minimum? and number < ramlParam.minimum
      return false
    if ramlParam.maximum? and number > ramlParam.maximum
      return false
    true

  validateInt: (@reqParam, @ramlParam) =>
    try number = parseInt reqParam
    catch e then false
    if ramlParam.minimum? and number < ramlParam.minimum
      return false
    if ramlParam.maximum? and number > ramlParam.maximum
      return false
    true

  validateBoolean: (@reqParam) =>
    true == reqParam or false == reqParam

module.exports = Validation