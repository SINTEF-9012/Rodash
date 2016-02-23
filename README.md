# Rodash
[_.set](https://lodash.com/docs#set) and [_.get](https://lodash.com/docs#get) for Ruby

The two methods set and get are based on [Lodash](https://lodash.com/) and ported to Ruby, along with their unit tests.

## Install

`gem install rodash`

### Rodash.set example

```ruby
object = { 'a' => [{ 'b' => { 'c' => 3 } }] }

Rodash.set(object, 'a[0].b.c', 4);
object['a'][0]['b']['c'];
 => 4

Rodash.set(object, 'x[0].y.z', 5);
object['x'][0]['y']['z']);
 => 5
```

### Rodash.get example

```ruby
object = { 'a' => [{ 'b' => { 'c' => 3 } }] };

Rodash.get(object, 'a[0].b.c');
 => 3

Rodash.get(object, ['a', '0', 'b', 'c']);
 => 3

Rodash.get(object, 'a.b.c', 'default');
 => 'default'
```
