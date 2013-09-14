require 'seeda/seed_builder'
require 'seeda/seed_evaluator'

module Seeda
  def self.run
    seed_builder.run
  end

  def self.build(&block)
    seed_builder.instance_exec(&block)
    seed_builder
  end

  def self.seed_builder
    @seed_builder ||= SeedBuilder.new
  end
end
