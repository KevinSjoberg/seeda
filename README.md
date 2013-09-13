# Seeda
Seeda makes it easy to create structured and modular seeds.


## Usage
```ruby
Seeda.builder do
  # Simple seeds
  seed { Category.create! name: "Work"     }
  seed { Category.create! name: "Personal" }

  # Seeds can be grouped and have names
  define :users do
    seed(:jane) { User.create! name: "Jane" }
    seed(:john) { User.create! name: "John" }
  end

  # Seeds can have context and dependencies (even ungrouped seeds)
  define :projects, Project, [:users, __:unnamed__] do |users, categories|
    seed { create! name: "Project 1", user: users[:jane], category: categories[0] }
    seed { create! name: "Project 2", user: users[:john], category: categories[1] }
  end
end

Seeda.build
```
