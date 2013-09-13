module Seeda
  class SeedEvaluator
    attr_reader :context, :dependencies, :evaluated_seeds

    def initialize(context, dependencies)
      @context = context
      @dependencies = dependencies
      @evaluated_seeds = {}
    end

    def seed(name = nil, &block)
      evaluated_seeds[name || iterate] = unless context
        execute(block)
      else
        execute_in_context(block)
      end
    end

    def evaluate(seeds)
      seeds.each { |seed| instance_exec(*dependencies, &seed) }

      evaluated_seeds
    end

    private

    def iterate
      @seed_number ? @seed_number += 1 : @seed_number = 0
    end

    def execute(block)
      block.call
    end

    def execute_in_context(block)
      if block.arity == 0
        context.class_exec(&block)
      else
        block.call(context.new)
      end
    end
  end
end