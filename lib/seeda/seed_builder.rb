require 'tsort'

module Seeda
  class UnknownDependencyError < Exception ; end
  class DependencyNestingError < Exception ; end

  class SeedBuilder
    include TSort

    attr_reader :seeds, :seed_procs

    def initialize
      @seeds      = {}
      @seed_procs = {}
    end

    def seed(name = nil, &block)
      seed_procs[:__unnamed__] ||= [nil, [], []]
      seed_procs[:__unnamed__][2].push(Proc.new { seed(name) { block.call } })
    end

    def define(namespace, context = nil, dependencices = [], &block)
      seed_procs[namespace] ||= [context, dependencices, []]
      seed_procs[namespace][2].push(block)
    end

    def run
      begin
        tsort.each do |namespace|
          blocks        = seed_procs[namespace][2]
          context       = seed_procs[namespace][0]
          dependencices = seed_procs[namespace][1].map { |d| seeds[d] }

          seeds[namespace] =
          SeedEvaluator.new(context, dependencices).evaluate(blocks)
        end
      rescue TSort::Cyclic => e
        raise DependencyNestingError
      end
    end

    def clear
      seed_procs.clear
    end

    def tsort_each_node(&block)
      seed_procs.keys.each(&block)
    end

    def tsort_each_child(name, &block)
      if seed_procs.has_key?(name)
        seed_procs[name][1].each(&block)
      else
        raise UnknownDependencyError, "unknown dependency: #{name}"
      end
    end
  end
end
