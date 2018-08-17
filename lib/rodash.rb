# Rodash 1.0.0
# Rodash.get and Rodash.set
# MIT License
# Based on Lodash.js 4.3.0 <https://lodash.com/>

class Rodash

  # Sets the value at `path` of `object`. If a portion of `path` doesn't exist
  # it's created. Arrays are created for missing index properties while objects
  # are created for all other missing properties.
  #
  # **Note:** This method mutates `object`.
  #
  # @param {Hash} object The object to modify.
  # @param {Array|string} path The path of the property to set.
  # @param {*} value The value to set.
  # @returns {Hash} Returns `object`.
  # @example
  #
  # object = { 'a' => [{ 'b' => { 'c' => 3 } }] }
  #
  # Rodash.set(object, 'a[0].b.c', 4)
  # object['a'][0]['b']['c']
  # // => 4
  #
  # Rodash.set(object, 'x[0].y.z', 5)
  # object['x'][0]['y']['z'])
  # // => 5
  #
  def self.set(object, path, value)
    object.nil? ? object : baseSet(object, path, value)
  end

  # Gets the value at `path` of `object`. If the resolved value is
  # `nil` the `defaultValue` is used in its place.
  #
  # @param {Hash|Array} object The object to query.
  # @param {Array|string} path The path of the property to get.
  # @param {*} [defaultValue] The value returned if the resolved value is `nil`.
  # @returns {*} Returns the resolved value.
  # @example
  #
  # object = { 'a' => [{ 'b' => { 'c' => 3 } }] }
  #
  # Rodash.get(object, 'a[0].b.c')
  # // => 3
  #
  # Rodash.get(object, ['a', '0', 'b', 'c'])
  # // => 3
  #
  # Rodash.get(object, 'a.b.c', 'default')
  # // => 'default'
  def self.get(object, path, defaultValue = nil)
    result = object.nil? ? nil : baseGet(object, path)
    result.nil? ? defaultValue : result
  end

  # Removes the property at `path` of `object`.
  #
  # **Note:** This method mutates `object`.
  #
  # @param {Hash} object The object to modify.
  # @param {Array|string} path The path of the property to unset.
  # @returns {boolean} Returns `true` if the property is deleted, else `false`.
  # @example
  #
  # object = { 'a' => [{ 'b' => { 'c' => 7 } }] }
  # Rodash.unset(object, 'a[0].b.c')
  # // => true
  #
  # object
  # // => { 'a' => [{ 'b' => {} }] }
  #
  # Rodash.unset(object, 'a[0].b.c')
  # // => true
  #
  # object
  # // => { 'a' => [{ 'b' => {} }] }
  #
  def self.unset(object, path)
    object.nil? ? true : baseUnset(object, path)
  end

  protected

  @@reIsDeepProp = /\.|\[(?:[^\[\]]*|(["'])(?:(?!\1)[^\\]|\\.)*?\1)\]/
  @@reIsPlainProp = /^\w*$/
  @@rePropName = /[^.\[\]]+|\[(?:(-?\d+(?:\.\d+)?)|(["'])((?:(?!\2)[^\\]|\\.)*?)\2)\]/
  @@reEscapeChar = /\\(\\)?/

  def self.baseSet(object, path, value, customizer = false)
      throw "object must be a hash" if not object.is_a? Hash

      path = isKey(path, object) ? [path + ''] : baseToPath(path)

      nested = object
      newNested = nil

      [*path, nil].each_cons(2) do |key, nextkey|
        if isIndex(key) && nested.is_a?(Array)
          key = key.to_i
        end
        if nextkey.nil?
          newNested = nested[key] = value
        else
          newNested = nested[key]
          if isIndex(nextkey) && (!newNested.is_a?(Hash) || !newNested.is_a(Array))
            nested[key] = []
            newNested = [] if newNested == nil
            nested[key] = newNested if newNested != nil
          elsif not newNested.is_a? Hash
            nested[key] = {}
            newNested = {} if newNested == nil
            nested[key] = newNested if newNested != nil
          end
        end
        nested = newNested
      end
      return object
  end

  def self.baseGet(object, path)
    path = isKey(path, object) ? [path + ''] : baseToPath(path)

    index = 0
    length = path.count

    while !object.nil? && index < length
      key = path[index]
      if object.is_a?(Array)
        if isIndex(key)
          object = object[key.to_i]
        else
          return nil
        end
      elsif object.is_a?(Hash)
        object = object[path[index]]
      else
        return nil
      end
      index += 1
    end

    (index > 0 && index == length) ? object : nil
  end

  def self.baseUnset(object, path)
    path = isKey(path, object) ? [path + ''] : baseToPath(path)
    object = parent(object, path)
    key = path.last
    if object.is_a?(Array) && isIndex(key)
      object[key.to_i] = nil
    elsif not object.nil?
      object.delete(key)
    end
    return true
  end

  def self.parent(object, path)
    path.count == 1 ? object : get(object, path[0 ... -1])
  end

  def self.isKey(value, object)
    return true if value.is_a? Numeric
    return !value.is_a?(Array) &&
      (@@reIsPlainProp =~ value || !@@reIsDeepProp =~ value ||
        (!object.nil? && !object.is_a?(Array) && object.has_key?(value)))
  end

  def self.baseToPath(value)
    value.kind_of?(Array) ? value : stringToPath(value)
  end

  def self.stringToPath(string)
    result = []
    string.to_s.gsub(@@rePropName) do |match|
      number = $1
      quote = $2
      string = $3
      result.push((quote && !quote.empty?) ? string.gsub(@@reEscapeChar, '\1') : (number || match))
    end

    return result
  end

  @@MAX_SAFE_INTEGER = 9007199254740991
  @@reIsUint = /^(?:0|[1-9]\d*)$/

  def self.isIndex(value, length = nil)
    value = (value.is_a?(Numeric) || @@reIsUint =~ value) ? value.to_i : -1
    length = length.nil? ? @@MAX_SAFE_INTEGER : length
    return value > -1 && value % 1 == 0 && value < length
  end
end
