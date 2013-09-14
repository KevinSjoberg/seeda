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
    Seeda.seed_builder.clear
  end

  def test_seeds
    builder = Seeda.build do
      seed { Storage.c_save(:jane, 'Jane') }
      seed { Storage.c_save(:john, 'John') }
    end

    Seeda.run

    assert_equal 'Jane', builder.seeds[:__unnamed__][0]
    assert_equal 'John', builder.seeds[:__unnamed__][1]
  end

  def test_grouped_seeds
    builder = Seeda.build do
      define :users do
        seed { Storage.c_save(:jane, 'Jane') }
        seed { Storage.c_save(:john, 'John') }
      end
    end

    Seeda.run

    assert builder.seeds[:users][0] == 'Jane'
    assert builder.seeds[:users][1] == 'John'
  end

  def test_seeds_with_names
    builder = Seeda.build do
      seed(:jane) { Storage.c_save(:jane, 'Jane') }
      seed(:john) { Storage.c_save(:john, 'John') }
    end

    Seeda.run

    assert builder.seeds[:__unnamed__][:jane] == 'Jane'
    assert builder.seeds[:__unnamed__][:john] == 'John'
  end

  def test_grouped_seeds_with_names
    builder = Seeda.build do
      define :users do
        seed(:jane) { Storage.c_save(:jane, 'Jane') }
        seed(:john) { Storage.c_save(:john, 'John') }
      end
    end

    Seeda.run

    assert builder.seeds[:users][:jane] == 'Jane'
    assert builder.seeds[:users][:john] == 'John'
  end

  def test_grouped_seeds_with_context
    builder = Seeda.build do
      define :users, Storage do
        seed {       c_save(:jane, 'Jane') }
        seed { |s| s.i_save(:john, 'John') }
      end
    end

    Seeda.run

    assert builder.seeds[:users][0] == 'Jane'
    assert builder.seeds[:users][1] == 'John'
  end

  def test_grouped_seeds_with_dependencies
    builder = Seeda.build do
      define :posts, Storage do
        seed { c_save(:post_1, 'Post 1') }
        seed { c_save(:post_2, 'Post 2') }
      end

      define :users, Storage, [:posts] do |posts|
        seed { c_save(:user_1, "Jane (#{posts[0]})")}
        seed { c_save(:user_2, "John (#{posts[1]})")}
      end
    end

    Seeda.run

    assert builder.seeds[:posts][0] == 'Post 1'
    assert builder.seeds[:posts][1] == 'Post 2'
    assert builder.seeds[:users][0] == 'Jane (Post 1)'
    assert builder.seeds[:users][1] == 'John (Post 2)'
  end

  def test_grouped_seeds_unknown_dependency_error
    Seeda.build do
      define :posts, Storage, [:unknown] do
        seed { c_save(:post_1, 'Post 1') }
      end
    end

    assert_raises(Seeda::UnknownDependencyError) { Seeda.run }
  end

  def test_grouped_seeds_circular_dependencies_error
    Seeda.build do
      define :posts, Storage, [:users] do
        seed { c_save(:post_1, 'Post 1') }
        seed { c_save(:post_2, 'Post 2') }
      end

      define :users, Storage, [:posts] do |posts|
        seed { c_save(:user_1, "Jane (#{posts[0]})")}
        seed { c_save(:user_2, "John (#{posts[1]})")}
      end
    end

    assert_raises(Seeda::DependencyNestingError) { Seeda.run }
  end
end
