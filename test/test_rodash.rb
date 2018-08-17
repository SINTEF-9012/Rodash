require 'test/unit'
require 'shoulda'

require_relative '../lib/rodash'

class SetTest < Test::Unit::TestCase

  should "set property values" do
    object = {'a' => 1}

    ['a', ['a']].each do |path|
      actual = Rodash.set(object, path, 2)

      assert_equal actual, object
      assert_equal actual['a'], 2

      object['a'] = 1
    end
  end

  should "set deep property values" do
    object = {'a' => {'b' => {'c' => 3 } } }
    ['a.b.c', ['a', 'b', 'c']].each do |path|
      actual = Rodash.set(object, path, 4)

      assert_equal actual, object
      assert_equal actual['a']['b']['c'], 4

      object['a']['b']['c'] = 3
    end
  end

  should "set a key over a path" do
    object = {'a.b.c' => 3}
    ['a.b.c', ['a.b.c']].each do |path|
      actual = Rodash.set(object, path, 4)

      assert_equal actual, object
      assert_equal object, {'a.b.c' => 4}

      object['a.b.c'] = 3
    end
  end

  should "no coerce array paths to strings" do
    object = {'a,b,c' => 3, 'a' => { 'b' => { 'c' => 3 } } }
    Rodash.set(object, ['a', 'b', 'c'], 4)
    assert_equal object['a']['b']['c'], 4
  end

  should "add multiple indexes to an array" do
    object = { "x" => ["a"] }
    Rodash.set(object, "x[1]", "b")
    assert_equal object['x'][0], "a"
    assert_equal object['x'][1], "b"
  end

  should "igone empty brackets" do
    object = {}
    Rodash.set(object, 'a[]', 1)
    assert_equal object, {'a' => 1}
  end

  should "handle empty paths" do
    [['', ''], [[], ['']]].each_with_index do |pair,index|
      object = {}
      Rodash.set(object, pair[0], 1)
      assert_equal object, index > 0 ? {} : {'' => 1}

      Rodash.set(object, pair[1], 2)
      assert_equal object, {'' => 2}
    end
  end


  should "handle complex paths" do
    object = { 'a' => { '1.23' => { '["b"]' => { 'c' => { "['d']" => { '\ne\n' => { 'f' => { 'g' => 8 } } } } } } } }

    paths = [
      'a[-1.23]["[\\"b\\"]"].c[\'[\\\'d\\\']\'][\ne\n][f].g',
      ['a', '-1.23', '["b"]', 'c', "['d']", '\ne\n', 'f', 'g']
    ]

    paths.each do |path|
      Rodash.set(object, path, 10)
      assert_equal object['a']['-1.23']['["b"]']['c']["['d']"]['\ne\n']['f']['g'], 10
      object['a']['-1.23']['["b"]']['c']["['d']"]['\ne\n']['f']['g'] = 8
    end
  end


  should "create parts of path that are missing" do
    object = {}

    ['a[1].b.c', ['a', '1', 'b', 'c']].each do |path|
      actual = Rodash.set(object, path, 4)

      assert_equal actual, object
      assert_equal actual, {'a' => [nil, {'b' => {'c' => 4 }}]}
      assert(! object.has_key?('0'))

      object.delete 'a'
    end
  end

  should "not error when object is nullish" do
    assert_equal Rodash.set(nil, 'a.b', 1), nil
    assert_equal Rodash.set(nil, ['a','b'], 1), nil
  end

  should "not create an array for missing non-index property names that start with numbers" do
    object = {}
    Rodash.set(object, ['1a', '2b', '3c'], 1)
    assert_equal object, {'1a' => {'2b' => {'3c' => 1 }}}
  end

end

