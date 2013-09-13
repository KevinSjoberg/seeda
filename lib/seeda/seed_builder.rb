require 'tsort'

module Seeda
  class UnknownDependencyError < Exception ; end
  class DependencyNestingError < Exception ; end

  class SeedBuilder
    include TSort

    attr_reader :seeds, :built_seeds

    def initialize
      @seeds       = {}
      @built_seeds = {}
    end

    def seed(name = nil, &block)
      seeds[:__unnamed__] ||= [nil, [], []]
      seeds[:__unnamed__][2].push(Proc.new { seed(name) { block.call } })
    end

    def define(namespace, context = nil, dependencices = [], &block)
      seeds[namespace] ||= [context, dependencices, []]
      seeds[namespace][2].push(block)
    end

    def build
      begin
        tsort.each do |namespace|
          blocks        = seeds[namespace][2]
          context       = seeds[namespace][0]
          dependencices = seeds[namespace][1].map { |d| built_seeds[d] }

          built_seeds[namespace] =
          SeedEvaluator.new(context, dependencices).evaluate(blocks)
        end
      rescue TSort::Cyclic => e
        raise DependencyNestingError
      end
    end

    def clear
      seeds.clear
    end

    def tsort_each_node(&block)
      seeds.keys.each(&block)
    end

    def tsort_each_child(name, &block)
      if seeds.has_key?(name)
        seeds[name][1].each(&block)
      else
        raise UnknownDependencyError, "unknown dependency: #{name}"
      end
    end
  end
end