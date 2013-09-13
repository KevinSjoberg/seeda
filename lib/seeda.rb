require 'seeda/seed_builder'
require 'seeda/seed_evaluator'

module Seeda
  def self.build
    seed_builder.build
  end

  def self.seeds
    seed_builder.built_seeds
  end

  def self.builder(&block)
    seed_builder.instance_exec(&block)
  end

  def self.clear_seeds
    seed_builder.clear
  end

  private

  def self.seed_builder
    @seed_builder ||= SeedBuilder.new
  end
end