class GetTest < Test::Unit::TestCase

  should "get property values" do
    object = {'a' => 1}

    ['a', ['a']].each do |path|
      assert_equal Rodash.get(object, path), 1
    end
  end

  should "get deep property values" do
    object = {'a' => {'b' => {'c' => 3 } } }

    ['a.b.c', ['a', 'b', 'c']].each do |path|
      assert_equal Rodash.get(object, path), 3
    end
  end

  should "get a key over a path" do
    object = {'a.b.c' => 3}
    ['a.b.c', ['a.b.c']].each do |path|
      assert_equal Rodash.get(object, path), 3
    end
  end

  should "get a key from an array" do
    object = {'a' => 1}, {'a' => 2}

    assert_equal Rodash.get(object, '[0].a'), 1
    assert_equal Rodash.get(object, '[1].a'), 2
  end

  should "no coerce array paths to strings" do
    object = {'a,b,c' => 3, 'a' => { 'b' => { 'c' => 4 } } }
    assert_equal Rodash.get(object, ['a', 'b', 'c']), 4
  end

  should "igone empty brackets" do
    object = {'a' => 1}
    assert_equal Rodash.get(object, 'a[]'), 1
  end

  should "handle empty paths" do
    [['', ''], [[], ['']]].each_with_index do |pair,index|
      object = {}
      assert_equal Rodash.get({}, pair[0]), nil
      assert_equal Rodash.get({'' => 3}, pair[1]), 3
    end
  end


  should "handle complex paths" do
    object = { 'a' => { '-1.23' => { '["b"]' => { 'c' => { "['d']" => { '\ne\n' => { 'f' => { 'g' => 8 } } } } } } } }

    paths = [
      'a[-1.23]["[\\"b\\"]"].c[\'[\\\'d\\\']\'][\ne\n][f].g',
      ['a', '-1.23', '["b"]', 'c', "['d']", '\ne\n', 'f', 'g']
    ]

    paths.each do |path|
      assert_equal Rodash.get(object, path), 8
    end
  end


  should "return nil if parts of path are missing" do
    object = { 'a' => [nil, nil] }

    ['a[1].b.c', ['a', '1', 'b', 'c']].each do |path|
      assert_equal Rodash.get(object, path), nil
    end
  end

  should "be able to return nil values" do
    object = { 'a' => { 'b' => nil }}
    assert_equal Rodash.get(object, 'a.b'), nil
    assert_equal Rodash.get(object, ['a', 'b']), nil
  end

  should "return the default value for nil values" do
    object = { 'a' => { 'b' => nil }}
    assert_equal Rodash.get(object, 'a.b', true), true
    assert_equal Rodash.get(object, ['a', 'b'], 898), 898
    assert_equal Rodash.get(object, ['a', 'b'], nil), nil
  end

end

class UnsetTest < Test::Unit::TestCase

  should "unset property values" do
    ['a', ['a']].each do |path|
      object = {'a' => 1, 'c' => 2 }
      assert Rodash.unset(object, path)
      assert_equal object, { 'c' => 2}
    end
  end

  should "unset deep property values" do

    ['a.b.c', ['a', 'b', 'c']].each do |path|
      object = {'a' => {'b' => {'c' => nil } } }
      assert Rodash.unset(object, path)
      assert_equal object, { 'a' => {'b' => {} } }
    end
  end

  should "handle complex paths" do

    paths = [
      'a[-1.23]["[\\"b\\"]"].c[\'[\\\'d\\\']\'][\ne\n][f].g',
      ['a', '-1.23', '["b"]', 'c', "['d']", '\ne\n', 'f', 'g']
    ]

    paths.each do |path|
      object = { 'a' => { '-1.23' => { '["b"]' => { 'c' => { "['d']" => { '\ne\n' => { 'f' => { 'g' => 8 } } } } } } } }
      assert Rodash.unset(object, path)
      assert(!object['a']['-1.23']['["b"]']['c']["['d']"]['\ne\n']['f'].has_key?('g'))
    end
  end

  should "return true for nonexistent paths" do
    object = { 'a' => { 'b' => { 'c' => nil }}}

    ['z', 'a.z', 'a.b.z', 'a.b.c.z'].each do |path|
      assert Rodash.unset(object, path)
    end

    assert_equal object, { 'a' => { 'b' => { 'c' => nil }}}
  end

  should "not error when object is nullish" do
    assert Rodash.unset(nil, 'a.b')
    assert Rodash.unset(nil, ['a','b'])
  end

  should "not error when object is an array" do
    object = [1, 2, 3]
    assert Rodash.unset(object, 'a')

    object = { 'a' => { 'b' => [1,2,3,4] }}
    assert Rodash.unset(object, 'a.b')
    assert_equal object, { 'a' => {} }
  end

  should "replace by nil unset values in arrays" do
    object = { 'a' => { 'b' => [1,2,3,4] }}
    assert Rodash.unset(object, 'a.b[2]')
    assert_equal object, { 'a' => { 'b' => [1,2,nil,4] }}
  end
end
