require 'test_helper'
require 'seeda'

class Storage
  @@store = {}

  class << self
    def [](key)
      @@store[key]
    end

    def []=(key, value)
      @@storage[key] = value
    end

    def clear
      @@store.clear
    end
  end

  def i_save(key, value)
    @@store[key] = value
  end

  def self.c_save(key, value)
    @@store[key] = value
  end
end

class TestSeeda < Minitest::Test
  def setup
    Storage.clear
    Seeda.clear_seeds
  end

  def test_seeds
    Seeda.builder do
      seed { Storage.c_save(:jane, 'Jane') }
      seed { Storage.c_save(:john, 'John') }
    end

    Seeda.build

    assert Seeda.seeds[:__unnamed__][0] == 'Jane'
    assert Seeda.seeds[:__unnamed__][1] == 'John'
  end

  def test_grouped_seeds
    Seeda.builder do
      define :users do
        seed { Storage.c_save(:jane, 'Jane') }
        seed { Storage.c_save(:john, 'John') }
      end
    end

    Seeda.build

    assert Seeda.seeds[:users][0] == 'Jane'
    assert Seeda.seeds[:users][1] == 'John'
  end

  def test_seeds_with_names
    Seeda.builder do
      seed(:jane) { Storage.c_save(:jane, 'Jane') }
      seed(:john) { Storage.c_save(:john, 'John') }
    end

    Seeda.build

    assert Seeda.seeds[:__unnamed__][:jane] == 'Jane'
    assert Seeda.seeds[:__unnamed__][:john] == 'John'
  end

  def test_grouped_seeds_with_names
    Seeda.builder do
      define :users do
        seed(:jane) { Storage.c_save(:jane, 'Jane') }
        seed(:john) { Storage.c_save(:john, 'John') }
      end
    end

    Seeda.build

    assert Seeda.seeds[:users][:jane] == 'Jane'
    assert Seeda.seeds[:users][:john] == 'John'
  end

  def test_grouped_seeds_with_context
    Seeda.builder do
      define :users, Storage do
        seed {       c_save(:jane, 'Jane') }
        seed { |s| s.i_save(:john, 'John') }
      end
    end

    Seeda.build

    assert Seeda.seeds[:users][0] == 'Jane'
    assert Seeda.seeds[:users][1] == 'John'
  end

  def test_grouped_seeds_with_dependencies
    Seeda.builder do
      define :posts, Storage do
        seed { c_save(:post_1, 'Post 1') }
        seed { c_save(:post_2, 'Post 2') }
      end

      define :users, Storage, [:posts] do |posts|
        seed { c_save(:user_1, "Jane (#{posts[0]})")}
        seed { c_save(:user_2, "John (#{posts[1]})")}
      end
    end

    Seeda.build

    assert Seeda.seeds[:posts][0] == 'Post 1'
    assert Seeda.seeds[:posts][1] == 'Post 2'
    assert Seeda.seeds[:users][0] == 'Jane (Post 1)'
    assert Seeda.seeds[:users][1] == 'John (Post 2)'
  end

  def test_grouped_seeds_unknown_dependency_error
    Seeda.builder do
      define :posts, Storage, [:unknown] do
        seed { c_save(:post_1, 'Post 1') }
      end
    end

    assert_raises(Seeda::UnknownDependencyError) { Seeda.build }
  end

  def test_grouped_seeds_circular_dependencies_error
    Seeda.builder do
      define :posts, Storage, [:users] do
        seed { c_save(:post_1, 'Post 1') }
        seed { c_save(:post_2, 'Post 2') }
      end

      define :users, Storage, [:posts] do |posts|
        seed { c_save(:user_1, "Jane (#{posts[0]})")}
        seed { c_save(:user_2, "John (#{posts[1]})")}
      end
    end

    assert_raises(Seeda::DependencyNestingError) { Seeda.build }
  end
end